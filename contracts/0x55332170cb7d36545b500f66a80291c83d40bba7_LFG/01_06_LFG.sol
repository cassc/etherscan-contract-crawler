pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IERC20.sol";


// $$\       $$$$$$$$\  $$$$$$\  
// $$ |      $$  _____|$$  __$$\ 
// $$ |      $$ |      $$ /  \__|
// $$ |      $$$$$\    $$ |$$$$\ 
// $$ |      $$  __|   $$ |\_$$ |
// $$ |      $$ |      $$ |  $$ |
// $$$$$$$$\ $$ |      \$$$$$$  |
// \________|\__|       \______/ 
                                                                                                         


contract LFG is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  address burn = 0x000000000000000000000000000000000000dEaD;
  address public daoContractAddress;
  address public tokenPairAddress;
  address public royaltyAddress = 0x8e3E7850b360B9C152481aDd56b7A510880495e7; 

  mapping (address => uint256) private _reserveTokenBalance;
  mapping (address => uint256) private _circulatingTokenBalance;
  mapping (address => mapping (address => uint256)) private _allowances;

  mapping (address => bool) private _isExcluded;
  address[] private _excluded;

  // The highest possible number.
  uint256 private constant MAX = ~uint256(0);

  // For the purpose of the bank analogy, this is the circulating supply as opposed to the reserve supply.
  // This value never changes. Burning tokens don't reduce this supply, they just get sent to a burn address. Minting doesn't exist.
  uint256 private constant _totalSupply = 200000000000 * 10**6 * 10**9;

  // Total reserve amount. The amount must be divisible by the circulating supply to reduce rounding errors in calculations,
  // hence the calculation of a remainder
  uint256 private _totalReserve = (MAX - (MAX % _totalSupply));

  // Total accumulated transaction fees.
  uint256 private _transactionFeeTotal;

  // Duration of initial sell tax.
  bool private initialSellTaxActive = false;

  // Once the initial sell tax is set once, it cannot be set again.
  bool private initialSellTaxSet = false;

  uint8 private _decimals = 9;
  string private _symbol = "LFG";
  string private _name = "Lets Fucking GO!";

  // Struct for storing calculated transaction reserve values, fixes the error of too many local variables.
  struct ReserveValues {
    uint256 reserveAmount;
    uint256 reserveFee;
    uint256 reserveTransferAmount;
    uint256 reserveTransferAmountDao;
    uint256 reserveTransferAmountMooncakeRoyalty; 
  }

  // Struct for storing calculated transaction values, fixes the error of too many local variables.
  struct TransactionValues {
    uint256 transactionFee;
    uint256 transferAmount;
    uint256 netTransferAmount;
    uint256 daoTax;
    uint256 mooncakeRoyalty;
  }

  constructor(
    address _daoContractAddress,
    address _opsWallet
  ) {
    daoContractAddress = _daoContractAddress;

    // 50% backhole burn. The burn address receives reflect, further accelerating the token's deflationary scheme.
    uint256 blackHole = _totalSupply.div(2);

    // 30% of remaining tokens for presale. 
    uint256 presale = blackHole.mul(3).div(10);

    // 59% to deployer for LP addition
    uint256 lp = blackHole.mul(59).div(100);

    // 10% to the DAO
    uint256 dao = blackHole.div(10);

    // 1% royalty
    uint256 royalty = blackHole.div(100);
        
    // ratio of reserve to total supply
    uint256 rate = getRate();
    
    _reserveTokenBalance[burn] = blackHole.mul(rate);
    _reserveTokenBalance[_opsWallet] = presale.mul(rate);
    _reserveTokenBalance[_msgSender()] = lp.mul(rate);
    _reserveTokenBalance[_daoContractAddress] = dao.mul(rate);
    _reserveTokenBalance[royaltyAddress] = royalty.mul(rate);
    
    emit Transfer(
      address(0),
      burn,
      blackHole
    );
    emit Transfer(
      address(0),
      _opsWallet,
      presale
    );
    emit Transfer(
      address(0),
      _msgSender(),
      lp
    );
    emit Transfer(
      address(0),
      _daoContractAddress,
      dao
    );
    emit Transfer(
      address(0),
      royaltyAddress,
      royalty
    );
  }

  /// @notice Applies anti-bot sell tax. To be called by the deployer directly before launching the PCS liquidity pool. Can only be called once.
  function applyInitialSellTax() public onlyOwner() {
    require(!initialSellTaxSet, "Initial sell tax has already been set.");
    initialSellTaxSet = true;
    initialSellTaxActive = true;
  }

  /// @notice Removes anti-bot sell tax. To be called by the deployer after a few hours of calling applyInitialSellTax().
  function removeInitialSellTax() public onlyOwner() {
    initialSellTaxActive = false;
  }

  /// @notice Change DAO contract address.
  function setDaoAddress(address _daoContractAddress) public onlyOwner() {
    daoContractAddress = _daoContractAddress;
  }

  /// @notice Set liquidity pool contract address.
  function setTokenPairAddress(address _tokenPairAddress) public onlyOwner() {
    tokenPairAddress = _tokenPairAddress;
  }

  /// @notice Gets the token's name
  /// @return Name
  function name() public view override returns (string memory) {
    return _name;
  }

  /// @notice Gets the token's symbol
  /// @return Symbol
  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  /// @notice Gets the token's decimals
  /// @return Decimals
  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  /// @notice Gets the total token supply (circulating supply from the reserve)
  /// @return Total token supply
  function totalSupply() public pure override returns (uint256) {
    return _totalSupply;
  }

  /// @notice Gets the token balance of given account
  /// @param account - Address to get the balance of
  /// @return Account's token balance
  function balanceOf(address account) public view override returns (uint256) {
    if (_isExcluded[account]) return _circulatingTokenBalance[account];
    return tokenBalanceFromReserveAmount(_reserveTokenBalance[account]);
  }

  /// @notice Transfers tokens from msg.sender to recipient
  /// @param recipient - Recipient of tokens
  /// @param amount - Amount of tokens to send
  /// @return true
  function transfer(
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(
      _msgSender(),
      recipient,
      amount
    );
    return true;
  }

  /// @notice Gets the token spend allowance for spender of owner
  /// @param owner - Owner of the tokens
  /// @param spender - Account with allowance to spend owner's tokens
  /// @return allowance amount
  function allowance(
    address owner,
    address spender
  ) public view override returns (uint256) {
    return _allowances[owner][spender];
  }

  /// @notice Approve token transfers from a 3rd party
  /// @param spender - The account to approve for spending funds on behalf of msg.senderds
  /// @param amount - The amount of tokens to approve
  /// @return true
  function approve(
    address spender,
    uint256 amount
  ) public override returns (bool) {
    _approve(
      _msgSender(),
      spender,
      amount
    );
    return true;
  }

  /// @notice Transfer tokens from a 3rd party
  /// @param sender - The account sending the funds
  /// @param recipient - The account receiving the funds
  /// @param amount - The amount of tokens to send
  /// @return true
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public override returns (bool) {
    _transfer(
      sender,
      recipient,
      amount
    );
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  /// @notice Increase 3rd party allowance to spend funds
  /// @param spender - The account being approved to spend on behalf of msg.sender
  /// @param addedValue - The amount to add to spending approval
  /// @return true
  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  /// @notice Decrease 3rd party allowance to spend funds
  /// @param spender - The account having approval revoked to spend on behalf of msg.sender
  /// @param subtractedValue - The amount to remove from spending approval
  /// @return true
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  ) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
    );
    return true;
  }

  /// @notice Gets the contract owner
  /// @return contract owner's address
  function getOwner() external override view returns (address) {
    return owner();
  }

  /// @notice Tells whether or not the address is excluded from owning reserve balance
  /// @param account - The account to test
  /// @return true or false
  function isExcluded(
    address account
  ) public view returns (bool) {
    return _isExcluded[account];
  }

  /// @notice Gets the total amount of fees spent
  /// @return Total amount of transaction fees
  function totalFees() public view returns (uint256) {
    return _transactionFeeTotal;
  }

  /// @notice Distribute tokens from the msg.sender's balance amongst all holders
  /// @param transferAmount - The amount of tokens to distribute
  function distributeToAllHolders(
    uint256 transferAmount
  ) public {
    address sender = _msgSender();
    require(!_isExcluded[sender], "Excluded addresses cannot call this function");
    (
      ,
      ReserveValues memory reserveValues
      ,
    ) = _getValues(transferAmount);
    _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(reserveValues.reserveAmount);
    _totalReserve = _totalReserve.sub(reserveValues.reserveAmount);
    _transactionFeeTotal = _transactionFeeTotal.add(transferAmount);
  }

  /// @notice Gets the reserve balance based on amount of tokens 
  /// @param transferAmount - The amount of tokens to distribute
  /// @param deductTransferReserveFee - Whether or not to deduct the transfer fee
  /// @return Reserve balance
  function reserveBalanceFromTokenAmount(
    uint256 transferAmount,
    bool deductTransferReserveFee
  ) public view returns(uint256) {
    (
      ,
      ReserveValues memory reserveValues
      ,
    ) = _getValues(transferAmount);
    require(transferAmount <= _totalSupply, "Amount must be less than supply");
    if (!deductTransferReserveFee) {       
      return reserveValues.reserveAmount;
    } else {
      return reserveValues.reserveTransferAmount;
    }
  }

  /// @notice Gets the token balance based on the reserve amount
  /// @param reserveAmount - The amount of reserve tokens owned
  /// @dev Dividing the reserveAmount by the currentRate is identical to multiplying the reserve amount by the ratio of totalSupply to totalReserve, which will be much less than 100% 
  /// @return Token balance
  function tokenBalanceFromReserveAmount(
    uint256 reserveAmount
  ) public view returns(uint256) {
    require(reserveAmount <= _totalReserve, "Amount must be less than total reflections");
    uint256 currentRate =  getRate();
    return reserveAmount.div(currentRate);
  }

  /// @notice Excludes an account from owning reserve balance. Useful for exchange and pool addresses.
  /// @param account - The account to exclude
  function excludeAccount(
    address account
  ) external onlyOwner() {
    require(!_isExcluded[account], "Account is already excluded");
    if(_reserveTokenBalance[account] > 0) {
        _circulatingTokenBalance[account] = tokenBalanceFromReserveAmount(_reserveTokenBalance[account]);
    }
    _isExcluded[account] = true;
    _excluded.push(account);
  }

  /// @notice Includes an excluded account from owning reserve balance
  /// @param account - The account to include
  function includeAccount(
    address account
  ) external onlyOwner() {
    require(_isExcluded[account], "Account is already excluded");
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_excluded[i] == account) {
        _excluded[i] = _excluded[_excluded.length - 1];
        _circulatingTokenBalance[account] = 0;
        _isExcluded[account] = false;
        _excluded.pop();
        break;
      }
    }
  }

  /// @notice Approves spender to spend owner's tokens
  /// @param owner - The account approving spender to spend tokens
  /// @param spender - The account to spend the tokens
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /// @notice Transfers 4.5% of every transaction to the LFG DAO
  /// @notice Transfers 0.5% of every transaction for contract license.
  /// @dev These addresses will never be excluded from receiving reflect, so we only increase their reserve balances
  function applyExternalTransactionTax(
    ReserveValues memory reserveValues,
    TransactionValues memory transactionValues,
    address sender
  ) private {
    _reserveTokenBalance[daoContractAddress] = _reserveTokenBalance[daoContractAddress].add(reserveValues.reserveTransferAmountDao);
    emit Transfer(
      sender,
      daoContractAddress,
      transactionValues.daoTax
    );  
    _reserveTokenBalance[royaltyAddress] = _reserveTokenBalance[royaltyAddress].add(reserveValues.reserveTransferAmountMooncakeRoyalty);
    emit Transfer(
      sender,
      royaltyAddress,
      transactionValues.mooncakeRoyalty
    );     
  }

  /// @notice Transfers tokens from sender to recipient differently based on inclusivity and exclusivity to reserve balance holding
  /// @param sender - The account sending tokens
  /// @param recipient - The account receiving tokens
  /// @param amount = The amount of tokens to send
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) private {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    if (_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferFromExcluded(
          sender,
          recipient,
          amount
        );
    } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
        _transferToExcluded(
          sender,
          recipient,
          amount
        );
    } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferStandard(
          sender,
          recipient,
          amount
        );
    } else if (_isExcluded[sender] && _isExcluded[recipient]) {
        _transferBothExcluded(
          sender,
          recipient,
          amount
        );
    } else {
        _transferStandard(
          sender,
          recipient,
          amount
        );
    }
  }

  /// @notice Transfers tokens from included sender to included recipient 
  /// @param sender - The account sending tokens
  /// @param recipient - The account receiving tokens
  /// @param transferAmount = The amount of tokens to send
  /// @dev Transferring tokens changes the reserve balances of the sender and recipient + reduces the totalReserve. It doesn't directly change the circulatingTokenBalance 
  function _transferStandard(
    address sender,
    address recipient,
    uint256 transferAmount
  ) private {
    (
      TransactionValues memory transactionValues,
      ReserveValues memory reserveValues
      ,
    ) = _getValues(transferAmount);
    _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(reserveValues.reserveAmount);
    _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(reserveValues.reserveTransferAmount);
    emit Transfer(
      sender,
      recipient,
      transactionValues.netTransferAmount
    );
    applyExternalTransactionTax(
      reserveValues,
      transactionValues,
      sender
    );
    _applyFees(
      reserveValues.reserveFee,
      transactionValues.transactionFee
    );
  }

  /// @notice Transfers tokens from included sender to excluded recipient 
  /// @param sender - The account sending tokens
  /// @param recipient - The account receiving tokens
  /// @param transferAmount = The amount of tokens to send
  /// @dev Transferring tokens to an excluded address directly increases the circulatingTokenBalance of the recipient, because excluded accounts only use that metric to calculate balances
  /// @dev Reserve balance is also transferred, in case the receiving address becomes included again
  function _transferToExcluded(
    address sender,
    address recipient,
    uint256 transferAmount
  ) private {
    (
      TransactionValues memory transactionValues,
      ReserveValues memory reserveValues
      ,
    ) = _getValues(transferAmount);

    _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(reserveValues.reserveAmount);

    // No tx fees for funding initial Token Pair contract. Only for transferToExcluded, all pools will be excluded from receiving reflect.
    if (recipient == tokenPairAddress) {
      _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(reserveValues.reserveAmount);   
      _circulatingTokenBalance[recipient] = _circulatingTokenBalance[recipient].add(transferAmount);

      emit Transfer(
        sender,
        recipient,
        transferAmount
      );

    } else {
      _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(reserveValues.reserveTransferAmount); 
      _circulatingTokenBalance[recipient] = _circulatingTokenBalance[recipient].add(transactionValues.netTransferAmount);
      emit Transfer(
        sender,
        recipient,
        transactionValues.netTransferAmount
      );
      applyExternalTransactionTax(
        reserveValues,
        transactionValues,
        sender
      );
      _applyFees(
        reserveValues.reserveFee,
        transactionValues.transactionFee
      );
    }
  }

  /// @notice Transfers tokens from excluded sender to included recipient
  /// @param sender - The account sending tokens
  /// @param recipient - The account receiving tokens
  /// @param transferAmount = The amount of tokens to send
  /// @dev Transferring tokens from an excluded address reduces the circulatingTokenBalance directly but adds only reserve balance to the included recipient
  function _transferFromExcluded(
    address sender,
    address recipient,
    uint256 transferAmount
  ) private {
    (
      TransactionValues memory transactionValues,
      ReserveValues memory reserveValues
      ,
    ) = _getValues(transferAmount);
    _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(transferAmount);
    _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(reserveValues.reserveAmount);

    // only matters when transferring from the Pair contract (which is excluded)
    if (!initialSellTaxActive) {
      _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(reserveValues.reserveTransferAmount);
      emit Transfer(
        sender,
        recipient,
        transactionValues.netTransferAmount
      );
      applyExternalTransactionTax(
        reserveValues,
        transactionValues,
        sender
      );
      _applyFees(
        reserveValues.reserveFee,
        transactionValues.transactionFee
      );
    } else {
      // Sell tax of 90% to prevent bots from sniping the liquidity pool. Should be active for a few hours after liquidity pool launch.
      _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(reserveValues.reserveAmount.div(10));
      emit Transfer(
        sender,
        recipient,
        transferAmount.div(10)
      );
    }
  }

  /// @notice Transfers tokens from excluded sender to excluded recipient 
  /// @param sender - The account sending tokens
  /// @param recipient - The account receiving tokens
  /// @param transferAmount = The amount of tokens to send
  /// @dev Transferring tokens from and to excluded addresses modify both the circulatingTokenBalance & reserveTokenBalance on both sides, in case one address is included in the future
  function _transferBothExcluded(
    address sender,
    address recipient,
    uint256 transferAmount
  ) private {
    (
      TransactionValues memory transactionValues,
      ReserveValues memory reserveValues
      ,
    ) = _getValues(transferAmount);
    _circulatingTokenBalance[sender] = _circulatingTokenBalance[sender].sub(transferAmount);
    _reserveTokenBalance[sender] = _reserveTokenBalance[sender].sub(reserveValues.reserveAmount);
    _reserveTokenBalance[recipient] = _reserveTokenBalance[recipient].add(reserveValues.reserveTransferAmount);   
    _circulatingTokenBalance[recipient] = _circulatingTokenBalance[recipient].add(transactionValues.netTransferAmount); 

    emit Transfer(
      sender,
      recipient,
      transactionValues.netTransferAmount
    );
    applyExternalTransactionTax(
      reserveValues,
      transactionValues,
      sender
    );
    _applyFees(
      reserveValues.reserveFee,
      transactionValues.transactionFee
    );
  }

  /// @notice Distributes the fee accordingly by reducing the total reserve supply. Increases the total transaction fees
  /// @param reserveFee - The amount to deduct from totalReserve, derived from transactionFee
  /// @param transactionFee - The actual token transaction fee
  function _applyFees(
    uint256 reserveFee,
    uint256 transactionFee
  ) private {
    _totalReserve = _totalReserve.sub(reserveFee);
    _transactionFeeTotal = _transactionFeeTotal.add(transactionFee);
  }

  /// @notice Utility function - gets values necessary to facilitate a token transaction
  /// @param transferAmount - The transfer amount specified by the sender
  /// @return values for a token transaction
  function _getValues(
    uint256 transferAmount
  ) private view returns (TransactionValues memory, ReserveValues memory, uint256) {
    TransactionValues memory transactionValues = _getTValues(transferAmount);
    uint256 currentRate = getRate();
    ReserveValues memory reserveValues = _getRValues(
      transferAmount,
      transactionValues,
      currentRate
    );

    return (
      transactionValues,
      reserveValues,
      currentRate
    );
  }

  /// @notice Utility function - gets transaction values
  /// @param transferAmount - The transfer amount specified by the sender
  /// @return Net transfer amount for the recipient and the transaction fee
  function _getTValues(
    uint256 transferAmount
  ) private pure returns (TransactionValues memory) {
    TransactionValues memory transactionValues;
    // 5% fee to all LFG Token holders.
    transactionValues.transactionFee = transferAmount.div(20);
    // 4.5% fee to the LFG DAO contract.
    transactionValues.daoTax = transferAmount.mul(9).div(200);
    // 0.5% royalty.
    transactionValues.mooncakeRoyalty = transferAmount.div(200);
    // Net transfer amount to recipient
    transactionValues.netTransferAmount = transferAmount.sub(transactionValues.transactionFee).sub(transactionValues.daoTax).sub(transactionValues.mooncakeRoyalty);
    
    return transactionValues;
  }

  /// @notice Utility function - gets reserve transaction values
  /// @param transferAmount - The transfer amount specified by the sender
  /// @param currentRate - The current rate - ratio of reserveSupply to totalSupply
  /// @return Net transfer amount for the recipient
  function _getRValues(
    uint256 transferAmount,
    TransactionValues memory transactionValues,
    uint256 currentRate
  ) private pure returns (ReserveValues memory) {
    ReserveValues memory reserveValues;
    reserveValues.reserveAmount = transferAmount.mul(currentRate);
    reserveValues.reserveFee = transactionValues.transactionFee.mul(currentRate);
    reserveValues.reserveTransferAmountDao = transactionValues.daoTax.mul(currentRate);
    reserveValues.reserveTransferAmountMooncakeRoyalty = transactionValues.mooncakeRoyalty.mul(currentRate);
    reserveValues.reserveTransferAmount = reserveValues.reserveAmount.sub(
      reserveValues.reserveFee
      ).sub(
        reserveValues.reserveTransferAmountDao
        ).sub(
          reserveValues.reserveTransferAmountMooncakeRoyalty
        );

    return reserveValues;
  }

  /// @notice Utility function - gets the current reserve rate - totalReserve / totalSupply
  /// @return Reserve rate
  function getRate() public view returns(uint256) {
    (
      uint256 reserveSupply,
      uint256 totalTokenSupply
    ) = getCurrentSupply();
    return reserveSupply.div(totalTokenSupply);
  }

  /// @notice Utility function - gets total reserve and circulating supply
  /// @return Reserve supply, total token supply
  function getCurrentSupply() public view returns(uint256, uint256) {
    uint256 reserveSupply = _totalReserve;
    uint256 totalTokenSupply = _totalSupply;      
    for (uint256 i = 0; i < _excluded.length; i++) {
      if (_reserveTokenBalance[_excluded[i]] > reserveSupply || _circulatingTokenBalance[_excluded[i]] > totalTokenSupply) return (_totalReserve, _totalSupply);
      reserveSupply = reserveSupply.sub(_reserveTokenBalance[_excluded[i]]);
      totalTokenSupply = totalTokenSupply.sub(_circulatingTokenBalance[_excluded[i]]);
    }
    if (reserveSupply < _totalReserve.div(_totalSupply)) return (_totalReserve, _totalSupply);
    return (reserveSupply, totalTokenSupply);
  }
}

// The High Table