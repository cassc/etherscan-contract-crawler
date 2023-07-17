// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";


contract PepeThePunk is
ERC721,
ERC2981,
RevokableDefaultOperatorFilterer,
Ownable,
ReentrancyGuard
{
    using Strings for uint;
    using Counters for Counters.Counter;
    // increasing size by 1 to optimise mint
    uint256 public maxTokensPerAddress = 31;
    uint256 public maxTokensPerTxn = 11;
    //  66 reserved for team and promotion
    uint public maxPublicSupply = 6600;
    uint public maxSupply = 6666;
    uint256 public price = 0.0033 ether;
    string public _provenance;
    bool public revealed;
    bool public isPublicSaleActive;
    string public baseURI;
    string public baseExtension;
    uint public _reserveTokenId = maxPublicSupply;
    mapping(address => uint) public tokensMintedByAddress;
    Counters.Counter private _tokenId;
    constructor() ERC721("PepeThePunk", "PTP") {}
    function totalSupply() public view virtual returns(uint) {
        return _tokenId.current() + _reserveTokenId - maxPublicSupply;
    }
    function mint(uint _mintAmount) public payable {
        require(isPublicSaleActive, "Public Sale is not active");
        require(_mintAmount < maxTokensPerTxn, "Too many per TX");
        require(tokensMintedByAddress[msg.sender] + _mintAmount < maxTokensPerAddress, "Max tokens minted for this address");
        require(_tokenId.current() + _mintAmount <= maxPublicSupply, "Max public supply exceeded");
        require(price * _mintAmount == msg.value, "Not enough ETH");
        for (uint i = 0; i < _mintAmount; i++) {
            _tokenId.increment();
            _safeMint(msg.sender, _tokenId.current());
        }
        tokensMintedByAddress[msg.sender] += _mintAmount;
    }
    function giveaway(address _to, uint _mintAmount) public onlyOwner {
        require(_reserveTokenId + _mintAmount <= maxSupply, "Max reserve supply exceeded");
        for (uint i = 0; i < _mintAmount; i++) {
            _reserveTokenId++;
            _safeMint(_to, _reserveTokenId);
        }
    }
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }
    function setSaleDetails(
        uint _maxTokensPerAddress,
        uint _price
    ) public onlyOwner {
        maxTokensPerAddress = _maxTokensPerAddress;
        price = _price;
    }
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenance = provenanceHash;
    }
    function setPublicSaleActive(bool _state) public onlyOwner {
        isPublicSaleActive = _state;
    }
    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdrawal of funds failed");
    }
    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}