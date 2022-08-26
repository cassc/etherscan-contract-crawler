// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RowdyKids is ERC721, ERC721Enumerable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    enum State {
        None,
        Sale,
        End
    }

    string internal baseURI;
    string public provenance;

    State public state = State.Sale;
    uint256 public saleStartTime = 1662379200;

    Counters.Counter private _tokenIdCounter;
    uint256 public maxFreeMint = 2;
    uint256 public exceedMintPrice = 0.01 ether;
    uint256 public maxTokenSupply = 10000;
    uint256 public constant MAX_MINTS_PER_TX = 10;
    
    mapping (address => uint256) private _freeMinted;
    
    constructor() ERC721("RowdyKids", "RKT") {
    }

    function setMaxTokenSupply(uint256 _maxTokenSupply) public onlyOwner {
        maxTokenSupply = _maxTokenSupply;
    }
    
    function setMaxFreeMint(uint256 _maxFreeMint) public onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    function setExceedMintPrice(uint256 _exceedMintPrice) public onlyOwner {
        exceedMintPrice = _exceedMintPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /*     
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) public onlyOwner {
        provenance = _provenanceHash;
    }

    function setSaleStartTime( uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setSaleState(uint256 index) public onlyOwner {
        state = State(index);
    }

    /*
    * Public Sale Mint RowdyKids NFTs
    */
    function mint(uint _numberOfTokens) public payable nonReentrant {

        require(state == State.Sale, "NOT_SALE_STATE");
        require(block.timestamp >= saleStartTime, "NOT_SALE_TIME");
        require(_numberOfTokens <= MAX_MINTS_PER_TX, "MAX_MINT/TX_EXCEEDS");
        require(totalSupply() + _numberOfTokens <= maxTokenSupply, "SOLDOUT");

        uint256 availableFreeMints = 0;
        (, availableFreeMints) = SafeMath.trySub(maxFreeMint, _freeMinted[_msgSender()]);

        uint256 mintCost = 0;
        if( _numberOfTokens > availableFreeMints)
            mintCost = (_numberOfTokens - availableFreeMints) * exceedMintPrice;
        require(mintCost == msg.value, "PRICE_ISNT_CORRECT");

        _freeMinted[msg.sender] += _numberOfTokens;

        for(uint256 i = 0; i < _numberOfTokens; i++) {
            uint256 mintIndex = _tokenIdCounter.current() + 1;
            if (mintIndex <= maxTokenSupply) {
                _safeMint(msg.sender, mintIndex);
                _tokenIdCounter.increment();
            }
        }
    }

    /*
    * Mint reserved NFTs for giveaways, dev, etc.
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner nonReentrant {
        require(totalSupply() + reservedAmount <= maxTokenSupply);
        
        uint256 mintIndex = _tokenIdCounter.current() + 1;
        for (uint256 i = 0; i < reservedAmount; i++) {
            _safeMint(msg.sender, mintIndex + i);
            _tokenIdCounter.increment();
        }
    }

    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }
}