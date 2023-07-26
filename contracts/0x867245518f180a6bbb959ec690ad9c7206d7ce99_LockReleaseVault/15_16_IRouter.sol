// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IRouter {
    event BridgeDeposit(
        uint256 nonce,
        address vault,
        uint256 amount,
        uint16 destinationChainId,
        bytes destinationAddress,
        uint32 protocolId
    );
    event BridgeRelease(
        uint256 nonce,
        address vault,
        address destinationAddress,
        uint256 amount,
        uint16 feeRate,
        bytes32 depositId
    );
    event BridgeRefund(
        uint256 nonce,
        address vault,
        address destinationAddress,
        uint256 amount,
        bytes32 depositId
    );
    event VaultAdd(address vaultAddress);
    event SetFeeCollector(address feeCollector);
    event SetMaxFeeRate(uint16 _maxFeeRate);

    function CONTRACT_ID() external pure returns (bytes32);

    function deposit(
        address _vault,
        uint256 _amount,
        uint16 _destinationChainId,
        bytes calldata _destinationAddress,
        uint32 _protocolId
    ) external payable;

    function feeCollector() external view returns (address);

    function isActive() external view returns (bool);

    function refund(
        address _vault,
        address _destinationAddress,
        uint256 _amount,
        bytes32 _depositId
    ) external payable;

    function release(
        address _vault,
        address _destinationAddress,
        uint256 _amount,
        uint16 _feeRate,
        bytes32 _depositId
    ) external payable;

    function setFeeCollector(address _feeCollector) external;

    function setMaxFeeRate(uint16 _maxFeeRate) external;
}