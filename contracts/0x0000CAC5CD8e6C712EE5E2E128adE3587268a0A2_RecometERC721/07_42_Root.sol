// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Root
 * Root - This contract manages the root.
 */
abstract contract Root {
    bytes32 private _root;
    bool private _isRootFreezed;

    event RootFreezed();
    event RootSet(bytes32 root);

    modifier whenNotRootFreezed() {
        require(!_isRootFreezed, "Root: root already freezed");
        _;
    }

    function root() public view returns (bytes32) {
        return _root;
    }

    function _freezeRoot() internal whenNotRootFreezed {
        _isRootFreezed = true;
        emit RootFreezed();
    }

    function _setRoot(bytes32 root_, bool freezing)
        internal
        whenNotRootFreezed
    {
        _root = root_;
        emit RootSet(root_);
        if (freezing) {
            _freezeRoot();
        }
    }

    function _validateRoot(bytes32 root_)
        internal
        view
        returns (bool, string memory)
    {
        if (_root != bytes32(0x0) && _root != root_) {
            return (false, "Root: root verification failed");
        }
        return (true, "");
    }

    uint256[50] private __gap;
}