// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "erc721a/contracts/ERC721A.sol";

contract EnchantedCreaturesClub is Ownable, ERC721A, ReentrancyGuard, Pausable {
    /* ======== ENUMS ======== */

    enum BatchMintType {
        GIVEAWAYS, // 0
        TEAM_TOKENS // 1
    }

    /* ======== EVENTS ======== */

    event UpdateTreasury(address treasury);
    event UpdateGameToken(address gameToken);
    event UpdateBaseURI(string baseURI);
    event UpdatePlaceholderURI(string placeholderURI);
    event UpdateMaxPerTx(uint256 maxPerTx);
    event UpdateEggRate(uint256 rate);
    event UpdateNativeRate(uint256 rate);
    event UpdateEggToken(address eggToken, uint256 eggDecimals);
    event UpdateBurn(bool active);
    event UpdateGiveawaySupply(uint256 supply);
    event UpdateFreeMintAmount(uint256 amount);
    event UpdateBatchMintSupply(uint256 amount);
    event updateWhitelistSale(bool sale);
    event updateSaleAmount(
        uint256 firstSaleMaxSupply,
        uint256 secondSaleMaxSupply
    );
    event UpdateTeamTokensSupply(uint256 supply);
    event UpdateEnableFreeClaim(bool enabled);
    event UpdateEnableMintStatus(
        bool enableMintWithNative,
        bool enableMintWithEgg
    );

    /* ======== VARIABLES ======== */

    uint256 public constant COLLECTION_SUPPLY = 10000;
    uint256 public firstSaleMaxSupply = 4000;
    uint256 public secondSaleMaxSupply = 6000;
    uint256 public eggRate = 800000;
    uint256 public freeMintAmount = 1;
    uint256 public nativeRate = 0.01 ether;
    uint256 public maxPerTx = 5;
    uint256 public eggDecimals;
    uint256 public giveawaySupply;
    uint256 public teamTokensSupply;
    uint256 public batchMintSupply;
    uint256 public firstSale;
    uint256 public secondSale;

    address public treasury;
    address public eggToken;
    address public gameToken;

    string public baseURI;
    string public placeholderURI;

    bool public enableBurn;
    bool public enableMintWithNative = false;
    bool public enableMintWithEgg = true;
    bool public enableFreeClaim = true;
    bool public whitelistSaleActive = true;

    mapping(address => bool) public freeMinters;

    /* ======== CONSTRUCTOR ======== */

    constructor() ERC721A("Enchanted Creatures Club", "ECC") {
        _pause();
    }

    /* ======== MODIFIERS ======== */

    /*
     * @notice: Checks if the msg.sender is the owner or the treasury address
     */
    modifier onlyTreasuryOrOwner() {
        require(
            treasury == _msgSender() || owner() == _msgSender(),
            "The caller is another address"
        );
        _;
    }

    /*
     * @notice: Checks if the origin is not a contract
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
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
     * @notice: Set the new egg token
     * @param: eggToken_: The egg token address
     * @param: eggDecimals_: The token decimals of egg
     */
    function setEggToken(address eggToken_, uint256 eggDecimals_)
        external
        onlyTreasuryOrOwner
    {
        eggToken = eggToken_;
        eggDecimals = eggDecimals_;
        emit UpdateEggToken(eggToken_, eggDecimals_);
    }

    /*
     * @notice: Set the egg rate per token
     * @param: eggRate_: The rate per token
     */
    function setEggRate(uint256 eggRate_) external onlyTreasuryOrOwner {
        eggRate = eggRate_;
        emit UpdateEggRate(eggRate_);
    }

    /*
     * @notice: Set the native rate per token
     * @param: nativeRate_: The native rate per token
     */
    function setNativeRate(uint256 nativeRate_) external onlyTreasuryOrOwner {
        nativeRate = nativeRate_;
        emit UpdateNativeRate(nativeRate_);
    }

    /*
     * @notice: Set the game nft token
     * @param: gameToken_: The game nft address
     */
    function setGameToken(address gameToken_) external onlyTreasuryOrOwner {
        gameToken = gameToken_;
        emit UpdateGameToken(gameToken_);
    }

    /*
     * @notice: If `enableBurn` = true burning will be enabled for people to burn else it will disabled
     * @param: enableBurn_: Enable or disable
     */
    function setEnableBurn(bool enableBurn_) external onlyTreasuryOrOwner {
        enableBurn = enableBurn_;
        emit UpdateBurn(enableBurn_);
    }

    /*
     * @notice: Enable or disable the free mint
     * @param: enableFreeClaim_: Enable or disable
     */
    function setEnableFreeClaim(bool enableFreeClaim_)
        external
        onlyTreasuryOrOwner
    {
        enableFreeClaim = enableFreeClaim_;
        emit UpdateEnableFreeClaim(enableFreeClaim_);
    }

    /*
     * @notice: Set the max mints per transaction
     * @param: maxPerTx_: The max mint amount per transaction
     */
    function setMaxPerTx(uint256 maxPerTx_) external onlyTreasuryOrOwner {
        maxPerTx = maxPerTx_;
        emit UpdateMaxPerTx(maxPerTx_);
    }

    /*
     * @notice: Set the free mint amount a user can claim
     * @param: freeMintAmount_: The free mint amount
     */
    function setFreeMintAmount(uint256 freeMintAmount_)
        external
        onlyTreasuryOrOwner
    {
        freeMintAmount = freeMintAmount_;
        emit UpdateFreeMintAmount(freeMintAmount_);
    }

    /*
     * @notice: Sets the whitelist sale active or not
     * @param: whitelistSaleActive_: Enable or disable
     */
    function setWhitelistSaleActive(bool whitelistSaleActive_)
        external
        onlyTreasuryOrOwner
    {
        whitelistSaleActive = whitelistSaleActive_;
        emit updateWhitelistSale(whitelistSaleActive_);
    }

    /*
     * @notice: Enable or disable the minting with eth or egg token
     * @param: enableMintWithNative_: Enable or disable the minting with eth
     * @param: enableMintWithEgg_: Enable or disable the minting with the egg token
     */
    function setEnableMintWith(
        bool enableMintWithNative_,
        bool enableMintWithEgg_
    ) external onlyTreasuryOrOwner {
        enableMintWithNative = enableMintWithNative_;
        enableMintWithEgg = enableMintWithEgg_;
        emit UpdateEnableMintStatus(enableMintWithNative_, enableMintWithEgg_);
    }

    /*
     * @notice: Sets the sale amounts
     * @param: firstSale_: Amount for the first sale
     * @param: secondSale_: Amount for the second sale
     */
    function setSales(uint256 firstSaleMaxSupply_, uint256 secondSaleMaxSupply_)
        external
        onlyTreasuryOrOwner
    {
        // Not adding a require here because the sale COLLECTION_SUPPLY is a constant
        firstSaleMaxSupply = firstSaleMaxSupply_;
        secondSaleMaxSupply = secondSaleMaxSupply_;
        emit updateSaleAmount(firstSaleMaxSupply_, secondSaleMaxSupply_);
    }

    /* ======== INTERNAL ======== */

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

    /*
     * @notice: Validations of the mint process
     */
    function _validateMint(
        bool mintIsActive,
        bool isNative,
        bool isPublicSale,
        uint256 price_,
        uint256 quantity_
    ) private {
        require(mintIsActive, "ECC: Mint is not enabled");
        require(
            quantity_ > 0 && quantity_ <= maxPerTx,
            "ECC: Reached max mint per tx"
        );
        require(
            (totalSupply() + quantity_) <= COLLECTION_SUPPLY,
            "ECC: Reached max supply"
        );

        if (isPublicSale) {
            require(
                (secondSale + quantity_) <= secondSaleMaxSupply,
                "ECC: Reached the max supply for secondSale"
            );
        } else {
            require(
                (firstSale + quantity_) <= firstSaleMaxSupply,
                "ECC: Reached the max supply for firstSale"
            );
        }

        if (!isNative) {
            require(
                eggToken != address(0),
                "ECC: Egg token is the zero address"
            );
            uint256 balance = IERC20(eggToken).balanceOf(_msgSender());
            require(balance >= price_, "ECC: Need to send more EGG.");
        } else {
            _refundIfOver(nativeRate * quantity_);
        }
    }

    /* ======== EXTERNAL ======== */

    /*
     * @notice: returns the number of tokens the address has minted
     * @param: owner: address that owns token ids
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /*
     * @notice: This batch mint is meant for team / giveaways etc..
     * @param: to_: The address that will receive the token ids
     * @param: quantity_: The mint amount
     */
    function batchMint(
        address to_,
        uint256 quantity_,
        BatchMintType type_
    ) external onlyTreasuryOrOwner {
        require(quantity_ > 0, "ECC: Quantity must be higher than 0");
        require(
            (totalSupply() + quantity_) <= COLLECTION_SUPPLY,
            "ECC: Reached max supply"
        );

        if (type_ == BatchMintType.GIVEAWAYS) {
            // 0
            giveawaySupply += quantity_;
            emit UpdateGiveawaySupply(giveawaySupply);
        } else if (type_ == BatchMintType.TEAM_TOKENS) {
            // 1
            teamTokensSupply += quantity_;
            emit UpdateTeamTokensSupply(teamTokensSupply);
        } else {
            batchMintSupply += quantity_;
            emit UpdateBatchMintSupply(batchMintSupply);
        }

        _safeMint(to_, quantity_);
    }

    /*
     * @notice: Withdraw the FUNDS from the contract to the treasury address
     */
    function withdrawFunds() external onlyTreasuryOrOwner nonReentrant {
        payable(address(treasury)).transfer(address(this).balance);
    }

    /*
     * @notice: Mint a athlete with the egg tokens
     * @param: quantity_: The amount of nfts to mint
     */
    function mintWhitelistWithEgg(uint256 quantity_)
        external
        whenNotPaused
        callerIsUser
    {
        require(whitelistSaleActive, "ECC: Whitelist sale is not active");
        require(gameToken != address(0), "ECC: Game token is the zero address");
        require(
            IERC721(gameToken).balanceOf(_msgSender()) > 0 ||
                IERC20(eggToken).balanceOf(_msgSender()) > 0,
            "ECC: No eggs or game tokens"
        );
        uint256 price = (eggRate * quantity_) * (10**eggDecimals);
        _validateMint(enableMintWithEgg, false, false, price, quantity_);
        require(
            IERC20(eggToken).transferFrom(_msgSender(), treasury, price),
            "ECC: Failed to transfer tokens"
        );
        firstSale += quantity_;
        _safeMint(_msgSender(), quantity_);
    }

    /*
     * @notice: Mint a athlete with the egg tokens
     * @param: quantity_: The amount of nfts to mint
     */
    function mintWhitelistWithNative(uint256 quantity_)
        external
        payable
        whenNotPaused
        callerIsUser
    {
        require(whitelistSaleActive, "ECC: Whitelist sale is not active");
        require(gameToken != address(0), "ECC: Game token is the zero address");
        require(
            IERC721(gameToken).balanceOf(_msgSender()) > 0 ||
                IERC20(eggToken).balanceOf(_msgSender()) > 0,
            "ECC: No eggs or game tokens"
        );
        _validateMint(enableMintWithNative, true, false, msg.value, quantity_);
        firstSale += quantity_;
        _safeMint(_msgSender(), quantity_);
    }

    /*
     * @notice: Mint a athlete with the egg tokens
     * @param: quantity_: The amount of nfts to mint
     */
    function mintPublicWithEgg(uint256 quantity_)
        external
        whenNotPaused
        callerIsUser
    {
        require(!whitelistSaleActive, "ECC: Whitelist sale is active");
        uint256 price = (eggRate * quantity_) * (10**eggDecimals);
        _validateMint(enableMintWithEgg, false, true, price, quantity_);
        require(
            IERC20(eggToken).transferFrom(_msgSender(), treasury, price),
            "ECC: Failed to transfer tokens"
        );
        secondSale += quantity_;
        _safeMint(_msgSender(), quantity_);
    }

    /*
     * @notice: Mint a athlete with the egg tokens
     * @param: quantity_: The amount of nfts to mint
     */
    function mintPublicWithNative(uint256 quantity_)
        external
        payable
        whenNotPaused
        callerIsUser
    {
        require(!whitelistSaleActive, "ECC: Whitelist sale is active");
        _validateMint(enableMintWithNative, true, true, msg.value, quantity_);
        secondSale += quantity_;
        _safeMint(_msgSender(), quantity_);
    }

    /*
     * @notice: Claim a free token
     */
    function claimFreeMintWhitelist()
        external
        whenNotPaused
        callerIsUser
        nonReentrant
    {
        require(enableFreeClaim, "ECC: Free claim is not enabled");
        require(!freeMinters[_msgSender()], "ECC: Already claimed");
        require(whitelistSaleActive, "ECC: Whitelist sale is not active");
        require(
            IERC721(gameToken).balanceOf(_msgSender()) > 0 ||
                IERC20(eggToken).balanceOf(_msgSender()) > 0,
            "ECC: No eggs or game tokens"
        );

        freeMinters[_msgSender()] = true;
        _safeMint(_msgSender(), freeMintAmount);
    }

    /*
     * @notice: Claim a free token
     */
    function claimFreeMintPublic()
        external
        whenNotPaused
        callerIsUser
        nonReentrant
    {
        require(enableFreeClaim, "ECC: Free claim is not enabled");
        require(!freeMinters[_msgSender()], "ECC: Already claimed");
        require(!whitelistSaleActive, "ECC: Whitelist sale is active");

        freeMinters[_msgSender()] = true;
        _safeMint(_msgSender(), freeMintAmount);
    }

    /*
     * @notice: Burn a token id to reduce the token supply
     */
    function burn(uint256 tokenId) external {
        require(enableBurn, "ECC: Not possible to burn");
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
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");

        if (bytes(baseURI).length <= 0) {
            return placeholderURI;
        }

        string memory uri = _baseURI();
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
    }
}