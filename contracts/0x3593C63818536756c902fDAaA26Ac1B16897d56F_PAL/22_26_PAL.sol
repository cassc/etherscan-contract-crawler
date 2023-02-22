// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// '########:::::'###::::'##:::::::
//  ##.... ##:::'## ##::: ##:::::::
//  ##:::: ##::'##:. ##:: ##:::::::
//  ########::'##:::. ##: ##:::::::
//  ##.....::: #########: ##:::::::
//  ##:::::::: ##.... ##: ##:::::::
//  ##:::::::: ##:::: ##: ########:
// ..:::::::::..:::::..::........::

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PAL is ERC721, ERC721Enumerable, ERC721Royalty, Ownable, DefaultOperatorFilterer, PaymentSplitter {
    error InvalidPrice(address emitter);
    error SaleNotStarted(address emitter);
    error SoldOut(address emitter);
    error EtherTransferFail(address emitter);

    event Sold(address indexed to, uint256 price, uint256 tokenId);
    event PermanentURI(string _value, uint256 indexed _id);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    using Strings for uint256;

    uint256 private constant STARTING_INDEX = 1;
    uint256 private currentMintTokenId = STARTING_INDEX;
    
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant PRICE = 3 ether;

    string public baseTokenUri;
    uint256 public saleStartTime;
    
    bool metadataFrozen = false;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenUri,
        uint256 _saleStartTime,
        address[] memory _premintReceivers,
        address _royalReceiver,
        uint96 _royalFeeNumerator,
        address[] memory payees, 
        uint256[] memory shares_
    ) payable ERC721(_name, _symbol) PaymentSplitter(payees, shares_) {
        baseTokenUri = _tokenUri;
        saleStartTime = _saleStartTime;
        
        for (uint256 i = 0; i < _premintReceivers.length; ++i) {
            _safeMint(_premintReceivers[i], currentMintTokenId);
            ++currentMintTokenId;
        }

        if (_royalReceiver != address(0)) {
            _setDefaultRoyalty(_royalReceiver, _royalFeeNumerator);
        }
    }

    function mint() public payable {
        if (totalSupply() >= MAX_SUPPLY) revert SoldOut(address(this));
        if (block.timestamp < saleStartTime) {
            revert SaleNotStarted(address(this));
        }

        if (msg.value != PRICE) revert InvalidPrice(address(this));

        emit Sold(msg.sender, PRICE, currentMintTokenId);
        _safeMint(msg.sender, currentMintTokenId);
        ++currentMintTokenId;
    }
    
    function mintRemaining() public onlyOwner() {
        while(totalSupply() < MAX_SUPPLY) {
            _safeMint(msg.sender, currentMintTokenId);
            ++currentMintTokenId;
        }
    }
    
    function freezeMetadata() public onlyOwner() {
        require(metadataFrozen == false, "Metadata already frozen");
        metadataFrozen = true;
        for (uint256 i = STARTING_INDEX; i <= totalSupply(); ++i) {
            emit PermanentURI(tokenURI(i), i);
        }
    }
    
    function setSaleStartTime(uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setBaseTokenUri(string calldata tokenUri) public onlyOwner {
        require(metadataFrozen == false, "Metadata frozen");
        emit BatchMetadataUpdate(STARTING_INDEX, totalSupply());
        baseTokenUri = tokenUri;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721)
    returns (string memory)
    {
        _requireMinted(tokenId);
        return string.concat(baseTokenUri, tokenId.toString(), ".json");
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        super._setDefaultRoyalty(receiver, feeNumerator);
    }

    function _beforeTokenTransfer(address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty, ERC721Enumerable)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

     function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}