pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Authorizable is Ownable {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || owner() == msg.sender,
            "Not authorized"
        );
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        require(_toAdd != address(0), "Authorizable: Rejected null address");
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != address(0), "Authorizable: Rejected null address");
        require(_toRemove != msg.sender, "Authorizable: Rejected self remove");
        authorized[_toRemove] = false;
    }
}

// @4's