// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../IFeedStrategy.sol";

interface ICurvePool {
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CurvePoolReferenceFeedStrategyV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IFeedStrategy {

    IFeedStrategy public referenceFeed;
    ICurvePool public curvePool;
    int8 public referenceCoinIndex;
    int8 public desiredCoinIndex;
    uint8 public referenceCoinDecimals;
    uint256 public desiredOneTokenAmount;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet,
        address _referenceFeedAddress, // price feed to use
        address _curvePoolAddress, // curve pool to use
        int8 _referenceCoinIndex, // token index which feed (_referenceFeedAddress) we already have
        int8 _desiredCoinIndex, // index of coin in pool we are desiring
        uint8 _referenceCoinDecimals, // decimals of coin in pool we are referring to
        uint256 _desiredOneTokenAmount // 1.0 of desired coin token with decimals
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);

        curvePool = ICurvePool(_curvePoolAddress);
        referenceCoinIndex = _referenceCoinIndex;
        desiredCoinIndex = _desiredCoinIndex;
        desiredOneTokenAmount = _desiredOneTokenAmount;
        referenceFeed = IFeedStrategy(_referenceFeedAddress);
        referenceCoinDecimals = _referenceCoinDecimals;

    }

    function getPrice() external view returns (int256 value, uint8 decimals) {
        uint256 oneTokenPrice = curvePool.get_dy(
            desiredCoinIndex,
            referenceCoinIndex,
            desiredOneTokenAmount
        );

        (int256 usdPrice, uint8 usdDecimals) = referenceFeed.getPrice();
        require(usdPrice > 0, "CurvePRFS: feed lte 0");

        return (int256(oneTokenPrice) * usdPrice, usdDecimals + referenceCoinDecimals);
    }

    function getPriceOfAmount(uint256 amount) external view returns (int256 value, uint8 decimals){
        uint256 tokenAmountPrice = curvePool.get_dy(
            desiredCoinIndex,
            referenceCoinIndex,
            amount
        );
        (int256 usdPrice, uint8 usdDecimals) = referenceFeed.getPrice();
        require(usdPrice > 0, "CurvePRFS: feed lte 0");
        return (int256(tokenAmountPrice) * usdPrice, usdDecimals + referenceCoinDecimals);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override {
    }

}