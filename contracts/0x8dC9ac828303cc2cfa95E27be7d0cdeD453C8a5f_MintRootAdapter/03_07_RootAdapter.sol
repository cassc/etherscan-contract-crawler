// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Initializable.sol";
import "../AllowedList.sol";
import "../Pausable.sol";

contract RootAdapter is AllowedList, Initializable, Pausable {
    mapping(uint16 => address) public adapters;

    function init(address admin_) external whenNotInitialized {
        require(admin_ != address(0), "zero address");
        admin = admin_;
        pauser = admin_;
        isInited = true;
    }

    function setAdapter(
        uint16 executionChainId_,
        address adapter_
    ) external onlyAdmin {
        adapters[executionChainId_] = adapter_;
    }
}