// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import { Helper } from "../libraries/Helper.sol";

abstract contract Creator {
    event CreatorUpdated(address creator);
    using Helper for uint256;
    using Helper for address;

    uint256 internal _creator;

    function _setCreator(address creator_) internal {
        _creator = creator_.toUint256();
        emit CreatorUpdated(creator_);
    }

    function creator() external view returns (address) {
        return _creator.toAddress();
    }

    uint256[49] private __gap;
}