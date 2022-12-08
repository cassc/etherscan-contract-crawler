// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface INFTStrategy {

    enum Kind {
        STANDARD,
        FLASH
    }

    function kind() external view returns (Kind);
    function depositAddress(address _account) external view returns (address);
    function afterDeposit(address _owner, uint256[] calldata _nftIndexes, bytes calldata _data) external;
    function withdraw(address _owner, address _recipient, uint256 _nftIndex) external;
}