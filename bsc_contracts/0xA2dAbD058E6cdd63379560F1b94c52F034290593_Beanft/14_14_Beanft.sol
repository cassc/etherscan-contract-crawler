// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Beanft is
    ERC721Enumerable,
    Ownable
{
    using Strings for uint256;
    uint256 public constant maxSupply = 777;
    uint256 public constant price = 0;
    string private baseURI;

    mapping(uint256 => string[4]) public words;
    mapping(address => uint256) public created;
    mapping(address => bool) public whitelisted;
    mapping(uint256 => address) public creator;
    uint256 public reservedForWhitelisted;
    bool public whitelistReserved = true;
    bool public mintActive = false;
    uint256 public startIndex;

    constructor() ERC721("Beanft Community", "Beanft") {}

    function mint(address to_, uint256 amount_, string[4] memory words_) external payable {
        require(mintActive, "Mint not started yet");
        require(amount_ == 1, "Only one NFT per wallet");
        require(msg.value == 0, "Free mint");
        require(tx.origin == to_, "Only mint for origin");
        require(bytes(words_[0]).length > 0, "Empty word 0");
        require(bytes(words_[1]).length > 0, "Empty word 1");
        require(bytes(words_[2]).length > 0, "Empty word 2");
        require(bytes(words_[3]).length > 0, "Empty word 3");
        require(created[to_] == 0, "Only one per wallet");

        uint256 _totalSupply = totalSupply();
        uint256 tokenId = _totalSupply + 1;

        if (whitelisted[to_]) {
            delete whitelisted[to_];
            --reservedForWhitelisted;
        }

        require(_totalSupply + (whitelistReserved ? reservedForWhitelisted : 0) < maxSupply, "Max Supply rached");
        
        created[to_] = tokenId;
        words[tokenId] = words_;
        creator[tokenId] = to_;
        _safeMint(to_, tokenId);
    }

    function setMintActive(bool _active) external onlyOwner {
        mintActive = _active;
    }

    function setWhitelisted(address[] calldata users) external onlyOwner {
        uint256 _reservedForWhitelisted = reservedForWhitelisted;
        for (uint256 i = 0; i < users.length; ++i) {
            if (!whitelisted[users[i]] && created[users[i]] == 0) {
                whitelisted[users[i]] = true;
                ++_reservedForWhitelisted; 
            }
        }
        reservedForWhitelisted = _reservedForWhitelisted;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setWhitelistReserved(bool whitelistReserved_) external onlyOwner {
        whitelistReserved = whitelistReserved_;
    }

    function shuffle() external onlyOwner {
        require(startIndex == 0, "Already shuffled");
        startIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.number))) % maxSupply;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI_ = _baseURI();

        if (startIndex == 0) {
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, "unrevealed/", tokenId.toString())) : "";
        } else {
            uint256 _generatedId = ((tokenId - 1 + startIndex) % maxSupply) + 1;
            return bytes(baseURI_).length > 0 ? string(abi.encodePacked(baseURI_, _generatedId.toString())) : "";
        }
    }
}