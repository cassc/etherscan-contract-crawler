// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import '../IERC721AntiScam.sol';

interface IERC721AntiScamControl is IERC721AntiScam {

    // For token lock
    function lock(LockStatus status, uint256 id) external;

    /**
     * @dev トークン所有者のウォレットアドレスにおけるロックステータスを変更する
     */
    function setWalletLock(address to, LockStatus status) external;

    /**
     * @dev トークン所有者のウォレットアドレスにおけるCALレベルを変更する
     */
    function setWalletCALLevel(address to, uint256 level) external;


    function grantLockerRole(address candidate) external;

    function revokeLockerRole(address candidate) external;

    function checkLockerRole(address operator) external view;

}