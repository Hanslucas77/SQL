-- Criar estrutura do banco de dados
CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

-- Tabelas principais
CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    data_cadastro DATE
);

CREATE TABLE pedidos (
    id_pedido INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT,
    data_pedido DATE,
    valor_total DECIMAL(10,2),
    status ENUM('pendente', 'pago', 'cancelado') DEFAULT 'pendente',
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
);

CREATE TABLE itens_pedido (
    id_item INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido INT,
    produto VARCHAR(100),
    quantidade INT,
    preco_unitario DECIMAL(10,2),
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

-- Inserção de dados fictícios
INSERT INTO clientes (nome, email, data_cadastro) VALUES
('Lucas Hans', 'lucas@example.com', '2023-01-15'),
('Ana Silva', 'ana@example.com', '2023-02-10'),
('Carlos Lima', 'carlos@example.com', '2023-03-05');

INSERT INTO pedidos (id_cliente, data_pedido, valor_total, status) VALUES
(1, '2023-04-01', 300.00, 'pago'),
(1, '2023-04-20', 150.00, 'pendente'),
(2, '2023-04-15', 200.00, 'cancelado');

INSERT INTO itens_pedido (id_pedido, produto, quantidade, preco_unitario) VALUES
(1, 'Teclado', 1, 100.00),
(1, 'Mouse', 2, 100.00),
(2, 'Headset', 1, 150.00),
(3, 'Monitor', 1, 200.00);

-- View para análise de clientes e total gasto
CREATE VIEW vw_analise_clientes AS
SELECT 
    c.id_cliente,
    c.nome,
    COUNT(p.id_pedido) AS total_pedidos,
    SUM(CASE WHEN p.status = 'pago' THEN p.valor_total ELSE 0 END) AS total_gasto
FROM clientes c
LEFT JOIN pedidos p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nome;

-- CTE para pedidos pagos nos últimos 30 dias
WITH pedidos_recentes AS (
    SELECT * FROM pedidos
    WHERE status = 'pago' AND data_pedido >= CURDATE() - INTERVAL 30 DAY
)
SELECT 
    pr.id_pedido,
    c.nome,
    pr.valor_total
FROM pedidos_recentes pr
JOIN clientes c ON c.id_cliente = pr.id_cliente;

-- Procedure para atualizar status de pedidos pendentes com mais de 7 dias
DELIMITER //
CREATE PROCEDURE atualizar_status_pedidos()
BEGIN
    UPDATE pedidos
    SET status = 'cancelado'
    WHERE status = 'pendente'
      AND data_pedido < CURDATE() - INTERVAL 7 DAY;
END;
//
DELIMITER ;

-- Trigger para atualizar valor_total do pedido automaticamente ao inserir item
DELIMITER //
CREATE TRIGGER atualizar_valor_total
AFTER INSERT ON itens_pedido
FOR EACH ROW
BEGIN
    UPDATE pedidos
    SET valor_total = valor_total + (NEW.quantidade * NEW.preco_unitario)
    WHERE id_pedido = NEW.id_pedido;
END;
//
DELIMITER ;

-- Consulta final para análise de faturamento mensal
SELECT 
    DATE_FORMAT(data_pedido, '%Y-%m') AS mes,
    SUM(valor_total) AS faturamento
FROM pedidos
WHERE status = 'pago'
GROUP BY mes
ORDER BY mes;
