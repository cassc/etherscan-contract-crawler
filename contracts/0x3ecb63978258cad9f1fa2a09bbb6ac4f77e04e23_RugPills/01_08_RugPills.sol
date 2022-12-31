// Tired of getting rugged ??
// Have a rug pill !!!

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract RugPills is ERC721A, Ownable, ReentrancyGuard {

    uint256 public maxSupply = 1000;
    uint256 public maxMintAmountPerWallet = 3;
    uint256 public maxFreeMintAmountPerWallet = 1;

    mapping(address => bool) freeMinted;
    uint256 public cost = 0.002 ether;
    bool public paused = true;

    string private baseURI = "https://nftstorage.link/ipfs/bafybeibx7rutvflq7sk3qyi77zjpq7uqkhp7olxztcvkonpim2bmbjc2ra";
    
    constructor() ERC721A("Rug Pills", "RugPills") {
        _mint(msg.sender, 1);
    }

    function eatRugPill(uint256 _amount) external payable nonReentrant {
      require(!paused, 'Cant eat pill yet.');

      require(totalSupply() + _amount <= maxSupply, 'Find pill somewhere else.');
      require(_numberMinted(msg.sender) + _amount <= maxMintAmountPerWallet, 'Dont overdose.');

      if(freeMinted[msg.sender]) {
        require(msg.value >= _amount * cost, 'Pills are costly.');
      } else {
        require(msg.value >= (_amount - 1) * cost, 'Pills are costly.');
        freeMinted[msg.sender] = true;
      } 
      _safeMint(msg.sender, _amount);
    }

    function mintForAddress(uint256 mintAmount_, address to_) external onlyOwner {
        _mint(to_, mintAmount_);
    }

    function batchMintForAddresses(address[] calldata addresses_, uint256[] calldata amounts_) external onlyOwner {
        require(addresses_.length == amounts_.length, "Length mismatch");
        unchecked {
        for (uint32 i = 0; i < addresses_.length; ++i) {
            _mint(addresses_[i], amounts_[i]);
        }
      }
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
      require(_exists(tokenId_), "Invalid Token Id");
      return string(abi.encodePacked(baseURI));
    }

    function flipMintState() external onlyOwner {
        paused = !paused;
    }

    function getMintState() public view returns (bool) {
        return paused;
    }

    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        maxMintAmountPerWallet = _mintLimit;
    }

    function setPrice(uint256 _price) external onlyOwner {
        cost = _price;
    }

    function gerPrice() public view returns (uint256) {
        return cost;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
}