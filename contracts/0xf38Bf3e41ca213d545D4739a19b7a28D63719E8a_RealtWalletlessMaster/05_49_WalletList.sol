// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

abstract contract WalletList {
    // Add the library methods
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

    // Declare a set state variable
    EnumerableMapUpgradeable.AddressToUintMap internal _walletSalt;

    // Gas heavy transaction end - start should be less than 380
    function sendWallets(
        WalletList newContract,
        uint256 start,
        uint256 end
    ) external virtual returns (bool) {
        _canUpdateWalletList();
        require(address(newContract) != address(this), "RWM04");
        require(start < end, "RWM08");
        uint256 size = _walletSalt.length();
        require(start < size && end <= size, "RWM09");
        address[] memory wallets = new address[](end - start);
        uint256[] memory salts = new uint256[](end - start);
        uint256 j = 0;
        for (uint256 i = start; i < end; i++) {
            (address w, uint256 s) = _walletSalt.at(i);
            wallets[j] = w;
            salts[j] = s;
            j++;
            _swapOwner(w, address(this), address(newContract));
        }
        newContract.receiveWallets(wallets, salts);
        return true;
    }

    function receiveWallets(
        address[] calldata wallets,
        uint256[] calldata salts
    ) external virtual returns (bool) {
        _canUpdateWalletList();
        uint256 size = wallets.length;
        require(size == salts.length, "RWM06");
        for (uint256 index = 0; index < size; index++) {
            _walletSalt.set(wallets[index], salts[index]);
        }
        return true;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function walletSet(address key, uint256 value) external returns (bool) {
        _canUpdateWalletList();
        return _walletSalt.set(key, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function walletRemove(address key) external returns (bool) {
        _canUpdateWalletList();
        return _walletSalt.remove(key);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function walletTryGet(address key) external view returns (bool, uint256) {
        return _walletSalt.tryGet(key);
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function walletGet(address key) external view returns (uint256) {
        return _walletSalt.get(key);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function walletAt(uint256 index) external view returns (address, uint256) {
        return _walletSalt.at(index);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(address key) external view returns (bool) {
        return _walletSalt.contains(key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function walletAmount() external view returns (uint256) {
        return _walletSalt.length();
    }

    //
    function _canUpdateWalletList() internal virtual;

    function _swapOwner(address wallet, address oldOwner, address newOwner) internal virtual;
    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[10] private __gap;
}