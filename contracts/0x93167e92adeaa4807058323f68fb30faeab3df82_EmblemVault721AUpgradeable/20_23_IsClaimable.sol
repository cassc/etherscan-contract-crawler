// SPDX-License-Identifier: CLOSED - Pending Licensing Audit
pragma solidity ^0.8.4;
import "./OwnableUpgradeable.sol";
abstract contract IsClaimable is OwnableUpgradeable {

    bool public isClaimable;

    function toggleClaimable() public onlyOwner {
        isClaimable = !isClaimable;
    }
   
}