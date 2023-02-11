pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenLocker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    ERC20 public token;
    address public withdrawer;
    uint256 public withdrawTime;
    string public name;

    event withdrawTokenEvent(uint256 timestamp, uint256 amount);

    constructor(
        ERC20 _token,
        string memory _name,
        address _withdrawer,
        uint256 _withdrawTime
    ){
        require(_withdrawTime > block.timestamp, "withdraw time should be more than now");

        token = _token;
        name = _name;
        withdrawer = _withdrawer;
        withdrawTime = _withdrawTime;
    }

    function withdrawToken(uint256 amount) public{
        require(amount >= token.balanceOf(address(this)), "Withdraw amount is exceed balance");
        require(msg.sender == withdrawer, "You are not withdrawer");
        require(block.timestamp > withdrawTime, "Not time yet");
        token.transfer(msg.sender, amount);
            emit withdrawTokenEvent(block.timestamp, amount);
    }

    function withdrawTokenAll() public{
        require(msg.sender == withdrawer, "You are not withdrawer");
        require(block.timestamp > withdrawTime, "Not time yet");
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
        emit withdrawTokenEvent(block.timestamp, amount);
    }

    function tokenRemaining() public view returns(uint256){
        return token.balanceOf(address(this));
    }

}