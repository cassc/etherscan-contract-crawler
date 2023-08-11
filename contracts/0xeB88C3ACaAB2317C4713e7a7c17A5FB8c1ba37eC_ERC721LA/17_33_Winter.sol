// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
import "../extensions/AccessControl.sol";

/**
 * Used to set Winter whitelisted minting addresses
 */
contract Winter is AccessControl {
    struct WinterState {
        address[] winterAddresses;
    }

    function _getWinterState()
        internal
        pure
        returns (WinterState storage state)
    {
        bytes32 position = keccak256("liveart.Winter");
        assembly {
            state.slot := position
        }
    }

    function addWinterWallets(
        address[] calldata newAddresses
    ) public onlyAdmin {
        for (uint256 i; i < newAddresses.length; i += 1) {
            _setWinterWallet(newAddresses[i]);
        }
    }

    function addWinterWallet(address newAddress) public onlyAdmin {
        _setWinterWallet(newAddress);
    }

    function _setWinterWallet(address newAddress) internal {
        WinterState storage state = _getWinterState();
        state.winterAddresses.push(newAddress);
    }

    function deleteWinterWallet(address newAddress) public onlyAdmin {
        WinterState storage state = _getWinterState();
        for (uint256 i; i < state.winterAddresses.length; i += 1) {
            if (newAddress == state.winterAddresses[i]) {
                delete state.winterAddresses[i];
            }
        }
        state.winterAddresses.push(newAddress);
    }

    function _isWinterWallet() internal view returns (bool) {
        WinterState storage state = _getWinterState();

        for (uint256 i; i < state.winterAddresses.length; i += 1) {
            if (msg.sender == state.winterAddresses[i]) {
                return true;
            }
        }
        return false;
    }
}