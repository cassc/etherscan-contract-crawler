// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./inc/IERC20.sol";
import "./inc/Initializable.sol";
import "./inc/UUPSUpgradeable.sol";
import "./inc/PausableUpgradeable.sol";
import "./inc/ReentrancyGuardUpgradeable.sol";

import "./VaultPhase.sol";
import "./IVaultToken.sol"; 
import "./IWhitelist.sol";
import "./CarefulMath.sol";
import "./ISecurityManager.sol";
import "./ManagedSecurity.sol";
import "./AddressUtil.sol";

//import "hardhat/console.sol";

/**
 * @title Vault
 * 
 * @dev Vault locks a Base Token (normally assumed to be a stablecoin) and issues Vault Token
 * in its place, during deposit phase. During locked phase, no deposits or withdrawals are allowed. 
 * During the next deposit phase, Vault Tokens may be exchanged for the Base Token at the prescribed 
 * exchange rate. 
 * 
 * Vault Token: 
 * Owned by this contract. That token is tied to this specific vault, and this specific vault uses only that token 
 * as a Vault Token. 
 * 
 * Base Token: 
 * a stablecoin normally (can be any ERC20); the address is passed in at construction and cannot be changed. 
 * 
 * Vault Phase: 
 * Three phases, Deposit, Locked, and Withdraw. During Deposit Phase, users may deposit Base Token and receive 
 * Vault Token. Users may not withdraw. 
 * During Locked phase, deposit and withdrawal are both disabled.  
 * During Withdraw phase, users may exchange Vault Token for Base Token. Users may not deposit. 
 * 
 * @author John R. Kosinski
 * Owned and Managed by Stream Finance
 */
contract Vault is 
        Initializable,
        PausableUpgradeable, 
        ReentrancyGuardUpgradeable, 
        ManagedSecurity,
        UUPSUpgradeable
        //IVault
    {
    
    //tokens
    IERC20 public baseToken; 
    IVaultToken public vaultToken; 
    
    //whitelist (optional) 
    IWhitelist public whitelist; 
    
    //accounting 
    VaultPhase public currentPhase;
    ExchangeRate public currentExchangeRate; 
    uint256 public minimumDeposit;
    
    //events
    event Deposit(address indexed recipient, address depositor, uint256 baseTokenAmountIn, uint256 vaultTokenAmountOut); 
    event Withdraw(address indexed depositor, uint256 vaultTokenAmountIn, uint256 baseTokenAmountOut); 
    event PhaseChanged(VaultPhase phase, ExchangeRate exchangeRate); 
    
    //errors 
    error ZeroAmountArgument(); 
    error InvalidTokenContract(address); 
    error ActionOutOfPhase();
    error NotWhitelisted(address);
    error TokenTransferFailed();
    error VaultTokenAlreadyUsed(address);
    error DepositBelowMinimum(); 
    error VaultTokenOnly();
    
    //Restricts a function call to a specific Vault Phase  
    modifier onlyInPhase(VaultPhase _phase) {
        VaultPhase phase = currentPhase; 
        if (phase != _phase) 
            revert ActionOutOfPhase();
        _;
    }
    
    //Disallows any caller except the address of the Vault Token associated with this Vault
    modifier vaultTokenOnly() {
        if (_msgSender() != address(vaultToken)) {
            revert VaultTokenOnly(); 
        }
        _;
    }
    
    /**
     * Returns a hard-coded version number pair (major + minor). 
     * 
     * @return (major, minor)
     */
    function version() external virtual pure returns (uint8, uint8) {
        return (1, 0);
    }
    
    /**
     * Creates the instance, associating it with its two tokens. 
     * - All available security roles are granted to the caller. 
     * - The two token addresses are checked for validity; they must be ERC20 contracts. 
     * - Exchange rate is set initially to 1:1. 
     * - Phase is set initially to Deposit. 
     * 
     * Reverts: 
     * - {ZeroAddressArgument} - if either of the token addresses is 0x0. 
     * - {InvalidTokenContract} - if either of the token addresses is deemed invalid (ERC20)
     * - 'Address: low-level delegate call failed' - if `_securityManager` is not legit
     * - 'Initializable: contract is already initialized' - if already previously initialized 
     * 
     * @param _baseToken Address of any ERC20 token (normally stablecoin). 
     * @param _vaultToken Address of this Vault's Vault Token. 
     * @param _minimumDeposit Sets the minimum amount allowed when calling { deposit } method.
     * @param _securityManager Contract which will manage secure access for this contract. 
     */
    function initialize(
            IERC20 _baseToken, 
            IVaultToken _vaultToken, 
            uint256 _minimumDeposit, 
            ISecurityManager _securityManager
        ) external initializer {  
                
        //check addresses 
        if (address(_baseToken) == address(0)) 
            revert("Base Token 0 address"); // ZeroAddressArgument(); 
        if (address(_vaultToken) == address(0)) 
            revert("Vault Token 0 address"); // ZeroAddressArgument(); 
        
        //tokens must be ERC20 contracts 
        if (!AddressUtil.isERC20Contract(address(_baseToken)))
            revert("BaseToken invalid contract"); //InvalidTokenContract(address(_baseToken)); 
        if (!AddressUtil.isERC20Contract(address(_vaultToken)))
            revert("VaultToken invalid contract"); //InvalidTokenContract(address(_vaultToken)); 
            
        //check that the vault token doesn't already belong to a (different) vault
        if (_vaultToken.vaultAddress() != address(this) && _vaultToken.vaultAddress() != address(0)){
            revert("Vault Token already in use"); // InvalidTokenContract(address(_vaultToken)); 
        }
        
        //initializers 
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
            
        //token addresses
        baseToken = _baseToken;
        vaultToken = _vaultToken; 
        
        //min deposit
        minimumDeposit = _minimumDeposit;
        
        //defaults 
        currentPhase = VaultPhase.Deposit;
        currentExchangeRate = ExchangeRate(1, 1);
        
        //security manager
        _setSecurityManager(_securityManager); 
    }
    
    /**
     * Takes a deposit of base token to lock up. 
     * The caller will have had to have approved the vault as spender for at least that amount.
     * 
     * Emits: 
     * - { Deposit } on successful deposit. 
     * - { ERC20-Transfer } when transferring Base Token in
     * - { ERC20-Transfer } when minting Vault Token out
     * 
     * Reverts: 
     * - {ZeroAmountArgument} - if the amount specified is zero. 
     * - {TokenTransferFailed} - if either `baseToken`.transferFrom or `vaultToken`.transfer returns false.
     * - {ActionOutOfPhase} - if Vault is not in Deposit phase. 
     * - {NotWhitelisted} - if caller is not whitelisted 
     * - 'Pausable: Paused' -  if contract is paused. 
     * - 'ERC20: insufficient allowance' - if user has not approved Vault for at least the given deposit amount
     * - 'ERC20: transfer amount exceeds balance' - if user has less than the given amount of Base Token
     * 
     * @param baseTokenAmount The quantity of the base token to deposit. 
     */
    function deposit(uint256 baseTokenAmount) virtual external 
        //nonReentrant
        onlyInPhase(VaultPhase.Deposit) 
        whenNotPaused 
    {
        _deposit(baseTokenAmount, _msgSender()); 
    }
    
    /**
     * This can only be called by an authorized user as part of the sweep-into-vault system (implemented 
     * off-chain) that allows for automatic zap-in of different currencies, and direct deposit. It essentially 
     * is a deposit by the vault sweep-in, on behalf of the `forAddress` user. 
     * 
     * Emits: 
     * - { Deposit } on successful deposit. 
     * - { ERC20-Transfer } when transferring Base Token in
     * - { ERC20-Transfer } when minting Vault Token out
     * 
     * Reverts: 
     * - {UnauthorizedAccess} - if caller is not authorized with the appropriate role
     * - {ZeroAmountArgument} - if the amount specified is zero. 
     * - {TokenTransferFailed} - if either `baseToken`.transferFrom or `vaultToken`.transfer returns false.
     * - {ActionOutOfPhase} - if Vault is not in Deposit phase. 
     * - {NotWhitelisted} - if caller or `forAddress` is not whitelisted 
     * - 'Pausable: Paused' -  if contract is paused. 
     * - 'ERC20: insufficient allowance' - if user has not approved Vault for at least the given deposit amount
     * - 'ERC20: transfer amount exceeds balance' - if user has less than the given amount of Base Token
     * 
     * @param baseTokenAmount The quantity of the base token to deposit. 
     * @param forAddress The address that will receive the VaultToken in return for the deposit. 
     */
    function depositFor(uint256 baseTokenAmount, address forAddress) virtual external 
        onlyInPhase(VaultPhase.Deposit) 
        whenNotPaused  
        onlyRole(DEPOSIT_MANAGER_ROLE)
    {
        _deposit(baseTokenAmount, forAddress); 
    }
        
    /**
     * Allows the caller to exchange their previously gotten Vault Token for Base Token, at the rate 
     * currently set. 
     * 
     * Emits: 
     * - { Withdraw } on successful withdrawal. 
     * - { ERC20-Transfer } when transferring Base Token out
     * - { ERC20-Transfer } when transferring Vault Token in
     * 
     * Reverts: 
     * - {ZeroAmountArgument} - if the amount specified is zero. 
     * - {TokenTransferFailed} - if either `vaultToken`.transferFrom or `baseToken`.transfer returns false.
     * - {ActionOutOfPhase} - if Vault is not in Withdraw phase. 
     * - {NotWhitelisted} - if caller is not whitelisted 
     * - 'Pausable: Paused' - if contract is paused. 
     * - 'ERC20: insufficient allowance' - if user has not approved Vault for at least the given amount
     * - 'ERC20: transfer amount exceeds balance' - if user has less than the given amount of Vault Token
     * 
     * @param vaultTokenAmount The amount of Vault Token that has been transferred to the Vault. 
     */ 
    function withdraw(uint256 vaultTokenAmount) virtual external 
        //nonReentrant
        onlyInPhase(VaultPhase.Withdraw) 
        whenNotPaused 
    {       
        _withdraw(vaultTokenAmount, _msgSender());
    }
    
    /**
     * Only the Vault's associated Vault Token may call this method. This is called to allow for direct transfer
     * (transfer) without approval to the Vault, bypassing the {withdraw} method, which requires approval first. 
     * 
     * Emits: 
     * - { Withdraw } on successful withdrawal. 
     * - { ERC20-Transfer } when transferring Base Token out
     * 
     * Reverts: 
     * - {ZeroAmountArgument} if the amount specified is zero. 
     * - {ActionOutOfPhase} if Vault is not in Withdraw phase. 
     * - {TokenTransferFailed} if either `vaultToken`.transferFrom or `baseToken`.transfer returns false.
     * - {NotWhitelisted} if sender is not whitelisted 
     * - Pausable: Paused if contract is paused. 
     * - 'ERC20: insufficient allowance' - if user has not approved Vault for at least the given amount
     * - 'ERC20: transfer amount exceeds balance' - if user has less than the given amount of Vault Token
     * - {VaultTokenOnly} - if the caller is not the associated Vault Token contract 
     * 
     * @param vaultTokenAmount The amount of Vault Token that has been transferred to the Vault. 
     * @param sender The sender of the Vault Token to the Vault; this should be the recipient of any Base Token due. 
     */
    function withdrawDirect(uint256 vaultTokenAmount, address sender) virtual external 
        //nonReentrant
        vaultTokenOnly
        onlyInPhase(VaultPhase.Withdraw) 
        whenNotPaused 
    { 
        _withdraw(vaultTokenAmount, sender); 
    }
    
    /**
     * Triggers stopped state, rendering many functions uncallable. 
     *
     * Emits: 
     * - { Pausable-Paused } on successful pause 
     * 
     * Reverts:
     * - {UnauthorizedAccess} - if caller is not authorized with the appropriate role
     * - 'Pausable: Paused' - if contract is paused. 
     */
    function pause() virtual external onlyRole(PAUSER_ROLE) {
        _pause();
    }
    
    /**
     * Returns to the normal state after having been paused.
     *
     * Emits: 
     * - { Pausable-Unpaused } on successful unpause
     * 
     * Reverts:
     * - {UnauthorizedAccess} - if caller is not authorized with the appropriate role
     * - 'Pausable: Not paused' - if contract is not paused. 
     */
    function unpause() virtual external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    /**
     * Allows the authorized caller to move the current Vault Phase to the next phase in the lifecycle.
     * Deposit -> Locked
     * Locked -> Withdraw
     * Withdraw -> Deposit 
     * 
     * Emits: 
     * - { PhaseChanged } on phase change. 
     * 
     * Reverts:
     * - {UnauthorizedAccess} - if caller is not authorized with the appropriate role
     * - {ZeroAmountArgument} - if either the numerator or the denominator of `exchangeRate` is zero. 
     * - 'Pausable: Paused' - if contract is paused. 
     * 
     * @param rate The exchange rate of VaultToken to BaseToken for the phase. 
     */
    function progressToNextPhase(ExchangeRate calldata rate) virtual external 
        onlyRole(LIFECYCLE_MANAGER_ROLE) 
        whenNotPaused {
            
        //numerator or denominator cannot be zero 
        if (rate.vaultToken == 0 || rate.baseToken == 0) 
            revert ZeroAmountArgument(); 
       
       //move from Deposit -> Locked 
        if (currentPhase == VaultPhase.Deposit) {
            currentExchangeRate = rate;
            currentPhase = VaultPhase.Locked;
        }
        //move from Locked -> Withdraw 
        else if (currentPhase == VaultPhase.Locked) {
            currentExchangeRate = rate;
            currentPhase = VaultPhase.Withdraw;
        }
        //move from Withdraw -> Deposit 
        else if (currentPhase == VaultPhase.Withdraw) {
            currentExchangeRate = rate;
            currentPhase = VaultPhase.Deposit; 
        }
        
        emit PhaseChanged(currentPhase, currentExchangeRate);
    }
    
    /**
     * Set the address of the oracle that holds the whitelist data. 
     * 
     * Two things are required for whitelisting to happen: 
     * - The {whitelist} is set with a valid IWhitelist address. 
     * - The associated IWhitelist instance must be turned on. 
     * 
     * Reverts:
     * - {UnauthorizedAccess} - if caller is not authorized with the appropriate role
     * - 'Pausable: Paused' - if contract is paused. 
     * 
     * @param whitelistAddr The address of the oracle. 
     */
    function setWhitelist(IWhitelist whitelistAddr) virtual external onlyRole(WHITELIST_MANAGER_ROLE)
        whenNotPaused {
        whitelist = whitelistAddr;
    }
    
    /**
     * Sets the minimum amount of Base Token that anyone is allowed to deposit. 
     * 
     * Reverts:
     * - {UnauthorizedAccess} - if caller is not authorized with the appropriate role
     */
    function setMinimumDeposit(uint256 _minimumDeposit) virtual external onlyRole(GENERAL_MANAGER_ROLE) {
        minimumDeposit = _minimumDeposit;
    }
    
    /**
     * Allows admin to withdraw Base Token via ERC20 transfer.
     * 
     * @param amount The amount to withdraw
     * 
     * Reverts:
     * - {UnauthorizedAccess}: if caller is not authorized with the appropriate role
     */
    function adminWithdraw(uint256 amount) external nonReentrant onlyRole(ADMIN_ROLE) {
        baseToken.transfer(msg.sender, amount); 
    }
    
    /**
     * Transfers Vault Token in return for a deposit of Base Token. 
     * The Vault Token balance held by this instance is used first, then minting will cover
     * the remainder, if any. 
     * 
     * @param to The address to which to transfer.
     * @param amount The amount to transfer.
     * 
     * @return bool The return value of the ERC20.transfer function call. 
     */
    function _sendVaultToken(address to, uint256 amount) virtual internal returns (bool) {
        
        //if available balance is not sufficient...
        uint256 availBalance = vaultToken.balanceOf(address(this));
        if (availBalance < amount) {
            //then mint the difference to vault first before sending
            vaultToken.mint(address(this), (amount - availBalance)); 
        }
        
        //send required amount 
        return vaultToken.transfer(to, amount);
    }
    
    /**
     * Determines whether or not the given address refers to a valid ERC20 token contract. 
     * 
     * @param _addr The address in question. 
     * @return bool True if ERC20 token. 
     */
    function _isERC20Contract(address _addr) internal view returns (bool) {
        if (_addr != address(0)) {
            if (AddressUpgradeable.isContract(_addr)) {
                IERC20 token = IERC20(_addr); 
                return token.totalSupply() >= 0;  
            }
        }
        return false;
    }
    
    /**
     * Allows the caller to exchange their previously gotten Vault Token for Base Token, at the rate 
     * currently set. 
     * 
     * @param vaultTokenAmount The amount of Vault Token being transferred in, in order to withdraw Base Token. 
     * @param recipient The intended recipient of the Base Token (must be whitelisted). 
     */ 
    function _withdraw(uint256 vaultTokenAmount, address recipient) virtual internal nonReentrant {
        
        //'direct' transfer of Vault Token from address triggered this withdrawal
        bool isDirect = recipient != _msgSender(); 
        
        //amount shouldn't be zero (but allowed for direct withdraw, because BEP-20 support requires
        // that transfers should not throw this revert for zero address)
        if (!isDirect && vaultTokenAmount == 0) 
            revert ZeroAmountArgument(); 
            
        //check for whitelisted recipient
        if (address(whitelist) != address(0)) {
            if (!whitelist.isWhitelisted(recipient)) {
                revert NotWhitelisted(recipient);
            }
        }
        
        //do the conversion: how much to pay out 
        uint256 baseTokenAmount = CarefulMath.vaultToBaseTokenAtRate(vaultTokenAmount, currentExchangeRate);
        
        //emit event
        emit Withdraw(_msgSender(), vaultTokenAmount, baseTokenAmount);
        
        //'direct' transfer: the VaultToken has already been received, so just send Base Token out
        if (isDirect) {
            if (!baseToken.transfer(recipient, baseTokenAmount)) 
                revert TokenTransferFailed(); 
        }
        
        //if not 'direct' transfer: must receive the Vault Token first 
        else {
            //get those vault tokens back 
            if (vaultToken.transferFromInternal(recipient, address(this), vaultTokenAmount)) { 
                
                //then do base token xfer
                if (!baseToken.transfer(recipient, baseTokenAmount)) 
                    revert TokenTransferFailed(); 
            } else {
                revert TokenTransferFailed(); 
            }
        }
    }
    
    /**
     * Deposits pre-approved Base Token, and transfers the appropriate amount of Vault Token (according to current
     * exchange rate) to the intended `recipient`. 
     * 
     * Emits: 
     * - { Deposit } on successful deposit. 
     * - { ERC20-Transfer } when transferring Base Token in
     * - { ERC20-Transfer } when minting Vault Token out
     * 
     * Requirements: 
     * - If whitelist is set and turned on, `recipient` must be whitelisted.
     * 
     * Reverts: 
     * - {ZeroAmountArgument} if the amount specified is zero. 
     * - {TokenTransferFailed} if either `baseToken`.transferFrom or `vaultToken`.transfer returns false.
     * - {NotWhitelisted} if either the sender of the transaction or the recipient are not whitelisted 
     *      (only if whitelisting is turned on and enabled)
     * 
     * @param baseTokenAmount The amount of Vault Token that has been transferred to the Vault. 
     * @param recipient The sender of the Vault Token to the Vault; this should be the recipient of any Base Token due. 
     */
    function _deposit(uint256 baseTokenAmount, address recipient) virtual internal nonReentrant {
        //deposit amount can't be 0
        if (baseTokenAmount == 0) 
            revert ZeroAmountArgument(); 
            
        //revert if less than minimum 
        if (baseTokenAmount < minimumDeposit) 
            revert DepositBelowMinimum(); 
            
        //check for whitelisted recipient and sender 
        if (address(whitelist) != address(0)) {
            if (!whitelist.isWhitelisted(recipient)) {
                revert NotWhitelisted(recipient);
            }
            
            //if recipient & sender are not the same, check sender too 
            if (recipient != _msgSender()) {
                if (!whitelist.isWhitelisted(_msgSender())) {
                    revert NotWhitelisted(_msgSender());
                }
            }
        }
        
        //calculate appropriate corresponding amount of vaultToken 
        uint256 vaultTokenAmount = CarefulMath.baseToVaultTokenAtRate(baseTokenAmount, currentExchangeRate);
            
        //emit event
        emit Deposit(recipient, _msgSender(), baseTokenAmount, vaultTokenAmount);
        
        //transfer tokens from/to
        if (baseToken.transferFrom(_msgSender(), address(this), baseTokenAmount)) {
            
            //mint new VaultToken to sender, to cover  
            if (!_sendVaultToken(recipient, vaultTokenAmount)) 
                revert TokenTransferFailed(); 
        }
        else { revert TokenTransferFailed(); }
    }
    
    /**
     * Authorizes users wtih the UPGRADER role to upgrade the implementation. 
     */
    function _authorizeUpgrade(address) internal virtual override onlyRole(UPGRADER_ROLE) { }
    
    /**
     * See { ContextUpgradeable._msgSender }. 
     * This needs to be overridden for multiple-inheritance reasons. 
     * 
     * @return address 
     */
    function _msgSender() internal override(Context, ContextUpgradeable) view returns(address) {
        return super._msgSender(); 
    }
}