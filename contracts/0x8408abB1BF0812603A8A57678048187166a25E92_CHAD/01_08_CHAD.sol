// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract CHAD is ERC20, Ownable {
    using ECDSA for bytes32;

    bool public isPaused = true;
    bool public isTokenCapLock = false;

    uint256 public MAX_SUPPLY;

    address private _signer;
    mapping(address => bool) private _tokenClaimed;
    mapping(uint256 => bool) private _nonceUsed;

    event TokenClaimed(address indexed owner, uint256 amount);

    constructor(address signerAddrs) ERC20("CHAD", "CHAD") {
        _signer = signerAddrs;
    }

    function claimRewards(uint256 amount, uint256 nonce, bytes calldata signature) external {
        require(!isPaused, "Claiming process is paused!");
        require(_validateSignature(amount, nonce, signature, msg.sender), "Invalid signer");
        require(!_nonceUsed[nonce], "Nonce already used");
        require(!_tokenClaimed[msg.sender], "Already claimed");

        uint256 rewards = amount * (10**18);
        _nonceUsed[nonce] = true;
        _tokenClaimed[msg.sender] = true;
        _mint(msg.sender, rewards);

        emit TokenClaimed(msg.sender, rewards);
    }

    function checkClaimStatus(address user) external view returns(bool) {
        return _tokenClaimed[user];
    }

    function getMaxSupply() public view returns (uint256) {
        require(isTokenCapLock, "Max supply is not set");
        return MAX_SUPPLY;
    }

    function _validateSignature(uint256 amount, uint256 nonce, bytes calldata signature, address sender) private view returns(bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(amount, nonce, sender));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == _signer);
    }

    function flipPause() external onlyOwner {
        isPaused = !isPaused;
    }

    function mintFor(address user, uint256 amount) external onlyOwner {
        if (isTokenCapLock) require(totalSupply() + amount <= MAX_SUPPLY, "You try to mint more than max supply");
        _mint(user, amount);
    }

    function setTokenCap(uint256 tokenCap) external onlyOwner {
        require(totalSupply() < tokenCap, "Value is smaller than the number of existing tokens");
        require(!isTokenCapLock, "Token cap has been already set");

        MAX_SUPPLY = tokenCap;
    }

    function setTokenCapLock() external onlyOwner {
        isTokenCapLock = true;
    }

    function setSigner(address signerAddrs) external onlyOwner {
        _signer = signerAddrs;
    }

    function burn(uint256 _amount) external onlyOwner {
        _burn(msg.sender, _amount);
    }
}