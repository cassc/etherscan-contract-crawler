// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./IGenericNFTStrategy.sol";

interface IStandardNFTStrategy is IGenericNFTStrategy {
    function afterDeposit(address _owner, uint256[] calldata _nftIndexes, bytes calldata _data) external;
    function withdraw(address _owner, address _recipient, uint256 _nftIndex) external;
    function flashLoanStart(address _owner, address _recipient, uint256[] calldata _nftIndexes, bytes calldata _additionalData) external returns (address _depositAddress);
    function flashLoanEnd(address _owner, uint256[] calldata _nftIndexes, bytes calldata _additionalData) external;
    function isDeposited(address _owner, uint256 _nftIndex) external view returns (bool);
}