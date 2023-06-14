// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract NonFungibleZine is ERC721, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;

    // Define starting contract state
    bytes32 merkleRoot;
    bool merkleSet = false;
    bool public earlyAccessMode = true;
    bool public mintingIsActive = false;
    bool public reservedZines = false;
    string public baseURI = "";
    uint256 public randPrime;
    uint256 public timestamp;
    uint256 public constant maxSupply = 1000;
    uint256 public constant maxMints = 2;

    constructor() ERC721("Non-Fungible Zine", "NFZ") {}

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or pause
    function toggleMinting() external onlyOwner {
        if (mintingIsActive) {
            mintingIsActive = false;
        } else {
            mintingIsActive = true;
        }
    }

    // Flip the early access mode to allow/disallow public minting vs whitelist
    function toggleEarlyAccessMode() external onlyOwner {
        if (earlyAccessMode) {
            earlyAccessMode = false;
        } else {
            earlyAccessMode = true;
        }
    }

    // Specify a randomly generated prime number (off-chain), only once
    function setRandPrime(uint256 _randPrime) public onlyOwner {
        if (randPrime == 0) {
            randPrime = _randPrime;
        }
    }

    // Specify a new IPFS URI for metadata
    function setBaseURI(string memory URI) public onlyOwner {
        baseURI = URI;
    }

    // Get total supply based upon counter
    function tokensMinted() public view returns (uint256) {
        return _tokenSupply.current();
    }

    // Specify a merkle root hash from the gathered k/v dictionary of
    // addresses and their claimable amount of tokens - thanks Kiwi!
    // https://github.com/0xKiwi/go-merkle-distributor
    function setMerkleRoot(bytes32 root) external onlyOwner {
        merkleRoot = root;
        merkleSet = true;
    }

    // Return bool on if merkle root hash is set
    function isMerkleSet() public view returns (bool) {
        return merkleSet;
    }

    // Internal mint function with proper "random-ish" logic
    function _mintZines(uint256 numberOfTokens) private {
        require(randPrime > 0, "Random prime number must be specified by contract owner before minting");
        require(numberOfTokens > 0, "Must mint at least 1 token");

        // Specify the block timestamp of the first mint to define NFT distribution
        if (timestamp == 0) {
            timestamp = block.timestamp;
        }

        // Mint i tokens where i is specified by function invoker
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenIndex = tokensMinted() + 1; // Start at 1
            uint256 seq = randPrime * tokenIndex;
            uint256 seqOffset = seq + timestamp;
            uint256 tokenId = (seqOffset % maxSupply) + 1; // Prevent tokenId 0
            _safeMint(msg.sender, tokenId);
            _tokenSupply.increment();
        }

        // Disable minting if max supply of tokens is reached
        if (tokensMinted() == maxSupply) {
            mintingIsActive = false;
        }
    }

    // Reserve some zines for giveaways
    function reserveZines() public onlyOwner {
        // Only allow one-time reservation
        if (!reservedZines) {
            _mintZines(20);
            reservedZines = true;
        }
    }

    // Claim and mint tokens
    function mintZines(
      uint256 index,
      address account,
      uint256 amount,
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    ) external {
        require(mintingIsActive, "Minting is not active.");
        require(numberOfTokens <= maxMints, "Cannot mint more than 2");
        require(tokensMinted().add(numberOfTokens) <= maxSupply, "Minting would exceed max supply");
        require(balanceOf(msg.sender).add(numberOfTokens) <= maxMints, "Minting would exceed maximum amount of 2 tokens per wallet.");

        if (earlyAccessMode) {
            require(merkleSet, "Merkle root not set by contract owner");
            require(msg.sender == account, "Can only be claimed by the hodler");
            // Verify merkle proof
            bytes32 node = keccak256(abi.encodePacked(index, account, amount));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid merkle proof");
        }

        _mintZines(numberOfTokens);
    }

    // Override the below functions from parent contracts

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }
}