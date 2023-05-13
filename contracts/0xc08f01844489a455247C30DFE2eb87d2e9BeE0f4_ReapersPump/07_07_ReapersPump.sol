/* o__ __o         o__ __o__/_          o           o__ __o     o__ __o__/_   o__ __o         o       o__ __o    
* <|     v\       <|    v              <|>         <|     v\   <|    v       <|     v\       <|>     /v     v\   
* / \     <\      < >                  / \         / \     <\  < >           / \     <\      < >    />       <\  
* \o/     o/       |                 o/   \o       \o/     o/   |            \o/     o/            _\o____       
*  |__  _<|        o__/_            <|__ __|>       |__  _<|/   o__/_         |__  _<|                  \_\__o__ 
*  |       \       |                /       \       |           |             |       \                       \  
* <o>       \o    <o>             o/         \o    <o>         <o>           <o>       \o           \         /  
*  |         v\    |             /v           v\    |           |             |         v\           o       o   
* / \         <\  / \  _\o__/_  />             <\  / \         / \  _\o__/_  / \         <\          <\__ __/>   
*
*                                 
*  o__ __o     o         o    o          o    o__ __o   
* <|     v\   <|>       <|>  <|\        /|>  <|     v\  
* / \     <\  / \       / \  / \\o    o// \  / \     <\ 
* \o/     o/  \o/       \o/  \o/ v\  /v \o/  \o/     o/ 
*  |__  _<|/   |         |    |   <\/>   |    |__  _<|/ 
*  |          < >       < >  / \        / \   |         
* <o>          \         /   \o/        \o/  <o>        
*  |            o       o     |          |    |         
* / \           <\__ __/>    / \        / \  / \                                                                                                                      
*                                                                                                                                                                                                                                                                       
*                                                                                                                                                                          
* Reaper will come for you in three days, but in the meantime he has more important things to do.
* Reaper kills 13% of tokens in lp daily.
*
* https://twitter.com/ReapersPump
* https://reaperspump.xyz/
* https://t.me/reaperspump
*
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "interfaces/IUniswapV2Router02.sol";
import "interfaces/IUniswapV2Pair.sol";
import "interfaces/IUniswapV2Factory.sol";


interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ReapersPump is IERC20, Ownable {
    string public name = "REAPERS PUMP";
    string public symbol = "RP";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    bool reaperAwake;

    uint256 public sellTax = 300;
    uint256 public lastKillTimestamp;

    uint256 maxWallet;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) isExcludedFromTax;

    mapping(address => uint256) public _firstReceivedBlock;  
    mapping(address => bool) public _immortal;   
    
    
    IUniswapV2Pair public uniswapV2Pair;
    IUniswapV2Router02 public uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address payable treasury = payable(0xf5b8D766f96F1403B1529B2664798fC4FE577809);
    

    constructor() {
        totalSupply = 66_666_666e18;
        balanceOf[msg.sender] = totalSupply;

        
        maxWallet = totalSupply / 50;
        
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH())
        );
        _immortal[msg.sender] = true;      
        _immortal[address(this)] = true;       
        _immortal[address(uniswapV2Pair)] = true;   
        _immortal[address(uniswapV2Router)] = true;   

        isExcludedFromTax[msg.sender] = true;
        isExcludedFromTax[address(this)] = true;
        isExcludedFromTax[treasury] = true;
        isExcludedFromTax[address(uniswapV2Router)] = true;

    }

    event KillTokens(uint256 prevReserve, uint256 newReserve);


    bool inSwap = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    receive() external payable {}


    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function CheatDeath(address account) public onlyOwner {
        _immortal[account] = true;
    }

    function AcceptDeath(address account) public onlyOwner {
        _immortal[account] = false;
        _firstReceivedBlock[account] = 0;
    }

    function KnowDeath(address account) public view returns (uint256) {    
        uint256 deathBlock;
        if (_firstReceivedBlock[account] != 0) {
            deathBlock = _firstReceivedBlock[account] + 3 days;
        }
        if (_firstReceivedBlock[account] == 0 || _immortal[account]) {
            deathBlock = 0;
        } 
        return deathBlock;
    }
     
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(_firstReceivedBlock[msg.sender] + 3 days > block.timestamp || _immortal[msg.sender], "cannot escape death");    
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(_firstReceivedBlock[sender] + 3 days > block.timestamp || _immortal[sender], "cannot escape death");    
        _spendAllowance(sender, _msgSender(), amount);
        _transfer(sender, recipient, amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        if (sender == address(uniswapV2Pair) && !isExcludedFromTax[recipient]) {
            require(amount + balanceOf[recipient] <= maxWallet, "Transfer amount exceeds the maxWallet");
        }

        if (recipient == address(uniswapV2Pair) && !isExcludedFromTax[sender]) {
            uint256 tax = (amount * sellTax) / 10000;
            amount -= tax;
            balanceOf[address(this)] += tax;
            balanceOf[sender] -= tax;
        }

        uint256 contractTokenBalance = balanceOf[address(this)];
        bool canSwap = contractTokenBalance > 0;

        if (
            canSwap && !inSwap && sender != address(uniswapV2Pair) && !isExcludedFromTax[sender]
                && !isExcludedFromTax[recipient]
        ) {
            swapTokensForEth(contractTokenBalance);
        }

        if (_firstReceivedBlock[recipient] == 0) {    
            _firstReceivedBlock[recipient] = block.timestamp;    
        } 

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
    }

    bool isReserve0;

    function killTokens() public {
        require(reaperAwake, "Reaper is not awake");
        require(lastKillTimestamp != block.timestamp, "Reaper cooldown");

        (uint112 reserve0, uint112 reserve1,) = uniswapV2Pair.getReserves();
        uint112 reserve = isReserve0 ? reserve0 : reserve1;

        uint toBurn = viewKillTokens();
        lastKillTimestamp = block.timestamp;

        burnFrom(address(uniswapV2Pair), toBurn);

        uniswapV2Pair.sync();

        emit KillTokens(reserve, reserve - toBurn);
    }

    function viewKillTokens() public view returns (uint256){
        (uint112 reserve0, uint112 reserve1,) = uniswapV2Pair.getReserves();
        uint112 reserve = isReserve0 ? reserve0 : reserve1;

        uint256 timePassed = viewTimePassed();
        uint256 toBurn;

        toBurn = (reserve * timePassed) / ((769 * 86400)/100);

        return toBurn;
    }

    function awakenReaper() public onlyOwner {
        require(!reaperAwake, "Reaper is up");
        reaperAwake = true;
        maxWallet = type(uint).max;
        lastKillTimestamp = block.timestamp;
    }

    function setReserve(bool _isReserve0) public onlyOwner {
        isReserve0 = _isReserve0;
    }

    function viewTimePassed() public view returns (uint256) {
        uint256 timePassed;
        if (block.timestamp - lastKillTimestamp > 3 days) {
            timePassed = 3 days;
        } else {
            timePassed = block.timestamp - lastKillTimestamp;
        }
        return timePassed;
    }

    function burnFrom(address account, uint256 amount) private {
        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, treasury, block.timestamp
        );
    }
    
}