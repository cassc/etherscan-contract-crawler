pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IMerkle.sol";

contract CyberSnails is ERC721A, Ownable, ReentrancyGuard, Pausable {
    using Strings for uint256;
    uint256 public price = 0.088 ether;
    string public baseUri = "https://ipfs.io/ipfs/QmasLSZ7dBCuCRLYYvqYRaoPk7EzRji8oVXQK1aJuopisj/";
    uint256 public supply = 8888;
    string public extension = ".json";  

    IERC721 public keys;  

    bool public whitelistLive;
    bool public isKeyMintLive;
    bool public isSaleLive;

    address payable public paymentSplitter;
    uint256 public maxPerWallet = 10;
    uint256 public maxWLPerWallet = 1;
    uint256 public maxPerTx = 5;

    IMerkle public whitelist;
    
    mapping(uint256 => uint256) usedKeys;
    mapping(address => uint256) whitelistLimitPerWallet;
    mapping(address => uint256) limitPerWallet;
    mapping(address => bool) admins;

    event SaleLive(bool live);
    event WhitelistLive(bool live);
    event KeymintLive(bool live);
    event Claimed(uint256 count, address sender);

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) { _pause(); }

    function keyMint(uint256[] memory tokenIds, uint256[] memory counts) external payable nonReentrant whenNotPaused {
        require(isKeyMintLive, "Not live");                
        require(tokenIds.length == counts.length, "Should be equal");
        uint256 totalKeys = tokenIds.length;
        uint256 total;
        for(uint256 i; i < totalKeys; i++) {
            require(usedKeys[tokenIds[i]] + counts[i] <= 2, "Used Key");
            require(keys.ownerOf(tokenIds[i]) == msg.sender, "Must own");
            usedKeys[tokenIds[i]] += counts[i];
            total += counts[i];
        }
        require(msg.value >= price * total, "invalid price");
        _callMint(total, msg.sender);
    }

    function whitelistMint(uint256 count, bytes32[] memory proof) external payable nonReentrant whenNotPaused {
        require(whitelistLive, "Not live");
        require(msg.value >= price * count, "invalid price");
        require(whitelist.isPermitted(msg.sender, proof), "not whitelisted");
        require(whitelistLimitPerWallet[msg.sender] + count <= maxWLPerWallet, "Exceeds max");

        whitelistLimitPerWallet[msg.sender] += count;
        _callMint(count, msg.sender);        
    }

    function mint(uint256 count) external payable nonReentrant whenNotPaused {
        require(isSaleLive, "Not live");
        require(count <= maxPerTx, "Exceeds max");
        require(msg.value >= price * count, "invalid price");
        require(limitPerWallet[msg.sender] + count <= maxPerWallet, "Exceeds max");

        limitPerWallet[msg.sender] += count;
        _callMint(count, msg.sender);        
    }

    function adminMint(uint256 count, address to) external adminOrOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {        
        uint256 total = totalSupply();
        require(count > 0, "Count is 0");
        require(total + count <= supply, "Sold out");
        _safeMint(to, count);
    }

    function burn(uint256 tokenId) external {
        TokenOwnership memory prevOwnership = ownershipOf(tokenId);

        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
            isApprovedForAll(prevOwnership.addr, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        require(isApprovedOrOwner, "Not approved");
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = baseUri;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                )
                : "";
    }

    function setExtension(string memory _extension) external adminOrOwner {
        extension = _extension;
    }

    function setUri(string memory _uri) external adminOrOwner {
        baseUri = _uri;
    }

    function setPaused(bool _paused) external adminOrOwner attributesSet {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    function togglePublicSale() external adminOrOwner attributesSet {
        bool isLive = !isSaleLive;
        isSaleLive = isLive;
        emit SaleLive(isLive);
    }

    function toggleKeyLive() external adminOrOwner attributesSet {
        bool isLive = !isKeyMintLive;
        isKeyMintLive = isLive;
        emit KeymintLive(isLive);
    }

    function toggleWhitelistLive() external adminOrOwner attributesSet {
        bool isLive = !whitelistLive;
        whitelistLive = isLive;
        emit WhitelistLive(isLive);
    }

    function setMerkle(IMerkle _whitelist) external adminOrOwner {
        whitelist = _whitelist;
    }

    function setPrice(uint256 _price) external adminOrOwner {
        price = _price;
    }

    function setSupply(uint256 _supply) external adminOrOwner {
        supply = _supply;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external adminOrOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setMaxWLPerWallet(uint256 _maxPerWallet) external adminOrOwner {
        maxWLPerWallet = _maxPerWallet;
    }

    function setPaymentSplitter(address payable _paymentSplitter) external adminOrOwner {
        paymentSplitter = _paymentSplitter;
    }

    function setMaxPerTx(uint256 _tx) external adminOrOwner {
        maxPerTx = _tx;
    }
     
    function withdraw() external adminOrOwner {
        require(paymentSplitter != address(0x0), "PS not set");
        (bool success, ) = paymentSplitter.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    function setKeys(IERC721 _key) external adminOrOwner {
        keys = _key;
    }

    function checkKeyCounter(uint256 _key) public view returns (uint256) {
        return usedKeys[_key];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }

    modifier attributesSet() {
        require(
            supply != 0 && address(whitelist) != address(0x0) && price != 0 && maxPerWallet != 0, 
            "Set everything before starting"
        );
        _;
    }
}