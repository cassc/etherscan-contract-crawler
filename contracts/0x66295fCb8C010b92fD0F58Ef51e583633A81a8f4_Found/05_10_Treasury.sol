// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is Ownable {
    mapping(address => bool) private _treasurers;
    
    event ActivateTreasurer(address indexed treasurer);
    event DeactivateTreasurer(address indexed treasurer);

    receive() external payable {}
    fallback() external payable {}

    function valueBalance() public view returns (uint) {
        return address(this).balance;
    }

    modifier onlyTreasurer() {
        require(
            _treasurers[msg.sender] && msg.sender != address(0), 
            "Caller is not the treasurer"
        );
        _;
    }

    function pushValue(address to, uint amount) external onlyTreasurer {
        _pushValue(to, amount);
    }

    function isTreasurerActive(address treasurer) external view returns (bool) {
        return _treasurers[treasurer];
    }

    function activateTreasurer(address treasurer) external onlyOwner {
        _treasurers[treasurer] = true;
        emit ActivateTreasurer(treasurer);
    }

    function deactivateTreasurer(address treasurer) external onlyOwner {
        _treasurers[treasurer] = false;
        emit DeactivateTreasurer(treasurer);
    }

    function _pushValue(address to, uint amount) internal {
        require(
            address(this).balance >= amount, 
            "Treasury transfer exceeds balance"
        );
        (bool success, ) = to.call{value:amount}("");
        require(success, "Treasury transfer failed");
    }
}