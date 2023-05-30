//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./ERC721EnumB.sol";

contract BaseERC721 is ERC721EnumB, Ownable, ReentrancyGuard, PaymentSplitter {
    using Strings for uint256;
    string public baseUri;
    address private teamWallet = 0x625Ff9Ce2d51Ee66FfCe890a455968CB39e7A405;
    uint256 public supply;
    uint256 public max; 
    string private extension = ".json";
    uint256 private startingIndex;
    uint256 public price;
    bool public isSaleActive;
    address[] _addresses = [
        // dev wallet
        0x06b9A0F17d8281Ba7D6c0A862750f39d1281a177,
        // owner wallet
        teamWallet
    ];
    uint256[] _shares = [20,80];
    mapping(address => uint) private mintCount;
    event SaleActive(bool live);

    constructor(
        uint256 _supply, 
        uint256 _max,
        uint256 _price,
        string memory _baseUri,
        string memory name,
        string memory symbol
    ) ERC721B(name, symbol) PaymentSplitter(_addresses, _shares){
        supply = _supply;
        max = _max;
        price = _price;
        baseUri = _baseUri;
    }

    function setExtension(string memory _extension) external onlyOwner {
        extension = _extension;
    }

    function setUri(string memory _uri) external onlyOwner {
        baseUri = _uri;
    }

    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    function setMax(uint _max) external onlyOwner {
        max = _max;
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "caller is not owner nor approved");
        _burn(tokenId);
    }

    function setSupply(uint _supply) external onlyOwner {
        supply = _supply;
    }

    modifier onlyTeam() {
        require(msg.sender == teamWallet, "Only team");
        _;
    }

    function teamMint(uint256 count) external nonReentrant onlyTeam {
        _callMint(count);
    }

    function setTeamWallet(address _teamWallet) external onlyOwner {
        teamWallet = _teamWallet;
    }

    function mint(uint256 count) external payable nonReentrant {
        require(isSaleActive, "Not Live");
        _callMint(count);
    }
    
   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	    require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
	    string memory currentBaseURI = baseUri;
	    return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString(), extension)) : "";
	}

    function _callMint(uint256 count) internal {
        uint256 total = totalSupply();
        require(count > 0, "Count is 0");       
        require(total + count <= supply, "Sold out");
        if(msg.sender != teamWallet) {
            require(price * count == msg.value, "Incorrect Eth");
            require(mintCount[msg.sender] + count <= max, "Max Mint");        
        }
        for (uint256 i = 0; i < count; i++) {  
            _safeMint(msg.sender, total + i);
            mintCount[msg.sender]++;
        }
        delete total;
    }

    function togglePublicSale() external onlyOwner {
        isSaleActive = !isSaleActive;
        emit SaleActive(isSaleActive);
    }
}