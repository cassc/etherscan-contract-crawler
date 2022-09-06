// SPDX-License-Identifier: MIT
//Azzzzzzzz.eth
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface NFT {
    function mint(address to, uint256 quantity) external;
}

contract MagiqzooSale is Ownable, ReentrancyGuard {

    uint256 public saleTime = 1660356000; // 8/13 10:00pm (GMT + 8)
    uint256 public saleEndTime = 1660528800; // 8/15 10:00pm (GMT +8)
    uint256 public salePrice = 0.9 ether;
    uint256 public remainingCount = 20;

    address public magiqzoo;
    bytes32 public whiteListMerkleRoot;
    mapping(address => bool) public addressPurchased;

    constructor(address _magiqzoo) {
        magiqzoo = _magiqzoo;
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
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        _mint(proof, numberOfTokens);
    }

    /* ****************** */
    /* INTERNAL FUNCTIONS */
    /* ****************** */

    function _mint(bytes32[] calldata proof, uint256 numberOfTokens) internal {
        require(block.timestamp >= saleTime, "Sale hasn't started" );
        require(block.timestamp < saleEndTime, "Sale has been over");
        require(numberOfTokens <= remainingCount, "sold out");
        require(!addressPurchased[msg.sender], "WL already bought");
        require(msg.value >= salePrice * numberOfTokens, "sent ether value incorrect");
        require(
            MerkleProof.verify(
                proof,
                whiteListMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "failed to verify first WL merkle root"
        );

        addressPurchased[msg.sender] = true;
        remainingCount -= numberOfTokens;
        NFT(magiqzoo).mint(msg.sender, numberOfTokens);
    }

    /* *************** */
    /* ADMIN FUNCTIONS */
    /* *************** */

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        whiteListMerkleRoot = _merkleRoot;
    }

    function setSaleData(
        uint256 _saleTime,
        uint256 _saleEndTime,
        uint256 _salePrice,
        uint256 _remainingCoung
    ) external onlyOwner {
        saleTime = _saleTime;
        saleEndTime = _saleEndTime;
        salePrice = _salePrice;
        remainingCount = _remainingCoung;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "sent value failed");
    }
}