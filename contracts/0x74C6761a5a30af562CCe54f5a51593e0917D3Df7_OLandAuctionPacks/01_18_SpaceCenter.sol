// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// contract interface
interface OfriendContractInterface {
  function ownerOf(uint256 _tokenId) external view returns (address);
  function approve(address to, uint256 _tokenId) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
}

interface PackContractInterface {
  function openPack(uint256 packId) external view;
  function ownerOf(uint256 packId) external view;
  function mintFutureLandsWithAmount(address to, uint256 amount, uint256 packId) external;
}


contract OLandAuctionPacks is ReentrancyGuard, ERC721, ERC721Burnable, ERC721Enumerable, Pausable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public OFriendAstronauts;
    Counters.Counter private _publicCounter;
      
    struct SpaceWalk {
        uint256 startBlock;  
        uint256 endBlock;    
        bool isWalking;  
        address owner;
    }

    bool public canGetPack;
    mapping(uint256 => bool) OfriendMinted;
    mapping (uint256 => SpaceWalk) private _spaceWalk;

    uint256 public constant CLOSE_PRICE_BASE = 10_00000000000000;
    uint256 public publicClosePrice = 10_00000000000000;
    uint256 public _missionId = 1;
    uint256 public _missionIdStart = 0;
    uint256 public _missionIdEnd = 5;
    uint256 public _maxPublicSupply = 16000;
    address public _ofriendContractAddress;
    address public _PackContractAddress;    
    uint256 private _closePriceRate = 1; 
    address private _localAddress;
    string private _baseTokenURI; 
    uint256 private supply = 6200;

    OfriendContractInterface OfriendContract;
    PackContractInterface PackContract;

    constructor() ERC721("oLand Auction Packs", "AUCTION PACK") {}

    function setOfriendContract(address _newOfriendAddress) public onlyOwner {
       _ofriendContractAddress = _newOfriendAddress;
       OfriendContract = OfriendContractInterface(_ofriendContractAddress);
    }

    function setLocalAddress(address _address) public onlyOwner {
       _localAddress = _address;
    }

    function setPackContract(address _newPackAddress) public onlyOwner {
       _PackContractAddress = _newPackAddress;
       PackContract = PackContractInterface(_PackContractAddress);
    }

    function totalSupply() public view override returns (uint256) {
        return supply;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        _baseTokenURI = baseURI_;
    }

    function setMission(uint256 missionId_, uint256 missionIdStart_, uint256 missionIdEnd_) external onlyOwner {
        _missionId = missionId_;
        _missionIdStart = missionIdStart_;
        _missionIdEnd = missionIdEnd_;
    }

    function setMaxPublicSupply(uint256 publicSupply) external onlyOwner {
        _maxPublicSupply = publicSupply;
    }

    function getMissionSuccess(uint256 missionMinimum) public view returns (bool) {
        uint256 tokenIdCurrent = OFriendAstronauts.current();
        if (tokenIdCurrent < missionMinimum) return false;
        return true;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert("Withdraw failure.");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function openPack(uint256 packId) public nonReentrant() {
        if (msg.sender != ownerOf(packId)) {
            if (msg.sender != owner()) revert("Must own pack.");
        }
        PackContract.openPack(packId);
        _burn(packId);
    }

    function toggleCanGetPack() external onlyOwner {
        canGetPack = !canGetPack;
    }

    function openPackLand(uint256 packId, address to, uint256 amount) public nonReentrant() {
        if (msg.sender != ownerOf(packId)) {
            if (msg.sender != owner()) revert("Must own pack for claim.");
        }
        // 0x34d85c9cdeb23fa97cb08333b511ac86e1c4e258 // use proxy after pack mint and futureMinter contract
        PackContract.mintFutureLandsWithAmount(to, amount, packId);
        _burn(packId);
    }

    function startSpaceWalk(uint256 oFriendTokenId) external nonReentrant() {
        address to = OfriendContract.ownerOf(oFriendTokenId);
        if (to != msg.sender) {
            if (msg.sender != owner()) revert("Must own oFriend");
        }

        uint256 OfriendMissionId;
        unchecked {
            OfriendMissionId = _missionId + oFriendTokenId;
        }
     
        if (!OfriendMinted[OfriendMissionId]) {
            if (msg.sender != owner()) revert("oFriend is not an astronaut!");
        }

        _spaceWalk[oFriendTokenId].startBlock = block.number;
        _spaceWalk[oFriendTokenId].endBlock = 0;
        _spaceWalk[oFriendTokenId].isWalking = true;
        _spaceWalk[oFriendTokenId].owner = msg.sender;
        OfriendContract.transferFrom(msg.sender, address(this), oFriendTokenId);

    }

     function stopSpaceWalk(uint256 oFriendTokenId) public nonReentrant() {
     
        if (!_spaceWalk[oFriendTokenId].isWalking) revert("Not walking!");

        if (_spaceWalk[oFriendTokenId].owner == msg.sender) {
            _spaceWalk[oFriendTokenId].endBlock = block.number;
            _spaceWalk[oFriendTokenId].isWalking = false;
            OfriendContract.transferFrom(address(this), msg.sender, oFriendTokenId);
        }

    }

    function getWalkDistance (uint256 oFriendTokenId) public view returns (uint256) {

        uint256 walked = 0;
        if (_spaceWalk[oFriendTokenId].endBlock > 0) return walked;
        unchecked {
            walked = block.number - _spaceWalk[oFriendTokenId].startBlock;
        }
        return walked;

    }

    function boardRocket(uint256 oFriendTokenId) public nonReentrant() {
        address to = OfriendContract.ownerOf(oFriendTokenId);
        if (to != msg.sender) {
            if (msg.sender != owner()) revert("Must own oFriend");
        }
        if (oFriendTokenId < 10000) {
            if (msg.sender != owner()) revert("oFriend must be out of house");
        }

        uint256 tokenIdCurrent = OFriendAstronauts.current();
        uint256 tokenId;
        uint256 OfriendMissionId;

        unchecked {
            tokenId = _missionId + tokenIdCurrent;
            OfriendMissionId = _missionId + oFriendTokenId;
        }

        if (OfriendMinted[OfriendMissionId]) {
            if (msg.sender != owner()) revert("oFriend already boarded mission");
        }
        OfriendMinted[OfriendMissionId] = true;
        OFriendAstronauts.increment();
        if (_missionIdEnd < tokenIdCurrent) {
            if (msg.sender != owner()) revert("Mission unavailable.");
        }
        _safeMint(to, tokenId);
    }

    function setPublicClosePrice(uint256 price) external onlyOwner {
        publicClosePrice = price;
    }

    function getPack() public payable nonReentrant() {
        if (tx.origin != msg.sender) revert("Sender must be origin.");
        if (!canGetPack) revert("Get pack is not available");

        _publicCounter.increment();
        uint256 currentTokenId = _publicCounter.current();
        uint256 tokenId;
        unchecked {
            tokenId = _missionIdEnd + currentTokenId;
        }
        if (currentTokenId + 1 > _maxPublicSupply) revert("Max supply reached.");
        _safeMint(msg.sender, tokenId);
        _refundOverPayment(publicClosePrice);
        if (publicClosePrice != 0) {
            uint256 closePriceIncrement;
            unchecked {
                closePriceIncrement = _closePriceRate * CLOSE_PRICE_BASE;
                publicClosePrice += closePriceIncrement;
            }
        }
        
    }

    function mintPack(address to) public onlyOwner {
        _publicCounter.increment();
        uint256 currentTokenId = _publicCounter.current();
        uint256 tokenId;
        unchecked {
            tokenId = _missionIdEnd + currentTokenId;
        }
        if (currentTokenId + 1 > _maxPublicSupply) revert("Max supply reached");
        _safeMint(to, tokenId);
    }

    function _refundOverPayment(uint256 amount) internal {
        if (msg.value < amount) revert();
        if (msg.value > amount) {
            payable(msg.sender).transfer(msg.value - amount);
        }
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = OFriendAstronauts.current();
        OFriendAstronauts.increment();
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}