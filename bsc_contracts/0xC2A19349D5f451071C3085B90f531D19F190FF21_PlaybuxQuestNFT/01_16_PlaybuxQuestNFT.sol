// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract PlaybuxQuestNFT is ERC721, ERC721Enumerable, ERC2981, AccessControl {
    using Strings for uint256;

    bytes32 internal constant FACTORY_ROLE = keccak256("FACTORY_ROLE"); // Factory role is used to mint new NFTs

    mapping(uint256 => uint256) public tokenSupplyByType; // Running number of tokens minted by type
    string public baseURI; // Base URI for token metadata

    constructor(
        address _receiver,
        uint96 _feeNumerator,
        string memory _uri
    ) ERC721("Playbux Early Bird Quest", "PBN") {
        baseURI = _uri;
        _setDefaultRoyalty(_receiver, _feeNumerator);
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
        return (_type * 1e18) + tokenSupplyByType[_type];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * setBaseURI sets the base URI for token metadata
     */
    function setBaseURI(string memory uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = uri;
    }

    /**
     * tokenURI returns the metadata URI for a given token ID
     * @param tokenId uint256 ID of the token to query
     * @return string URI of the token
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _type = findTypeStrByTokenId(tokenId);
        // ! baseURI must end with "/"
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _type)) : "";
    }

    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /**
     * mintTo mints a new token to the given address
     * @param _to address of the future owner of the token
     * @param _type type of the token
     */
    function mintTo(address _to, uint256 _type) public onlyRole(FACTORY_ROLE) {
        require(_type > 0, "Invalid token type");
        uint256 _tokenId = _findTokenId(_type) + 1;
        tokenSupplyByType[_type]++;
        _mint(_to, _tokenId);
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
        uint256 supplyByType = tokenSupplyByType[_type];

        require(_type > 0, "Invalid token type");

        /*
         * If the token id is not the next one in the sequence, it means that the token id is already minted.
         * Use mintTo() to mint the next token in the sequence.
         */
        require(findTokenIndexByTokenId(_tokenId) <= supplyByType, "Token ID is not available");
        require(supplyByType != 0, "Token ID is not available");

        _mint(_to, _tokenId);
    }

    /**
     * burnByTokenId burns the token with the given ID
     * Use on cross-chain transfers to burn the token on the source chain
     * User must be the owner of the token or approved to burn the token
     * @param _tokenId ID of the token
     */
    function burnByTokenId(uint256 _tokenId) public onlyRole(FACTORY_ROLE) {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: caller is not token owner or approved");

        _burn(_tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
}