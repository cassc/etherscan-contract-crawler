// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../IFeedStrategy.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CurveLpReferenceFeedStrategyV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IFeedStrategy {

    using AddressUpgradeable for address;

    IFeedStrategy public referenceFeed;
    address public curvePool;
    uint256 public lpOneTokenAmount;
    uint128 public referenceCoinIndex;
    bytes public typeOfTokenIndex;
    uint8 public referenceCoinDecimals;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet,
        address _referenceFeedAddress, // price feed to use
        address _curvePoolAddress, // curve pool to use
        uint8 _referenceCoinIndex, // token index which feed (_referenceFeedAddress) we already have
        uint8 _referenceCoinDecimals, // decimals of coin in pool we are referring to
        uint256 _lpOneTokenAmount, // 1.0 of desired lp coin token with decimals
        bytes memory _typeOfTokenIndex
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);

        curvePool = _curvePoolAddress;
        referenceCoinIndex = _referenceCoinIndex;
        lpOneTokenAmount = _lpOneTokenAmount;
        referenceFeed = IFeedStrategy(_referenceFeedAddress);
        referenceCoinDecimals = _referenceCoinDecimals;
        typeOfTokenIndex = _typeOfTokenIndex;
    }

    function getPrice() external view returns (int256 value, uint8 decimals) {
        uint256 oneLpPrice;
        
        bytes memory curveCall = abi.encodeWithSignature(
            string(bytes.concat("calc_withdraw_one_coin(uint256,", typeOfTokenIndex,")")),
            lpOneTokenAmount,
            referenceCoinIndex
        );

        bytes memory data = curvePool.functionStaticCall(curveCall);
        oneLpPrice = abi.decode(data, (uint256));
        
        (int256 usdPrice, uint8 usdDecimals) = referenceFeed.getPrice();
        require(usdPrice > 0, "CurvePRFS: feed lte 0");

        return (int256(oneLpPrice) * usdPrice, usdDecimals + referenceCoinDecimals);
    }

    function getPriceOfAmount(uint256 amount) external view returns (int256 value, uint8 decimals){
        uint256 lpAmountPrice;

        bytes memory curveCall = abi.encodeWithSignature(
            string(bytes.concat("calc_withdraw_one_coin(uint256,", typeOfTokenIndex,")")),
            amount,
            referenceCoinIndex
        );

        bytes memory data = curvePool.functionStaticCall(curveCall);
        lpAmountPrice = abi.decode(data, (uint256));

        (int256 usdPrice, uint8 usdDecimals) = referenceFeed.getPrice();
        require(usdPrice > 0, "CurvePRFS: feed lte 0");
        return (int256(lpAmountPrice) * usdPrice, usdDecimals + referenceCoinDecimals);
    }



    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override {
    }

}