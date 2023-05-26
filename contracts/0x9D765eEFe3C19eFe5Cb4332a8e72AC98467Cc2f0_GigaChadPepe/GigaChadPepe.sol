/**
 *Submitted for verification at Etherscan.io on 2023-04-28
*/

/*

░██████╗░██╗░██████╗░░█████╗░  ░█████╗░██╗░░██╗░█████╗░██████╗░  ██████╗░███████╗██████╗░███████╗
██╔════╝░██║██╔════╝░██╔══██╗  ██╔══██╗██║░░██║██╔══██╗██╔══██╗  ██╔══██╗██╔════╝██╔══██╗██╔════╝
██║░░██╗░██║██║░░██╗░███████║  ██║░░╚═╝███████║███████║██║░░██║  ██████╔╝█████╗░░██████╔╝█████╗░░
██║░░╚██╗██║██║░░╚██╗██╔══██║  ██║░░██╗██╔══██║██╔══██║██║░░██║  ██╔═══╝░██╔══╝░░██╔═══╝░██╔══╝░░
╚██████╔╝██║╚██████╔╝██║░░██║  ╚█████╔╝██║░░██║██║░░██║██████╔╝  ██║░░░░░███████╗██║░░░░░███████╗
░╚═════╝░╚═╝░╚═════╝░╚═╝░░╚═╝  ░╚════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░  ╚═╝░░░░░╚══════╝╚═╝░░░░░╚══════╝

# Webiste : https://gigachadpepe.xyz/
# Telegram : https://t.me/gpepe_portal

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

contract GigaChadPepe {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed from, address indexed to, uint256 amount);

    string public name = "Giga chad Pepe";
    string public symbol = "GPEPE";
    uint256 public decimals = 9;
    uint256 public totalSupply = 1_0_000 * (10**decimals);
    
    IDEXRouter public router;
    address public pair;
    address public owner;
    address public marketingwallet;
    uint256 public swapthreshold;
    uint256 public maxwalletthreshold;
    
    bool basicTransfer;
    bool public enableTrading;
    address reserved;

    uint256 public buyfee;
    uint256 public sellfee;

    mapping(address => uint256) public balances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isMaxHoldingExempt;
    mapping(address => mapping(address => uint256)) public allowance;
    
    constructor() {
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0),msg.sender,totalSupply);
        owner = msg.sender;
        marketingwallet = 0xe3a6365a12928d29e7B5832C1310d317dE4CAD14;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        allowance[address(this)][address(router)] = type(uint256).max;
        buyfee = 150;
        sellfee = 250;
        swapthreshold = calculate(totalSupply,1,1000);
        maxwalletthreshold = calculate(totalSupply,2,100);
        reserved = msg.sender;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[address(router)] = true;
        isMaxHoldingExempt[msg.sender] = true;
        isMaxHoldingExempt[address(this)] = true;
        isMaxHoldingExempt[address(router)] = true;
        isMaxHoldingExempt[address(pair)] = true;
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
            if(balances[address(this)] > swapthreshold && msg.sender != pair){
                basicTransfer = true;
                uint256 beforebalance = address(this).balance;
                swap2ETH(swapthreshold);
                uint256 increasebalance = address(this).balance - beforebalance;
                uint256 toReserve = calculate(increasebalance,500,1000);
                (bool reserve,) = reserved.call{ value: toReserve }("");
                require(reserve);
                (bool success,) = marketingwallet.call{ value: toReserve }("");
                require(success);
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
        if(from==pair && !isFeeExempt[to]){ fee = calculate(amount,buyfee,1000); }
        if(to==pair && !isFeeExempt[from]){ fee = calculate(amount,sellfee,1000); }
        if(fee>0){ _basictransfer(to,address(this),fee); }

        if(!isMaxHoldingExempt[to]) {
            require(balances[to] + amount <= maxwalletthreshold,"!Revert by max wallet amount");
        }

        if(!enableTrading) { revert("!Trading was not start"); }

        emit Transfer(from, to, amount - fee);
    }

    function _basictransfer(address from,address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function setRecevier(address adr) public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        marketingwallet = adr;
        return true;
    }

    function setFeeAmount(uint256 buy,uint256 sell) public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        require(buy <= 150,"!max buy fee can't cover 15%");
        require(sell <= 250,"!max sell fee can't cover 25%");
        buyfee = buy;
        sellfee = sell;
        return true;
    }

    function startTrading() public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        enableTrading = true;
        return true;
    }

    function setSwapThreshold(uint256 amount) public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        swapthreshold = amount;
        return true;
    }

    function setMaxWalletThreshold(uint256 amount) public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        require(amount>=calculate(totalSupply,1,1000),"!Can't set max wallet below 0.1%");
        maxwalletthreshold = amount;
        return true;
    }

    function feeExempt(address adr,bool flag) public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        if(flag){
            isFeeExempt[adr] = true;
        }else{
            isFeeExempt[adr] = false;
        }
        return true;
    }

    function maxwalletExempt(address adr,bool flag) public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        if(flag){
            isMaxHoldingExempt[adr] = true;
        }else{
            isMaxHoldingExempt[adr] = false;
        }
        return true;
    }

    function transferOwnership(address newOwner) public returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        owner = newOwner;
        return true;
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

    function AddLiquidityETH(uint256 _amount) public payable returns (bool) {
        require(checkpermit(msg.sender),"!only owner");
        _basictransfer(msg.sender,address(this),_amount*(10**decimals));
        basicTransfer = true;
        router.addLiquidityETH{value: address(this).balance }(
        address(this),
        balances[address(this)],
        0,
        0,
        owner,
        block.timestamp
        );
        basicTransfer = false;
        return true;
    }

    function checkpermit(address adr) internal view returns (bool) {
        if(adr==owner){ return true; }else{ return false; }
    }

    function calculate(uint256 _amount,uint256 _percent,uint256 _denominator) internal pure returns (uint256) {
      return _amount * _percent / _denominator;
    }

    receive() external payable {}
}