// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Pausable.sol";
import "../Initializable.sol";
import "../AllowedList.sol";

abstract contract Adapter is Initializable, Pausable {
    address public rootAdapter;

    event RootAdapterUpdated(address old_adapter, address new_adapter);

    function setRootAdapter(address rootAdapter_) external onlyAdmin {
        require(rootAdapter_ != address(0), "zero address");
        emit RootAdapterUpdated(rootAdapter, rootAdapter_);
        rootAdapter = rootAdapter_;
    }

    modifier onlyRootAdapter() {
        require(msg.sender == rootAdapter, "only root adapter");
        _;
    }
}