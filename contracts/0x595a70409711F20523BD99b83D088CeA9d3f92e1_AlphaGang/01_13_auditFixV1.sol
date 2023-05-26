//SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AlphaGang is ERC1155, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public name = "Alpha Gang";
    string public symbol = "AG";
    string public baseURI =
        "ipfs://QmXtSDsWm2nQC497UeVsgPH2hT21WoZe8pi831iQugQ1Q3/";

    bytes32 public merkleRoot =
        0x36bd448259415f8e16e833c018c45c26375ca9174b00186068a9e5bf37d94f7b;

    uint256 public supply;
    mapping(address => bool) public walletMints;

    uint32 public constant TIERS = 3;
    uint32 public constant SUPPLY_MAX = 666;

    bool public publicPaused = true;

    constructor(string memory _initBaseURI) ERC1155(_initBaseURI) {
        baseURI = _initBaseURI;
    }

    function mint(bytes32[] calldata _merkleProof) external nonReentrant {
        require(!publicPaused, "Presale is paused!");
        require(
            !walletMints[msg.sender],
            "You can have only one pass per wallet!"
        );
        require((supply + 1) <= SUPPLY_MAX, "Invalid Quantity!");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Merkle Proof!"
        );

        walletMints[msg.sender] = true;
        uint256 _tier = (supply % TIERS) + 1; // Equal distribution.
        supply++;

        _mint(msg.sender, _tier, 1, "");
    }

    function mintForAddress(
        address to,
        uint32 id,
        uint32 quantity
    ) external onlyOwner {
        supply += quantity;
        _mint(to, id, quantity, "");
    }

    function batchMintForAddress(
        address[] calldata to,
        uint32 id,
        uint256[] calldata quantity
    ) external onlyOwner {
        uint32 i;
        for (i = 0; i < quantity.length; i++) {
            supply += quantity[i];
            _mint(to[i], id, quantity[i], "");
        }
    }

    function togglePublicSale() external onlyOwner {
        publicPaused = !publicPaused;
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}