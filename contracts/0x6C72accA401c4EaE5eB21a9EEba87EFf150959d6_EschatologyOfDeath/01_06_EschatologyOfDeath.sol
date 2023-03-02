// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract EschatologyOfDeath is ERC721A, Ownable {
    uint32 public whiteListReserve;
    uint32 public maxSupply;
    uint32 public mintStartTimestamp;
    uint32 public whiteListEndTimestamp;

    bytes32 public merkleRoot; 

    mapping(address => bool) public hasWhiteListMint;   // mapping to limit white list mint to 1
    mapping(address => bool) public hasMint;            // mapping to limit mint to 1

    constructor(
        bytes32 _merkleRoot, 
        uint32 _whiteListSize, 
        uint32 _maxSupply,
        uint32 _mintStartTimestamp,
        uint32 _whiteListMintDuration
    ) ERC721A("Eschatology Of Death", "EOD") {
        merkleRoot                      = _merkleRoot;
        whiteListReserve                = _whiteListSize;
        maxSupply                       = _maxSupply;
        mintStartTimestamp              = _mintStartTimestamp;
        whiteListEndTimestamp           = _mintStartTimestamp + _whiteListMintDuration;
    }

    function whiteListed(address _wallet, bytes32[] calldata _proof) public view returns (bool) {
        return MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(_wallet)));
    }

    function whiteListMint(bytes32[] calldata _proof) public {
        require(block.timestamp >= mintStartTimestamp, "White list mint not open");
        require(block.timestamp < whiteListEndTimestamp, "White list mint closed");
        require(whiteListed(msg.sender, _proof), "You are not white listed");
        require(hasWhiteListMint[msg.sender] == false, "Only one white list mint per wallet");
        require(whiteListReserve > 0, "Reserve is empty");

        whiteListReserve--;
        hasWhiteListMint[msg.sender] = true;

        _mint(msg.sender, 1);
    }

    function mint() public {
        require(block.timestamp >= mintStartTimestamp, "Mint not open");
        require(block.timestamp < whiteListEndTimestamp ? totalSupply() + whiteListReserve < maxSupply : totalSupply() < maxSupply, "Max supply reached");
        require(hasMint[msg.sender] == false, "Only one mint per wallet");

        hasMint[msg.sender] = true;

        _mint(msg.sender, 1);
    }

    function _baseURI() override internal view virtual returns (string memory) {
        return "ipfs://QmNi723hcDyefCofQLFEWvBzcfnnwJKZYkLbFeDgswtduX/";
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

}