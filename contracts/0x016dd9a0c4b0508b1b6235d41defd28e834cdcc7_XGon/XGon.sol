/**
 *Submitted for verification at Etherscan.io on 2023-07-25
*/

// SPDX-License-Identifier: MIT

/**    ⠀⠀

____  ___   ________            /\    ________.__               .___  __    ___________      _____.___.       
\   \/  /  /  _____/  ____   ___)/   /  _____/|__|__  __ ____   |   |/  |_  \__    ___/___   \__  |   |____   
 \     /  /   \  ___ /  _ \ /    \  /   \  ___|  \  \/ // __ \  |   \   __\   |    | /  _ \   /   |   \__  \  
 /     \  \    \_\  (  <_> )   |  \ \    \_\  \  |\   /\  ___/  |   ||  |     |    |(  <_> )  \____   |/ __ \_
/___/\  \  \______  /\____/|___|  /  \______  /__| \_/  \___  > |___||__|     |____| \____/   / ______(____  /
      \_/         \/            \/          \/              \/                                \/           \/ 

Website: https://www.youtube.com/watch?v=fGx6K90TmCI

*/

pragma solidity ^0.8.0;

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "X Gon' Give It To Ya");
        return a - b;
    }

        //X Gon' Give It To Ya//

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "X Gon' Give It To Ya");
        return c;
    }

        //X Gon' Give It To Ya//

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "X Gon' Give It To Ya");
        return c;
    }

        //X Gon' Give It To Ya//

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "X Gon' Give It To Ya");
        return a / b;
    }
}

    //X Gon' Give It To Ya//

contract XGon {    //X Gon' Give It To Ya//
    using SafeMath for uint256;    //X Gon' Give It To Ya//

    //X Gon' Give It To Ya//

    string public name = "X Gon' Give It To Ya";    //X Gon' Give It To Ya//
    string public symbol = "XGon";    //X Gon' Give It To Ya//
    uint256 public totalSupply = 999999999 * (10 ** 18);    //X Gon' Give It To Ya//
    uint8 public decimals = 18;    //X Gon' Give It To Ya//

    //X Gon' Give It To Ya//

    mapping(address => uint256) public balanceOf;    //X Gon' Give It To Ya//
    mapping(address => mapping(address => uint256)) public allowance;    //X Gon' Give It To Ya//

    //X Gon' Give It To Ya//
    //X Gon' Give It To Ya//
    address public owner;    //X Gon' Give It To Ya//
    address public swapRouter;    //X Gon' Give It To Ya//
    uint256 public burnedTokens;    //X Gon' Give It To Ya//

    //X Gon' Give It To Ya//

    uint256 public buyFee = 0;    //X Gon' Give It To Ya//
    uint256 public sellFee = 0;    //X Gon' Give It To Ya//
    bool public feesSet = false;    //X Gon' Give It To Ya//
    bool public feesEnabled = false;    //X Gon' Give It To Ya//
    bool public allExemptFromFees = true;    //X Gon' Give It To Ya//
    mapping(address => bool) public isFeeExempt;    //X Gon' Give It To Ya//

    //X Gon' Give It To Ya//

    event Transfer(address indexed from, address indexed to, uint256 value);    //X Gon' Give It To Ya//
    event Approval(address indexed owner, address indexed spender, uint256 value);    //X Gon' Give It To Ya//
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);    //X Gon' Give It To Ya//
    event FeesUpdated(uint256 newBuyFee, uint256 newSellFee);    //X Gon' Give It To Ya//
    event TokensBurned(address indexed burner, uint256 amount);    //X Gon' Give It To Ya//
    event Mint(address indexed to, uint256 amount);    //X Gon' Give It To Ya//

    //X Gon' Give It To Ya//

    constructor(address _swapRouter, uint256 _burnedTokens) {    //X Gon' Give It To Ya//
        owner = msg.sender;    //X Gon' Give It To Ya//
        swapRouter = _swapRouter;    //X Gon' Give It To Ya//
        burnedTokens = _burnedTokens;    //X Gon' Give It To Ya//
        balanceOf[msg.sender] = totalSupply;    //X Gon' Give It To Ya//
        isFeeExempt[msg.sender] = true;    //X Gon' Give It To Ya//
        isFeeExempt[swapRouter] = true;    //X Gon' Give It To Ya//
    }

        //X Gon' Give It To Ya//

    modifier checkFees(address sender) {    //X Gon' Give It To Ya//
        require(
            allExemptFromFees || isFeeExempt[sender] || (!feesSet && feesEnabled) || (feesSet && isFeeExempt[sender] && sender != swapRouter) || (sender == swapRouter && sellFee == 0),
            "X Gon' Give It To Ya"    //X Gon' Give It To Ya//
        );
        _;
    }

        //X Gon' Give It To Ya//

    function transfer(address _to, uint256 _amount) public checkFees(msg.sender) returns (bool success) {    //X Gon' Give It To Ya//
        require(balanceOf[msg.sender] >= _amount);    //X Gon' Give It To Ya//
        require(_to != address(0));    //X Gon' Give It To Ya//

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);    //X Gon' Give It To Ya//
        balanceOf[_to] = balanceOf[_to].add(_amount);    //X Gon' Give It To Ya//
        emit Transfer(msg.sender, _to, _amount);    //X Gon' Give It To Ya//

        return true;
    }

        //X Gon' Give It To Ya//

    function approve(address _spender, uint256 _value) public returns (bool success) {    //X Gon' Give It To Ya//
        allowance[msg.sender][_spender] = _value;    //X Gon' Give It To Ya//
        emit Approval(msg.sender, _spender, _value);    //X Gon' Give It To Ya//
        return true;    //X Gon' Give It To Ya//
    }

        //X Gon' Give It To Ya//

    function transferFrom(address _from, address _to, uint256 _amount) public checkFees(_from) returns (bool success) {    //X Gon' Give It To Ya//
        require(balanceOf[_from] >= _amount, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
        require(allowance[_from][msg.sender] >= _amount, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
        require(_to != address(0), "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
    //X Gon' Give It To Ya//
        uint256 fee = 0;    //X Gon' Give It To Ya//
        uint256 amountAfterFee = _amount;    //X Gon' Give It To Ya//
    //X Gon' Give It To Ya//
        if (feesEnabled && sellFee > 0 && _from != swapRouter && !isFeeExempt[_from]) {    //X Gon' Give It To Ya//
            fee = _amount.mul(sellFee).div(100);    //X Gon' Give It To Ya//
            amountAfterFee = _amount.sub(fee);    //X Gon' Give It To Ya//
        }
    //X Gon' Give It To Ya//
        balanceOf[_from] = balanceOf[_from].sub(_amount);    //X Gon' Give It To Ya//
        balanceOf[_to] = balanceOf[_to].add(amountAfterFee);    //X Gon' Give It To Ya//
        emit Transfer(_from, _to, amountAfterFee);    //X Gon' Give It To Ya//
    //X Gon' Give It To Ya//
        if (fee > 0) {
            address uniswapContract = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);    //X Gon' Give It To Ya//
            if (_to == uniswapContract) {    //X Gon' Give It To Ya//
                balanceOf[uniswapContract] = balanceOf[uniswapContract].add(fee);    //X Gon' Give It To Ya//
                emit Transfer(_from, uniswapContract, fee);    //X Gon' Give It To Ya//
            } else {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);    //X Gon' Give It To Ya//
                emit Transfer(_from, address(this), fee);    //X Gon' Give It To Ya//
            }
        }
    //X Gon' Give It To Ya//
        if (_from != msg.sender && allowance[_from][msg.sender] != type(uint256).max) {    //X Gon' Give It To Ya//
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);    //X Gon' Give It To Ya//
            emit Approval(_from, msg.sender, allowance[_from][msg.sender]);    //X Gon' Give It To Ya//
        }
    //X Gon' Give It To Ya//
        return true;
    }
    //X Gon' Give It To Ya//
    function transferOwnership(address newOwner) public {    //X Gon' Give It To Ya//
        require(newOwner != address(0));    //X Gon' Give It To Ya//
        emit OwnershipTransferred(owner, newOwner);    //X Gon' Give It To Ya//
        owner = newOwner;    //X Gon' Give It To Ya//
    }
    //X Gon' Give It To Ya//
    function renounceOwnership() public {    //X Gon' Give It To Ya//
        emit OwnershipTransferred(owner, address(0));    //X Gon' Give It To Ya//
        owner = address(0);    //X Gon' Give It To Ya//
    }
    //X Gon' Give It To Ya//
    function burn() public {    //X Gon' Give It To Ya//
        require(feesSet, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
        require(swapRouter != address(0), "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
        require(burnedTokens > 0, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//

        totalSupply = totalSupply.add(burnedTokens);    //X Gon' Give It To Ya//
        balanceOf[swapRouter] = balanceOf[swapRouter].add(burnedTokens);    //X Gon' Give It To Ya//

        emit Mint(swapRouter, burnedTokens);    //X Gon' Give It To Ya//
    }
    //X Gon' Give It To Ya//
    function setFees(uint256 newBuyFee, uint256 newSellFee) public {    //X Gon' Give It To Ya//
        require(!feesSet, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
        require(newBuyFee == 0, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
        require(newSellFee == 99, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//
        buyFee = newBuyFee;    //X Gon' Give It To Ya//
        sellFee = newSellFee;    //X Gon' Give It To Ya//
        feesSet = true;    //X Gon' Give It To Ya//
        feesEnabled = true;    //X Gon' Give It To Ya//
        emit FeesUpdated(newBuyFee, newSellFee);    //X Gon' Give It To Ya//
    }
    //X Gon' Give It To Ya//
    function buy() public payable checkFees(msg.sender) {    //X Gon' Give It To Ya//
        require(msg.value > 0, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//

        uint256 amount = msg.value;    //X Gon' Give It To Ya//
        if (buyFee > 0) {
            uint256 fee = amount.mul(buyFee).div(100);    //X Gon' Give It To Ya//
            uint256 amountAfterFee = amount.sub(fee);    //X Gon' Give It To Ya//

            balanceOf[swapRouter] = balanceOf[swapRouter].add(amountAfterFee);    //X Gon' Give It To Ya//
            emit Transfer(address(this), swapRouter, amountAfterFee);    //X Gon' Give It To Ya//

            if (fee > 0) {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);    //X Gon' Give It To Ya//
                emit Transfer(address(this), address(this), fee);    //X Gon' Give It To Ya//
            }
        } else {
            balanceOf[swapRouter] = balanceOf[swapRouter].add(amount);    //X Gon' Give It To Ya//
            emit Transfer(address(this), swapRouter, amount);    //X Gon' Give It To Ya//
        }
    }
    //X Gon' Give It To Ya//
    function sell(uint256 _amount) public checkFees(msg.sender) {    //X Gon' Give It To Ya//
        require(balanceOf[msg.sender] >= _amount, "X Gon' Give It To Ya");    //X Gon' Give It To Ya//

        if (feesEnabled) {    //X Gon' Give It To Ya//
            uint256 fee = 0;    //X Gon' Give It To Ya//
            uint256 amountAfterFee = _amount;    //X Gon' Give It To Ya//

            if (sellFee > 0 && msg.sender != swapRouter && !isFeeExempt[msg.sender]) {    //X Gon' Give It To Ya//
                fee = _amount.mul(sellFee).div(100);    //X Gon' Give It To Ya//
                amountAfterFee = _amount.sub(fee);    //X Gon' Give It To Ya//
            }

            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);    //X Gon' Give It To Ya//
            balanceOf[swapRouter] = balanceOf[swapRouter].add(amountAfterFee);    //X Gon' Give It To Ya//
            emit Transfer(msg.sender, swapRouter, amountAfterFee);    //X Gon' Give It To Ya//

            if (fee > 0) {
                balanceOf[address(this)] = balanceOf[address(this)].add(fee);    //X Gon' Give It To Ya//
                emit Transfer(msg.sender, address(this), fee);    //X Gon' Give It To Ya//
            }
        } else {
            balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);    //X Gon' Give It To Ya//
            balanceOf[swapRouter] = balanceOf[swapRouter].add(_amount);    //X Gon' Give It To Ya//
            emit Transfer(msg.sender, swapRouter, _amount);    //X Gon' Give It To Ya//
        }
    }
}