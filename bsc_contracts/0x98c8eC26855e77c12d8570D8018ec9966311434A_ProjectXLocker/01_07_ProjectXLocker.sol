// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract ProjectXLocker is Ownable {
    using SafeERC20 for IERC20;

    bool public isActive = false;
    bool private initialized = false;

    IERC20 public token;
    address public  reflectionToken;
    uint256 private accReflectionPerShare;
    uint256 private allocatedReflections;
    uint256 public totalAllocated;

    uint256 private constant PRECISION_FACTOR = 1 ether;
    uint256 private constant BLOCKS_PER_DAY = 28800;

    struct Distribution {
        address distributor;        // distributor address
        uint256 alloc;              // allocation token amount
        uint256 duration;           // distributor can unlock after duration in minutes 
        uint256 unlockBlock;        // block number that distributor can unlock
        uint256 reflectionDebt;
        bool claimed;
    }
   
    mapping(address => Distribution) public distributions;
    mapping(address => bool) isDistributor;
    address[] public distributors;

    event AddDistribution(address indexed distributor, uint256 allocation, uint256 duration);
    event UpdateDistribution(address indexed distributor, uint256 allocation, uint256 duration);
    event RemoveDistribution(address indexed distributor);
    event Claim(address indexed distributor, uint256 amount);
    event Harvest(address indexed distributor, uint256 amount);
        
    modifier onlyActive() {
        require(isActive == true, "Not active");
        _;
    }

    constructor () {}

    function initialize(IERC20 _token, address _reflectionToken) external onlyOwner {
        require(initialized == false, "Already initialized");
        initialized = true;

        token = _token;
        reflectionToken = _reflectionToken;
    }

    function addDistribution(address _distributor, uint256 _allocation, uint256 _duration) external onlyOwner {
        require(isDistributor[_distributor] == false, "Already set");

        isDistributor[_distributor] = true;
        distributors.push(_distributor);
        
        Distribution storage _distribution = distributions[_distributor];        
        _distribution.distributor = _distributor;
        _distribution.alloc = _allocation * 10**(IERC20Metadata(address(token)).decimals());
        _distribution.duration = _duration;
        _distribution.unlockBlock = block.number + _duration * BLOCKS_PER_DAY;
        _distribution.reflectionDebt = _allocation * accReflectionPerShare / PRECISION_FACTOR;
        _distribution.claimed = false;

        totalAllocated += _distribution.alloc;

        emit AddDistribution(_distributor, _distribution.alloc, _duration);
    }

    function removeDistribution(address distributor) external onlyOwner {
        require(isDistributor[distributor] == true, "Not found");

        isDistributor[distributor] = false;
        
        Distribution storage _distribution = distributions[distributor];
        require(!_distribution.claimed, "Already claimed");

        totalAllocated -= _distribution.alloc;

        _distribution.distributor = address(0x0);
        _distribution.alloc = 0;
        _distribution.duration = 0;
        _distribution.unlockBlock = 0;
        _distribution.reflectionDebt = 0;

        emit RemoveDistribution(distributor);
    }

    function updateDistribution(address _distributor, uint256 _allocation, uint256 _duration) external onlyOwner {
        require(isDistributor[_distributor] == true, "Not found");

        Distribution storage _distribution = distributions[_distributor];

        require(_distribution.unlockBlock > block.number, "Cannot update");
        totalAllocated -= _distribution.alloc;

        _distribution.alloc = _allocation * 10**(IERC20Metadata(address(token)).decimals());
        _distribution.duration = _duration;
        _distribution.unlockBlock = block.number + _duration * BLOCKS_PER_DAY;
        _distribution.reflectionDebt = _allocation * accReflectionPerShare * PRECISION_FACTOR;
        
        totalAllocated += _distribution.alloc;
        emit UpdateDistribution(_distributor, _distribution.alloc, _duration);
    }

    function claim() external onlyActive {
        require(isDistributor[msg.sender] == true, "Not found");

        Distribution storage _distribution = distributions[msg.sender];
        require(_distribution.unlockBlock <= block.number, "Not unlocked yet");
        require(!_distribution.claimed, "Already claimed");
        
        harvest();
       
        token.safeTransfer(_distribution.distributor, _distribution.alloc);
        _distribution.claimed = true;
        totalAllocated -= _distribution.alloc;

        emit Claim(_distribution.distributor, _distribution.alloc);
    }

    function harvest() public onlyActive {
        if(!isDistributor[msg.sender]) return;
        if(distributions[msg.sender].claimed) return;

        _updatePool();

        Distribution storage _distribution = distributions[msg.sender];
        uint256 amount = _distribution.alloc;
        uint256 pending = amount * accReflectionPerShare / PRECISION_FACTOR - _distribution.reflectionDebt;

        if(pending > 0) {
            IERC20(reflectionToken).safeTransfer(msg.sender, pending);
            allocatedReflections = allocatedReflections - pending;
            emit Harvest(msg.sender, pending);
        }
        _distribution.reflectionDebt = amount * accReflectionPerShare / PRECISION_FACTOR;
    }

    function pendingClaim(address _user) external view returns (uint256) {
        if(!isDistributor[_user]) return 0;
        if(distributions[_user].claimed) return 0;
        if(distributions[_user].unlockBlock > block.number) return 0;

        return distributions[_user].alloc;
    }

    function pendingReflection(address _user) external view returns (uint256) {
        if(!isDistributor[_user]) return 0;
        if(distributions[_user].claimed) return 0;

        uint256 tokenAmt = token.balanceOf(address(this));
        if(tokenAmt == 0 || totalAllocated == 0) return 0;

        Distribution storage _distribution = distributions[_user];

        uint256 reflectionAmt = IERC20(reflectionToken).balanceOf(address(this));
        if(reflectionAmt > allocatedReflections) {
            reflectionAmt = reflectionAmt - allocatedReflections;
        } else {
            reflectionAmt = 0;
        }
        uint256 _accReflectionPerShare = accReflectionPerShare + reflectionAmt * PRECISION_FACTOR / totalAllocated;
        
        uint256 pending = _distribution.alloc * _accReflectionPerShare / PRECISION_FACTOR - _distribution.reflectionDebt;
        return pending;
    }

    function insufficientTokens() external view returns (uint256) {
        uint256 tokenAmt = token.balanceOf(address(this));
        if(tokenAmt >= totalAllocated) return 0;
        return totalAllocated - tokenAmt;
    }

    function setStatus(bool _isActive) external onlyOwner {
        isActive = _isActive;
    }

    function _updatePool() internal {
        uint256 tokenAmt = token.balanceOf(address(this));
        if(tokenAmt == 0 || totalAllocated == 0) return;

        uint256 reflectionAmt = IERC20(reflectionToken).balanceOf(address(this));
        if(reflectionAmt > allocatedReflections) {
            reflectionAmt = reflectionAmt - allocatedReflections;
        } else {
            reflectionAmt = 0;
        }

        accReflectionPerShare += reflectionAmt * PRECISION_FACTOR / totalAllocated;
        allocatedReflections += reflectionAmt;
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

    receive() external payable {}
}