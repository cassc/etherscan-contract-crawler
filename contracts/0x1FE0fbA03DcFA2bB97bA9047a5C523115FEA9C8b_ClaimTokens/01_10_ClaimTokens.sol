// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface TokenDecimal {
    function decimals() external returns (uint8);
}

contract ClaimTokens is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 private token;
    bytes32 public root;

    uint256 public totalClaimed;

    address private tokenHolder;

    mapping(address => bool) public isClaimed;

    event Claimed(address indexed tokenAddress, address indexed user, uint256 amount, uint256 indexed timestamp);

    constructor(address _token, address _tokenholder, bytes32 _root) {
        token = IERC20(_token);
        tokenHolder = _tokenholder;
        root = _root;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
       return MerkleProof.verify(proof, root, leaf);
    }

    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function _getToken() external view returns(IERC20) {
        return token;
    }

    function _setToken(IERC20 _token) external onlyOwner {
        token = _token;
    }

    function _getTokenHolder() external view returns(address) {
        return tokenHolder;
    }

    function _setTokenHolder(address _tokenholder) external onlyOwner {
        tokenHolder = _tokenholder;
    }

    function Claim(uint256 _amount, bytes32[] memory proof) external nonReentrant whenNotPaused {
        require(msg.sender != address(0), "CONTRACT: Caller is zero address");
        require(!isClaimed[msg.sender], "CONTRACT: Tokens already claimed!!");
        require(address(token) != address(0), "CONTRACT: Token is not set.");
        require(isValid(proof, keccak256(abi.encodePacked(msg.sender, _amount))), "Caller not whitelisted");

        uint256 claimedTokens = _amount;
        totalClaimed += claimedTokens;
        token.safeTransferFrom(tokenHolder, msg.sender, claimedTokens);
        isClaimed[msg.sender] = true;
        emit Claimed(address(token), msg.sender, claimedTokens, block.timestamp);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    fallback() external payable {}

    receive() external payable {}
}