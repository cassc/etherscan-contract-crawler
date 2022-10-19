// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract LuckyRooLocker is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool private initialized = false;
    uint256 private constant BLOCKS_PER_DAY = 28800;

    IERC20 public token;
    address public reflectionToken;
    uint256 public constant duration = 12 * 30; // 12 months

    address public member;
    uint256 public allocation;
    uint256 public tokenDebt;
    uint256 public lastClaimBlock;
    uint256 public unlockRate;

    event SetMember(address member, uint256 alloc, uint256 lockDuration, uint256 rate);
    event RemoveMember(address member);
    event Claim(address member, uint256 amount);
    event Harvest(address to, uint256 amount);

    event AdminTokenRecovered(address token, uint256 amount);

    modifier onlyMember() {
        require(msg.sender == member, "caller is not the member");
        _;
    }

    constructor () {}

    function initialize(IERC20 _token, address _reflectionToken) external onlyOwner {
        require(initialized == false, "already initialized");
        initialized = true;

        token = _token;
        reflectionToken = _reflectionToken;
    }

    function setMember(address _member, uint256 _alloc, uint256 _lockDuration) external onlyOwner {
        require(initialized, "not initialized");
        require(member == address(0x0), "already set");

        require(_member != address(0x0), "invalid address");
        require(_alloc > 0, "invalid amount");

        member = _member;
        allocation = _alloc * 10**IERC20Metadata(address(token)).decimals();
        tokenDebt = 0;
        lastClaimBlock = block.number + _lockDuration * BLOCKS_PER_DAY;
        unlockRate = allocation / (duration * BLOCKS_PER_DAY);

        emit SetMember(member, allocation, _lockDuration, unlockRate);
    }

    function removeMember() external onlyOwner {
        member = address(0x0);
        allocation = 0;
        tokenDebt = 0;
        unlockRate = 0;
        lastClaimBlock = 0;
        
        emit RemoveMember(member);
    }

    function claim() external onlyMember nonReentrant{
        uint256 remainAmount = allocation - tokenDebt;
        require(remainAmount > 0, "already claimed");
        require(block.number > lastClaimBlock, "not available to claim");

        uint256 amount = unlockRate * (block.number - lastClaimBlock);
        if(amount > remainAmount) {
            amount = remainAmount;
        }
        tokenDebt += amount;
        lastClaimBlock = block.number;

        token.safeTransfer(msg.sender, amount);
        emit Claim(msg.sender, amount);
    }

    function harvest(address _to) external onlyMember nonReentrant {
        uint256 amount = address(this).balance;
        if(reflectionToken == address(0x0)) {
            payable(_to).transfer(amount);
            emit Harvest(_to, amount);
            return;
        }
        
        amount = IERC20(reflectionToken).balanceOf(address(this));
        if(reflectionToken == address(token)) {
            uint256 remainAmount = allocation - tokenDebt;
            if(remainAmount > amount) return;

            amount -= remainAmount;
        }

        IERC20(reflectionToken).safeTransfer(_to, amount);
        emit Harvest(_to, amount);
    }

    function pendingClaim() external view returns (uint256) {
        if(member == address(0x0)) return 0;
        if(block.number < lastClaimBlock) return 0;

        uint256 remainAmount = allocation - tokenDebt;
        uint256 amount = unlockRate * (block.number - lastClaimBlock);
        if(amount > remainAmount) {
            amount = remainAmount;
        }

        return amount;
    }

    function pendingReflection() external view returns (uint256) {
        if(member == address(0x0)) return 0;
        if(reflectionToken == address(0x0)) {
            return address(this).balance;
        }

        uint256 amount = IERC20(reflectionToken).balanceOf(address(this));
        if(reflectionToken == address(token)) {
            uint256 remainAmount = allocation - tokenDebt;
            if(remainAmount > amount) return 0;

            amount -= remainAmount;
        }
        return amount;
    }

    function insufficientTokens() external view returns(uint256) {
        uint256 remainAmount = allocation - tokenDebt;
        uint256 amount = token.balanceOf(address(this));
        if(amount > remainAmount) return 0;
        return remainAmount - amount;
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 tokenAmt = token.balanceOf(address(this));
        if(tokenAmt > 0) {
            token.transfer(msg.sender, tokenAmt);
        }
        
        if(address(token) == reflectionToken) return;
        if(reflectionToken == address(0x0)) {
            uint256 amount = address(this).balance;
            payable(msg.sender).transfer(amount);
        } else {
            uint256 amount = IERC20(reflectionToken).balanceOf(address(this));
            IERC20(reflectionToken).transfer(msg.sender, amount);
        }
    }

    function rescueTokens(address _token) external onlyOwner {
        require(
            _token != address(token) && _token != reflectionToken,
            "Cannot be token or dividend token"
        );

        uint256 _amount = address(this).balance;
        if (_token == address(0x0)) {
            payable(msg.sender).transfer(_amount);
        } else {
            _amount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit AdminTokenRecovered(_token, _amount);
    }

    receive() external payable {}
}