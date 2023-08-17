// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

error InvalidCall();
error PermissionDenied();

contract Reddio721CustomURI is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIds;

    address private immutable operator;
    // true -> ERC721M, only for starkex
    // false -> ERC721, for everyone
    bool private mintable;
    mapping(uint256 => bytes) public specificTokenURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory,
        bool _mintable
    ) ERC721(name_, symbol_) {
        mintable = _mintable;
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

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        return string(specificTokenURI[tokenId]);
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

    function mintFor(
        address player,
        uint256 amount,
        bytes calldata mintingBlob
    ) external erc721m returns (uint256) {
        (uint256 tokenId, bytes memory metadata) = abi.decode(mintingBlob, (uint256, bytes));
        _safeMint(player, tokenId);
        if (metadata.length > 0) {
            specificTokenURI[tokenId] = metadata;
        }
        return tokenId;
    }
}