// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OrdinalKids is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 555;
    uint256 public SALE_PRICE = .003 ether;
    uint256 public MAX_MINT = 5;
    bool public mintStarted = false;
    string public baseURI = "ipfs://QmSXEqpdBdAethasV6QQfs9Z9pkKqJDUXV3PRyB2Mqj7ui/";

    constructor() ERC721A("Ordinal Kids", "OK") {}

    function mint(uint256 amount) external payable {
        require(mintStarted, "Mint paused.");
        require((totalSupply() + amount) <= MAX_SUPPLY, "Max supply exceeded.");
        require(amount <= MAX_MINT, "Max mint exceeded.");
        require(msg.value >= (SALE_PRICE * amount), "Wrong mint price.");

        _safeMint(msg.sender, amount);
    }

    function ownerMint(address receiver, uint256 mintAmount)
        external
        onlyOwner
    {
        _safeMint(receiver, mintAmount);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function startSale() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setSupply(uint256 newSupply) external onlyOwner {
        MAX_SUPPLY = newSupply;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        SALE_PRICE = _newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}