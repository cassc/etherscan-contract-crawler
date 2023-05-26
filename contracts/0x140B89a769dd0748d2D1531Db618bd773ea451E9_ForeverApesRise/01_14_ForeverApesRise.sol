// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ForeverApesRise is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    string public baseURI;
    uint256 public maxSupply = 5000;
    uint256 public saleState;
    uint256 public mintPrice = 0.07 ether;
    uint256 public preSaleLimit = 3400;
    string public provenanceHash;
    uint256 public start_index_time;
    uint256 public startingIndexBlock;
    uint256 public startingIndex;
    uint256 public maxMintPerTx = 20;
    Counters.Counter private _tokenIDs;

    mapping(address => uint256) private whileList;
    mapping(uint256 => bool) public redeemed;

    event redeemEvent(address indexed _from, uint256 indexed _id, bool _value);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /*
    Sale state is 0 and no minting should occur
    Sale state is 1 for pre sale/whitelist
    Sale state is 2 for Public sale 
    */
    function setSaleState(uint256 _state) public onlyOwner {
        saleState = _state;
    }

    /*
    Whitelist a set of users for presale. only 1 mint per whitelist
    */
    function whitelist(address[] memory _users, uint8 numAllowedToMint) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whileList[_users[i]] = numAllowedToMint;
        }
    }

    //unWhitelist addresses
    function unWhitelist(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whileList[_users[i]] = 0;
        }
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    /*
    Code to facilitate book redemptions and verify if a book has been claimed for a token. 
    The team will decide if this is the way to go.
    */
    function redeemBook(uint256 tokenId) public {
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner == msg.sender, "Only token owner can redeem");
        require(redeemed[tokenId] == false, "Book already redeemed with token");
        redeemed[tokenId] = true;
        emit redeemEvent(msg.sender, tokenId, true);
    }

    function preSaleMint(uint256 quantity) public payable {
        require(saleState == 1, "Pre Sale is not active");
        require(quantity > 0, "Requested quantity cannot be zero");
        require(
            quantity <= whileList[msg.sender],
            "Exceeded max available to purchase"
        );
        require(
            super.totalSupply() + quantity <= preSaleLimit,
            "Ran our of presale Mints"
        );
        require(quantity * mintPrice <= msg.value, "Not enough ether sent");
        whileList[msg.sender] -= quantity;
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenIDs.current());
            redeemed[_tokenIDs.current()] = false;
            _tokenIDs.increment();
        }
    }

    function whitelistQuanityAvailable(address user)
        external
        view
        returns (uint256)
    {
        return whileList[user];
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        provenanceHash = provenance;
    }

    function setTimestamp(uint256 revealTimeStamp) public onlyOwner {
        start_index_time = revealTimeStamp;
    }

    /**
     * Mint public
     */
    function mint(uint256 quantity) public payable {
        require(saleState == 2, "Public Sale is not active");
        require(quantity > 0, "Requested quantity cannot be zero");
        require(quantity <= maxMintPerTx, "Exceeded max tokens per tx");
        require(
            super.totalSupply() + quantity <= maxSupply,
            "Cannot exceed max supply"
        );
        require(quantity * mintPrice <= msg.value, "Not enough ether sent");
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, _tokenIDs.current());
            redeemed[_tokenIDs.current()] = false;
            _tokenIDs.increment();
        }
        if (
            startingIndexBlock == 0 &&
            (totalSupply() == maxSupply || block.timestamp >= start_index_time)
        ) {
            startingIndexBlock = block.number;
            startingIndex = startingIndexBlock % maxSupply;
        }
    }

    function setIndex() public onlyOwner {
        require(startingIndexBlock != 0, "Start Index needs to be set");
        startingIndexBlock = block.number;
        startingIndex = startingIndexBlock % maxSupply;
    }
}