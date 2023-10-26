// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/v4.9.2/token/ERC721/ERC721.sol";

import "@openzeppelin/v4.9.2/utils/introspection/ERC165.sol";

import "@openzeppelin/v4.9.2/token/common/ERC2981.sol";

import "@openzeppelin/v4.9.2/access/Ownable.sol";

/**
 * @title NieuxCollective
 * @dev Implementation of the NieuxCollective
 * @author Ryan Meyers - strangeruff.eth
 */
contract NieuxCollective is ERC721, Ownable, ERC2981 {
    address private _receiver;
    uint256 public nextTokenId = 505;
    string public baseURI =
        "ipfs://ipfs://bafybeibqj3m675dqsnv7x7qax236n5ysjcuqlcefbec5vq4snlrhxuh4ca/";

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() ERC721("Nieux Collective", "NIEUX") {
        _setDefaultRoyalty(msg.sender, 500);
    }

    /**
     * @dev Airdrops a token to a given address
     * @param to address to receive the token
     */
    function airdropOne(address to) external onlyOwner {
        _safeMint(to, nextTokenId);
        nextTokenId += 1;
    }

    /**
     * @dev Airdrops multiple tokens to multiple addresses
     * @param to array of addresses to receive the tokens
     */
    function airdropMany(address[] calldata to) external onlyOwner {
        for (uint i = 0; i < to.length; ) {
            _safeMint(to[i], nextTokenId + i);
        }
        nextTokenId += to.length;
    }

    /**
     * @dev Airdrops specific tokens to specific addresses
     * @param to array of addresses to receive the tokens
     * @param tokenIds array of token ids to be airdropped
     */
    function airdropFounders(
        address[] calldata to,
        uint256[] calldata tokenIds
    ) external onlyOwner {
        if (nextTokenId != 505) {
            revert InvalidParameters();
        }

        if (to.length != tokenIds.length) {
            revert InvalidParameters();
        }

        for (uint i = 0; i < to.length; ) {
            _mint(to[i], tokenIds[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * @param interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Sets the base URI for all token IDs. It is automatically added as a prefix to the
     * value returned in {tokenURI}, or to the token ID if {tokenURI} is empty.
     * @param uri the base URI to be set
     */
    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json"))
                : "";
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     * @param value uint256 value to convert to string
     */
    function _toString(
        uint256 value
    ) internal pure virtual returns (string memory str) {
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)

            let end := str

            for {
                let temp := value
            } 1 {

            } {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) {
                    break
                }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }

    /**
     * @dev Withdraws the contract balance to the receiver address
     */
    function withdraw() public payable {
        (bool sent, bytes memory data) = payable(_receiver).call{
            value: address(this).balance
        }("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Sets the default royalty for the contract
     * @param receiver address to receive the royalty
     * @param feeNumerator the royalty fee numerator
     */
    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public payable onlyOwner {
        _receiver = receiver;
        _setDefaultRoyalty(_receiver, feeNumerator);
    }

    /**
     * @dev Error to be thrown when a URI is queried for a nonexistent token
     */
    error URIQueryForNonexistentToken();
    /**
     * @dev Error to be thrown when invalid parameters are provided
     */
    error InvalidParameters();

    /**
     * @dev Event to be emitted when metadata is updated
     * @param _fromTokenId the start token id of the batch
     * @param _toTokenId the end token id of the batch
     */
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}