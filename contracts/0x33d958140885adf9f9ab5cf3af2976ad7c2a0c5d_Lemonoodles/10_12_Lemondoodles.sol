// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import { IERC721, ERC721, Strings } from "./ERC721.sol";
import { Ownable } from "./Ownable.sol";
import { ECDSA } from "./ECDSA.sol";

contract Lemonoodles is ERC721, Ownable {
    using Strings for uint;
    using ECDSA for bytes32;

    constructor(string memory baseUri_) ERC721("Lemonoodles", "LN") {
        _baseUri = baseUri_;
    }

    modifier directOnly {
        require(tx.origin == msg.sender, "EOA_ONLY");
        _;
    }

    /** Constants */

    /** RESERVED included in MAX_SUPPLY */
    uint constant MAX_SUPPLY = 7777;
    uint constant RESERVED = 20;
    uint constant COST_PER = 0.035 ether;
    uint constant MIN_ID = 1;
    uint constant MIN_GIVEAWAY_ID = MAX_SUPPLY - RESERVED + 1;

    uint constant MAX_PER_TX = 10;
    uint constant EACH_WHITELIST_AMOUNT = 2; /** There's a few different whitelist methods/collections, each one the user has will give them +2 mints */

    string constant ERROR_MAX_PUBLIC_SUPPLY = "The max public sale supply has been reached!";
    string constant ERROR_MAX_GIVEAWAY_SUPPLY = "The max giveaway supply has been reached!";
    string constant ERROR_INVALID_ETH = "Invalid ether amount sent!";
    string constant ERROR_OVER_MAX_PER_TX = "You can only mint up to 10 per transaction!";
    string constant ERROR_PUB_SALE_NOT_ACTIVE = "The public sale is not currently active!";
    string constant ERROR_WL_SALE_NOT_ACTIVE = "The whitelist sale is not currently active!";
    string constant ERROR_INVALID_SIGNATURE = "Invalid signature provided!";
    string constant ERROR_OVER_WL_MAX = "You can not mint that many using your whitelist!";

    /** Storage */

    uint _nextId = MIN_ID;
    uint _nextGiveawayId = MIN_GIVEAWAY_ID;

    bool _publicSale = false;
    bool _whitelistSale = false;
    bool public _metadataLocked = false;

    string _baseUri;

    address _signer = 0x402C5b659503ec988e4ad02F681f3C50F329e0b5;

    mapping(address => uint) public wlMintsOf;


    /** Minting */

    function publicMint(uint amount) external payable directOnly {
        unchecked {
            require(_publicSale, ERROR_PUB_SALE_NOT_ACTIVE);
            require(amount <= MAX_PER_TX, ERROR_OVER_MAX_PER_TX);
            require(totalSupplyPublic() + amount <= MAX_SUPPLY - RESERVED, ERROR_MAX_PUBLIC_SUPPLY);
            require(msg.value == amount * COST_PER, ERROR_INVALID_ETH);

            uint nextId_ = _nextId;
            for(uint i = 0; i < amount; i++) {
                _mint(msg.sender, nextId_ + i);
            }
            _nextId += amount;
        }
    }

    function whitelistMint(uint amount, uint maxMints, bytes memory signature) external payable directOnly {
        unchecked {
            require(_whitelistSale, ERROR_WL_SALE_NOT_ACTIVE);
            require(amount <= MAX_PER_TX, ERROR_OVER_MAX_PER_TX);
            require(totalSupplyPublic() + amount <= MAX_SUPPLY - RESERVED, ERROR_MAX_PUBLIC_SUPPLY);
            require(msg.value == amount * COST_PER, ERROR_INVALID_ETH);

            require(keccak256(abi.encode(msg.sender, maxMints)).toEthSignedMessageHash().recover(signature) == _signer, ERROR_INVALID_SIGNATURE);
            require(wlMintsOf[msg.sender] + amount <= maxMints, ERROR_OVER_WL_MAX);
            wlMintsOf[msg.sender] += amount;

            uint nextId_ = _nextId;
            for(uint i = 0; i < amount; i++) {
                _mint(msg.sender, nextId_ + i);
            }
            _nextId += amount;
        }
    }

    /** View */

    function totalSupplyPublic() public view returns(uint) {
        return _nextId - MIN_ID;
    }

    function totalSupplyPrivate() public view returns(uint) {
        return _nextGiveawayId - MIN_GIVEAWAY_ID;
    }

    function totalSupply() public view returns(uint) {
        return totalSupplyPublic() + totalSupplyPrivate();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_baseUri, tokenId.toString(), ".json"));
    }

    function publicSaleState() external view returns(bool) {
        return _publicSale;
    }

    function whitelistSaleState() external view returns(bool) {
        return _whitelistSale;
    }

    /** Admin Only */

    function adminMint(address[] calldata to) external onlyOwner {
        require(totalSupplyPrivate() + to.length <= RESERVED, ERROR_MAX_GIVEAWAY_SUPPLY);
        for(uint i = 0; i < to.length; i++)
            _mint(to[i], _nextGiveawayId++);
    }
    
    function setSaleStates(bool publicState, bool whitelistState) external onlyOwner {
        _publicSale = publicState;
        _whitelistSale = whitelistState;
    }

    function lockMetadata() external onlyOwner {
        _metadataLocked = true;
    }

    function setBaseUri(string calldata baseUri_) external onlyOwner {
        require(!_metadataLocked, "Metadata no longer mutable!");
        _baseUri = baseUri_;
    }

    address d1 = 0x0020bDe6b220ff86fcDe3528254996D22282CABB;
    address d2 = 0x1eE5481A04ffe6d13cA975fcF2005510350fA06E;
    address d3 = 0xDBEe7AD6c7D51994a09b655cA5a7b3104Edcc77b;
    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(d1).transfer((balance * 4) / 100);           // 4%
        payable(d2).transfer((balance * 3) / 100);           // 3%
        payable(d3).transfer(address(this).balance);         // Remaining balance (93%)
    }

    function emergencyWithdraw() external { // In case withdraw doesn't work for any reason, send all funds to d3, only callable by d1
        require(msg.sender == d1);
        payable(d3).transfer(address(this).balance);
    }
}