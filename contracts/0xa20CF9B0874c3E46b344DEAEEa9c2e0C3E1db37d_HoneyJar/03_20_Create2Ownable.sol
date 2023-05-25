//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Allows you to pass in the owner address during contract creation
/// @author Modified from Tubby Cats (https://github.com/tubby-cats/dual-ownership-nft/blob/master/contracts/MultisigOwnable.sol)
abstract contract Create2Ownable is Ownable {
    address public realOwner;

    /// @notice passing an address allows a factory to deploy the contract an attribute ownership to the correct address
    constructor(address realOwner_) {
        realOwner = realOwner_;
        _transferOwnership(realOwner_);
    }

    modifier onlyRealOwner() {
        require(realOwner == msg.sender, "MultisigOwnable: caller is not the real owner");
        _;
    }

    function transferRealOwnership(address newRealOwner) public onlyRealOwner {
        realOwner = newRealOwner;
    }

    function transferLowerOwnership(address newOwner) public onlyRealOwner {
        _transferOwnership(newOwner);
    }
}