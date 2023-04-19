/**
 *Submitted for verification at BscScan.com on 2023-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDexFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }
}

contract marketmakerpairV1 is permission {

    address public owner;
    address pcv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address tokenAddress = 0xd4D984b949bd01EA6Ed66292cB26602650125AAa;
    address busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    IDexRouter router;
    IDexFactory factory;

    IBEP20 token;
    IBEP20 busd;

    uint256 public countTx;

    struct TX {
        address from;
        address to;
        uint256 amount;
        bool isBuy;
        uint256 price;
    }
    
    mapping(uint256 => TX) public txs;

    uint256 public balancePrice = 50000;
    uint256 public buyThreshold = 15 * 1e18;
    uint256 public sellThreshold = 300000000000000;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        router = IDexRouter(pcv2);
        factory = IDexFactory(router.factory());
        token = IBEP20(tokenAddress);
        busd = IBEP20(busdAddress);
        token.approve(pcv2,type(uint256).max);
        busd.approve(pcv2,type(uint256).max);
    }

    function beforetransfer(address from,address to, uint256 amount) external returns (bool){
        require(msg.sender==tokenAddress,"Only Token!");
        countTx += 1;
        address pair = factory.getPair(tokenAddress,busdAddress);
        uint256 currentPrice = _currentPrice(pair);
        if(from==pair){ _updateTX(countTx,from,to,amount,true,currentPrice); }
        if(to==pair){ _updateTX(countTx,from,to,amount,false,currentPrice); }
        return true;
    }
    
    function aftertransfer(address from,address to, uint256 amount) external returns (bool){
        require(msg.sender==tokenAddress,"Only Token!");
        address pair = factory.getPair(tokenAddress,busdAddress);
        uint256 currentPrice = _currentPrice(pair);
        if(from==pair||to==pair){
            if(amount>0){
                if(currentPrice>balancePrice){
                    marketSell();
                }else{
                    marketBuy();
                }
            }
        }
        return true;
    }

    function marketBuy() internal {
        if(busd.balanceOf(address(this))>=buyThreshold){
            address[] memory path = new address[](2);
            path[0] = busdAddress;
            path[1] = tokenAddress;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                buyThreshold,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function marketSell() internal {
        if(token.balanceOf(address(this))>=sellThreshold){
            address[] memory path = new address[](2);
            path[0] = tokenAddress;
            path[1] = busdAddress;
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                sellThreshold,
                0,
                path,
                address(this),
                block.timestamp
            );
        }
    }

    function _currentPrice(address pair) public view returns (uint256) {
        uint256 balanceBUSD = busd.balanceOf(pair);
        uint256 balanceToken = token.balanceOf(pair);
        return balanceBUSD / balanceToken;
    }

    function _updateTX(uint256 txid,address from,address to,uint256 amount,bool isBuy,uint256 price) internal {
        txs[txid].from = from;
        txs[txid].to = to;
        txs[txid].amount = amount;
        txs[txid].isBuy = isBuy;
        txs[txid].price = price;
    }

    function settingMaketMakerPrice(uint256 _balancePrice,uint256 _buyThreshold,uint256 _sellThreshold) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        balancePrice = _balancePrice;
        buyThreshold = _buyThreshold;
        sellThreshold = _sellThreshold;
        return true;
    }

    function transferOwnership(address adr) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        owner = adr;
        return true;
    }

    function purge(address _token) public returns (bool) {
      require(checkpermit(msg.sender,"owner"));
      uint256 amount = IBEP20(_token).balanceOf(address(this));
      IBEP20(_token).transfer(msg.sender,amount);
      return true;
    }
}