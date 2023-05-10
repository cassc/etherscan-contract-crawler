// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./ERC20.sol";
import "./SafeMath.sol";

contract DexMeta {

    using SafeMath for uint256;

    ERC20   public BUSD_TOKEN;
    ERC20   public U_TOKEN;

    struct Order {
        uint256 id;
        address payable user;
        uint256 amount;
        uint256 remain;
        uint256 price;
        bool is_sell;
        bool active;
        uint256 time;
    }

    Order[] public orders;
    uint256 public orderCount;
    mapping(uint256 => uint256) public ordersCountOnPrice;
    mapping(uint256 => uint256[]) public ordersOnPrice;
    mapping(address => uint256[]) private userOrders;
    

    constructor(address busd, address utoken){
        BUSD_TOKEN   = ERC20(busd);
        U_TOKEN   = ERC20(utoken);
    }

    function createOrder(uint256 _amount, uint256 _price, bool is_sell, bool execute) public {

        if(is_sell){
            require(U_TOKEN.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        }else{
            require(BUSD_TOKEN.transferFrom(msg.sender, address(this), safeTotalPrice(_amount, _price)), "Transfer failed");
        }

        orders.push(Order(orderCount, payable(msg.sender), _amount, _amount, _price, is_sell, true, block.timestamp));
        ordersOnPrice[_price].push(orderCount);
        ordersCountOnPrice[_price]++;
        userOrders[msg.sender].push(orderCount);
        orderCount++;
        if(execute){
            executeOrder((orderCount - 1));
        }

        emit newOrder(msg.sender, _amount, _price, is_sell);
    }

    function cancelOrder(uint256 _orderId) public {
        require(_orderId < orders.length && orders[_orderId].active == true, "Invalid order");
        require(orders[_orderId].user == msg.sender, 'You can not cancel this order');
        orders[_orderId].active = false;
        
        if(orders[_orderId].is_sell){
            require(U_TOKEN.transfer(orders[_orderId].user, orders[_orderId].remain), "Transfer failed");
        }else{
            require(BUSD_TOKEN.transfer(orders[_orderId].user, safeTotalPrice(orders[_orderId].remain, orders[_orderId].price)), "Transfer failed");
        }
        emit onCancelOrder(_orderId, orders[_orderId].remain);
    }

    function executeOrder(uint256 _orderId) private {

        for(uint256 i=0; i<ordersCountOnPrice[orders[_orderId].price]; i++){

            if(orders[ordersOnPrice[orders[_orderId].price][i]].is_sell != orders[_orderId].is_sell && orders[ordersOnPrice[orders[_orderId].price][i]].active == true){
                
                uint256 order1Remain = orders[_orderId].remain;
                uint256 order2Remain = orders[ordersOnPrice[orders[_orderId].price][i]].remain;
                uint256 amount = 0;

                if(order1Remain >= order2Remain){
                    orders[_orderId].remain -= order2Remain;
                    orders[ordersOnPrice[orders[_orderId].price][i]].remain = 0;
                    orders[ordersOnPrice[orders[_orderId].price][i]].active = false;
                    amount = order2Remain;
                    if(orders[_orderId].remain <= 0){
                        orders[_orderId].active = false;
                    }
                }
                else{
                    orders[ordersOnPrice[orders[_orderId].price][i]].remain -= order1Remain;
                    orders[_orderId].remain = 0;
                    orders[_orderId].active = false;
                    amount = order1Remain;
                    if(orders[ordersOnPrice[orders[_orderId].price][i]].remain <= 0){
                        orders[ordersOnPrice[orders[_orderId].price][i]].active = false;
                    }
                }

                if(amount > 0){
                    if(orders[_orderId].is_sell){
                        require(U_TOKEN.transfer(orders[ordersOnPrice[orders[_orderId].price][i]].user, amount), "Transfer failed");
                        require(BUSD_TOKEN.transfer(orders[_orderId].user, safeTotalPrice(amount, orders[_orderId].price)), "Transfer failed");
                    }else{
                        require(U_TOKEN.transfer(orders[_orderId].user, amount), "Transfer failed");
                        require(BUSD_TOKEN.transfer(orders[ordersOnPrice[orders[_orderId].price][i]].user, safeTotalPrice(amount, orders[_orderId].price)), "Transfer failed");
                    }
                    emit onExecuteOrder(_orderId, ordersOnPrice[orders[_orderId].price][i], amount, orders[_orderId].price);
                }

            }

            if(orders[_orderId].active == false){
                break;
            }
        }

    }

    function getOrders(bool onlyActive) public returns (Order[] memory) {

        Order[] memory OrderArray = new Order[](orderCount);
        uint256 _i = 0;

        for(uint256 i=0; i<orderCount; i++){
            if(onlyActive == true && orders[i].active == false)
                continue;
            
            OrderArray[_i] = orders[i];
            _i++;
            
        }

        return OrderArray;
    }

    function getBuyOrders(bool onlyActive) public returns (Order[] memory) {
        Order[] memory OrderArray = new Order[](orderCount);
        uint256 _i = 0;

        for(uint256 i=0; i<orderCount; i++){
            if((onlyActive == true && orders[i].active == false) || orders[i].is_sell == true)
                continue;
            

            OrderArray[_i] = orders[i];
            _i++;
            
        }

        return OrderArray;
    }

    function getSellOrders(bool onlyActive) public returns (Order[] memory) {
        Order[] memory OrderArray = new Order[](orderCount);
        uint256 _i = 0;

        for(uint256 i=0; i<orderCount; i++){
            if((onlyActive == true && orders[i].active == false) || orders[i].is_sell == false)
                continue;
            

            OrderArray[_i] = orders[i];
            _i++;
            
        }

        return OrderArray;
    }

    function safeTotalPrice(uint256 amount, uint256 price) private returns(uint256) {
        uint256 total = totalPrice(amount, price);
        require(total > 0, 'Internal Error');
        return total;
    }

    function totalPrice(uint256 amount, uint256 price) public returns(uint256){
        return amount.div(1e8).mul(price.div(1e10));
    }

    function getUserOrderIds(address user_address) public view returns (uint256[] memory){
        return userOrders[user_address];
    }

    function getUserOrder(address user_address) public view returns (Order[] memory){

        uint256 oLength = userOrders[user_address].length;

         Order[] memory OrderArray = new Order[](oLength);

        for(uint256 i=0; i<oLength; i++){
            OrderArray[i] = orders[userOrders[user_address][i]];
        }

        return OrderArray;
    }

    event newOrder(address indexed user, uint256 _amount, uint256 _price, bool is_sell);
    event onCancelOrder(uint256 orderId, uint256 remain);
    event onExecuteOrder(uint256 orderId1, uint256 orderId2, uint256 amount, uint256 price);


}
