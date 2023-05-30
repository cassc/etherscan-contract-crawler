// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";


// soupXmondrian commemorative drop for Patrn/Art101 hodlers.
// A snapshot of addresses holding our NFTs and the amounts they can claim
// will be gathered at a specific time. Distribution will be done via
// merkle tree proof to allow users to claim their tokens.
contract soupXmondrian is ERC1155, Ownable {
    using SafeMath for uint256;
    using MerkleProof for bytes32[];

    // Track indexes (users) which have claimed their tokens
    mapping(uint256 => uint256) private claimedBitMap;

    // Define starting contract state
    bytes32 merkleRoot;
    bool merkleSet = false;
    bool public mintingActive = false;
    string public baseURI = "ipfs://QmRTqBFtst7j1Yj63xDXDEmg43rethZ8dAAy4WDvwieqKo/{id}";

    constructor() ERC1155(baseURI) {}

    // Flip the minting from active or pause
    function toggleMinting() external onlyOwner {
        if (mintingActive) {
            mintingActive = false;
        } else {
            mintingActive = true;
        }
    }

    // Specify a new IPFS URI for metadata
    function setBaseURI (string memory newURI) external onlyOwner {
        baseURI = newURI;
        _setURI(baseURI);
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
    function mintItem(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external {
        require(mintingActive, "Minting must be active");
        require(amount <= 2, "Max amount that can be claimed is 2");
        require(msg.sender == account, "Can only be claimed by the hodler");
        require(!isClaimed(index), "Drop already claimed");

        // Verify the merkle proof
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid proof");

        // Mark it claimed and proceed with minting
        _setClaimed(index);

        // Mint tokens, ensuring uniques if multiple
        for(uint256 i = 0; i < amount; i++) {
            uint256 tokenId = ((block.number + i) % 3) + 1;
            _mint(msg.sender, tokenId, 1, "");
        }
    }

}