// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

import "./Ownable.sol";

error CrossmintNotActive();
error CrossmintAddressNotSet();
error CrossmintAddressDoesNotMatch();

abstract contract Crossmintable is Ownable {
    bool public crossmintIsActive;
    address private crossmintAddress;

    function flipCrossmintState() external onlyOwner {
        crossmintIsActive = !crossmintIsActive;
    }

    function setCrossmintAddress(address _crossmintAddress) public onlyOwner {
        crossmintAddress = _crossmintAddress;
    }

    modifier onlyCrossmint() {
        if (!crossmintIsActive) revert CrossmintNotActive();
        if (crossmintAddress == address(0)) revert CrossmintAddressNotSet();
        if (msg.sender != crossmintAddress)
            revert CrossmintAddressDoesNotMatch();
        _;
    }
}