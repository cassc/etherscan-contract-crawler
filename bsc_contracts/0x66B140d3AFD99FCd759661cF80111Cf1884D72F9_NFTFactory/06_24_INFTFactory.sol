// SPDX-License-Identifier: bsl-1.1
/**
 * Copyright 2022 Raise protocol ([email protected])
 */
pragma solidity ^0.8.0;

import "./IWithBalance.sol";
import "./INFT.sol";
import "./INFTRepresentation.sol";

interface INFTFactory {

    event NFTContractCreated(address indexed nftContract, address indexed owner);
    event NFTContractOwnerChanged(address indexed nftContract, address indexed oldOwner, address indexed newOwner);

    event NFTTransferred(address indexed nftContract, address indexed from, address indexed to, uint tokenId);

    event RequiredTokenToMintChanged(address token, uint amount);

    function requiredTokenToMint() external view returns (IWithBalance);
    function requiredTokenToMintAmount() external view returns (uint);

    function nftRepresentation() external view returns (INFTRepresentation);

    function trackNftContractOwners(address _oldOwner, address _newOwner) external;
    function trackTokenTransfer(address _owner, address _from, address _to, uint _tokenId) external;
}