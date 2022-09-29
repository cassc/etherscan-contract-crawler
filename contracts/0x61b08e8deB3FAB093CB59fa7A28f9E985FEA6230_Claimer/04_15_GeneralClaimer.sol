// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './IClaimer.sol';
import './WithDiamondHands.sol';

abstract contract GeneralClaimer is IClaimer, Ownable {
    using SafeERC20 for IERC20;

    string public override id;
    address public override token;
    address[] public accounts;
    // When a wallet is hacked, we transfer user's claims to a new account. We use the map to
    mapping(address => address) public transferredAccountsMap;
    address[2][] public transferredAccounts;
    
    uint256 public totalTokens;
    uint256 public totalClaimedTokens;

    uint256 public pausedAt;

    event ClaimingPaused(bool status, uint256 pausedAt);
    event AllocationTransferred(address indexed account, address indexed newAccount);

    function getAccounts(uint256 _unused) public view override returns (address[] memory) {
        return accounts;
    }
    
    function getTransferredAccounts() public view override returns (address[2][] memory) {
        return transferredAccounts;
    }

    function isPaused() public view override returns (bool) {
        return pausedAt > 0;
    }
    
    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function pauseClaiming(bool status) external onlyOwner {
        pausedAt = status ? block.timestamp : 0;
        emit ClaimingPaused(status, pausedAt);
    }

    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }

        IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
    }

    function withdrawToken(address _token, uint256 amount) external onlyOwner {
        IERC20(_token).transfer(owner(), amount);
    }

    function transferTokens(address to, uint256 amount) internal {
        IERC20(token).transfer(to, amount);
    }
    
    function setTransferredAccounts(address[2][] calldata _transferred) external onlyOwner {
        transferredAccounts = _transferred;
    }
    
    function getAccountRemaining(address account) internal view virtual returns (uint256);
    
    function setAllocation(address account, uint256 newTotal) external virtual;
    
    function transferAllocation(address from, address to) external virtual;

    function batchAddAllocation(address[] calldata addresses, uint256[] calldata amounts) external virtual;

    function batchAddAllocationWithClaimed(
        address[] calldata addresses,
        uint256[] calldata allocations,
        uint256[][] calldata claimed
    ) external virtual;
}