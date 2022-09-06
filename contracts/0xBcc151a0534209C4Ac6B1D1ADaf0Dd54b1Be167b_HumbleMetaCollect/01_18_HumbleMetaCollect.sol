// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./EIP712FileSignature.sol";

contract HumbleMetaCollect is Ownable, ERC721, ReentrancyGuard, EIP712FileSignature {
    using Counters for Counters.Counter;

    event HasMinted(uint256 _tokenId, bytes _signature, string _dataId);

    string public metadataServiceAccount;

    uint256 public MAX_SUPPLY;
    mapping(string => uint256) maxSupplyForDataId;
    mapping(string => uint256) tokenCounterForDataId;

    uint256 public MINT_PRICE;
    mapping(string => uint256) mintPriceForDataId;

    bool public saleIsActive;
    bool public groupSaleIsActive;
    uint256 public activeGroupId;

    Counters.Counter private groupCounter;
    Counters.Counter private tokenCounter;

    string private customBaseURI;
    string private customContractURI;

    PaymentSplitter private paymentSplitter;
    
    mapping(address => uint256[]) groupsForOwner;
    mapping(uint256 => mapping(address => uint256)) ownersForGroup;
    mapping(uint256 => address) managerForGroup;
    mapping(uint256 => uint256[]) tokensForGroup;
    mapping(uint256 => uint256[]) derivativeTokensForGroup;
    mapping(uint256 => bytes) filesSignatureForToken;
    
    modifier onlyGroupOwner(uint256 _groupId) {
        require(ownersForGroup[_groupId][msg.sender] > 0, "Sender does not own group");
        _;
    }

    modifier onlyGroupManager(uint256 _groupId) {
        require(managerForGroup[_groupId] == msg.sender, "Sender is not group manager");
        _;
    }

    /**
     * Constructor
     * @param _name Name of the NFT token
     * @param _symbol Symbol of the NFT token
     * @param baseURI_ The root metadata URL
     * @param _metadataServiceAccount The Google Cloud service account which is the only approved metadata file uploader
     * @param _mintPrice The value paid to use mint functions
     * @param _payees The wallet addresses who are allowed to be payed out
     * @param _shares The shares applied to each wallet address
     */
    constructor(string memory _name, string memory _symbol, string memory baseURI_, string memory _contractURI, string memory _metadataServiceAccount, uint256 _mintPrice, address[] memory _payees, uint256[] memory _shares) ERC721(_name, _symbol) EIP712FileSignature() {
        customBaseURI = baseURI_;
        customContractURI = _contractURI;
        metadataServiceAccount = _metadataServiceAccount;

        MAX_SUPPLY = 1;
        MINT_PRICE = _mintPrice;

        paymentSplitter = new PaymentSplitter(_payees, _shares);

        saleIsActive = false;
        groupSaleIsActive = false;
    }

    /**
     * @dev Changes the current sales state
     */
    function flipSaleIsActive() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /**
     * @dev Changes the current sales state for a single group
     */
    function flipGroupSaleIsActive(uint256 _groupId) public onlyOwner {
        groupSaleIsActive = !groupSaleIsActive;
        activeGroupId = _groupId;
    }

    /**
     * @dev Updates the base uri
     * @param _count The total number of tokens that the contract can mint
     */
    function setMaxSupply(uint256 _count) public onlyOwner {
        MAX_SUPPLY = _count;
    }

    /**
     * @dev Max supply for third party platforms
     * @param _count The total number of tokens that can be minted for a template data identifier
     * @param _dataId Template data identifier used during minting
     */
    function setMaxSupplyForDataId(uint256 _count, string memory _dataId) public onlyOwner {
        maxSupplyForDataId[_dataId] = _count;
    }

    /**
     * @dev Max supply for specified template data identifier
     * @param _dataId Template data identifier used during minting
     */
    function maxSupplyOfDataId(string memory _dataId) public view returns (uint256) {
        return maxSupplyForDataId[_dataId];
    }

    /**
     * @dev Set mint price for specific data identifier
     * @param _price Integer in wei
     * @param _dataId Template data identifier used during minting
     */
    function setMintPriceForDataId(uint256 _price, string memory _dataId) public onlyOwner {
        mintPriceForDataId[_dataId] = _price;
    }

    /**
     * @dev Mint price in wei for specified template data identifier
     * @param _dataId Template data identifier used during minting
     */
    function mintPriceOfDataId(string memory _dataId) public view returns (uint256) {
        return mintPriceForDataId[_dataId];
    }

    /**
     * @dev Sets the value needed to mint tokens
     * @param _price The cost to mint a token
     */
    function setMintPrice(uint256 _price) public onlyOwner {
        MINT_PRICE = _price;
    }

    /**
     * @dev Updates the base uri
     * @param baseURI_ The uri that is prefixed for all token ids
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        customBaseURI = baseURI_;
    }

    /**
     * @dev Gets the base uri for metadata storage
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /**
     * @dev Gets the base uri for metadata storage
     */
    function baseTokenURI() public view returns (string memory) {
        return customBaseURI;
    }

    /**
     * @dev Gets the token uri and appends .json
     * @param _tokenId Unique token identifier
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");
        string memory baseURI = _baseURI();
        string memory tokenURI_ = super.tokenURI(_tokenId);

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(tokenURI_, '.json'))
            : '';
    }

    /**
     * @dev Sets the custom contract metadata
     * @param contractURI_ File path under base URI without the .json file extension
     */
    function setContractURI(string memory contractURI_) external onlyOwner {
        customContractURI = contractURI_;
    }

    /**
     * @dev Gets the contract uri and appends .json
     */
    function contractURI() public view virtual returns (string memory) {
        string memory baseURI = _baseURI();

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, customContractURI, '.json'))
            : '';
    }

    /**
     * @dev Gets total number of existing groups
     */
    function totalGroups() public view returns (uint256) {
        return groupCounter.current();
    }
    
    /**
     * @dev Gets total number of existing tokens
     */
    function totalTokens() public view returns (uint256) {
        return tokenCounter.current();
    }

    /**
     * @dev Total tokens minted for a template data identifier
     * @param _dataId Template data identifier used during minting
     */
    function totalTokensOfData(string memory _dataId) public view returns (uint256) {
        return tokenCounterForDataId[_dataId];
    }

    /**
     * @dev Max supply for third party platforms
     */
    function totalSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev Sets new token in mapping for new group
     */
    function setTokensForGroup() private {
        tokensForGroup[totalGroups()].push(totalTokens());
    }

    /**
     * @dev Sets new token in mapping for an existing group
     * @param _groupId Unique group identifier
     */
    function setTokensForGroupId(uint256 _groupId) private {
        tokensForGroup[_groupId].push(totalTokens());
    }


    /**
     * @dev Sets the file signature for a new token
     * @param _signature Off chain web3 wallet signature approving the attached files checksums
     */
    function setFilesSignatureForToken(bytes calldata _signature) private {
        filesSignatureForToken[totalTokens()] = _signature;
    }

    /**
     * @dev Sets a new derivative token in mapping for an existing group
     * @param _groupId Unique group identifier
     */
    function setDerivativeTokensForGroup(uint256 _groupId) private {
        derivativeTokensForGroup[_groupId].push(totalTokens());
    }

    /**
     * @dev Mints a new token into a new group. Can only be called by approved onboarded user
     * @param _shares Number of shares to allocate to the initial token holder
     * @param _signingName The token or asset name
     * @param _signingMetadataHash The Sha3 hash of the metadata object
     * @param _signingDataId The reference id that is used for metadata reference and physical asset verification
     * @param _signature Off chain web3 wallet signature approving the attached files checksums
     */
    function mintWithNewGroup(uint256 _shares, string memory _signingName, string memory _signingMetadataHash, string memory _signingDataId, bytes calldata _signature) public payable nonReentrant verifyFileSignature(_signature, msg.sender, _signingName, _signingMetadataHash, _signingDataId) {
        require(saleIsActive, "Sale not active");
        require(msg.value >= mintPriceForDataId[_signingDataId], "Insufficient payment");
        require(totalTokens() < MAX_SUPPLY, "Exceeds max supply");
        require(tokenCounterForDataId[_signingDataId] < maxSupplyForDataId[_signingDataId], "Exceeds data id max supply");

        groupsForOwner[msg.sender].push(totalGroups());
        ownersForGroup[totalGroups()][msg.sender] = _shares;
        managerForGroup[totalGroups()] = msg.sender;
        
        setTokensForGroup();
        setFilesSignatureForToken(_signature);

        _safeMint(msg.sender, totalTokens());

        payable(paymentSplitter).transfer(msg.value);

        emit HasMinted(totalTokens(), _signature, _signingDataId);

        tokenCounterForDataId[_signingDataId] += 1;
        groupCounter.increment();
        tokenCounter.increment();
    }

    /**
     * @dev Mints a new token or new derivative token into an existing group. Can only be called by the group manager.
     * @param _groupId Unique group identifier
     * @param _isDerivative Is new token a derivative token
     * @param _signingName The token or asset name
     * @param _signingMetadataHash The Sha3 hash of the metadata object
     * @param _signingDataId The reference id that is used for metadata reference and physical asset verification
     * @param _signature Off chain web3 wallet signature approving the attached files checksums
     */
    function mintWithGroupId(uint256 _groupId, bool _isDerivative, string memory _signingName, string memory _signingMetadataHash, string memory _signingDataId, bytes calldata _signature) public payable nonReentrant verifyFileSignature(_signature, msg.sender, _signingName, _signingMetadataHash, _signingDataId) {
        require(groupSaleIsActive, "Group sale not active");
        require(msg.value >= mintPriceForDataId[_signingDataId], "Insufficient payment");
        require(activeGroupId == _groupId, "Group sale not active for group");
        require(_groupId < totalGroups(), "Group does not exist");
        require(totalTokens() < MAX_SUPPLY, "Exceeds max supply");
        require(tokenCounterForDataId[_signingDataId] < maxSupplyForDataId[_signingDataId], "Exceeds data id max supply");

        setTokensForGroupId(_groupId);
        setFilesSignatureForToken(_signature);
        
        if (_isDerivative) {
            setDerivativeTokensForGroup(_groupId);
        }

        _safeMint(msg.sender, totalTokens());

        payable(paymentSplitter).transfer(msg.value);

        emit HasMinted(totalTokens(), _signature, _signingDataId);

        tokenCounterForDataId[_signingDataId] += 1;
        tokenCounter.increment();
    }

    /**
     * @dev Adds a new owner to a group with specified shares
     * @param _owner Wallet address for owner
     * @param _shares Shares to give the new owner
     * @param _groupId Unique group identifier
     */
    function setGroupOwner(address _owner, uint256 _shares, uint256 _groupId) public onlyGroupManager(_groupId) {
        groupsForOwner[_owner].push(_groupId);
        ownersForGroup[_groupId][_owner] = _shares;
    }

    /**
     * @dev Removes an owner from a group
     * @param _owner Wallet address for owner
     * @param _groupId Unique group identifier
     */
    function removeGroupOwner(address _owner, uint256 _groupId) public onlyGroupManager(_groupId) {
        // delete groupsForOwner[_owner][_groupId];
        delete ownersForGroup[_groupId][_owner];
    }

    /**
     * @dev Sets new manager for a group
     * @param _owner Wallet address for owner
     * @param _groupId Unique group identifier
     */
    function setGroupManager(address _owner, uint256 _groupId) public onlyGroupManager(_groupId) {
        managerForGroup[_groupId] = _owner;
    }
    
    /**
     * @dev Gets shares owned by wallet 
     * @param _owner Wallet address for owner
     * @param _groupId Unique group identifier
     */
    function groupSharesOfOwner(address _owner, uint256 _groupId) public view returns (uint256) {
        return ownersForGroup[_groupId][_owner];
    }
    
    /**
     * @dev Checks that wallet owns group
     * @param _owner Wallet address for owner
     */
    function groupsOfOwner(address _owner) public view returns (uint256[] memory) {
        return groupsForOwner[_owner];
    }
    
    /**
     * @dev Gets total number of existing tokens
     * @param _groupId Unique group identifier
     */
    function tokensOfGroup(uint256 _groupId) public view returns (uint256[] memory) {
        return tokensForGroup[_groupId];
    }

    /**
     * @dev Gets the manager for a group
     * @param _groupId Unique group identifier
     */
    function managerOfGroup(uint256 _groupId) public view returns (address) {
        return managerForGroup[_groupId];
    }

    /**
     * @dev Gets the wallet signature for a token's attached files
     * @param _tokenId Unique token identifier
     */
    function filesSignatureOfToken(uint256 _tokenId) public view returns (bytes memory) {
        return filesSignatureForToken[_tokenId];
    }

    /**
     * @dev Gets the wallet signature for a token's attached files
     * @param _signingName The token or asset name
     * @param _signingMetadataHash The Sha3 hash of the metadata object
     * @param _signingDataId The reference id that is used for metadata reference and physical asset verification
     * @param _signature Unique token identifier
     */
    function verifyTokenFileSigner(string memory _signingName, string memory _signingMetadataHash, string memory _signingDataId, bytes calldata _signature) public view verifyFileSignature(_signature, msg.sender, _signingName, _signingMetadataHash, _signingDataId) returns (bool) {
        return true;
    }
    
    /**
     * @dev Gets derivative tokens that belong to a group
     * @param _groupId Unique group identifier
     */
    function derivativeTokensOfGroup(uint256 _groupId) public view returns(uint256[] memory) {
        return derivativeTokensForGroup[_groupId];
    }

    /**
     * @dev Sends distribution to a shareholder wallet
     * @param account The wallet to payout their owned shares
     */
    function release(address payable account) public virtual onlyOwner {
        paymentSplitter.release(account);
    }
}