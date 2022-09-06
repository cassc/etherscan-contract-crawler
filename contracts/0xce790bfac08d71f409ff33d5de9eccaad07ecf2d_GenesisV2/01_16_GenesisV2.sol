//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.11;

import "./ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";

contract GenesisV2 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    uint256 public tokenCounter;

    // type 1 counter
    uint256 public genesisMemberCounter;

    uint256 public keySocietyCounter;

    // range for sale
    uint256[] public saleRange;

    uint256[] temp;

    // base uri for token
    string private baseUri;

    // token uri extension
    string private baseExtension;

    // Users structure
    struct Users {
        address user;
        uint256 count;
    }

    // genesis user mapping w.r.t their address
    mapping(address => Users) public genesisList;

    // key society sale status
    bool public keySocietySaleStatus;

    // genesis sale status
    bool public genesisSaleStatus;

    // max NFT limit
    uint256 public maxNFT;

    // get token type
    mapping(uint256 => string) public tokenType;

    // genesis whitelist structure.
    struct Whitelist {
        bool isWhitlelisted;
        bool isClaimed;
    }

    // mapping of user address with whitelist data
    mapping(address => Whitelist) public WhitelistedAddress;

    // Order struct
    struct Order {
        uint256 num;
        uint256 price;
        uint256 usdPrice;
        bytes32 messageHash;
    }

    // cross mint address
    address public crossMintAddress;

    // merchant wallet address
    address public merchantWallet;

    // unlimited stage enable disable
    bool public genesisUnlimitedStage;

    // check for no repetition of signature
    mapping(bytes => bool) public signatureCheck;

    // token details
    struct Token {
        uint256 tokenId;
        string tokenType;
    }

    // Price
    uint256 public Price;

    // crossmint token counter
    uint256 public crossmintCounter;

    /**
     * @dev Emitted when new gensis token is minted.
     */
    event GenesisPurchased(
        address user,
        uint256[] tokenIds,
        uint256 ethPrice,
        uint256 usdPrice,
        string tokenType
    );

    /**
     * @dev Emitted when new token minted by owner.
     */
    event KeySocietyClaimed(address user, uint256 tokenId, string tokenType);

    /**
     * @dev Emitted when new token minted by owner.
     */
    event crossmintToTokenDetails(
        address to,
        uint256[] tokenIds,
        uint256 userId,
        uint256 priceETH,
        uint256 priceUSD,
        string tokenType
    );

    /**
     * @dev Emitted when new tokens are airdroped.
     */
    event AirDrop(address[] user, uint256[] tokenIds, string tokenType);

    // initialisation section

    function initialize() public initializer {
        __ERC721_init("Clubhouse Archives", "CAG");
        __Ownable_init();
        __ReentrancyGuard_init();

        baseUri = "https://s3.amazonaws.com/assets.thearchivesmint.xyz/token-uri/";
        baseExtension = "/token-uri.json";

        saleRange = [80, 1880];
        maxNFT = 2;

        keySocietySaleStatus = true;
        genesisSaleStatus = true;
        genesisUnlimitedStage = true;

        keySocietyCounter = 0; // id = 1
        genesisMemberCounter = 0; // id = 2

        merchantWallet = owner();

        crossMintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
    }

    function withdraw() external virtual nonReentrant onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev updates the totalSupply range
     *
     * @param _saleRangeIds range of token supply according to their types
     * Example: [1, 80, 1960]. From 1 to 80 = type 1
     * From 81 to 1960 = type 2
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateTotalSupply(
        uint256[] calldata _saleRangeIds,
        uint256 _maxNft
    ) external virtual onlyOwner {
        delete saleRange;
        saleRange.push(_saleRangeIds[0]);
        saleRange.push(_saleRangeIds[1]);
        maxNFT = _maxNft;
    }

    /**
     * @dev updates the token base uri and extension
     *
     * @param _baseuri base uri. (Ex. "https://abc.com/")
     * @param _extension extension uri. (Ex. ".json", "-token-uri.json", etc)
     *
     * Requirements:
     * - only owner can update value.
     */

    function upadateDefaultUri(string memory _baseuri, string memory _extension)
        external
        virtual
        onlyOwner
    {
        baseUri = _baseuri;
        baseExtension = _extension;
    }

    /**
     * @dev updates the token minting price in crossmint function.
     *
     * @param _price mint price
     *
     * Requirements:
     * - only owner can update value.
     */

    function updatePrice(uint256 _price) external virtual onlyOwner {
        Price = _price;
    }

    /**
     * @dev user can view its balance token ids and its type
     *
     * @param _user user wallet address
     *
     * Returns:
     * - Array of struct Token
     */

    function userBalance(address _user)
        external
        view
        virtual
        returns (Token[] memory TokenDetails)
    {
        uint256 number = _userBalance[_user].length;
        TokenDetails = new Token[](number);
        uint256 j = 0;

        for (uint256 i = 0; i < number; i++) {
            if (_userBalance[_user][i] != 0) {
                Token memory _data = Token(
                    _userBalance[_user][i],
                    tokenType[_userBalance[_user][i]]
                );
                TokenDetails[j] = _data;
                j++;
            }
        }
    }

    /**
     * @dev updates the status of sales.
     *
     * @param _key_society key society status
     * @param _genesis_status genesis member society society
     * @param _genesis_unlimited_stage unlimited stage status
     *
     * Requirements:
     * - only owner can update value.
     */

    function upadateSaleStatus(
        bool _key_society,
        bool _genesis_status,
        bool _genesis_unlimited_stage
    ) external virtual onlyOwner {
        keySocietySaleStatus = _key_society;
        genesisSaleStatus = _genesis_status;
        genesisUnlimitedStage = _genesis_unlimited_stage;
    }

    /**
     * @dev updates the cross mint and merchant wallet address.
     *
     * @param _cross_mint_address cross mint address
     * @param _merchant_wallet merchant wallet address
     *
     * Requirements:
     * - only owner can update value.
     */

    function updateCrossMintAndMerchantAddress(
        address _cross_mint_address,
        address _merchant_wallet
    ) external virtual onlyOwner {
        crossMintAddress = _cross_mint_address;
        merchantWallet = _merchant_wallet;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     *
     * @param _tokenId tokenid.
     */

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "GenesisV1: URI query for nonexistent token"
        );
        return
            string(
                abi.encodePacked(
                    baseUri,
                    StringsUpgradeable.toString(_tokenId),
                    baseExtension
                )
            );
    }

    /**
     * @dev adds and removes user from whitelist list.
     *
     * @param _addresses array of addresses.
     * @param _status whitelist status
     *
     * Requirements:
     * - msg.sender must be owner of contract.
     *
     * Returns
     * - boolean.
     *
     */

    function addOrRemoveWhitelistUser(
        address[] calldata _addresses,
        bool _status
    ) external virtual onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            WhitelistedAddress[_addresses[i]].isWhitlelisted = _status;
        }
    }

    /**
     * @dev claim the key society token. Only whitelisted addresses can claim.
     *
     * Requirements:
     * - msg.sender must be whitelist and have not been claimed.
     *
     * Emits a {KeySocietyClaimed} event.
     */

    function keySocietyClaim() external virtual {
        require(
            keySocietySaleStatus && saleRange[0] >= keySocietyCounter,
            "GenesisV1: Sale is closed"
        );

        require(
            WhitelistedAddress[msg.sender].isWhitlelisted &&
                !WhitelistedAddress[msg.sender].isClaimed,
            "GenesisV1: User is not whitelisted or already claimed"
        );

        tokenCounter += 1;
        _mint(msg.sender, tokenCounter);

        tokenType[tokenCounter] = "KEY-SOCIETY";
        keySocietyCounter += 1;
        WhitelistedAddress[msg.sender].isClaimed = true;

        emit KeySocietyClaimed(msg.sender, tokenCounter, "KEY-SOCIETY");
    }

    /**
     * @dev genesis member token minting
     *
     * @param order order structure
     * @param signature owner's signature
     *
     * Requirements:
     * - msg.sender must be whitelist as genesis member.
     *
     * Emits a {GenesisPurchased} event.
     */

    function genesisTokenSale(Order memory order, bytes memory signature)
        external
        payable
        virtual
    {
        require(
            genesisSaleStatus && saleRange[1] >= genesisMemberCounter,
            "GenesisV1: genesis sale is closed"
        );

        bool status = SignatureCheckerUpgradeable.isValidSignatureNow(
            owner(),
            order.messageHash,
            signature
        );
        require(
            status && !signatureCheck[signature],
            "$GenesisV1: cannot purchase the token"
        );

        if (genesisList[msg.sender].user == msg.sender) {
            genesisList[msg.sender].count += order.num;
        }

        if (genesisList[msg.sender].user == address(0)) {
            Users memory _data = Users(msg.sender, order.num);
            genesisList[msg.sender] = _data;
        }

        if (genesisUnlimitedStage) {
            require(
                genesisList[msg.sender].count <= maxNFT &&
                    order.price == msg.value,
                "GenesisV1: Exceeds max count or invalid price"
            );
        }

        for (uint256 i = 0; i < order.num; i++) {
            tokenCounter += 1;
            _mint(msg.sender, tokenCounter);
            temp.push(tokenCounter);
        }

        tokenType[tokenCounter] = "GENESIS-MEMBER";
        genesisMemberCounter += order.num;
        signatureCheck[signature] = true;

        payable(merchantWallet).transfer(msg.value); // merchant wallet

        emit GenesisPurchased(
            msg.sender,
            temp,
            msg.value,
            order.usdPrice,
            "GENESIS-MEMBER"
        );

        delete temp;
    }

    /**
     * @dev mint to method used by cross mint address.
     *
     * @param to to address where token to be minted
     * @param count number of tokens to be minted
     * @param userId user id from db
     * @param usd_price usd price
     *
     * Requirements:
     * - msg.sender must be crossmmint address
     *
     * Returns
     * - boolean.
     *
     * Emits a {crossmintToTokenDetails} event.
     */

    function mintTo(
        address to,
        uint256 count,
        uint256 userId,
        uint256 usd_price
    ) external payable returns (bool) {
        require(
            msg.sender == crossMintAddress,
            "GenesisV1: Method can be only called by Cross mint address"
        );

        uint256 _price = Price * count;
        require(_price <= msg.value, "GenesisV1: Price is incorrect");

        for (uint256 i = 0; i < count; i++) {
            tokenCounter += 1;
            _mint(to, tokenCounter);
            temp.push(tokenCounter);
        }

        tokenType[tokenCounter] = "GENESIS-MEMBER";
        crossmintCounter += 1;

        payable(merchantWallet).transfer(msg.value);

        emit crossmintToTokenDetails(
            to,
            temp,
            userId,
            msg.value,
            usd_price,
            "GENESIS-MEMBER"
        );

        delete temp;

        return true;
    }

    /**
     * @dev updates the cross mint token count
     *
     * @param _count count of cross mint
     *
     * Requirements:
     * - msg.sender must be owner address
     *
     */

    function updateGenesisDetails(uint256 _count) external virtual onlyOwner {
        crossmintCounter = _count;
        for (uint256 i = 1; i <= tokenCounter; i++) {
            bytes memory tempString = bytes(tokenType[i]);
            if (tempString.length == 0) {
                tokenType[i] = "GENESIS-MEMBER";
            }
        }
    }

    /**
     * @dev airdrops the tokens to array of addresses
     *
     * @param _addresses to address where token to be minted
     *
     * Requirements:
     * - msg.sender must be owner address
     *
     * Emits a {AirDrop} event.
     */

    function airdrop(address[] calldata _addresses) external virtual onlyOwner {
        require(
            saleRange[1] >= genesisMemberCounter,
            "GenesisV1: overflow supply"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            tokenCounter += 1;
            genesisMemberCounter += 1;
            _mint(_addresses[i], tokenCounter);
            tokenType[tokenCounter] = "GENESIS-MEMBER";
            temp.push(tokenCounter);
        }

        emit AirDrop(_addresses, temp, "GENESIS-MEMBER");

        delete temp;
    }
}