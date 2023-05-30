pragma solidity 0.8.4;
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';


contract PocketDimension is ERC721A, Ownable, Pausable, ReentrancyGuard, IERC2981 {

    using Strings for uint256;
    using Strings for uint8;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    mapping (uint256 => uint256) public _tokens;
    mapping (uint256 => uint256) public _landTypeCounter;

    bool public saleActive = false;
    string private baseURI;
    string private tokenSuffixURI;
    string private contractMetadata = 'contract.json';

    uint256 public constant TICK_PERIOD = 45 minutes; // Time period to decrease price
    uint256 public constant PUBLIC_SALE_PERIOD = 225 minutes;   // Dutch Auction Time Period
    uint256 public constant STARTING_PRICE = 2000000000000000000;  // 2 ETH
    uint256 public constant BOTTOM_PRICE = 1000000000000000000; // 1 ETH
    uint256 public constant SALE_PRICE_STEP = 200000000000000000; // 0.2 ETH
    uint256 public constant MINT_BATCH_LIMIT = 5; // Max number of Tokens minted in a txn
    

    event TokenMinted(address indexed owner, uint256 indexed landType, uint256 indexed quantity);
    event SaleStatusChange(address indexed issuer, bool indexed status);
    event ContractWithdraw(address indexed initiator, address indexed hokWithdrawAddress, uint256 amount);
    event WithdrawAddressChanged(address indexed initiator, address indexed previousAddress, address indexed newAddress);
    event SaleAddressChanged(address indexed initiator, address indexed previousAddress, address indexed newAddress);
    event MinterAddressChanged(address indexed initiator, address indexed previousAddress, address indexed newAddress);

    uint16 internal royalty = 500; // base 10000, 5%
    uint16 public constant BASE = 10000;
    
    uint256 public saleStartsAt;
    uint256 public publicsaleStartsAt;
    uint256 public publicsaleEndsAt;
    uint256 public privatesaleStartsAt;
    uint256 public privatesaleEndsAt;
    
    uint256 public constant MAX_PRIVATE_SALE_SUPPLY = 10000;
    uint256 public constant MAX_TOKENS = 10000; // Max number of token sold in  sale
    uint256 public constant MAX_INTERNAL_SUPPLY = 235;
    address private hokWithdrawAddress;
    address private hokMinterAddress;

    uint256 MAX_PRIVATE_LAND_SALE_PER_TYPE = 1000; // max private land sale
    uint256 MAX_PUBLIC_LAND_SALE_PER_TYPE = 1000; // max public land sale


    struct memberRecord {
        uint8 balance;
        bool exists;
        bool redeemed;
        uint8 minted;
    }

    mapping (address => memberRecord) public _memberslist;

    constructor(string memory _baseContractURI, string memory _tokenSuffixURI, uint256 _saleStartTime) ERC721A("Pocket Dimension Earth", "PDE") {
        baseURI = _baseContractURI;
        tokenSuffixURI = _tokenSuffixURI;

        saleStartsAt = _saleStartTime; // Unix Timestamp April 16, 2022 09:00:00 pm PST
        privatesaleStartsAt = saleStartsAt; // Start of Day 1, April 16, 2022 09:00:00 pm PST
        privatesaleEndsAt = saleStartsAt + 24 hours; // End of Day 1, April 17, 2022 08:59:59 am PST
        publicsaleStartsAt = saleStartsAt + 24 hours;  // Start of Day 2, April 17, 2022 09:00:00 pm PST
        publicsaleEndsAt = saleStartsAt + 48 hours;  // End of Day 2, April 18, 2022 08:59:59 am PST
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
     * - `landType` type of land for mint
     * - Max number of tokens for the private sale not reached
     * @param landType - Type of land
     * @param numTokens - Number of tokens to be minted
     */
    function mintPrivateSale(uint8 landType, uint256 numTokens)
        external payable
    {        
        require(saleActive && block.timestamp >= saleStartsAt, "Sale not active");
        uint256 time = (block.timestamp);
        require(time > privatesaleStartsAt && time < privatesaleEndsAt, "Private sale over");
        require(_memberslist[msg.sender].exists, "Restricted access");
        require(_memberslist[msg.sender].minted + numTokens < _memberslist[msg.sender].balance, "User mint over allowed number"); // fix PPS-02
        require(landType > 0 && landType < 11, "Invalid Land type");

        require(_landTypeCounter[landType] + numTokens < MAX_PRIVATE_LAND_SALE_PER_TYPE + 1, "Sold out");
        
        require((_tokenIds.current() + numTokens) <= MAX_PRIVATE_SALE_SUPPLY, "Private sale sold out");

        require(msg.value >= BOTTOM_PRICE * numTokens, "Insufficient Eth");
        require(numTokens <= MINT_BATCH_LIMIT && numTokens > 0, "Wrong token number");

        for(uint256 i = 0; i < numTokens; i++){
            _tokens[_tokenIds.current()] = landType;
            _tokenIds.increment();

            _memberslist[msg.sender].minted += 1;
        }
        _landTypeCounter[landType] += numTokens;
        _safeMint(msg.sender, numTokens);
        emit TokenMinted(msg.sender, landType, numTokens);
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
    function mintPublicSale(uint8 landType, uint256 numTokens)
        external payable
    {
        require(saleActive && block.timestamp >= saleStartsAt, "Sale not active");
        uint256 time = (block.timestamp);
        require(time > publicsaleStartsAt && time < publicsaleEndsAt, "Public sale over");
        require(landType > 0 && landType < 11, "Invalid Land type");
        
        require(_landTypeCounter[landType] + numTokens < MAX_PUBLIC_LAND_SALE_PER_TYPE + 1, "Sold out");
        
        uint256 currentPrice = _getCurrentPrice();
        require(msg.value >= currentPrice * numTokens, "Insufficient Eth");
        require(numTokens <= MINT_BATCH_LIMIT && numTokens > 0, "Wrong token number");
        require((_tokenIds.current() + numTokens) <= MAX_TOKENS, "Public sale sold out");
        for(uint256 i = 0; i < numTokens; i++){
            _tokens[_tokenIds.current()] = landType;
            _tokenIds.increment();
        }
        _landTypeCounter[landType] += numTokens;
        _safeMint(msg.sender, numTokens);
        emit TokenMinted(msg.sender, landType, numTokens);
    }

    function _getCurrentPrice() internal view returns (uint256 ){
        uint256 time = (block.timestamp);
    	uint256 price = BOTTOM_PRICE;
        if(time > (PUBLIC_SALE_PERIOD + publicsaleStartsAt)) {
            return price;
        }
        uint256 timeSlot = (time-publicsaleStartsAt) / TICK_PERIOD;
        price = STARTING_PRICE - (SALE_PRICE_STEP * timeSlot);
        price = BOTTOM_PRICE > price ? BOTTOM_PRICE : price;
    	return price;
    }

    function getCurrentPrice() external view returns (uint256 ){
        uint256 time = (block.timestamp);
    	if(time < publicsaleStartsAt) {
            return BOTTOM_PRICE;
        }
        return _getCurrentPrice();
    }

    /**
     * @dev mints `numTokens` tokens of HOK token and assigns it to
     * `msg.sender` by calling _safeMint function.
     *
     * Emits a {TokenMinted} event.
     * Emits two {TransferSingle} events via ERC721 Contract.
     *
     * Requirements:
     * - Current timestamp must before the start of private sale `privatesaleStartsAt`.
     * - `msg.sender` is hokMinterAddress
     * - `numTokens` within limits of max number of tokens minted in single txn.
     * - `landType` type of land for mint
     * - Max number of tokens for the private sale not reached
     * @param landType - Type of land
     * @param numTokens - Number of tokens to be minted
     */
    function mintInternal(uint8 landType, uint256 numTokens)
        external 
    {
     
        uint256 time = (block.timestamp);
        require(time < privatesaleStartsAt, "Can only mint before private sale");
        require(msg.sender == hokMinterAddress, "Not allowed");
        
        require(landType > 0 && landType < 11, "Invalid Land type");
        
        require(_landTypeCounter[landType] + numTokens < MAX_PRIVATE_LAND_SALE_PER_TYPE + 1, "Sold out");

        require((_tokenIds.current() + numTokens) <= MAX_INTERNAL_SUPPLY, "Maximum number reached");


        for(uint256 i = 0; i < numTokens; i++){
            _tokens[_tokenIds.current()] = landType;
            _tokenIds.increment();
        }
        _landTypeCounter[landType] += numTokens;
        _safeMint(msg.sender, numTokens);
        emit TokenMinted(msg.sender, landType, numTokens);
    }

    /**
     * @dev mints `numTokens` tokens of HOK token and assigns it to
     * `msg.sender` by calling _safeMint function.
     *
     * Emits a {TokenMinted} event.
     * Emits two {TransferSingle} events via ERC721 Contract.
     *
     * Requirements:
     * - Current timestamp must greater than  `publicsaleEndsAt`.
     * - `numTokens` within limits.
     * - Max number of tokens for the sale not reahced
     * @param numTokens - Number of tokens to be minted
     */
    function mintAfterSale(uint8 landType, uint256 numTokens)
        external onlyOwner
    {
        require(block.timestamp > publicsaleEndsAt, "Cannot mint");
        require(landType > 0 && landType < 11, "Invalid Land type");
        
        require(_landTypeCounter[landType] + numTokens < MAX_PUBLIC_LAND_SALE_PER_TYPE + 1, "Sold out");
        
        require(numTokens > 0, "Wrong token number");
        require((_tokenIds.current() + numTokens) <= MAX_TOKENS, "Public sale sold out");
        for(uint256 i = 0; i < numTokens; i++){
            _tokens[_tokenIds.current()] = landType;
            _tokenIds.increment();
        }
        _landTypeCounter[landType] += numTokens;
        _safeMint(msg.sender, numTokens);
        emit TokenMinted(msg.sender, landType, numTokens);
    }

    /**
     * @dev Adds list of wallet addresses and their HOK membership card balances to whitelisted members in '_memberslist'.
     *
     * @param users - List of wallet addresses
     * @param balances - Users HOK membership card balances
     */
    // function whitelistMembers (address[] memory users, uint8[] memory balances) public onlyOwner {
    function whitelistMembers (address[] memory users, uint8[] memory balances) external onlyOwner {
        require(!saleActive, "Cannot whitelist");
        uint256 time = (block.timestamp);
        require(time < saleStartsAt, "Cannot modify after private sale start");

        for (uint i = 0; i < users.length; i++) {
            _memberslist[users[i]].exists = true;
            _memberslist[users[i]].balance = balances[i];
            _memberslist[users[i]].minted = 0;
        }
    }

    /**
     * @dev removes list of wallet addresses of already whitelisted members from '_memberslist'.
     *
     * @param users - List of wallet addresses
     */
    function removeWhitelistMembers (address[] memory users) external onlyOwner {
        for (uint i = 0; i < users.length; i++) {
            delete _memberslist[users[i]];
        }
    }

    /**
     * @dev Queries `_memberslist` and returns if '_address' exists or not.
     *
     * @param _address - user address
     */
    function isWhitelisted(address _address) external view returns(bool) {
        // return (_memberslist[_address].exists || _partnerslist[_address]);
        return _memberslist[_address].exists;
    }

    function getPrivateRemLandType(uint256 landType) public view returns (uint256) {
        require(landType > 0 && landType < 11, "Invalid Land type");
        return MAX_PRIVATE_LAND_SALE_PER_TYPE - _landTypeCounter[landType];
    }

    function getPublicRemLandType(uint256 landType) public view returns (uint256) {
        require(landType > 0 && landType < 11, "Invalid Land type");
        return MAX_PUBLIC_LAND_SALE_PER_TYPE - _landTypeCounter[landType];
    }


    function getRemPrivateSaleSupply() public view returns (uint256) {
        return (MAX_PRIVATE_SALE_SUPPLY - _tokenIds.current() );
        // return (MAX_TOKENS - _tokenIds.current() );
    }

    function getRemPublicSaleSupply() public view returns (uint256) {
        return (MAX_TOKENS - _tokenIds.current() );
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


    function setBaseURI(string memory baseContractURI) external onlyOwner {
       baseURI = baseContractURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseContractURI = _baseURI();
        
        // TODO: change URI based on the _tokens landType, for now keep this
        return bytes(baseContractURI).length > 0 ? string(abi.encodePacked(baseContractURI, '/', _tokens[tokenId].toString(), '/', tokenId.toString(), tokenSuffixURI)) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev returns the base contract metadata json object
     * this metadata file is used by OpenSea see {https://docs.opensea.io/docs/contract-level-metadata}
     *
     */
    function contractURI() external view returns (string memory) {
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
    function changeSaleStatus() external onlyOwner{
        // require(msg.sender == saleContractAdddress, "Not Allowed");
        saleActive = !saleActive;
        emit SaleStatusChange(msg.sender, saleActive);
    }

    function getSaleStatus() external view returns(bool) {
        return saleActive;
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

    /// @dev withdraw ERC20 tokens divided by splits
    function withdrawTokens(address _tokenContract) external onlyOwner nonReentrant {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of hok address
        uint256 _amount = tokenContract.balanceOf(address(this));

        tokenContract.transfer(hokWithdrawAddress, _amount);
    }

    /**
     * @dev Change the address that can withdraw the ETH.
     *
     * Emits a {WithdrawAddressChanged} event.
     * @param _newAddress - Address to be withdrawed to
     */
    function changeWithdrawAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0),'Non Zero Address');
        emit WithdrawAddressChanged(msg.sender, hokWithdrawAddress, _newAddress);
        hokWithdrawAddress = _newAddress;
    }

    /**
     * @dev Change the address that can call the mint internal function.
     *
     * Emits a {MinterAddressChanged} event.
     * @param _minterAdress - Address of minter
     */
    function changeHoKMinterAddress(address _minterAdress) public onlyOwner {
        require(_minterAdress != address(0),'Non Zero Address');
        emit MinterAddressChanged(msg.sender, hokMinterAddress, _minterAdress);
        hokMinterAddress = _minterAdress;
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
    function setRoyalty(uint16 _royalty) external virtual onlyOwner {
        require(_royalty >= 0 && _royalty <= 1000, 'Royalty must be between 0% and 10%.');

        royalty = _royalty;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A,IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}