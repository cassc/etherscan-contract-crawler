//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

interface IJIngle {
    function transfer(address _to, uint256 _tokenId) external virtual;
}

/// @title A wrapped contract for CryptoJingles V0 and V1 (Only 2018 mints)
contract OGWrappedJingle is ERC721URIStorage, Ownable {

    event Wrapped(address indexed, uint256 indexed, uint256, address);
    event Unwrapped(address indexed, uint256 indexed, uint256, address);

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    enum Version { V0, V1 }

    uint256 constant public NUM_V0_JINGLES = 30;
    uint256 constant public NUM_V1_JINGLES = 47;
    struct JingleToken {
        uint256 tokenId;
        address jingleContract;
        bool isWrapped;
    }

    mapping (uint256 => JingleToken) public wrappedToUnwrapped;
    
    mapping (uint256 => mapping (address => uint256)) public unwrappedToWrapped;

    constructor() ERC721("Genesis Jingles", "GJ") {}

    /// @notice Locks an old v0/v1 jingle and gives the user a wrapped jingle
    /// @dev User must approve the contract to withdraw the asset
    /// @param _tokenId Token id of the asset to be wrapped
    /// @param _version 0 - v0 version, 1 - v1 version
    function wrap(uint256 _tokenId, Version _version) public {
        address jingleContract = getJingleAddr(_version);
        address tokenOwner = IERC721(jingleContract).ownerOf(_tokenId);

        // check if v0 can wrap
        require(wrapCheck(_tokenId, _version), "Wrap check not passed");

        // check if user is owner
        require(tokenOwner == msg.sender, "Not token owner");

        // pull user jingle
        IERC721(jingleContract).transferFrom(msg.sender, address(this), _tokenId);

        uint256 wrappedTokenId;

        if (unwrappedToWrapped[_tokenId][jingleContract] == 0) { // mint new wrapped token
            wrappedTokenId = mintNewToken();
            unwrappedToWrapped[_tokenId][jingleContract] = wrappedTokenId;
        } else { 
            // re-use the old wrapped id for the same jingle
            wrappedTokenId = unwrappedToWrapped[_tokenId][jingleContract];

            require(ownerOf(wrappedTokenId) == address(this), "Wrapper must be owner");
            _transfer(address(this), msg.sender, wrappedTokenId);
        }

        wrappedToUnwrapped[wrappedTokenId] = JingleToken({
            tokenId: _tokenId,
            jingleContract: jingleContract,
            isWrapped: true
        });

        emit Wrapped(msg.sender, wrappedTokenId, _tokenId, jingleContract);
    }


    /// @notice Unlocks an old v0/v1 jingle and burnes the users wrapped jingle
    /// @param _wrappedTokenId Token id of the wrapped jingle
    /// @param _version 0 - v0 version, 1 - v1 version
    function unwrap(uint256 _wrappedTokenId, Version _version) public {
        // check if user is owner
        address jingleContract = getJingleAddr(_version);
        address tokenOwner = ownerOf(_wrappedTokenId);

        require(tokenOwner == msg.sender, "Not token owner");

        // pull the wrapped token to the contract
        transferFrom(msg.sender, address(this), _wrappedTokenId);

        JingleToken memory tokenData = wrappedToUnwrapped[_wrappedTokenId];

        require(tokenData.isWrapped, "Token not wrapped");

        tokenData.isWrapped = false;
        wrappedToUnwrapped[_wrappedTokenId] = tokenData;

        // send token to caller
        IJIngle(jingleContract).transfer(msg.sender, tokenData.tokenId);

        emit Unwrapped(msg.sender, _wrappedTokenId, tokenData.tokenId, jingleContract);
    }

    function mintNewToken() internal returns (uint256) {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);

        return newItemId;
    }

    function wrapCheck(uint256 _tokenId, Version _version) internal pure returns (bool) {
        if (_version == Version.V0) {
            if (_tokenId <= NUM_V0_JINGLES) return true;
        }

        if (_version == Version.V1) {
            if (_tokenId <= NUM_V1_JINGLES) return true;
        }

        return false;
    }

    function getJingleAddr(Version _version) internal pure returns (address) {
        if (_version == Version.V0) {
            return 0x5AF7Af54E8Bc34b293e356ef11fffE51d6f9Ae78;
        } else {
            return 0x5B6660ca047Cc351BFEdCA4Fc864d0A88F551485;
        }
    }

    /////////////////// PUBLIC ////////////////////////

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(uint256 _tokenId) public pure override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    function baseTokenURI() public pure returns (string memory) {
        return "https://cryptojingles.app/api/og-wrapped-jingles/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://cryptojingles.app/api/metadataOG";
    }
}