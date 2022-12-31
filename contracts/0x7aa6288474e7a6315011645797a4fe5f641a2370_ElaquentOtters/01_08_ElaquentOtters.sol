// Elaquent Otters
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract ElaquentOtters is ERC721A, Ownable, ReentrancyGuard {

    uint256 public maxSupply = 5000;
    uint256 public maxMintAmountPerWallet = 11;
    uint256 public maxFreeMintAmountPerWallet = 1;

    mapping(address => bool) freeMinted;
    uint256 public cost = 0.002 ether;
    bool public mintState = false;

    string private baseURI = "";
    
    constructor() ERC721A("Elaquent Otters", "EQOTTERS") {
        _mint(msg.sender, 1);
    }

    function publicMint(uint256 _amount) external payable nonReentrant {
      require(mintState, 'Mint is not live yet.');

      require(totalSupply() + _amount <= maxSupply, 'Go buy on secondary.');
      require(_numberMinted(msg.sender) + _amount <= maxMintAmountPerWallet, 'Mint limit exceeded.');

      if(freeMinted[msg.sender]) {
        require(msg.value >= _amount * cost, 'Insufficient balance.');
      } else {
        require(msg.value >= (_amount - 1) * cost, 'Insufficient balance.');
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
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId_), ".json"));
    }

    function flipMintState() external onlyOwner {
        mintState = !mintState;
    }

    function getMintState() public view returns (bool) {
        return mintState;
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