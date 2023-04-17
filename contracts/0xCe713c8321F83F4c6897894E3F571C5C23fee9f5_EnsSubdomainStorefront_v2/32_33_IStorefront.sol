// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "src/structs/SaleConfig.sol";
import "src/interfaces/IPriceOracle.sol";

interface IStorefront {
    function setUpDomains(
        uint256[] calldata _ids,
        SaleConfig[] calldata _configs
    ) external;

    function purchaseDomains(
        uint256[] calldata _ids,
        string[] calldata _labels,
        address[] calldata _mintTo,
        address _resolver,
        uint64[] calldata _duration
    ) external payable;

    function renewSubdomain(
        uint256[] calldata _ids,
        string[] calldata _labels,
        uint64[] calldata _durations
    ) external payable;

    function setGlobalSalesDisabled(bool _isDisabled) external;

    function getPrices(
        uint256[] calldata _ids,
        uint64[] calldata _durations
    ) external view returns (uint256[] memory);

    function withdrawFunds() external;

    function updateVisionFee(uint256 _visionPercent) external;

    // function salesConfigs(
    //     uint256
    // ) external view returns (address owner, uint88 price, bool isForSale, uint256 dailyRent);

    function dailyRenewalPrice(uint256 _id) external view returns (uint256);

    function isSalesDisabled(address _user) external view returns (bool);
}