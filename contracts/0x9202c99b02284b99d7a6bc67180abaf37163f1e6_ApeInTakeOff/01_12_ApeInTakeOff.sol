// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ApeInTakeOff is ERC1155Supply, Ownable {
    using ECDSA for bytes32;
    address private _signerAddress = 0xEF1f611A5D34ee2ceC474AbC212d625362329BC0;

    uint256 constant APE_CLAIMABLE = 3000;
    uint256 constant APE_CODES = 450;

    mapping(address => uint256) public claimedAmount;
    mapping(bytes32 => bool) private _usedCodeHashes;
    uint256 public claimedCounter;
    uint256 public claimedCodesCounter;
    bool public claimingLive;

    constructor() ERC1155("https://ipfs.io/ipfs/QmQRLUCqYPU54L3ASJaFdjqamSvWYKfekhuQmZQUeQpTaw/{id}") {}

    function verifyClaim(address sender, uint256 claimableAmount, bytes calldata signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, claimableAmount));
        return _signerAddress == hash.recover(signature);
    }
    
    function verifyCode(address sender, bytes32 codeHash, bytes calldata signature) private view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, codeHash));
        return _signerAddress == hash.recover(signature);
    }

    function claim(uint256 claimableAmount, bytes calldata signature) external {
        require(claimingLive, "NOT_LIVE");
        require(verifyClaim(msg.sender, claimableAmount, signature), "INVALID_TRANSACTION");

        uint256 unclaimedAmount = claimableAmount - claimedAmount[msg.sender];
        require(unclaimedAmount > 0, "ALREADY_CLAIMED_MAX");
        require(claimedCounter + unclaimedAmount <= APE_CLAIMABLE, "MAX_CLAIMED");

        claimedAmount[msg.sender] += unclaimedAmount;
        claimedCounter += unclaimedAmount;
        _mint(msg.sender, 2, unclaimedAmount, "");
    }

    function claimCode(bytes32 codeHash, bytes calldata signature) external {
        require(claimingLive, "NOT_LIVE");
        require(verifyCode(msg.sender, codeHash, signature), "INVALID_TRANSACTION");

        require(claimedCodesCounter < APE_CODES, "MAX_CLAIMED");
        require(!_usedCodeHashes[codeHash], "CODE_USED");

        _usedCodeHashes[codeHash] = true;
        claimedCodesCounter++;
        _mint(msg.sender, 2, 1, "");
    }

    function setSignerAddress(address signer) external onlyOwner {
        _signerAddress = signer;
    }

    function toggleClaiming() external onlyOwner {
        claimingLive = !claimingLive;
    }
}