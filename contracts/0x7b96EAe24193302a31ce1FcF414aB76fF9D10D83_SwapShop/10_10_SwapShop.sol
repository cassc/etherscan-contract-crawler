// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// SwapShop by Seedphrase.eth :tophat:
// Use at https://swapshop.pro :sheep:
// Built by https://www.tokenpage.xyz :rocket:

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

error CannotLoadWolf();
error CannotSwapWolf();
error NoSheepLoaded();
error NoSheepSwapped();
error InsufficientEthPayment();
error InsufficientWoolPayment();
error NotAuthorized();
error NotDelegatedSheep();
error InvalidRequest();
error NotDowngradable();
error NotUpgradable();
error PromoCodeTokenLimitReached();
error PromoCodeAlreadyUsed();
error InvalidSignature();

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

interface IWOOL is IERC20 {
}

contract SwapShop is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    IWOOL public wool;
    IWoolf public wolfGame;
    IWolfGameReborn public wolfGameReborn;
    EnumerableSet.UintSet private _gen0SheepIds;
    EnumerableSet.UintSet private _gen1SheepIds;
    address public delegator;
    uint256 public gen0BasicEthPrice;
    uint256 public gen1BasicEthPrice;
    uint256 public gen0BasicWoolPrice;
    uint256 public gen1BasicWoolPrice;
    uint256 public gen0AdvancedEthPrice;
    uint256 public gen1AdvancedEthPrice;
    uint256 public gen0AdvancedWoolPrice;
    uint256 public gen1AdvancedWoolPrice;
    uint256 public upgradeAdditionalEthPrice;
    uint256 public upgradeAdditionalWoolPrice;
    uint256 public promoCodeTokenLimit = 1;
    mapping (string => address) public promoCodeUserMap;
    address public serverSigner;

    constructor(address initialWolfGameRebornAddress, address initialWoolAddress, address initialDelegator, uint256 initialSwapEthPrice, uint256 initialSwapWoolPrice, uint256 initialUpgradeAdditionalEthPrice, uint256 initialUpgradeAdditionalWoolPrice)
    Ownable() {
        wolfGameReborn = IWolfGameReborn(initialWolfGameRebornAddress);
        wolfGame = IWoolf(wolfGameReborn.woolf());
        wool = IWOOL(initialWoolAddress);
        delegator = initialDelegator;
        gen0BasicEthPrice = initialSwapEthPrice;
        gen1BasicEthPrice = initialSwapEthPrice;
        gen0BasicWoolPrice = initialSwapWoolPrice;
        gen1BasicWoolPrice = initialSwapWoolPrice;
        gen0AdvancedEthPrice = initialSwapEthPrice;
        gen1AdvancedEthPrice = initialSwapEthPrice;
        gen0AdvancedWoolPrice = initialSwapWoolPrice;
        gen1AdvancedWoolPrice = initialSwapWoolPrice;
        upgradeAdditionalEthPrice = initialUpgradeAdditionalEthPrice;
        upgradeAdditionalWoolPrice = initialUpgradeAdditionalWoolPrice;
    }

    // Util

    modifier onlyDelegator() {
        if (delegator != _msgSender()) {
            revert NotAuthorized();
        }
        _;
    }

    modifier onlyOwnerOrDelegator() {
        if (owner() != _msgSender() && delegator != _msgSender()) {
            revert NotAuthorized();
        }
        _;
    }

    // Views

    function stock() external view returns (uint256[] memory gen0SheepIds, uint256[] memory gen1SheepIds) {
        return (_gen0SheepIds.values(), _gen1SheepIds.values());
    }

    function getPrices() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (gen0BasicEthPrice, gen1BasicEthPrice, gen0BasicWoolPrice, gen1BasicWoolPrice, gen0AdvancedEthPrice, gen1AdvancedEthPrice, gen0AdvancedWoolPrice, gen1AdvancedWoolPrice, upgradeAdditionalEthPrice, upgradeAdditionalWoolPrice);
    }

    // Admin

    function setDelegator(address newDelegator) external onlyOwner {
        delegator = newDelegator;
    }

    function withdrawEth() external onlyOwnerOrDelegator {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function withdrawErc20(address tokenAddress) public onlyOwnerOrDelegator {
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(owner(), amount);
    }

    function withdrawWool() external onlyOwnerOrDelegator {
        withdrawErc20(address(wool));
    }

    function pause() external onlyOwnerOrDelegator {
        _pause();
    }

    function unpause() external onlyOwnerOrDelegator {
        _unpause();
    }

    function updatePrices(uint256 newGen0BasicEthPrice, uint256 newGen1BasicEthPrice, uint256 newGen0BasicWoolPrice, uint256 newGen1BasicWoolPrice, uint256 newGen0AdvancedEthPrice, uint256 newGen1AdvancedEthPrice, uint256 newGen0AdvancedWoolPrice, uint256 newGen1AdvancedWoolPrice, uint256 newUpgradeAdditionalEthPrice, uint256 newUpgradeAdditionalWoolPrice) external onlyOwnerOrDelegator {
        gen0BasicEthPrice = newGen0BasicEthPrice;
        gen1BasicEthPrice = newGen1BasicEthPrice;
        gen0BasicWoolPrice = newGen0BasicWoolPrice;
        gen1BasicWoolPrice = newGen1BasicWoolPrice;
        gen0AdvancedEthPrice = newGen0AdvancedEthPrice;
        gen1AdvancedEthPrice = newGen1AdvancedEthPrice;
        gen0AdvancedWoolPrice = newGen0AdvancedWoolPrice;
        gen1AdvancedWoolPrice = newGen1AdvancedWoolPrice;
        upgradeAdditionalEthPrice = newUpgradeAdditionalEthPrice;
        upgradeAdditionalWoolPrice = newUpgradeAdditionalWoolPrice;
    }

    function setServerSigner(address newServerSigner) external onlyOwnerOrDelegator {
        serverSigner = newServerSigner;
    }

    function setPromoCodeTokenLimit(uint256 newPromoCodeTokenLimit) external onlyOwnerOrDelegator {
        promoCodeTokenLimit = newPromoCodeTokenLimit;
    }

    // Delegator

    function loadSheep(uint256[] calldata tokenIds) external onlyDelegator whenNotPaused {
        uint256 paidTokenCount = wolfGame.getPaidTokens();
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            uint256 tokenId = tokenIds[i];
            IWoolf.SheepWolf memory tokenTraits = wolfGame.getTokenTraits(tokenId);
            if (!tokenTraits.isSheep) {
                revert CannotLoadWolf();
            }
            bool isGen0 = tokenId <= paidTokenCount;
            if (isGen0) {
                _gen0SheepIds.add(tokenId);
            } else {
                _gen1SheepIds.add(tokenId);
            }
            wolfGameReborn.transferFrom(_msgSender(), address(this), tokenId);
        }
    }

    function withdrawSheep(uint256[] calldata tokenIds) external onlyDelegator {
        uint256 paidTokenCount = wolfGame.getPaidTokens();
        for (uint256 i = 0; i < tokenIds.length; i += 1) {
            uint256 tokenId = tokenIds[i];
            bool isGen0 = tokenId <= paidTokenCount;
            if (isGen0) {
                _gen0SheepIds.remove(tokenId);
            } else {
                _gen1SheepIds.remove(tokenId);
            }
            wolfGameReborn.transferFrom(address(this), _msgSender(), tokenId);
        }
    }

    function withdrawAllSheep() external onlyDelegator {
        uint256 gen0SheepCount = _gen0SheepIds.length();
        uint256 gen1SheepCount = _gen1SheepIds.length();
        if (gen0SheepCount + gen1SheepCount == 0) {
            revert NoSheepLoaded();
        }
        if (gen0SheepCount > 0) {
            for (uint256 i = gen0SheepCount; i > 0; i--) {
                uint256 tokenId = _gen0SheepIds.at(i - 1);
                _gen0SheepIds.remove(tokenId);
                wolfGameReborn.transferFrom(address(this), _msgSender(), tokenId);
            }
        }
        if (gen1SheepCount > 0) {
            for (uint256 i = gen1SheepCount; i > 0; i--) {
                uint256 tokenId = _gen1SheepIds.at(i - 1);
                _gen1SheepIds.remove(tokenId);
                wolfGameReborn.transferFrom(address(this), _msgSender(), tokenId);
            }
        }
    }

    // Users

    function _checkIsSheep(uint tokenId) internal view {
        IWoolf.SheepWolf memory tokenTraits = wolfGame.getTokenTraits(tokenId);
        if (!tokenTraits.isSheep) {
            revert CannotSwapWolf();
        }
    }

    function _swap(uint256 incomingTokenId, uint256 outgoingTokenId) internal {
        wolfGameReborn.transferFrom(_msgSender(), delegator, incomingTokenId);
        wolfGameReborn.transferFrom(address(this), _msgSender(), outgoingTokenId);
    }

    function _swapGen0(uint256 incomingTokenId, uint256 outgoingTokenId) internal {
         if (!_gen0SheepIds.remove(outgoingTokenId)) {
            revert NotDelegatedSheep();
         }
        _swap(incomingTokenId, outgoingTokenId);
    }

    function _swapGen1(uint256 incomingTokenId, uint256 outgoingTokenId) internal {
        if (!_gen1SheepIds.remove(outgoingTokenId)) {
            revert NotDelegatedSheep();
        }
        _swap(incomingTokenId, outgoingTokenId);
    }

    function _swapSheepChosen(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bool allowDowngrade, bool allowUpgrade) internal returns (uint256 gen0OutgoingCount, uint256 gen1OutgoingCount, uint256 upgradeCount) {
        if (tokenIds.length == 0) {
            revert NoSheepSwapped();
        }
        if (tokenIds.length != outgoingTokenIds.length) {
            revert InvalidRequest();
        }

        uint256 gen0IncomingCount = 0;
        uint256 gen1IncomingCount = 0;
        uint256 paidTokenCount = wolfGame.getPaidTokens();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 incomingTokenId = tokenIds[i];
            _checkIsSheep(incomingTokenId);
            if (incomingTokenId <= paidTokenCount) {
                gen0IncomingCount += 1;
            } else {
                gen1IncomingCount += 1;
            }
            uint256 outgoingTokenId = outgoingTokenIds[i];
            // NOTE(krishan711): we dont need to check outgoingTokenId is a sheep, it's already checked on the way in.
            if (outgoingTokenId <= paidTokenCount) {
                gen0OutgoingCount += 1;
            } else {
                gen1OutgoingCount += 1;
            }
        }

        if (gen0IncomingCount > gen0OutgoingCount && !allowDowngrade) {
            revert NotDowngradable();
        }
        if (gen1IncomingCount > gen1OutgoingCount) {
            if (!allowUpgrade) {
                revert NotUpgradable();
            }
            upgradeCount = gen1IncomingCount - gen1OutgoingCount;
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 incomingTokenId = tokenIds[i];
            uint256 outgoingTokenId = outgoingTokenIds[i];
            if (outgoingTokenId <= paidTokenCount) {
                _swapGen0(incomingTokenId, outgoingTokenId);
            } else {
                _swapGen1(incomingTokenId, outgoingTokenId);
            }
        }

        return (gen0OutgoingCount, gen1OutgoingCount, upgradeCount);
    }

    function _validatePromoCode(uint256[] calldata tokenIds, string calldata promoCode, bytes calldata promoCodeSignature) internal {
        if (tokenIds.length == 0 || tokenIds.length > promoCodeTokenLimit) {
            revert PromoCodeTokenLimitReached();
        }
        if (promoCodeUserMap[promoCode] != address(0)) {
            revert PromoCodeAlreadyUsed();
        }
        bytes32 messageHash = keccak256(abi.encodePacked(tokenIds, promoCode));
        address signer = messageHash.toEthSignedMessageHash().recover(promoCodeSignature);
        if (signer != serverSigner) {
            revert InvalidSignature();
        }
        promoCodeUserMap[promoCode] = _msgSender();
    }

    function _validateSwap(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bytes calldata signature) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(tokenIds, outgoingTokenIds));
        address signer = messageHash.toEthSignedMessageHash().recover(signature);
        if (signer != serverSigner) {
            revert InvalidSignature();
        }
    }

    function _swapSheepBasic(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bool allowDowngrade, bytes calldata signature, bool shouldUseWool, bool hasUsedPromoCode) internal {
        _validateSwap(tokenIds, outgoingTokenIds, signature);
        (uint256 gen0Count, uint256 gen1Count, uint256 upgradeCount) = _swapSheepChosen(tokenIds, outgoingTokenIds, allowDowngrade, false);
        if (upgradeCount > 0) {
            revert NotUpgradable();
        }
        if (!hasUsedPromoCode) {
            if (shouldUseWool) {
                uint256 expectedWoolCost = (gen0Count * gen0BasicWoolPrice) + (gen1Count * gen1BasicWoolPrice);
                if (!wool.transferFrom(_msgSender(), address(this), expectedWoolCost)) {
                    revert InsufficientWoolPayment();
                }
            } else {
                uint256 expectedEthCost = (gen0Count * gen0BasicEthPrice) + (gen1Count * gen1BasicEthPrice);
                if (msg.value < expectedEthCost) {
                    revert InsufficientEthPayment();
                }
            }
        }
    }

    function swapSheepBasicEth(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bool allowDowngrade, bytes calldata signature) external payable nonReentrant whenNotPaused {
        _swapSheepBasic(tokenIds, outgoingTokenIds, allowDowngrade, signature, false, false);
    }

    function swapSheepBasicEthPromo(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bytes calldata signature, string calldata promoCode, bytes calldata promoCodeSignature) external nonReentrant whenNotPaused {
        _validatePromoCode(tokenIds, promoCode, promoCodeSignature);
        _swapSheepBasic(tokenIds, outgoingTokenIds, false, signature, false, true);
    }

    function swapSheepBasicWool(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bool allowDowngrade, bytes calldata signature) external nonReentrant whenNotPaused {
        _swapSheepBasic(tokenIds, outgoingTokenIds, allowDowngrade, signature, true, false);
    }

    function swapSheepBasicWoolPromo(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bytes calldata signature, string calldata promoCode, bytes calldata promoCodeSignature) external nonReentrant whenNotPaused {
        _validatePromoCode(tokenIds, promoCode, promoCodeSignature);
        _swapSheepBasic(tokenIds, outgoingTokenIds, false, signature, true, true);
    }

    function _swapSheepAdvanced(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bool allowDowngrade, bool allowUpgrade, bool shouldUseWool, bool hasUsedPromoCode) internal {
        (uint256 gen0Count, uint256 gen1Count, uint256 upgradeCount) = _swapSheepChosen(tokenIds, outgoingTokenIds, allowDowngrade, allowUpgrade);
        if (!hasUsedPromoCode) {
            if (shouldUseWool) {
                uint256 expectedWoolCost = (gen0Count * gen0AdvancedWoolPrice) + (gen1Count * gen1AdvancedWoolPrice) + (upgradeCount * upgradeAdditionalWoolPrice);
                if (!wool.transferFrom(_msgSender(), address(this), expectedWoolCost)) {
                    revert InsufficientWoolPayment();
                }
            } else {
                uint256 expectedEthCost = (gen0Count * gen0AdvancedEthPrice) + (gen1Count * gen1AdvancedEthPrice) + (upgradeCount * upgradeAdditionalEthPrice);
                if (msg.value < expectedEthCost) {
                    revert InsufficientEthPayment();
                }
            }
        }
    }

    function swapSheepAdvancedEth(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bool allowDowngrade, bool allowUpgrade) external payable nonReentrant whenNotPaused {
        _swapSheepAdvanced(tokenIds, outgoingTokenIds, allowDowngrade, allowUpgrade, false, false);
    }

    function swapSheepAdvancedEthPromo(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, string calldata promoCode, bytes calldata promoCodeSignature) external nonReentrant whenNotPaused {
        _validatePromoCode(tokenIds, promoCode, promoCodeSignature);
        _swapSheepAdvanced(tokenIds, outgoingTokenIds, false, false, false, true);
    }

    function swapSheepAdvancedWool(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, bool allowDowngrade, bool allowUpgrade) external nonReentrant whenNotPaused {
        _swapSheepAdvanced(tokenIds, outgoingTokenIds, allowDowngrade, allowUpgrade, true, false);
    }

    function swapSheepAdvancedWoolPromo(uint256[] calldata tokenIds, uint256[] calldata outgoingTokenIds, string calldata promoCode, bytes calldata promoCodeSignature) external nonReentrant whenNotPaused {
        _validatePromoCode(tokenIds, promoCode, promoCodeSignature);
        _swapSheepAdvanced(tokenIds, outgoingTokenIds, false, false, true, true);
    }
}