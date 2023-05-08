// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


// Twitter: https://twitter.com/pupes_gambit

// In the land of crypto, Pupe is found,
// A token with rules that are truly profound,
// It rests to grow, rewards to bestow,
// Hold it close, and your assets will grow.

// Sleep or wake, the limits are set,
// As time unfolds, rewards you'll get,
// Give it Pepe, its energy to restore,
// Tokenomics are strong, you'll see for sure.

// When Pupes are left, abandoned and sad,
// Adopt and share, their fate's not all bad,
// A portion you'll gain, of their worth,
// A second chance, they'll have a rebirth.

// Welcome to Pupe, a token unique,
// In a world of cryptos, it stands mystique,
// Embrace its charm, follow the trend,
// In Pupe's embrace, your wealth will ascend.


contract Pupe is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public pepeAddress; 
    address public uniswapV2Pair;

    struct PupeOwner {
        uint256 sleepStart;
        uint256 sleepEnd;  // how long pupe has been awake for
        uint256 pepeDebt;  // the total rewards before pupe goes to sleep
        uint256 shareSize;  // amount * sleep time
    }
    mapping(address => PupeOwner) public owners;

    uint256 public minSleep;
    uint256 public maxSleep;
    uint256 public timeToAbandon;
    
    // for things like waking up: pupeAmount = pepeAmount * pepeScalingFactor
    uint256 public pepeScalingFactor;
    // total shares asleep
    uint256 public totalShares;
    uint256 public totalAsleep;

    mapping(address => uint256) private transferableAmount;

    // total accumulated pepe
    uint256 public accPepePerShare;
    mapping(address => uint256) private queuedRewards;

    //////  EVENTS  //////
    event Sleep(
        address indexed user, 
        uint256 duration
    );
    event Stroke(
        address indexed from, 
        address indexed to, 
        uint256 amountPepe
    );
    event Claim(
        address indexed user, 
        uint256 amountPepe
    );
    event Adopted(
        address indexed from, 
        address indexed to, 
        uint256 amountAdoptd
    );

    constructor(
        uint256 _totalSupply
    ) ERC20("Pupe", "PUPE") ReentrancyGuard() {
        _mint(msg.sender, _totalSupply);
    }

    //////  OWNER FUNCTIONS  //////

    function setUniPair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function setPepeAddress(IERC20 _pepe) external onlyOwner {
        pepeAddress = _pepe;
    }

    function setParamaters(
        uint256 _time,
        uint256 _min, 
        uint256 _max,
        uint256 _scalingFactor
    ) external onlyOwner {
        timeToAbandon = _time;
        minSleep = _min;
        maxSleep = _max;
        pepeScalingFactor = _scalingFactor;
    }
    
    //////  PUBLIC FUNCTIONS  //////

    // gib pupe some rest so he has energy to move
    function sleep(uint256 _seconds) external {
        uint256 userBalance = balanceOf(msg.sender);

        require(
            userBalance > 0, 
            "no pupe to put to sleep"
        );
        require(
            minSleep <= _seconds 
            && _seconds <= maxSleep, 
            "sleep duration not permitted"
        );

        // store pending rewards etc
        _refreshState(msg.sender);

        PupeOwner storage owner = owners[msg.sender];
        owner.sleepStart = block.timestamp;
        owner.sleepEnd = block.timestamp + _seconds;
        owner.shareSize = userBalance * _seconds;

        // can't claim any rewards from before sleep time
        owner.pepeDebt = (accPepePerShare * owner.shareSize) / 1e12;
        totalShares += owner.shareSize;

        emit Sleep(msg.sender, block.timestamp + _seconds);
    }

    // keeps pupe loyal - can gib 0 pepe to keep him happy
    function stroke(address _ownerAddress, uint256 _pepeAmount) external {
        require(balanceOf(_ownerAddress) > 0, "address doesn't own pupe");
        require(
            block.timestamp > owners[_ownerAddress].sleepEnd, 
            "can't stroke sleeping pupe"
        );

        PupeOwner storage owner = owners[_ownerAddress];
        owner.sleepEnd = block.timestamp;  // delays when pupe will abandon

        if (_pepeAmount > 0) {
            // unlocks an amount of pupe to be able to be transferred / swapped
            transferableAmount[_ownerAddress] += _pepeAmount * pepeScalingFactor;
            
            if (totalShares > 0) {
                accPepePerShare += (_pepeAmount * 1e12) / totalShares;
            }

            IERC20(address(pepeAddress)).safeTransferFrom(
                msg.sender, 
                address(this), 
                _pepeAmount
            );
        }
        emit Stroke(msg.sender, _ownerAddress, _pepeAmount);
    }

    // wakeup someones Pupe before their sleep ends
    function wake(address _ownerAddress) external {
        uint256 pepeAmount = costWake(_ownerAddress);
        require(pepeAddress.balanceOf(msg.sender) >= pepeAmount, "insufficient pepe");

        if (totalShares > 0) {
            accPepePerShare += (pepeAmount * 1e12) / totalShares;
        }
        _refreshState(_ownerAddress);

        IERC20(address(pepeAddress)).safeTransferFrom(
            msg.sender, 
            address(this), 
            pepeAmount
        );
    }

    // claim all pending pepe rewards - doesn't wake pupe up if asleep
    function claim() external nonReentrant {
        _queuePending(msg.sender);

        uint256 pending = queuedRewards[msg.sender];
        require(pending > 0, "no pending rewards");

        // reset rewards for future claims
        queuedRewards[msg.sender] = 0;
        owners[msg.sender].pepeDebt = (
            accPepePerShare * owners[msg.sender].shareSize
        ) / 1e12;
    
        pepeAddress.transfer(msg.sender, pending);
        emit Claim(msg.sender, pending);
    }

    // burns the total amount lost, then mints 50% of that to the message sender
    function adopt(address _ownerAddress) public nonReentrant {
        require(block.timestamp > abandonTime(_ownerAddress), "address not abandoned");

        uint256 adoptAmount = balanceOf(_ownerAddress);
        _burn(_ownerAddress, adoptAmount);
        _mint(msg.sender, adoptAmount / 2);
        emit Adopted(_ownerAddress, msg.sender, adoptAmount/2);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(
            block.timestamp < abandonTime(recipient)
            && block.timestamp < abandonTime(msg.sender), 
            "cannot transfer to/from abandoned address"
        );
        // only run checks once Uni pool begins
        bool tradingEnabled = uniswapV2Pair != address(0);

        _refreshState(msg.sender); 
        if (
            tradingEnabled
            && msg.sender != uniswapV2Pair 
            && msg.sender != owner()
        ) {
            require(
                transferableAmount[msg.sender] >= amount, 
                "cannot transfer that much"
            );
            transferableAmount[msg.sender] -= amount;
        }
        if (
            tradingEnabled
            && recipient != uniswapV2Pair 
            && recipient != uniswapV2Pair
        ) {
            require(
                amount >= minTransferIn(recipient), 
                "insufficient amount to wake up"
            );
        }
        _refreshState(recipient);

        return super.transfer(recipient, amount);
    }

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    //////  PUBLIC VIEWS  //////

    // amount of pepe strokes required to be able to transfer this amount
    function costStroke(address _ownerAddress, uint256 _amount)
        external 
        view 
        returns (uint256) 
    {
        require(block.timestamp > owners[_ownerAddress].sleepEnd, "can't stroke sleeping pupe");

        uint256 maxTransfer = maxTransferOut(_ownerAddress);
        if (maxTransfer >= _amount) {
            return 0;  // address has sufficient to transfer amount
        }
        return (_amount - maxTransfer) / pepeScalingFactor;
    }

    // the amount of pepe it would cost to wake up someones pupe
    function costWake(address _ownerAddress) public view returns (uint256) {
        if (
            block.timestamp > owners[_ownerAddress].sleepEnd 
            || balanceOf(_ownerAddress) == 0
        ) {
            return 0;
        }
        PupeOwner memory owner = owners[_ownerAddress];
        uint256 initialPupe = owner.shareSize / (owner.sleepEnd - owner.sleepStart);
        return (initialPupe - pendingPupe(_ownerAddress)) / pepeScalingFactor;
    }

    // anyone that doesn't own any pupe gets maxTime remaining
    function abandonTime(address _ownerAddress) 
        public 
        view 
        returns (uint256)  
    {
        uint256 maxTimeAbandon = block.timestamp + timeToAbandon;
        if (
            uniswapV2Pair  == address(0)
            || _ownerAddress == uniswapV2Pair
            || _ownerAddress == owner()
            || balanceOf(_ownerAddress) == 0
        ) {
            return maxTimeAbandon;
        }

        if (block.timestamp <= owners[_ownerAddress].sleepEnd) {
            // add the time remaining from current sleep
            return maxTimeAbandon + (owners[_ownerAddress].sleepEnd - block.timestamp);
        } else {
            return maxTimeAbandon - (block.timestamp - owners[_ownerAddress].sleepEnd);
        }
    }

    // how many pepe this pupe owner can claim
    function pendingPepe(address _ownerAddress) public view returns (uint256) {
        
        uint256 sleepRewards = (accPepePerShare * owners[_ownerAddress].shareSize) / 1e12;
        if (sleepRewards > 0) {
            sleepRewards -= owners[_ownerAddress].pepeDebt;
        }
        return queuedRewards[_ownerAddress] + sleepRewards;
    }

    // the amount of pupe tranferrable due to sleep
    function pendingPupe(address _ownerAddress) public view returns (uint256) {
        PupeOwner memory owner = owners[_ownerAddress];
        if (owner.sleepStart == 0) {
            return 0;  // address has never slept
        }
        uint256 maxDuration = (owner.sleepEnd - owner.sleepStart);
        uint256 maxAmount = owner.shareSize / maxDuration;
        if (block.timestamp >= owner.sleepEnd) {
            return maxAmount;
        }
        return (
            maxAmount * (block.timestamp - owner.sleepStart)
        ) / maxDuration;
    }

    // amount of pupe to transfer to this address if you want to wake up
    function minTransferIn(address _ownerAddress) public view returns (uint256)  {
        if (_ownerAddress == uniswapV2Pair) {
            return 0;
        }
        return costWake(_ownerAddress) * pepeScalingFactor;
    }

    // maximum amount of pupe that can be sent from this address at current timestamp
    function maxTransferOut(address _ownerAddress) public view returns (uint256)  {
        if (_ownerAddress == uniswapV2Pair) {
            return type(uint256).max;
        }
        uint256 maxTransfer = transferableAmount[_ownerAddress];
        if (block.timestamp > owners[_ownerAddress].sleepStart) {
            // amount from latest sleep
            maxTransfer += pendingPupe(_ownerAddress);
        }
        return maxTransfer;
    }

    function _refreshState(address _ownerAddress) internal {
        _queuePending(_ownerAddress);

        PupeOwner storage owner = owners[_ownerAddress];
        owner.sleepEnd = block.timestamp;
        owner.pepeDebt = (
            accPepePerShare * owner.shareSize
        ) / 1e12;

        totalShares -= owner.shareSize;
        owner.shareSize = 0;
    }

    // store the amount of pepe and pupe rewards earned
    function _queuePending(address _ownerAddress) internal {
        // queue pupe rewards
        transferableAmount[_ownerAddress] += pendingPupe(_ownerAddress);
        queuedRewards[_ownerAddress] = pendingPepe(_ownerAddress);
    }
}