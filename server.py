from aiohttp import web
import asyncio
import subprocess

connected_websockets = set()

async def index(request):
    return web.FileResponse('index.html')  # Serve static file

async def websocket_handler(request):
    ws = web.WebSocketResponse()
    await ws.prepare(request)

    connected_websockets.add(ws)
    print("WebSocket connected")

    async for msg in ws:
        if msg.type == web.WSMsgType.TEXT:
            # Echo message or handle commands
            for client in connected_websockets:
                if client != ws:
                    await client.send_str(msg.data)

    connected_websockets.remove(ws)
    print("WebSocket disconnected")
    return ws

def start_shell_script():
    # Start the shell script and log its output
    print("Starting the watch-folder.sh script...")
    process = subprocess.Popen(
        ["bash", "watch-folder.sh"],  # Adjust the path if necessary
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    # Stream the output of the shell script to the same log
    for line in iter(process.stdout.readline, ''):
        print(line.strip())  # Log stdout to Docker logs
    for line in iter(process.stderr.readline, ''):
        print(line.strip())  # Log stderr to Docker logs
    process.stdout.close()
    process.stderr.close()
    process.wait()

app = web.Application()
app.router.add_get('/', index)
app.router.add_get('/ws', websocket_handler)

host = '0.0.0.0'
port = 443

print(f"Starting WebSocket server at ws://localhost:{port}/ws")

# Start the shell script asynchronously
loop = asyncio.get_event_loop()
loop.run_in_executor(None, start_shell_script)

# Run the web application
web.run_app(app, host=host, port=port)