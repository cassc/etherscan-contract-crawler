// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev owner
import "@openzeppelin/contracts/access/Ownable.sol";

contract Royalty is Ownable {
    // Team addresses for withdrawals
    address public a1;
    address public a2;

    /// @dev fallback
    fallback() external payable {
        deposit();
    }

    /// @dev receive
    receive() external payable {
        deposit();
    }

    /// @dev deposit
    function deposit() public payable {
        /// @dev percent
        uint256 percent = msg.value / 100;

        /// @dev send percent
        require(payable(a1).send(percent * 97));

        /// @dev send percent
        require(payable(a2).send(percent * 3));
    }

    /// @dev set addresses a1
    function setA1(address _a1) public onlyOwner {
        a1 = _a1;
    }

    /// @dev set addresses a2
    function setA2(address _a2) public onlyOwner {
        a2 = _a2;
    }
}