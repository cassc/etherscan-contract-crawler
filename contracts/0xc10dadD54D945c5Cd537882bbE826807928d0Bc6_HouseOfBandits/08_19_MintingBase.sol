// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// abstract contract MintingBase is Ownable, ReentrancyGuard {
//     uint8 public maxTxs;
//     mapping(address => uint256) public mintTxs;

//     uint256 public mintPrice;

//     bytes32 public merkleRoot;

//     constructor(
//         uint8 _maxTxs,
//         uint256 _mintPrice,
//         bytes32 _merkleRoot
//     ) {
//         maxTxs = _maxTxs;
//         mintPrice = _mintPrice;
//         merkleRoot = _merkleRoot;
//     }

//     function setPrice(uint256 _mintPrice) external onlyOwner {
//         mintPrice = _mintPrice;
//     }

//     function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
//         merkleRoot = _merkleRoot;
//     }

//     modifier mintingIsOpen(
//         uint256 _startTime,
//         uint256 _endTime,
//         string memory _windowName
//     ) {
//         require(
//             block.timestamp >= _startTime && block.timestamp <= _endTime,
//             string(abi.encodePacked(_windowName, " mint is closed"))
//         );

//         _;
//     }

//     modifier limitTxs() {
//         require(
//             mintTxs[msg.sender] < maxTxs,
//             "Max amount of transactions reached"
//         );

//         _;
//     }

//     modifier onlyAllowList(bytes32[] calldata _merkleProof) {
//         bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
//         require(
//             MerkleProof.verify(_merkleProof, merkleRoot, leaf),
//             "Incorrect proof"
//         );

//         _;
//     }
// }


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract MintingBase is Ownable, ReentrancyGuard {
    mapping(address => uint256) public mintTxs;

    uint256 public mintPrice;

    constructor(uint256 _mintPrice) {
        mintPrice = _mintPrice;
    }

    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    modifier mintingIsOpen(
        uint256 _startTime,
        uint256 _endTime,
        string memory _windowName
    ) {
        require(
            block.timestamp >= _startTime && block.timestamp <= _endTime,
            string(abi.encodePacked(_windowName, " mint is closed"))
        );

        _;
    }
}