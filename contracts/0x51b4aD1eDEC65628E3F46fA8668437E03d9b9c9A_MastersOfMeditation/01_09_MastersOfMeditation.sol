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
 *          STANDARD_MINTING_FOUNDATION______________________________________________________________
 *
 */

import "erc721a/contracts/ERC721A.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Masters of Meditation ERC721A Smart Contract
 */

contract MastersOfMeditation is Ownable, ReentrancyGuard, ERC721A {
    event PaymentReceived(address from, uint256 amount);

    constructor(address authorizerAddress_, address distributorAddress_)
        ERC721A("Masters of Meditation", "GURU")
    {
        authorizerAddress = authorizerAddress_;
        distributorAddress = distributorAddress_;
    }

    /** MINTING LIMITS **/

    uint256 public constant MINT_LIMIT_PER_ADDRESS = 10;

    uint256 public constant MAX_MULTIMINT = 5;

    mapping(uint256 => bool) public qualifiedNonceList;
    mapping(address => uint256) public qualifiedWalletList;

    /** MINTING **/

    uint256 public constant MAX_SUPPLY = 10_000;

    uint256 public constant PRICE = 0 ether;

    /**
     * @dev Open3 Qualified Mint, triggers a mint based on the amount to the sender
     */
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

    /**
     * @dev Owner of the contract can mints to the address based on the amount.
     */
    function ownerMint(address address_, uint256 amount_) external onlyOwner {
        require(totalSupply() + amount_ <= MAX_SUPPLY, "Exceeds max supply");

        _safeMint(address_, amount_);
    }

    /** ACTIVATION **/

    bool public saleIsActive = false;

    address private authorizerAddress;

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev Enables or disables the minting process.
     */
    function setSaleIsActive(bool saleIsActive_) external onlyOwner {
        saleIsActive = saleIsActive_;
    }

    /**
     * @dev The address of the authorizer.
     */
    function authorizer() public view returns (address) {
        return authorizerAddress;
    }

    /**
     * @dev Sets the address of the authorizer.
     */
    function setAuthorizerAddress(address address_) external onlyOwner {
        authorizerAddress = address_;
    }

    /** URI HANDLING **/

    string private customContractURI = "";

    /**
     * @dev Sets the contract URI.
     */
    function setContractURI(string memory customContractURI_)
        external
        onlyOwner
    {
        customContractURI = customContractURI_;
    }

    /**
     * @dev Gets the contract URI.
     */
    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    string private customBaseURI;

    /**
     * @dev Sets the base URI.
     */
    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    /**
     * @dev Gets the base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /** PAYOUT **/

    address private distributorAddress;

    /**
     * @dev Withdraws the ether from the contract to the distributor address.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(distributorAddress), balance);
    }

    /**
     * @dev The address where withdraw will be sent to.
     */
    function distributor() public view returns (address) {
        return distributorAddress;
    }

    /**
     * @dev Sets the distributor address.
     */
    function setDistributorAddress(address address_) external onlyOwner {
        distributorAddress = address_;
    }

    /** PAYABLE **/

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}