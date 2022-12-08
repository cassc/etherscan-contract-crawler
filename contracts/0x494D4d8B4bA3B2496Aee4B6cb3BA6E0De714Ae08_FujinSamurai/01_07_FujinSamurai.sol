// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FujinSamurai is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 333;
    uint256 public SALE_PRICE = .008 ether;
    uint256 public MAX_MINT = 2;
    bool public mintStarted = false;
    string public baseURI =
        "ipfs://QmbDm1URdfqgVnHiFQ7c654emAwnKnMBU2A6ekLKYkkH1a/";
    mapping(address => uint256) public walletMintCount;
    address reserveWallet = 0x921F787fb03485c944D0Bae4E2EefeDbcbC64952;

    constructor() ERC721A("Fujin Samurai", "FS") {}

    function mint(uint256 _quantity) external payable {
        require(mintStarted, "You can't be paranoid right now.");
        require(
            (totalSupply() + _quantity) <= MAX_SUPPLY,
            "Max supply exceeded."
        );
        require(
            (walletMintCount[msg.sender] + _quantity) <= MAX_MINT,
            "Max mint exceeded."
        );
        require(msg.value >= (SALE_PRICE * _quantity), "Wrong price detected.");

        walletMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reserveMint(uint256 mintAmount) external onlyOwner {
        _safeMint(reserveWallet, mintAmount);
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