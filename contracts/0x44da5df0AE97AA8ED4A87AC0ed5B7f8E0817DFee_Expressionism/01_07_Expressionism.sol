// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Expressionism is ERC721A, Ownable {
    using Strings for uint256;

    uint256 public MAX_DMT = 333;
    uint256 public MAX_DMT_PER_WALLET = 2;
    uint256 public DMT_Price = 0.0069 ether;
    bool public mintStarted = false;
    string public baseURI = "ipfs://QmWXSgCj1dViDB7AwkaXuv5Qv1xkYuazWcYqno1dqHBwkG/";
    mapping(address => uint256) public dmtPerWallet;

    constructor() ERC721A("Expressionism by DMT", "EXP") {}

    function getThePipe(uint256 _quantity) external payable {
        require(mintStarted, "You can not get your pipe yet.");
        require(
            (totalSupply() + _quantity) <= MAX_DMT,
            "Beyond max DMT supply."
        );
        require(
            (dmtPerWallet[msg.sender] + _quantity) <= MAX_DMT_PER_WALLET,
            "Wrong DMT amount."
        );
        require(msg.value >= (DMT_Price * _quantity), "Wrong DMT price.");

        dmtPerWallet[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function reservePipe(uint256 mintAmount) external onlyOwner {
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

    function startSaleDMT() external onlyOwner {
        mintStarted = !mintStarted;
    }

    function setDMTPrice(uint256 _newPrice) external onlyOwner {
        DMT_Price = _newPrice;
    }

    function withdrawPipe() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}