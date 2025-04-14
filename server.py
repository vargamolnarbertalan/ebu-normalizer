from aiohttp import web
import asyncio
import subprocess

async def index(request):
    return web.FileResponse('index.html')  # Serve the HTML file

def start_shell_script():
    print("Starting the watch-folder.sh script...")
    process = subprocess.Popen(
        ["bash", "watch-folder.sh"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )
    for line in iter(process.stdout.readline, ''):
        print(line.strip())
    for line in iter(process.stderr.readline, ''):
        print(line.strip())
    process.stdout.close()
    process.stderr.close()
    process.wait()

app = web.Application()

# Serve index.html at root
app.router.add_get('/', index)

# 🔥 Serve static files from the current directory
app.router.add_static('/', path='.', show_index=True)

host = '0.0.0.0'
port = 80

print(f"Starting server at http://{host}:{port}/")

loop = asyncio.get_event_loop()
#loop.run_in_executor(None, start_shell_script)

web.run_app(app, host=host, port=port)