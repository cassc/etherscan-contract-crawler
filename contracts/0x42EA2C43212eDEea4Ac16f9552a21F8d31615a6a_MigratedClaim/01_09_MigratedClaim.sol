// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract MigratedClaim is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    IERC20 claimToken;
    address public signer;
    mapping(address => bool) public claims;
    mapping(address => mapping(uint256 => bool)) public bonusClaims; // nonce'd

    /**
     * Admin
     */

    constructor(IERC20 _claimToken) {
        require(address(_claimToken) != address(0), "E0"); // E0: addr err
        claimToken = _claimToken;
        signer = msg.sender;
    }

    function setClaimToken(IERC20 _claimToken) external onlyOwner {
        claimToken = _claimToken;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * Public
     */

    function claim(uint256 _amount, bytes calldata _signature) external {
        require(!claims[msg.sender], "Already claimed");
        require(_verifySignerSignature(
            keccak256(abi.encode(msg.sender, _amount)),
            _signature
        ), "Invalid signature");

        claims[msg.sender] = true;
        claimToken.transfer(msg.sender, _amount);
    }

    function bonusClaim(uint256 _amount, uint256 _nonce, bytes calldata _signature) external {
        require(!bonusClaims[msg.sender][_nonce], "Already claimed");
        require(_verifySignerSignature(
            keccak256(abi.encode(msg.sender, _amount, _nonce)),
            _signature
        ), "Invalid signature");

        bonusClaims[msg.sender][_nonce] = true;
        claimToken.transfer(msg.sender, _amount);
    }

    /**
     * Private
     */

    function _verifySignerSignature(bytes32 _hash, bytes calldata _signature) private view returns (bool) {
        return _hash.toEthSignedMessageHash().recover(_signature) == signer;
    }
}