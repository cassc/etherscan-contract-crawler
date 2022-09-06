// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MusixContract is ERC721Enumerable,Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
	using Strings for uint256;

	Counters.Counter private _tokenIds;
    string private baseTokenURI;
	string private myContractURI;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_MINT = 10;
    uint256 public constant MIN_PRICE = 0.0369 ether;
    uint256 public constant MAX_PRICE = 0.1537 ether;
    uint256 public startDate = 1656356400;

    mapping(uint256 => string) tokenIdToRarity;
    event NewRandom(uint _value);

    constructor(string memory baseURI)
		ERC721("MasterKey", "MASTERKEY")
	{
        baseTokenURI = baseURI;
        _tokenIds.increment();
    }

    function mintNft(uint _quantity) external payable{
        uint256 _totalMinted = _tokenIds.current();
        require(_totalMinted + _quantity <= MAX_SUPPLY, "Quantity Exceed MAX SUPPLY");
		require(_quantity > 0 && _quantity <= MAX_PER_MINT, "Exceed mint quantity");
		require(msg.value >= getCurrentPrice()*_quantity, "Not enough Matic");

        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(msg.sender, _tokenIds.current());
            tokenIdToRarity[_tokenIds.current()] = randomize(_tokenIds.current());
            _tokenIds.increment();
        }
        
    }

    function getCurrentPrice() public view returns (uint256){
        uint256 daysAfterLaunch = 0;
        if(block.timestamp > startDate){
            daysAfterLaunch = (block.timestamp - startDate) / (1* 1 days);
        }
        
        uint256 priceCalculation = MIN_PRICE+(daysAfterLaunch* 0.02336 ether);

        if(priceCalculation < MAX_PRICE){
            return priceCalculation;
        }else{
            return MAX_PRICE;
        }

    }

    function getDays() public view returns (uint256){
        return (block.timestamp - startDate) / (1* 1 days);

    }

    function randomize(uint _tokenId) private returns (string memory) {
        uint random = (uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _tokenId.toString()))) % 10000) + 1;
        emit NewRandom(random);
        if(random > 0 && random <= 7395){
            return "Blue";
        }else if(random > 7395 && random <= 9395){
            return "Green";
        }else if(random > 9395 && random <= 9895){
            return "Copper";
        }else if(random > 9895 && random <= 9995){
            return "Silver";
        }else if(random > 9895 && random <= 10000){
            return "Gold";
        }else{
            return "Blue";
        }
    }

    function tokensOfOwner(address _owner) external view returns (uint[] memory) {
        uint tokenCount = balanceOf(_owner);
        uint[] memory tokensId = new uint256[](tokenCount);
        for (uint i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }

        return tokensId;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseURI(), tokenIdToRarity[tokenId], ".json"));
    }
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
	function contractURI() public view returns (string memory) {
        return myContractURI;
    }
    function getRarity(uint256 tokenId) public view returns ( string memory){
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenIdToRarity[tokenId];
    }
	function setContractURI(string memory _uri) external onlyOwner{
        myContractURI = _uri;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');require(success, "Withdrawal failed");
    }
}