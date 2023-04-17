// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

/*
// FOX BLOCKCHAIN \\

FoxChain works to connect all Blockchains in one platform with one click access to any network.

Website     : https://foxchain.app/
Telegram    : https://t.me/FOXCHAINNEWS
Twitter     : https://twitter.com/FoxchainLabs
Github      : https://github.com/FoxChainLabs

*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarderV2 {
    /// @dev even if not all parameters are currently used in this implementation they help future proofing it
    function onReward(
        uint256 _pid,
        address _user,
        address _to,
        uint256 _pending,
        uint256 _stakedAmount,
        uint256 _lpSupply
    ) external;

    /// @dev passing stakedAmount here helps future proofing the interface
    function pendingTokens(
        uint256 pid,
        address user,
        uint256 amount
    ) external view returns (IERC20[] memory, uint256[] memory);
}