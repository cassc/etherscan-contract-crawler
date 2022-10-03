// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EIP712Upgradeable.sol";

contract KindeckGenesis is  
    EIP712Upgradeable,
    OwnableUpgradeable,
    ERC1155Upgradeable
{
    // whitelist setup
    using ECDSA for bytes32;
    bytes32 public constant PRESALE_TYPEHASH = keccak256("Presale(address buyer,uint256 maxCount,uint8 tier)");

    mapping(uint256 => string) public uris;

    // keep track of those on whitelist claiming
    // address -> tier -> number of claimed tokens
    mapping(address => mapping(uint8 => uint256 ) ) public claimed;

    // The key used to sign whitelist signatures.
    address whitelistSigner;

    enum ProtocolState{
        PAUSE, // locked mode to prepare and setup another things
        WHITELIST, // whitelist open for minting
        PUBLIC // public minting open
    }
    ProtocolState private _state;
   
    // basic nft setup
    string private _collectionURI;

    // payment setup
    IERC20 public tokenPayment;

    /**
     * @notice A struct containing the parameters required for defining the tiers
     *  
     * @param tierName The tier ID.
     * @param tier The profile token ID to point the mirror to.
     * @param whitelistSupply whitelist current amounts
    //  * @param whitelistMaxSupply whitelist total amounts - fixed 
     * @param WHITELIST_SALE_PRICE whitelist price
     * @param tierTotalSupply current total supply including whitelist
     * @param PUBLIC_SALE_PRICE normal price
     @ @param tokensMinted number of currenty minted tokens in this tier
     * @param isPrivate flag if tier is private
     */
    struct TiersData {
        string tierName;
        uint256 tier;

        uint256 whitelistSupply;
        uint256 WHITELIST_SALE_PRICE;

        uint256 tierSupply;
        uint256 PUBLIC_SALE_PRICE;

        uint256 tokensMinted;
        bool isPrivate;
    }
    mapping(uint8 => TiersData) public tierLevel;

    event StateSet(address owner, ProtocolState prevState, ProtocolState newState, uint time);
    event SetToken(address owner, IERC20 prevToken, IERC20 newToken, uint time);
    event ClaimedWL(address indexed user, uint amount, uint tier, uint time);
    event PublicMint(address indexed user, uint amount, uint tier, uint time);
    event Gift(address indexed user, uint amount, uint tier, uint time);
    event ChangePrice(address owner, uint8 tier, uint prevPrice, uint updatedPrice, uint time);
    event WhitelistSignerSettled(address oldSigner, address newSigner);

    string public name;
    string public symbol;
 
    function initialize(
        string memory _nameEIP712,
        string memory _name,
        string memory _symbol,
        string memory collectionURI, 
        address _whitelistSigner,
        address _tokenPaymentAddress
    ) public initializer   {
        __ERC1155_init("");
        __EIP712_init(_nameEIP712, "1.0.0");
        __Ownable_init();

        setCollectionURI(collectionURI);
        name = _name;
        symbol = _symbol;
        tokenPayment = IERC20(_tokenPaymentAddress);
        whitelistSigner = _whitelistSigner;
        _state = ProtocolState.PAUSE;

        setTierLevel(1, TiersData({
            tierName: "founders", 
            tier: 1, 
            whitelistSupply: 0, 
            WHITELIST_SALE_PRICE: 0, 
            tierSupply: 555, 
            PUBLIC_SALE_PRICE: 0,
            tokensMinted: 0,
            isPrivate: true
        }) );

        setTierLevel(2, TiersData({
            tierName: "legendary", 
            tier: 2, 
            whitelistSupply: 250, 
            WHITELIST_SALE_PRICE: 0.1 ether,  
            tierSupply: 777, 
            PUBLIC_SALE_PRICE: 1 ether,
            tokensMinted: 0,
            isPrivate: false
        }) );

        setTierLevel(3, TiersData({
            tierName: "epic", 
            tier: 3, 
            whitelistSupply: 200,  
            WHITELIST_SALE_PRICE: 0.2 ether, 
            tierSupply: 888, 
            PUBLIC_SALE_PRICE: 2 ether,
            tokensMinted: 0,
            isPrivate: false
        }) );

        setTierLevel(4, TiersData({
            tierName: "rare", 
            tier: 4, 
            whitelistSupply: 150,  
            WHITELIST_SALE_PRICE: 0.3 ether, 
            tierSupply: 2222, 
            PUBLIC_SALE_PRICE: 3 ether,
            tokensMinted: 0,
            isPrivate: false
        }) );

        setTierLevel(5, TiersData({
            tierName: "tranche", 
            tier: 5, 
            whitelistSupply: 50, 
            WHITELIST_SALE_PRICE: 0.4 ether , 
            tierSupply: 20000, 
            PUBLIC_SALE_PRICE: 4 ether,
            tokensMinted: 0,
            isPrivate: true
        }) );
    }

    // ============ INTERNAL ============

    // todo: refactor minting as internal
    function _hash(address _buyer, uint256 _maxCount, uint8 _level) internal view returns(bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            PRESALE_TYPEHASH,
            _buyer,
            _maxCount,
            _level
        )));
    }

    function _verify(bytes32 _digest, bytes memory _signature) internal view returns(bool) {
        return ECDSA.recover(_digest, _signature) == whitelistSigner;
    }

    function setTierLevel(uint8 _level, TiersData memory _detailData ) internal {
        tierLevel[_level] = _detailData;
    }

    // ============ PUBLIC FUNCTIONS FOR MINTING ============
    function whitelistMint( 
        uint256 _numberOfTokens,
        uint8 _level,
        bytes calldata _signature
    ) 
        public
        payable
    {
        require(_numberOfTokens > 0, "The amount is 0"); 
        require(_state == ProtocolState.WHITELIST, "Whitelist minting is not open");
        require(whitelistSigner != address(0), "Signer is default address!");
        require(_verify(_hash(msg.sender, _numberOfTokens, _level ), _signature), "The Signature is invalid!");
        require(claimed[msg.sender][_level] == 0, "Token is already claimed");

        require(tierLevel[_level].isPrivate == false, "Exclusive tier");
        require(_numberOfTokens < getTierWhitelistSupplyLeft(_level), "Not enough tokens remaining to mint");
        
        uint mintPrice = _numberOfTokens * tierLevel[_level].WHITELIST_SALE_PRICE;
        require(mintPrice == msg.value, "Incorrect ETH value sent" );

        tierLevel[_level].tokensMinted += _numberOfTokens;
        _mint(msg.sender, _level, _numberOfTokens, "");

        claimed[msg.sender][_level] = _numberOfTokens;
        emit ClaimedWL(msg.sender, _numberOfTokens, _level, block.timestamp);
    }

    function freeMint(uint256 _numberOfTokens, uint8 _level ) public payable {
        require(_numberOfTokens > 0, "The amount is 0"); 
        require(_state == ProtocolState.PUBLIC, "Public minting is not open");
        require(tierLevel[_level].isPrivate == false, "Exclusive tier");
        require(_numberOfTokens < getTierTotalSupplyLeft(_level), "Not enough tokens remaining to mint");

        uint mintPrice = _numberOfTokens * tierLevel[_level].PUBLIC_SALE_PRICE;
        require(mintPrice == msg.value, "Incorrect ETH value sent" );

        tierLevel[_level].tokensMinted += _numberOfTokens;
        _mint(msg.sender, _level, _numberOfTokens, "");

        emit PublicMint(msg.sender, _numberOfTokens, _level, block.timestamp);
    }

    // ============ PUBLIC READ-ONLY FUNCTIONS ============
    /**
     * @dev Returns the current protocol state.
     */
    function getState() external view returns (ProtocolState) {
        return _state;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return uris[id];
    }

    /**
    * @dev collection URI for marketplace display
    */
    function contractURI() public view returns (string memory) {
        return _collectionURI;
    }

    // for testing, might remove
    function getTierDetail(uint8 _level) public view returns (TiersData memory){
        // should return detail
        return  tierLevel[_level];
    }

    function getTierWhitelistSupplyLeft(uint8 _level) public view returns(uint256) {
        return tierLevel[_level].whitelistSupply - tierLevel[_level].tokensMinted;
    }

    function getTierTotalSupplyLeft(uint8 _level) public view returns(uint256) {
        return tierLevel[_level].tierSupply - tierLevel[_level].tokensMinted;
    }


    // ============ OWNER-ONLY ADMIN FUNCTIONS ============
    function setStatusContract(ProtocolState newState) public onlyOwner {
        ProtocolState prevState = _state;
        _state = newState;
        emit StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function setTokenPayment(IERC20 _tokenPaymentAddress) public onlyOwner {
        IERC20 prevToken = tokenPayment;
        tokenPayment = IERC20(_tokenPaymentAddress);
        emit SetToken(msg.sender, prevToken, _tokenPaymentAddress, block.timestamp);

    }

    function setTokenURI(uint256 id, string memory uri_) external onlyOwner {
        uris[id] = uri_;
    }

    /**
    * @dev set collection URI for marketplace display
    */
    function setCollectionURI(string memory collectionURI) public virtual onlyOwner {
        _collectionURI = collectionURI;
    }

    /** @notice change Token Name
     *  @param _name new name
     */
    function setName(string memory _name) external onlyOwner {
        name = _name;
    }

    /** @notice change Token Symbol
     *  @param _symbol new symbol
     */
    function setSymbol(string memory _symbol) external onlyOwner {
        symbol = _symbol;
    }

    /**
    * @dev set whitelistSigner
    */
    function setWhitelistSigner(address  _whitelistSigner) external onlyOwner {
        require(_whitelistSigner != whitelistSigner, "Signer is still the same!");
        
        address prevSigner = whitelistSigner;
        whitelistSigner = _whitelistSigner;

        emit WhitelistSignerSettled(prevSigner, _whitelistSigner);
    }

    function setTierIsPrivate(uint8 _level, bool _isPrivate) external onlyOwner {
        tierLevel[_level].isPrivate = _isPrivate;
    }

    function updatePrice(uint8 _level, uint _price, bool _isWhitelist) external onlyOwner {
        uint prevPrice;
        if(_isWhitelist){
            prevPrice = tierLevel[_level].WHITELIST_SALE_PRICE ;
            tierLevel[_level].WHITELIST_SALE_PRICE = _price;
        }else{
            prevPrice = tierLevel[_level].PUBLIC_SALE_PRICE ;
            tierLevel[_level].PUBLIC_SALE_PRICE = _price;
        }
        emit ChangePrice(msg.sender, _level, prevPrice, _price, block.timestamp);
    }

    // mostly for private tier 1, but can be used for others by owner
    function gift(
        address[] calldata receivers, 
        uint256[] calldata amounts, 
        uint8 _level
    ) external onlyOwner {
        require(receivers.length == amounts.length, "Arrays length must be equal");

        for (uint256 i = 0; i < receivers.length; i++) {
            require(amounts[i] < tierLevel[_level].tierSupply - tierLevel[_level].tokensMinted, "Receivers are more than the current supply");
            tierLevel[_level].tokensMinted += amounts[i];

            _mint(receivers[i], _level, amounts[i], "");
            emit Gift(receivers[i], amounts[i], _level, block.timestamp);
        }
    }

    /**
     * @dev withdraw funds for to specified account
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}