/**
 * @title: Idle Token fully fungible, without gov tokens mgmt and with fees managed at contract level
 * @dev: code is copied from IdleTokenGovernance + IdleTokenHelper + IdleTokenV3_1 from this repo 
 * https://github.com/Idle-Labs/idle-contracts and all governance tokens ref have been stripped out
 * other changes: safemath removed, upgraded to recent oz contracts
 * @summary: ERC20 that holds pooled user funds together
 *           Each token rapresent a share of the underlying pools
 *           and with each token user have the right to redeem a portion of these pools
 * @author: Idle Labs Inc., idle.finance
 */
pragma solidity 0.8.10;
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IERC20Detailed.sol";
import "./interfaces/ILendingProtocol.sol";

contract IdleTokenFungible is Initializable, ERC20Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Detailed;

  uint256 internal constant ONE_18 = 10**18;
  // State variables
  // eg. DAI address
  address public token;
  // Idle rebalancer current implementation address
  address public rebalancer;
  // Address collecting underlying fees
  address public feeAddress;
  // eg. 18 for DAI
  uint256 internal tokenDecimals;
  // Max unlent assets percentage for gas friendly swaps
  uint256 public maxUnlentPerc; // 100000 == 100% -> 1000 == 1%
  // Current fee on interest gained
  uint256 public fee;
  // eg. [cTokenAddress, iTokenAddress, ...]
  address[] public allAvailableTokens;
  // last fully applied allocations (ie when all liquidity has been correctly placed)
  // eg. [5000, 0, 5000, 0] for 50% in compound, 0% fulcrum, 50% aave, 0 dydx. same order of allAvailableTokens
  uint256[] public lastAllocations;
  // eg. cTokenAddress => IdleCompoundAddress
  mapping(address => address) public protocolWrappers;
  // variable used for avoid the call of mint and redeem in the same tx
  bytes32 internal _minterBlock;

  // Events
  event Rebalance(address _rebalancer, uint256 _amount);
  event Referral(uint256 _amount, address _ref);
  uint256 internal constant FULL_ALLOC = 100000;

  // last allocations submitted by rebalancer
  uint256[] internal lastRebalancerAllocations;

  // last saved net asset value (in `token`)
  uint256 public lastNAV;
  // unclaimed fees in `token`
  uint256 public unclaimedFees;
  address public constant TL_MULTISIG = 0xFb3bD022D5DAcF95eE28a6B07825D4Ff9C5b3814;
  address public constant DL_MULTISIG = 0xe8eA8bAE250028a8709A3841E0Ae1a44820d677b;

  // ERROR MESSAGES:
  // 0 = is 0
  // 1 = already initialized
  // 2 = length is different
  // 3 = Not greater then
  // 4 = lt
  // 5 = too high
  // 6 = not authorized
  // 7 = not equal
  // 8 = error on flash loan execution
  // 9 = Reentrancy

  // ###############
  // Initialize methods copied from IdleTokenV3_1.sol, removed unused stuff
  // ###############

  // Used to prevent initialization of the implementation contract
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    token = address(1);
  }

    /**
   * It allows owner to manually initialize new contract implementation
   *
   * @param _protocolTokens : array of protocol tokens supported
   * @param _wrappers : array of wrappers for protocol tokens
   * @param _lastRebalancerAllocations : array of allocations
   */
  function _extraInitialize(
    address[] memory _protocolTokens,
    address[] memory _wrappers,
    uint256[] memory _lastRebalancerAllocations
  ) internal {
    // set all available tokens and set the protocolWrappers mapping in the for loop
    allAvailableTokens = _protocolTokens;
    // set protocol token to gov token mapping
    for (uint256 i = 0; i < _protocolTokens.length; i++) {
      protocolWrappers[_protocolTokens[i]] = _wrappers[i];
    }

    lastRebalancerAllocations = _lastRebalancerAllocations;
    lastAllocations = _lastRebalancerAllocations;
  }

  function _init(
    string calldata _name, // eg. IdleDAI
    string calldata _symbol, // eg. IDLEDAI
    address _token,
    address[] calldata _protocolTokens,
    address[] calldata _wrappers,
    uint256[] calldata _lastRebalancerAllocations
  ) external initializer {
    require(token == address(0), '1');
    // Initialize inherited contracts
    ERC20Upgradeable.__ERC20_init(_name, _symbol);
    OwnableUpgradeable.__Ownable_init();
    ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
    PausableUpgradeable.__Pausable_init();
    // Initialize storage variables
    maxUnlentPerc = 1000;
    token = _token;
    tokenDecimals = IERC20Detailed(_token).decimals();
    // end of old initialize method
    feeAddress = TL_MULTISIG;
    rebalancer = address(0xB3C8e5534F0063545CBbb7Ce86854Bf42dB8872B);
    fee = 15000;

    _extraInitialize(_protocolTokens, _wrappers, _lastRebalancerAllocations);
  }

  // ############### 
  // End initialize
  // ############### 

  // onlyOwner
  // pause deposits
  function pause() external {
    require(msg.sender == TL_MULTISIG || msg.sender == DL_MULTISIG || msg.sender == owner(), '6');
    _pause();
  }

  // unpause deposits
  function unpause() external {
    require(msg.sender == TL_MULTISIG || msg.sender == DL_MULTISIG || msg.sender == owner(), '6');
    _unpause();
  }

  /**
   * It allows owner to modify allAvailableTokens array in case of emergency
   * ie if a bug on a interest bearing token is discovered and reset protocolWrappers
   * associated with those tokens.
   *
   * @param protocolTokens : array of protocolTokens addresses (eg [cDAI, iDAI, ...])
   * @param wrappers : array of wrapper addresses (eg [IdleCompound, IdleFulcrum, ...])
   */
  function setAllAvailableTokensAndWrappers(
    address[] calldata protocolTokens,
    address[] calldata wrappers
  ) external onlyOwner {
    require(protocolTokens.length == wrappers.length, "2");

    address protToken;
    for (uint256 i = 0; i < protocolTokens.length; i++) {
      protToken = protocolTokens[i];
      require(protToken != address(0) && wrappers[i] != address(0), "0");
      protocolWrappers[protToken] = wrappers[i];
    }

    allAvailableTokens = protocolTokens;
  }

  /**
   * It allows owner to set the IdleRebalancerV3_1 address
   *
   * @param _rebalancer : new IdleRebalancerV3_1 address
   */
  function setRebalancer(address _rebalancer)
    external onlyOwner {
      require((rebalancer = _rebalancer) != address(0), "0");
  }

  /**
   * It allows owner to set the fee (1000 == 10% of gained interest)
   *
   * @param _fee : fee amount where 100000 is 100%, max settable is 20%
   */
  function setFee(uint256 _fee)
    external onlyOwner {
      // 100000 == 100% -> 10000 == 10%
      require((fee = _fee) <= FULL_ALLOC / 5, "5");
      if (_fee == 0) {
        unclaimedFees = 0;
      }
  }

  /**
   * It allows owner to set the fee address
   *
   * @param _feeAddress : fee address
   */
  function setFeeAddress(address _feeAddress)
    external onlyOwner {
      require((feeAddress = _feeAddress) != address(0), "0");
  }

  /**
   * It allows owner to set the max unlent asset percentage (1000 == 1% of unlent asset max)
   *
   * @param _perc : max unlent perc where 100000 is 100%
   */
  function setMaxUnlentPerc(uint256 _perc)
    external onlyOwner {
      require((maxUnlentPerc = _perc) <= 100000, "5");
  }

  /**
   * Used by Rebalancer to set the new allocations
   *
   * @param _allocations : array with allocations in percentages (100% => 100000)
   */
  function setAllocations(uint256[] calldata _allocations) external {
    require(msg.sender == rebalancer || msg.sender == owner(), "6");
    _setAllocations(_allocations);
  }

  /**
   * Used by Rebalancer or in openRebalance to set the new allocations
   *
   * @param _allocations : array with allocations in percentages (100% => 100000)
   */
  function _setAllocations(uint256[] memory _allocations) internal {
    require(_allocations.length == allAvailableTokens.length, "2");
    uint256 total;
    for (uint256 i = 0; i < _allocations.length; i++) {
      total += _allocations[i];
    }
    lastRebalancerAllocations = _allocations;
    require(total == FULL_ALLOC, "7");
  }

  // view
  /**
   * Get latest allocations submitted by rebalancer
   *
   * @return : array of allocations ordered as allAvailableTokens
   */
  function getAllocations() external view returns (uint256[] memory) {
    return lastRebalancerAllocations;
  }

  /**
  * Get currently used protocol tokens (cDAI, aDAI, ...)
  *
  * @return : array of protocol tokens supported
  */
  function getAllAvailableTokens() external view returns (address[] memory) {
    return allAvailableTokens;
  }

  /**
   * IdleToken price calculation, in underlying
   *
   * @return : price in underlying token
   */
  function tokenPrice()
    external view
    returns (uint256) {
    return _tokenPrice();
  }

  /**
   * Get APR of every ILendingProtocol
   *
   * @return addresses array of token addresses
   * @return aprs array of aprs (ordered in respect to the `addresses` array)
   */
  function getAPRs()
    external view
    returns (address[] memory addresses, uint256[] memory aprs) {
      address[] memory _allAvailableTokens = allAvailableTokens;

      address currToken;
      addresses = new address[](_allAvailableTokens.length);
      aprs = new uint256[](_allAvailableTokens.length);
      for (uint256 i = 0; i < _allAvailableTokens.length; i++) {
        currToken = _allAvailableTokens[i];
        addresses[i] = currToken;
        aprs[i] = ILendingProtocol(protocolWrappers[currToken]).getAPR();
      }
  }

  /**
   * Get current avg APR of this IdleToken
   *
   * @return avgApr current weighted avg apr
   */
  function getAvgAPR()
    external view
    returns (uint256 avgApr) {
    (uint256[] memory amounts, uint256 total) = _getCurrentAllocations();
    address[] memory _allAvailableTokens = allAvailableTokens;

    // IDLE gov token won't be counted here because is not in allAvailableTokens
    for (uint256 i = 0; i < _allAvailableTokens.length; i++) {
      if (amounts[i] == 0) {
        continue;
      }
      address protocolToken = _allAvailableTokens[i];
      // avgApr = avgApr.add(currApr.mul(weight).div(ONE_18))
      avgApr += ILendingProtocol(protocolWrappers[protocolToken]).getAPR() * amounts[i];
    }

    if (total == 0) {
      return 0;
    }

    avgApr = avgApr / total;
  }

  // external
  /**
   * Used to mint IdleTokens, given an underlying amount (eg. DAI).
   * This method triggers a rebalance of the pools if _skipRebalance is set to false
   * NOTE: User should 'approve' _amount of tokens before calling mintIdleToken
   * NOTE 2: this method can be paused
   *
   * @param _amount : amount of underlying token to be lended
   * @param : not used anymore
   * @param _referral : referral address
   * @return mintedTokens : amount of IdleTokens minted
   */
  function mintIdleToken(uint256 _amount, bool, address _referral)
    external nonReentrant whenNotPaused
    returns (uint256 mintedTokens) {
    _updateFeeInfo();

    _minterBlock = keccak256(abi.encodePacked(tx.origin, block.number));
    // Get current IdleToken price
    uint256 idlePrice = _tokenPrice();
    // transfer tokens to this contract
    IERC20Detailed(token).safeTransferFrom(msg.sender, address(this), _amount);

    mintedTokens = _amount * ONE_18 / idlePrice;
    _mint(msg.sender, mintedTokens);

    lastNAV += _amount;

    if (_referral != address(0)) {
      emit Referral(_amount, _referral);
    }
  }

  /**
   * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
   *
   * @param _amount : amount of IdleTokens to be burned
   * @return redeemedTokens : amount of underlying tokens redeemed
   */
  function redeemIdleToken(uint256 _amount)
    external
    returns (uint256) {
      return _redeemIdleToken(_amount);
  }

  /**
   * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
   *
   * @param _amount : amount of IdleTokens to be burned
   * @return redeemedTokens : amount of underlying tokens redeemed
   */
  function _redeemIdleToken(uint256 _amount)
    internal nonReentrant
    returns (uint256 redeemedTokens) {
      _checkMintRedeemSameTx();
      _updateFeeInfo();
      if (_amount != 0) {
        uint256 price = _tokenPrice();
        uint256 valueToRedeem = _amount * price / ONE_18;
        uint256 balanceUnderlying = _contractBalanceOf(token);

        if (valueToRedeem > balanceUnderlying) {
          redeemedTokens = _redeemHelper(_amount, balanceUnderlying);
        } else {
          redeemedTokens = valueToRedeem;
        }
        // update lastNAV
        lastNAV -= redeemedTokens;
        // burn idleTokens
        _burn(msg.sender, _amount);
        // send underlying minus fee to msg.sender
        _transferTokens(token, msg.sender, redeemedTokens);
      }
  }

  function _redeemHelper(uint256 _amount, uint256 _balanceUnderlying) private returns (uint256 redeemedTokens) {
    address currToken;
    uint256 idleSupply = totalSupply();
    address[] memory _allAvailableTokens = allAvailableTokens;

    for (uint256 i = 0; i < _allAvailableTokens.length; i++) {
      currToken = _allAvailableTokens[i];
      redeemedTokens += _redeemProtocolTokens(
        currToken,
        // _amount * protocolPoolBalance / idleSupply
        _amount * _contractBalanceOf(currToken) / idleSupply // amount to redeem
      );
    }
    // and get a portion of the eventual unlent balance
    redeemedTokens += _amount * _balanceUnderlying / idleSupply;
  }

  /**
   * Dynamic allocate all the pool across different lending protocols if needed,
   * rebalance without params
   *
   * NOTE: this method can be paused
   *
   * @return : whether has rebalanced or not
   */
  function rebalance() external returns (bool) {
    return _rebalance();
  }

  // internal
  /**
   * Get current idleToken price based on net asset value and totalSupply
   *
   * @return price value of 1 idleToken in underlying
   */
  function _tokenPrice() internal view returns (uint256 price) {
    uint256 _totSupply = totalSupply();
    uint256 _tokenDecimals = tokenDecimals;
    if (_totSupply == 0) {
      return 10**(_tokenDecimals);
    }

    uint256 totNav = _getCurrentPoolValue() - unclaimedFees;
    price = (totNav - _calculateFees(totNav)) * ONE_18 / _totSupply; // idleToken price in token wei
  }

  /**
   * Dynamic allocate all the pool across different lending protocols if needed
   *
   * NOTE: this method can be paused
   *
   * @return : whether has rebalanced or not
   */
  function _rebalance()
    internal whenNotPaused
    returns (bool) {
      _updateFeeInfo();
      uint256 _unclaimedFees = unclaimedFees;
      if (_unclaimedFees > 0) {
        // send fees (lastNAV was just updated in _updateFeeInfo)
        _mint(feeAddress, _unclaimedFees * totalSupply() / lastNAV);
        // reset fee counter and update lastNAV
        lastNAV += _unclaimedFees;
        unclaimedFees = 0;
      }

      // check if we need to rebalance by looking at the last allocations submitted by rebalancer
      uint256[] memory rebalancerLastAllocations = lastRebalancerAllocations;
      uint256[] memory _lastAllocations = lastAllocations;
      uint256 lastLen = _lastAllocations.length;
      bool areAllocationsEqual = rebalancerLastAllocations.length == lastLen;
      if (areAllocationsEqual) {
        for (uint256 i = 0; i < lastLen || !areAllocationsEqual; i++) {
          if (_lastAllocations[i] != rebalancerLastAllocations[i]) {
            areAllocationsEqual = false;
            break;
          }
        }
      }

      uint256 balance = _contractBalanceOf(token);

      if (areAllocationsEqual && balance == 0) {
        return false;
      }

      uint256 maxUnlentBalance = _getCurrentPoolValue() * maxUnlentPerc / FULL_ALLOC;
      if (areAllocationsEqual) {
        if (balance > maxUnlentBalance) {
          // mint the difference
          _mintWithAmounts(rebalancerLastAllocations, balance - maxUnlentBalance);
        }
        return false;
      }

      // Instead of redeeming everything during rebalance we redeem and mint only what needs
      // to be reallocated

      // get current allocations in underlying (it does not count unlent underlying)
      (uint256[] memory amounts, uint256 totalInUnderlying) = _getCurrentAllocations();
      // calculate the total amount in underlying that needs to be reallocated
      totalInUnderlying += balance;

      (uint256[] memory toMintAllocations, uint256 totalToMint, bool lowLiquidity) = _redeemAllNeeded(
        amounts,
        // calculate new allocations given the total (not counting unlent balance)
        _amountsFromAllocations(rebalancerLastAllocations, totalInUnderlying - maxUnlentBalance)
      );
      // if some protocol has liquidity that we should redeem, we do not update
      // lastAllocations to force another rebalance next time
      if (!lowLiquidity) {
        // Update lastAllocations with rebalancerLastAllocations
        delete lastAllocations;
        lastAllocations = rebalancerLastAllocations;
      }

      uint256 totalRedeemd = _contractBalanceOf(token);

      if (totalRedeemd <= maxUnlentBalance || totalToMint == 0) {
        return false;
      }

      // Do not mint directly using toMintAllocations check with totalRedeemd
      uint256[] memory tempAllocations = new uint256[](toMintAllocations.length);
      for (uint256 i = 0; i < toMintAllocations.length; i++) {
        // Calc what would have been the correct allocations percentage if all was available
        tempAllocations[i] = toMintAllocations[i] * FULL_ALLOC / totalToMint;
      }

      // partial amounts
      _mintWithAmounts(tempAllocations, totalRedeemd - maxUnlentBalance);

      emit Rebalance(msg.sender, totalInUnderlying);

      return true; // hasRebalanced
  }

  /**
   * Calculate gain and save eventual fees in unclaimedFees
   */
  function _updateFeeInfo() internal {
    // remove fees
    uint256 _currNAV = _getCurrentPoolValue() - unclaimedFees;
    uint256 _fees = _calculateFees(_currNAV);
    if (_fees > 0) {
      unclaimedFees += _fees;
    }
    lastNAV = _currNAV - _fees;
  }

  /**
   * Calculate fees, _currNAV should have fee already accounted excluded
   */
  function _calculateFees(uint256 _currNAV) internal view returns (uint256 _fees) {
    // lastNAV is without fees
    uint256 _lastNAV = lastNAV;
    if (_currNAV > _lastNAV) {
      // calculate new fees (TVLs without old fees)
      _fees = (_currNAV - _lastNAV) * fee / FULL_ALLOC;
    }
  }

  /**
   * Mint specific amounts of protocols tokens
   *
   * @param allocations array of amounts to be minted
   * @param total total amount
   */
  function _mintWithAmounts(uint256[] memory allocations, uint256 total) internal {
    // mint for each protocol and update currentTokensUsed
    uint256[] memory protocolAmounts = _amountsFromAllocations(allocations, total);

    uint256 currAmount;
    address protWrapper;
    address[] memory _tokens = allAvailableTokens;
    address _token = token;
    for (uint256 i = 0; i < protocolAmounts.length; i++) {
      currAmount = protocolAmounts[i];
      if (currAmount != 0) {
        protWrapper = protocolWrappers[_tokens[i]];
        // Transfer _amount underlying token (eg. DAI) to protWrapper
        _transferTokens(_token, protWrapper, currAmount);
        ILendingProtocol(protWrapper).mint();
      }
    }
  }

  /**
   * Calculate amounts from percentage allocations (100000 => 100%)
   *
   * @param allocations array of protocol allocations in percentage
   * @param total total amount
   * @return newAmounts array with amounts
   */
  function _amountsFromAllocations(uint256[] memory allocations, uint256 total)
    internal pure returns (uint256[] memory newAmounts) {
    newAmounts = new uint256[](allocations.length);
    uint256 currBalance;
    uint256 allocatedBalance;

    for (uint256 i = 0; i < allocations.length; i++) {
      if (i == allocations.length - 1) {
        newAmounts[i] = total - allocatedBalance;
      } else {
        currBalance = total * allocations[i] / FULL_ALLOC;
        allocatedBalance += currBalance;
        newAmounts[i] = currBalance;
      }
    }
    return newAmounts;
  }

  /**
   * Redeem all underlying needed from each protocol
   *
   * @param amounts : array with current allocations in underlying
   * @param newAmounts : array with new allocations in underlying
   * @return toMintAllocations : array with amounts to be minted
   * @return totalToMint : total amount that needs to be minted
   */
  function _redeemAllNeeded(
    uint256[] memory amounts,
    uint256[] memory newAmounts
    ) internal returns (
      uint256[] memory toMintAllocations,
      uint256 totalToMint,
      bool lowLiquidity
    ) {
    toMintAllocations = new uint256[](amounts.length);
    ILendingProtocol protocol;
    uint256 currAmount;
    uint256 newAmount;
    address currToken;
    address[] memory _tokens = allAvailableTokens;
    // check the difference between amounts and newAmounts
    for (uint256 i = 0; i < amounts.length; i++) {
      currToken = _tokens[i];
      newAmount = newAmounts[i];
      currAmount = amounts[i];
      protocol = ILendingProtocol(protocolWrappers[currToken]);
      if (currAmount > newAmount) {
        uint256 toRedeem = currAmount - newAmount;
        uint256 availableLiquidity = protocol.availableLiquidity();
        if (availableLiquidity < toRedeem) {
          lowLiquidity = true;
          // remove 1% to be sure it's really available (eg for compound-like protocols)
          toRedeem = availableLiquidity * (FULL_ALLOC-1000) / FULL_ALLOC;
        }
        // redeem the difference
        _redeemProtocolTokens(
          currToken,
          // convert amount from underlying to protocol token
          toRedeem * ONE_18 / protocol.getPriceInToken()
        );
        // tokens are now in this contract
      } else {
        toMintAllocations[i] = newAmount - currAmount;
        totalToMint += toMintAllocations[i];
      }
    }
  }

  /**
   * Get the contract balance of every protocol currently used
   *
   * @return amounts : array with all amounts for each protocol in order,
   *                   eg [amountCompoundInUnderlying, amountFulcrumInUnderlying]
   * @return total : total AUM in underlying
   */
  function _getCurrentAllocations() internal view
    returns (uint256[] memory amounts, uint256 total) {
      // Get balance of every protocol implemented
      address currentToken;
      address[] memory _tokens = allAvailableTokens;
      uint256 tokensLen = _tokens.length;
      amounts = new uint256[](tokensLen);
      for (uint256 i = 0; i < tokensLen; i++) {
        currentToken = _tokens[i];
        amounts[i] = _getPriceInToken(protocolWrappers[currentToken]) * _contractBalanceOf(currentToken) / ONE_18;
        total += amounts[i];
      }
  }

  /**
   * Get the current pool value in underlying
   *
   * @return total : total AUM in underlying
   */
  function _getCurrentPoolValue() internal view
    returns (uint256 total) {
      // Get balance of every protocol implemented
      address currentToken;
      address[] memory _tokens = allAvailableTokens;
      for (uint256 i = 0; i < _tokens.length; ) {
        currentToken = _tokens[i];
        total += _getPriceInToken(protocolWrappers[currentToken]) * _contractBalanceOf(currentToken) / ONE_18;
        unchecked {
          i++;
        }
      }

      // add unlent balance
      total += _contractBalanceOf(token);
  }

  /**
   * Get contract balance of _token
   *
   * @param _token : address of the token to read balance
   * @return total : balance of _token in this contract
   */
  function _contractBalanceOf(address _token) private view returns (uint256) {
    // Original implementation:
    //
    // return IERC20(_token).balanceOf(address(this));

    // Optimized implementation inspired by uniswap https://github.com/Uniswap/uniswap-v3-core/blob/main/contracts/UniswapV3Pool.sol#L144
    //
    // 0x70a08231 -> selector for 'function balanceOf(address) returns (uint256)'
    (bool success, bytes memory data) =
        _token.staticcall(abi.encodeWithSelector(0x70a08231, address(this)));
    require(success);
    return abi.decode(data, (uint256));
  }


  /**
   * Get price of 1 protocol token in underlyings
   *
   * @param _token : address of the protocol token
   * @return price : price of protocol token
   */
  function _getPriceInToken(address _token) private view returns (uint256) {
    return ILendingProtocol(_token).getPriceInToken();
  }

  /**
   * Check that no mint has been made in the same block from the same EOA
   */
  function _checkMintRedeemSameTx() private view {
    require(keccak256(abi.encodePacked(tx.origin, block.number)) != _minterBlock, "9");
  }

  // ILendingProtocols calls
  /**
   * Redeem underlying tokens through protocol wrapper
   *
   * @param _amount : amount of `_token` to redeem
   * @param _token : protocol token address
   * @return tokens : new tokens minted
   */
  function _redeemProtocolTokens(address _token, uint256 _amount)
    internal
    returns (uint256 tokens) {
      if (_amount != 0) {
        // Transfer _amount of _protocolToken (eg. cDAI) to _wrapperAddr
        address _wrapperAddr = protocolWrappers[_token];
        _transferTokens(_token, _wrapperAddr, _amount);
        tokens = ILendingProtocol(_wrapperAddr).redeem(address(this));
      }
  }

  function _transferTokens(address _token, address _to, uint256 _amount) internal {
    IERC20Detailed(_token).safeTransfer(_to, _amount);
  }
}