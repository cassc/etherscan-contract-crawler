// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ERC721AStorage} from "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import {AppFacet} from "../../internals/AppFacet.sol";
import {BaseStorage} from "../../diamond/BaseStorage.sol";
import {DropStorage} from "../drop/DropStorage.sol";
import {ApeDropStorage} from "./ApeDropStorage.sol";

contract ApeDropFacet is AppFacet {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    modifier onlyMintable(uint64 quantity) {
        DropStorage.Layout storage layout = DropStorage.layout();
        require(quantity > 0, "Quantity is 0");
        require(quantity <= layout._maxPerMint, "Exceeded max per mint");
        if (
            layout._maxAmount > 0 &&
            _totalSupply() + quantity > layout._maxAmount
        ) {
            revert("Exceeded max supply");
        }
        _;
    }

    function initializeApeDrop(
        address tokenAddress_
    ) public onlyRolesOrOwner(BaseStorage.ADMIN_ROLE) {
        require(
            !ApeDropStorage.layout()._apeInitialized,
            "already initialized"
        );

        ApeDropStorage.layout()._apeCoinContract = IERC20Upgradeable(
            tokenAddress_
        );
        ApeDropStorage.layout()._apeInitialized = true;
    }

    function finalizeApeDrop() public onlyRolesOrOwner(BaseStorage.ADMIN_ROLE) {
        require(ApeDropStorage.layout()._apeInitialized, "not initialized");

        ApeDropStorage.layout()._apeInitialized = false;
        ApeDropStorage.layout()._apeCoinContract = IERC20Upgradeable(
            address(0)
        );
    }

    function apeMintTo(
        address recipient,
        uint64 quantity
    ) external payable onlyMintable(quantity) {
        ApeDropStorage.Layout storage layout = ApeDropStorage.layout();
        require(!layout._apePresaleActive, "Presale active");
        require(layout._apeSaleActive, "Sale not active");
        require(
            _getAux(recipient) + quantity <= DropStorage.layout()._maxPerWallet,
            "Exceeded max per wallet"
        );

        _apePurchaseMint(quantity, recipient);
    }

    function apePresaleMintTo(
        address recipient,
        uint64 quantity,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable onlyMintable(quantity) {
        DropStorage.Layout storage dropLayout = DropStorage.layout();
        ApeDropStorage.Layout storage layout = ApeDropStorage.layout();
        uint256 mintQuantity = _getAux(recipient) + quantity;
        require(layout._apePresaleActive, "Presale not active");
        require(dropLayout._merkleRoot != "", "Presale not set");
        require(
            mintQuantity <= dropLayout._maxPerWallet,
            "Exceeded max per wallet"
        );
        require(mintQuantity <= allowed, "Exceeded max per wallet");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                dropLayout._merkleRoot,
                keccak256(abi.encodePacked(recipient, allowed))
            ),
            "Presale invalid"
        );

        _apePurchaseMint(quantity, recipient);
    }

    function apeStartSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        ApeDropStorage.Layout storage layout = ApeDropStorage.layout();
        DropStorage.Layout storage dropLayout = DropStorage.layout();

        layout._apeSaleActive = true;
        layout._apePresaleActive = presale;
        layout._apePrice = newPrice;

        dropLayout._maxAmount = newMaxAmount;
        dropLayout._maxPerMint = newMaxPerMint;
        dropLayout._maxPerWallet = newMaxPerWallet;
    }

    function apeStopSale() external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        ApeDropStorage.Layout storage layout = ApeDropStorage.layout();
        layout._apeSaleActive = false;
        layout._apePresaleActive = false;
    }

    function apePresaleActive() external view returns (bool) {
        return ApeDropStorage.layout()._apePresaleActive;
    }

    function apeSaleActive() external view returns (bool) {
        return ApeDropStorage.layout()._apeSaleActive;
    }

    function apePrice() external view returns (uint256) {
        return ApeDropStorage.layout()._apePrice;
    }

    function apeRevenue() external view returns (uint256) {
        return ApeDropStorage.layout()._apeRevenue;
    }

    function apeWithdraw() external onlyRolesOrOwner(BaseStorage.ADMIN_ROLE) {
        ApeDropStorage.Layout storage layout = ApeDropStorage.layout();
        uint256 balance = layout._apeCoinContract.balanceOf(address(this));
        require(balance > 0, "0 balance");

        layout._apeCoinContract.safeTransfer(_msgSenderERC721A(), balance);
    }

    function _apePurchaseMint(uint64 quantity, address to) internal {
        ApeDropStorage.Layout storage layout = ApeDropStorage.layout();
        uint256 total = layout._apePrice * quantity;

        unchecked {
            layout._apeRevenue = layout._apeRevenue + total;
        }

        layout._apeCoinContract.safeTransferFrom(to, address(this), total);
        _setAux(to, _getAux(to) + quantity);
        _mint(to, quantity);
    }
}