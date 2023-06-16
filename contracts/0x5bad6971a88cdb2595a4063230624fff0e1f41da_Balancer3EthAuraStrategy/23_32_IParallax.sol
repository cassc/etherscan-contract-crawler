//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity 0.8.15;

interface IParallax {
    /**
     * @notice Represents a single strategy with its relevant data.
     */
    struct Strategy {
        uint256 fee;
        uint256 totalStaked;
        uint256 totalShares;
        uint256 lastCompoundTimestamp;
        uint256 cap;
        uint256 rewardPerBlock;
        uint256 rewardPerShare;
        uint256 lastUpdatedBlockNumber;
        address strategy;
        uint32 timelock;
        bool isActive;
        IERC20Upgradeable rewardToken;
        uint256 usersCount;
    }

    /// @notice The view method for getting current feesReceiver.
    function feesReceiver() external view returns (address);

    /**
     * @notice The view method for getting current withdrawal fee by strategy.
     * @param strategy An address of a strategy.
     * @return Withdrawal fee.
     **/
    function getFee(address strategy) external view returns (uint256);

    /** @notice Returns the ID of the NFT owned by the specified user at the
     *           given index.
     *  @param user The address of the user who owns the NFT.
     *  @param index The index of the NFT to return.
     *  @return The ID of the NFT at the given index, owned by the specified
     *          user.
     */
    function getNftByUserAndIndex(
        address user,
        uint256 index
    ) external view returns (uint256);

    /**
     * @notice The view method to check if the token is in the whitelist.
     * @param strategy An address of a strategy.
     * @param token An address of a token to check.
     * @return Boolean flag.
     **/
    function tokensWhitelist(
        address strategy,
        address token
    ) external view returns (bool);
}