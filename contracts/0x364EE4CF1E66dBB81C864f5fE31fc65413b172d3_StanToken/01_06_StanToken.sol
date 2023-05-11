pragma solidity ^0.8.0;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "openzeppelin/contracts/access/Ownable.sol";

contract StanToken is ERC20, Ownable {
    uint256 public transferDelay;
    uint256 public maxTransferAmount;
    uint256 public botProtectionEndTime;

    mapping(address => uint256) private _lastTransferTimestamp;
    mapping(address => bool) public blacklistedAddresses;

    constructor(
        uint256 initialSupply,
        uint256 _transferDelay,
        uint256 _maxTransferAmount,
        uint256 _botProtectionDuration
    ) ERC20("Stan Token", "STAN") {
        _mint(msg.sender, initialSupply);
        transferDelay = _transferDelay;
        maxTransferAmount = _maxTransferAmount;
        botProtectionEndTime = block.timestamp + _botProtectionDuration;
    }

    function addToBlacklist(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            blacklistedAddresses[users[i]] = true;
        }
    }

    function removeFromBlacklist(address[] memory users) external onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            blacklistedAddresses[users[i]] = false;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!blacklistedAddresses[msg.sender], "Address blacklisted");
        require(amount <= maxTransferAmount, "Amount exceeds maximum transfer limit");

        if (block.timestamp < botProtectionEndTime) {
            require(
                block.timestamp >= (_lastTransferTimestamp[msg.sender] + transferDelay),
                "Transfer too soon"
            );
            _lastTransferTimestamp[msg.sender] = block.timestamp;
        }

        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!blacklistedAddresses[sender], "Address blacklisted");
        require(amount <= maxTransferAmount, "Amount exceeds maximum transfer limit");

        if (block.timestamp < botProtectionEndTime) {
            require(
                block.timestamp >= (_lastTransferTimestamp[sender] + transferDelay),
                "Transfer too soon"
            );
            _lastTransferTimestamp[sender] = block.timestamp;
        }

        return super.transferFrom(sender, recipient, amount);
    }
}