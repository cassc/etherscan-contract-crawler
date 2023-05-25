// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

interface IGenesisEthlizards {
    function batchTransferFrom(address _from, address _to, uint256[] calldata _tokenId) external;
}