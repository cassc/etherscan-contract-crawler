// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IERC5192.sol";

contract PlaybuxSBT is ERC721, IERC5192, ERC721Enumerable, AccessControl {
    using Strings for uint256;
    mapping(uint256 => uint256) public runningNumberByType; // Running number of tokens minted by type
    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE"); // Factory role is used to mint new NFTs
    string public baseURI; // Base URI for token metadata

    mapping(address => mapping(uint256 => uint256)) public soulboundTokens; // Mapping of soulbound tokens id by address and type

    event SetBaseURI(string _baseURI);
    event SetSoulbound(bool _soulbound);

    constructor(string memory _uri) ERC721("Playbux Soulbound Token", "PBS") {
        baseURI = _uri;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * _substring returns the substring of the given string
     * @param str string to be sliced
     * @param startIndex starting index of the substring
     * @param endIndex ending index of the substring
     */
    function _substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    /**
     * _findTokenId finds the token ID for the given type
     * @param _type type of the token
     */
    function _findTokenId(uint256 _type) private view returns (uint256) {
        return (_type * 1e18) + runningNumberByType[_type];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        require(from == address(0) || to == address(0), "PlaybuxSBT: token is soulbound");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * setBaseURI sets the base URI for token metadata
     * @param _baseURI The base URI for token metadata
     */
    function setBaseURI(string memory _baseURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _baseURI;
        emit SetBaseURI(_baseURI);
    }

    /**
     * tokenURI returns the metadata URI for a given token ID
     * @param tokenId uint256 ID of the token to query
     * @return string URI of the token
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _type = findTypeStrByTokenId(tokenId);
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _type)) : "";
    }

    /**
     * mintTo mints a new token to the given address
     * @param _to address of the future owner of the token
     * @param _type type of the token
     */
    function mintTo(address _to, uint256 _type) public onlyRole(FACTORY_ROLE) {
        require(_type > 0, "Invalid token type");
        require(!checkOwnerHasTokenByType(_to, _type), "Owner already has token of this type");
        uint256 _tokenId = _findTokenId(_type) + 1;
        runningNumberByType[_type]++;
        soulboundTokens[_to][_type] = _tokenId;
        _mint(_to, _tokenId);

        emit Locked(_tokenId);
    }

    /**
     * mintByTokenId mints a new token to the given address
     * Use on cross-chain transfers to mint the token on the destination chain
     * cannot be used to mint the same token twice
     * cannot be used to mint a new token that is not the next in the sequence
     * @param _to address of the future owner of the token
     * @param _tokenId ID of the token
     */
    function mintByTokenId(address _to, uint256 _tokenId) public onlyRole(FACTORY_ROLE) {
        uint256 _type = findTypeByTokenId(_tokenId);
        uint256 supplyByType = runningNumberByType[_type];

        require(_type > 0, "Invalid token type");

        require(supplyByType != 0, "This type of token has not been minted yet");
        /*
         * If the token id is not the next one in the sequence, it means that the token id is already minted.
         * Use mintTo() to mint the next token in the sequence.
         */
        require(findTokenIndexByTokenId(_tokenId) <= supplyByType, "Token ID is not available");
        soulboundTokens[_to][_type] = _tokenId;
        _mint(_to, _tokenId);

        emit Locked(_tokenId);
    }

    /**
     * burnByTokenId burns the token with the given ID
     * Use on cross-chain transfers to burn the token on the source chain
     * User must be the owner of the token or approved to burn the token
     * @param _tokenId ID of the token
     */
    function burnByTokenId(uint256 _tokenId) public onlyRole(FACTORY_ROLE) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: caller is not token owner or approved");
        uint256 _type = findTypeByTokenId(_tokenId);
        soulboundTokens[_msgSender()][_type] = 0;
        _burn(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev to comply with ERC5192
     * @return bool status of the token
     */
    function locked(uint256) external pure override(IERC5192) returns (bool) {
        return true; // all tokens are locked
    }

    /**
     * findTypeStrByTokenId finds the type of the token with the given ID
     * @param _tokenId ID of the token
     * @return type of the token as a string
     */
    function findTypeStrByTokenId(uint256 _tokenId) public pure returns (string memory) {
        return _substring(_tokenId.toString(), 0, bytes(_tokenId.toString()).length - 18);
    }

    /**
     * findTypeByTokenId finds the type of the token with the given ID
     * @param _tokenId ID of the token
     * @return type of the token as a uint256
     */
    function findTypeByTokenId(uint256 _tokenId) public pure returns (uint256) {
        return _tokenId / 1e18;
    }

    /**
     * findTokenIndexByTokenId finds the index of the token with the given ID
     * @param _tokenId ID of the token
     * @return index of the token
     */
    function findTokenIndexByTokenId(uint256 _tokenId) public pure returns (uint256) {
        return _tokenId % 1e18;
    }

    function checkOwnerHasTokenByType(address _owner, uint256 _type) public view returns (bool) {
        return soulboundTokens[_owner][_type] > 0;
    }
}