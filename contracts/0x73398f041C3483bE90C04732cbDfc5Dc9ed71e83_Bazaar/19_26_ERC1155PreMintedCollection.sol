// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../ERC1155.sol";
import "../../../utils/structs/Bits.sol";


/**
 * @dev an ERC1155 that has a fixed supply for all its tokens.
 * it is created with an implicit finite set of 256 tokens, as the token id range is [1-256].
 * minting happens implicitly when only a portion of fixed supply is transferred.
 */
contract ERC1155PreMintedCollection is ERC1155, IERC1155MetadataURI {
    using Address for address payable;
    using Address for address;
    using Bits for Bits.Bitmap;

    address public creator;
    string public name;
    string public symbol;
    string public baseURI; // used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    uint public howManyTokens;
    uint public supplyPerToken;
    Bits.Bitmap private notOwnedByCreator; // in the beginning, creator owns it all (using reverse logic: 0 indicates ownership)

    constructor(
        string memory _name,
        string memory _symbol,
        uint _howManyTokens,
        uint _supplyPerToken,
        string memory _baseURI
    ) {
        creator = tx.origin;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        supplyPerToken = _supplyPerToken;
        howManyTokens = _howManyTokens;
    }

    function isOwnedByCreator(uint id) public view returns (bool) { return !notOwnedByCreator.get(id); }

    /// @dev for tracing
    function creatorOwnershipBitMap() external view returns (uint[] memory) {
        return notOwnedByCreator.toArray(howManyTokens);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function exists(uint id) public view virtual returns (bool) { return 0 <= id && id < howManyTokens; }

    function totalSupply(uint id) public view virtual returns (uint) { return exists(id) ? supplyPerToken : 0; }

    /**
     * This implementation relies on the token type ID substitution mechanism.
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the actual token type ID.
     */
    function uri(uint tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "IERC1155MetadataURI: uri query for nonexistent token");
        return string(abi.encodePacked(baseURI, "/", uint2str(tokenId), ".json"));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function balanceOf(address account, uint id) public view override(IERC1155, ERC1155) virtual returns (uint) {
        uint balance = super.balanceOf(account, id);
        return balance > 0 ?
            balance :
            account == creator && isOwnedByCreator(id) ?
                supplyPerToken :
                0;
    }

    function _safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) internal virtual override {
        if (from == creator && isOwnedByCreator(id)) {
            notOwnedByCreator.set(id);
            balances[id][creator] += supplyPerToken;
        }
        super._safeTransferFrom(from, to, id, amount, data);
    }
}