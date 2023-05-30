// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "solmate/tokens/ERC721.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";

error MaxSupply();
error NonExistentTokenURI();
error PeriodNotOver();

contract Mushroom is ERC721, Ownable {
    using Strings for uint256;

    uint256 public currentTokenId;
    uint256 public constant maxSupply = 2500;
    string public baseURI;
    bytes32 public immutable merkleRoot;
    uint256 public immutable mintPeriod;
    address public immutable treasury;
    uint256 public constant treasuryMint = 100;
    mapping(address => bool) public userToClaims;

    constructor(
        string memory _name,
        string memory _symbol,
        bytes32 _merkleRoot,
        string memory _baseURI,
        uint256 _mintPeriod,
        address _treasury
    ) ERC721(_name, _symbol) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        mintPeriod = block.timestamp + _mintPeriod;
        treasury = _treasury;
    }

    function mint(address _recipient, bytes32[] memory proof)
        public
        returns (uint256)
    {
        // Verify the merkle proof.
        require(_recipient != address(0), "Address Zero");
        bytes32 leaf = keccak256(abi.encodePacked(_recipient));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
        require(userToClaims[_recipient] == false, "Already claimed");
        require(currentTokenId + 1 <= maxSupply - treasuryMint, "Max public supply reached");
        userToClaims[_recipient] = true;
        uint256 newItemId = ++currentTokenId;
        _safeMint(_recipient, newItemId);
        return newItemId;
    }

    function publicMint() public returns (uint256) {
        require(block.timestamp > mintPeriod, "Mint period still not over");
        require(userToClaims[msg.sender] == false, "Already claimed");
        require(
            currentTokenId + 1 <= maxSupply - treasuryMint,
            "Max public supply reached"
        );
        userToClaims[msg.sender] = true;
        uint256 newItemId = ++currentTokenId;
        _safeMint(msg.sender, newItemId);
        return newItemId;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function withdraw() public {
        require(block.timestamp > mintPeriod, "Mint period still not over");
         require(
            currentTokenId + 1 <= maxSupply,
            "Max supply reached"
        );
        uint256 newItemId = ++currentTokenId;
        _safeMint(treasury, newItemId);
    }

    function withdrawAll() public {
        require(block.timestamp > mintPeriod, "Mint period still not over");
        while (currentTokenId < maxSupply) {
            uint256 newItemId = ++currentTokenId;
            _safeMint(treasury, newItemId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        ownerOf(tokenId);
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
}