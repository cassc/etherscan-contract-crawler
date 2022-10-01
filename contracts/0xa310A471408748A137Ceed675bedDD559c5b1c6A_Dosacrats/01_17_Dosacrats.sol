// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Dosacrats is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable, VRFConsumerBaseV2{
    using Counters for Counters.Counter;
    using Strings for uint256;
      
     // Chainlink Setup //
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator;
    bytes32 keyHash;
    uint32 chainlinkCallbackLimit = 300000;
    uint16 requestConfirmations = 3;
    uint64 subscriptionId;
    uint256 public collectionSeed;

    // Minters
    mapping(uint256 => address) public minters;

    // Max supply of NFTs
    uint256 public constant MAX_NFT_SUPPLY = 10_000;


    // Max NFT per user
    uint256 public MAX_NFT_PER_USER = 10;

    // Max NFTs per mint
    uint256 public MAX_NFT_PER_MINT = 10;

    uint256 public mintPrice = 0.1 ether;

    //Tax-Free Users
    mapping(address => uint256) public freeNft;

    mapping(address => bool) public isWhitelisted;

    bool public whitelistEnabled = false;

    // Total supply of NFTs
    uint256 internal _totalSupply;

    // Admin wallet
    address public admin;

    bool public mintEnabled;
    string private baseURI;
    string public imageHash;

    mapping(address => bool) public excluded;
    constructor(
        address _chainlinkCoordinatorAddress,
        string memory _imageHash,
        string memory _baseURI,
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) VRFConsumerBaseV2(_chainlinkCoordinatorAddress) {
        imageHash = _imageHash;
        baseURI = _baseURI;
        vrfCoordinator = _chainlinkCoordinatorAddress;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        admin = msg.sender;
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function setSeededURI(string memory _baseUri) external onlyOwner {
        require(
            keccak256(abi.encodePacked((baseURI))) !=
            keccak256(abi.encodePacked((_baseUri))),
            "ERC721Metadata: existed seededUri"
        );
        baseURI = _baseUri;
    }

    function setImageHash(string memory hash) external onlyOwner {
        imageHash = hash;
    }

    function setVRFSettings(uint64 _subscriptionId, uint16 _requestConfirmations, uint32 _callbackGasLimit, bytes32 _keyHash) external onlyOwner {
        requestConfirmations = _requestConfirmations;
        chainlinkCallbackLimit = _callbackGasLimit;
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
    }

    function getMintedCounts() external view returns (uint256) {
        uint256 count = 0;
        for (uint i = 1; i <= MAX_NFT_SUPPLY; i++) {
            if (minters[i] == msg.sender) {
                count += 1;
            }
        }
        return count;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable){
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool){
        return super.supportsInterface(interfaceId);
    }

    function contractURI() public view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "metadata.json")) : "";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require( _exists(tokenId), "ERROR: URI query for nonexistent token" );
        if (collectionSeed == 0) {
            tokenId = 0;
        }
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function getTokenSeed(uint256 tokenId) public view returns (uint256)
    {
        require( tokenId <= MAX_NFT_SUPPLY, "Token Not Found");
        require( tokenId > 0, "Token Not Found");

        if (collectionSeed == 0){
            return 0;
        }

        uint256[MAX_NFT_SUPPLY] memory numberArr;

        uint256 n;
        uint256 temp;
        for (uint256 i = 0; i < MAX_NFT_SUPPLY;) {
            n = i + collectionSeed % (MAX_NFT_SUPPLY - i);
            temp = numberArr[n] == 0 ? n : numberArr[n];
            numberArr[n] = numberArr[i] == 0 ? i : numberArr[i];
            numberArr[i] = temp;
            unchecked{ i++; }
        }

        return numberArr[tokenId - 1];
    }

    function setMintEnabled(bool state) external onlyOwner{
        mintEnabled = state;
    }

    function _transfer(address from,address to, uint256 tokenId) internal override{
        require(excluded[to] || balanceOf(to) + 1 <= MAX_NFT_PER_USER, "You are exceeding MAX_NFT_PER_USER");
        super._transfer(from,to,tokenId);
    }

    function mintNFT(uint256 numberOfNfts) external payable nonReentrant{
        require(mintEnabled, "Mint not enabled yet");
        require(!isContract(msg.sender), "You can't mint with contract");
        require(!whitelistEnabled || isWhitelisted[msg.sender], "You are not whitelisted");
        require(totalSupply() < MAX_NFT_SUPPLY, "All minted");
        require(numberOfNfts > 0, "numberOfNfts cannot be 0");
        require(numberOfNfts <= MAX_NFT_PER_MINT, "You can't mint more than MAX_NFT_PER_MINT NFT");
        require(balanceOf(msg.sender) + numberOfNfts <= MAX_NFT_PER_USER, "You are exceeding MAX_NFT_PER_USER");
        require(totalSupply() + (numberOfNfts) <= MAX_NFT_SUPPLY,"All NFTs already minted");
        uint256 price = mintPrice * _calculateNftToBePayed(numberOfNfts);
        require(msg.value >= price, "invalid ether value");
        freeNft[msg.sender] -= numberOfNfts - _calculateNftToBePayed(numberOfNfts);
        sendEthToAdmin(price);
        mint(msg.sender, numberOfNfts);
        if(msg.value - price > 0) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function generateSeed() external onlyOwner {
        require(chainlinkCallbackLimit <= 2_500_000, 'Chainlink callback gas limit must be less then 2500000');
        require(collectionSeed == 0, 'Chainlink randomic seed already generated');
        COORDINATOR.requestRandomWords(keyHash,subscriptionId,requestConfirmations, chainlinkCallbackLimit, 1);
    }

    function mint(address to, uint256 number) internal {
        for(uint256 i = 0; i < number;) {
            _totalSupply++;
            _mint(to, _totalSupply);
            minters[_totalSupply] = to;
            unchecked{ i++; }
        }
    }

    function fulfillRandomWords(uint256 , uint256[] memory _randomValues) internal virtual override {
        collectionSeed = _randomValues[0];
    }

    function _calculateNftToBePayed(uint256 numberOfNfts) internal view returns (uint256) {
        uint256 payableNfts = 0;
        if (numberOfNfts > freeNft[msg.sender]) {
            payableNfts = numberOfNfts - freeNft[msg.sender];
        }

        return payableNfts;
    }

    function setFreeNft(address user, uint256 value) external onlyOwner{
        freeNft[user] = value;
    }

    function setMintPrice(uint256 value) external onlyOwner{
        mintPrice = value;
    }

    function setMaxNFTPerUser(uint256 _max) external onlyOwner {
        MAX_NFT_PER_USER = _max;
    }

    function setMaxNFTPerMint(uint256 _max) external onlyOwner {
        MAX_NFT_PER_MINT = _max;
    }

    function setExcludedAddress(address addr, bool state) external onlyOwner{
        excluded[addr] = state;
    }

    function sendEthToAdmin(uint256 amount) internal {
        (bool success, ) = admin.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function setAdminWallet(address _admin) external onlyOwner {
        admin = _admin;
    }

    function setWhitelistEnabled(bool state) external onlyOwner {
        whitelistEnabled = state;
    }

    function setBulkWhitelist(address[] calldata _users, bool status) external onlyOwner {
        uint256 length = _users.length;
        for (uint256 i = 0; i < length;) {
            isWhitelisted[_users[i]] = status;
            unchecked {
                i++;
            }
        }
    }

    function setWhitelist(address _user, bool status) external onlyOwner {
        isWhitelisted[_user] = status;
    }
}