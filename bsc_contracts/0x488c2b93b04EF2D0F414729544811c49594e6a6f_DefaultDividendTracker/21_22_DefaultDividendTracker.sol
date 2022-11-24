// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./DividendPayingTokenInterface.sol";
import "../IterableMapping.sol";
import "../IRematic.sol";
import "../Interface/IPool.sol";
import "../PancakeswapInterface/IPancakeRouter02.sol";


/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {

        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20Upgradeable, ERC20BurnableUpgradeable, OwnableUpgradeable, UUPSUpgradeable, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  address public  REWARD;

  address public rematicAdminAddress;

  IPancakeRouter02  public pancakeSwapV2Router;
  address public  pancakeSwapPair;
  address public  rematicAddress;

  modifier onlyRematicAdmin() {
      require(rematicAdminAddress == address(msg.sender), "Message sender needs to be RematicAdmin Contract");
      _;
  }

  uint256 public totalDividendsDistributed;


  function __DividendPayingToken_init(address reward_, address rematicAddress_) internal onlyInitializing {
    __DividendPayingToken_init_unchained(reward_, rematicAddress_);
  }

  function __DividendPayingToken_init_unchained(address reward_, address rematicAddress_) internal onlyInitializing {
      REWARD = reward_;
      rematicAddress = rematicAddress_;
  }

  function _authorizeUpgrade(address newImplementaion) internal override onlyOwner {}

  function setRematicAddress(address _rematicAddress) public onlyOwner {
    require(rematicAddress != _rematicAddress, "already set same value");
    rematicAddress = _rematicAddress;
  }

  function distributeRewardDividends(uint256 amount) public onlyRematicAdmin {
    require(totalSupply() > 0);
    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude).div(totalSupply())
      );
      emit DividendsDistributed(msg.sender, amount);
      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.1
  function withdrawDividend() public virtual override {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  /// @notice Withdraws the ether distributed to the sender.
  /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn ether is greater than 0.
 function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
    }
    return _withdrawableDividend;
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }


  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe().div(magnitude);
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {

    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }

  }
}

contract DefaultDividendTracker is DividendPayingToken {

    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => uint256) public excludedAccountMap;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    uint256 public gasForProcessing;
    mapping (address => uint256) public holdersDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);
    event Claimed(address indexed account, uint256 amount);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    function initialize(
        address _reward,
        address _rematicAddress
    ) public initializer{

      __DividendPayingToken_init(_reward, _rematicAddress);
      
      __ERC20_init("RMTXv3_Dividend_Tracker", "RMTXv3_Dividend_Tracker");
      __Ownable_init();

      // init
      claimWait = 3600;
      minimumTokenBalanceForDividends = 200000 * (10**18); //must hold 200000+ tokens;
      gasForProcessing = 300000;

    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "RFTX_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "RFTX_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main  MetaRise contract.");
    }

    function _excludeFromDividendsByAdminContract(address account) external onlyRematicAdmin {

    	excludedFromDividends[account] = true;
    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
      
    }

    function excludeFromDividends(address account, bool flag) public onlyOwner {

      require(!excludedFromDividends[account] == flag, "Same value!");
    	excludedFromDividends[account] = flag;

      if(flag){
        excludedAccountMap[account] = tokenHoldersMap.get(account);
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
      }else{
        tokenHoldersMap.set(account, excludedAccountMap[account]);
        _setBalance(account, excludedAccountMap[account]);
      }
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 86400, "RFTX_Dividend_Tracker: claimWait must be updated greater than 24 hours");
        require(newClaimWait != claimWait, "RFTX_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function setLastProcessedIndex(uint256 index) external onlyOwner {
    	lastProcessedIndex = index;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) :0;
    }

    // function getAccountAtIndex(uint256 index)
    //     public view returns (
    //         address,
    //         int256,
    //         int256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256) {
    // 	if(index >= tokenHoldersMap.size()) {
    //         return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
    //     }

    //     address account = tokenHoldersMap.getKeyAtIndex(index);

    //     return getAccount(account);
    // }

    function getAccountAtIndex(uint256 index) public view returns (address) {
    	if(index >= tokenHoldersMap.size()) {
            return address(0);
        }
        address account = tokenHoldersMap.getKeyAtIndex(index);
        return account;
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }
    
    function setBalance(address payable account, uint256 newBalance) external onlyRematicAdmin {

      if(excludedFromDividends[account]) {
        if(newBalance >= minimumTokenBalanceForDividends) {
          excludedAccountMap[account] = newBalance;
        } else {
          excludedAccountMap[account] = 0;
        }
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
          _setBalance(account, newBalance);
          tokenHoldersMap.set(account, newBalance);
      } else {
          _setBalance(account, 0);
          tokenHoldersMap.remove(account);
      }
    }

    function process() external onlyRematicAdmin returns (uint256, uint256, uint256) {

    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;
    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

      uint256 _lastProcessedIndex = lastProcessedIndex;
      uint256 gasUsed = 0;
      uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gasForProcessing && _lastProcessedIndex < numberOfTokenHolders) {

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
    			if(processAccount(payable(account), true)) {
    				claims++;
    			}
    		}

    		iterations++;

        uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

        _lastProcessedIndex++;

    		gasLeft = newGasLeft;

    	}

      if(_lastProcessedIndex == tokenHoldersMap.keys.length) {
    		lastProcessedIndex = 0;
    	}else{
        lastProcessedIndex = _lastProcessedIndex;
      }
      
    	return (iterations, claims, _lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyRematicAdmin returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        holdersDividends[account] = holdersDividends[account].add(amount);
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
          return true;
        }
    	return false;
    }

    function setRematicAdmin (address _address) public onlyOwner {
        require(_address != address(rematicAdminAddress), "RFTX Admin: The rematicAdminAddress already has that address");
        rematicAdminAddress = _address;
    }

    function setRewardToken(address _address) public onlyRematicAdmin {
        require(REWARD != _address, "already same value");
        REWARD = _address;
    }

    receive() external payable {
        // custom function code
    }

    function withdrawToken(address token, address account) public onlyOwner {

        uint256 balance =IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(account, balance);

    }

    function withdrawBNB(address _to) public onlyOwner {
        (bool success, ) = address(_to).call{value: address(this).balance}(new bytes(0));
        require(success, "Withdraw is failed");
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "RFTX-DividendTracker: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "RFTX-DividendTracker: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function claimDividend() external {
      require(holdersDividends[msg.sender] > 0, "Empty amount for this account");
      uint256 divAmount = holdersDividends[msg.sender];
      holdersDividends[msg.sender] = 0;
      bool success = IERC20(REWARD).transfer(msg.sender, divAmount);
      if(success) {
        emit Claimed(msg.sender, divAmount);
      }
    }

    function ClaimOnBehalfOf(address _pool) external onlyOwner {
      require(holdersDividends[_pool] > 0, "Empty amount for this account");
      uint256 divAmount = holdersDividends[_pool];
      holdersDividends[_pool] = 0;
      bool success = IERC20(REWARD).transfer(_pool, divAmount);

      if(success) {
      // recalucate reflection tokens in the pool
        IPool(_pool)._calculateReflections();
        emit Claimed(_pool, divAmount);
      }
    }

    function updateClaimDivAmount(address account, uint256 _amount) public onlyOwner {
      require(holdersDividends[account] != _amount, "Same value");
      holdersDividends[account] = _amount;
    }
}