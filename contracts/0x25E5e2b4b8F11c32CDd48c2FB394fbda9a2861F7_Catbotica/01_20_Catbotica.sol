//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract Catbotica is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _redeemIds;
    Counters.Counter private _tokenIds;

    bool public saleActive = false;
    string public PROVENANCE_HASH;
    string private baseURI;

    string private tokenSuffixURI;
    string private contractMetadata = 'contract.json';
    uint256 public constant TICK_PERIOD = 30 minutes; // Time period to decrease price
    uint256 public constant PUBLIC_SALE_PERIOD = 4 hours; // Dutch Auction Time Period
    uint256 public constant STARTING_PRICE = 200000000000000000; // 0.2 ETH
    uint256 public constant BOTTOM_PRICE = 80000000000000000; // 0.08 ETH
    uint256 public constant SALE_PRICE_STEP = 20000000000000000; // 0.02 ETH
    uint256 public constant PRIVATE_SALE_PRICE = 80000000000000000; // 0.08 ETH
    uint256 public constant MINT_BATCH_LIMIT = 5; // Max number of Tokens minted in a txn
    uint256 public constant RESERVED_TOKEN_ID_OFFSET = 500; // Tokens reserved for RWA list

    uint256 public saleStartsAt;
    uint256 public publicsaleStartsAt;
    uint256 public publicsaleEndsAt;
    uint256 public privatesaleStartsAt;
    uint256 public privatesaleEndsAt;
    uint256 public redemptionEndsAt;

    uint16 public constant MAX_PRIVATE_SALE_SUPPLY = 3000; // Cap for tokens to be sold in private sale is 2500 in addition to 500 for redmeption by RWA list
    uint16 public constant MAX_TOKENS = 12000; // Max number of token sold in  sale
    address[] private recipients;
    uint16[] private splits;
    uint16 public constant SPLIT_BASE = 10000;

    mapping(address => bool) public proxyRegistryAddress;

    // schema of the RWA/PWA list record
    struct waRecord {
        uint8 balance; // amount allowed to redeem
        bool exists; // if the user is whitelisted or not
        bool redeemed;
        uint8 limit; // max num tokens allowed to buy in private sale
        bool minted;
    }

    mapping(address => waRecord) public _waList;

    event TokenMinted(address indexed owner, uint256 indexed quantity);
    event SaleStatusChange(address indexed issuer, bool indexed status);
    event ContractWithdraw(address indexed initiator, uint256 amount);
    event ContractWithdrawToken(address indexed initiator, address indexed token, uint256 amount);
    event ProvenanceHashSet(address indexed initiator, string previousHash, string newHash);
    event WithdrawAddressChanged(address indexed previousAddress, address indexed newAddress);

    uint16 internal royalty = 750; // base 10000, 7.5%
    uint16 public constant BASE = 10000;

    constructor(
        uint256 _saleStartTime,
        uint256 _privateSaleEndsAt,
        uint256 _publicSaleStartsAt,
        uint256 _publicsaleEndsAt,
        uint256 _redemptionEndsAt,
        string memory _baseContractURI,
        string memory _tokenSuffixURI,
        string memory _provenanceHash,
        address[] memory _recipients,
        uint16[] memory _splits,
        address _proxyAddress
    ) ERC721('Catbotica', 'CBOT') {
        baseURI = _baseContractURI;
        tokenSuffixURI = _tokenSuffixURI;
        saleStartsAt = _saleStartTime; // Unix Timestamp for sale starting time
        privatesaleStartsAt = saleStartsAt; // Start Private Sale
        privatesaleEndsAt = _privateSaleEndsAt; // End of Private Sale
        publicsaleStartsAt = _publicSaleStartsAt; // Start of Public Sale
        publicsaleEndsAt = _publicsaleEndsAt; // End of Public Sale
        redemptionEndsAt = _redemptionEndsAt; // End of period for members to redeem free tokens
        PROVENANCE_HASH = _provenanceHash;
        recipients = _recipients;
        splits = _splits;
        proxyRegistryAddress[_proxyAddress] = true;
    }

    function mintNFT(address recipient, uint8 numTokens) public onlyOwner {
        uint256 time = (block.timestamp);
        require(time > privatesaleEndsAt && time < publicsaleStartsAt, 'Not Allowed');
        require(
            (_tokenIds.current() + numTokens + RESERVED_TOKEN_ID_OFFSET) <= MAX_PRIVATE_SALE_SUPPLY,
            'Private sale over'
        );
        for (uint8 i = 0; i < numTokens; i++) {
            _tokenIds.increment();
            _safeMint(recipient, _tokenIds.current() + RESERVED_TOKEN_ID_OFFSET);
        }
        emit TokenMinted(recipient, numTokens);
    }

    function claimUnredeemed(address recipient, uint8 numTokens) public onlyOwner {
        uint256 time = (block.timestamp);
        require(time > redemptionEndsAt, 'Redemption still active');
        require((_redeemIds.current() + numTokens) <= RESERVED_TOKEN_ID_OFFSET, 'Tokens Redeemed');
        for (uint8 i = 0; i < numTokens; i++) {
            _redeemIds.increment();
            _safeMint(recipient, _redeemIds.current());
        }
        emit TokenMinted(recipient, numTokens);
    }

    /**
     * @dev mints equivalent of `msg.sender` whitelisted balance of Catbotica token and assigns it to
     * `msg.sender` by calling _safeMint function. Dedicated for free redemotion for Catbotica RWA List.
     *
     * Emits a {TokenMinted} event.
     * Emits two {TransferSingle} events via ERC721 Contract.
     *
     * Requirements:
     * - `saleActive` must be set to true.
     * - Current timestamp must greater than or equal `saleStartsAt`.
     * - `msg.sender` is among whitelisted Catbotica RWA list members and hasn't redeemed the token before.
     * - Max number of tokens assigned for free redemption not reahced
     */
    function memberRedeem() public {
        require(block.timestamp >= saleStartsAt && block.timestamp < redemptionEndsAt, 'Redeem not active');
        uint8 userBalance = _waList[msg.sender].balance;
        require((_redeemIds.current()) + userBalance <= RESERVED_TOKEN_ID_OFFSET, 'Tokens Redeemed');
        require(_waList[msg.sender].exists, 'Restricted access');
        require(!_waList[msg.sender].redeemed, 'Tokens redeemed');
        _waList[msg.sender].redeemed = true;
        for (uint8 i = 0; i < userBalance; i++) {
            _redeemIds.increment();
            _safeMint(msg.sender, _redeemIds.current());
        }
        emit TokenMinted(msg.sender, userBalance);
    }

    /**
     * @dev mints `numTokens` tokens of Catbotica token and assigns it to
     * `msg.sender` by calling _safeMint function.
     *
     * Emits a {TokenMinted} event.
     * Emits two {TransferSingle} events via ERC721 Contract.
     *
     * Requirements:
     * - `saleActive` must be set to true.
     * - Current timestamp must greater than or equal `saleStartsAt`.
     * - Current timestamp must within period of private sale `privatesaleStartsAt` - `privatesaleEndsAt`.
     * - `msg.sender` is among whitelisted Catbotica memebrs or partners
     * - Ether amount sent greater or equal the base price multipled by `numTokens`.
     * - `numTokens` within limits of max number of tokens minted in single txn.
     * - Max number of tokens for the private sale not reahced
     * @param numTokens - Number of tokens to be minted
     */
    function mintPrivateSale(uint8 numTokens) public payable {
        require(saleActive && block.timestamp >= saleStartsAt, 'Sale not active');
        uint256 time = (block.timestamp);
        require(time > privatesaleStartsAt && time < privatesaleEndsAt, 'Private sale over');
        require(_waList[msg.sender].exists, 'Restricted access');
        require(!_waList[msg.sender].minted, 'Tokens minted');
        uint8 tokenLimit = _waList[msg.sender].limit;
        require(numTokens <= tokenLimit, 'Above limit');

        require(
            (_tokenIds.current() + numTokens + RESERVED_TOKEN_ID_OFFSET) <= MAX_PRIVATE_SALE_SUPPLY,
            'Private sale sold'
        );

        require(msg.value >= PRIVATE_SALE_PRICE * numTokens, 'Insufficient ETH');
        require(numTokens > 0, 'Wrong Num Token');

        for (uint8 i = 0; i < numTokens; i++) {
            _tokenIds.increment();
            _waList[msg.sender].limit = _waList[msg.sender].limit - 1;
            _safeMint(msg.sender, _tokenIds.current() + RESERVED_TOKEN_ID_OFFSET);
        }
        if (_waList[msg.sender].limit == 0) {
            _waList[msg.sender].minted = true;
        }

        emit TokenMinted(msg.sender, numTokens);
    }

    /**
     * @dev mints `numTokens` tokens of Catbotica token and assigns it to
     * `msg.sender` by calling _safeMint function.
     *
     * Emits a {TokenMinted} event.
     * Emits two {TransferSingle} events via ERC721 Contract.
     *
     * Requirements:
     * - `saleActive` must be set to true.
     * - Current timestamp must greater than or equal `saleStartsAt`.
     * - Current timestamp must within period of public sale `publicsaleStartsAt` - `publicsaleEndsAt`.
     * - Ether amount sent greater or equal the current price multipled by `numTokens`.
     * - `numTokens` within limits of max number of tokens minted in single txn.
     * - Max number of tokens for the sale not reahced
     * @param numTokens - Number of tokens to be minted
     */
    function mintPublicSale(uint8 numTokens) public payable {
        require(saleActive && block.timestamp >= saleStartsAt, 'Sale not active');
        uint256 time = (block.timestamp);
        require(time > publicsaleStartsAt && time < publicsaleEndsAt, 'Public sale over');
        uint256 currentPrice = _getCurrentPrice();
        require(msg.value >= currentPrice * numTokens, 'Insufficient ETH');
        require(numTokens <= MINT_BATCH_LIMIT && numTokens > 0, 'Wrong Num Token');
        require((_tokenIds.current() + numTokens + RESERVED_TOKEN_ID_OFFSET) <= MAX_TOKENS, 'Public sale sold');
        for (uint8 i = 0; i < numTokens; i++) {
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current() + RESERVED_TOKEN_ID_OFFSET);
        }
        emit TokenMinted(msg.sender, numTokens);
    }

    function _getCurrentPrice() internal view returns (uint256) {
        uint256 time = (block.timestamp);
        uint256 price = BOTTOM_PRICE;

        if (time > (PUBLIC_SALE_PERIOD + publicsaleStartsAt)) {
            return price;
        }
        uint256 timeSlot = (time - publicsaleStartsAt) / TICK_PERIOD;
        if (timeSlot > 0) {
            timeSlot = timeSlot - 1;
        }
        price = STARTING_PRICE - (SALE_PRICE_STEP * timeSlot);
        return price;
    }

    function getCurrentPrice() public view returns (uint256) {
        uint256 time = (block.timestamp);

        if (time < privatesaleEndsAt) {
            return PRIVATE_SALE_PRICE;
        }

        if (time > privatesaleEndsAt && time < publicsaleStartsAt) {
            return STARTING_PRICE;
        }

        return _getCurrentPrice();
    }

    /**
     * @dev Adds list of wallet addresses and their Catbotica membership card balances to whitelisted members in '_memberslist'.
     *
     * @param users - List of wallet addresses
     * @param balances - Whitelisted Users allowed balances for redeem
     * @param limits - Whitelisted Users limit in private sale
     */
    function whitelistMembers(
        address[] memory users,
        uint8[] memory balances,
        uint8[] memory limits
    ) public onlyOwner {
        require(!saleActive, 'Cant whitelist');
        for (uint16 i = 0; i < users.length; i++) {
            _waList[users[i]].exists = true;
            _waList[users[i]].balance = balances[i];
            _waList[users[i]].limit = limits[i];
        }
    }

    /**
     * @dev removes list of wallet addresses of already whitelisted members from '_walist'.
     *
     * @param users - List of wallet addresses
     */
    function removeWhitelistMembers(address[] memory users) public onlyOwner {
        for (uint8 i = 0; i < users.length; i++) {
            delete _waList[users[i]];
        }
    }

    function setBaseURI(string memory baseContractURI) public onlyOwner {
        baseURI = baseContractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseContractURI = _baseURI();
        return
            bytes(baseContractURI).length > 0
                ? string(abi.encodePacked(baseContractURI, tokenId.toString(), tokenSuffixURI))
                : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev returns the base contract metadata json object
     * this metadat file is used by OpenSea see {https://docs.opensea.io/docs/contract-level-metadata}
     *
     */
    function contractURI() public view returns (string memory) {
        string memory baseContractURI = _baseURI();
        return string(abi.encodePacked(baseContractURI, contractMetadata));
    }

    /**
     * @dev Changes the sale status 'saleActive' from active to not active and vice versa
     *
     * Only Contract Owner can execute
     *
     * Emits a {SaleStatusChange} event.
     */
    function changeSaleStatus() public onlyOwner {
        saleActive = !saleActive;
        emit SaleStatusChange(msg.sender, saleActive);
    }

    /**
     * @dev withdraws the contract balance and send it to the withdraw Addresses based on split ratio.
     *
     * Emits a {ContractWithdraw} event.
     */
    function withdraw() public nonReentrant {
        uint256 balance = address(this).balance;

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = payable(recipients[i]).call{value: (balance * splits[i]) / SPLIT_BASE}('');
            require(sent, 'Withdraw Failed.');
        }

        emit ContractWithdraw(msg.sender, balance);
    }

    /**
     * @dev Queries `_memberslist` and returns if '_address' exists or not.
     *
     * @param _address - user address
     */
    function isWhitelisted(address _address) public view returns (bool) {
        return (_waList[_address].exists);
    }

    /// @notice Calculate the royalty payment
    /// @param _salePrice the sale price of the token
    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (_salePrice * royalty) / BASE);
    }

    /// @dev set the royalty
    /// @param _royalty the royalty in base 10000, 500 = 5%
    function setRoyalty(uint16 _royalty) public onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'Royalty must be between 0% and 10%.');

        royalty = _royalty;
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external nonReentrant {
        IERC20 tokenContract = IERC20(_tokenContract);
        // transfer the token from address of Catbotica address
        uint256 balance = tokenContract.balanceOf(address(this));

        for (uint256 i = 0; i < recipients.length; i++) {
            tokenContract.transfer(recipients[i], (balance * splits[i]) / SPLIT_BASE);
        }

        emit ContractWithdrawToken(msg.sender, _tokenContract, balance);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function changeWithdrawAddress(address _recipient) external {
        require(_recipient != address(0), 'Cannot use zero address');
        require(_recipient != address(this), 'Cannot use this contract address');

        // loop over all the recipients and update the address
        bool _found = false;
        for (uint256 i = 0; i < recipients.length; i++) {
            // if the sender matches one of the recipients, update the address
            if (recipients[i] == msg.sender) {
                recipients[i] = _recipient;
                _found = true;
                break;
            }
        }
        require(_found, 'The sender is not a recipient.');
        emit WithdrawAddressChanged(msg.sender, _recipient);
    }

    function getRemPrivateSaleSupply() public view returns (uint256) {
        if (_tokenIds.current() > (MAX_PRIVATE_SALE_SUPPLY - RESERVED_TOKEN_ID_OFFSET)) return 0;
        return (MAX_PRIVATE_SALE_SUPPLY - RESERVED_TOKEN_ID_OFFSET - _tokenIds.current());
    }

    function getRemPublicSaleSupply() public view returns (uint256) {
        return (MAX_TOKENS - RESERVED_TOKEN_ID_OFFSET - _tokenIds.current());
    }

    // function getTotalPrivateSaleSupply() public pure returns (uint256) {
    //     return MAX_PRIVATE_SALE_SUPPLY;
    // }

    // function getTotalPublicSaleSupply() public pure returns (uint256) {
    //     return MAX_TOKENS;
    // }

    /*
     * Set the provenance
     *
     * Only Contract Owner can execute
     *
     */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        emit ProvenanceHashSet(msg.sender, PROVENANCE_HASH, provenanceHash);
        PROVENANCE_HASH = provenanceHash;
    }

    /*
     * Function to allow receiving ETH sent to contract
     *
     */
    receive() external payable {}

    /**
     * Override isApprovedForAll to whitelisted marketplaces to enable gas-free listings.
     *
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // check if this is an approved marketplace
        if (proxyRegistryAddress[_operator]) {
            return true;
        }
        // otherwise, use the default ERC721 isApprovedForAll()
        return super.isApprovedForAll(_owner, _operator);
    }

    /*
     * Function to set status of proxy contracts addresses
     *
     */
    function setProxy(address _proxyAddress, bool _value) public onlyOwner {
        proxyRegistryAddress[_proxyAddress] = _value;
    }
}