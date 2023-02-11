// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;


import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Tides is ERC721AQueryable, Ownable, DefaultOperatorFilterer {

    uint256 public maxSupply = 999;
    uint256 public maxAmountPerTx = 3;
    uint256 public price = 0.004 ether;

    string public baseTokenURI = 'ipfs://bafybeiecvylmc4uziqfhhpmksxcc32x3bq36d5hhsu2idjbk7c6qdhsd5q/';
    saleState public state;


    enum saleState {
        pause,
        open
    }

    constructor() ERC721A("Tides by 0xTatsuhiro", "Tides by 0xTatsuhiro") {
    }


    function mint(uint256 amount) external payable {
        require(state == saleState.open, "Mint is close");
        require(totalSupply() + amount <= maxSupply, "Sold out");
        require(amount <= maxAmountPerTx, "Max per tx is 5");
        require(msg.value >= amount * price, "You need to pay more");

        _safeMint(msg.sender, amount);
    }

    function updateState(saleState _state) external onlyOwner {
        state = _state;
    }

    function updatePrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = owner().call{ value: address(this).balance }("");
        require(success, "Failed to withdraw Ether");
    }

    function airdrop(uint256 amount, address to) external onlyOwner {
        require(amount + totalSupply() <= maxSupply, "Sold out");
        _safeMint(to, amount);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}