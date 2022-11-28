// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
import "./interfaces/Interfaces.sol";

/// @title Option Vault Factory
/// @author dannydoritoeth
/// @notice OptionsVaultERC20 represents an individual options vault. Each option vault is backed by a single underlying ERC20 collateral token which is used to underwrite all option positions. Regular users can supply collateral to the vault and receive transferable vault shares representing this collateral in return. Whenever people buy options from the vault, these shares will appreciate in value. Whenever people exercise these options, the shares depreciate.
contract OptionsVaultERC20 is ERC20, AccessControl, IStructs, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using OptionsLib for BoolState;
    using OptionsLib for bool;

    // properties
    IOptionsVaultFactory public factory;
    uint256 public vaultId;
    IERC20 public collateralToken;
    uint256 public collateralReserves;
    uint256 public lockedCollateralCall;
    uint256 public lockedCollateralPut;
    mapping(uint256 => bool) public lockedCollateral;
    address public vaultFeeRecipient;
    IFeeCalcs public vaultFeeCalc;
    BoolState public vaultFeeCalcLocked;
    uint256 public vaultFee;
    string public ipfsHash;
    bool public readOnly;
    uint256 public maxInvest;
    uint256 public tradingWindow;
    uint256 public transferWindow;
    uint256 public transferWindowStartTime;
    mapping(IOracle => bool) public oracleEnabled;
    BoolState public oracleEnabledLocked;
    BoolState public lpOpenToPublic;
    BoolState public buyerWhitelistOnly;
    uint8 private decimalsConst;

    // constants
    bytes32 public immutable VAULT_OPERATOR_ROLE = keccak256("VAULT_OPERATOR_ROLE");
    bytes32 public immutable VAULT_BUYERWHITELIST_ROLE = keccak256("VAULT_BUYERWHITELIST_ROLE");
    bytes32 public immutable VAULT_LPWHITELIST_ROLE = keccak256("VAULT_LPWHITELIST_ROLE");

    // events

    /// @notice An account provides liquidity to a vault
    /// @param account the account performing the action
    /// @param vaultId Vault id
    /// @param amount the collateral amount be provided
    /// @param mintTokens the number of vault tokens minted
    /// @param mint whether to mint ownership tokens or not. Not minting increases the propotional balance for everyone.
    event Provide(address indexed account, uint vaultId, uint256 amount, uint256 mintTokens, bool mint);

    /// @notice A vault collects premium when an options is purchased
    /// @param account the account performing the action
    /// @param vaultId Vault id
    /// @param amount the amount of premium collected
    event CollectPremium(address indexed account, uint vaultId, uint256 amount);

    /// @notice An account withdraws liqudity from a vault
    /// @param account the account performing the action
    /// @param vaultId Vault id
    /// @param amountA The collateral amount withdrawn
    /// @param burnTokens the number of vault tokens burned
    event Withdraw(address indexed account, uint vaultId, uint amountA, uint256 burnTokens);

    /// @notice An option is purchased an collateral is locked
    /// @param optionId ID of the option
    /// @param optionSize The amount of collateral to be locked
    event Lock(uint indexed optionId, uint256 optionSize);

    /// @notice An option collateral is unlocked. Done when exercising or after expiry.
    /// @param optionId ID of the option
    event Unlock(uint indexed optionId);

    /// @notice A vault has incurred a profit
    /// @dev Explain to a developer any extra details
    /// @param optionId ID of the option
    /// @param vaultId Vault id
    /// @param amount The amount of profit the vault incurred
    event VaultProfit(uint indexed optionId, uint vaultId, uint amount);

    /// @notice A vault has incurred a loss
    /// @param optionId ID of the option
    /// @param vaultId Vault id
    /// @param amount The amount of loss the vault incurred
    event VaultLoss(uint indexed optionId, uint vaultId, uint amount);

    /// @notice A oracle is been set to either enabled or disabled for this vault
    /// @param oracle Oracle address
    /// @param vaultId Vault id
    /// @param enabled Enabled or disabled
    /// @param collateralToken The erc20 token used for collateral
    /// @param decimals Oracle decimals
    /// @param description Oracle description
    event UpdateOracle(IOracle indexed oracle, uint indexed vaultId, bool enabled, IERC20 collateralToken, uint8 decimals, string description);

    /// @notice Generic event for when a boolean variable changes
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param vaultId Vault id
    /// @param from Changing from
    /// @param to Changing to
    event SetVaultBool(address indexed byAccount, SetVariableType indexed eventType, uint indexed vaultId, bool from, bool to);

    /// @notice Generic event for when a BoolState variable changes
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param vaultId Vault id
    /// @param from Changing from
    /// @param to Changing to
    event SetVaultBoolState(address indexed byAccount, SetVariableType indexed eventType, uint indexed vaultId, BoolState from, BoolState to);

    /// @notice Generic event for when an address variable changes
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param vaultId Vault id
    /// @param from Changing from
    /// @param to Changing to
    event SetVaultAddress(address indexed byAccount, SetVariableType indexed eventType, uint indexed vaultId, address from, address to);

    /// @notice Generic event for when a uint variable changes
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param vaultId Vault id
    /// @param from Changing from
    /// @param to Changing to
    event SetVaultUInt(address indexed byAccount, SetVariableType indexed eventType, uint indexed vaultId, uint256 from, uint256 to);

    /// @notice Trading/transfer window parameters are changed
    /// @param byAccount The account making the change
    /// @param _tradingWindow the number of seconds the trading window is open for
    /// @param _transferWindow the number of seconds the transfer window is open for
    /// @param _transferWindowStartTime the time when the transfer window should start
    event SetWindowParams(address indexed byAccount, uint256 _tradingWindow, uint256 _transferWindow,  uint256 _transferWindowStartTime);

    /// @notice The vault didn't have enough funds to pay an option profit
    /// @param vaultId Vault id
    event VaultInsolvent(uint indexed vaultId);

    // functions

    /// @notice Constructor for the vault
    /// @dev The vault clones a deployed contract and then call initialize
    constructor() ERC20("Optix Vault V1", "OPTIX-VAULT-V1") {}

    /// @notice The ERC20 token name for this vault
    function name() public view override returns (string memory) {
        return string.concat("Optix Vault V1-",Strings.toString(block.chainid),"-",Strings.toString(vaultId));
    }

    /// @notice The ERC20 token symbol for this vault
    function symbol() public view override returns (string memory) {
        return string.concat("OPTIX-VAULT-V1-",Strings.toString(block.chainid),"-",Strings.toString(vaultId));
    }

    /// @notice The ERC20 token decimals for this vault
    function decimals() public view override returns (uint8) {
        return decimalsConst;
    }


    /// @notice The vault is deployed by cloning so this is used inplace of a constructor.
    /// @param _owner The account that creates the vault is the initial owner
    /// @param _oracle Oracle address
    /// @param _collateralToken The erc20 token used for collateral
    /// @param _vaultFeeCalc The address that implements the fee calculations
    /// @param _vaultId The id for this vault
    function initialize(address _owner, IOracle _oracle, IERC20 _collateralToken, IFeeCalcs _vaultFeeCalc, uint256 _vaultId) external {
        require(address(factory) == address(0), "OptionsVaultERC20: can't be 0 address");
        collateralToken = _collateralToken;

        vaultFeeRecipient = _owner;
        vaultFeeCalc = _vaultFeeCalc;
        vaultFee = 100;
        maxInvest = type(uint256).max;
        lpOpenToPublic = BoolState.FalseMutable;
        buyerWhitelistOnly = BoolState.FalseMutable;
        oracleEnabledLocked = BoolState.FalseMutable;
        factory = IOptionsVaultFactory(_msgSender());
        vaultId = _vaultId;

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setupRole(VAULT_OPERATOR_ROLE, _owner);
        _setupRole(VAULT_LPWHITELIST_ROLE, _owner);
        _setupRole(VAULT_BUYERWHITELIST_ROLE, _owner);

        oracleEnabled[_oracle] = true;

        ERC20Decimals ct = ERC20Decimals(address(collateralToken));
        if (ct.decimals()==0){
           decimalsConst = 18;
        }
        else{
           decimalsConst = 18+ct.decimals();
        }
    }

    /// @notice A provider supplies token to the vault and receives optix vault tokens
    /// @param _collateralIn Amount to deposit in the collatoral token
    /// @return mintTokens Tokens minted to represent ownership
    function provide(uint256 _collateralIn) external returns (uint256 mintTokens){
        return provideAndMint(_collateralIn,true,false);
    }

    /// @notice Sends tokens to the vault optionally receiving minted tokens in return.
    /// @param _collateralIn Amount to deposit in the collatoral token
    /// @param _mintVaultTokens Whether to mint ownership tokens or not. Not minting increases the propotional balance for everyone
    /// @param _collectedWithPremium Option premium is collected by the ERC721 and transferred to the vault so it doesn't need to copy it again
    /// @return mintTokens The number of vault tokens minted
    function provideAndMint(uint256 _collateralIn, bool _mintVaultTokens, bool _collectedWithPremium) public nonReentrant returns (uint256 mintTokens) {

        if(_mintVaultTokens && lpOpenToPublic.IsFalse()){
            require(hasRole(VAULT_LPWHITELIST_ROLE, _msgSender()), "OptionsVaultERC20: must be in LP Whitelist");
        }

        if(_collectedWithPremium){
            require(factory.optionsContract() == _msgSender(), "OptionsVaultERC20: must be called from options contract");
        }
        else{
            require(!readOnly, "OptionsVaultERC20: vault is readonly");
            require(vaultCollateralTotal()+(_collateralIn*1e4/factory.getCollateralizationRatio(IOptionsVaultERC20(address(this))))<=maxInvest,"OptionsVaultERC20: max invest limit reached");
            if(lpOpenToPublic.IsTrue()&&!isInTransferWindow()){
                revert("OptionsVaultERC20: must be in transfer window");
            }
        }

        uint256 supply = totalSupply();
        uint balance = collateralReserves;
        if (supply > 0 && balance > 0){
            mintTokens = _collateralIn*supply/balance;
        }
        else
            mintTokens = _collateralIn*10**decimalsConst;
        require(mintTokens > 0, "OptionsVaultERC20: amount is too small");

        collateralReserves += _collateralIn;

        if(_mintVaultTokens){
            _mint(_msgSender(), mintTokens);
        }

        if(_collectedWithPremium){
            emit CollectPremium(_msgSender(), vaultId, _collateralIn);
        }
        else{
            emit Provide(_msgSender(), vaultId, _collateralIn, mintTokens, _mintVaultTokens);
            collateralToken.safeTransferFrom(_msgSender(), address(this), _collateralIn);
        }
    }

    /// @notice Withdraw from the vault, burning the user tokens
    /// @param _tokensToBurn Amount to deposit in the collatoral token
    /// @return collateralOut Amount of collateral tokens withdrawn
    function withdraw(uint256 _tokensToBurn) external nonReentrant returns (uint collateralOut) {

        if(_tokensToBurn==0){
            return 0;
        }

        if(lpOpenToPublic.IsTrue() && isInTradingWindow()){
            revert("OptionsVaultERC20: must be in transfer window");
        }

        collateralOut = collateralReserves * _tokensToBurn / totalSupply();
        require(collateralOut <= vaultCollateralAvailable(0),"OptionsVaultERC20: not enough unlocked collateral available");
        collateralReserves -= collateralOut;

        _burn(_msgSender(), _tokensToBurn); //will fail if they don't have enough
        emit Withdraw(_msgSender(), vaultId, collateralOut, _tokensToBurn);
        collateralToken.safeTransfer(_msgSender(), collateralOut);
    }


    /// @notice Called by Options to lock funds
    /// @param _optionId ID of the option
    /// @param _optionSize The amount of collateral to be locked
    /// @param _optionType Put or call
    function lock(uint _optionId, uint256 _optionSize, OptionType _optionType ) external  {

        require(factory.optionsContract() == _msgSender(), "OptionsVaultERC20: must be called from options contract");

        lockedCollateral[_optionId] = true;
        if(_optionType == OptionType.Put){
            lockedCollateralPut = lockedCollateralPut+_optionSize;
        }
        else{
            lockedCollateralCall = lockedCollateralCall+_optionSize;
        }

        emit Lock(_optionId, _optionSize);
    }

    /// @notice Option is expired, called by OptionsERC721 to unlock collateral
    /// @param _optionId ID of the option
    function unlock(uint256 _optionId) external  {
        require(lockedCollateral[_optionId], "OptionsVaultERC20: lockedCollateral with id has already unlocked");
        require(factory.optionsContract() == _msgSender(), "OptionsVaultERC20: must be called from options contract");

        Option memory o = IOptionsERC721(factory.optionsContract()).options(_optionId);
        lockedCollateral[_optionId] = false;

        if(o.optionType == OptionType.Put)
          lockedCollateralPut = lockedCollateralPut-o.optionSize;
        else
          lockedCollateralCall = lockedCollateralCall-o.optionSize;

        emit VaultProfit(_optionId, o.vaultId, o.premium.intrinsicFee+o.premium.extrinsicFee);
        emit Unlock(_optionId);
    }


    /// @notice Option is exercised and there are funds to send to the option holder. If the amount is greater than the option size then the options size is sent. 
    /// @param _optionId ID of the option
    /// @param _to Address to send the funds to
    /// @param _amount The amount to send
    function send(uint _optionId, address _to, uint256 _amount) public {
        require(lockedCollateral[_optionId], "OptionsVaultERC20: id already unlocked");
        require(_to != address(0), "OptionsVaultERC20: can't be 0 address");
        require(factory.optionsContract() == _msgSender(), "OptionsVaultERC20: must be called from options contract");

        Option memory o = IOptionsERC721(factory.optionsContract()).options(_optionId);

        lockedCollateral[_optionId] = false;
        if(o.optionType == OptionType.Put)
          lockedCollateralPut = lockedCollateralPut-o.optionSize;
        else
          lockedCollateralCall = lockedCollateralCall-o.optionSize;

        uint transferAmount = _amount > o.optionSize ? o.optionSize : _amount;
        uint cr = collateralReserves;

        if (collateralReserves>=transferAmount){

            if (transferAmount <= o.premium.intrinsicFee+o.premium.extrinsicFee)
                emit VaultProfit(_optionId, o.vaultId, o.premium.intrinsicFee+o.premium.extrinsicFee-transferAmount);
            else
                emit VaultLoss(_optionId, o.vaultId, transferAmount-o.premium.intrinsicFee+o.premium.extrinsicFee);
            emit Unlock(_optionId);

            collateralReserves -= transferAmount;
            collateralToken.safeTransfer(_to, transferAmount);
        }
        else{
            emit Unlock(_optionId);
            emit VaultInsolvent(o.vaultId);
            readOnly = true;

            collateralReserves = 0;
            collateralToken.safeTransfer(_to, cr);
        }
    }

    /// @notice Check if the option is valid or not
    /// @param _buyer Who is the buyer
    /// @param _period Option period in seconds
    /// @param _optionSize Option size
    /// @param _oracle Oracle address
    /// @return true if the options is allowed to be purchased
    function isOptionValid(address _buyer, uint256 _period, uint256 _optionSize, IOracle _oracle, uint256 _collectedPremium) public view returns (bool) {
        require(!readOnly, "OptionsVaultERC20: vault is readonly");
        if(factory.oracleIsPermissionless().IsFalse()){
            require(factory.oracleWhitelisted(_oracle),"OptionsVaultERC20: oracle must be in whitelist");
        }
        if(factory.collateralTokenIsPermissionless().IsFalse()){
            require(factory.collateralTokenWhitelisted(collateralToken),"OptionsVaultERC20: collateral token must be in whitelist");
        }
        require(oracleEnabled[_oracle],"OptionsVaultERC20: oracle not enabled for this vault");
        if(buyerWhitelistOnly.IsTrue()){
            require(hasRole(VAULT_BUYERWHITELIST_ROLE, _buyer), "OptionsVaultERC20: must be in _buyer whitelist");
        }
        require(vaultCollateralAvailable(_collectedPremium)>=_optionSize, "OptionsVaultERC20: not enough available collateral");
        if(lpOpenToPublic.IsTrue()){
            if(isInTradingWindow()){
                require(block.timestamp + _period<nextTransferWindowStartTime(),"OptionsVaultERC20: must expire before transfer window");
            }else{
                revert("OptionsVaultERC20: must be in the trading window");
            }
        }

        return true;
    }

    /// @notice Collateral reserves available, adjusted by collateralization ratio
    function vaultCollateralTotal() public view returns (uint256) {
        if(totalSupply()==0){
            return 0;
        }

        return 1e4*collateralReserves/factory.getCollateralizationRatio(IOptionsVaultERC20(address(this)));
    }

    /// @notice Sum of locked collateral puts & calls
    function vaultCollateralLocked() public view returns (uint256){
        return lockedCollateralPut+lockedCollateralCall;
    }

    /// @notice The total collateral less the amount locked
    function vaultCollateralAvailable(uint256 _includingPremium) public view returns (uint256) {
        if (vaultCollateralLocked()>vaultCollateralTotal()+_includingPremium){
            return 0;
        }
        return vaultCollateralTotal()+_includingPremium-vaultCollateralLocked();
    }

    /// @notice How much is the vault utilized from 0...10000 (100%). Also if the optionSize is included
    /// @param _includingOptionSize How much would the vault be utilized if this amount is included
    function vaultUtilization(uint256 _includingOptionSize) public view returns (uint256) {
        return (vaultCollateralLocked()+_includingOptionSize)*1e4/vaultCollateralTotal();
    }

    /// @notice A functions that returns true if the account passed in holds the DEFAULT_ADMIN_ROLE role
    /// @param _account account to check
    function hasRoleVaultOwner(address _account) public view returns (bool){
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice  A functions that returns true if the account passed in holds the DEFAULT_ADMIN_ROLE or VAULT_OPERATOR_ROLE roles
    /// @param _account account to check
    function hasRoleVaultOwnerOrOperator(address _account) public view returns (bool){
        return (hasRole(DEFAULT_ADMIN_ROLE, _account) || (hasRole(VAULT_OPERATOR_ROLE,_account)));
    }

    /// @notice Change the vault fee. Can only be called by the vault owner or operator
    /// @param _value Change the value to
    function setVaultFee(uint256 _value) external isVaultOwnerOrOperator {
        emit SetVaultUInt(_msgSender(),SetVariableType.VaultFee, vaultId, vaultFee, _value);
        vaultFee = _value;
    }

    /// @notice Change the trading/transfer window parameters. Can only be called by the vault owner or operator.
    /// This only applies to vaults open to the public. They only allow deposits & withdrawals during the transfer period.
    /// @param _tradingWindow The time in seconds that the trading window show be open for
    /// @param _transferWindow The time in seconds that the transfer window show be open for
    /// @param _transferWindowStartTime The time that the
    function setWindowParams(uint256 _tradingWindow, uint256 _transferWindow,  uint256 _transferWindowStartTime) external isVaultOwnerOrOperator isMutable(lpOpenToPublic) isPrivateOrInTransferWindow {
        require(_tradingWindow> 1 days,"OptionsVaultERC20: trading window must be more than a day");
        require(_transferWindow> 1 days,"OptionsVaultERC20: transfer window must be more than a day");
        require(_transferWindowStartTime>block.timestamp,"OptionsVaultERC20: transfer window start must be in the future");
        emit SetWindowParams(_msgSender(), _tradingWindow, _transferWindow, _transferWindow);
        tradingWindow = _tradingWindow;
        transferWindow = _transferWindow;
        transferWindowStartTime = _transferWindowStartTime;
    }

    /// @notice Set the vault to be open to the public. Immutable setting that can't be changed later. Can only be done by the vault owner. Default setting is that it's not open to the public.
    function setLPOpenToPublicTrueImmutable() public isVaultOwner isMutable(lpOpenToPublic) {
        require(transferWindowStartTime>block.timestamp,"OptionsVaultERC20: transfer window start must be in the future");
        emit SetVaultBoolState(_msgSender(),SetVariableType.LPOpenToPublic, vaultId, lpOpenToPublic, BoolState.TrueImmutable);
        lpOpenToPublic = BoolState.TrueImmutable;
    }

    /// @notice Set the address that the vault fee should be transferred to. Defaults to the vault creator.
    /// @param _value Change the value to
    function setVaultFeeRecipient(address _value) external isVaultOwner {
        require(_value != address(0),"OptionsVaultERC20: can't be 0 address");
        emit SetVaultAddress(_msgSender(),SetVariableType.VaultFeeRecipient, vaultId, vaultFeeRecipient, _value);
        vaultFeeRecipient = _value;
    }

    /// @notice Set the maximum amount of collateral that can be added to the vault. Defaults to the maximum uint value
    /// @param _value Change the value to
    function setMaxInvest(uint256 _value) external isVaultOwnerOrOperator {
        emit SetVaultUInt(_msgSender(),SetVariableType.MaxInvest, vaultId, maxInvest, _value);
        maxInvest = _value;
    }

    /// @notice Set whether the only buyers on a whitelist can buy from this vault or not. Defaults to no.
    /// @param _value Change the value to
    function setBuyerWhitelistOnly(bool _value) public isVaultOwnerOrOperator isMutable(buyerWhitelistOnly) isPrivateOrInTransferWindow {
        emit SetVaultBoolState(_msgSender(),SetVariableType.BuyerWhitelistOnly, vaultId, buyerWhitelistOnly, _value.ToBoolState());
        buyerWhitelistOnly = _value.ToBoolState();
    }

    /// @notice Set the buyerWhitelistOnly setting to be immutable.
    function setBuyerWhitelistOnlyImmutable() public isVaultOwner isMutable(buyerWhitelistOnly) isPrivateOrInTransferWindow {
        if (buyerWhitelistOnly.IsTrue()){
            emit SetVaultBoolState(_msgSender(),SetVariableType.BuyerWhitelistOnly, vaultId, buyerWhitelistOnly, BoolState.TrueImmutable);
            buyerWhitelistOnly = BoolState.TrueImmutable;
        }
        else{
            emit SetVaultBoolState(_msgSender(),SetVariableType.BuyerWhitelistOnly, vaultId, buyerWhitelistOnly, BoolState.FalseImmutable);
            buyerWhitelistOnly = BoolState.FalseImmutable;
        }
    }

    /// @notice Set the vault to be readonly. Options can't be created and liquidity can't be provided when its read only.
    /// @param _value Change the value to
    function setReadOnly(bool _value) external isVaultOwnerOrOperator {
        emit SetVaultBool(_msgSender(),SetVariableType.ReadOnly, vaultId, readOnly, _value);
        readOnly = _value;
    }

    /// @notice Set the address that implements the intrinsic, extrinsic & vault fees. If it is locked then it can't be changed. SimpleSeller contract is the default.
    /// @param _value Change the value to
    function setVaultFeeCalc(IFeeCalcs _value) external isVaultOwnerOrOperator isPrivateOrInTransferWindow {
        require(vaultFeeCalcLocked.IsFalse(),"OptionsVaultERC20: vaultFeeCalc is locked");
        emit SetVaultAddress(_msgSender(),SetVariableType.VaultFeeCalc, vaultId, address(vaultFeeCalc), address(_value));
        vaultFeeCalc = _value;
    }

    /// @notice Set whether its possible to change the address for implementing the intrinsic, extrinsic & vault fees.
    /// @param _value Change the value to
    function setVaultFeeCalcLocked(bool _value) public isVaultOwner isMutable(vaultFeeCalcLocked) isPrivateOrInTransferWindow {
        emit SetVaultBoolState(_msgSender(),SetVariableType.VaultFeeCalcLocked, vaultId, vaultFeeCalcLocked, _value.ToBoolState());
        vaultFeeCalcLocked = _value.ToBoolState();
    }

    /// @notice Set the vaultFeeCalcLocked setting to be immutable.
    function setVaultFeeCalcLockedImmutable() public isVaultOwner isMutable(vaultFeeCalcLocked) isPrivateOrInTransferWindow {
        if (vaultFeeCalcLocked.IsTrue()){
            emit SetVaultBoolState(_msgSender(),SetVariableType.VaultFeeCalcLocked, vaultId, vaultFeeCalcLocked, BoolState.TrueImmutable);
            vaultFeeCalcLocked = BoolState.TrueImmutable;
        }
        else{
            emit SetVaultBoolState(_msgSender(),SetVariableType.VaultFeeCalcLocked, vaultId, vaultFeeCalcLocked, BoolState.FalseImmutable);
            vaultFeeCalcLocked = BoolState.FalseImmutable;
        }
    }

    /// @notice Set the ipfs hash associated with this vault
    /// @param _value Change the value to
    function setIpfsHash(string calldata _value) external isVaultOwnerOrOperator {
        ipfsHash = _value;
    }

    /// @notice Set whether an oracle is enabled for this vault or not. Setting can be made immutable so no more changes can be made to which vaults to associate with a vault. The factory can also restrict whether oracles must be whitelisted or not. This setting is intended to only be used initially and then make it open & permissionless.
    /// @param _oracle Oracle address
    /// @param _value Change the value to
    function setOracleEnabled(IOracle _oracle, bool _value) external isVaultOwnerOrOperator isMutable(oracleEnabledLocked) isPrivateOrInTransferWindow {
        if(factory.oracleIsPermissionless().IsFalse()){
            require(factory.oracleWhitelisted(_oracle),"OptionsVaultERC20: oracle must be in whitelist");
        }
        oracleEnabled[_oracle] = _value;
        emit UpdateOracle(_oracle, vaultId, _value, collateralToken, _oracle.decimals(), _oracle.description());
    }

    /// @notice Lock down permanently the ability to change the oracles linked to this vault
    function setOracleEnabledLockedImmutable() public isVaultOwner isMutable(oracleEnabledLocked) isPrivateOrInTransferWindow {
        require(oracleEnabledLocked.IsMutable(),"OptionsVaultFactory: setting is immutable");
        emit SetVaultBoolState(_msgSender(),SetVariableType.OracleEnabledLocked, vaultId, oracleEnabledLocked, BoolState.TrueImmutable);
        oracleEnabledLocked = BoolState.TrueImmutable;
    }

    /// @notice Returns true if the current block timestamp is in the trading window
    function isInTradingWindow() public view returns (bool) {
        if (transferWindowStartTime>block.timestamp){
            return false;
        }
        else{
            uint256 timeInWindow = (block.timestamp-transferWindowStartTime) % (transferWindow+tradingWindow);
            return timeInWindow > transferWindow;
        }
    }

    /// @notice Returns true if the current block timestamp is in the transfer window
    function isInTransferWindow() public view returns (bool) {
        if (transferWindowStartTime>block.timestamp){
            return false;
        }
        else{
            uint256 timeInWindow = (block.timestamp-transferWindowStartTime) % (transferWindow+tradingWindow);
            return timeInWindow < transferWindow;
        }
    }

    /// @notice Returns the time when the next transfer window starts
    function nextTransferWindowStartTime() public view returns (uint256) {
        if (block.timestamp < transferWindowStartTime ){
            return 0;
        }
        uint256 timeInWindow = (block.timestamp-transferWindowStartTime) % (transferWindow+tradingWindow);
        return block.timestamp+transferWindow+tradingWindow-timeInWindow;
    }

    // modifiers

    /// @notice A modifer that checks if the caller holds the DEFAULT_ADMIN_ROLE role on this vault
    modifier isVaultOwner() {
        require(hasRoleVaultOwner(_msgSender()), "OptionsVaultERC20: must be vault owner");
        _;
    }

    /// @notice  A modifer that checks if the caller holds the DEFAULT_ADMIN_ROLE or VAULT_OPERATOR_ROLE roles
    modifier isVaultOwnerOrOperator() {
        require(hasRoleVaultOwnerOrOperator(_msgSender()), "OptionsVaultERC20: must have owner or operator role");
        _;
    }

    /// @notice  A modifer that checks if the vault is either private or in the transfer window
    modifier isPrivateOrInTransferWindow() {
        require(lpOpenToPublic.IsFalse() || isInTransferWindow(), "OptionsVaultERC20: must be private or transfer window");
        _;
    }

    /// @notice A modifier that checks if a BoolState is mutable
    /// @param _value Change the value to
    modifier isMutable(BoolState _value) {
        require(_value.IsMutable(),"OptionsVaultERC20: setting is immutable");
        _;
    }
}