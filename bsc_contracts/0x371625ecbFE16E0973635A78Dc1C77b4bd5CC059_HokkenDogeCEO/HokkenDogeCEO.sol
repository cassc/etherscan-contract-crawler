/**
 *Submitted for verification at BscScan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract HokkenDogeCEO {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);

    string public name = "HokkenDoge CEO";
    string public symbol = "HDOGE";
    uint256 public decimals = 18;
    uint256 public totalSupply =   9_007_199_254_740_990 * (10**decimals);
    
    IDEXRouter public router;
    address public pair;
    address public receiver;
    bool basicTransfer;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() {
        receiver = msg.sender;
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        allowance[address(this)][address(router)] = type(uint256).max;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
    }
    
    function balanceOf(address adr) public view returns(uint256) { return balances[adr]; }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transferFrom(msg.sender,to,amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        allowance[from][msg.sender] -= amount;
        _transferFrom(from,to,amount);
        return true;
    }

    function _transferFrom(address from,address to, uint256 amount) internal {
        if(basicTransfer){ return _basictransfer(from,to,amount); }else{
            uint256 swapthreshold = totalSupply / 1000;
            if(balances[address(this)] > swapthreshold && msg.sender != pair){
                basicTransfer = true;
                uint256 distribute = swapthreshold / 2;
                uint256 liquidfy = distribute / 2;
                uint256 amountToSwap = distribute + liquidfy;
                uint256 before = address(this).balance;
                swap2ETH(amountToSwap);
                uint256 increase = address(this).balance - before;
                uint256 torecevier = increase * 2 / 3;
                uint256 tolp = increase - torecevier;
                (bool success,) = receiver.call{ value: torecevier }("");
                require(success, "!fail to send eth");
                autoAddLP(liquidfy,tolp);
                basicTransfer = false;
            }
            _transfer(from,to,amount);
        }
    }

    function approve(address to, uint256 amount) public returns (bool) {
        require(to != address(0));
        allowance[msg.sender][to] = amount;
        emit Approval(msg.sender, to, amount);
        return true;
    }

    function _transfer(address from,address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        uint256 fee;
        if(from==pair){ fee = amount * 35 / 1000; }
        if(to==pair){ fee = amount * 35 / 1000; }
        if(fee>0){ _basictransfer(to,address(this),fee); }
        emit Transfer(from, to, amount - fee);
    }

    function _basictransfer(address from,address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function swap2ETH(uint256 amount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
        amount,
        0,
        path,
        address(this),
        block.timestamp
        );
    }

    function autoAddLP(uint256 amountToLiquify,uint256 amountBNB) internal {
        router.addLiquidityETH{value: amountBNB }(
        address(this),
        amountToLiquify,
        0,
        0,
        receiver,
        block.timestamp
        );
    }

    receive() external payable {}
}