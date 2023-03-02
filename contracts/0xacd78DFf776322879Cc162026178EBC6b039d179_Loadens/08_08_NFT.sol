// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./libraries/ERC721A.sol";
import "./libraries/Strings.sol";
import "./libraries/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Loadens is ERC721A, Ownable {
    using Strings for uint256;

    string private baseURI;

    bytes32 public merkleRoot =
        0xb4fb11ad8c604356051a03e522896a97bf6cc797e27a21bb03e1df8c93022bd3;

    uint256 public price = 0.0044 ether;

    uint256 public maxPerTx = 4;

    uint256 public maxSupply = 4444;

    bool public mintEnabled = false;

    bool public whitelistSaleEnabled = false;

    constructor(address owner_) ERC721A("Loadens", "LDN") {
        _safeMint(owner_, 1);
        setBaseURI("ipfs://QmTWTrAuKC9vJhpK72MTtZnR15t8nSZ1QFsLpfYaxbwEfG/");
        transferOwnership(owner_);
    }

    function setMerkleRoot(bytes32 _newRoot) public onlyOwner {
        merkleRoot = _newRoot;
    }

    function mint(uint256 count, bytes32[] calldata _merkleProof) external payable {
        uint256 cost = price * count;
        require(msg.value >= cost, "Please send the exact amount");
        require(totalSupply() + count <= maxSupply, "No more");
        require(mintEnabled, "Minting is not live yet");
        require(count <= maxPerTx, "Max per TX reached");

        if(whitelistSaleEnabled) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
            require(
                MerkleProof.verify(_merkleProof, merkleRoot, leaf),
                "Invalid Merkle Proof"
            );
            _safeMint(msg.sender, count);
        } else {
            _safeMint(msg.sender, count);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setPrice(uint256 _newPrice) external onlyOwner {
        price = _newPrice;
    }

    function flipSale() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function startWhitelistSale() external onlyOwner {
        whitelistSaleEnabled = !whitelistSaleEnabled;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }
}