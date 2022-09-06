// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../../contracts/lib/OwnableCloneable.sol";

contract $OwnableCloneable is OwnableCloneable {
    constructor() {}

    function $ownableInitialized() external view returns (bool) {
        return ownableInitialized;
    }

    function $_setOwner(address newOwner) external {
        return super._setOwner(newOwner);
    }

    function $_msgSender() external view returns (address) {
        return super._msgSender();
    }

    function $_msgData() external view returns (bytes memory) {
        return super._msgData();
    }
}