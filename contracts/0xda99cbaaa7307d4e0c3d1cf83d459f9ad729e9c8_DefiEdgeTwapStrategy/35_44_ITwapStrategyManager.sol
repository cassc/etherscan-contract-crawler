//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.6;

import "./ITwapStrategyFactory.sol";

interface ITwapStrategyManager {
    function isUserWhiteListed(address _account) external view returns (bool);

    function isAllowedToManage(address) external view returns (bool);

    function isAllowedToBurn(address) external view returns (bool);

    function managementFeeRate() external view returns (uint256); // 1e8 decimals

    function performanceFeeRate() external view returns (uint256); // 1e8 decimals

    function operator() external view returns (address);

    function limit() external view returns (uint256);

    function feeTo() external view returns (address);

    function factory() external view returns (ITwapStrategyFactory);

    function incrementSwapCounter() external;

    function twapPricePeriod() external view returns (uint256);
}