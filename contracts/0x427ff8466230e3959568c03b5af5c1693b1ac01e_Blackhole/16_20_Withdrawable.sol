// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBlackholeRenderer.sol";

abstract contract Withdrawable {
    function mass() public view returns (uint256) {
        return address(this).balance;
    }

    function _withdraw() internal {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "fail");
    }

    function _withdrawShare(uint256 shares) internal {
        uint256 share = (address(this).balance / 100) * shares;

        (bool success, ) = msg.sender.call{value: share}("");
        require(success, "fail");
    }
}