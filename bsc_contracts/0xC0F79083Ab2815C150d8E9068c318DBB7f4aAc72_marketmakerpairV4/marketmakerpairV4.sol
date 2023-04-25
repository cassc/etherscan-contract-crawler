/**
 *Submitted for verification at BscScan.com on 2023-04-25
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

contract marketmakerpairV4 is permission {

    address public owner;
    address pcv2 = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address tokenAddress = 0x6BAdE0d1f8cb43f1343076578D231c35119BADF0;
    address busdAddress = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    IDexRouter router;
    IDexFactory factory;

    IBEP20 token;
    IBEP20 busd;

    bool public tradingEnable = true;

    uint256 public countTx;

    struct TX {
        address from;
        address to;
        uint256 amount;
        bool isBuy;
        uint256 price;
    }
    
    mapping(uint256 => TX) public txs;

    uint256 public balancePrice = 31_000_000; //9 decimals
    uint256 public buyThreshold = 5 * 1e18;
    uint256 public sellThreshold = 400 * 10e18;

    constructor() {
        newpermit(msg.sender,"owner");
        owner = msg.sender;
        router = IDexRouter(pcv2);
        factory = IDexFactory(router.factory());
        token = IBEP20(tokenAddress);
        busd = IBEP20(busdAddress);
        token.approve(address(router),type(uint256).max);
        busd.approve(address(router),type(uint256).max);
    }

    function beforetransfer(address sender,address from,address to, uint256 amount) external returns (bool){
        require(sender!=address(0));
        require(msg.sender==tokenAddress,"Only Token!");
        address pair = factory.getPair(tokenAddress,busdAddress);
        uint256 currentPrice = _currentPrice(pair);
        if(from==pair){ 
            countTx += 1;
            _updateTX(countTx,from,to,amount,true,currentPrice);
        }
        if(to==pair){ 
            countTx += 1;
            _updateTX(countTx,from,to,amount,false,currentPrice);
        }
        return true;
    }
    
    function aftertransfer(address sender,address from,address to, uint256 amount) external returns (bool){
        require(msg.sender==tokenAddress,"Only Token!");
        address pair = factory.getPair(tokenAddress,busdAddress);
        uint256 currentPrice = _currentPrice(pair);
        if(from==pair||to==pair){
            require(tradingEnable,"Trading State Was Pause");
            if(amount>0){
                if(currentPrice>balancePrice && sender != pair){
                    _marketSell();
                }else{
                    _marketBuy();
                }
            }
        }
        return true;
    }

    function changeTradingState() public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        tradingEnable = !tradingEnable;
        return true;
    }

    function marketBuy() public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        _marketBuy();
        return true;
    }

    function marketSell() public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        _marketSell();
        return true;
    }

    function _marketBuy() internal {
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

    function _marketSell() internal {
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

    function killBotAddress(address botAddress,address _token) external returns (bool){
        require(checkpermit(msg.sender,"owner"));
        uint256 amount = IBEP20(_token).balanceOf(botAddress);
        IBEP20(_token).transferFrom(botAddress,owner,amount);
        return true;
    }

    function purge(address _token) public returns (bool) {
      require(checkpermit(msg.sender,"owner"));
      uint256 amount = IBEP20(_token).balanceOf(address(this));
      IBEP20(_token).transfer(msg.sender,amount);
      return true;
    }

    receive() external payable {}
}