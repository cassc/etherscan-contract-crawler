// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @author YLDR <[email protected]>
contract SuperAdminControl is Ownable {
    struct CallData {
        address to;
        bytes data;
        uint256 value;
    }

    function call(CallData[] calldata calls) external onlyOwner {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success,) = calls[i].to.call{value: calls[i].value}(calls[i].data);
            require(success, "failed");
        }
    }
}