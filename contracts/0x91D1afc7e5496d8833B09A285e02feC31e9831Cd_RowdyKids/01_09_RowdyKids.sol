// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RowdyKids is ERC721AQueryable, Ownable, ReentrancyGuard {

    enum State {
        None,
        Sale,
        End
    }

    State public state = State.Sale;

    string internal baseURI;
    uint256 public saleStartTime = 1662379200;
    uint256 public maxFreeMint = 2;
    uint256 public exceedMintPrice = 0.01 ether;
    uint256 public maxTokenSupply = 10000;
    uint256 public constant MAX_MINTS_PER_TX = 10;
    
    mapping (address => uint256) private _freeMinted;
    
    constructor() ERC721A("RowdyKids", "RKT") {
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

    function setSaleStartTime( uint256 _saleStartTime) public onlyOwner {
        saleStartTime = _saleStartTime;
    }

    function setSaleState(uint256 index) public onlyOwner {
        state = State(index);
    }

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /*
    * Public Sale Mint RowdyKids NFTs
    */
    function mint(uint256 _numberOfTokens) public payable nonReentrant {

        require(state == State.Sale, "NOT_SALE_STATE");
        require(block.timestamp >= saleStartTime, "NOT_SALE_TIME");
        require(_numberOfTokens <= MAX_MINTS_PER_TX, "MAX_MINT/TX_EXCEEDS");
        require(totalSupply() + _numberOfTokens <= maxTokenSupply, "SOLDOUT");

        uint256 availableFreeMints = 0;
        if(maxFreeMint > _freeMinted[_msgSender()])
            availableFreeMints = maxFreeMint - _freeMinted[_msgSender()];

        uint256 mintCost = 0;
        if( _numberOfTokens > availableFreeMints)
            mintCost = (_numberOfTokens - availableFreeMints) * exceedMintPrice;
        require(mintCost == msg.value, "PRICE_ISNT_CORRECT");

        _freeMinted[msg.sender] += _numberOfTokens;
        _safeMint(msg.sender, _numberOfTokens);
    }

    /*
    * Mint reserved NFTs for giveaways, dev, etc.
    */
    function reserveMint(uint256 reservedAmount) public onlyOwner nonReentrant {
        require(totalSupply() + reservedAmount <= maxTokenSupply, "EXCEED TOTAL SUPPLY");

        _safeMint(msg.sender, reservedAmount);
    }

    function withdrawAll() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }
}