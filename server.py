from aiohttp import web
import asyncio
import os

async def index(request):
    return web.FileResponse('index.html')  # Serve the HTML file

async def get_new_log(request):
    log_file = 'encode.log'
    if os.path.exists(log_file):
        try:
            with open(log_file, 'r') as f:
                content = f.read()
            return web.Response(text=content)
        except Exception as e:
            return web.Response(text=f"Error reading log file: {e}", status=500)
    else:
        return web.Response(text="Log file not found.", status=404)

app = web.Application()

# Serve index.html at root
app.router.add_get('/', index)

# Serve /getNewLog path
app.router.add_get('/getNewLog', get_new_log)

# Serve static files from the current directory
app.router.add_static('/', path='.', show_index=True)

host = '0.0.0.0'
port = 80

print(f"Starting server at http://{host}:{port}/")

web.run_app(app, host=host, port=port)