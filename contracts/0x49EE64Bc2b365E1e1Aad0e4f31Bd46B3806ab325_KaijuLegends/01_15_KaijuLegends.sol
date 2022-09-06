// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";

contract KaijuLegends is Ownable, ERC721A, ReentrancyGuard, Pausable {
    /* ======== LIBRARIES ======== */

    using ECDSA for bytes32;

    /* ======== ENUMS ======== */

    enum BatchMintType {
        CRYPTODOTCOM, // 0
        GIVEAWAYS, // 1
        TEAM_TOKENS, // 2
        FREE_MINTS // 3
    }

    /* ======== EVENTS ======== */

    event UpdateSales(bool privateSaleActive, bool partnerSaleActive);
    event UpdateBurn(bool active);
    event UpdateMaxMint(uint256 maxMintPerTx, uint256 maxMintPerWallet);
    event UpdatePartnerMaxMint(uint256 partnerMaxMintPerTx, uint256 partnerMaxMintPerWallet);
    event UpdateTreasury(address treasury);
    event UpdateWhitelistSigner(address whitelistSigner);
    event UpdateBaseURI(string baseURI);
    event UpdatePlaceholderURI(string placeholderURI);
    event UpdatePrivateSalePrice(uint256 privateSalePrice);
    event UpdateCryptoDotComSupply(uint256 supply);
    event UpdateFreeMintsSupply(uint256 supply);
    event UpdateGiveawaySupply(uint256 supply);
    event UpdateTeamTokensSupply(uint256 supply);
    event UpdateMaxSupply(
        uint256 cryptoDotComMaxSupply,
        uint256 privateSaleMaxSupply_,
        uint256 partnerMaxSupply_
    );
    event UpdatePartnerMintContract(address partnerMintContract);

    /* ======== VARIABLES ======== */

    bool public privateSaleActive = true;
    bool public partnerSaleActive = false;
    bool public enableBurn = false;

    uint256 public constant COLLECTION_SUPPLY = 7777;
    uint256 public partnerMaxMintPerTx = 5;
    uint256 public partnerMaxMintPerWallet = 5;
    uint256 public maxMintPerTx = 3;
    uint256 public maxMintPerWallet = 6;
    uint256 public privateSalePrice = .15 ether;
    uint256 public partnerMaxSupply = 200;
    uint256 public cryptoDotComMaxSupply = 2000;
    uint256 public privateSaleMaxSupply = 5577;
    uint256 public cryptoDotComSupply;
    uint256 public giveawaySupply;
    uint256 public teamTokensSupply;
    uint256 public freeMintsSupply;
    uint256 public partnerSupply;
    uint256 public privateSaleSupply;

    address public treasury;
    address public whitelistSigner;
    address public partnerMintContract;

    string public baseURI;
    string public placeholderURI;

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PRESALE_TYPEHASH =
        keccak256("PrivateSale(address buyer)");

    /* ======== CONSTRUCTOR ======== */

    constructor() ERC721A("Kaiju Legends", "KAIJU") {
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
    function setSales(bool privateSaleActive_, bool partnerSaleActive_)
        external
        onlyTreasuryOrOwner
    {
        privateSaleActive = privateSaleActive_;
        partnerSaleActive = partnerSaleActive_;
        emit UpdateSales(privateSaleActive_, partnerSaleActive_);
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
     * @notice: Set the max mint per transaction for private sale
     * @param: maxMintPerTx_: The new max mint per transaction
     * @param: maxMintPerWallet_: The new max mint per wallet
     */
    function setPrivateSaleMaxMint(uint256 maxMintPerTx_, uint256 maxMintPerWallet_)
        external
        onlyTreasuryOrOwner
    {
        maxMintPerTx = maxMintPerTx_;
        maxMintPerWallet = maxMintPerWallet_;
        emit UpdateMaxMint(maxMintPerTx_, maxMintPerWallet_);
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
     * @notice: Set the new max supply for partner
     * @param: maxMintPerWallet_: The max supply for partner
     */
    function setMaxSupply(
        uint256 cryptoDotComMaxSupply_,
        uint256 privateSaleMaxSupply_,
        uint256 partnerMaxSupply_
    ) external onlyTreasuryOrOwner {
        cryptoDotComMaxSupply = cryptoDotComMaxSupply_;
        privateSaleMaxSupply = privateSaleMaxSupply_;
        partnerMaxSupply = partnerMaxSupply_;

        emit UpdateMaxSupply(
            cryptoDotComMaxSupply_,
            privateSaleMaxSupply_,
            partnerMaxSupply_
        );
    }

    /*
     * @notice: Set the new partnerMintContract address
     * @param: partnerMintContract_: The address of the new partner minting contract
     */
    function setPartnerMintContract(address partnerMintContract_)
        external
        onlyTreasuryOrOwner
    {
        partnerMintContract = partnerMintContract_;
        emit UpdatePartnerMintContract(partnerMintContract_);
    }

     /*
     * @notice: Set the max mint per transaction for partner
     * @param: partnerMaxMintPerTx: The new max mint per transaction
     * @param: partnerMaxMintPerWallet: The new max mint per wallet
     */
    function setPartnerSaleMaxMint(uint256 partnerMaxMintPerTx_, uint256 partnerMaxMintPerWallet_)
        external
        onlyTreasuryOrOwner
    {
        partnerMaxMintPerTx = partnerMaxMintPerTx_;
        partnerMaxMintPerWallet = partnerMaxMintPerWallet_;
        emit UpdatePartnerMaxMint(partnerMaxMintPerTx_, partnerMaxMintPerWallet_);
    }

    /*
     * @notice: If `enableBurn` = true burning will be enabled for people to burn else it will disabled
     * @param: enableBurn_: Enable or disable
     */
    function setEnableBurn(bool enableBurn_)
        external
        onlyTreasuryOrOwner
    {
        enableBurn = enableBurn_;
        emit UpdateBurn(enableBurn_);
    }

    /* ======== INTERNAL ======== */

    /*
     * @notice: Validations of the mint process
     */
    function _validateMint(
        address receiver_,
        uint256 quantity_,
        uint256 saleSupply_,
        uint256 saleMaxSupply_,
        uint256 saleMaxMintPerTx_,
        uint256 saleMaxMintPerWallet_,
        bool saleIsActive_
    ) private {
        require(
            saleIsActive_,
            "KaijuLegends: Sale has not begun yet"
        );
        require(
            (totalSupply() + quantity_) <= COLLECTION_SUPPLY,
            "KaijuLegends: Reached max supply"
        );
        require(
            (saleSupply_ + quantity_) <= saleMaxSupply_,
            "KaijuLegends: Reached max supply"
        );
        require(
            quantity_ > 0 && quantity_ <= saleMaxMintPerTx_,
            "KaijuLegends: Reached max mint per tx"
        );
        require(
            (_numberMinted(receiver_) + quantity_) <= saleMaxMintPerWallet_,
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
        _validateMint(_msgSender(), quantity_, privateSaleSupply, privateSaleMaxSupply, maxMintPerTx, maxMintPerWallet, privateSaleActive);
        _validatePrivateSaleSignature(signature_);

        _safeMint(_msgSender(), quantity_);

        privateSaleSupply += quantity_;
    }

    /*
     * The partner partner sale
     * @param receiver_: The address that will receive the token
     * @param quantity_: The mint amount
     */
    function partnerSale(address receiver_, uint256 quantity_)
        external
        payable
        onlyPartner
    {
        require(
            partnerMintContract != address(0),
            "KaijuLegends: partnerMintContract is the zero address"
        );

        _validateMint(receiver_, quantity_, partnerSupply, partnerMaxSupply, partnerMaxMintPerTx, partnerMaxMintPerWallet, partnerSaleActive);
        _safeMint(receiver_, quantity_);

        partnerSupply += quantity_;
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
        require(
            (totalSupply() + quantity_) <= COLLECTION_SUPPLY,
            "KaijuLegends: Reached max supply"
        );

        _safeMint(to_, quantity_);

        if (type_ == BatchMintType.CRYPTODOTCOM) {
            require(
                (cryptoDotComSupply + quantity_) <= cryptoDotComMaxSupply,
                "KaijuLegends: Reached the max supply for cryptoDotCom"
            );
            // 0
            cryptoDotComSupply += quantity_;
            emit UpdateCryptoDotComSupply(cryptoDotComSupply);
        } else if (type_ == BatchMintType.GIVEAWAYS) {
            // 1
            giveawaySupply += quantity_;
            emit UpdateGiveawaySupply(giveawaySupply);
        } else if (type_ == BatchMintType.TEAM_TOKENS) {
            // 2
            teamTokensSupply += quantity_;
            emit UpdateTeamTokensSupply(teamTokensSupply);
        } else if (type_ == BatchMintType.FREE_MINTS) {
            // 3
            freeMintsSupply += quantity_;
            emit UpdateFreeMintsSupply(freeMintsSupply);
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
        require(enableBurn, 'KaijuLegends: Not possible to burn');
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