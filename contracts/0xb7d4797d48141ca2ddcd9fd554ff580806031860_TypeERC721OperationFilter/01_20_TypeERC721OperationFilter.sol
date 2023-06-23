// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import './CryptoGenerator.sol';

contract TypeERC721OperationFilter is ERC721Enumerable, DefaultOperatorFilterer, Ownable, CryptoGenerator {
    using Strings for uint256;

    string public _baseTokenURI;
    uint256 public _price;
    uint256 public _maxSupply;

    constructor(address _owner, string memory name, string memory symbol, uint256 maxSupply, uint256 price, string memory baseURI, address payable _affiliated) ERC721(name, symbol) CryptoGenerator(_owner, _affiliated) payable {
        setBaseURI(baseURI);
        _maxSupply = maxSupply;
        _price = price;
        if (msg.sender != _owner) {
            transferOwnership(_owner);
        }
    }

    function mint(uint256 mintCount) public payable {
        uint256 supply = totalSupply();

        require(supply + mintCount <= _maxSupply,   "max_token_supply_exceeded");
        require(msg.value >= _price * mintCount,    "insufficient_payment_value");

        for (uint256 i = 1; i <= mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
        if (supply + mintCount == _maxSupply) {
            withdrawAll();
        }
    }

    /*
     * Mint reserved NFTs for giveaways, devs, etc.
     */
    function reserveMint(uint256 mintCount) public onlyOwner {
        uint256 supply = totalSupply();

        require(supply + mintCount <= _maxSupply,   "max_token_supply_exceeded");

        for (uint256 i = 1; i <= mintCount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPrice(uint256 price) public onlyOwner {
        _price = price;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(owner()).send(address(this).balance));
    }

    /**
   * Override isApprovedForAll to auto-approve OS's proxy contract
   */
    function isApprovedForAll(address _owner, address _operator) public override (ERC721, IERC721) view returns (bool isOperator) {
        // if OpenSea's ERC721 Proxy Address is detected, auto-return true
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            return true;
        }

        // otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
    * OC Operator filter
    **/
    /**
    * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override (ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override (ERC721, IERC721)  onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override (ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override (ERC721, IERC721)
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}