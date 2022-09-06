// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TCGBridge is AccessControl, ReentrancyGuard {
    bytes32 public constant CHARON_ROLE = keccak256("CHARON_ROLE");

    IERC20 public token;
    bytes32 public chainId;
    uint256 internal nonce = 0;

    //  chainId --> nonce --> True / False
    mapping(bytes32 => mapping(uint256 => bool)) public processedNonces;

    // chainId --> fee
    mapping(bytes32 => uint256) public targetChainFees;

    event Bridged(address sender, uint256 amount, bytes32 targetChain, uint256 nonce);
    event Released(address recipient, uint256 amount, bytes32 sourceChain, uint256 nonce);
    event FeeWithdraw(address withdrawer, uint256 amount);
    event TokenWithdraw(address withdrawer, uint256 amount);
    event FeeSet(address setter, bytes32 chainId, uint256 fee);

    constructor(address _token, bytes32 _chainId) {
        token = IERC20(_token);
        chainId = _chainId;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(CHARON_ROLE, msg.sender);
    }

    function bridge(uint256 _amount, bytes32 _targetChain) external payable nonReentrant {
        uint256 fee = targetChainFees[_targetChain];
        require(msg.value == fee && fee > 0, "Invalid fee provided");
        require(token.transferFrom(msg.sender, address(this), _amount), "Token transfer unsuccessful");
        emit Bridged(msg.sender, _amount, _targetChain, nonce);
        nonce++;
    }

    function release(
        uint256 _amount,
        address _recipient,
        bytes32 _sourceChain,
        uint256 _nonce
    ) external onlyRole(CHARON_ROLE) {
        require(processedNonces[_sourceChain][_nonce] == false, "Released already done");
        require(token.transfer(_recipient, _amount), "Token transfer unsuccessful");
        processedNonces[_sourceChain][_nonce] = true;
        emit Released(_recipient, _amount, _sourceChain, _nonce);
    }

    function withdrawFees() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        (bool success, bytes memory data) = payable(msg.sender).call{value: balance}("");
        require(success, "Withdraw was unsuccessful");
        emit FeeWithdraw(msg.sender, balance);
    }

    function withdrawTokens() external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Token transfer unsuccessful");
        emit TokenWithdraw(msg.sender, balance);
    }

    function setFee(bytes32 _chainId, uint256 _fee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        targetChainFees[_chainId] = _fee;
        emit FeeSet(msg.sender, _chainId, _fee);
    }
}