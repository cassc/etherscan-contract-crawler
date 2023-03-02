// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { ERC721AQueryableUpgradeable, ERC721AUpgradeable, IERC721AUpgradeable } from "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import { CopiumWarsSlayersStorage } from "./CopiumWarsSlayersStorage.sol";
import { DiamondOwnable } from "../acl/DiamondOwnable.sol";
import { ICopiumWarsSlayers } from "./ICopiumWarsSlayers.sol";
import { MintTokenVerifier } from "./MintTokenVerifier.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { Pausable } from "@solidstate/contracts/security/Pausable.sol";
import { Math } from "@solidstate/contracts/utils/Math.sol";

contract CopiumWarsSlayersERC721Facet is
    ERC721AQueryableUpgradeable,
    DiamondOwnable,
    MintTokenVerifier("CopiumWarsSlayers", "1.0.0"),
    Pausable,
    ICopiumWarsSlayers
{
    using AddressUtils for address payable;

    uint256 constant MAX_TOTAL_SUPPLY = 6666;
    uint256 constant PREMIUM_DURATION = 90;
    uint256 constant PREMIUM = 0.059 ether;
    uint256 constant BASE_COST = 0.01 ether;

    /**
     * @notice Initialises this contract with initial values
     * @param theExecutor_ Initial approved signer
     */
    function initialize(
        address theExecutor_,
        address payable copiumBank_,
        string calldata baseURI_
    ) external initializerERC721A onlyOwner {
        __ERC721A_init("Copium Wars Slayers", "!SLAY");
        if (copiumBank_ == address(0)) revert WrongBank();
        CopiumWarsSlayersStorage.layout().theExecutor = theExecutor_;
        CopiumWarsSlayersStorage.layout().copiumBank = copiumBank_;
        CopiumWarsSlayersStorage.layout().startTime = block.timestamp;
        CopiumWarsSlayersStorage.layout().baseURI = baseURI_;
        _mint(copiumBank_, 1666);
        _pause();
    }

    // ============================= ADMIN =============================

    ///@inheritdoc ICopiumWarsSlayers
    function setTheExecutor(address theExecutor_) external onlyOwner {
        CopiumWarsSlayersStorage.layout().theExecutor = theExecutor_;
    }

    ///@inheritdoc ICopiumWarsSlayers
    function setCopiumBank(address payable copiumBank_) external onlyOwner {
        if (copiumBank_ == address(0)) revert WrongBank();
        CopiumWarsSlayersStorage.layout().copiumBank = copiumBank_;
    }

    ///@inheritdoc ICopiumWarsSlayers
    function withdrawFunds() external onlyOwner {
        CopiumWarsSlayersStorage.layout().copiumBank.sendValue(address(this).balance);
    }

    ///@inheritdoc ICopiumWarsSlayers
    function pause() external onlyOwner {
        _pause();
    }

    ///@inheritdoc ICopiumWarsSlayers
    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        CopiumWarsSlayersStorage.layout().baseURI = baseURI;
    }

    ///@inheritdoc ICopiumWarsSlayers
    function adminMint(address recipient, uint256 amount) external onlyOwner {
        if (totalSupply() + amount > MAX_TOTAL_SUPPLY) revert MaxTotalSupplyBreached();
        _mint(recipient, amount);
    }

    // ============================= USER =============================

    ///@inheritdoc ICopiumWarsSlayers
    function mintWithToken(
        uint256 mintTokenId,
        address recipient,
        uint256 amount,
        bytes calldata signature
    ) external whenNotPaused {
        if (totalSupply() + amount > MAX_TOTAL_SUPPLY) revert MaxTotalSupplyBreached();
        _validateMintToken(mintTokenId, recipient, amount, signature);
        CopiumWarsSlayersStorage.layout().lockedBalance[recipient] += amount;
        _mint(recipient, amount);
        emit MintTokenUsed(mintTokenId, recipient, amount);
    }

    ///@inheritdoc ICopiumWarsSlayers
    function unlockBalance(address account, uint256 amount) external payable {
        uint requiredPayment = amount * unlockPrice();
        if (requiredPayment != msg.value) revert WrongUnlockPayment(requiredPayment, msg.value);
        if (amount > CopiumWarsSlayersStorage.layout().lockedBalance[account]) revert WrongUnlockQuantity(amount);
        CopiumWarsSlayersStorage.layout().lockedBalance[account] -= amount;
        emit BalanceUnlocked(account, amount);
    }

    function approve(
        address to,
        uint256 tokenId
    ) public payable virtual override(ERC721AUpgradeable, IERC721AUpgradeable) {
        uint256 _lockedBalance = CopiumWarsSlayersStorage.layout().lockedBalance[msg.sender];
        if (_lockedBalance > 0) {
            uint256 balance = balanceOf(msg.sender);
            if (balance == _lockedBalance) {
                revert ApprovalLocked(msg.sender, _lockedBalance);
            }
        }
        _approve(to, tokenId);
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public virtual override(ERC721AUpgradeable, IERC721AUpgradeable) {
        uint256 _lockedBalance = CopiumWarsSlayersStorage.layout().lockedBalance[msg.sender];
        if (_lockedBalance > 0) {
            uint256 balance = balanceOf(msg.sender);
            if (balance == _lockedBalance) {
                revert ApprovalLocked(msg.sender, _lockedBalance);
            }
        }
        super.setApprovalForAll(operator, approved);
    }

    // ============================= VIEWS =============================

    ///@inheritdoc ICopiumWarsSlayers
    function unlockPrice() public view returns (uint256 price) {
        uint256 elapsedDays = Math.min(
            ((block.timestamp / 1 days) - (CopiumWarsSlayersStorage.layout().startTime / 1 days)),
            90
        );
        price = (((PREMIUM_DURATION - elapsedDays) * PREMIUM) / PREMIUM_DURATION) + BASE_COST;
    }

    ///@inheritdoc ICopiumWarsSlayers
    function lockedBalance(address account) external view returns (uint256 price) {
        return CopiumWarsSlayersStorage.layout().lockedBalance[account];
    }

    ///@inheritdoc ICopiumWarsSlayers
    function isMintTokenUsed(uint256 mintTokenId) external view returns (bool) {
        return CopiumWarsSlayersStorage.layout().usedMintTokens[mintTokenId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override(ERC721AUpgradeable, IERC721AUpgradeable) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        string memory result = string(abi.encodePacked(baseURI, _toString(tokenId), ".json"));

        return bytes(baseURI).length != 0 ? result : "";
    }

    ///@inheritdoc ICopiumWarsSlayers
    function birthTime(uint256 tokenId) external view returns (uint) {
        TokenOwnership memory ownership = _ownershipOf(tokenId);
        return ((CopiumWarsSlayersStorage.layout().startTime / 1 hours) + ownership.extraData) * 1 hours;
    }

    ///@inheritdoc ICopiumWarsSlayers
    function theExecutor() external view returns (address) {
        return CopiumWarsSlayersStorage.layout().theExecutor;
    }

    ///@inheritdoc ICopiumWarsSlayers
    function copiumBank() external view returns (address) {
        return CopiumWarsSlayersStorage.layout().copiumBank;
    }

    function _extraData(
        address from,
        address,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        if (from == address(0)) {
            return uint24((block.timestamp - CopiumWarsSlayersStorage.layout().startTime) / 1 hours);
        }
        return previousExtraData;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return CopiumWarsSlayersStorage.layout().baseURI;
    }

    function _afterTokenTransfers(address from, address, uint256, uint256 quantity) internal virtual override {
        uint256 _lockedBalance = CopiumWarsSlayersStorage.layout().lockedBalance[from];
        if (_lockedBalance > 0) {
            uint256 leftBalance = balanceOf(from);
            if (leftBalance < _lockedBalance) {
                revert TransferLocked(from, quantity, leftBalance);
            }
        }
    }
}