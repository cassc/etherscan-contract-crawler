/* Copyright (C) 2022 Assemble Stream, Inc. */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Mints Cost 0.06 ETH
// All Mints Require Pre-Approval (Back End Digital Signature)
// Curators will get One AirDrop + 4 Paid Mints
// Others get One Free + 2 Paid Mints
// HUG Back End will Reveal MetaData after each NFT is Minted

contract HUGMembershipPass is ERC721A, Ownable {
    using Strings for uint256;

    // Mint Status
    bool private mintEnabled = false;

    // Mint Parameters
    uint256 public constant maxMints = 3;
    uint256 public constant maxMintsCurators = 4;
    uint256 public constant hugCost = 0.06 ether;
    uint256 public constant mintMaxSupply = 15000;

    // Tokens & Meta Data
    string baseURI;

    // Digital Signature Approver Public Key
    address private hugApprovalSigner;

    // Withdraw Wallet
    address payable public payableWallet;

    // Custom Errors
    error MintNotEnabled();
    error MaxMintsExceeded();
    error MintCapacityExceeded();
    error InsufficientFunds();
    error InvalidApproval();

    //
    // Constructor
    //
    constructor(
        string memory _baseURI,
        address _hugApprovalSigner,
        address payable _payableWallet
    ) ERC721A("The HUG Pass", "HUG") {
        baseURI = _baseURI;
        hugApprovalSigner = _hugApprovalSigner;
        payableWallet = _payableWallet;
    }

    //
    // Public Mint - Requires Pre-Approval
    //
    function mintHUG(
        uint256 count,
        bytes memory signature,
        bool isCurator,
        bool oneFree
    ) public payable {
        unchecked {
            // Verify Minting is Enabled
            if (!mintEnabled) revert MintNotEnabled();

            // Verify Max Mints Not Exceeded
            uint256 mintsUsedCount = _numberMinted(msg.sender);
            uint256 mintsMax = isCurator ? maxMintsCurators : maxMints;
            if ((mintsUsedCount + count) > mintsMax) revert MaxMintsExceeded();

            // Check Total Supply
            if ((totalSupply() + count) > mintMaxSupply)
                revert MintCapacityExceeded();

            // Verify Sufficient ETH
            uint256 ethRequired = calculateEthRequired(
                oneFree,
                mintsUsedCount,
                count
            );
            if (msg.value < ethRequired) revert InsufficientFunds();

            // Verify Digital Signature
            verifySenderApproved(isCurator, oneFree, signature);

            // Mint!
            _safeMint(msg.sender, count);
        }
    }

    //
    // Reserve for Community/Team AirDrops
    //
    function reserveHugs(uint256 count) public onlyOwner {
        _safeMint(owner(), count);
    }

    //
    // AirDrop Reserved Tokens
    //
    function airDropReserved(address[] calldata to, uint256[] calldata tokenIds)
        public
        onlyOwner
    {
        unchecked {
            uint256 len = to.length;
            uint256 index;
            for (index = 0; index < len; index++) {
                transferFrom(owner(), to[index], tokenIds[index]);
            }
        }
    }

    //
    // AirDrop Minted Tokens
    //
    function airDropMint(address[] calldata to, uint256[] calldata count) public onlyOwner {
        unchecked {
            uint256 len = to.length;
            uint256 index;
            for (index = 0; index < len; index++) {
                _safeMint(to[index], count[index]);
            }
        }

    }

    //
    // Calculate ETH
    //
    function calculateEthRequired(
        bool oneFree,
        uint256 oldCount,
        uint256 mintsRequested
    ) private pure returns (uint256) {
        //reduce
        if (oldCount == 0 && oneFree) {
            return (mintsRequested - 1) * hugCost;
        }
        return mintsRequested * hugCost;
    }

    //
    // Verify Approval Digital Signature
    //
    function verifySenderApproved(
        bool isCurator,
        bool oneFree,
        bytes memory signature
    ) private view {
        bytes32 hashedInsideContract = keccak256(
            abi.encodePacked(msg.sender, isCurator, oneFree)
        );
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hashedInsideContract
            )
        );
        address recovered = ECDSA.recover(messageDigest, signature);
        if (recovered != hugApprovalSigner) revert InvalidApproval();
    }

    //
    // Withdraw
    //
    function withdraw() external payable onlyOwner {
        require(
            payableWallet != address(0),
            "Cannot withdraw funds to 0 address."
        );
        payableWallet.transfer(address(this).balance);
    }

    //
    // Metadata URI for Token
    //
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    //
    // Get Number of Mints Used
    //
    function hugsMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    //
    // Adjust Parameters
    //

    function setMintEnabled(bool _mintEnabled) public onlyOwner {
        mintEnabled = _mintEnabled;
    }

    function setHugApprovalSigner(address _hugApprovalSigner) public onlyOwner {
        hugApprovalSigner = _hugApprovalSigner;
    }

    function setPayableWallet(address payable _payableWallet) public onlyOwner {
        payableWallet = _payableWallet;
    }
}