// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/ISellerToken.sol';
// import 'erc721a/contracts/ERC721A.sol';
import './library/errors/Errors.sol';
import './interfaces/ITokenMetadata.sol';
import 'solmate/src/auth/Owned.sol';
import 'solmate/src/tokens/ERC721.sol';

contract SellerToken is Owned, ERC721 {
    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    mapping(address => bool) private _tokenManagers;
    ITokenMetadata public _tokenMetadata;
    string public _baseTokenURI;
    string public contractURI;

    constructor(string memory name_, string memory symbol_, string memory baseTokenURI, string memory _contractURI)
        Owned(msg.sender)
        ERC721(name_, symbol_) {
            _baseTokenURI = baseTokenURI;
            contractURI = _contractURI;
    }

    function toggleTokenManager(address wallet, bool permission) onlyOwner public {
        _tokenManagers[ wallet ] = permission;
    }

    function tokenManager(address wallet) public view returns(bool) {
        return _tokenManagers[ wallet ];
    }

    modifier onlyTokenManagers() {
        if (false == _tokenManagers[ msg.sender ]) {
            revert Errors.UserPermissions();
        }

        _;
    }

    function mint(address dest, uint256 id) onlyTokenManagers public returns(uint256) {
        _mint(dest, id);
        return id;
    }

    function burn(uint256 tokenId) onlyTokenManagers public {
        _burn(tokenId);
    }

    function updateBaseURI(string memory uri) onlyOwner public {
        _baseTokenURI = uri;
        _tokenMetadata = ITokenMetadata(address(0));
    }

    function setMetadataContract(address tokenMetadata) onlyOwner public {
        _tokenMetadata = ITokenMetadata(tokenMetadata);
    }

    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public override view returns(string memory) {
        if (address(_tokenMetadata) != address(0)) {
            return _tokenMetadata.tokenURI(tokenId);
        }

        // call ownerOf to verify that this token is actually minted
        ownerOf(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }


    function updateMetadata(uint256 id) public onlyOwner {
        emit MetadataUpdate(id);
    }

    function updateAllMetadata() public onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /**
     * credit erc721a
     * https://www.erc721a.org/
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
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