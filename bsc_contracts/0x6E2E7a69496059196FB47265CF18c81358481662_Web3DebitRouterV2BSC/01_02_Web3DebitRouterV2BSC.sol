// SPDX-License-Identifier: MIT
pragma solidity = 0.8.17;

import "./ReentrancyGuard.sol";


interface IGateway {

    function payment(
        address _store,
        address _token,
        uint _amount,
        uint _memo,
        address _sender,
        uint _source,
        address _tokenin,
        uint amountIn) external returns (bool);

}


interface IStargateRouter {

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }


    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload) external payable;

}


interface ERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);

}


interface ISwapRouterUniswapV2 {

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline) external returns (uint[] memory amounts);


    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external payable returns (uint[] memory amounts);


    function WETH() external pure returns (address);

}


contract Web3DebitRouterV2BSC is ReentrancyGuard {

ISwapRouterUniswapV2 public immutable swapRouterUniswapV2;
IStargateRouter public immutable stargateRouter;

uint public immutable source;

IGateway public gateway;
address public owner;
bool public locked;

struct DataToStargate {

    uint16 dstChainId_;
    uint256 srcPoolId_;
    uint256 dstPoolId_;
    uint256 amountLD_;
    uint256 minAmountLD_;
    uint256 gasfee_;
    uint thememo_;    
    address receiverAddress_;
    address tokenincross_;
    address thestore_;
    address tokenoutcross_;

}

struct DataToStargate1 {

     uint thetimeswap;
     uint theamountInMaximum;
     uint amountLD;
     uint16 dstChainId;
     uint srcPoolId;
     uint dstPoolId;
     uint minAmountLD;
     uint gasfee;
     address receiverAddress;
     address thestore;
     address tokenoutcross;
     uint theamountpay;
     uint thememo;

}

struct DataSwap {

    address tokenIn;
    address tokenOut;
    uint timeswap;
    uint amountOut;
    uint amountInMaximum;
    address store;
    uint memo;

}


event Routed(
    address indexed store,
    address indexed sender,
    uint memo,
    address tokenin,
    address tokenout,
    uint amountin,
    uint amountout,
    uint destchain,
    uint srcpool,
    uint dstpool,
    uint amountoutfixed);


event ReceivedFromStargate(
    uint _nonce,
    address _token,                  
    uint256 amountLD,
    address indexed store,
    address indexed sender,
    uint amountout,
    uint memo,
    uint source);
     

constructor(
    ISwapRouterUniswapV2 _swapRouterUniswapV2,
    IGateway _gateway,
    IStargateRouter _stargateRouter,
    uint _sourcechain,
    address _owner) {
        
    require(_owner != address(0));
    require(_sourcechain > 0);

    swapRouterUniswapV2 = _swapRouterUniswapV2;
    gateway = _gateway;
    source = _sourcechain;
    owner = _owner;
    stargateRouter = _stargateRouter;

}


modifier onlyOwner() {

    require(msg.sender == owner);
    _;

}


function transferOwner(address _newowner) external onlyOwner {

    require(_newowner != address(0));
    owner = _newowner;

}


function lockRouter() external onlyOwner {

    if (locked) {
        locked = false;
    }

    if (!locked) {
        locked = true;
    }

}


function changeGateway(IGateway _gateway) external onlyOwner {
    
    gateway = _gateway;

}


function noSwapPayOnChainSameERC20(address _tokenOut, uint256 _amountOut, address _store, uint _memo) external nonReentrant {

    require(!locked);
    require(_store != address(0));
    require(_tokenOut != address(0));
    require(_memo > 0);
    require(_amountOut > 0);

    require(ERC20(_tokenOut).balanceOf(msg.sender) >= _amountOut);
    require(ERC20(_tokenOut).allowance(msg.sender, address(this)) >= _amountOut);
    require(ERC20(_tokenOut).transferFrom(msg.sender, address(this), _amountOut));
    
    require(ERC20(_tokenOut).approve(address(gateway), _amountOut));
    require(gateway.payment(_store, _tokenOut, _amountOut, _memo, msg.sender, source, _tokenOut, _amountOut));

    emit Routed(
        _store,
        msg.sender,
        _memo,
        _tokenOut,
        _tokenOut,
        _amountOut,
        _amountOut,
        0,
        0,
        0,
        0);

}


function swapExactOutputAndPayOnChainERC20(
    address[] memory path,
    uint256 _timeswap,
    uint256 _amountOut,
    uint256 _amountInMaximum,
    address _store,
    uint _memo) external nonReentrant {

    require(!locked);
    require(_store != address(0));
    require(path[0] != address(0));
    require(path[path.length - 1] != address(0));
    
    require(_timeswap > block.timestamp);
    require(_amountOut > 0);
    require(_amountInMaximum > 0);
    require(_memo > 0);

    DataSwap memory _dataswap = DataSwap(
        
        path[0],
        path[path.length - 1],
        _timeswap,
        _amountOut,
        _amountInMaximum,
        _store,
        _memo);

    _swapExactOutputAndPayOnChainERC20(_dataswap, path);

}


function _swapExactOutputAndPayOnChainERC20(DataSwap memory _dataswap, address[] memory path) internal {
    
    require(ERC20(_dataswap.tokenIn).balanceOf(msg.sender) >= _dataswap.amountInMaximum);
    require(ERC20(_dataswap.tokenIn).allowance(msg.sender, address(this)) >= _dataswap.amountInMaximum);
    require(ERC20(_dataswap.tokenIn).transferFrom(msg.sender, address(this), _dataswap.amountInMaximum));
    require(ERC20(_dataswap.tokenIn).approve(address(swapRouterUniswapV2), _dataswap.amountInMaximum));

    uint balancestart = ERC20(_dataswap.tokenOut).balanceOf(address(this));

    uint[] memory amountIn;

    amountIn = swapRouterUniswapV2.swapTokensForExactTokens(
        _dataswap.amountOut,
        _dataswap.amountInMaximum,
        path,
        address(this),
        _dataswap.timeswap);

    require((ERC20(_dataswap.tokenOut).balanceOf(address(this)) - balancestart) == _dataswap.amountOut);
        
    if (amountIn[0] < _dataswap.amountInMaximum) {
        require(ERC20(_dataswap.tokenIn).approve(address(swapRouterUniswapV2), 0));
        require(ERC20(_dataswap.tokenIn).transfer(msg.sender, _dataswap.amountInMaximum - amountIn[0]));
    }

    require(ERC20(_dataswap.tokenOut).approve(address(gateway), _dataswap.amountOut));

    require(gateway.payment(
        _dataswap.store,
        _dataswap.tokenOut,
        _dataswap.amountOut,
        _dataswap.memo,
        msg.sender,
        source,
        _dataswap.tokenIn,
        amountIn[0]));

    emit Routed(
        _dataswap.store,
        msg.sender,
        _dataswap.memo,
        _dataswap.tokenIn,
        _dataswap.tokenOut,
        amountIn[0],
        _dataswap.amountOut,
        0,
        0,
        0,
        0);

}


function swapExactOutputAndPayOnChainNATIVE(
    address[] memory path,
    uint256 _timeswap,
    uint256 _amountOut,
    uint256 _amountInMaximum,
    address _store,
    uint _memo) external payable nonReentrant {

    require(!locked);
    require(_store != address(0));
    require(path[0] != address(0));
    require(path[path.length - 1] != address(0));

    require(_timeswap > block.timestamp);
    require(_amountOut > 0);
    require(_amountInMaximum > 0);
    require(_memo > 0);

    require(msg.value == _amountInMaximum);

    DataSwap memory _dataswap = DataSwap(
        swapRouterUniswapV2.WETH(),
        path[path.length - 1],
        _timeswap,
        _amountOut,
        _amountInMaximum,
        _store,
        _memo);

    require(path[0] == _dataswap.tokenIn);

    _swapExactOutputAndPayOnChainNATIVE(_dataswap, path);

}


function _swapExactOutputAndPayOnChainNATIVE(DataSwap memory _dataswap, address[] memory path) internal {

    uint balancestart = ERC20(_dataswap.tokenOut).balanceOf(address(this));

    uint[] memory amountIn;

    amountIn = swapRouterUniswapV2.swapETHForExactTokens{value: msg.value}(
    _dataswap.amountOut,
    path,
    address(this),
    _dataswap.timeswap);

    require((ERC20(_dataswap.tokenOut).balanceOf(address(this)) - balancestart) == _dataswap.amountOut);
                
    if (amountIn[0] < _dataswap.amountInMaximum) {

        (bool success,) = msg.sender.call{ value: _dataswap.amountInMaximum - amountIn[0] }("");
    }
      
    require(ERC20(_dataswap.tokenOut).approve(address(gateway), _dataswap.amountOut));
 
    require(gateway.payment(
        _dataswap.store,
        _dataswap.tokenOut,
        _dataswap.amountOut,
        _dataswap.memo,
        msg.sender,
        source,
        _dataswap.tokenIn,
        amountIn[0]));
        
    emit Routed(
        _dataswap.store,
        msg.sender,
        _dataswap.memo,
        _dataswap.tokenIn,
        _dataswap.tokenOut,
        amountIn[0],
        _dataswap.amountOut,
        0,
        0,
        0,
        0);

}


function withdrawEther() external payable onlyOwner nonReentrant {
  
    (bool sent,) = owner.call{value: address(this).balance}("");
    require(sent, "Failed to send Ether");

}


function balanceEther() external view returns (uint) {
 
    return address(this).balance;

}


function swapToStargate(
    uint16 dstChainId,
    uint256 srcPoolId,
    uint256 dstPoolId,
    uint256 amountLD,
    uint256 minAmountLD,
    uint256 gasfee,
    address receiverAddress,
    address tokenincross,
    address thestore,
    uint thememo,    
    address tokenoutcross,
    uint theamountpay) external payable nonReentrant {

    require(!locked);
    require(msg.value > 0);

    require(amountLD > 0);
    require(minAmountLD > 0);
    require(dstChainId > 0);
    require(srcPoolId > 0);
    require(dstPoolId > 0);
    require(gasfee > 0);
    require(receiverAddress != address(0));
    require(tokenincross != address(0));
    require(thestore != address(0));
    require(tokenoutcross != address(0));
    require(thememo > 0);
    require(theamountpay > 0);

    DataToStargate memory _datastargate = DataToStargate(
        dstChainId,
        srcPoolId,
        dstPoolId,
        amountLD,
        minAmountLD,
        gasfee,
        thememo,    
        receiverAddress,
        tokenincross,
        thestore,
        tokenoutcross);

    _swapToStargate(_datastargate, theamountpay);
    
}


function _swapToStargate(DataToStargate memory _datastargate, uint theamountpay) internal {
    
    require(ERC20(_datastargate.tokenincross_).balanceOf(msg.sender) >= _datastargate.amountLD_);
    require(ERC20(_datastargate.tokenincross_).allowance(msg.sender, address(this)) >= _datastargate.amountLD_);
    require(ERC20(_datastargate.tokenincross_).transferFrom(msg.sender, address(this), _datastargate.amountLD_));

    require(ERC20(_datastargate.tokenincross_).approve(address(stargateRouter), _datastargate.amountLD_));

    bytes memory data = abi.encode(
        _datastargate.thestore_,
        _datastargate.tokenoutcross_,
        theamountpay,
        _datastargate.thememo_,
        msg.sender,
        source,
        _datastargate.tokenincross_,
        _datastargate.amountLD_);


    stargateRouter.swap{value:msg.value}(
        _datastargate.dstChainId_,                           
        _datastargate.srcPoolId_,                            
        _datastargate.dstPoolId_,                            
        payable(msg.sender),                      
        _datastargate.amountLD_,                  
        _datastargate.minAmountLD_,                
        IStargateRouter.lzTxObj(_datastargate.gasfee_, 0, "0x"), 
        abi.encodePacked(_datastargate.receiverAddress_), 
        data);                     
    

    emit Routed(
        _datastargate.thestore_,
        msg.sender,
        _datastargate.thememo_,
        _datastargate.tokenincross_,
        _datastargate.tokenoutcross_,
        _datastargate.amountLD_,
        theamountpay,
        _datastargate.dstChainId_,
        _datastargate.srcPoolId_,
        _datastargate.dstPoolId_,
        _datastargate.minAmountLD_);

}


function swapExactOutputAndPayCrossChainERC20(
    address[] memory path,
    DataToStargate1 memory datastruct) external payable nonReentrant {
        
    require(!locked);
    require(msg.value > 0);

    DataToStargate1 memory data = datastruct;

     require(data.thetimeswap > block.timestamp);
     require(data.theamountInMaximum > 0);
     require(data.amountLD > 0);
     require(data.dstChainId > 0);
     require(data.srcPoolId > 0);
     require(data.dstPoolId > 0);
     require(data.minAmountLD > 0);
     require(data.gasfee > 0);
     require(data.receiverAddress != address(0));
     require(data.thestore != address(0));
     require(data.tokenoutcross != address(0));
     require(data.theamountpay > 0);
     require(data.thememo > 0);

    require(path[0] != address(0));
    require(path[path.length - 1] != address(0));

    _swapExactOutputAndPayCrossChainERC20(data, path);

}


function _swapExactOutputAndPayCrossChainERC20(
    DataToStargate1 memory data,
    address[] memory path) internal {

    require(ERC20(path[0]).balanceOf(msg.sender) >= data.theamountInMaximum);
    require(ERC20(path[0]).allowance(msg.sender, address(this)) >= data.theamountInMaximum);
    require(ERC20(path[0]).transferFrom(msg.sender, address(this), data.theamountInMaximum));
    require(ERC20(path[0]).approve(address(swapRouterUniswapV2), data.theamountInMaximum));

    uint balancestart = ERC20(path[path.length - 1]).balanceOf(address(this));

    uint[] memory amountIn;

    amountIn = swapRouterUniswapV2.swapTokensForExactTokens(
        data.amountLD,
        data.theamountInMaximum,
        path,
        address(this),
        data.thetimeswap);

    require((ERC20(path[path.length - 1]).balanceOf(address(this)) - balancestart) == data.amountLD);
        
    if (amountIn[0] < data.theamountInMaximum) {
        require(ERC20(path[0]).approve(address(swapRouterUniswapV2), 0));
        require(ERC20(path[0]).transfer(msg.sender, data.theamountInMaximum - amountIn[0]));
    }
    
    require(ERC20(path[path.length - 1]).approve(address(stargateRouter), data.amountLD));
    
    _swapToStargateFromERC20(data, amountIn[0], path[0]);

}


function _swapToStargateFromERC20(
    DataToStargate1 memory data,
    uint amountIn,
    address thetokenIn) internal {

    bytes memory datapayload = abi.encode(
        data.thestore,
        data.tokenoutcross,
        data.theamountpay,
        data.thememo,
        msg.sender,
        source,
        thetokenIn,
        amountIn);

    stargateRouter.swap{value: msg.value}(
        data.dstChainId,                          
        data.srcPoolId,                           
        data.dstPoolId,                           
        payable(msg.sender),                      
        data.amountLD,                  
        data.minAmountLD,               
        IStargateRouter.lzTxObj(data.gasfee, 0, "0x"),  
        abi.encodePacked(data.receiverAddress),    
        datapayload);                      

    emit Routed(
        data.thestore,
        msg.sender,
        data.thememo,
        thetokenIn,
        data.tokenoutcross,
        amountIn,
        data.theamountpay,
        data.dstChainId,
        data.srcPoolId,
        data.dstPoolId,
        data.minAmountLD);

}


function swapExactOutputAndPayCrossChainNATIVE(
    address[] memory path,
    DataToStargate1 memory datastruct) external payable nonReentrant {
            
    require(!locked);
    require(msg.value > 0);

    DataToStargate1 memory data = datastruct;

    require(swapRouterUniswapV2.WETH() == path[0]);

     require(data.thetimeswap > block.timestamp);
     require(data.theamountInMaximum > 0);
     require(data.amountLD > 0);
     require(data.dstChainId > 0);
     require(data.srcPoolId > 0);
     require(data.dstPoolId > 0);
     require(data.minAmountLD > 0);
     require(data.gasfee > 0);
     require(data.receiverAddress != address(0));
     require(data.thestore != address(0));
     require(data.tokenoutcross != address(0));
     require(data.theamountpay > 0);
     require(data.thememo > 0);

    require(path[0] != address(0));
    require(path[path.length - 1] != address(0));

    _swapExactOutputAndPayCrossChainNATIVE(data, path);

}


function _swapExactOutputAndPayCrossChainNATIVE(
    DataToStargate1 memory data,
    address[] memory path) internal {

    uint balancestart = ERC20(path[path.length - 1]).balanceOf(address(this));

    uint[] memory amountIn;

    amountIn = swapRouterUniswapV2.swapETHForExactTokens{value: data.theamountInMaximum}(
    data.amountLD,
    path,
    address(this),
    data.thetimeswap);

    require((ERC20(path[path.length - 1]).balanceOf(address(this)) - balancestart) == data.amountLD);

    if (amountIn[0] < data.theamountInMaximum) {
                        
        (bool success,) = msg.sender.call{ value: data.theamountInMaximum - amountIn[0] }("");
    }
    
    require(ERC20(path[path.length - 1]).approve(address(stargateRouter), data.amountLD));
    
    _swapToStargateFromNATIVE(data, amountIn[0], path[0]);

}


function _swapToStargateFromNATIVE(
    DataToStargate1 memory data,
    uint amountIn,
    address thetokenIn) internal {
 
    bytes memory datapayload = abi.encode(
        data.thestore,
        data.tokenoutcross,
        data.theamountpay,
        data.thememo,
        msg.sender,
        source,
        thetokenIn,
        amountIn);

    stargateRouter.swap{value: msg.value - data.theamountInMaximum}(
        data.dstChainId,                          
        data.srcPoolId,                           
        data.dstPoolId,                           
        payable(msg.sender),                      
        data.amountLD,                  
        data.minAmountLD,                  
        IStargateRouter.lzTxObj(data.gasfee, 0, "0x"), 
        abi.encodePacked(data.receiverAddress),    
        datapayload);                     

    emit Routed(
        data.thestore,
        msg.sender,
        data.thememo,
        thetokenIn,
        data.tokenoutcross,
        amountIn,
        data.theamountpay,
        data.dstChainId,
        data.srcPoolId,
        data.dstPoolId,
        data.minAmountLD);

}


function sgReceive(
    uint16 /*_srcChainId*/,            
    bytes memory /*_srcAddress*/,      
    uint256 _nonce,                  
    address _token,                
    uint256 amountLD,              
    bytes memory payload) external nonReentrant {

    require(msg.sender == address(stargateRouter)); 

    (address thestore,
     address thetoken,
     uint theamount,
     uint thememo,
     address thesender,
     uint thesource,
     address thetokenin,
     uint theamountin) = abi.decode(payload, (address, address, uint, uint, address, uint, address, uint));


    if (amountLD > theamount) {
        require(ERC20(thetoken).transfer(thesender, amountLD - theamount));
    }

    require(ERC20(thetoken).approve(address(gateway), theamount));

    require(gateway.payment(thestore, thetoken, theamount, thememo, thesender, thesource, thetokenin, theamountin));

    emit ReceivedFromStargate(
        _nonce,
        _token,
        amountLD,
        thestore,
        thesender,
        theamount,
        thememo,
        thesource);
    
}    


receive() payable external {}

}