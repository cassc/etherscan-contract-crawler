// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../IFeedStrategy.sol";
import "./../../../interfaces/IChainlinkPriceFeed.sol";

import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ChainlinkFeedStrategyV2 is
    Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    IFeedStrategy {

    IChainlinkPriceFeed public chainlinkFeed;
    address public token;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _multiSigWallet,
        address _chainlinkFeedAddress,
        address _token
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _multiSigWallet);

        chainlinkFeed = IChainlinkPriceFeed(_chainlinkFeedAddress);
        token = _token;
    }

    function getPrice() external view returns (int256 value, uint8 decimals) {
        return (chainlinkFeed.latestAnswer(), chainlinkFeed.decimals());
    }

    function getPriceOfAmount(uint256 amount) external view returns (int256 value, uint8 decimals){
        uint8 totalDecimals = chainlinkFeed.decimals();
        if(token != address(0)){
            totalDecimals += IERC20Metadata(token).decimals();
        }
        return (chainlinkFeed.latestAnswer() * int256(amount), totalDecimals);
    }


    function _authorizeUpgrade(address newImplementation)
    internal
    onlyRole(DEFAULT_ADMIN_ROLE)
    override {}
}