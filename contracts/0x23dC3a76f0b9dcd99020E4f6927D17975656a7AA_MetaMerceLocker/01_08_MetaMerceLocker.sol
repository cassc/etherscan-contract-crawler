// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Brewlabs
 * This contract has been developed by brewlabs.info
 */
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract MetaMerceLocker is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool private initialized = false;

    IERC20 public token;
    address public reflectionToken;
    uint256 public lockDuration = 90;

    uint256 private accReflectionPerShare;
    uint256 private allocatedReflections;
    uint256 private totalAllocated;
    uint256 public totalDistributed;

    uint256 private constant PRECISION_FACTOR = 1 ether;

    struct Distribution {
        address distributor;        // distributor address
        uint256 alloc;              // allocation token amount
        uint256 unlockBlock;         // block number to unlock
        bool claimed;
    }
   
    mapping(address => Distribution) public distributions;
    mapping(address => bool) isDistributor;
    address[] public distributors;

    event AddDistribution(address indexed distributor, uint256 allocation, uint256 duration, uint256 unlockBlock);
    event UpdateDistribution(address indexed distributor, uint256 allocation, uint256 duration, uint256 unlockBlock);
    event WithdrawDistribution(address indexed distributor, uint256 amount, uint256 reflection);
    event RemoveDistribution(address indexed distributor);
    event UpdateLockDuration(uint256 Days);

    constructor () {}

    function initialize(IERC20 _token, address _reflectionToken) external onlyOwner {
        require(!initialized, "already initialized");
        initialized = true;

        token = _token;
        reflectionToken = _reflectionToken;
    }

    function addDistribution(address distributor, uint256 allocation) external onlyOwner {
        require(!isDistributor[distributor], "already set");

        isDistributor[distributor] = true;
        distributors.push(distributor);

        uint256 allocationAmt = allocation.mul(10**IERC20Metadata(address(token)).decimals());
        
        Distribution storage _distribution = distributions[distributor];
        _distribution.distributor = distributor;
        _distribution.alloc = allocationAmt;
        _distribution.unlockBlock = block.number.add(lockDuration.mul(6426));

        totalDistributed += allocationAmt;

        emit AddDistribution(distributor, allocationAmt, lockDuration, _distribution.unlockBlock);
    }

    function removeDistribution(address distributor) external onlyOwner {
        require(isDistributor[distributor], "Not found");
        require(!distributions[distributor].claimed, "Already claimed");

        isDistributor[distributor] = false;
        totalDistributed -= distributions[distributor].alloc;

        Distribution storage _distribution = distributions[distributor];
        _distribution.distributor = address(0x0);
        _distribution.alloc = 0;
        _distribution.unlockBlock = 0;

        emit RemoveDistribution(distributor);
    }

    function updateDistribution(address distributor, uint256 allocation) external onlyOwner {
        require(isDistributor[distributor] == true, "Not found");

        Distribution storage _distribution = distributions[distributor];
        require(!_distribution.claimed, "already withdrawn");
        require(_distribution.unlockBlock > block.number, "cannot update");
        
        uint256 allocationAmt = allocation.mul(10**IERC20Metadata(address(token)).decimals());
        totalDistributed += allocationAmt - _distribution.alloc;

        _distribution.distributor = distributor;
        _distribution.alloc = allocationAmt;
        _distribution.unlockBlock = block.number.add(lockDuration.mul(6426));

        emit UpdateDistribution(distributor, allocationAmt, lockDuration, _distribution.unlockBlock);
    }

    function withdrawDistribution(address _user) external onlyOwner {
        require(claimable(_user) == true, "not claimable");
        
        _updatePool();

        Distribution storage _distribution = distributions[_user];
        uint256 pending = _distribution.alloc.mul(accReflectionPerShare).div(PRECISION_FACTOR);
        if(pending > 0) {
            IERC20(reflectionToken).safeTransfer(_user, pending);
            allocatedReflections = allocatedReflections.sub(pending);
        }

        totalDistributed -= _distribution.alloc;
        _distribution.claimed = true;
        if(totalAllocated > _distribution.alloc) {
            totalAllocated = totalAllocated - _distribution.alloc;
        } else {
            totalAllocated = 0;
        }

        token.safeTransfer(_distribution.distributor, _distribution.alloc);

        emit WithdrawDistribution(_distribution.distributor, _distribution.alloc, pending);
    }

    function pendingReflection(address _user) external view returns (uint256) {
        if(isDistributor[_user] == false) return 0;
        if(totalDistributed == 0) return 0;

        uint256 reflectionAmt = availableDividendTokens();
        if(reflectionAmt < allocatedReflections) return 0;
        reflectionAmt = reflectionAmt - allocatedReflections;

        uint256 _accReflectionPerShare = accReflectionPerShare.add(reflectionAmt.mul(PRECISION_FACTOR).div(totalDistributed));
        
        Distribution storage _distribution = distributions[_user];
        if(_distribution.claimed) return 0;
        return _distribution.alloc.mul(_accReflectionPerShare).div(PRECISION_FACTOR);
    }

    function claimable(address _user) public view returns (bool) {
        if(!isDistributor[_user]) return false;
        if(distributions[_user].claimed) return false;
        if(distributions[_user].unlockBlock < block.number) return true;

        return false;
    }

    function availableAllocatedTokens() public view returns (uint256) {
        if(address(token) == reflectionToken) return totalAllocated;
        return token.balanceOf(address(this));
    }

    function availableDividendTokens() public view returns (uint256) {
        if(reflectionToken == address(0x0)) {
            return address(this).balance;
        }

        uint256 _amount = IERC20(reflectionToken).balanceOf(address(this));        
        if(reflectionToken == address(token)) {
            if(_amount < totalAllocated) return 0;
            _amount = _amount - totalAllocated;
        }

        return _amount;
    }

    function setLockDuration(uint256 _days) external onlyOwner {
        require(_days > 0, "Invalid duration");

        lockDuration = _days;
        emit UpdateLockDuration(_days);
    }

    function depositToken(uint256 _amount) external onlyOwner {
        require(_amount > 0, "invalid amount");

        uint256 beforeAmt = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 afterAmt = token.balanceOf(address(this));

        totalAllocated = totalAllocated + afterAmt - beforeAmt;
    }

    function emergencyWithdraw() external onlyOwner {
        uint256 tokenAmt = token.balanceOf(address(this));
        if(tokenAmt > 0) {
            token.transfer(msg.sender, tokenAmt);
        }

        uint256 reflectionAmt = IERC20(reflectionToken).balanceOf(address(this));
        if(reflectionAmt > 0) {
            IERC20(reflectionToken).transfer(msg.sender, reflectionAmt);
        }
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _token: the address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function rescueTokens(address _token) external onlyOwner {
        require(_token != address(token) && _token != address(reflectionToken), "Cannot be token & dividend token");

        if(_token == address(0x0)) {
            uint256 _tokenAmount = address(this).balance;
            payable(msg.sender).transfer(_tokenAmount);
        } else {
            uint256 _tokenAmount = IERC20(_token).balanceOf(address(this));
            IERC20(_token).safeTransfer(msg.sender, _tokenAmount);
        }
    }

    function _updatePool() internal {
        if(totalDistributed == 0) return;

        uint256 reflectionAmt = availableDividendTokens();
        if(reflectionAmt < allocatedReflections) return;
        reflectionAmt = reflectionAmt - allocatedReflections;

        accReflectionPerShare = accReflectionPerShare.add(reflectionAmt.mul(PRECISION_FACTOR).div(totalDistributed));
        allocatedReflections = allocatedReflections.add(reflectionAmt);
    }
    
    receive() external payable {}
}