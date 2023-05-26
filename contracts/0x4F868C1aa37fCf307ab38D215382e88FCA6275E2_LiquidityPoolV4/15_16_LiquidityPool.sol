// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.6;

import "./Interf.sol";
import "./CanReclaimTokens.sol";
import './BorrowerProxy.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "hardhat/console.sol";

contract LiquidityPoolStorageV1 {
    mapping (address=>IKToken) public kTokens;
    mapping (address=>bool) public registeredKTokens;
    mapping (address=>uint256) public loanedAmount;
    mapping (address=>mapping (address=>uint256)) public adapterLoanedAmount;
    mapping (address=>uint256) public adapterLimits;

    uint256 public depositFeeInBips;
    uint256 public poolFeeInBips;
    address[] public registeredTokens;
    address payable feePool;
    BorrowerProxy public borrower;
}

contract LiquidityPoolV4 is LiquidityPoolStorageV1, ILiquidityPool, CanReclaimTokens, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    uint256 public constant BIPS_BASE = 10000;
    address public constant ETHEREUM = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event Deposited(address indexed _depositor, address indexed _token, uint256 _amount, uint256 _mintAmount);
    event Withdrew(address indexed _reciever, address indexed _withdrawer, address indexed _token, uint256 _amount, uint256 _burnAmount);
    event Borrowed(address indexed _borrower, address indexed _token, uint256 _amount, uint256 _fee);
    event EtherReceived(address indexed _from, uint256 _amount);
    event AdapterLimitChanged(address indexed _adapter, uint256 _from, uint256 _to);
    event AdapterBorrowed(address indexed _adapter, address indexed _token, uint256 _amount);
    event AdapterRepaid(address indexed _adapter, address indexed _token, uint256 _amount);

    modifier onlyWhitelistedAdapter() {
        require(adapterLimits[msg.sender] != 0, "JITU: caller is not a whitelisted keeper");
        _;
    }

    receive () external override payable {
        emit EtherReceived(_msgSender(), msg.value);
    }

    constructor() {
        borrower = new BorrowerProxy();
    }

    /// @notice updates the deposit fee.
    ///
    /// @dev fee is in bips so it should 
    ///     satisfy [0 <= fee <= BIPS_BASE]
    /// @param _depositFeeInBips The new deposit fee.
    function updateDepositFee(uint256 _depositFeeInBips) external onlyOperator {
        require(_depositFeeInBips <= BIPS_BASE, "LiquidityPool: fee should be between 0 and BIPS_BASE");
        depositFeeInBips = _depositFeeInBips;
    }

    /// @notice updates the pool fee.
    ///
    /// @dev fee is in bips so it should 
    ///     satisfy [0 <= fee <= BIPS_BASE]
    /// @param _poolFeeInBips The new pool fee.
    function updatePoolFee(uint256 _poolFeeInBips) external onlyOperator {
        require(_poolFeeInBips <= BIPS_BASE, "LiquidityPool: fee should be between 0 and BIPS_BASE");
        poolFeeInBips = _poolFeeInBips;
    }

    /// @notice updates the fee pool.
    ///
    /// @param _newFeePool The new fee pool.
    function updateFeePool(address payable _newFeePool) external onlyOperator {
        require(_newFeePool != address(0), "LiquidityPoolV2: feepool cannot be 0x0");
        feePool = _newFeePool;        
    }

    /// @notice change the credit limit for the given adapter.
    /// @param _adapter the address of the keeper
    /// @param _limitInBips the spending limit of the adapter
    function updateAdapterLimit(address _adapter, uint256 _limitInBips) external onlyOperator {
        require(_limitInBips <= BIPS_BASE, "limit should be between 0 and BIPS_BASE");
        adapterLimits[_adapter] = _limitInBips;
        _checkCreditLimit(_adapter);
        emit AdapterLimitChanged(_adapter, adapterLimits[_adapter], _limitInBips);
    }

    /// @notice pauses this contract.
    function pause() external onlyOperator {
        _pause();
    }

    /// @notice unpauses this contract.
    function unpause() external onlyOperator {
        _unpause();
    }

    /// @notice Renounces operatorship of this contract 
    function renounceOperator() public override(ILiquidityPool, KRoles) {
        KRoles.renounceOperator();
    }

    /// @notice register a token on this Keeper.
    ///
    /// @param _kToken The keeper ERC20 token.
    function register(IKToken _kToken) external override onlyOperator {
        require(address(kTokens[_kToken.underlying()]) == address(0x0), "Underlying asset should not have been registered");
        require(!registeredKTokens[address(_kToken)], "kToken should not have been registered");

        kTokens[_kToken.underlying()] = _kToken;
        registeredKTokens[address(_kToken)] = true;
        registeredTokens.push(address(_kToken.underlying()));
        blacklistRecoverableToken(_kToken.underlying());
    }

    /// @notice Deposit funds to the Keeper Protocol.
    ///
    /// @param _token The address of the token contract.
    /// @param _amount The value of deposit.
    function deposit(address _token, uint256 _amount) external payable override nonReentrant whenNotPaused returns (uint256) {
        IKToken kTok = kTokens[_token];
        require(address(kTok) != address(0x0), "Token is not registered");
        require(_amount > 0, "Deposit amount should be greater than 0");
        _transferIn(_token, _amount);
        uint256 mintAmount = calculateMintAmount(kTok, _token, _amount);
        require(kTok.mint(_msgSender(), mintAmount), "Failed to mint kTokens");
        emit Deposited(_msgSender(), _token, _amount, mintAmount);

        return mintAmount;
    }

    /// @notice Withdraw funds from the Compound Protocol.
    ///
    /// @param _to The address of the amount receiver.
    /// @param _kToken The address of the kToken contract.
    /// @param _kTokenAmount The value of the kToken amount to be burned.
    function withdraw(address payable _to, IKToken _kToken, uint256 _kTokenAmount) external override nonReentrant whenNotPaused {
        require(registeredKTokens[address(_kToken)], "kToken is not registered");
        require(_kTokenAmount > 0, "Withdraw amount should be greater than 0");
        address token = _kToken.underlying();
        uint256 amount = calculateWithdrawAmount(_kToken, token, _kTokenAmount);
        _kToken.burnFrom(_msgSender(), _kTokenAmount);
        _transferOut(_to, token, amount);
        emit Withdrew(_to, _msgSender(), token, amount, _kTokenAmount);
    }

    /// @notice borrow assets from this LP, and return them within the same transaction.
    ///
    /// @param _token The address of the token contract.
    /// @param _amount The amont of token.
    /// @param _data The implementation specific data for the Borrower.
    function borrow(address _token, uint256 _amount, bytes calldata _data) external nonReentrant whenNotPaused {
        require(address(kTokens[_token]) != address(0x0), "Token is not registered");
        uint256 initialBalance = borrowableBalance(_token);
        _transferOut(_msgSender(), _token, _amount);
        borrower.lend(_msgSender(), _data);
        uint256 finalBalance = borrowableBalance(_token);
        require(finalBalance >= initialBalance, "Borrower failed to return the borrowed funds");

        uint256 fee = finalBalance - initialBalance;
        uint256 poolFee = calculateFee(poolFeeInBips, fee);
        emit Borrowed(_msgSender(), _token, _amount, fee);
        _transferOut(feePool, _token, poolFee);
    }

    /// @notice Calculate the given token's outstanding balance of this contract.
    ///
    /// @param _token The address of the token contract.
    ///
    /// @return Outstanding balance of the given token.
    function borrowableBalance(address _token) public view override returns (uint256) {
        if (_token == ETHEREUM) {
            return address(this).balance;
        }
        return IERC20(_token).balanceOf(address(this));
    }

    /// @notice returns the total value locked in the LiquidityPool for the 
    ///         given token
    /// @param _token the address of the token
    function totalValueLocked(address _token) public view returns (uint256) {
        return borrowableBalance(_token) + loanedAmount[_token];
    }

    /// @notice Calculate the given owner's outstanding balance for the given token on this contract.
    ///
    /// @param _token The address of the token contract.
    /// @param _owner The address of the token contract.
    ///
    /// @return Owner's outstanding balance of the given token.
    function underlyingBalance(address _token, address _owner) public view override returns (uint256) {
        uint256 kBalance = kTokens[_token].balanceOf(_owner);
        uint256 kSupply = kTokens[_token].totalSupply();
        if (kBalance > 0) {
            return (totalValueLocked(_token) * kBalance) / kSupply;
        }
        return 0;
    }

    /// @notice Migrate funds to the new liquidity provider.
    ///
    /// @param _newLP The address of the new LiquidityPool contract.
    function migrate(ILiquidityPool _newLP) public onlyOperator {
        for (uint256 i = 0; i < registeredTokens.length; i++) {
            address token = registeredTokens[i];
            kTokens[token].addMinter(address(_newLP));
            kTokens[token].renounceMinter();
            _newLP.register(kTokens[token]);
            _transferOut(address(_newLP), token, borrowableBalance(token));
        }
        _newLP.renounceOperator();
    }
    
    /// @notice adapterBorrow allows supported KeeperDAO adapters to lend 
    ///         assets intra block.
    ///
    /// @param _token The address of the token contract.
    /// @param _amount The amont of token.
    /// @param _data The implementation specific data for the Borrower.
    function adapterBorrow(address _token, uint256 _amount, bytes calldata _data) 
        external nonReentrant onlyWhitelistedAdapter whenNotPaused {
        require(address(kTokens[_token]) != address(0x0), "Token is not registered");

        loanedAmount[_token] += _amount;
        adapterLoanedAmount[_msgSender()][_token] +=  _amount;
        _checkTokenCreditLimit(_msgSender(), _token);

        _transferOut(_msgSender(), _token, _amount);
        borrower.lend(_msgSender(), _data);
        
        emit AdapterBorrowed(_msgSender(), _token, _amount);
    }

    /// @notice repay allows supported KeeperDAO adapters to repay 
    ///         assets intra block.
    ///
    /// @param _token The address of the token contract.
    /// @param _amount The amont of token.
    function adapterRepay(address _adapter, address _token, uint256 _amount) 
        external payable nonReentrant whenNotPaused {
        require(address(kTokens[_token]) != address(0x0), "Token is not registered");

        // pull the funds from the msg.sender to this contract
        _transferIn(_token, _amount);

        uint256 repayAmount = adapterLoanedAmount[_adapter][_token] < _amount  ?
            adapterLoanedAmount[_adapter][_token] : _amount;
        loanedAmount[_token] -= repayAmount;
        adapterLoanedAmount[_adapter][_token] -= repayAmount;
        
        emit AdapterRepaid(_adapter, _token, repayAmount);
    }

    // returns the corresponding kToken for the given underlying token if it exists.
    function kToken(address _token) external view override returns (IKToken) {
        return kTokens[_token];
    }

    /// Calculates the amount that will be withdrawn when the given amount of kToken 
    /// is burnt.
    /// @dev used in the withdraw() function to calculate the amount that will be
    ///      withdrawn. 
    function calculateWithdrawAmount(IKToken _kToken, address _token, uint256 _kTokenAmount) internal view returns (uint256) {
        uint256 kTokenSupply = _kToken.totalSupply();
        require(kTokenSupply != 0, "No KTokens to be burnt");
        uint256 poolBalance = borrowableBalance(_token);
        uint256 withdrawAmount = (_kTokenAmount * (poolBalance + loanedAmount[_token])) / _kToken.totalSupply();
        require(withdrawAmount <= poolBalance, "Insufficient pool liquidity");
        return withdrawAmount;
    }

    /// Calculates the amount of kTokens that will be minted when the given amount 
    /// is deposited.
    /// @dev used in the deposit() function to calculate the amount of kTokens that
    ///      will be minted.
    function calculateMintAmount(IKToken _kToken, address _token, uint256 _depositAmount) internal view returns (uint256) {
        // The borrow balance includes the deposit amount, which is removed here.        
        uint256 initialBalance = totalValueLocked(_token) - _depositAmount;
        uint256 kTokenSupply = _kToken.totalSupply();
        if (kTokenSupply == 0) {
            return _depositAmount;
        }

        // mintAmoount = amountDeposited * (1-fee) * kPool /(pool + amountDeposited * fee)
        return (applyFee(depositFeeInBips, _depositAmount) * kTokenSupply) /
            (initialBalance + calculateFee(depositFeeInBips, _depositAmount));
    }

    /// Applies the fee by subtracting fees from the amount and returns  
    /// the amount after deducting the fee.
    /// @dev it calculates (1 - fee) * amount
    function applyFee(uint256 _feeInBips, uint256 _amount) internal pure returns (uint256) {
        return (_amount * (BIPS_BASE - _feeInBips)) / BIPS_BASE; 
    }

    /// Calculates the fee amount. 
    /// @dev it calculates fee * amount
    function calculateFee(uint256 _feeInBips, uint256 _amount) internal pure returns (uint256) {
        return (_amount * _feeInBips) / BIPS_BASE; 
    }

    /// @notice checks credit limit of the adapter
    function _checkCreditLimit(address _adapter) internal view {
        for (uint i = 0; i < registeredTokens.length; i++) {
            _checkTokenCreditLimit(_adapter, registeredTokens[i]);
        }
    }

    /// @notice checks credit limit of the adapter for the given token
    function _checkTokenCreditLimit(address _adapter, address _token) internal view {
        uint256 adapterLimit = (adapterLimits[_adapter] * totalValueLocked(_token)) / BIPS_BASE;
        require(adapterLoanedAmount[_adapter][_token] <= adapterLimit, "Exceeds the credit limit");
    }

    /// @notice transfers funds into the contract
    function _transferIn(address _token, uint256 _amount) internal {
        if (_token != ETHEREUM) {
            require(msg.value == 0, "LiquidityPool: ETH sent during an ERC20 deposit");
            IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        } else {
            require(msg.value >= _amount, "LiquidityPool: incorrect ETH amount");
        }
    }

    /// @notice transfers funds out of the contract
    function _transferOut(address _to, address _token, uint256 _amount) internal {
        if (_token != ETHEREUM) {
            IERC20(_token).safeTransfer(_to, _amount);
        } else {
            (bool success,) = _to.call{ value: _amount }("");
            require(success, "LiquidityPool: failed to transfer ETH");
        }
    }
}