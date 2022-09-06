// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract ABCD is Ownable, ERC721A, ReentrancyGuard, Pausable {
    /* ======== LIBRARIES ======== */

    using ECDSA for bytes32;

    /* ======== ENUMS ======== */

    enum BatchMintType {
        CRYPTODOTCOM, // 0
        COLLABORATIONS, // 1
        GIVEAWAYS, // 2
        TEAM_TOKENS // 3
    }

    /* ======== EVENTS ======== */

    event UpdatePrivateSaleActive(bool privateSaleActive);
    event UpdateMaxMintPerTx(uint256 maxMintPerTx);
    event UpdateTreasury(address treasury);
    event UpdateWhitelistSigner(address whitelistSigner);
    event UpdateBaseURI(string baseURI);
    event UpdatePlaceholderURI(string placeholderURI);
    event UpdatePrivateSalePrice(uint256 privateSalePrice);
    event UpdateMaxMintPerWallet(uint256 maxMintPerWallet);
    event UpdateCryptoDotComSupply(uint256 supply);
    event UpdateCollaborationSupply(uint256 supply);
    event UpdateGiveawaySupply(uint256 supply);
    event UpdateTeamTokensSupply(uint256 supply);
    event UpdatePartnerMaxSupply(uint256 supply);
    event UpdatePartnerMintContract(address partnerMintContract);

    /* ======== VARIABLES ======== */

    bool public privateSaleActive = true;

    uint256 public constant COLLECTION_SUPPLY = 7777;
    uint256 public maxMintPerTx = 5;
    uint256 public maxMintPerWallet = 15;
    uint256 public privateSalePrice = .15 ether;
    uint256 public partnerMaxSupply = 200;
    uint256 public cryptoDotComSupply;
    uint256 public collaborationSupply;
    uint256 public giveawaySupply;
    uint256 public teamTokensSupply;
    uint256 public partnerSupply;

    address public treasury;
    address public whitelistSigner;
    address public partnerMintContract;

    string public baseURI;
    string public placeholderURI;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PRESALE_TYPEHASH =
        keccak256("PrivateSale(address buyer)");

    /* ======== CONSTRUCTOR ======== */

    constructor() ERC721A("ABCD", "ABCD") {
        _pause();

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("KAIJU")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        whitelistSigner = owner();
    }

    /* ======== MODIFIERS ======== */

    /*
     * @notice: Checks if the msg.sender is the owner or the treasury address
     */
    modifier onlyTreasuryOrOwner() {
        require(
            treasury == _msgSender() || owner() == _msgSender(),
            "Caller is not the owner or treasury"
        );
        _;
    }

    /*
     * @notice: Checks if the msg.sender is the partnerMintContract
     */
    modifier onlyPartner() {
        require(partnerMintContract == _msgSender(), "Caller is not partner");
        _;
    }

    /* ======== SETTERS ======== */

    /*
     * @notice: Pause the smart contract
     * @param: paused_: A boolean to pause or unpause the contract
     */
    function setPaused(bool paused_) external onlyTreasuryOrOwner {
        if (paused_) _pause();
        else _unpause();
    }

    /*
     * @notice: Set the private sale enabled or enabled
     * @param: privateSaleActive_: A boolean to pause or unpause the private sale
     */
    function setPrivateSale(bool privateSaleActive_)
        external
        onlyTreasuryOrOwner
    {
        require(
            privateSaleActive != privateSaleActive_,
            "KaijuLegends: Sale is the same"
        );
        privateSaleActive = privateSaleActive_;
        emit UpdatePrivateSaleActive(privateSaleActive_);
    }

    /*
     * @notice: Set the private sale price
     * @param: privateSalePrice_: The new price for the private sale in WEI
     */
    function setPrivateSalePrice(uint256 privateSalePrice_)
        external
        onlyTreasuryOrOwner
    {
        privateSalePrice = privateSalePrice_;
        emit UpdatePrivateSalePrice(privateSalePrice_);
    }

    /*
     * @notice: Set the max mint per transaction
     * @param: maxMintPerTx_: The new max mint per transaction
     */
    function setMaxMintPerTx(uint256 maxMintPerTx_)
        external
        onlyTreasuryOrOwner
    {
        maxMintPerTx = maxMintPerTx_;
        emit UpdateMaxMintPerTx(maxMintPerTx_);
    }

    /*
     * @notice: Set the new base URI
     * @param: baseURI_: The string of the new base uri
     */
    function setBaseURI(string memory baseURI_) external onlyTreasuryOrOwner {
        baseURI = baseURI_;
        emit UpdateBaseURI(baseURI_);
    }

    /*
     * @notice: Set the new placeholder URI
     * @param: placeholderURI_: The string of the new placeholder URI
     */
    function setPlaceholderURI(string memory placeholderURI_)
        external
        onlyTreasuryOrOwner
    {
        placeholderURI = placeholderURI_;
        emit UpdatePlaceholderURI(placeholderURI_);
    }

    /*
     * @notice: Set the new treasury address
     * @param: treasury_: The new treasury address
     */
    function setTreasury(address treasury_) external onlyTreasuryOrOwner {
        treasury = treasury_;
        emit UpdateTreasury(treasury_);
    }

    /*
     * @notice: Set the new whitelist signer
     * @param: whitelistSigner_: The address of the new whitelist signer for the private sale
     */
    function setWhitelistSigner(address whitelistSigner_)
        external
        onlyTreasuryOrOwner
    {
        whitelistSigner = whitelistSigner_;
        emit UpdateWhitelistSigner(whitelistSigner_);
    }

    /*
     * @notice: Set the new private sale max mint per wallet
     * @param: maxMintPerWallet_: The max amount per wallet for the private sale
     */
    function setMaxMintPerWallet(uint256 maxMintPerWallet_)
        external
        onlyTreasuryOrOwner
    {
        maxMintPerWallet = maxMintPerWallet_;
        emit UpdateMaxMintPerWallet(maxMintPerWallet_);
    }

    /*
     * @notice: Set the new max supply for partner
     * @param: maxMintPerWallet_: The max supply for partner
     */
    function setPartnerMaxSupply(uint256 partnerMaxSupply_)
        external
        onlyTreasuryOrOwner
    {
        partnerMaxSupply = partnerMaxSupply_;
        emit UpdatePartnerMaxSupply(partnerMaxSupply);
    }

    /*
     * @notice: Set the new partnerMintContract address
     * @param: partnerMintContract_: The address of the new partner minting contract
     * @todo: Add the modifier `onlyTreasuryOrOwner`. This has been removed for now so partner can test this
     */
    function setPartnerMintContract(address partnerMintContract_) external {
        partnerMintContract = partnerMintContract_;
        emit UpdatePartnerMintContract(partnerMintContract_);
    }

    /* ======== INTERNAL ======== */

    /*
     * @notice: Validations of the mint process
     */
    function _validateMint(uint256 quantity_, bool isPartner) private {
        require(
            privateSaleActive,
            "KaijuLegends: Private sale has not begun yet"
        );
        if (!isPartner) {
            uint256 partnerTokensLeft = partnerMaxSupply - partnerSupply;
            require(
                (totalSupply() + quantity_) <=
                    (COLLECTION_SUPPLY - partnerTokensLeft),
                "KaijuLegends: Reached max private sale supply"
            );
        }
        require(
            quantity_ > 0 && quantity_ <= maxMintPerTx,
            "KaijuLegends: Reached max mint per tx"
        );
        require(
            (_numberMinted(_msgSender()) + quantity_) <= maxMintPerWallet,
            "KaijuLegends: Reached max mint per wallet"
        );
        _refundIfOver(privateSalePrice * quantity_);
    }

    /*
     * @notice: Recovering the hash and checking if the signer is equal to the `whitelistSigner`
     */
    function _validatePrivateSaleSignature(bytes memory signature_)
        private
        view
    {
        // Verify EIP-712 signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PRESALE_TYPEHASH, _msgSender()))
            )
        );
        address recoveredAddress = digest.recover(signature_);
        require(
            recoveredAddress != address(0) &&
                recoveredAddress == address(whitelistSigner),
            "KaijuLegends: Invalid signature"
        );
    }

    /*
     * @notice: If a user sends more ETH than the actuall mint price than the exceeded amount will be send back
     * @param: price_: The total price for the mint
     */
    function _refundIfOver(uint256 price_) private {
        require(msg.value >= price_, "Need to send more ETH.");
        if (msg.value > price_) {
            payable(_msgSender()).transfer(msg.value - price_);
        }
    }

    /* ======== EXTERNAL ======== */

    /*
     * @notice: The private sale mint
     * @param: quantity_: The mint amount
     * @param: signature_: The signature hash that will be used to verify the user has been whitelisted
     */
    function privateSaleMint(uint256 quantity_, bytes memory signature_)
        external
        payable
        whenNotPaused
    {
        _validateMint(quantity_, false);
        _validatePrivateSaleSignature(signature_);

        _safeMint(_msgSender(), quantity_);
    }

    /*
     * The partner partner sale
     * @param receiver_: The address that will receive the token
     * @param quantity_: The mint amount
     */
    function partnerSale(address receiver_, uint256 quantity_)
        external
        payable
        whenNotPaused
        onlyPartner
    {
        require(
            partnerMintContract != address(0),
            "KaijuLegends: partnerMintContract is the zero address"
        );
        require(
            (partnerSupply + quantity_) <= partnerMaxSupply,
            "KaijuLegends: Reached the max supply for partner"
        );

        _validateMint(quantity_, true);
        _safeMint(receiver_, quantity_);

        partnerSupply = partnerSupply + quantity_;
    }

    /*
     * @notice: This batch mint is meant for the CRYPTO.COM sale / Giveaways / Collaborations. Only the `treasury / owner` can mint them to a wallet
     * @param: to_: The address that will receive the token ids
     * @param: quantity_: The mint amount
     */
    function batchMint(
        address to_,
        uint256 quantity_,
        BatchMintType type_
    ) external onlyTreasuryOrOwner {
        require(quantity_ > 0, "KaijuLegends: Quantity must be higher than 0");
        uint256 partnerTokensLeft = partnerMaxSupply - partnerSupply;
        require(
            (totalSupply() + quantity_) <=
                (COLLECTION_SUPPLY - partnerTokensLeft),
            "KaijuLegends: Reached max private sale supply"
        );

        _safeMint(to_, quantity_);

        if (type_ == BatchMintType.CRYPTODOTCOM) {
            // 0
            cryptoDotComSupply += quantity_;
            emit UpdateCryptoDotComSupply(cryptoDotComSupply);
        } else if (type_ == BatchMintType.COLLABORATIONS) {
            // 1
            collaborationSupply += quantity_;
            emit UpdateCollaborationSupply(collaborationSupply);
        } else if (type_ == BatchMintType.GIVEAWAYS) {
            // 2
            giveawaySupply += quantity_;
            emit UpdateGiveawaySupply(giveawaySupply);
        } else if (type_ == BatchMintType.TEAM_TOKENS) {
            // 3
            teamTokensSupply += quantity_;
            emit UpdateTeamTokensSupply(teamTokensSupply);
        }
    }

    /*
     * @notice: Withdraw the ETH from the contract to the treasury address
     */
    function withdrawEth() external onlyTreasuryOrOwner nonReentrant {
        payable(address(treasury)).transfer(address(this).balance);
    }

    /*
     * @notice: Burn a token id to reduce the token supply
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /* ======== OVERRIDES ======== */

    /*
     * @notice: returns the baseURI for the token metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /*
     * @notice: returns a URI for the tokenId
     * @param: tokenId_: the minted token id
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId_), "URI query for nonexistent token");

        if (bytes(baseURI).length <= 0) {
            return placeholderURI;
        }

        string memory uri = _baseURI();
        return string(abi.encodePacked(uri, Strings.toString(tokenId_)));
    }

    /*
     * @notice: returns the number of tokens the address has minted
     * @param: owner: address that owns token ids
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }
}