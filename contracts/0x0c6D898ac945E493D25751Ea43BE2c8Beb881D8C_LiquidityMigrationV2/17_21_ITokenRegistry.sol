//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "../IEstimator.sol";

interface ITokenRegistry {
    function itemCategories(address token) external view returns (uint256);

    function estimatorCategories(address token) external view returns (uint256);

    function estimators(uint256 categoryIndex) external view returns (IEstimator);

    function getEstimator(address token) external view returns (IEstimator);

    function addEstimator(uint256 estimatorCategoryIndex, address estimator) external;

    function addItem(uint256 itemCategoryIndex, uint256 estimatorCategoryIndex, address token) external;
}