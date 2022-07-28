// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ChampionsAscensionImperialGallery is ERC721, Pausable, AccessControl {

    // Store the NFT type in the upper 128 bits.
    uint256 constant NFT_TYPE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000;

    // Store the NFT index within the type in the lower 128 bits.
    uint256 constant NFT_INDEX_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    // For conversion of token ID components to canonical hex strings. Fixed length, lower case, without the `0x` prefix
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC721("ChampionsAscensionImperialGallery", "ART") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /**
     * @dev Converts a `uint128` to its ASCII `string` hexadecimal representation zero-padded to a fixed length, 
     * lower case, without the `0x` prefix. Note the number of hex characters will be twice the byte length.
     */
    function toPaddedHexString(uint256 value, uint256 byteLength) 
        public
        pure
        returns (string memory) 
    {
        bytes memory buffer = new bytes(2 * byteLength);
        for (uint256 i = 2 * byteLength; i > 0; --i) {
            buffer[i - 1] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "byte length too small to represent value");
        return string(buffer);
    }

    function decomposeTokenId(uint256 _tokenId) 
        public 
        pure 
        returns(uint128 _tokenType, uint128 _tokenIndex)
    {
      return ( 
        uint128(_tokenId >> 128), 
        uint128(_tokenId & NFT_INDEX_MASK) 
      );
    }

    function composeTokenId(uint128 _tokenType, uint128 _tokenIndex)
        public
        pure
        returns(uint256 _tokenId)
    {
      uint256 tokenId = (uint256(_tokenType) << 128) | _tokenIndex;
      return tokenId;
    }

    function tokenURI(uint256 _tokenId)
        public
        pure
        override
        returns (string memory)
    {
        uint128 tokenType;
        uint128 tokenIndex;
        (tokenType, tokenIndex) = decomposeTokenId(_tokenId);
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    toPaddedHexString(tokenType, 16),
                    "/",
                    toPaddedHexString(tokenIndex, 16)
                )
            );
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://champions.io/gallery/nfts/";
    }

    function ownerOfTypeAndIndex(uint128 tokenType, uint128 tokenIndex)
        public
        view
        returns (address)
    {
        uint256 tokenId = composeTokenId(tokenType, tokenIndex);
        return ownerOf(tokenId);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint128 tokenType, uint128 tokenIndex)
        public
        onlyRole(MINTER_ROLE)
    {
        require(tokenType > 0, "token type must be non-zero");
        require(tokenIndex > 0, "token index must be non-zero");
        uint256 tokenId = composeTokenId(tokenType, tokenIndex);
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}