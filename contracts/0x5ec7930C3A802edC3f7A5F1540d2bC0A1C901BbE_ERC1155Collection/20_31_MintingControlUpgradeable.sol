// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "../../interfaces/IMintingControl.sol";

abstract contract MintingControlUpgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IMintingControl {
    mapping(address => bool) private _minters;

    bool public isPublic;

    event MinterSet(address indexed account, bool isMinter);
    event Published(address account);
    event Unpublished(address account);

    modifier onlyAllowedMinters() {
        require(isPublic || isMinter(_msgSender()), "Sender has no minter role");
        _;
    }

    function __MintingControl_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __MintingControl_init_unchained();
        __Context_init_unchained();
    }

    function __MintingControl_init_unchained() internal onlyInitializing {}

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable) returns (bool) {
        return interfaceId == type(IMintingControl).interfaceId || super.supportsInterface(interfaceId);
    }

    function _setMinter(address account, bool _isMinter) internal {
        _minters[account] = _isMinter;
        emit MinterSet(account, _isMinter);
    }

    function _publish() internal {
        isPublic = true;
        emit Published(_msgSender());
    }

    function _unpublish() internal {
        isPublic = false;
        emit Unpublished(_msgSender());
    }

    uint256[50] private __gap;
}