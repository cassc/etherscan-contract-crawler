// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import {IISBStaticData} from './IISBStaticData.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IISGData} from './IISGData.sol';

error BeforeMint();
error MintReachedMaxSupply();
error MintReachedSaleSupply();
error MintReachedWhitelistSaleSupply();
error MintValueIsMissing();
error MintCannotBuyCharacter();
error MintMinSupply();
error MintMaxSupply();
error MintNotWhitelisted();

interface IIsekaiBattle is IISGData {
    function withdrawAddress() external view returns (address payable);

    function staticData() external view returns (IISBStaticData);

    function whitelist(address) external view returns (bool);

    function whitelistMinted(address) external view returns (uint256);

    function phase() external view returns (IISBStaticData.Phase);

    function minMintSupply() external view returns (uint16);

    function maxMintSupply() external view returns (uint16);

    function maxSupply() external view returns (uint256);

    function resetLevel() external view returns (bool);

    function saveTransferTime() external view returns (bool);

    function tokens() external view returns (IERC20, IERC20);

    function mintByTokens(uint16[] calldata characterIds) external;

    function mint(uint16[] calldata characterIds) external payable;

    function whitelistMint(uint16[] calldata characterIds) external payable;

    function minterMint(uint16[] calldata characterIds, address to) external;

    function burn(uint256 tokenId) external;

    function withdraw() external;

    function setWhitelist(address[] memory addresses) external;

    function deleteWhitelist(address[] memory addresses) external;

    function setTokens(IISBStaticData.Tokens memory _newTokens) external;

    function setPhase(IISBStaticData.Phase _newPhase) external;

    function setMaxSupply(uint256 _newMaxSupply) external;

    function setResetLevel(bool _newResetLevel) external;

    function setSaveTransferTime(bool _newSaveTransferTime) external;

    function setMinMintSupply(uint16 _minMintSupply) external;

    function setMaxMintSupply(uint16 _maxMintSupply) external;
}