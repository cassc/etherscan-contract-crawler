/**
 *Submitted for verification at Etherscan.io on 2023-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract OTCMarketplace {
    struct Order {
        address seller;
        address token;
        uint256 price;
        uint256 quantity;
    }

    struct TokenBasi {
        string symbol;
        uint256 deci;
        uint256 min;
    }
    mapping(address => mapping(address => Order[])) private orders;
    address[] public  ts;
    mapping(address => address[]) private sells;
    address private dev;
    mapping(address => TokenBasi) private tbas;
    uint256 private listTypeCreate;
    uint256 private listTypeCancel;
    uint256 private listTypeExcute;
    uint256 private fee;
    constructor() {
        dev = msg.sender;
        listTypeCreate = 0;
        listTypeCancel = 0;
        listTypeExcute = 1;
        fee = 1;
    }
    event OrderCreated(address seller, address token, uint256 price, uint256 quantity, uint256 key);
    event OrderCancel(address seller, address token, uint256 key);
    event OrderExecuted(address buyer, address seller, address token, uint256 price, uint256 quantity, uint256 key);

    modifier validOrder(address token, address seller, uint256 orderIndex) {
        require(orderIndex < orders[token][seller].length, "Invalid order");
        _;
    }
    function setListTypeAndFee(uint256 listTypeCreate,uint256 listTypeCancel,uint256 listTypeExcute, uint256 fee) external {
        require(msg.sender == dev, "not dev");
        listTypeCreate = listTypeCreate;
        listTypeCancel = listTypeCancel;
        listTypeExcute = listTypeExcute;
        require(fee<=10,"too much");
        fee = fee;
    }
    function addT(address token, string memory symbol, uint256 deci, uint256 min) external {
        require(msg.sender == dev, "not dev");
        TokenBasi memory newBas = TokenBasi(symbol, deci, min);
        ts.push(token);
        tbas[token] = newBas;
    }
    function getT(address token) public view returns (string memory, uint256, uint256) {
        TokenBasi storage newBas = tbas[token];
        return (newBas.symbol, newBas.deci, newBas.min);
    }
    function getTs(uint256 i) public view returns (address){
        return ts[i];
    }
    function upSym(address token, string memory symbol, uint256 deci, uint256 min) public {
        require(msg.sender == dev, "not dev");
        tbas[token].symbol = symbol;
        tbas[token].deci = deci;
        tbas[token].min = min;
    }
    function getTSize(address token) public view returns (uint256 tsize){
        return ts.length;
    }
    function isT(address token) public view returns (bool) {
        for (uint256 i = 0; i < ts.length; i++) {
            if (ts[i] == token) {
                return true;
            }
        }
        return false;
    }
    function getOrder(address token, address seller, uint256 orderIndex) public view returns (address, address, uint256, uint256) {
        require(isT(token), "Not allowed token");
        Order storage order = orders[token][seller][orderIndex];
        return (order.seller, order.token, order.price, order.quantity);
    }
    function getSellerSize(address token, address seller) public view returns (uint256) {
        require(isT(token), "Not allowed token");
        return orders[token][seller].length;
    }
    function getTokenSellerSize(address token, address seller) public view returns (uint256) {
        require(isT(token), "Not allowed token");
        return sells[token].length;
    }
    function create(address token, uint256 price, uint256 quantity) external {
        require(quantity > 0 && price > 0, "Invalid quantity or price");
        require(isT(token), "Not allowed token");
        TokenBasi storage newBas = tbas[token];
        require(quantity >= newBas.min, "less min");
        uint256 realyQua = quantity;
        if (listTypeCreate == 1) {
            IERC20(token).transferFrom(msg.sender, address(this), quantity * 10 ** newBas.deci * (100 - fee) / 100);
            IERC20(token).transferFrom(msg.sender, dev, quantity * 10 ** newBas.deci * fee / 100);
            realyQua = quantity * (100 - fee) / 100;
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), quantity * 10 ** newBas.deci);
            realyQua = quantity;
        }
        Order memory newOrder = Order(msg.sender, token, price, realyQua);
        orders[token][msg.sender].push(newOrder);
        sells[token].push(msg.sender);

        emit OrderCreated(msg.sender, token, price, realyQua, orders[token][msg.sender].length - 1);
    }

    function cancel(address token, uint256 orderIndex) external {
        require(isT(token), "Not allowed token");
        Order storage order = orders[token][msg.sender][orderIndex];
        TokenBasi storage newBas = tbas[token];
        require(order.quantity > 0 && order.seller == msg.sender, "Invalid order or seller");

        if (listTypeCancel == 1) {
            IERC20(token).transfer(msg.sender, order.quantity * 10 ** newBas.deci * (100 - fee) / 100);
            IERC20(token).transfer(dev, order.quantity * 10 ** newBas.deci * fee / 100);
        } else {
            IERC20(token).transfer(msg.sender, order.quantity * 10 ** newBas.deci);
        }
        delete orders[token][msg.sender][orderIndex];
        emit OrderCancel(msg.sender, token, orderIndex);

    }

    function execute(address token, address seller, uint256 orderIndex) external payable validOrder(token, seller, orderIndex) {
        Order storage order = orders[token][seller][orderIndex];
        uint256 quantity = order.quantity;
        uint256 price = order.price;
        require(quantity > 0 && price > 0, "Insufficient balance");
        require(msg.value >= (price * 10 ** 15), "Insufficient funds");
        TokenBasi storage newBas = tbas[token];
        if (listTypeExcute == 1) {
            IERC20(token).transfer(msg.sender, quantity * 10 ** newBas.deci * (100 - fee) / 100);
            IERC20(token).transfer(dev, quantity * 10 ** newBas.deci * fee / 100);
        } else {
            IERC20(token).transfer(msg.sender, quantity * 10 ** newBas.deci);
        }

        payable(seller).transfer(msg.value);
        delete orders[token][seller][orderIndex];

        emit OrderExecuted(msg.sender, seller, token, price, quantity, orderIndex);
    }


}