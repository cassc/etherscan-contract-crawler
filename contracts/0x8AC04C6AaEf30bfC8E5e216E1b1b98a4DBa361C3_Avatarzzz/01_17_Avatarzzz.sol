// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Avatarzzz is ERC721, ERC721URIStorage, Pausable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address payable private constant FUND_ACCOUNT = payable(0xC47E9faC26217C3f4D34a2D6086df26c5c307085);

    uint256 public mintPrice = 10 * 1e18;
    string public constant BASE_TOKEN_URI = "https://storage.googleapis.com/avatarzzz_metadata/";
    uint256 public maxMint = 1;
    uint256 public maxSupply = 10000;

    mapping(string => uint8) private existingURI;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    AggregatorV3Interface internal priceFeed;
    
    constructor() ERC721("Avatarzzz", "AVA") {
        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price , , ,) = priceFeed.latestRoundData();
        return uint256(price * 1e10); 
    }

    function msgValueInUSD(uint256 amount) public view returns(uint256) {
        uint256 currentETHPrice = getLatestPrice(); 
        uint256 ethAmountInUSD = (currentETHPrice * amount) / 1e18;
        return ethAmountInUSD;
    }

    mapping(address => bool) private addressAlreadyMinted; 

    function safeMint(uint256 num) public nonReentrant payable {
        require(num >= 0, "num failure"); 
        require(num < maxSupply, "Sorry minting failed, check token details");
        require(addressAlreadyMinted[msg.sender] == false, "Sorry!, you already minted 1 mint");
        require(existingURI[string(abi.encodePacked(BASE_TOKEN_URI,Strings.toString(num),".json"))] != 1, "Sorry!, this NFT is already minted");
        require(_tokenIdCounter.current() < maxSupply,"Sorry!, All the Avatarrzzz are minted. Please wait for upcoming drop (minting < total supply)");
        require(msgValueInUSD(msg.value) >= mintPrice, "Please pay the minting price to purchase the Avatarzzz. Thank You!");   
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(BASE_TOKEN_URI,Strings.toString(num),".json")));
        existingURI[string(abi.encodePacked(BASE_TOKEN_URI,Strings.toString(num),".json"))] = 1;
        addressAlreadyMinted[msg.sender] = true;
        
        emit NftMinted(tokenId, num, msg.sender);
    }

    event NftMinted(
        uint256 indexed tId,
        uint256 indexed avatarNum,
        address minter
    );

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal whenNotPaused override
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function checkURIexistance(string memory uri) public view returns (bool) {
        return existingURI[uri] == 1;
    }

    function updateMintingPrice(uint256 _newPrice) public onlyOwner {
        mintPrice = _newPrice;
    }

    function updateMaxSupply(uint256 _newSupply) public onlyOwner {
        maxSupply = _newSupply;
    }

    function updateMaxMint(uint256 _newMaxMint) public onlyOwner {
        maxMint = _newMaxMint;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = (FUND_ACCOUNT).call{value: address(this).balance}("");
        require(success, "Ether withdrawl failed!");
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}