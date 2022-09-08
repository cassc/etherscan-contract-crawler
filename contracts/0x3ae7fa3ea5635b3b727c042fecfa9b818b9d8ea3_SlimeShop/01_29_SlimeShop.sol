// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;
import {MerkleProofLib} from "solady/utils/MerkleProofLib.sol";
import {BoundLayerableFirstComposedCutoff} from "bound-layerable/examples/BoundLayerableFirstComposedCutoff.sol";
import {CommissionWithdrawable} from "utility-contracts/withdrawable/CommissionWithdrawable.sol";
import {ConstructorArgs} from "./Structs.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {ERC721A} from "bound-layerable/token/ERC721A.sol";

// ░██████╗██╗░░░░░██╗███╗░░░███╗███████╗░██████╗██╗░░██╗░█████╗░██████╗░
// ██╔════╝██║░░░░░██║████╗░████║██╔════╝██╔════╝██║░░██║██╔══██╗██╔══██╗
// ╚█████╗░██║░░░░░██║██╔████╔██║█████╗░░╚█████╗░███████║██║░░██║██████╔╝
// ░╚═══██╗██║░░░░░██║██║╚██╔╝██║██╔══╝░░░╚═══██╗██╔══██║██║░░██║██╔═══╝░
// ██████╔╝███████╗██║██║░╚═╝░██║███████╗██████╔╝██║░░██║╚█████╔╝██║░░░░░
// ╚═════╝░╚══════╝╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░
contract SlimeShop is
    BoundLayerableFirstComposedCutoff,
    ERC2981,
    CommissionWithdrawable
{
    struct PublicMintParameters {
        uint64 publicMintPrice;
        uint64 publicSaleStartTime;
        uint64 maxMintedSetsPerWallet;
    }

    PublicMintParameters public publicMintParameters;
    bytes32 public merkleRoot;

    error IncorrectPayment(uint256 got, uint256 want);
    error InvalidProof();
    error MaxMintsExceeded(uint256 numLeft);
    error MintNotActive(uint256 startTime);

    constructor(ConstructorArgs memory args)
        BoundLayerableFirstComposedCutoff(
            args.name,
            args.symbol,
            args.vrfCoordinatorAddress,
            args.maxNumSets,
            args.numTokensPerSet,
            args.subscriptionId,
            args.metadataContractAddress,
            args.firstComposedCutoff,
            args.exclusiveLayerId,
            16,
            args.keyHash
        )
        CommissionWithdrawable(args.feeRecipient, args.feeBps)
    {
        publicMintParameters = PublicMintParameters({
            publicMintPrice: args.publicMintPrice,
            publicSaleStartTime: args.startTime,
            maxMintedSetsPerWallet: args.maxSetsPerWallet
        });

        merkleRoot = args.merkleRoot;
        _setDefaultRoyalty(
            args.royaltyInfo.receiver,
            args.royaltyInfo.royaltyFraction
        );
    }

    function mint(uint256 numSets) public payable canMint(numSets) {
        PublicMintParameters memory params = publicMintParameters;
        uint256 _publicSaleStartTime = params.publicSaleStartTime;
        if (block.timestamp < _publicSaleStartTime) {
            revert MintNotActive(_publicSaleStartTime);
        }
        uint256 price = params.publicMintPrice * numSets;
        if (msg.value != price) {
            revert IncorrectPayment(msg.value, price);
        }
        uint256 numSetsMinted = _numberMinted(msg.sender) / NUM_TOKENS_PER_SET;
        if (params.maxMintedSetsPerWallet < numSetsMinted + numSets) {
            revert MaxMintsExceeded(
                params.maxMintedSetsPerWallet - numSetsMinted
            );
        }
        _mint(msg.sender, numSets * NUM_TOKENS_PER_SET);
    }

    function mintAllowList(
        uint256 numSets,
        uint256 mintPrice,
        uint256 maxMintedSetsForWallet,
        uint256 startTime,
        bytes32[] calldata proof
    ) public payable canMint(numSets) {
        if (block.timestamp < startTime) {
            revert MintNotActive(startTime);
        }
        if (msg.value < mintPrice) {
            revert IncorrectPayment(msg.value, mintPrice);
        }
        uint256 numberMinted = _numberMinted(msg.sender) / NUM_TOKENS_PER_SET;
        if (maxMintedSetsForWallet < numberMinted + numSets) {
            revert MaxMintsExceeded(maxMintedSetsForWallet - numberMinted);
        }
        bool isValid = MerkleProofLib.verify(
            proof,
            merkleRoot,
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    mintPrice,
                    maxMintedSetsForWallet,
                    startTime
                )
            )
        );
        if (!isValid) {
            revert InvalidProof();
        }

        _mint(msg.sender, numSets * NUM_TOKENS_PER_SET);
    }

    /**
     * @notice Determine layer type by its token ID
     */
    function getLayerType(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint8 layerType)
    {
        uint256 numTokensPerSet = NUM_TOKENS_PER_SET;

        /// @solidity memory-safe-assembly
        assembly {
            layerType := mod(tokenId, numTokensPerSet)
            if gt(layerType, 5) {
                layerType := 5
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        return _tokenURI(tokenId);
    }

    function getPublicSaleStartTime() public view virtual returns (uint64) {
        return publicMintParameters.publicSaleStartTime;
    }

    function getPublicMintPrice() public view virtual returns (uint64) {
        return publicMintParameters.publicMintPrice;
    }

    function getPublicMaxSetsPerWallet() public view virtual returns (uint64) {
        return publicMintParameters.maxMintedSetsPerWallet;
    }

    function getNumberMintedForAddress(address addr)
        public
        view
        virtual
        returns (uint256)
    {
        return _numberMinted(addr);
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setPublicSaleStartTime(uint64 startTime) public onlyOwner {
        publicMintParameters.publicSaleStartTime = startTime;
    }

    function setPublicMintPrice(uint64 price) public onlyOwner {
        publicMintParameters.publicMintPrice = price;
    }

    function setMaxMintedSetsPerWallet(uint64 maxMintedSetsPerWallet)
        public
        onlyOwner
    {
        publicMintParameters.maxMintedSetsPerWallet = maxMintedSetsPerWallet;
    }

    function setDefaultRoyalty(address receiver, uint96 royaltyFraction)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, royaltyFraction);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return
            interfaceId == type(ERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}