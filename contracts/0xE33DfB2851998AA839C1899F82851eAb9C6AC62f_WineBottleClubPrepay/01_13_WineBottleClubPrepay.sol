//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Wine Bottle Club, Prepay
/// @author Consultec, FZCO
contract WineBottleClubPrepay is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) public _refunded;
    string public _baseTokenURI;
    bytes32 public _root;
    uint256 public _tokenPrice = 0.3 ether;

    constructor(string memory baseTokenURI)
        ERC721("WineBottleClubPrepay", "WBCPrep")
    {
        setBaseTokenURI(baseTokenURI);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function refund(
        address to,
        uint256 amount,
        bytes32[] calldata proof
    ) external payable {
        require(
            MerkleProof.verify(proof, _root, keccak256(abi.encode(to, amount))),
            "!proof"
        );
        require(!_refunded[to], "!refunded");
        _refunded[to] = true;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "!transfer");
    }

    function mint(address to, uint256 count) external payable {
        _mintMany(to, _tokenPrice, uint16(count));
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return _baseTokenURI;
    }

    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    //
    // Private functions
    //

    function _mintMany(
        address to,
        uint256 tokenPrice,
        uint16 count
    ) private {
        unchecked {
            require(msg.value >= tokenPrice * count, "!ether");
        }
        for (uint256 i = 0; i < count; i++) {
            _tokenIds.increment();
            _safeMint(to, _tokenIds.current());
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        require((address(0) == from), "!locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //
    // Owner functions
    //

    function setMerkleRoot(bytes32 root) public onlyOwner {
        _root = root;
    }

    function ownerMint(address to, uint16 count) external onlyOwner {
        _mintMany(to, 0, count);
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setTokenPrice(uint256 tokenPrice) public onlyOwner {
        _tokenPrice = tokenPrice;
    }

    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "!transfer");
    }
}