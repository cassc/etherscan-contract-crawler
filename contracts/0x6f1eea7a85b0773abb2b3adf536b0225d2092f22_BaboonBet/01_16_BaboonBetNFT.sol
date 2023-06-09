// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// implements the ERC721 standard
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaboonBet is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _Ids;
    uint256 public immutable MAX_BABOONS = 10000;
    uint256 public immutable baboonPrice = 0.05 ether; 
    bool private saleActive = true; 

    string private baseURI = "https://api.baboon.bet/token/";

    address payable private _manager; 

    constructor(address manager) ERC721("BaboonBet", "BBET") {
        _manager = payable(manager);
    }

    function buy(uint256 baboonsQty) external payable {
        require(saleActive == true, "Sales are currently close");
        require(totalSupply() < MAX_BABOONS, "Sold Out");
        require(baboonsQty > 0, "Qty cannot be 0");
        require(baboonsQty <= 100, "Qty exceeded");
        require(
            totalSupply().add(baboonsQty) <= MAX_BABOONS,
            "Sale exceeds available Baboons"
        );
        uint256 salePrice = baboonPrice.mul(baboonsQty);
        require(msg.value >= salePrice, "Insufficient Amount"); 

        for (uint256 i = 0; i < baboonsQty; i++) {
            _Ids.increment();
            uint256 newItemId = _Ids.current();
            _safeMint(msg.sender, newItemId);
        }

       _manager.transfer(msg.value);
        
    }

    function tokensOfOwner(address owner)
        external
        view
        returns (string[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            return new string[](0);
        } else {
            string[] memory result = new string[](tokenCount);
            uint256 id;

            for (id = 0; id < tokenCount; id++) {
                result[id] = tokenURI((tokenOfOwnerByIndex(owner, id)));
            }

            return result;
        }
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function toogleSale() public onlyOwner {
        saleActive = !saleActive;
    }

    function statusSale() public view returns (bool status) {
        return saleActive; 
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "0"));
    }

    function _baseURI()
        internal
        view
        override(ERC721)
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}