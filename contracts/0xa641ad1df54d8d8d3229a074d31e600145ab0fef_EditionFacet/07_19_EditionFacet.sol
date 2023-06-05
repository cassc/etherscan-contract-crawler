// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {ERC721AStorage} from "erc721a-upgradeable/contracts/ERC721AStorage.sol";
import {AppFacet} from "../../internals/AppFacet.sol";
import {INiftyKitV3} from "../../interfaces/INiftyKitV3.sol";
import {BaseStorage} from "../../diamond/BaseStorage.sol";
import {EditionStorage} from "./EditionStorage.sol";

contract EditionFacet is AppFacet {
    event EditionCreated(uint256 indexed editionId);
    event EditionMinted(
        address indexed to,
        uint256 indexed editionId,
        uint256 quantity,
        uint256 value
    );

    using AddressUpgradeable for address;
    using ECDSAUpgradeable for bytes32;

    function createEdition(
        string memory tokenURI,
        uint256 price,
        uint256 maxQuantity,
        uint256 maxPerWallet,
        uint256 maxPerMint
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        EditionStorage.Layout storage layout = EditionStorage.layout();

        uint256 editionId = layout._count;
        layout._editions[editionId] = EditionStorage.Edition({
            tokenURI: tokenURI,
            merkleRoot: "",
            price: price,
            quantity: 0,
            maxQuantity: maxQuantity,
            maxPerWallet: maxPerWallet,
            maxPerMint: maxPerMint,
            nonce: 0,
            signer: _msgSenderERC721A(),
            active: false
        });

        unchecked {
            layout._count = editionId + 1;
        }

        emit EditionCreated(editionId);
    }

    function updateEdition(
        uint256 editionId,
        uint256 price,
        uint256 maxQuantity,
        uint256 maxPerWallet,
        uint256 maxPerMint
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        EditionStorage.Layout storage layout = EditionStorage.layout();
        require(layout._count > editionId, "Does not exist");

        layout._editions[editionId].price = price;
        layout._editions[editionId].maxQuantity = maxQuantity;
        layout._editions[editionId].maxPerWallet = maxPerWallet;
        layout._editions[editionId].maxPerMint = maxPerMint;
    }

    function setEditionTokenURI(
        uint256 editionId,
        string memory tokenURI
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        EditionStorage.Layout storage layout = EditionStorage.layout();
        require(layout._count > editionId, "Does not exist");

        layout._editions[editionId].tokenURI = tokenURI;
    }

    function setEditionMerkleRoot(
        uint256 editionId,
        bytes32 merkleRoot
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        EditionStorage.Layout storage layout = EditionStorage.layout();
        require(layout._count > editionId, "Does not exist");

        layout._editions[editionId].merkleRoot = merkleRoot;
    }

    function setEditionActive(
        uint256 editionId,
        bool active
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        EditionStorage.Layout storage layout = EditionStorage.layout();
        require(layout._count > editionId, "Does not exist");

        layout._editions[editionId].active = active;
    }

    function setEditionSigner(
        uint256 editionId,
        address signer
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        EditionStorage.Layout storage layout = EditionStorage.layout();
        require(layout._count > editionId, "Does not exist");

        layout._editions[editionId].signer = signer;
    }

    function invalidateSignature(
        uint256 editionId
    ) external onlyRolesOrOwner(BaseStorage.MANAGER_ROLE) {
        EditionStorage.Layout storage layout = EditionStorage.layout();
        require(layout._count > editionId, "Does not exist");

        EditionStorage.Edition storage edition = layout._editions[editionId];
        edition.nonce = edition.nonce + 1;
    }

    function mintEdition(
        address recipient,
        uint256 editionId,
        uint256 quantity,
        bytes calldata signature,
        bytes32[] calldata proof
    ) external payable {
        INiftyKitV3 niftyKit = BaseStorage.layout()._niftyKit;
        EditionStorage.Layout storage layout = EditionStorage.layout();
        EditionStorage.Edition storage edition = layout._editions[editionId];
        (uint256 sellerFees, uint256 buyerFees) = niftyKit.getFees(
            edition.price * quantity
        );

        require(layout._count > editionId, "Does not exist");
        require(edition.active, "Not active");
        require(
            edition.price * quantity + buyerFees <= msg.value,
            "Value incorrect"
        );
        _requireQuantity(layout, edition, editionId, recipient, quantity);
        _requireSignature(edition, editionId, signature);
        _requireProof(edition, recipient, proof);

        unchecked {
            layout._editionRevenue = layout._editionRevenue + msg.value;
            layout._mintCount[editionId][recipient] =
                layout._mintCount[editionId][recipient] +
                quantity;
        }

        AddressUpgradeable.sendValue(
            payable(address(niftyKit)),
            sellerFees + buyerFees
        );

        _mintEdition(edition, recipient, quantity);

        emit EditionMinted(recipient, editionId, quantity, msg.value);
    }

    function getEdition(
        uint256 editionId
    ) external view returns (EditionStorage.Edition memory) {
        return EditionStorage.layout()._editions[editionId];
    }

    function getEditionPrice(
        uint256 editionId
    ) external view returns (uint256) {
        INiftyKitV3 niftyKit = BaseStorage.layout()._niftyKit;
        EditionStorage.Layout storage layout = EditionStorage.layout();
        require(layout._count > editionId, "Does not exist");

        EditionStorage.Edition storage edition = layout._editions[editionId];
        uint256 basePrice = edition.price;
        (, uint256 buyerFees) = niftyKit.getFees(basePrice);
        return basePrice + buyerFees;
    }

    function editionRevenue() external view returns (uint256) {
        return EditionStorage.layout()._editionRevenue;
    }

    function editionsCount() external view returns (uint256) {
        return EditionStorage.layout()._count;
    }

    function _requireQuantity(
        EditionStorage.Layout storage layout,
        EditionStorage.Edition storage edition,
        uint256 editionId,
        address recipient,
        uint256 quantity
    ) internal view {
        require(
            layout._mintCount[editionId][recipient] + quantity <=
                edition.maxPerWallet,
            "Exceeded max per wallet"
        );
        require(quantity <= edition.maxPerMint, "Exceeded max per mint");
        require(
            edition.maxQuantity == 0 ||
                edition.quantity + quantity <= edition.maxQuantity,
            "Exceeded max amount"
        );
    }

    function _requireSignature(
        EditionStorage.Edition storage edition,
        uint256 editionId,
        bytes calldata signature
    ) internal view {
        require(
            keccak256(
                abi.encodePacked(editionId, edition.nonce, block.chainid)
            ).toEthSignedMessageHash().recover(signature) == edition.signer,
            "Invalid signature"
        );
    }

    function _requireProof(
        EditionStorage.Edition storage edition,
        address recipient,
        bytes32[] calldata proof
    ) internal view {
        if (edition.merkleRoot != "") {
            require(
                MerkleProofUpgradeable.verify(
                    proof,
                    edition.merkleRoot,
                    keccak256(abi.encodePacked(recipient))
                ),
                "Invalid proof"
            );
        }
    }

    function _mintEdition(
        EditionStorage.Edition storage edition,
        address recipient,
        uint256 quantity
    ) internal {
        uint256 startTokenId = ERC721AStorage.layout()._currentIndex;
        for (
            uint256 tokenId = startTokenId;
            tokenId < quantity + startTokenId;

        ) {
            BaseStorage.layout()._tokenURIs[tokenId] = BaseStorage.URIEntry(
                true,
                edition.tokenURI
            );
            unchecked {
                tokenId++;
            }
        }

        unchecked {
            edition.quantity = edition.quantity + quantity;
        }

        _mint(recipient, quantity);
    }
}