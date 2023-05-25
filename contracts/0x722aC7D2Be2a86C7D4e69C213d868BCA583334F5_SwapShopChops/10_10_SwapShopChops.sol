// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// SwapShop Chops by Seedphrase.eth 🎩
// Use at https://chops.swapshop.pro 🥩
// Built by https://www.tokenpage.xyz 🚀

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

error CannotSwapWolf();
error Gen0SwapsNotEnabled();
error Gen1SwapsNotEnabled();
error Gen2SwapsNotEnabled();
error Gen2MinEnergyMaxNotReached();
error InvalidSignature();
error NotAuthorized();

interface IWoolf {
    struct SheepWolf {
        bool isSheep;
        uint8 fur;
        uint8 head;
        uint8 ears;
        uint8 eyes;
        uint8 nose;
        uint8 mouth;
        uint8 neck;
        uint8 feet;
        uint8 alphaIndex;
    }
    function getTokenTraits(uint256 tokenId) external view returns (SheepWolf memory);
    function getPaidTokens() external view returns (uint256);
}

interface IWolfGameReborn {
    function woolf() external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IWolfGameGen2 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IWOOL is IERC20 {
}

contract SwapShopChops is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    event ChopSwap(uint256 swapId, address swapper, uint256 chopsAmount);

    IWoolf public wolfGame;
    IWolfGameReborn public wolfGameReborn;
    IWolfGameGen2 public wolfGameGen2;
    address public controller;
    uint256 public lastSwapId;
    bool public isGen0SwapsEnabled;
    bool public isGen1SwapsEnabled;
    bool public isGen2SwapsEnabled;
    uint256 public gen0ChopsPerEnergyMax;
    uint256 public gen1ChopsPerEnergyMax;
    uint256 public gen2ChopsPerEnergyMax;
    uint256 public gen2MinimumEnergyMax;
    address public serverSigner;

    constructor(address initialWolfGameRebornAddress, address initialWolfGameGen2Address, address initialController)
    Ownable() {
        wolfGameReborn = IWolfGameReborn(initialWolfGameRebornAddress);
        wolfGame = IWoolf(wolfGameReborn.woolf());
        wolfGameGen2 = IWolfGameGen2(initialWolfGameGen2Address);
        controller = initialController;
    }

    // Util

    modifier onlyOwnerOrController() {
        if (owner() != _msgSender() && controller != _msgSender()) {
            revert NotAuthorized();
        }
        _;
    }

    // Admin

    function setController(address newController) external onlyOwner {
        controller = newController;
    }

    function pause() external onlyOwnerOrController {
        _pause();
    }

    function unpause() external onlyOwnerOrController {
        _unpause();
    }

    function setPrices(bool newIsGen0SwapsEnabled, bool newIsGen1SwapsEnabled, bool newIsGen2SwapsEnabled, uint256 newGen0ChopsPerEnergyMax, uint256 newGen1ChopsPerEnergyMax, uint256 newGen2ChopsPerEnergyMax, uint256 newGen2MinimumEnergyMax) external onlyOwnerOrController {
        isGen0SwapsEnabled = newIsGen0SwapsEnabled;
        isGen1SwapsEnabled = newIsGen1SwapsEnabled;
        isGen2SwapsEnabled = newIsGen2SwapsEnabled;
        gen0ChopsPerEnergyMax = newGen0ChopsPerEnergyMax;
        gen1ChopsPerEnergyMax = newGen1ChopsPerEnergyMax;
        gen2ChopsPerEnergyMax = newGen2ChopsPerEnergyMax;
        gen2MinimumEnergyMax = newGen2MinimumEnergyMax;
    }

    function setServerSigner(address newServerSigner) external onlyOwnerOrController {
        serverSigner = newServerSigner;
    }

    // Views

    function getPrices() external view returns (bool, bool, bool, uint256, uint256, uint256, uint256) {
        return (isGen0SwapsEnabled, isGen1SwapsEnabled, isGen2SwapsEnabled, gen0ChopsPerEnergyMax, gen1ChopsPerEnergyMax, gen2ChopsPerEnergyMax, gen2MinimumEnergyMax);
    }

    // Users

    function _checkIsSheep(uint tokenId) internal view {
        IWoolf.SheepWolf memory tokenTraits = wolfGame.getTokenTraits(tokenId);
        if (!tokenTraits.isSheep) {
            revert CannotSwapWolf();
        }
    }

    function _validateGen2Energies(uint256[] calldata gen2TokenIds, uint16[] calldata gen2TokenEnergyMaxs, bytes calldata gen2TokensSignature) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(gen2TokenIds, gen2TokenEnergyMaxs));
        address signer = messageHash.toEthSignedMessageHash().recover(gen2TokensSignature);
        if (signer != serverSigner) {
            revert InvalidSignature();
        }
    }

    function chopSwapSheep(uint256[] calldata gen0Gen1TokenIds, uint256[] calldata gen2TokenIds, uint16[] calldata gen2TokenEnergyMaxs, bytes calldata gen2TokensSignature) external nonReentrant whenNotPaused {
        if (gen2TokenIds.length > 0) {
            _validateGen2Energies(gen2TokenIds, gen2TokenEnergyMaxs, gen2TokensSignature);
        }
        lastSwapId++;
        uint256 gen0TokenCount;
        uint256 gen1TokenCount;
        uint256 paidTokenCount = wolfGame.getPaidTokens();
        for (uint256 i = 0; i < gen0Gen1TokenIds.length; i++) {
            uint256 gen0Gen1TokenId = gen0Gen1TokenIds[i];
            _checkIsSheep(gen0Gen1TokenId);
            if (gen0Gen1TokenId <= paidTokenCount) {
                gen0TokenCount += 1;
            } else {
                gen1TokenCount += 1;
            }
            wolfGameReborn.transferFrom(_msgSender(), controller, gen0Gen1TokenId);
        }
        uint256 gen2TotalEnergyMax = 0;
        for (uint256 i = 0; i < gen2TokenIds.length; i++) {
            if (gen2TokenEnergyMaxs[i] < gen2MinimumEnergyMax) {
                revert Gen2MinEnergyMaxNotReached();
            }
            gen2TotalEnergyMax += gen2TokenEnergyMaxs[i];
            wolfGameGen2.transferFrom(_msgSender(), controller, gen2TokenIds[i]);
        }
        if (gen0TokenCount > 0 && !isGen0SwapsEnabled) {
            revert Gen0SwapsNotEnabled();
        }
        if (gen1TokenCount > 0 && !isGen1SwapsEnabled) {
            revert Gen1SwapsNotEnabled();
        }
        if (gen2TokenIds.length > 0 && !isGen2SwapsEnabled) {
            revert Gen2SwapsNotEnabled();
        }
        uint256 chopsAmount = (gen0TokenCount * 1000 * gen0ChopsPerEnergyMax) + (gen1TokenCount * 800 * gen1ChopsPerEnergyMax) + (gen2TotalEnergyMax * gen2ChopsPerEnergyMax);
        emit ChopSwap(lastSwapId, _msgSender(), chopsAmount);
    }

}