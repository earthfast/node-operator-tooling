from .content_node import ContentNode
from .domain_node import DomainNode

def create_node(node_type, env, setup_ssl, start_container):
    if node_type == 'content':
        return ContentNode(env, setup_ssl, start_container)
    elif node_type == 'domain':
        return DomainNode(env, setup_ssl, start_container)
    else:
        raise ValueError(f"Unsupported node type: {node_type}")
