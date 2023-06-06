// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";


contract Bauhaus is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    // Track indexes (users) which have claimed their tokens
    mapping(uint256 => uint256) private claimedBitMap;
    mapping(address => uint256) private amountClaimable;
    mapping(address => uint256) private amountClaimed;

    // Define starting contract state
    bytes32 merkleRoot;
    bool merkleSet = false;
    bool public mintingActive = false;
    bool public earlyAccessMode = true;
    string public baseURI = "ipfs://QmVwRivM4b48tYc9tp7ixMNHQJWkQunyWXonJowvtgfHFz/";
    uint256 public randPrime;
    uint256 public timestamp;
    uint256 public constant maxItemPurchase = 20;
    uint256 public constant maxItems = 8192;

    constructor() ERC721("Bauhaus Blocks", "BB") {}

    // Withdraw contract balance to creator (mnemonic seed address 0)
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    // Flip the minting from active or pause
    function toggleMinting() external onlyOwner {
        if (mintingActive) {
            mintingActive = false;
        } else {
            mintingActive = true;
        }
    }

    // Flip the early access mode to allow/disallow public
    // minting instead of merkle-drop whitelist
    function toggleEarlyAccessMode() external onlyOwner {
        if (earlyAccessMode) {
            earlyAccessMode = false;
        } else {
            earlyAccessMode = true;
        }
    }

    // Specify a new IPFS URI for metadata
    function setBaseURI (string memory newURI) external onlyOwner {
        baseURI = newURI;
    }

    // Specify a randomly generated prime number (off-chain), only once
    function setRandPrime(uint256 _randPrime) public onlyOwner {
        if (randPrime == 0) {
            randPrime = _randPrime;
        }
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

    // Check if an index has claimed tokens
    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    // Store if an index has claimed their tokens
    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    // Mint and claim tokens
    function mintItem(
      uint256 index,
      address account,
      uint256 amount,
      bytes32[] calldata merkleProof,
      uint256 numberOfTokens
    ) external {
        require(numberOfTokens > 0, "Must provide at least 1");
        require(randPrime > 0, "Random prime number must be specified by contract operator before minting");
        require(mintingActive, "Minting must be active");
        require(numberOfTokens <= 20, "Cannot mint more than 20 at a time");
        require(totalSupply().add(numberOfTokens) <= maxItems, "Minting would exceed max supply");

        if (earlyAccessMode) {
            require(msg.sender == account, "Can only be claimed by the hodler");
            require(!isClaimed(index), "Drop already claimed");
            // Verify merkle proof
            bytes32 node = keccak256(abi.encodePacked(index, account, amount));
            require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");
            // Update the claimable amount for address
            if (amountClaimable[msg.sender] == 0) {
                amountClaimable[msg.sender] = amount;
            }
            // Ensure not trying to mint more than claimable
            require(amountClaimed[msg.sender].add(numberOfTokens) <= amountClaimable[msg.sender], "Cannot mint more than what is claimable");
        } else {
            require(numberOfTokens <= 6, "Cannot mint more than 6 at a time while not in early access mode");
        }

        // Specify the block timestamp of the first mint to define NFT distribution
        if (timestamp == 0) {
            timestamp = block.timestamp;
        }

        // Mint i tokens where i is specified by function invoker
        for(uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenIndex = totalSupply() + 1; // Start at 1
            uint256 seq = randPrime * tokenIndex;
            uint256 seqOffset = seq + timestamp;
            uint256 tokenId = (seqOffset % maxItems) + 1; // Prevent tokenId 0
            if (totalSupply() < maxItems) {
                // Mint and transfer to the contract invoker
                _safeMint(msg.sender, tokenId);
                if (earlyAccessMode) {
                    // Increment amount claimed counter while in earlyAccessMode
                    amountClaimed[msg.sender] = amountClaimed[msg.sender].add(1);
                    if (amountClaimed[msg.sender] == amountClaimable[msg.sender]) {
                        // Mark it claimed and proceed with minting
                        _setClaimed(index);
                    }
                }
            }
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}