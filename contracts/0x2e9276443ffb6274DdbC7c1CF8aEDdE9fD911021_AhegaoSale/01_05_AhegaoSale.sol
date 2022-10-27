/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract AhegaoSale is Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    uint256 public whiteListSaleStartTime = 1666832400; // 10/26 21:00 EST
    uint256 public whiteListSaleEndTime = 1666843200; // 10/27 00:00  EST
    uint256 public remainingCount = 2700;  //2700 + 300 
    uint256 public salePrice = 0.069 ether;
    uint256 public maxPurchaseQuantity = 3; 

    address public ahegao;
    bytes32 public whiteListMerkleRoot;
    mapping(address => uint256) public addressPurchased;

    constructor(address _ahegao) {
        ahegao = _ahegao;
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
        require(addressPurchased[msg.sender] + numberOfTokens <= maxPurchaseQuantity, "total quantity exceeds maxPurcahedQuantity");
        
        if(addressPurchased[msg.sender] >= 1){
            require(msg.value >= numberOfTokens * salePrice, "send value incorrect");
        }else{
            require(msg.value >= (numberOfTokens - 1) * salePrice, "send value incorrect");
        }

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
        NFT(ahegao).mint(msg.sender, numberOfTokens);
        addressPurchased[msg.sender] += numberOfTokens;
    }

    function _mint(uint256 numberOfTokens) internal {
        require(numberOfTokens <= remainingCount, "sold out");

        remainingCount -= numberOfTokens;
        NFT(ahegao).mint(msg.sender, numberOfTokens);
        addressPurchased[msg.sender] += numberOfTokens;
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
        uint256 _remainingCount,
        uint256 _salePrice,
        uint256 _maxPurchaseQuantity
    ) external onlyOwner {
        whiteListSaleStartTime = _whiteListSaleStartTime;
        whiteListSaleEndTime = _whiteListSaleEndTime;
        remainingCount = _remainingCount;
        salePrice = _salePrice;
        maxPurchaseQuantity = _maxPurchaseQuantity;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }
}