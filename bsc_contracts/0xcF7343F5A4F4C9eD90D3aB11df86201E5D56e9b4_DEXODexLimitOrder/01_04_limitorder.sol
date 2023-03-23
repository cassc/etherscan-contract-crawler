/**
 *Submitted for verification at polygonscan.com on 2021-06-13
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import "./Ownable.sol";
import "./safelib.sol";
import "./IERC20.sol";

// A partial WETH interfaec.
interface IWETH is IERC20 {
    function deposit() external payable;
}

contract DEXODexLimitOrder is Ownable {
    using SafeMath for uint256;

    address public NATIVE = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    enum OrderState {Created, Cancelled, Finished}
    enum OrderType {EthForTokens, TokensForEth, TokensForTokens}
    
    struct Order {
        OrderState orderState;
        OrderType orderType;
        address payable traderAddress;
        address assetIn;
        address assetOut;
        uint assetInOffered;
        uint assetOutExpected;
        uint executorFee;
        uint stake;
        uint id;
        uint ordersI;
        address[] path;
    }
    address public immutable WETH;

    uint public STAKE_FEE = 2;
    uint public EXECUTOR_FEE = 500000000000000;
    uint[] public orders;
    uint public ordersNum = 0;
    address public stakeAddress = address(0x885Be84DA467aC606bC2F9Ff782a8C0B3D9b0670);
    
    event logOrderCreated(
        uint id,
        OrderState orderState, 
        OrderType orderType, 
        address payable traderAddress, 
        address assetIn, 
        address assetOut,
        uint assetInOffered, 
        uint assetOutExpected, 
        uint executorFee
    );
    event logOrderCancelled(uint id, address payable traderAddress, address assetIn, address assetOut, uint refundETH, uint refundToken);
    
    mapping(uint => Order) public orderBook;
    mapping(address => uint[]) private ordersForAddress;
    
    constructor(address weth) public Ownable(){
        WETH = weth;
    }
    
    function setNewStakeFee(uint256 _STAKE_FEE) external onlyOwner {
        STAKE_FEE = _STAKE_FEE;
    }
    
    function setNewExecutorFee(uint256 _EXECUTOR_FEE) external onlyOwner {
        EXECUTOR_FEE = _EXECUTOR_FEE;
    }
    
    function setNewStakeAddress(address _stakeAddress) external onlyOwner {
        require(_stakeAddress != address(0), 'Do not use 0 address');
        stakeAddress = _stakeAddress;
    }
    
    
    function updateOrder(Order memory order, OrderState newState) internal {
        if(orders.length > 1) {
            uint openId = order.ordersI;
            uint lastId = orders[orders.length-1];
            Order memory lastOrder = orderBook[lastId];
            lastOrder.ordersI = openId;
            orderBook[lastId] = lastOrder;
            orders[openId] = lastId;
        }
        orders.pop();
        order.orderState = newState;
        orderBook[order.id] = order;        
    }

    function createOrder(OrderType orderType, address assetIn, address assetOut, uint assetInOffered, uint assetOutExpected,address[] calldata path, uint executorFee) external payable {
        
        uint payment = msg.value;
        uint stakeValue = 0;
        
        require(assetInOffered > 0, "Asset in amount must be greater than 0");
        require(assetOutExpected > 0, "Asset out amount must be greater than 0");
        require(executorFee >= EXECUTOR_FEE, "Invalid fee");
        
        if(orderType == OrderType.EthForTokens) {
            require(assetIn == WETH, "Use WETH as the assetIn");
            stakeValue = assetInOffered.mul(STAKE_FEE).div(1000);
            require(payment == assetInOffered.add(executorFee).add(stakeValue), "Payment = assetInOffered + executorFee + stakeValue");
            
        }
        else {
            require(payment == executorFee, "Transaction value must match executorFee");
            if (orderType == OrderType.TokensForEth) { require(assetOut == WETH, "Use WETH as the assetOut"); }
            stakeValue = assetInOffered.mul(STAKE_FEE).div(1000);
            TransferHelper.safeTransferFrom(assetIn, msg.sender, address(this), assetInOffered.add(stakeValue));
        }
        
        uint orderId = ordersNum;
        ordersNum++;
        
        orderBook[orderId] = Order(OrderState.Created, orderType, payable(msg.sender), assetIn, assetOut, assetInOffered, 
        assetOutExpected, executorFee, stakeValue, orderId, orders.length,path);
        
        ordersForAddress[msg.sender].push(orderId);
        orders.push(orderId);
        
        emit logOrderCreated(
            orderId, 
            OrderState.Created, 
            orderType, 
            payable(msg.sender), 
            assetIn, 
            assetOut,
            assetInOffered, 
            assetOutExpected, 
            executorFee
        );
    }
    
    function executeOrder(
        uint orderId,
        address sellToken,
        address buyToken,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint value
    ) external  onlyExecutor {
        Order memory order = orderBook[orderId];  
        require(order.traderAddress != address(0), "Invalid order");
        require(order.orderState == OrderState.Created, 'Invalid order state');
        
        updateOrder(order, OrderState.Finished);
    
        uint boughtAmount =0;

        if(order.orderType == OrderType.TokensForEth) {
            boughtAmount = address(this).balance;
        }else{
            boughtAmount = IERC20(buyToken).balanceOf(address(this));
        }

        require(IERC20(sellToken).approve(spender, type(uint256).max));
        (bool success,) = swapTarget.call{value: value}(swapCallData);
        require(success, 'SWAP_CALL_FAILED');
        
        if(order.orderType == OrderType.TokensForEth) {
            boughtAmount = address(this).balance - boughtAmount;
            TransferHelper.safeTransferETH(order.traderAddress, boughtAmount);
        }else{
            boughtAmount = IERC20(buyToken).balanceOf(address(this))-boughtAmount;
            TransferHelper.safeTransfer(buyToken, order.traderAddress, boughtAmount);
        }

        if (order.orderType == OrderType.EthForTokens) {
            TransferHelper.safeTransferETH(stakeAddress, order.stake);
        } 
        else{
            TransferHelper.safeTransfer(order.assetIn, stakeAddress, order.stake);
        }
        
        TransferHelper.safeTransferETH(msg.sender, order.executorFee);
    }
    
    function cancelOrder(uint orderId) external {
        Order memory order = orderBook[orderId];  
        require(order.traderAddress != address(0), "Invalid order");
        require(msg.sender == order.traderAddress, 'This order is not yours');
        require(order.orderState == OrderState.Created, 'Invalid order state');
        
        updateOrder(order, OrderState.Cancelled);
        
        uint refundETH = 0;
        uint refundToken = 0;
        
        if (order.orderType != OrderType.EthForTokens) {
            refundETH = order.executorFee;
            refundToken = order.assetInOffered.add(order.stake);
            TransferHelper.safeTransferETH(order.traderAddress, refundETH);
            TransferHelper.safeTransfer(order.assetIn, order.traderAddress, refundToken);
        }
        else {
            refundETH = order.assetInOffered.add(order.executorFee).add(order.stake);
            TransferHelper.safeTransferETH(order.traderAddress, refundETH);  
        }
        
        emit logOrderCancelled(order.id, order.traderAddress, order.assetIn, order.assetOut, refundETH, refundToken);        
    }
    
    function getOrdersLength() external onlyExecutor view returns (uint) {
        return orders.length;
    }
    
    function getOrdersForAddressLength(address _address) external onlyExecutor view returns (uint)
    {
        return ordersForAddress[_address].length;
    }

    function getOrderIdForAddress(address _address, uint index) external onlyExecutor view returns (uint)
    {
        return ordersForAddress[_address][index];
    }    
    
    receive() external payable {}
    // Transfer ETH into this contract and wrap it into WETH.
    function depositETH()
        external
        payable
    {
        IWETH(WETH).deposit{value: msg.value}();
    }


    function marketSwap (
        OrderType orderType, 
        address sellToken,
        address buyToken,
        address spender,
        address payable swapTarget,
        bytes calldata swapCallData,
        uint assetInOffered
    )
        external
        onlyExecutor
        payable // Must attach ETH equal to the `value` field from the API response.
    {
        uint payment = msg.value;
        uint stakeValue = 0;
        
        if(orderType == OrderType.EthForTokens) {
            require(sellToken == WETH, "Use WETH as the assetIn");
            stakeValue = assetInOffered.mul(STAKE_FEE).div(1000);
            require(payment == assetInOffered.add(stakeValue), "Payment = assetInOffered + stakeValue");
            TransferHelper.safeTransferETH(stakeAddress, stakeValue);
        }else{
            if (orderType == OrderType.TokensForEth) { require(buyToken == WETH, "Use WETH as the assetOut"); }
            stakeValue = assetInOffered.mul(STAKE_FEE).div(1000);
            TransferHelper.safeTransferFrom(sellToken, msg.sender, address(this), assetInOffered.add(stakeValue));
            TransferHelper.safeTransfer(sellToken, stakeAddress, stakeValue);
        }
        uint boughtAmount =0;

        if(orderType == OrderType.TokensForEth) {
            boughtAmount = address(this).balance;
        }else{
            boughtAmount = IERC20(buyToken).balanceOf(address(this));
        }

        require(IERC20(sellToken).approve(spender, type(uint256).max));
        (bool success,) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, 'SWAP_CALL_FAILED');
        
        if(orderType == OrderType.TokensForEth) {
            boughtAmount = address(this).balance - boughtAmount;
            TransferHelper.safeTransferETH(msg.sender, boughtAmount);
        }else{
            boughtAmount = IERC20(buyToken).balanceOf(address(this))-boughtAmount;
            TransferHelper.safeTransfer(buyToken, msg.sender, boughtAmount);
        }

    }

    function withdrawToken(address _tokenContract, uint256 _amount) public virtual onlyOwner {
        if(_tokenContract==NATIVE){
            TransferHelper.safeTransferETH(msg.sender, _amount);
        }else{
            IERC20 tokenContract = IERC20(_tokenContract);
            tokenContract.transfer(msg.sender, _amount);        
        }

    }

}