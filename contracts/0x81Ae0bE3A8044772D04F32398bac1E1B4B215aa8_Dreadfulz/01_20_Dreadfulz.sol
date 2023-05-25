pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@divergencetech/ethier/contracts/thirdparty/opensea/OpenSeaGasFreeListing.sol";
import "./interfaces/IMerkle.sol";

contract Dreadfulz is ERC721ABurnable, Ownable, ReentrancyGuard, Pausable, PaymentSplitter {
    using Strings for uint256;
    string public baseUri = "https://ipfs.io/ipfs/QmUfeu9YQSXnJXBZRxa6M3kcKauWkTV1zHKBpzCMxmhcdN/";
    uint256 public supply;
    string public extension = ".json";  

    bool public whitelistLive;
    bool public isSaleLive;
    IMerkle public whitelist;

    struct Config {
        uint256 mintPrice;
        uint256 wlPrice;
        uint256 maxMint;
        uint256 maxMintPerTx;
    }

    Config public config;
    
    mapping(address => bool) admins;

    event WhitelistLive(bool live);
    event SaleLive(bool live);

    address[] recipients_ = [
        0x90fe9E0e0A5cbd055357f0A7146F3F27999b7d6c,
        0x5cCA08B7AEc91F7b65c89be60a97564ea3DD2F16
    ];
    uint256[] shares_ = [
        925,
        75
    ];

    constructor(
        string memory name,
        string memory symbol
    ) ERC721A(name, symbol) PaymentSplitter(recipients_, shares_) { 
        config.mintPrice = 0.098 ether;
        config.wlPrice = 0.088 ether;

        config.maxMint = 2;
        config.maxMintPerTx = 2;

        supply = 7777;
    }

    function whitelistMint(uint64 count, uint64 capacity, bytes32[] memory proof) external payable nonReentrant notBots whenNotPaused {
        require(count > 0, "No zero");
        require(whitelistLive, "Not live");
        require(whitelist.isPermitted(msg.sender, capacity, proof), "not whitelisted");
        require(msg.value >= config.wlPrice * count, "invalid price");
        uint64 newCount = _getAux(msg.sender) + count;
        require(newCount <= capacity, "Exceeds max");        
        _setAux(msg.sender,  newCount);
        _callMint(count, msg.sender);        
    }

    function mint(uint256 count) external payable nonReentrant whenNotPaused notBots { 
        require(count > 0, "No zero");
        require(isSaleLive, "Not live");
        require(count <= config.maxMintPerTx, "Exceeds max");
        uint256 publicMint = _numberMinted(msg.sender) - _getAux(msg.sender);
        require(publicMint + count <= config.maxMint, "Exceeds max");         
        require(msg.value >= config.mintPrice * count, "invalid price");
        _callMint(count, msg.sender);        
    }

    modifier notBots {        
        require(_msgSender() == tx.origin, "no bots");
        _;
    }

    function adminMint(uint256 count, address to) external adminOrOwner {
        _callMint(count, to);
    }

    function _callMint(uint256 count, address to) internal {        
        uint256 total = totalSupply();
        require(total + count <= supply, "Sold out");
        _safeMint(to, count);
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

    function setPaused(bool _paused) external adminOrOwner {
        if(_paused) {
            _pause();
        } else {
            _unpause();
        }
    }

    /**
        * @dev Returns the tokenIds of the address. O(totalSupply) in complexity.
     */
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 holdingAmount = balanceOf(owner);
        uint256 currSupply = _currentIndex;
        uint256 tokenIdsIdx;
        address currOwnershipAddr;

        uint256[] memory list = new uint256[](holdingAmount);

        unchecked {
            for (uint256 i; i < currSupply; i++) {
                TokenOwnership memory ownership = _ownerships[i];

                if (ownership.burned) {
                    continue;
                }

                // Find out who owns this sequence
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }

                // Append tokens the last found owner owns in the sequence
                if (currOwnershipAddr == owner) {
                    list[tokenIdsIdx++] = i;
                }

                // All tokens have been found, we don't need to keep searching
                if (tokenIdsIdx == holdingAmount) {
                    break;
                }
            }
        }

        return list;
    }

    function togglePublicLive() external adminOrOwner {
        bool isLive = !isSaleLive;
        isSaleLive = isLive;
        emit SaleLive(isLive);
    }

    function toggleWhitelistLive() external adminOrOwner {
        bool isLive = !whitelistLive;
        whitelistLive = isLive;
        emit WhitelistLive(isLive);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return super.isApprovedForAll(owner, operator) || OpenSeaGasFreeListing.isApprovedForAll(owner, operator) || admins[msg.sender];
    }

    function setMerkle(IMerkle _whitelist) external adminOrOwner {
        whitelist = _whitelist;
    }

    function setSupply(uint256 _supply) external adminOrOwner {
        supply = _supply;
    }

    function setConfig(Config memory _config) external adminOrOwner {
        config = _config;
    }
     
    function addAdmin(address _admin) external adminOrOwner {
        admins[_admin] = true;
    }

    function removeAdmin(address _admin) external adminOrOwner {
        delete admins[_admin];
    }

    modifier adminOrOwner() {
        require(msg.sender == owner() || admins[msg.sender], "Unauthorized");
        _;
    }
}