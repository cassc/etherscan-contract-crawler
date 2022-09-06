/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract LostInTheDevilTriangleSale is Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1661011200; // 8/20 4pm  
    uint256 public whiteListSaleEndTime = 1661097600; // 8/21 4pm
    uint256 public remainingCount = 1800;  //1800 + 222 

    address public lostInTheDevilTriangle;
    bytes32 public whiteListMerkleRoot;

    constructor(address _lostInTheDevilTriangle) {
        lostInTheDevilTriangle = _lostInTheDevilTriangle;
    }

    /* ************** */
    /* USER FUNCTIONS */
    /* ************** */
    function mint(bytes32[] calldata proof, uint256 numberOfTokens)
        external
        payable
        nonReentrant
    {
        require(tx.origin == msg.sender, "contract not allowed");
        require(block.timestamp > whiteListSaleStartTime, "whiteList Sale hasn't started");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");

        if (block.timestamp <= whiteListSaleEndTime) {
            _mintWhiteList(proof, numberOfTokens);
        } else {
            _mint(numberOfTokens);
        }
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _mintWhiteList(bytes32[] calldata proof, uint256 numberOfTokens)
        internal
    {
        require(numberOfTokens <= remainingCount, "sold out");
        require(
            MerkleProof.verify(
                proof,
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "failed to verify first WL merkle root"
        );

        remainingCount -= numberOfTokens;
        NFT(lostInTheDevilTriangle).mint(msg.sender, numberOfTokens);
    }

    function _mint(uint256 numberOfTokens) internal {
        require(numberOfTokens <= remainingCount, "sold out");

        remainingCount -= numberOfTokens;
        NFT(lostInTheDevilTriangle).mint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function setSaleData(
        uint256 _whiteListSaleStartTime,
        uint256 _whiteListSaleEndTime,
        uint256 _remainingCount
    ) external onlyOwner {
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        remainingCount = _remainingCount;
    }
}