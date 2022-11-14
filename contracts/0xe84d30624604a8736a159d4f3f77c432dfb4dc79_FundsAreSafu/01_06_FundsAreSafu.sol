// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FundsAreSafu is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 333;
    uint256 public MAX_MINT = 3;
    uint256 public SALE_PRICE = .005 ether;
    bool public mintStarted = false;

    string public baseURI = "ipfs://QmPvPHTz1yvLCi5qxKE6BLhaTdBMure8EA3Z9SiwiWdYU2/";
    mapping(address => uint256) public walletMintCount;

    constructor() ERC721A("FundsAreSafu", "FAS") {}

    function safuMint(uint256 _quantity) external payable {
        require(mintStarted, "Minting is not live yet.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Not Safu: Beyond max supply."
        );
        require(
            (walletMintCount[msg.sender] + _quantity) <= MAX_MINT,
            "Not Safu: Wrong mint amount."
        );
        require(msg.value >= (SALE_PRICE * _quantity), "Not Safu: Wrong mint price.");

        walletMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function teamSafuMint(uint256 mintAmount) external onlyOwner {
        _safeMint(msg.sender, mintAmount);
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

    function startSaleSafu() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setPriceSafu(uint256 _newPrice) external onlyOwner {
        SALE_PRICE = _newPrice;
    }

    function setSupplySafu(uint256 _newSupply) external onlyOwner {
        MAX_SUPPLY = _newSupply;
    }

    function withdrawSafu() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}