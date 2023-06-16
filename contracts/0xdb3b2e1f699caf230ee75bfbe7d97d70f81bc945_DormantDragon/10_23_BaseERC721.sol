//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract BaseERC721 is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Strings for uint256; 
    string public baseUri;
    uint256 immutable public supply;
    uint256 immutable public max; 
    uint256 private startingIndex;
    uint256 public price;
    uint256 internal nextToken;
    bool public isSaleActive;
    mapping(address => uint) internal publicCount;
    mapping(address => uint) internal whitelistCount;
    address teamWallet;

    constructor(
        uint256 _supply, 
        uint256 _max,
        uint256 _price,
        string memory _baseUri,
        address _teamWallet,
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        supply = _supply;
        max = _max;
        price = _price;
        baseUri = _baseUri;
        teamWallet = _teamWallet;
    }

    function setUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }

    function mint(uint256 count) external payable nonReentrant {                
        require(isSaleActive, "Not live");
        require(publicCount[msg.sender] + count <= max, "max mints");
        _callMint(count);
        publicCount[msg.sender] += count;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyTeam {
        require(msg.sender == 0x5370d0e7D10004b39e9c7D38433116BA1a46463d,"only team" );
        _;
    }

    function teamMint() external onlyTeam{
        uint256 _total = totalSupply();
        require(balanceOf(teamWallet) == 0, "should be empty");
        require(_total < supply, "sold out"); 
        
        for (uint256 i = 0; i < 50; i++) {
            _safeMint(teamWallet, nextToken);
            nextToken = nextToken.add(1).mod(supply);
        }
    }

    function _callMint(uint256 count) internal {
        uint256 _total = totalSupply();        
        require(count > 0, "count is 0");       
        require(_total < supply, "sold out");        
        if(msg.sender != teamWallet) {
            require(price.mul(count) == msg.value, "Incorrect eth"); 
        }           

        for (uint256 i = 0; i < count; i++) {
            _safeMint(msg.sender, nextToken);
            nextToken = nextToken.add(1).mod(supply);
        }
    }

    function setStartingIndex() external onlyOwner {
        require(startingIndex == 0, "index set");
        
        startingIndex = uint256(blockhash(block.number - 1)) % supply;
   
        // Prevent default sequence
        if (startingIndex == 0) {
            startingIndex = startingIndex.add(1);
        }

        nextToken = startingIndex;
    }

    function togglePublicSale() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, tokenId.toString(), ".json")) : "";
    }

    function withdraw() external onlyTeam {
        uint256 balance = address(this).balance;
        payable(teamWallet).transfer(balance);
    }
}