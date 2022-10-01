// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IXtatuzPricing {

    function marketPrice(address propertyAddress_, uint256 tokenId) external view returns(uint256);

    function setOperator(address operator_) external;

    function setRouterAddress(address routerAddress_) external;

}