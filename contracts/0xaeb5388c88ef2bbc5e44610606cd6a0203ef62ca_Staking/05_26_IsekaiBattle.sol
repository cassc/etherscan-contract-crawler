// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC721A} from 'erc721a/contracts/ERC721A.sol';
import {ISGData, IISBStaticData} from './extensions/ISGData.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './interface/IIsekaiBattle.sol';

contract IsekaiBattle is IIsekaiBattle, ERC721A('Isekai Battle', 'ISB'), ISGData, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address payable public constant override withdrawAddress = payable(0xbbaF7550c32634f22E989252CD9070b38eFABa42);
    IISBStaticData public immutable override staticData;

    mapping(address => bool) public override whitelist;
    mapping(address => uint256) public override whitelistMinted;

    IISBStaticData.Phase public override phase = IISBStaticData.Phase.BeforeMint;

    uint16 public override minMintSupply = 3;
    uint16 public override maxMintSupply = 15;
    uint256 public override maxSupply = 30000;
    bool public override resetLevel = false;
    bool public override saveTransferTime = true;

    IISBStaticData.Tokens public override tokens;

    constructor(IISBStaticData _staticData) ISGData() {
        staticData = _staticData;
    }

    function mintByTokens(uint16[] calldata characterIds) external override nonReentrant {
        _mintByTokensCheck(characterIds.length);
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            if (getSINNPrice(characterIds.length) > 0 && address(tokens.SINN) != address(0))
                tokens.SINN.safeTransferFrom(
                    _msgSender(),
                    withdrawAddress,
                    getSINNPrice(characterIds.length) * characterIds.length
                );
            if (getGOVPrice(characterIds.length) > 0 && address(tokens.GOV) != address(0))
                tokens.GOV.safeTransferFrom(
                    _msgSender(),
                    withdrawAddress,
                    getGOVPrice(characterIds.length) * characterIds.length
                );
        }
        _mintSetMetadata(characterIds);
        _safeMint(_msgSender(), characterIds.length);
    }

    function mint(uint16[] calldata characterIds) external payable override nonReentrant {
        _mintCheck(characterIds.length);
        _mintSetMetadata(characterIds);
        _safeMint(_msgSender(), characterIds.length);
    }

    function whitelistMint(uint16[] calldata characterIds) external payable override nonReentrant {
        _WLMintCheck(characterIds.length);
        _mintSetMetadata(characterIds);
        whitelistMinted[_msgSender()] += characterIds.length;
        _safeMint(_msgSender(), characterIds.length);
    }

    function minterMint(uint16[] calldata characterIds, address to) external override onlyRole(MINTER_ROLE) {
        _mintSetMetadata(characterIds);
        _safeMint(to, characterIds.length);
    }

    function burn(uint256 tokenId) external override onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function withdraw() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool os, ) = withdrawAddress.call{value: address(this).balance}('');
        require(os);
    }

    function setWhitelist(address[] memory addresses) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
        }
    }

    function deleteWhitelist(address[] memory addresses) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
        }
    }

    function setTokens(IISBStaticData.Tokens memory _newTokens) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        tokens = _newTokens;
    }

    function setPhase(IISBStaticData.Phase _newPhase) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        phase = _newPhase;
    }

    function setMaxSupply(uint256 _newMaxSupply) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = _newMaxSupply;
    }

    function setResetLevel(bool _newResetLevel) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        resetLevel = _newResetLevel;
    }

    function setSaveTransferTime(bool _newSaveTransferTime) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        saveTransferTime = _newSaveTransferTime;
    }

    function setMinMintSupply(uint16 _minMintSupply) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        minMintSupply = _minMintSupply;
    }

    function setMaxMintSupply(uint16 _maxMintSupply) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintSupply = _maxMintSupply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return
            staticData.createMetadata(
                tokenId,
                characters[metadatas[tokenId].characterId],
                metadatas[tokenId],
                getStatus(tokenId),
                statusMasters,
                images[characters[metadatas[tokenId].characterId].imageId],
                getGenneration(tokenId)
            );
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ISGData) returns (bool) {
        return interfaceId == type(IIsekaiBattle).interfaceId || super.supportsInterface(interfaceId);
    }

    function _mintSetMetadata(uint16[] calldata characterIds) internal virtual {
        for (uint256 i = 0; i < characterIds.length; i++) {
            if (characters[characterIds[i]].canBuy == false) revert MintCannotBuyCharacter();
            metadatas[_currentIndex + i].characterId = characterIds[i];
            metadatas[_currentIndex + i].level = 1;
        }
    }

    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (quantity != 1) return;
        if (resetLevel) metadatas[startTokenId].level = 1;
        if (saveTransferTime) metadatas[startTokenId].transferTime = block.timestamp;
    }

    function _mintByTokensCheck(uint256 length) internal view virtual {
        if (phase != IISBStaticData.Phase.MintByTokens) revert BeforeMint();
        if (totalSupply() + length > maxSupply) revert MintReachedMaxSupply();
        if (maxMintSupply < length) revert MintMaxSupply();
        uint256 allowance = type(uint256).max;
        if (address(tokens.SINN) != address(0)) {
            allowance = tokens.SINN.allowance(_msgSender(), address(this));
        }
        uint256 govAllowance = type(uint256).max;
        if (address(tokens.GOV) != address(0)) {
            allowance = tokens.GOV.allowance(_msgSender(), address(this));
        }
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender())) {
            if (allowance < getSINNPrice(length) * length) revert MintValueIsMissing();
            if (govAllowance < getGOVPrice(length) * length) revert MintValueIsMissing();
        }
    }

    function _mintCheck(uint256 length) internal view virtual {
        if (phase != IISBStaticData.Phase.PublicMint) revert BeforeMint();
        if (totalSupply() + length > maxSupply) revert MintReachedMaxSupply();
        if (minMintSupply > length) revert MintMinSupply();
        if (maxMintSupply < length) revert MintMaxSupply();
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender()))
            if (msg.value < getPrice(length) * length) revert MintValueIsMissing();
    }

    function _WLMintCheck(uint256 length) internal view virtual {
        if (phase != IISBStaticData.Phase.WLMint) revert BeforeMint();
        if (minMintSupply > length) revert MintMinSupply();
        if (!whitelist[_msgSender()]) revert MintNotWhitelisted();
        if (whitelistMinted[_msgSender()] + length > maxMintSupply) revert MintReachedWhitelistSaleSupply();
        if (!hasRole(DEFAULT_ADMIN_ROLE, _msgSender()))
            if (msg.value < getWLPrice(length) * length) revert MintValueIsMissing();
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}