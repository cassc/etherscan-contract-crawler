pragma solidity >=0.8.0 <0.9.0;

import "./Constants.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Treasury is Constants, AccessControl {
    event Withdraw(uint256 _amount);

    function withdraw(uint256 _amount) public {
        require(hasRole(TREASURER_ROLE, msg.sender), "Caller is not treasurer");
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        require(success, "Transfer failed");
        emit Withdraw(_amount);
    }
}