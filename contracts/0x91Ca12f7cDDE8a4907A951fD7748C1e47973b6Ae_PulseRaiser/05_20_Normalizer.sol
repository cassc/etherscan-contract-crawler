// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// https://docs.chain.link/data-feeds/l2-sequencer-feeds
import "@chainlink/interfaces/AggregatorV3Interface.sol";
import "@chainlink/interfaces/AggregatorV2V3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OwnablePausable.sol";

import "./interfaces/INormalizer.sol";

interface IERC20Metadata_ {
    function decimals() external view returns (uint8);
}

abstract contract Normalizer is OwnablePausable, INormalizer {
    address public constant ARB_MAINNET_SEQ_FEED =
        0xFdB631F5EE196F0ed6FAa767959853A9F217697D;
    address public constant ARB_GOERLI_SEQ_FEED =
        0x4da69F028a5790fCCAfe81a75C0D24f46ceCDd69;

    uint256 private constant ARBITRUM_ONE = 42161;
    uint256 private constant ARBITRUM_NOVA = 42170;
    uint256 private constant ARBITRUM_GOERLI = 421613;
    uint256 private constant GRACE_PERIOD_TIME = 3600;

    AggregatorV2V3Interface public sequencerUptimeFeed;

    // map an asset to a feed that returns its conversion rate to normalized token
    mapping(address => address) public feeds;
    // enabled stablecoins like USDT, USDC, and BUSD that need no normalization
    mapping(address => bool) public stables;

    constructor() {
        if (block.chainid == ARBITRUM_ONE || block.chainid == ARBITRUM_NOVA) {
            sequencerUptimeFeed = AggregatorV2V3Interface(ARB_MAINNET_SEQ_FEED);
        } else if (block.chainid == ARBITRUM_GOERLI) {
            sequencerUptimeFeed = AggregatorV2V3Interface(ARB_GOERLI_SEQ_FEED);
        }
    }

    //
    // - MUTATORS (ADMIN)
    //
    function controlAssetsWhitelisting(
        address[] memory tokens_,
        address[] memory feeds_
    ) external {
        _checkOwner();

        _controlAssetsWhitelisting(tokens_, feeds_);
    }

    function controlStables(
        address[] memory stables_,
        bool[] memory states_
    ) external {
        _checkOwner();

        _controlStables(stables_, states_);
    }

    //
    // - INTERNALS
    //
    function _controlAssetsWhitelisting(
        address[] memory assets_,
        address[] memory feeds_
    ) internal {
        uint256 numAssets = assets_.length;
        for (uint256 f = 0; f < numAssets; f++) {
            require(assets_[f] != address(0), "Zero Asset Address");
            feeds[assets_[f]] = feeds_[f];
            if (feeds_[f] == address(0)) {
                emit AssetDisabled(assets_[f]);
            } else {
                emit AssetEnabled(assets_[f], feeds_[f]);
            }
        }
    }

    function _controlStables(
        address[] memory assets_,
        bool[] memory states_
    ) internal {
        require(assets_.length == states_.length, "Mismatched Arrays");

        for (uint8 f = 0; f < assets_.length; f++) {
            require(assets_[f] != address(0), "Zero Asset Address");
            stables[assets_[f]] = states_[f];
            if (states_[f]) {
                emit AssetEnabled(assets_[f], assets_[f]);
            } else {
                emit AssetDisabled(assets_[f]);
            }
        }
    }

    function _requireTokenWhitelisted(address asset_) internal view {
        require(
            feeds[asset_] != address(0) || stables[asset_],
            "Invalid Payment Asset"
        );
    }

    function _normalize(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        if (token == address(0)) return 0;
        if (stables[token]) {
            return amount * (10 ** (18 - IERC20Metadata_(token).decimals()));
        }

        return _priceFeedNormalize(token, amount);
    }

    function _priceFeedNormalize(
        address token,
        uint256 amount
    ) internal view returns (uint256) {
        _ensureSequencerUp();
        AggregatorV3Interface priceFeed = AggregatorV3Interface(feeds[token]);

        (, int price, , , ) = priceFeed.latestRoundData();

        uint8 tokenDecimals = IERC20Metadata_(token).decimals();

        return
            ((uint256(price) * amount) / (10 ** priceFeed.decimals())) *
            (10 ** (18 - tokenDecimals));
    }

    function _ensureSequencerUp() internal view {
        // short-circuit if we're not on Arbitrum
        if (address(sequencerUptimeFeed) == address(0)) return;

        // prettier-ignore
        (
            /*uint80 roundID*/,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        require(isSequencerUp, "ARB: Sequencer Is Down");

        // Make sure the grace period has passed after the
        // sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        require(timeSinceUp > GRACE_PERIOD_TIME, "ARB: Grace Period Not Over");
    }
}