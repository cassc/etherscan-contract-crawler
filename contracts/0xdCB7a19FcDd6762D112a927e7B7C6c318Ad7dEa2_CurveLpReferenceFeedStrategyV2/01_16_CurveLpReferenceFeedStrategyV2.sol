// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../IFeedStrategy.sol";

interface ICurvePool {
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, uint256 i)
        external
        view
        returns (uint256);
}

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CurveLpReferenceFeedStrategyV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IFeedStrategy {

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    IFeedStrategy public referenceFeed;
    ICurvePool public curvePool;
    uint256 public lpOneTokenAmount;
    uint128 public referenceCoinIndex;
    uint16 public typeOfTokenIndex;
    uint8 public referenceCoinDecimals;
    bool public upgradeStatus;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet,
        address _referenceFeedAddress, // price feed to use
        address _curvePoolAddress, // curve pool to use
        uint8 _referenceCoinIndex, // token index which feed (_referenceFeedAddress) we already have
        uint8 _referenceCoinDecimals, // decimals of coin in pool we are referring to
        uint256 _lpOneTokenAmount, // 1.0 of desired lp coin token with decimals
        uint16 _typeOfTokenIndex
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);
        _grantRole(UPGRADER_ROLE, _multiSigWallet);

        curvePool = ICurvePool(_curvePoolAddress);
        referenceCoinIndex = _referenceCoinIndex;
        lpOneTokenAmount = _lpOneTokenAmount;
        referenceFeed = IFeedStrategy(_referenceFeedAddress);
        referenceCoinDecimals = _referenceCoinDecimals;
        typeOfTokenIndex = _typeOfTokenIndex;
    }

    function getPrice() external view returns (int256 value, uint8 decimals) {
        uint256 oneLpPrice;
        
        if(typeOfTokenIndex == 128){
            oneLpPrice = curvePool.calc_withdraw_one_coin(
                lpOneTokenAmount,
                int128(referenceCoinIndex)
            );
        }
        else{
            oneLpPrice = curvePool.calc_withdraw_one_coin(
                lpOneTokenAmount,
                uint256(referenceCoinIndex)
            );
        }
        
        (int256 usdPrice, uint8 usdDecimals) = referenceFeed.getPrice();
        require(usdPrice > 0, "CurvePRFS: feed lte 0");

        return (int256(oneLpPrice) * usdPrice, usdDecimals + referenceCoinDecimals);
    }

    function getPriceOfAmount(uint256 amount) external view returns (int256 value, uint8 decimals){
        uint256 lpAmountPrice = curvePool.calc_withdraw_one_coin(
            amount,
            referenceCoinIndex
        );
        (int256 usdPrice, uint8 usdDecimals) = referenceFeed.getPrice();
        require(usdPrice > 0, "CurvePRFS: feed lte 0");
        return (int256(lpAmountPrice) * usdPrice, usdDecimals + referenceCoinDecimals);
    }

    function changeUpgradeStatus(bool _status)
    external
    onlyRole(DEFAULT_ADMIN_ROLE) {
        upgradeStatus = _status;
    }


    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(UPGRADER_ROLE)
    override {
        require(upgradeStatus, "Executor: Upgrade not allowed");
        upgradeStatus = false;
    }

}