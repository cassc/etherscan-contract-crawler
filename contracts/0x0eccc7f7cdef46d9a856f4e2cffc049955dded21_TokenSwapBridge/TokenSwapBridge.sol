/**
 *Submitted for verification at Etherscan.io on 2021-01-27
*/

pragma solidity ^0.5.0;
/*
 * @title: SafeMath
 * @dev: Helper contract functions to arithmatic operations safely.
 */

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

}

 /*
 * @title: Token
 * @dev: Interface contract for ERC20 tokens
 */
contract Token {
    function totalSupply() public view returns (uint256 supply);

    function balanceOf(address _owner) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        public
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success);

    function approve(address _spender, uint256 _value)
        public
        returns (bool success);

    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining);
    
    function burn(uint256 amount) public;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}


contract TokenSwapBridge {
    using SafeMath for uint256;

    constructor() public {
        owner = msg.sender;
        paused = false;
    }
    
    event SwapKAI(address _from, address _addr, uint256 _amount);
    address constant KAI_ADDRESS = 0xD9Ec3ff1f8be459Bb9369b4E79e9Ebcf7141C093;

    address private owner;
    address[] public depositors;
    bool public paused;
    mapping (address => uint256) public amount;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function swapKAI(address _toAddress,  uint256 _amount) public {
        require(paused == false, "SwapToken paused");
        require(Token(KAI_ADDRESS).transferFrom(msg.sender, address(this), _amount));
        
        if (amount[_toAddress] == 0) {
            depositors.push(_toAddress);
        }
        
        amount[_toAddress] += _amount;
        
        emit SwapKAI(msg.sender, _toAddress, _amount);
    }
    
    function burnKAI() public onlyOwner {
        Token(KAI_ADDRESS).burn(getBalanceKAIContract());
    }
    
    function getBalanceKAIContract() public view returns (uint256) {
        return Token(KAI_ADDRESS).balanceOf(address(this));
    }

    function setPause() public onlyOwner {
        paused = true;
    }
    
    function setUnpause() public onlyOwner {
        paused = false;
    }
    
    function getDepositors() public view returns (address[] memory) {
        return depositors;
    }
    
    function emergencyWithdrawalKAI(uint256 _amount) public onlyOwner {
        Token(KAI_ADDRESS).transfer(msg.sender, _amount);
    }  
}