// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import { IERC2981, IERC165 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./ERC1155O.sol";
import "./extensions/ERC1155Supply.sol";
import "./IERC1155Comet.sol";
import "./utils/ERC1155Token.sol";

/**
 * @title  ERC1155Comet
 * @author Orange Comet
 *
 * @notice Orange Comet standard ERC1155 contract
 */
contract ERC1155Comet is
    IERC1155Comet,
    ERC1155Supply,
    ERC1155Token,
    Ownable,
    IERC2981
{
    // The token metadata base URI
    string _baseTokenURI;

    // The token metadata contract URI
    string _contractURI;

    // The royalty percentage as a percent (e.g. 10 for 10%)
    uint256 _royaltyPercent;

    // The max supply of tokens in this contract.
    uint256 _maxSupply;

    // The beneficiary wallet.
    address _beneficiary;

    // The royalties wallet.
    address _royalties;

    /**
     * @notice ERC1155 constructor.
     *
     * @param name The token name.
     * @param symbol The token symbol.
     */
    constructor(string memory name, string memory symbol) ERC1155("") {
        // Set the contract name
        _name = name;

        // Set the contract symbol
        _symbol = symbol;

        // set default royalty percent to 10;
        _royaltyPercent = 10;

        // set the default royalty payout to the owner for safety
        _royalties = owner();

        // set the default beneficiary payout to the owner for safety
        _beneficiary = owner();
    }

    /**
     * @notice Sets the Base URI for the token API.
     * @param newUri The new URI to set
     */
    function setURI(string memory newUri) external onlyOwner {
        // uri tracked by this contract
        _baseTokenURI = newUri;

        // set private _uri for ERC1155 base contract
        _setURI(newUri);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (!exists(tokenId)) revert URIQueryForNonexistentToken();

        return
            bytes(_baseTokenURI).length > 0
                ? string(abi.encodePacked(_baseTokenURI, _toString(tokenId)))
                : "";
    }

    /**
     * @notice OpenSea contract level metdata standard for displaying on storefront.
     *         Reference: https://docs.opensea.io/docs/contract-level-metadata
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @notice Sets the Contract URI for marketplace APIs.
     * @param newUri The new URI to set
     */
    function setContractURI(string memory newUri) external onlyOwner {
        _contractURI = newUri;
    }

    /**
     * @notice Sets the royalties wallet address.
     *
     * @param wallet The new wallet address.
     */
    function setRoyalties(address wallet) external onlyOwner {
        _royalties = wallet;
    }

    /**
     * @notice Sets the royalty percentage.
     *
     * @param value The value as an integer (e.g. 10 for 10%).
     */
    function setRoyaltyPercent(uint256 value) external onlyOwner {
        _royaltyPercent = value;
    }

    /**
     * @notice Sets the Contract URI for marketplace APIs.
     *         Implements tracking of balances and total supply.
     * @param to The address to mint to
     * @param id The token ID
     * @param amount The quantity of tokens to mint
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _balances[id][to] += amount;
        _totalSupply[id] += amount;

        emit TransferSingle(operator, address(0), to, id, amount);
    }

    /**
     * @notice Supporting ERC721, IER165
     *         https://eips.ethereum.org/EIPS/eip-165
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return `true` if the contract implements `interfaceId`
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256 royaltyAmount)
    {
        // Silence solc unused parameter warning.
        // All tokens have the same royalty.
        _tokenId;
        royaltyAmount = (_salePrice / 100) * _royaltyPercent;

        return (_royalties, royaltyAmount);
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory str)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}