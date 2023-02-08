// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LockedSupplyMonitor {
    event AddedAddresses(
        address indexed user,
        IERC20 indexed token,
        address[] addresses
    );
    event RemovedAddresses(
        address indexed user,
        IERC20 indexed token,
        address[] addresses
    );

    mapping(address => mapping(IERC20 => address[]))
        private userToTokenToLockedAddresses;

    function addLockedTokenAddresses(
        IERC20 token,
        address[] calldata wallets
    ) external {
        require(
            wallets.length <= 30,
            "Cannot process more than 30 addresses at a time."
        );
        require(isERC20(token), "Token must be ERC20");
        for (uint i = 0; i < wallets.length; i++) {
            if (wallets[i] == address(0)) continue;
            userToTokenToLockedAddresses[msg.sender][token].push(wallets[i]);
        }
        emit AddedAddresses(msg.sender, token, wallets);
    }

    function removeLockedTokenAddresses(
        IERC20 token,
        address[] memory wallets
    ) external {
        require(
            wallets.length <= 30,
            "Cannot process more than 30 addresses at a time."
        );
        require(isERC20(token), "Token must be ERC20");
        address[] storage lockedAddresses = userToTokenToLockedAddresses[
            msg.sender
        ][token];
        for (uint i = 0; i < lockedAddresses.length; i++) {
            for (uint j = 0; j < wallets.length; j++) {
                if (lockedAddresses[i] == wallets[j]) {
                    removeIndex(lockedAddresses, i);
                }
            }
        }
        emit RemovedAddresses(msg.sender, token, wallets);
    }

    function removeLockedTokenAddressesWithIndex(
        IERC20 token,
        uint[] calldata walletIndices
    ) external {
        require(
            walletIndices.length <= 30,
            "Cannot process more than 30 addresses at a time."
        );
        address[] storage lockedAddresses = userToTokenToLockedAddresses[
            msg.sender
        ][token];
        address[] memory removedAddresses = new address[](walletIndices.length);

        for (uint i = 0; i < walletIndices.length; i++) {
            removedAddresses[i] = lockedAddresses[walletIndices[i]];
            removeIndex(lockedAddresses, walletIndices[i]);
        }
        emit RemovedAddresses(msg.sender, token, removedAddresses);
    }

    function removeIndex(address[] storage array, uint index) private {
        if (array.length > 1 && index != array.length - 1) {
            array[index] = array[array.length - 1];
        }
        array.pop();
    }

    function getIndices(
        address user,
        IERC20 token,
        address[] calldata wallets
    ) external view returns (uint[] memory indices) {
        address[] memory lockedAddresses = userToTokenToLockedAddresses[user][
            token
        ];

        uint[] memory indicesPre = new uint[](lockedAddresses.length);
        uint count;
        for (uint i = 0; i < lockedAddresses.length; i++) {
            for (uint j = 0; j < wallets.length; j++) {
                if (lockedAddresses[i] == wallets[j]) {
                    indicesPre[count] = i;
                    count++;
                }
            }
        }

        if (count == 0) return indices;
        indices = new uint[](count);
        for (uint i = 0; i < indices.length; i++) {
            indices[i] = indicesPre[i];
        }
    }

    function getLockedTokenAddresses(
        address user,
        IERC20 token
    ) external view returns (address[] memory) {
        return userToTokenToLockedAddresses[user][token];
    }

    function getLockedTokenAddressesNoDuplicates(
        address user,
        IERC20 token
    ) public view returns (address[] memory addresses) {
        address[] memory lockedAddresses = userToTokenToLockedAddresses[user][token];

        address[] memory addressesPre = new address[](lockedAddresses.length);
        uint count;
        for (uint i = 0; i < lockedAddresses.length; i++) {
            if (lockedAddresses[i] == address(0)) continue;
            bool counted;
            for (uint j = 0; j < i; j++) {
                if (lockedAddresses[i] == lockedAddresses[j]) {
                    counted = true;
                    break;
                }
            }
            if (!counted) {
                addressesPre[count] = lockedAddresses[i];
                count++;
            }
        }

        addresses = new address[](count);
        for (uint i = 0; i < addresses.length; i++) {
            addresses[i] = addressesPre[i];
        }
    }

    function getLockedSupply(
        address user,
        IERC20 token
    ) public view returns (uint lockedSupply) {
        address[] memory lockedAddresses = getLockedTokenAddressesNoDuplicates(
            user,
            token
        );
        for (uint i = 0; i < lockedAddresses.length; i++) {
            if (lockedAddresses[i] == address(0)) continue;
            lockedSupply += IERC20(token).balanceOf(lockedAddresses[i]);
        }
    }

    function getTotalSupply(IERC20 token) public view returns (uint) {
        return token.totalSupply();
    }

    function getCirculatingSupply(
        address user,
        IERC20 token
    ) public view returns (uint) {
        return (getTotalSupply(token) - getLockedSupply(user, token));
    }

    function getSupplyInformation(
        address user,
        IERC20 token
    ) external view returns (uint, uint, uint) {
        return (
            getTotalSupply(token),
            getLockedSupply(user, token),
            getCirculatingSupply(user, token)
        );
    }

    function isERC20(IERC20 token) private view returns (bool) {
        if (address(token).code.length == 0) {
            return false;
        }
        try token.balanceOf(address(0)) {} catch {
            return false;
        }
        try token.totalSupply() {
            return true;
        } catch {
            return false;
        }
    }
}