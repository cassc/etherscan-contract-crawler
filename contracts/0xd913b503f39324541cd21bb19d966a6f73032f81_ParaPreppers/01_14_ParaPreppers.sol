// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ParaPreppers is ERC721A, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string public baseTokenURI = "https://nft.parapreppernft.com/ipfs/QmXrZcpzkqjV5haNqN4oUs3HhXtH95kqRG9cfAWbVz7Kqi/";
    bytes32 public whitelistMerkleRoot = 0x87170a03d9457fcf5c21ae8643017d276f69925e4e7b4dc08f8ff993f2c97ba4;
    uint16 public constant TOTAL_MINT_AMOUNT = 3000;
    string public mintType = "presale";
    uint256 public pricePerNft = 0.08 ether;

    constructor() ERC721A("Para Preppers", "PARA") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    //  Set the base uri for token
    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    //  Set the merkle tree for whitelist
    function setWhitelistMerkleRoot(bytes32 _whitelistMerkleRoot)
        public
        onlyOwner
    {
        whitelistMerkleRoot = _whitelistMerkleRoot;
    }

    //  Set the price per NFT
    function setPricePerNft(uint256 _pricePerNft) public onlyOwner {
        pricePerNft = _pricePerNft;
    }

    //  Set the mint type
    function setMintType(string memory _mintType) external onlyOwner {
        if (
            keccak256(abi.encodePacked((_mintType))) ==
            keccak256(abi.encodePacked(("presale")))
        ) {
            mintType = _mintType;
            setPricePerNft(0.08 ether);
        } else if (
            keccak256(abi.encodePacked((_mintType))) ==
            keccak256(abi.encodePacked(("public")))
        ) {
            mintType = _mintType;
            setPricePerNft(0.1 ether);
        } else {
            revert("No valid mint type.");
        }
    }

    //  Private sale with whitelist
    function privateMint(bytes32[] calldata _merkleProof) public payable {
        bytes memory tempEmptyStringTest = bytes(mintType);
        bytes32 leaf;

        require(
            keccak256(abi.encodePacked((mintType))) !=
                keccak256(abi.encodePacked(("public"))),
            "Public sale period!"
        );
        require(
            msg.sender == tx.origin,
            "Mint from other contract not allowed."
        );
        require(tempEmptyStringTest.length > 0, "Mint type isn't set yet.");
        require(whitelistMerkleRoot.length > 0, "Whitelist isn't provided.");

        leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, whitelistMerkleRoot, leaf),
            "Not whitelisted address."
        );

        _safeMint(msg.sender, 1);
    }

    function withdraw(address ownerWallet) external onlyOwner {
        uint256 balance = address(this).balance;

        payable(ownerWallet).transfer(balance);
    }

    //  Public sale without whitelist
    function publicMint() public payable {
        require(
            keccak256(abi.encodePacked((mintType))) ==
                keccak256(abi.encodePacked(("public"))),
            "Presale period!."
        );
        require(
            msg.sender == tx.origin,
            "Mint from other contract not allowed."
        );

        _safeMint(msg.sender, 1);
    }
}