//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./OnDemandToken.sol";

abstract contract OnDemandTokenBridgable is OnDemandToken {
    mapping (address => bool) public bridges;

    event SetupBridge(address bridge, bool active);

    function setupBridge(address _bridge, bool _active) external onlyOwner() {
        bridges[_bridge] = _active;
        emit SetupBridge(_bridge, _active);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        if (_from != address(0) && _to != address(0) && bridges[msg.sender]) {
            uint256 balance = balanceOf(msg.sender);

            if (balance < _amount) {
                uint256 amountToMint = _amount - balance;
                _assertMaxSupply(amountToMint);
                _mint(msg.sender, amountToMint);
            }
        }
    }
}