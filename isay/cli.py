import click

from .tools import say

@click.command()
@click.argument("message", default="hello")
def main(message: str):
    print(say(message))