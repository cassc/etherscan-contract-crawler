// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract CryptoCrocs is ERC721A, Ownable, ReentrancyGuard {

    uint256 public MAX_SUPPLY = 999;
    uint256 public MINT_LIMIT = 10;
    uint256 public PRICE = 0.002 ether;

    mapping(address => uint256) mintedAddresses;

    bool public mintState = false;
    string private baseURI = "";

    constructor() ERC721A("Crypto Crocs", "CRYPTOCROCS") {
        _mint(msg.sender, 1);
    }

    function mint(uint256 amount) external payable {
        require(mintState, "BE_PATIENT");
        require(amount + totalSupply() <= MAX_SUPPLY, "GO_TO_OPENSEA");
        require(amount + mintedAddresses[msg.sender] <= MINT_LIMIT, "MINT_LIMIT_EXCEEDS");
        require(msg.value >= amount * PRICE, "INCORRECT_ETH");

        mintedAddresses[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function mintForAddress(uint256 mintAmount_, address to_) external onlyOwner {
        _mint(to_, mintAmount_);
    }

    function batchMintForAddresses(address[] calldata addresses_, uint256[] calldata amounts_) external onlyOwner {
        require(addresses_.length == amounts_.length, "ADDRESSES_AMOUNT_MISMATCH");
        unchecked {
        for (uint32 i = 0; i < addresses_.length; ++i) {
            _mint(addresses_[i], amounts_[i]);
        }
      }
    }

    // URI
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    // SALE STATE FUNCTIONS
    function flipMintState() external onlyOwner {
        mintState = !mintState;
    }

    function getMintState() public view returns (bool) {
        return mintState;
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
      require(_exists(tokenId_), "INVALID_TOKEN_ID");
      return string(abi.encodePacked(baseURI, Strings.toString(tokenId_), ".json"));
    }

    // LIMIT SETTERS
    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        MINT_LIMIT = _mintLimit;
    }

    // PRICE FUNCTIONS
    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

    function gerPrice() public view returns (uint256) {
        return PRICE;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
      MAX_SUPPLY = _maxSupply;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    // withdraw
    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }
}