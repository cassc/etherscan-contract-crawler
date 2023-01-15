// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MEME721 is
    AccessControlEnumerableUpgradeable,
    ERC2981,
    ERC721URIStorageUpgradeable
{
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 private constant MAX_BASE_SUPPLY = 1000000;

    string internal baseTokenURI;
    uint256 private _baseID;
    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => uint256) public tokenMaxSupply;
    mapping(uint256 => uint256) public currentTokenID;

    bytes32 public constant JUICING_ROLE = keccak256("JUICING_ROLE");

    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    function maxSupply(uint256 _id) public view returns (uint256) {
        return tokenMaxSupply[_id];
    }

    function create(uint256 _maxSupply) internal returns (uint256 tokenId) {
        require(_maxSupply < MAX_BASE_SUPPLY, "invalid supply");
        uint256 _baseTokenID = _getNextBaseID();
        _incrementBaseID();
        creators[_baseTokenID] = msg.sender;
        tokenSupply[_baseTokenID] = 0;
        tokenMaxSupply[_baseTokenID] = _maxSupply;
        return _baseTokenID;
    }

    function mint(address _to, uint256 _baseTokenID)
        internal
        returns (uint256)
    {
        require(
            creators[_baseTokenID] != address(0),
            "baseTokenID not been created"
        );
        require(
            tokenSupply[_baseTokenID] < tokenMaxSupply[_baseTokenID],
            "Max supply reached"
        );
        uint256 tokenID = _getNextTokenID(_baseTokenID);
        _mint(_to, tokenID);
        _incrementTokenId(_baseTokenID);
        tokenSupply[_baseTokenID] = tokenSupply[_baseTokenID].add(1);
        return tokenID;
    }

    function _getBaseID(uint256 tokenID) internal pure returns (uint256) {
        return tokenID.div(MAX_BASE_SUPPLY).mul(MAX_BASE_SUPPLY);
    }

    function _getNextBaseID() private view returns (uint256) {
        return _baseID.add(MAX_BASE_SUPPLY);
    }

    function _incrementBaseID() private {
        _baseID = _baseID.add(MAX_BASE_SUPPLY);
    }

    function _getNextTokenID(uint256 _baseTokenID)
        private
        view
        returns (uint256)
    {
        return (currentTokenID[_baseTokenID].add(1)).add(_baseTokenID);
    }

    function _incrementTokenId(uint256 _baseTokenID) private {
        currentTokenID[_baseTokenID]++;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseTokenURI = _baseTokenURI;
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}