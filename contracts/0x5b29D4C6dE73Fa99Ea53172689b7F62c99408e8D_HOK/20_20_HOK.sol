//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';


contract HOK is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard, IERC2981 {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _redeemIds;
    Counters.Counter private _tokenIds;

    bool public saleActive = false;

    string private baseURI;
    string private tokenSuffixURI;
    string private contractMetadata = 'contract.json';
    uint256 public constant TICK_PERIOD = 30 minutes; // Time period to decrease price
    uint256 public constant PUBLIC_SALE_PERIOD = 3 hours;   // Dutch Auction Time Period
    uint256 public constant STARTING_PRICE = 200000000000000000;  // 0.2 ETH
    uint256 public constant BOTTOM_PRICE = 80000000000000000; // 0.08 ETH
    uint256 public constant SALE_PRICE_STEP = 20000000000000000; // 0.02 ETH
    uint256 public constant MINT_BATCH_LIMIT = 5; // Max number of Tokens minted in a txn
    uint256 public constant TOKEN_ID_OFFSET = 809; // Tokens reserved for Membership holders
    uint256 public saleStartsAt;
    uint256 public publicsaleStartsAt;
    uint256 public publicsaleEndsAt;
    uint256 public privatesaleStartsAt;
    uint256 public privatesaleEndsAt;
    uint256 public redemptionEndsAt;
    uint256 public constant MAX_PRIVATE_SALE_SUPPLY = 3000; // Cap for tokens to be sold in private sale is 2191 in addition to 809 for redmeption by members
    uint256 public constant MAX_TOKENS = 10000; // Max number of token sold in  sale
    address private hokWithdrawAddress = address(0xa489363add22E44f1e6B8352aBaC2db6507bbFE3);

    // schema of the member record
    struct memberRecord {
        uint8 balance;
        bool exists;
        bool redeemed;
    }

    mapping (address => memberRecord) public _memberslist;
    mapping (address => bool) public _partnerslist;

    event TokenMinted(address indexed owner, uint256 indexed quantity);
    event SaleStatusChange(address indexed issuer, bool indexed status);
    event ContractWithdraw(address indexed initiator, address indexed hokWithdrawAddress, uint256 amount);
    event WithdrawAddressChanged(address indexed initiator,address indexed previousAddress, address indexed newAddress);

    uint16 internal royalty = 500; // base 10000, 5%
    uint16 public constant BASE = 10000;

    constructor(uint256 _saleStartTime, string memory _baseContractURI, string memory _tokenSuffixURI) ERC721("GenX by HOK", "GenX") {
        baseURI = _baseContractURI;
        tokenSuffixURI = _tokenSuffixURI;
        saleStartsAt = _saleStartTime; // Unix Timestamp Sep 28, 2021 12:00:00 pm PST
        privatesaleStartsAt = saleStartsAt; // Start of Day 1, Sep 28, 2021 12:00:00 pm PST
        privatesaleEndsAt = saleStartsAt + 24 hours; // End of Day 1, Sep 29, 2021 11:59:59 am PST
        publicsaleStartsAt = saleStartsAt + 48 hours;  // Start of Day 3, Sep 30, 2021 12:00:00 pm PST
        publicsaleEndsAt = saleStartsAt + 72 hours;  // End of Day 3, Oct 1, 2021 11:59:59 am PST
        redemptionEndsAt = saleStartsAt + 30 days;    // Oct 28, 2021 12:00:00 pm PST, End of period for members to redeem from the 809 free tokens
    }

    function mintNFT(address recipient, uint256 numTokens)
        public onlyOwner
    {
        uint256 time = (block.timestamp);
        require(time > privatesaleEndsAt && time < publicsaleStartsAt, "Not Day 2");
        require((_tokenIds.current() + numTokens+TOKEN_ID_OFFSET) <= MAX_PRIVATE_SALE_SUPPLY, "Private sale over");
        for(uint256 i = 0; i < numTokens; i++){
            _tokenIds.increment();
            _safeMint(recipient, _tokenIds.current() + TOKEN_ID_OFFSET);
        }
        emit TokenMinted(recipient, numTokens);
    }

    function claimUnredeemed(address recipient, uint256 numTokens)
        public onlyOwner
    {
        uint256 time = (block.timestamp);
        require(time > redemptionEndsAt, "Redemption still active");
        require((_redeemIds.current()+numTokens) <= TOKEN_ID_OFFSET, "Tokens Redeemed");
        for(uint256 i = 0; i < numTokens; i++){
            _redeemIds.increment();
            _safeMint(recipient, _redeemIds.current() );
        }
        emit TokenMinted(recipient, numTokens);
    }

    /**
     * @dev mints equivalent of `msg.sender` whitelisted balance of HOK token and assigns it to
     * `msg.sender` by calling _safeMint function. Dedicated for free redemotion for HOK members.
     *
     * Emits a {TokenMinted} event.
     * Emits two {TransferSingle} events via ERC721 Contract.
     *
     * Requirements:
     * - `saleActive` must be set to true.
     * - Current timestamp must greater than or equal `saleStartsAt`.
     * - `msg.sender` is among whitelisted HOK memebrs and hasn't redeemed the token before.
     * - Max number of tokens assigned for free redemption not reahced
     */
    function memberRedeem()
        public
    {
        require(block.timestamp >= saleStartsAt && block.timestamp < redemptionEndsAt, "Redeem not active");
        uint256 userBalance = _memberslist[msg.sender].balance;
        require((_redeemIds.current()) + userBalance <= TOKEN_ID_OFFSET, "Tokens Redeemed");
        require(_memberslist[msg.sender].exists,"Restricted access");
        require(!_memberslist[msg.sender].redeemed,"Tokens redeemed");
        _memberslist[msg.sender].redeemed = true;
        for(uint256 i = 0; i < userBalance; i++){
            _redeemIds.increment();
            _safeMint(msg.sender, _redeemIds.current());
        }
        emit TokenMinted(msg.sender, userBalance);
    }

    /**
     * @dev mints `numTokens` tokens of HOK token and assigns it to
     * `msg.sender` by calling _safeMint function.
     *
     * Emits a {TokenMinted} event.
     * Emits two {TransferSingle} events via ERC721 Contract.
     *
     * Requirements:
     * - `saleActive` must be set to true.
     * - Current timestamp must greater than or equal `saleStartsAt`.
     * - Current timestamp must within period of private sale `privatesaleStartsAt` - `privatesaleEndsAt`.
     * - `msg.sender` is among whitelisted HOK memebrs or partners
     * - Ether amount sent greater or equal the base price multipled by `numTokens`.
     * - `numTokens` within limits of max number of tokens minted in single txn.
     * - Max number of tokens for the private sale not reahced
     * @param numTokens - Number of tokens to be minted
     */
    function mintPrivateSale(uint256 numTokens)
        public payable
    {
        require(saleActive && block.timestamp >= saleStartsAt, "Sale not active");
        uint256 time = (block.timestamp);
        require(time > privatesaleStartsAt && time < privatesaleEndsAt, "Private sale over");
        require(_memberslist[msg.sender].exists || _partnerslist[msg.sender],"Restricted access");

        require((_tokenIds.current() + numTokens+TOKEN_ID_OFFSET) <= MAX_PRIVATE_SALE_SUPPLY, "Private sale sold");

        require(msg.value >= BOTTOM_PRICE * numTokens, "Insuffiecint Eth");
        require(numTokens <= MINT_BATCH_LIMIT && numTokens > 0, "Wrong Num Token");

        for(uint256 i = 0; i < numTokens; i++){
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current() + TOKEN_ID_OFFSET);
        }
        emit TokenMinted(msg.sender, numTokens);
    }

    /**
     * @dev mints `numTokens` tokens of HOK token and assigns it to
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
    function mintPublicSale(uint256 numTokens)
        public payable
    {
        require(saleActive && block.timestamp >= saleStartsAt, "Sale not active");
        uint256 time = (block.timestamp);
        require(time > publicsaleStartsAt && time < publicsaleEndsAt, "Public sale over");
        uint256 currentPrice = _getCurrentPrice();
        require(msg.value >= currentPrice * numTokens, "Insuffiecint Eth");
        require(numTokens <= MINT_BATCH_LIMIT && numTokens > 0, "Wrong Num Token");
        require((_tokenIds.current() + numTokens+TOKEN_ID_OFFSET) <= MAX_TOKENS, "Public sale sold");
        for(uint256 i = 0; i < numTokens; i++){
            _tokenIds.increment();
            _safeMint(msg.sender, _tokenIds.current() + TOKEN_ID_OFFSET);
        }
        emit TokenMinted(msg.sender, numTokens);
    }

    function _getCurrentPrice() internal view returns (uint256 ){
        uint256 time = (block.timestamp);
    	uint256 price = BOTTOM_PRICE;
        if(time > (PUBLIC_SALE_PERIOD + publicsaleStartsAt)) {
            return price;
        }
        uint256 timeSlot = (time-publicsaleStartsAt) / TICK_PERIOD;
        price = STARTING_PRICE - (SALE_PRICE_STEP * timeSlot);
    	return price;
    }

    function getCurrentPrice() public view returns (uint256 ){
        uint256 time = (block.timestamp);
    	if(time < publicsaleStartsAt) {
            return BOTTOM_PRICE;
        }
        return _getCurrentPrice();
    }

    /**
     * @dev function that overrides safeTransferFrom to ensure no transfer till sale is over
     * see {IERC721-safeTransferFrom}.
     * Requirements:
     * - `saleActive` must be set to false.
     */
    function safeTransferFrom( address from, address to, uint256 id, bytes memory _data)
        public virtual override
    {
        require(!saleActive,"No Transfer during sale");
        super.safeTransferFrom(from,to,id, _data);
    }

    /**
     * @dev function that overrides safeTransferFrom to ensure no transfer till sale is over
     * see {IERC721-safeTransferFrom}.
     * Requirements:
     * - `saleActive` must be set to false.
     */
    function safeTransferFrom( address from, address to, uint256 id)
        public virtual override
    {
        require(!saleActive,"No Transfer during sale");
        super.safeTransferFrom(from,to,id);
    }

    /**
     * @dev function that overrides safeTransferFrom to ensure no transfer till sale is over
     * see {IERC721-transferFrom}.
     * Requirements:
     * - `saleActive` must be set to false.
     */
    function transferFrom( address from, address to, uint256 id)
        public virtual override
    {
        require(!saleActive,"No Transfer during sale");
        super.transferFrom(from,to,id);
    }

    /**
     * @dev Adds list of wallet addresses and their HOK membership card balances to whitelsited members in '_memberslist'.
     *
     * @param users - List of wallet addresses
     * @param balances - Users HOK membership card balances
     */
    function whitelistMembers (address[] memory users, uint8[] memory balances) public onlyOwner {
        require(!saleActive, "Cant whitelist");
        for (uint i = 0; i < users.length; i++) {
            _memberslist[users[i]].exists = true;
            _memberslist[users[i]].balance = balances[i];
        }
    }

    /**
     * @dev Adds list of wallet addresses to whitelsited partenrs in '_partnerslist'.
     *
     * @param users - List of wallet addresses
     */
    function whitelistPartners (address[] memory users) public onlyOwner {
        require(!saleActive, "Cant whitelist");
        for (uint i = 0; i < users.length; i++) {
            _partnerslist[users[i]] = true;
        }
    }

    /**
     * @dev removes list of wallet addresses of already whitelsited members from '_memberslist'.
     *
     * @param users - List of wallet addresses
     */
    function removeWhitelistMembers (address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            delete _memberslist[users[i]];
        }
    }

    /**
     * @dev removes list of wallet addresses of already whitelsited partners from '_partnerslist'.
     *
     * @param users - List of wallet addresses
     */
    function removeWhitelistPartners (address[] memory users) public onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            delete _partnerslist[users[i]];
        }
    }

    function setBaseURI(string memory baseContractURI) public onlyOwner {
       baseURI = baseContractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseContractURI = _baseURI();
        return bytes(baseContractURI).length > 0 ? string(abi.encodePacked(baseContractURI, tokenId.toString(), tokenSuffixURI)) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
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
     * @dev withdraws the specified '_amount' from contract balance and send it to the withdraw Addresses based on split ratio.
     *
     * Emits a {ContractWithdraw} event.
     * @param _amount - Amount to be withdrawn
     */
    function withdraw(uint256 _amount) public nonReentrant {
        require(msg.sender == hokWithdrawAddress, "Not allowed");

        uint256 balance = address(this).balance;
        require(_amount <= balance,"Insufficient funds");

        bool success;
        (success, ) = payable(hokWithdrawAddress).call{value: _amount}('');
        require(success, 'Withdraw Failed');

        emit ContractWithdraw(msg.sender, hokWithdrawAddress, _amount);
    }

    /**
     * @dev Queries `_memberslist` and returns if '_address' exists or not.
     *
     * @param _address - user address
     */
    function isWhitelisted(address _address) public view returns(bool) {
        return (_memberslist[_address].exists || _partnerslist[_address]);
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
    function setRoyalty(uint16 _royalty) public virtual onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'Royalty must be between 0% and 10%.');

        royalty = _royalty;
    }

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of hok address
        uint256 _amount = tokenContract.balanceOf(address(this));
        tokenContract.transfer(hokWithdrawAddress, _amount);

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable,IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function changeWithdrawAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0),'Non Zero Address');
        emit WithdrawAddressChanged(msg.sender, hokWithdrawAddress, _newAddress);
        hokWithdrawAddress = _newAddress;
    }

    function getRemPrivateSaleSupply() public view returns (uint256) {
        return (MAX_PRIVATE_SALE_SUPPLY - TOKEN_ID_OFFSET - _tokenIds.current() );
    }

    function getRemPublicSaleSupply() public view returns (uint256) {
        return (MAX_TOKENS - TOKEN_ID_OFFSET -  _tokenIds.current() );
    }

}