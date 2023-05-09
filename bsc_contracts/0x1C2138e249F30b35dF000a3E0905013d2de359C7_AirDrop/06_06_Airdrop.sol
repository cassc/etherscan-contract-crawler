//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AirDrop is
    Ownable,
    Pausable,
    ReentrancyGuard
{

    IERC20 public tokenAddress;

    uint256 public totalWalletClaimed;
    uint256 public totalTokenClaimed;
    mapping (address => uint256) public whiteListClaimed;
    mapping (address => bool) public addressClaimed;
    bool public isClaim;

    event Claimed(address claimedAddress, uint256 amountToken);
    event EmergencyWithdraw(address emergencyWallet, uint256 amount);

    constructor(
        address _tokenAddress
    ) {
        tokenAddress = IERC20(_tokenAddress);
        isClaim = false;
        totalWalletClaimed = 0;
        totalTokenClaimed = 0;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        tokenAddress = IERC20(_tokenAddress);
    }

    function setClaim(bool _isClaim) external onlyOwner {
        isClaim = _isClaim;
    }

    function addWhiteList(address[] memory _wallets, uint256[] memory _amounts) external whenNotPaused onlyOwner{
        for (uint256 i = 0; i < _wallets.length; i++ ){
            whiteListClaimed[_wallets[i]] = _amounts[i];
        }
    }

    function claim() external whenNotPaused nonReentrant {
        address sender = msg.sender;
        require(whiteListClaimed[sender] > 0, "You aren't on whitelist or you claimed!");
        require(!addressClaimed[sender], "You claimed!");
        require(isClaim, "Cannot claim!");
        uint256 totalClaim = whiteListClaimed[sender];
        if (totalClaim >= tokenAddress.balanceOf(address(this))){
            totalClaim = tokenAddress.balanceOf(address(this));
        }
        whiteListClaimed[sender] = 0;
        addressClaimed[sender] = true;
        totalWalletClaimed += 1;
        totalTokenClaimed += totalClaim;
        tokenAddress.transfer(sender, totalClaim);
        emit Claimed(sender, totalClaim);
    }

    function emergencyWithdraw(address _emergencyWallet) external onlyOwner {
        require(
            _emergencyWallet != address(0),
            "Emergency wallet have not set yet"
        );
        uint256 balanceOfThis = tokenAddress.balanceOf(address(this));
        if (balanceOfThis > 0) {
            tokenAddress.transfer(_emergencyWallet, balanceOfThis);
        }
        emit EmergencyWithdraw(_emergencyWallet, balanceOfThis);
    }

}