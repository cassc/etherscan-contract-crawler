/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract PixelYachtStaffClubSale is Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1660917600; // 8/19 2pm  
    uint256 public whiteListSaleEndTime = 1660924800; // 8/19 4pm
    uint256 public remainingCount = 1800;  //1800 + 222 

    address public pixelYachtStaffClub;
    bytes32 public whiteListMerkleRoot;

    constructor(address _pixelYachtStaffClub) {
        pixelYachtStaffClub = _pixelYachtStaffClub;
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
        NFT(pixelYachtStaffClub).mint(msg.sender, numberOfTokens);
    }

    function _mint(uint256 numberOfTokens) internal {
        require(numberOfTokens <= remainingCount, "sold out");

        remainingCount -= numberOfTokens;
        NFT(pixelYachtStaffClub).mint(msg.sender, numberOfTokens);
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