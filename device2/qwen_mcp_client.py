#!/usr/bin/env python3
"""
qwen_mcp_client.py
MCP Client - Qwen 2.5 기반 자동화
"""

from openai import OpenAI
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
import json
import asyncio
import logging

# 로깅
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

class QwenMCPClient:
    def __init__(self):
        # Ollama (Qwen 2.5) OpenAI 호환 모드
        self.llm = OpenAI(
            base_url="http://localhost:11434/v1",
            api_key="ollama"
        )
        self.model = "qwen2.5:7b"
        self.mcp_session = None
        self.available_tools = []
    
    async def connect_to_mcp_server(self):
        """MCP Server 연결"""
        server_params = StdioServerParameters(
            command="python3",
            args=["mcp_server.py"]
        )
        
        stdio_transport = await stdio_client(server_params)
        self.stdio, self.write = stdio_transport
        self.mcp_session = ClientSession(self.stdio, self.write)
        await self.mcp_session.initialize()
        
        # 도구 목록 가져오기
        tools_list = await self.mcp_session.list_tools()
        
        for tool in tools_list.tools:
            self.available_tools.append({
                "type": "function",
                "function": {
                    "name": tool.name,
                    "description": tool.description,
                    "parameters": tool.inputSchema
                }
            })
        
        logging.info(f"✅ MCP Server 연결 완료")
        logging.info(f"📋 사용 가능한 도구: {len(self.available_tools)}개")
    
    async def run_auto_defense(self):
        """자동 방어 루프 (10초마다)"""
        logging.info("\n🛡️ Qwen 2.5 자동 방어 시작...\n")
        
        iteration = 0
        
        while True:
            try:
                iteration += 1
                logging.info(f"{'='*60}")
                logging.info(f"🔄 반복 {iteration}")
                logging.info(f"{'='*60}")
                
                await self.execute_task(
                    "최근 Suricata 로그 10개를 분석해서 악성 트래픽이 있으면 "
                    "Suricata 룰을 자동으로 생성하고 적용해줘. "
                    "결과는 한국어로 간단히 요약해줘."
                )
                
                logging.info(f"\n⏳ 10초 대기...\n")
                await asyncio.sleep(10)
            
            except KeyboardInterrupt:
                logging.info("\n🛑 종료")
                break
            except Exception as e:
                logging.error(f"오류: {e}")
                await asyncio.sleep(10)
    
    async def execute_task(self, user_task: str):
        """Qwen에게 작업 실행 요청"""
        messages = [
            {
                "role": "system",
                "content": """당신은 네트워크 보안 AI 어시스턴트입니다.
사용 가능한 도구를 활용하여 사용자의 요청을 처리하세요.

도구 목록:
1. get_suricata_logs(count) - Suricata 로그 조회
2. analyze_network_flow(flow_data) - ML 모델로 분석
3. generate_suricata_rule(attack_type, src_ip, dest_ip, proto) - 룰 생성
4. apply_rule_to_suricata(rule, sid) - 룰 적용

항상 한국어로 답변하고, 간결하게 요약하세요."""
            },
            {
                "role": "user",
                "content": user_task
            }
        ]
        
        # Agent 루프
        for iteration in range(10):
            # Qwen 호출
            response = self.llm.chat.completions.create(
                model=self.model,
                messages=messages,
                tools=self.available_tools,
                tool_choice="auto",
                temperature=0.1
            )
            
            assistant_message = response.choices[0].message
            
            # 메시지 추가
            messages.append({
                "role": "assistant",
                "content": assistant_message.content,
                "tool_calls": assistant_message.tool_calls
            })
            
            # 도구 호출이 없으면 완료
            if not assistant_message.tool_calls:
                if assistant_message.content:
                    logging.info(f"\n🤖 Qwen:\n{assistant_message.content}\n")
                break
            
            # 도구 실행
            for tool_call in assistant_message.tool_calls:
                tool_name = tool_call.function.name
                tool_args = json.loads(tool_call.function.arguments)
                
                logging.info(f"🔧 도구 호출: {tool_name}")
                
                # MCP 도구 실행
                try:
                    result = await self.mcp_session.call_tool(
                        tool_name,
                        arguments=tool_args
                    )
                    
                    result_content = result.content[0].text
                    
                    # 도구 결과 추가
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "name": tool_name,
                        "content": result_content
                    })
                    
                    logging.info(f"   ✓ 완료")
                
                except Exception as e:
                    logging.error(f"   ❌ 오류: {e}")
                    messages.append({
                        "role": "tool",
                        "tool_call_id": tool_call.id,
                        "name": tool_name,
                        "content": f"오류 발생: {str(e)}"
                    })


async def main():
    print("=" * 60)
    print("🇰🇷 Qwen 2.5 + MCP 자동 방어 시스템")
    print("=" * 60)
    print()
    
    client = QwenMCPClient()
    await client.connect_to_mcp_server()
    await client.run_auto_defense()


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n🛑 종료")