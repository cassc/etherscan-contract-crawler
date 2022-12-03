/**
 * 
 * '||\   /||` |''||''| '||   ||` |'''''/ |''||''| '||   ||` '||\   /||` 
    ||\\.//||     ||     ||   ||      //     ||     ||   ||   ||\\.//||  
    ||     ||     ||     ||   ||     //      ||     ||   ||   ||     ||  
    ||     ||     ||     ||   ||    //       ||     ||   ||   ||     ||  
   .||     ||. |..||..|  `|...|'  /.....| |..||..|  `|...|'  .||     ||. 
 *                                                                   
 *                                                                    
**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "closedsea/src/OperatorFilterer.sol";
import "./IERC2981.sol";

/**
 * @title MiuziumNFT
 */
contract MiuziumNFT is ERC721, Ownable, ReentrancyGuard, OperatorFilterer {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    mapping(address => bool) private _minters;
    mapping(string => uint256) public _prices;
    mapping(string => bytes32) private _merkleRoots;
    mapping(string => address) private _pieces;
    mapping(uint256 => string) private _idToMetadata;
    mapping(string => uint256) public _metadataToId;
    mapping(address => uint256) public _minterVault;
    mapping(address => uint256) public _bidderVault;
    mapping(string => Auction) public _auctions;
    mapping(string => mapping(uint256 => Offer)) private _offers;
    mapping(string => uint256) private _offersCounter;
    bool public salesActive = false;
    bool public connectionRevealed = false;
    string public contractIpfsJson;
    string public contractBaseUri = "https://api.miuzium.io/nfts/";
    string private unrevealedNft = "UnrevealedIpfsHash";
    address public vaultAddress;
    uint256 public _baseRoyaltiesPercentage = 5;
    mapping(address => uint256) public _royaltiesPercentages;
    // Auctions
    struct Offer {
        uint256 offer;
        address from;
        uint40 timestamp;
        bool revoked;
        bool accepted;
    }
    struct Auction {
        uint256 reserve;
        address from;
        uint40 start;
        uint40 end;
        bool ended;
    }

    event Prepared(address creator, string metadata);
    event Placed(string metadata, uint256 offer, uint256 value);
    event Accepted(string metadata, uint256 offer, uint256 value);
    event Revoked(string metadata, uint256 offer);

    constructor(
        string memory _name,
        string memory _ticker,
        string memory _contractIpfs
    ) ERC721(_name, _ticker) {
        contractIpfsJson = _contractIpfs;
    }

    function _baseURI() internal view override returns (string memory) {
        return contractBaseUri;
    }

    function contractURI() external view returns (string memory) {
        return contractIpfsJson;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        if (connectionRevealed) {
            string memory _tknId = _idToMetadata[_tokenId];
            return string(abi.encodePacked(contractBaseUri, _tknId));
        } else {
            return unrevealedNft;
        }
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTkns = totalSupply();
            uint256 resultIndex = 0;
            uint256 tnkId;

            for (tnkId = 1; tnkId <= totalTkns; tnkId++) {
                if (ownerOf(tnkId) == _owner) {
                    result[resultIndex] = tnkId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function fixStrings(uint256 _what, string memory _newString)
        external
        onlyOwner
    {
        if (_what == 0) {
            contractIpfsJson = _newString;
        } else if (_what == 1) {
            contractBaseUri = _newString;
        } else if (_what == 2) {
            unrevealedNft = _newString;
        }
    }

    function fixBools(
        uint8 _what,
        address _address,
        bool _state
    ) external onlyOwner {
        if (_what == 0) {
            _minters[_address] = _state;
        } else if (_what == 1) {
            salesActive = _state;
        } else if (_what == 2) {
            connectionRevealed = _state;
        }
    }

    function fixVault(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Can't use black hole.");
        vaultAddress = newAddress;
    }

    function fixMerkleRoot(string memory _metadata, bytes32 root)
        external
        onlyOwner
    {
        _merkleRoots[_metadata] = root;
    }

    function isMinter(address _toCheck) public view returns (bool) {
        return _minters[_toCheck];
    }

    /*
        This method will return royalty info
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_tokenId > 0, "Asking royalties for non-existent token");
        string memory metadata = _idToMetadata[_tokenId];
        address creator = _pieces[metadata];
        uint256 percentage = _baseRoyaltiesPercentage;
        address finalReceiver = vaultAddress;
        if (_royaltiesPercentages[creator] > 0) {
            percentage = _royaltiesPercentages[creator];
            finalReceiver = creator;
        }
        uint256 _royalties = (_salePrice * percentage) / 100;
        return (finalReceiver, _royalties);
    }

    /*
        This method will allow owner to fix royalties receiver
    */
    function fixRoyaltiesParams(
        uint256 newRoyaltiesPercentage,
        address creatorAddress
    ) external onlyOwner {
        _royaltiesPercentages[creatorAddress] = newRoyaltiesPercentage;
    }

    /*
        This method will return the whitelisting state for a proof
    */
    function isWhitelisted(
        bytes32[] calldata _merkleProof,
        address _address,
        string memory _metadata
    ) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(_address));
        bool whitelisted = MerkleProof.verify(
            _merkleProof,
            _merkleRoots[_metadata],
            leaf
        );
        return whitelisted;
    }

    /*
        This method will allow minters to prepare an NFT
     */
    function prepareNFT(string memory _metadata) external {
        require(
            isMinter(msg.sender) && _pieces[_metadata] == address(0),
            "Not a minter or piece exists"
        );
        _pieces[_metadata] = msg.sender;
        emit Prepared(msg.sender, _metadata);
    }

    /*
        This method will allow users to drop nft for free
    */
    function dropNFT(string memory _metadata, address _receiver) external {
        require(
            _pieces[_metadata] == msg.sender && _metadataToId[_metadata] == 0,
            "Not the owner or NFT minted yet"
        );
        _tokenIdCounter.increment();
        uint256 nextId = _tokenIdCounter.current();
        _idToMetadata[nextId] = _metadata;
        _metadataToId[_metadata] = nextId;
        _mint(_receiver, nextId);
    }

    /*
        This method will allow minters to prepare an NFT
     */
    function sellNFT(string memory _metadata, uint256 _price) external {
        require(isMinter(msg.sender), "Only minters can sell NFTs");
        require(
            _auctions[_metadata].start == 0,
            "An auction exists yet for this token"
        );
        require(
            _pieces[_metadata] == msg.sender && _metadataToId[_metadata] == 0,
            "This piece don't exists, you're not the owner or metadata was minted yet"
        );
        _prices[_metadata] = _price;
    }

    /*
        This method will allow users to buy the nft
    */
    function buyNFT(string memory _metadata, bytes32[] calldata _merkleProof)
        external
        payable
    {
        bool canMint = true;
        if (uint256(_merkleRoots[_metadata]) != 0) {
            canMint = isWhitelisted(_merkleProof, msg.sender, _metadata);
        }
        
        require(salesActive, "Sell not active");
        require(_prices[_metadata] > 0, "Not selling the item");
        require(canMint, "Not in whitelist, can't mint");
        require(msg.value == _prices[_metadata], "Price is not correct");
        require(_metadataToId[_metadata] == 0, "Item already minted");
        require(_pieces[_metadata] != address(0), "Item doesn't exists");
        require(_pieces[_metadata] != msg.sender, "Can't buy from yourself");

        _tokenIdCounter.increment();
        address creator = _pieces[_metadata];
        uint256 nextId = _tokenIdCounter.current();
        _idToMetadata[nextId] = _metadata;
        _metadataToId[_metadata] = nextId;
        _minterVault[creator] += msg.value;
        _mint(msg.sender, nextId);
    }

    /*
        This method will allow users to buy the nft through Crossmint.io
    */
    function crossmint(string memory _metadata, address _to) external payable {
        require(
            msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
            "Only crossmint can buy from there"
        );
        
        require(salesActive, "Sell not active");
        require(_prices[_metadata] > 0, "Not selling the item");
        require(msg.value == _prices[_metadata], "Price is not correct");
        require(_metadataToId[_metadata] == 0, "Item already minted");
        require(_pieces[_metadata] != address(0), "Item doesn't exists");
        require(_pieces[_metadata] != msg.sender, "Can't buy from yourself");

        _tokenIdCounter.increment();
        address creator = _pieces[_metadata];
        uint256 nextId = _tokenIdCounter.current();
        _idToMetadata[nextId] = _metadata;
        _metadataToId[_metadata] = nextId;
        _minterVault[creator] += msg.value;
        _mint(_to, nextId);
    }

    /*
        This method will fix reserve price (start an auction)
     */
    function startAuction(
        string memory _metadata,
        uint256 _reservePrice,
        uint256 _startAuction,
        uint256 _endAuction
    ) public {
        require(
            msg.sender == _pieces[_metadata],
            "Only owner can start auctions"
        );
        require(
            _auctions[_metadata].start == 0,
            "An auction exists yet for this token"
        );
        require(
            _startAuction > block.timestamp,
            "Auction can't start in the past"
        );
        require(
            _startAuction < _endAuction,
            "Auction can't end before the start"
        );
        require(_metadataToId[_metadata] == 0, "NFT was minted yet");
        require(
            _prices[_metadata] == 0,
            "There's a fixed price sale, can't start auction"
        );
        // Setting auction
        _auctions[_metadata].reserve = _reservePrice;
        _auctions[_metadata].start = uint40(_startAuction);
        _auctions[_metadata].end = uint40(_endAuction);
        _auctions[_metadata].from = msg.sender;
    }

    function stopAuction(string memory _metadata) public {
        require(
            msg.sender == _pieces[_metadata],
            "Only owner can stop auction"
        );
        require(_metadataToId[_metadata] == 0, "NFT was minted yet");
        // Resetting auction
        delete _auctions[_metadata];
    }

    /*
        This method will allow users to bid on the nft
    */
    function makeBid(string memory _metadata) public payable {
        require(
            _metadataToId[_metadata] == 0 &&
                _auctions[_metadata].ended == false,
            "Auction no longer valid"
        );
        uint256 reservePrice = _auctions[_metadata].reserve;
        require(reservePrice > 0, "This NFT is not in auction");
        require(
            block.timestamp > _auctions[_metadata].start,
            "Auction isn't started"
        );
        require(block.timestamp < _auctions[_metadata].end, "Auction is ended");
        uint256 lastIndex = _offersCounter[_metadata];
        if (lastIndex > 0) {
            uint256 lastOffer = 0;
            while (lastOffer == 0) {
                Offer memory last = _offers[_metadata][lastIndex];
                if (last.revoked == false) {
                    lastOffer = last.offer;
                } else {
                    lastIndex--;
                }
            }
            require(
                lastOffer < msg.value,
                "Can't make an offer lower than last"
            );
        }
        require(
            msg.value > reservePrice,
            "Can't offer less than reserve price"
        );
        require(
            _pieces[_metadata] != msg.sender,
            "Can't make an offer to yourself"
        );
        _offersCounter[_metadata]++;
        uint256 offerId = _offersCounter[_metadata];
        _offers[_metadata][offerId].timestamp = uint40(block.timestamp);
        _offers[_metadata][offerId].offer = msg.value;
        _offers[_metadata][offerId].from = msg.sender;
        _bidderVault[msg.sender] += msg.value;
        emit Placed(_metadata, offerId, msg.value);
    }

    /*
        This method will allow bidders to revoke bids
    */
    function revokeBid(string memory _metadata, uint256 _offer)
        external
        nonReentrant
    {
        require(
            _offers[_metadata][_offer].from == msg.sender &&
                !_offers[_metadata][_offer].revoked,
            "Can't revoke the bid, not the owner or revoked yet"
        );
        require(
            _bidderVault[msg.sender] >= _offers[_metadata][_offer].offer &&
                _offers[_metadata][_offer].accepted == false,
            "Can't withdraw, bid was accepted"
        );
        bool success;
        (success, ) = payable(msg.sender).call{
            value: _offers[_metadata][_offer].offer
        }("");
        require(success, "Withdraw to user failed");
        _bidderVault[msg.sender] -= _offers[_metadata][_offer].offer;
        _offers[_metadata][_offer].revoked = true;
        emit Revoked(_metadata, _offer);
    }

    // Returns the index of the highest offer for `_metadata`
    function returnLastOffer(string memory _metadata)
        external
        view
        returns (uint256)
    {
        uint256 lastIndex = _offersCounter[_metadata];
        if (lastIndex > 0) {
            uint256 lastOffer = 0;
            while (lastOffer == 0) {
                Offer memory last = _offers[_metadata][lastIndex];
                if (last.revoked == false) {
                    lastOffer = last.offer;
                } else {
                    lastIndex--;
                }
            }
        }
        return lastIndex;
    }

    // Returns the offer amount for `_metadata` at `_offer` index.
    function returnOffer(string memory _metadata, uint256 _offer)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        Offer memory offer = _offers[_metadata][_offer];
        return (
            offer.from,
            offer.offer,
            offer.timestamp,
            offer.revoked,
            offer.accepted
        );
    }

    /*
        Accept offer
    */
    function acceptOffer(string memory _metadata, uint256 _offer) external {
        require(_metadataToId[_metadata] == 0, "Auction no longer valid");
        require(_pieces[_metadata] == msg.sender, "Only owner can accept");
        Offer memory offer = _offers[_metadata][_offer];
        require(
            offer.offer > 0 && !offer.revoked,
            "This offer doesn't exists or was revoked"
        );
        _offers[_metadata][_offer].accepted = true;
        _bidderVault[offer.from] -= offer.offer;
        _minterVault[_pieces[_metadata]] += offer.offer;
        _auctions[_metadata].ended = true;
        // Mint the nft
        _tokenIdCounter.increment();
        uint256 nextId = _tokenIdCounter.current();
        _idToMetadata[nextId] = _metadata;
        _metadataToId[_metadata] = nextId;
        _mint(offer.from, nextId);
        emit Accepted(_metadata, _offer, offer.offer);
    }

    // Withdraws the earnings earned by the minter.
    function withdrawFromVault() external nonReentrant {
        require(
            isMinter(msg.sender) && _minterVault[msg.sender] > 0,
            "Not a minter or no balance"
        );
        bool success;
        (success, ) = payable(msg.sender).call{value: _minterVault[msg.sender]}(
            ""
        );
        require(success, "Recipient failed to receive");
        _minterVault[msg.sender] = 0;
    }

    // ERC721 function overrides for operator filtering to enable OpenSea creator royalities.

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}