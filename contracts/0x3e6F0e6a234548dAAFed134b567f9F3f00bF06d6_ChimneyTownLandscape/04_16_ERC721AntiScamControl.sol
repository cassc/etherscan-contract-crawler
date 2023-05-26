// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import './IERC721AntiScamControl.sol';
import '../ERC721AntiScam.sol';

abstract contract ERC721AntiScamControl is IERC721AntiScamControl, ERC721AntiScam {
    mapping(address => bool) _operators;

    modifier onlyLocker() {
        checkLockerRole(msg.sender);
        _;
    }

    /**
     * @dev トークンレベルでのロックステータスを変更する
     */
    function lock(LockStatus status, uint256 id) external virtual onlyLocker {
        _lock(status, id);
    }

    /**
     * @dev トークン所有者のウォレットアドレスにおけるロックステータスを変更する
     */
    function setWalletLock(address to, LockStatus status) external virtual override onlyLocker {
        _setWalletLock(to, status);
    }

    /**
     * @dev トークン所有者のウォレットアドレスにおけるCALレベルを変更する
     */
    function setWalletCALLevel(address to,uint256 level) external virtual override onlyLocker {
        _setWalletCALLevel(to, level);
    }

    function isLocker(address operator) public view returns (bool) {
        return _operators[operator];
    }

    function _grantLockerRole(address candidate) internal {
        require(!_operators[candidate],'account is already has an operator role');
        _operators[candidate] = true;
    }

    function _revokeLockerRole(address candidate) internal {
        checkLockerRole(candidate);
        delete _operators[candidate];
    }

    function checkLockerRole(address operator) public view {
        require(_operators[operator],'account is not an locker');
    }
}