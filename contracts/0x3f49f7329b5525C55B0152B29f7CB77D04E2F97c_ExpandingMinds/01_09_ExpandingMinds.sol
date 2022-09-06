// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
 *
 * _______/\\\\\_______/\\\\\\\\\\\\\____/\\\\\\\\\\\\\\\__/\\\\\_____/\\\_____/\\\\\\\\\\__
 *  _____/\\\///\\\____\/\\\/////////\\\_\/\\\///////////__\/\\\\\\___\/\\\___/\\\///////\\\_
 *   ___/\\\/__\///\\\__\/\\\_______\/\\\_\/\\\_____________\/\\\/\\\__\/\\\__\///______/\\\__
 *    __/\\\______\//\\\_\/\\\\\\\\\\\\\/__\/\\\\\\\\\\\_____\/\\\//\\\_\/\\\_________/\\\//___
 *     _\/\\\_______\/\\\_\/\\\/////////____\/\\\///////______\/\\\\//\\\\/\\\________\////\\\__
 *      _\//\\\______/\\\__\/\\\_____________\/\\\_____________\/\\\_\//\\\/\\\___________\//\\\_
 *       __\///\\\__/\\\____\/\\\_____________\/\\\_____________\/\\\__\//\\\\\\__/\\\______/\\\__
 *        ____\///\\\\\/_____\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\___\//\\\\\_\///\\\\\\\\\/___
 *         ______\/////_______\///______________\///////////////__\///_____\/////____\/////////_____
 *
 */

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title ExpandingMinds ERC721A Smart Contract
 */

contract ExpandingMinds is Ownable, ReentrancyGuard, ERC721A {
    constructor(address authorizerAddress_, address distributorAddress_)
        ERC721A("Expanding Minds", "MIND")
    {
        authorizerAddress = authorizerAddress_;
        distributorAddress = distributorAddress_;
    }

    /** MINTING LIMITS */

    uint256 public constant MINT_LIMIT_PER_ADDRESS = 1;

    uint256 public constant MAX_MULTIMINT = 1;

    mapping(uint256 => bool) public qualifiedNonceList;
    mapping(address => uint256) public qualifiedWalletList;

    /** MINTING */

    uint256 public constant MAX_SUPPLY = 1_111;

    uint256 public constant PRICE = 0 ether;

    function qualifiedMint(
        uint256 amount_,
        bytes memory signature_,
        uint256 nonce_
    ) external payable nonReentrant {
        require(saleIsActive, "Sale not active");
        require(!qualifiedNonceList[nonce_], "Access nonce not owned");
        require(amount_ <= MAX_MULTIMINT, "Exceeds max mints per transaction");
        require(
            qualifiedWalletList[msg.sender] + amount_ <= MINT_LIMIT_PER_ADDRESS,
            "Minting limit exceeded"
        );
        require(totalSupply() + amount_ <= MAX_SUPPLY, "Exceeds max supply");
        require(PRICE * amount_ <= msg.value, "Insufficient payment");

        bytes32 hash = keccak256(abi.encodePacked(msg.sender, nonce_));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);

        require(
            ECDSA.recover(message, signature_) == authorizerAddress,
            "Bad signature"
        );

        qualifiedNonceList[nonce_] = true;
        qualifiedWalletList[msg.sender] += amount_;

        _safeMint(msg.sender, amount_);
    }

    function ownerMint(address address_, uint256 amount_) external onlyOwner {
        require(totalSupply() + amount_ <= MAX_SUPPLY, "Exceeds max supply");

        _safeMint(address_, amount_);
    }

    /** ACTIVATION */

    bool public saleIsActive = false;

    address private authorizerAddress;

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    function authorizer() public view returns (address) {
        return authorizerAddress;
    }

    function setAuthorizerAddress(address address_) external onlyOwner {
        authorizerAddress = address_;
    }

    /** URI HANDLING */

    string private customContractURI = "";

    function setContractURI(string memory customContractURI_)
        external
        onlyOwner
    {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    string private customBaseURI;

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /** PAYOUT */

    address private distributorAddress;

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(distributorAddress), balance);
    }

    function distributor() public view returns (address) {
        return distributorAddress;
    }

    function setDistributorAddress(address address_) external onlyOwner {
        distributorAddress = address_;
    }
}