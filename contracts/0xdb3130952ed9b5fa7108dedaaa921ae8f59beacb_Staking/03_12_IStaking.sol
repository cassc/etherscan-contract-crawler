// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStaking {
	function stake(uint256 amount) external;
	function unstake(uint256 amount) external;

    function claimProfit(IERC20 token) external returns (uint256);
    function claimAllProfits() external returns (uint256[] memory profits);

    function addClaimableToken(IERC20 newClaimableToken) external;
    function removeClaimableToken(IERC20 removedClaimableToken) external;

    function addToken(IERC20 newToken) external;
    function removeToken(IERC20 removedToken) external;

    function convertFunds() external;

    function setStakingLockupTime(uint256 newLockupTime) external;

    function profitOf(address account, IERC20 token) external view returns (uint256);

    function getClaimableTokens() external view returns (IERC20[] memory);
    function getOtherTokens() external view returns (IERC20[] memory);

    receive() external payable;
}