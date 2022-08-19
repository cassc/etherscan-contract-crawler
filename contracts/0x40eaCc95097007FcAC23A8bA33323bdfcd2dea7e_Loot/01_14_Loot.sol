// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Loot
 * Loot - a contract for Loot semi-fungible tokens.
 */
contract Loot is ERC1155, ERC2981, Ownable {
    string public name;
    string public symbol;
    uint96 public royaltyFee;
    address public royaltyAddress;

    mapping(address => bool) public minterRole;
    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => string) customUri;

    constructor() ERC1155("https://eightbit.me/api/loot/{id}") {
        name = "EightBit Loot";
        symbol = "EBL";
        royaltyAddress = owner();
        royaltyFee = 500;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Returns the URI for token with `tokenId`.
     *
     * @param tokenId | uint256 ID of the token to query
     * @return uri | uri string
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        bytes memory customUriBytes = bytes(customUri[tokenId]);
        if (customUriBytes.length > 0) {
            return customUri[tokenId];
        } else {
            return super.uri(tokenId);
        }
    }

    /**
     * @notice Returns the total quantity for a token ID.
     *
     * @param _id | uint256 ID of the token to query
     * @return amount | token in existence
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /**
     * @notice Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism.
     *
     * @param _newURI | new URI for all tokens
     */
    function setURI(string memory _newURI) public onlyOwner {
        _setURI(_newURI);

        emit SetURI(_newURI);
    }

    /**
     * @notice Update the base URI for the token.
     *
     * @param _tokenId | the token to update.
     * @param _newURI | new URI for the token.
     */
    function setCustomURI(uint256 _tokenId, string memory _newURI) public onlyOwner {
        customUri[_tokenId] = _newURI;

        emit SetCustomURI(_tokenId, _newURI);
    }

    /**
     * @notice Mints `quantity` of tokens `to` address.
     *
     * @param to | address of the future owner of the token
     * @param id | token ID to mint
     * @param quantity | amount of tokens to mint
     */
    function mint(
        address to,
        uint256 id,
        uint256 quantity
    ) public {
        require(minterRole[msg.sender], "Loot#mint: ONLY_MINTER");
        _mint(to, id, quantity, "");
        tokenSupply[id] = tokenSupply[id] + quantity;

        emit Mint(to, id, quantity);
    }

    /**
     * @notice Set or update minter role `_to` address.
     *
     * @param _to | address of the minter to modify
     * @param _isMinter | true if minter
     */
    function setMinterRole(address _to, bool _isMinter) public onlyOwner {
        minterRole[_to] = _isMinter;

        emit SetMinterRole(_to, _isMinter);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice update royalty fee
     */
    function setRoyaltyFee(uint96 _royaltyFee) external onlyOwner {
        royaltyFee = _royaltyFee;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * *** ONLY OWNER ***
     *
     * @notice update royalty address
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    event Mint(address to, uint256 tokenId, uint256 quantity);

    event SetMinterRole(address to, bool isMinter);

    event SetURI(string newURI);

    event SetCustomURI(uint256 tokenId, string newURI);
}