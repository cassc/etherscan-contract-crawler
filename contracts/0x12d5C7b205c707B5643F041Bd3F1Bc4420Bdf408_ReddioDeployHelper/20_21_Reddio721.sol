// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error InvalidCall();
error PermissionDenied();

contract Reddio721 is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private immutable operator;
    // true -> ERC721M, only for starkex
    // false -> ERC721, for everyone
    bool private mintable;
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        bool _mintable
    ) ERC721(name_, symbol_) {
        mintable = _mintable;
        baseURI = baseURI_;
        if (!_mintable) {
            _tokenIds.increment();
        }

        operator = _mintable
            ? 0xB62BcD40A24985f560b5a9745d478791d8F1945C
            : address(0);
    }

    modifier erc721() {
        if (mintable) {
            revert InvalidCall();
        }
        _;
    }

    modifier erc721m() {
        if (!mintable) {
            revert InvalidCall();
        }
        if (msg.sender != operator) {
            revert PermissionDenied();
        }
        _;
    }


    function mint(address to) external erc721 returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);

        _tokenIds.increment();
        return newItemId;
    }

    function mint_multi(
        address to,
        uint256 amount
    ) external erc721 returns (uint256) {
        for (uint256 i = 0; i < amount; ) {
            uint256 newItemId = _tokenIds.current();
            _mint(to, newItemId);
            _tokenIds.increment();
            unchecked {
                ++i;
            }
        }
        return amount;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mintFor(
        address player,
        uint256 amount,
        bytes calldata mintingBlob
    ) external erc721m returns (uint256) {
        uint256 tokenId = bytesToUint(mintingBlob);
        _safeMint(player, tokenId);
        return tokenId;
    }

    function bytesToUint(bytes memory b) private pure returns (uint256) {
        uint256 number;
        for (uint256 i = 0; i < b.length; i++) {
            number =
                number +
                uint256(uint8(b[i])) *
                (2 ** (8 * (b.length - (i + 1))));
        }
        return number;
    }
}