// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IBKCommon {
    function setOperator(address[] calldata _operators, bool _isOperator) external;

    function pause() external;

    function unpause() external;

    function rescueETH(address recipient) external;

    function rescueERC20(address asset, address recipient) external;

    function rescueERC721(address asset, uint256[] calldata ids, address recipient) external;

    function rescueERC1155(address asset, uint256[] calldata ids, uint256[] calldata amounts, address recipient)  external;
}