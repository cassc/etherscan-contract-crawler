// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "./AmberIslandKey.sol";

contract AmberIslandBottles is ERC721, ERC721Royalty, AccessControl {
    using Counters for Counters.Counter;

    AmberIslandKey keysContract;
    bytes32 public constant RELEASE_ROLE = keccak256("RELEASE_ROLE");
    bytes32 public constant BOTTLE_STATE_ROLE = keccak256("BOTTLE_STATE_ROLE");

    enum BottleState {
        Closed,
        Opened,
        Redeemed
    }
    mapping(uint256 => BottleState) tokenIdToBottleState;

    struct Release {
        bool exists;
        string name;
        uint256 price;
        uint256 maxSupply;
        uint256 startTime;
        bool keyHoldersOnly;
        string uri;
        uint256 nextBottle;
        uint256 royalties;
        BottleState defaultState;
    }
    uint256 releaseId = 1000000;
    mapping(uint256 => Release) idToRelease;
    mapping(uint256 => mapping(uint256 => bool)) keyIdToReleaseMinted;
    mapping(uint256 => uint256) tokenIdToReleaseId;

    address feeRecipient = 0x8b375C1488cf58524Bacc962a2BE732189906739;

    event ReleaseCreated(Release release);

    modifier releaseExists(uint256 id) {
        require(idToRelease[id].exists, "AIB: Release does not exist");
        _;
    }

    constructor(address _keyContractAddress) ERC721("AmberIslandBottle", "AIB") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(RELEASE_ROLE, msg.sender);
        _grantRole(BOTTLE_STATE_ROLE, msg.sender);
        keysContract = AmberIslandKey(_keyContractAddress);
    }

    function safeMint(uint256 release, address to, bool includeKey, uint256 keyTokenId) releaseExists(release) payable public {
        Release storage bottle = idToRelease[release];
        uint256 bottleCount = bottle.nextBottle;
        require(bottleCount <= bottle.maxSupply, "AIB: All bottles minted");
        require(bottle.startTime <= block.timestamp, "AIB: Release not unlocked yet");
        
        if(includeKey) {
            uint256 keyPrice = keysContract.getMintPrice();
            require(msg.value == bottle.price + keyPrice, "AIB: Invalid value for bottle and key");
            keyTokenId = keysContract.getCurrentTokenId();
            keysContract.publicMint{ value: keyPrice }(to, 1);
        } else {
            require(msg.value == bottle.price, "AIB: Invalid value for bottle");
        }

        if(bottle.keyHoldersOnly) {
            require(keysContract.ownerOf(keyTokenId) == to, "AIB: Key not owned by recipient");
            require(!keyIdToReleaseMinted[keyTokenId][release], "AIB: Key already used for this bottle");

            keyIdToReleaseMinted[keyTokenId][release] = true;
        }

        uint256 tokenId = 10000000000 + release + bottleCount;
        idToRelease[release].nextBottle = bottleCount + 1;
        _safeMint(to, tokenId);

        tokenIdToBottleState[tokenId] = bottle.defaultState;
        tokenIdToReleaseId[tokenId] = release;

        (bool sent, bytes memory data) = feeRecipient.call{value: bottle.price}("");
        require(sent, "AIB: Failed to send Ether");
    }

    function createRelease(string memory _name, uint256 _price, uint256 _maxSupply, uint256 _startTime, bool _keyHoldersOnly, string memory _uri, uint256 _royalties, BottleState _defaultState) 
        public 
        onlyRole(RELEASE_ROLE)
    {
        idToRelease[releaseId] = Release(
            true,
            _name,
            _price,
            _maxSupply,
            _startTime,
            _keyHoldersOnly,
            _uri,
            1,
            _royalties,
            _defaultState
        );

        emit ReleaseCreated(idToRelease[releaseId]);
        
        releaseId = releaseId + 1000000;
    }

    function getReleaseDetails(uint256 release) public view releaseExists(release) returns (Release memory) {
        Release memory details = idToRelease[release];
        return details;
    }

    function withdraw() 
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setBottlePrice(uint256 release, uint256 price) public onlyRole(RELEASE_ROLE) {
        idToRelease[release].price = price;
    }

    function setBottleStartTime(uint256 release, uint256 timestamp) public onlyRole(RELEASE_ROLE) {
        idToRelease[release].startTime = timestamp;
    }

    function setBottleUri(uint256 release, string memory uri) public onlyRole(RELEASE_ROLE) {
        idToRelease[release].uri = uri;
    }

    function bulkSetBottleState(uint256[] memory tokenIds, BottleState state) public onlyRole(BOTTLE_STATE_ROLE) {
        for(uint32 i = 0; i < tokenIds.length; i++) {
            tokenIdToBottleState[tokenIds[i]] = state;
        }
    }

    function getPrice(uint256 release, bool includeKey) releaseExists(release) public view returns (uint256) {
        uint256 price = idToRelease[release].price;

        if(includeKey) {
            uint256 keyPrice = keysContract.getMintPrice();
            price = price + keyPrice;
        }

        return price;
    }

    function getKeyUsedForRelease(uint256 release, uint256 keyTokenId) public view returns (bool) {
        return keyIdToReleaseMinted[keyTokenId][release];
    }

    function getCurrentTokenId(uint256 release) releaseExists(release) public view returns (uint256) {
        return idToRelease[release].nextBottle;
    }

    function getCurrentReleaseId() public view returns (uint256) {
        return releaseId;
    }

    function setFeeRecipient(address _recipient) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeRecipient = _recipient;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        Release storage bottle = idToRelease[tokenIdToReleaseId[tokenId]];

        string memory state;
        BottleState bottleState = tokenIdToBottleState[tokenId];
        if(bottleState == BottleState.Closed) state = "/prereveal.json";
        else if(bottleState == BottleState.Opened) state = "/revealed.json";
        else if(bottleState == BottleState.Redeemed) state = "/redeemed.json";

        return string.concat(bottle.uri, state);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Royalty, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721Royalty) {}

}