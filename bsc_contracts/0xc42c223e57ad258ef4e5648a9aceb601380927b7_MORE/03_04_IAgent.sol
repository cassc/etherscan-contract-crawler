// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IAgent {
    function delegate(
        uint256 buyPot, uint256 sellPot, uint256 transferPot, uint256 teamPot, uint256 referrerPot, uint256 tokensUsedForReferrerPot
    ) external payable;
    function marketplaceDelegate(uint256 toBuyback, uint256 toMarketing, uint256 toTeam) external payable;
    function notifyTransferListener(address from, address to) external;
    function notifyTransferListener(address from) external;

    function tryToLock(address account, uint128 amount, uint32 duration) external;
    function tryToLockExtra(address account, uint256 lockIndex, uint128 amount) external;
    function tryToUnlock(address account, uint256 lockIndex) external returns(uint256);
}