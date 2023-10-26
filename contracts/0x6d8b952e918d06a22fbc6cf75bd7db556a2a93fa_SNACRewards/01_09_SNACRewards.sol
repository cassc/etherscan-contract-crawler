// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract SNACRewards is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.UintSet;

    address public signerAddress;
    address public ERC20Address;
    mapping(address => EnumerableSet.UintSet) seenNonces;

    constructor(address _ERC20Adress) {
        _pause();
        ERC20Address = _ERC20Adress;
    }

    function withdrawERC20Balance(address _address) external onlyOwner {
        uint256 contractBalance = IERC20(ERC20Address).balanceOf(address(this));
        IERC20(ERC20Address).transfer(_address, contractBalance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setERC20Address(address _ERC20Address) external onlyOwner {
        ERC20Address = _ERC20Address;
    }

    function setSigner(address _signer) external onlyOwner {
        signerAddress = _signer;
    }

    function verifySignature(
        bytes memory signature,
        uint256 reward,
        uint256 nonce
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, reward, nonce, address(this)));
        bytes32 messageHash = hash.toEthSignedMessageHash();
        return messageHash.recover(signature) == signerAddress;
    }

    function claimReward(
        bytes memory signature,
        uint256 reward,
        uint256 nonce
    ) external whenNotPaused nonReentrant {
        require(verifySignature(signature, reward, nonce), "Invalid transaction");
        require(!seenNonces[msg.sender].contains(nonce), "Used signature");

        seenNonces[msg.sender].add(nonce);
        IERC20(ERC20Address).transfer(msg.sender, reward * 10**18);
    }
}