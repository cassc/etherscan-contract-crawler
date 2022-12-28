// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './ERC20EToken.sol';
import './CoreConstants.sol';
import './FlashLoanFeeProvider.sol';
import './interfaces/IVault.sol';

contract Vault is
    Moderable,
    IVault,
    CoreConstants,
    ERC20EToken,
    FlashLoanFeeProvider,
    ReentrancyGuard
{
    ERC20 public stakedToken;
    address public treasuryAddress;
    address public flashLoanProviderAddress;

    uint256 public totalAmountDeposited = 0;
    uint256 public minAmountForFlash = 0;
    uint256 public maxCapacity = 0;

    bool public isPaused = true;
    bool public ongoingFlashLoan = false;
    bool public isInitialized = false;

    address public immutable factory;

    mapping(address => uint256) public lastDepositBlockNr;

    /**
     * @dev Only if vault is not paused.
     **/
    modifier onlyNotPaused {
        require(isPaused == false, 'ONLY_NOT_PAUSED');
        _;
    }

    modifier noOngoingFlashLoan {
        require (ongoingFlashLoan == false, 'ONGOING_FLASH_LOAN');
        _;
    }


    /**
     * @dev Only if vault is not initialized.
     **/
    modifier onlyNotInitialized {
        require(isInitialized == false, 'ONLY_NOT_INITIALIZED');
        _;
    }

    /**
     * @dev Only if msg.sender is flash loan provider.
     **/
    modifier onlyFlashLoanProvider {
        require(flashLoanProviderAddress == msg.sender, 'ONLY_FLASH_LOAN_PROVIDER');
        _;
    }

    constructor(ERC20 _stakedToken)
        ERC20EToken(
            string(abi.encodePacked(_stakedToken.symbol(), ' eVault LP')),
            string(abi.encodePacked('e', _stakedToken.symbol()))
        )
    {
        factory = msg.sender;
        stakedToken = _stakedToken;
    }

    /**
     * @dev Initialize vault contract.
     * @param _treasuryAddress address of treasury where part of flash loan fee is sent.
     * @param _flashLoanProviderAddress provider of flash loans
     * @param _maxCapacity max capacity for a vault
     */
    function initialize(
        address _treasuryAddress,
        address _flashLoanProviderAddress,
        uint256 _maxCapacity
    ) external override onlyModerator onlyNotInitialized {
        treasuryAddress = _treasuryAddress;
        flashLoanProviderAddress = _flashLoanProviderAddress;
        maxCapacity = _maxCapacity;
        isPaused = false;
        isInitialized = true;
    }

    /**
     * @dev Getter for number of decimals.
     * @return number of decimals of eToken.
     */
    function decimals() public view virtual override returns (uint8) {
        return stakedToken.decimals();
    }

    /**
     * @dev Getter get an output amount for exact input.
     * @return receivedETokens number of LP tokens for an exact input
     */

    function getAmountOutputForExactInput(uint256 amount) external view virtual returns (uint256 receivedETokens) {
        require(amount > 0, 'CANNOT_STAKE_ZERO_TOKENS');
        receivedETokens = getNrOfETokensToMint(amount);
    }

    /**
     * @dev Setter for max capacity.
     * @param _maxCapacity new value to be set.
     */
    function setMaxCapacity(uint256 _maxCapacity) external onlyModerator {
        maxCapacity = _maxCapacity;
        emit SetMaxCapacity(msg.sender, _maxCapacity);
    }

    /**
     * @dev Setter for minimum amount for flash.
     * @param _minAmountForFlash Minimum amount for a flash.
     */
    function setMinAmountForFlash(uint256 _minAmountForFlash) external onlyModerator {
        minAmountForFlash = _minAmountForFlash;
        emit SetMinAmountForFlash(msg.sender, _minAmountForFlash);
    }

    /**
     * @dev Get number of tokens to mint.
     * @param amount of tokens deposited into Vault in order to receive eTokens.
     */
    function getNrOfETokensToMint(uint256 amount) internal view returns (uint256) {
        return (amount * RATIO_MULTIPLY_FACTOR) / getRatioForOneEToken();
    }

    /**
     * @dev Provide liquidity to Vault.
     * @param amount The amount of liquidity to be deposited.
     */
    function provideLiquidity(uint256 amount, uint256 minOutputAmount) external onlyNotPaused noOngoingFlashLoan nonReentrant {
        require(amount > 0, 'CANNOT_STAKE_ZERO_TOKENS');
        require(amount + totalAmountDeposited <= maxCapacity, 'AMOUNT_IS_BIGGER_THAN_CAPACITY');

        uint256 receivedETokens = getNrOfETokensToMint(amount);
        require (receivedETokens >= minOutputAmount, "Insufficient Output");

        totalAmountDeposited = amount + totalAmountDeposited;

        _mint(msg.sender, receivedETokens);
        require(
            stakedToken.transferFrom(msg.sender, address(this), amount),
            'TRANSFER_STAKED_FAIL'
        );

        emit Deposit(msg.sender, amount, receivedETokens, lastDepositBlockNr[msg.sender]);

        lastDepositBlockNr[msg.sender] = block.number;
    }

    /**
     * @dev Remove liquidity.
     * @param amount of eTokens to be removed from Vault.
     */
    function removeLiquidity(uint256 amount) external nonReentrant {
        require(amount <= balanceOf(msg.sender), 'AMOUNT_BIGGER_THAN_BALANCE');

        uint256 stakedTokensToTransfer = getStakedTokensFromAmount(amount);
        totalAmountDeposited =
            totalAmountDeposited -
            (amount * totalAmountDeposited) /
            totalSupply();

        _burn(msg.sender, amount);
        require(stakedToken.transfer(msg.sender, stakedTokensToTransfer), 'TRANSFER_STAKED_FAIL');

        emit Withdraw(msg.sender, amount, stakedTokensToTransfer);
    }

    /**
     * @dev One eToken to token
     * @return The current eToken ratio.
     */
    function getRatioForOneEToken() public view returns (uint256) {
        if (totalSupply() > 0 && stakedToken.balanceOf(address(this)) > 0) {
            return (stakedToken.balanceOf(address(this)) * RATIO_MULTIPLY_FACTOR) / totalSupply();
        }
        return 1 * RATIO_MULTIPLY_FACTOR;
    }

    /**
     * @dev Pause vault.
     */
    function pauseVault() external onlyModerator {
        require(isPaused == false, 'VAULT_ALREADY_PAUSED');
        isPaused = true;
        emit VaultPaused(msg.sender);
    }

    /**
     * @dev Unpause vault.
     */
    function unpauseVault() external onlyModerator {
        require(isPaused == true, 'VAULT_ALREADY_RESUMED');
        isPaused = false;
        emit VaultResumed(msg.sender);
    }


    /**
     * @dev Lock vault.
     */
    function lockVault() external onlyFlashLoanProvider {
        require(ongoingFlashLoan == false, 'VAULT_ALREADY_LOCKED');
        ongoingFlashLoan = true;
    }

    /**
     * @dev Unlock vault.
     */
    function unlockVault() external onlyFlashLoanProvider {
        require(ongoingFlashLoan == true, 'VAULT_ALREADY_UNLOCKED');
        ongoingFlashLoan = false;
    }

    /**
     * @dev FlashLoanProvider can send funds in name of Vault
     * @param recipient Address where the funds are sent.
     * @param amount Amount of funds to be sent.
     * @return Transfer result.
     */
    function transferToAccount(address recipient, uint256 amount)
        external
        onlyFlashLoanProvider
        onlyNotPaused
        returns (bool)
    {
        return stakedToken.transfer(recipient, amount);
    }

    /**
     * @dev The amount of staked tokens.
     * @param amount of eTokens deposited to be burned.
     * @return The amount of staked tokens to send to address.
     */
    function getStakedTokensFromAmount(uint256 amount) internal view returns (uint256) {
        return (amount * getRatioForOneEToken()) / RATIO_MULTIPLY_FACTOR;
    }

    /**
     * @dev Split fees
     * @param fee Fee amount to be split
     */
    function splitFees(uint256 fee)
        external
        onlyFlashLoanProvider
        returns (uint256 treasuryAmount)
    {
        treasuryAmount = getTreasuryAmountToSend(fee);
        require(stakedToken.transfer(treasuryAddress, treasuryAmount), 'TRANSFER_SPLIT_FAIL');
        emit SplitFees(treasuryAddress, treasuryAmount);
    }
}