// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;



import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract BabyDoodlePunks is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    string _baseUri;
    string _contractUri;
    
    uint public price = 0.03 ether;
    uint public maxFreeMint = 555;
    uint public constant MAX_SUPPLY = 5555;
    uint public maxFreeMintPerWallet = 25;
    bool public isSalesActive = false;
    
    mapping(address => uint) public addressToFreeMinted;

    constructor() ERC721("Baby Doodle Punks", "BDP") {
        _contractUri = "ipfs://QmQQjzTujPNAD4a5UBtd9xk5vgYQE7iEQvuZmpPmr7DMu6";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }
    
    function freeMint() external {
        require(isSalesActive, "Baby Doodle Punks sales is not active yet");
        require(totalSupply() < maxFreeMint, "No more free Babies for you!");
        require(addressToFreeMinted[msg.sender] < maxFreeMintPerWallet, "caller already minted for free");
        
        addressToFreeMinted[msg.sender]++;
        safeMint(msg.sender);
    }
    
    function mint(uint quantity) external payable {
        require(isSalesActive, "sale is not active yet");
        require(quantity <= 10, "max mints per transaction exceeded");
        require(totalSupply() + quantity <= MAX_SUPPLY, "sold out!");
        require(msg.value >= price * quantity, "ether send is under price");
        
        for (uint i = 0; i < quantity; i++) {
            safeMint(msg.sender);
        }
    }

    function safeMint(address to) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
    
    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current();
    }
    
    function contractURI() public view returns (string memory) {
        return _contractUri;
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseUri = newBaseURI;
    }
    
    function setContractURI(string memory newContractURI) external onlyOwner {
        _contractUri = newContractURI;
    }
    
    function toggleSales() external onlyOwner {
        isSalesActive = !isSalesActive;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function withdrawAll() external onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}