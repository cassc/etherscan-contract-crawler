// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Libs
import { AbstractVault, IERC20 } from "../AbstractVault.sol";
import { LiquidatorAbstractVault } from "./LiquidatorAbstractVault.sol";

struct StreamData {
    uint32 last;
    uint32 end;
    uint128 sharesPerSecond;
}

/**
 * @title   Abstract ERC-4626 vault that streams increases in the vault's assets per share by minting and then burning shares over a period of time.
 * @author  mStable
 * @dev     VERSION: 1.0
 *          DATE:    2022-06-03
 *
 * Implementations must implement the `collectRewards` function.
 *
 * The following functions have to be called by implementing contract.
 * - constructor
 *   - AbstractVault(_asset)
 *   - VaultManagerRole(_nexus)
 * - VaultManagerRole._initialize(_vaultManager)
 * - LiquidatorAbstractVault._initialize(_rewardTokens)
 */
abstract contract LiquidatorStreamAbstractVault is AbstractVault, LiquidatorAbstractVault {
    using SafeERC20 for IERC20;

    /// @notice Number of seconds the increased asssets per share will be streamed after tokens are donated.
    uint256 public immutable STREAM_DURATION;
    /// @notice The scale of the shares per second to be burnt which is 18 decimal places.
    uint256 public constant STREAM_PER_SECOND_SCALE = 1e18;

    /// @notice Stream data for the shares being burnt over time to slowing increase the vault's assetes per share.
    StreamData public shareStream;

    modifier streamRewards() {
        _streamRewards();
        _;
    }

    /**
     * @param _streamDuration  Number of seconds the increased asssets per share will be streamed after liquidated rewards are donated back.
     */
    constructor(uint256 _streamDuration) {
        STREAM_DURATION = _streamDuration;
    }

    /// @dev calculates the amount of vault shares that can be burnt to this point in time.
    function _secondsToBurn(StreamData memory stream) internal view returns (uint256 secondsToBurn_) {
        // If still burning vault shares
        if (block.timestamp < stream.end) {
            secondsToBurn_ = block.timestamp - stream.last;
        }
        // If still vault shares to burn since the stream ended.
        else if (stream.last < stream.end) {
            secondsToBurn_ = stream.end - stream.last;
        }
    }

    /// @dev Burns vault shares to this point of time.
    function _streamRewards() internal {
        StreamData memory stream = shareStream;

        if (stream.last < stream.end) {
            uint256 secondsToBurn = _secondsToBurn(stream);
            uint256 sharesToBurn = (secondsToBurn * stream.sharesPerSecond) /
                STREAM_PER_SECOND_SCALE;

            // Store the current timestamp which can be past the end.
            shareStream.last = SafeCast.toUint32(block.timestamp);

            // Burn the shares since the last time.
            _burn(address(this), sharesToBurn);

            emit Withdraw(msg.sender, address(0), address(this), 0, sharesToBurn);
        }
    }

    /**
     * @notice The number of shares after any liquidated shares are burnt.
     * @return shares The vault's total number of shares.
     * @dev If shares are being burnt, the `totalSupply` will decrease in every block.
     */
    function totalSupply() public view virtual override(ERC20, IERC20) returns (uint256 shares) {
        StreamData memory stream = shareStream;
        uint256 secondsToBurn = _secondsToBurn(stream);
        uint256 sharesToBurn = (secondsToBurn * stream.sharesPerSecond) / STREAM_PER_SECOND_SCALE;
        
        shares = ERC20.totalSupply() - sharesToBurn;
    }

    /**
     * @notice Converts donated tokens into vault assets, mints shares so the assets per share
     * does not increase initially, and then burns the new shares over a period of time
     * so the assets per share gradually increases.
     * @param token The address of the token being donated to the vault.
     @ @param amount The amount of tokens being donated to the vault.
     */
    function donate(address token, uint256 amount) external virtual override streamRewards {
        (uint256 newShares, uint256 newAssets) = _convertTokens(token, amount);

        StreamData memory stream = shareStream;
        uint256 remainingStreamShares = _streamedShares(stream);

        if (newShares > 0) {
            // Not all shares have to be streamed. Some may be used as a fee.
            (uint256 newStreamShares, uint256 streamAssets) = _beforeStreamShare(
                newShares,
                newAssets
            );

            uint256 sharesPerSecond = ((remainingStreamShares + newStreamShares) *
                STREAM_PER_SECOND_SCALE) / STREAM_DURATION;

            // Store updated stream data
            shareStream = StreamData(
                SafeCast.toUint32(block.timestamp),
                SafeCast.toUint32(block.timestamp + STREAM_DURATION),
                SafeCast.toUint128(sharesPerSecond)
            );

            // Mint new shares that will be burnt over time.
            _mint(address(this), newStreamShares);

            emit Deposit(msg.sender, address(this), streamAssets, newStreamShares);
        }
    }

    /**
     * @dev The base implementation assumes the donated token is the vault's asset token.
     * This can be overridden in implementing contracts.
     * Overriding implementations can also invest the assets into an underlying platform or vaults.
     */
    function _convertTokens(address token, uint256 amount)
        internal
        virtual
        returns (uint256 shares_, uint256 assets_)
    {
        require(token == address(_asset), "Donated token not asset");

        assets_ = amount;

        uint256 totalAssetsBefore = totalAssets();
        // if no assets in the vault yet then shares = assets
        // use the shares per asset when the existing streaming ends so remove the unstream shares from the total supply.
        shares_ = totalAssetsBefore == 0
            ? amount
            : (amount * (ERC20.totalSupply() - _streamedShares(shareStream))) / totalAssetsBefore;

        // Transfer assets from donor to vault.
        _asset.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev This implementation just returns the amount of new shares and assets. The can be overriden to take out a fee
     * or do something else with the shares.
     * @param newShares The total number of new shares to be minted in order to stream the increased in assets per share.
     * @param newAssets The total number of new assets being deposited.
     * @param streamShares The number of shares to be minted and then burnt over a period of time.
     * @param streamAssets The number of assets allocated to the streaming of shares.
     */
    function _beforeStreamShare(uint256 newShares, uint256 newAssets)
        internal
        virtual
        returns (uint256 streamShares, uint256 streamAssets)
    {
        streamShares = newShares;
        streamAssets = newAssets;
    }

    /**
     * @dev Base implementation returns the vault asset.
     * This can be overridden to swap rewards for other tokens.
     */
    function _donateToken(address) internal view virtual override returns (address token) {
        token = address(_asset);
    }

    /// @return remainingShares The amount of liquidated shares still to be burnt.
    function _streamedShares(StreamData memory stream)
        internal
        pure
        returns (uint256 remainingShares)
    {
        if (stream.last < stream.end) {
            uint256 secondsSinceLast = stream.end - stream.last;

            remainingShares = (secondsSinceLast * stream.sharesPerSecond) / STREAM_PER_SECOND_SCALE;
        }
    }

    /***************************************
            Streamed Rewards Views
    ****************************************/

    /**
     * @return remaining Amount of liquidated shares still to be burnt.
     */
    function streamedShares() external view returns (uint256 remaining) {
        StreamData memory stream = shareStream;
        remaining = _streamedShares(stream);
    }

    /***************************************
        Add streamRewards modifier
    ****************************************/

    function deposit(uint256 assets, address receiver)
        external
        virtual
        override
        whenNotPaused
        streamRewards
        returns (uint256 shares)
    {
        shares = _deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver)
        external
        virtual
        override
        whenNotPaused
        streamRewards
        returns (uint256 assets)
    {
        assets = _mint(shares, receiver);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external virtual override whenNotPaused streamRewards returns (uint256 assets) {
        assets = _redeem(shares, receiver, owner);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external virtual override whenNotPaused streamRewards returns (uint256 shares) {
        shares = _withdraw(assets, receiver, owner);
    }
}