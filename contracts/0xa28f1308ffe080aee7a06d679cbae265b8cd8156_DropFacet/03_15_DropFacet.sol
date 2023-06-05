// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {ERC721AStorage} from "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import {AppFacet} from "../../internals/AppFacet.sol";
import {INiftyKitV3} from "../../interfaces/INiftyKitV3.sol";
import {BaseStorage} from "../../diamond/BaseStorage.sol";
import {DropStorage} from "./DropStorage.sol";

contract DropFacet is AppFacet {
    using AddressUpgradeable for address;

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

    function mintTo(
        address recipient,
        uint64 quantity
    ) external payable onlyMintable(quantity) {
        DropStorage.Layout storage layout = DropStorage.layout();
        require(!layout._presaleActive, "Presale active");
        require(layout._saleActive, "Sale not active");
        require(
            _getAux(recipient) + quantity <= layout._maxPerWallet,
            "Exceeded max per wallet"
        );

        _purchaseMint(quantity, recipient);
    }

    function presaleMintTo(
        address recipient,
        uint64 quantity,
        uint256 allowed,
        bytes32[] calldata proof
    ) external payable onlyMintable(quantity) {
        DropStorage.Layout storage layout = DropStorage.layout();
        uint256 mintQuantity = _getAux(recipient) + quantity;
        require(layout._presaleActive, "Presale not active");
        require(layout._merkleRoot != "", "Presale not set");
        require(
            mintQuantity <= layout._maxPerWallet,
            "Exceeded max per wallet"
        );
        require(mintQuantity <= allowed, "Exceeded max per wallet");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                layout._merkleRoot,
                keccak256(abi.encodePacked(recipient, allowed))
            ),
            "Presale invalid"
        );

        _purchaseMint(quantity, recipient);
    }

    function batchAirdrop(
        uint64[] calldata quantities,
        address[] calldata recipients
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        uint256 length = recipients.length;
        require(quantities.length == length, "Invalid Arguments");

        for (uint256 i = 0; i < length; ) {
            _safeMint(recipients[i], quantities[i]);
            unchecked {
                i++;
            }
        }
    }

    function setMerkleRoot(
        bytes32 newRoot
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        DropStorage.layout()._merkleRoot = newRoot;
    }

    function startSale(
        uint256 newMaxAmount,
        uint256 newMaxPerMint,
        uint256 newMaxPerWallet,
        uint256 newPrice,
        bool presale
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        DropStorage.Layout storage layout = DropStorage.layout();
        layout._saleActive = true;
        layout._presaleActive = presale;

        layout._maxAmount = newMaxAmount;
        layout._maxPerMint = newMaxPerMint;
        layout._maxPerWallet = newMaxPerWallet;
        layout._price = newPrice;
    }

    function stopSale() external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        DropStorage.Layout storage layout = DropStorage.layout();
        layout._saleActive = false;
        layout._presaleActive = false;
    }

    function maxAmount() external view returns (uint256) {
        return DropStorage.layout()._maxAmount;
    }

    function maxPerMint() external view returns (uint256) {
        return DropStorage.layout()._maxPerMint;
    }

    function maxPerWallet() external view returns (uint256) {
        return DropStorage.layout()._maxPerWallet;
    }

    function price() external view returns (uint256) {
        INiftyKitV3 niftyKit = BaseStorage.layout()._niftyKit;
        uint256 basePrice = DropStorage.layout()._price;
        (, uint256 buyerFees) = niftyKit.getFees(basePrice);
        return basePrice + buyerFees;
    }

    function displayPrice() external view returns (uint256) {
        return DropStorage.layout()._price;
    }

    function presaleActive() external view returns (bool) {
        return DropStorage.layout()._presaleActive;
    }

    function saleActive() external view returns (bool) {
        return DropStorage.layout()._saleActive;
    }

    function dropRevenue() external view returns (uint256) {
        return DropStorage.layout()._dropRevenue;
    }

    function _purchaseMint(uint64 quantity, address to) internal {
        INiftyKitV3 niftyKit = BaseStorage.layout()._niftyKit;
        DropStorage.Layout storage layout = DropStorage.layout();
        uint256 mintPrice = layout._price * quantity;
        (uint256 sellerFees, uint256 buyerFees) = niftyKit.getFees(mintPrice);
        require(mintPrice + buyerFees <= msg.value, "Value incorrect");

        unchecked {
            layout._dropRevenue = layout._dropRevenue + msg.value;
        }

        AddressUpgradeable.sendValue(
            payable(address(niftyKit)),
            sellerFees + buyerFees
        );

        _setAux(to, _getAux(to) + quantity);
        _mint(to, quantity);
    }
}