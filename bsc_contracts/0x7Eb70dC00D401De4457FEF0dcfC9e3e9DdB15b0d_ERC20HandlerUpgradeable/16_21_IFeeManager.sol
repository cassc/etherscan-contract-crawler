// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

interface IFeeManagerUpgradeable {
    function setFees(
        uint8 destinationChainID,
        address[] calldata feeTokenAddrs,
        uint256[] calldata transferFees,
        uint256[] calldata exchangeFees,
        bool[] calldata accepted
    ) external;

    function withdrawFee(address tokenAddress, address recipient, uint256 amount) external;

    function setFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) external;

    function getFee(uint8 destinationChainID, address feeTokenAddress, uint256 widgetID) external view returns (uint256, uint256, uint256);

    function depositWidgetFee(uint256 widgetID, address feeTokenAddress, uint256 feeAmount) external;
}