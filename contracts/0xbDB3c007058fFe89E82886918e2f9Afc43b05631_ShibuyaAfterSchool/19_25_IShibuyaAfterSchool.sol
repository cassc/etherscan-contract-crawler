// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISBYASStaticData} from './ISBYASStaticData.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISBYASData} from './ISBYASData.sol';

interface IShibuyaAfterSchool is ISBYASData {
    function withdrawAddress() external view returns (address payable);

    function staticData() external view returns (ISBYASStaticData);

    function minted(address) external view returns (uint256);

    function phase() external view returns (ISBYASStaticData.Phase);

    function maxMintSupply() external view returns (uint16);

    function maxSupply() external view returns (uint256);

    function mint(uint256 length, bytes32[] calldata _merkleProof) external payable;

    function minterMint(uint256 length, address to) external;

    function burnerBurn(address _address, uint256[] calldata tokenIds) external;

    function withdraw() external;

    function setPhase(ISBYASStaticData.Phase _newPhase) external;

    function setMaxSupply(uint256 _newMaxSupply) external;

    function setMaxMintSupply(uint16 _maxMintSupply) external;
}