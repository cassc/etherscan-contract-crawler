// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;
import "./interfaces/Interfaces.sol";

/// @title Options Vault Factory
/// @author dannydoritoeth
/// @notice The central contract for deploying and managing option collateral vaults.
contract OptionsVaultFactory is AccessControl, IStructs, ReentrancyGuard {
    using OptionsLib for BoolState;

    // properties
    IOptionsVaultERC20[] public vaults;
    mapping(address => uint256) internal _vaultId;
    address public optionsContract;
    mapping(IOracle => bool) public oracleWhitelisted;
    mapping(IERC20 => bool) public collateralTokenWhitelisted;
    mapping(IOptionsVaultERC20 => uint256) public collateralizationRatio;
    BoolState public createVaultIsPermissionless = BoolState.FalseMutable;
    BoolState public oracleIsPermissionless = BoolState.FalseMutable;
    BoolState public collateralTokenIsPermissionless = BoolState.FalseMutable;

    // constants
    address public immutable optionVaultERC20Implementation;
    bytes32 public immutable CREATE_VAULT_ROLE = keccak256("CREATE_VAULT_ROLE");
    bytes32 public immutable COLLATERAL_RATIO_ROLE = keccak256("COLLATERAL_RATIO_ROLE");

    // events
    /// @notice A new vault is created
    /// @param vaultId Vault id
    /// @param oracle Oracle address
    /// @param collateralToken The erc20 token used for collateral
    /// @param vault The address of the newly created IOptionsERC20Vault
    event CreateVault(uint indexed vaultId, IOracle oracle, IERC20 collateralToken, address vault);

    /// @notice A generic event for changes to a global bool variable
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param from Changing from
    /// @param to Changing to
    event SetGlobalBool(address indexed byAccount, SetVariableType indexed eventType, bool from, bool to);

    /// @notice A generic event for changes to a global bool variable
    /// @param byAccount The account making the change
    /// @param eventType The type of event this change is
    /// @param from Changing from
    /// @param to Changing to
    event SetGlobalBoolState(address indexed byAccount, SetVariableType indexed eventType, BoolState from, BoolState to);

    /// @notice The collateral ratio for a vault has changed. In basis points.
    /// @param byAccount The account making the change
    /// @param _address the vault being changed
    /// @param _from Changing from
    /// @param _to Changing to
    event SetCollateralRatio(address indexed byAccount, IOptionsVaultERC20 _address, uint256 _from, uint256 _to);

    /// @notice Deploy a new factory contract
    /// @param _optionVaultERC20Implementation the vaultERC20 implementation to be used
    constructor(address _optionVaultERC20Implementation)  {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(COLLATERAL_RATIO_ROLE, _msgSender());
        _setupRole(CREATE_VAULT_ROLE, _msgSender());
        optionVaultERC20Implementation = _optionVaultERC20Implementation;
    }

    /// @notice Inialize the contract
    /// @param _optionsContract the options contract to link the factory to
    function initialize(address _optionsContract) external isDefaultAdmin {
        require(optionsContract == address(0),"OptionsVaultFactory: must be 0 address");
        optionsContract = _optionsContract;
    }

    /// @notice Allows anyone to create a new vault. Each vault must have a configured collateral token which is the underlying asset of the options of that vault. The vault will then pay out option payoffs using these tokens. The collateral token is immutable. An oracle is linked to the vault but oracles can be linked & unlinked. 
    /// @dev Explain to a developer any extra details
    /// @param _oracle Oracle address
    /// @param _collateralToken The erc20 token used for collateral
    /// @param _vaultFeeCalc The address that implements the fee calculations
    /// @return The address of the vault created
    function createVault(IOracle _oracle, IERC20 _collateralToken, IFeeCalcs _vaultFeeCalc) nonReentrant external returns (address){
        if(createVaultIsPermissionless.IsFalse()){
            require(hasRole(CREATE_VAULT_ROLE, _msgSender()), "OptionsVaultFactory: must hold CREATE_VAULT_ROLE");
        }

        if(oracleIsPermissionless.IsFalse()){
            require(oracleWhitelisted[_oracle],"OptionsVaultFactory: oracle must be in whitelist");
        }
        if(collateralTokenIsPermissionless.IsFalse()){
            require(collateralTokenWhitelisted[_collateralToken],"OptionsVaultFactory: collateral token must be in whitelist");
        }
        uint length = vaults.length;
        address vault = Clones.clone(optionVaultERC20Implementation);
        IOptionsVaultERC20(vault).initialize(_msgSender(),_oracle,_collateralToken,_vaultFeeCalc,length);

        emit CreateVault(length, _oracle, _collateralToken, vault);

        _vaultId[vault] = length;
        vaults.push(IOptionsVaultERC20(vault));
        return vault;
    }

    /// @notice A helper function to return the length of the vaults array
    function vaultsLength() external view returns(uint) {
        return vaults.length;
    }

    /// @notice Anyone can create vaults; permissionless & immutable
    function setCreateVaultIsPermissionlessImmutable() external isDefaultAdmin isMutable(createVaultIsPermissionless) {
        emit SetGlobalBoolState(_msgSender(),SetVariableType.CreateVaultIsPermissionless, createVaultIsPermissionless, BoolState.TrueImmutable);
        createVaultIsPermissionless = BoolState.TrueImmutable;
    }

    /// @notice Any oracle can be linked to vaults; permissionless & immutable
    function setOracleIsPermissionlessImmutable() external isDefaultAdmin isMutable(oracleIsPermissionless) {
        emit SetGlobalBoolState(_msgSender(),SetVariableType.OracleIsPermissionless, oracleIsPermissionless, BoolState.TrueImmutable);
        oracleIsPermissionless = BoolState.TrueImmutable;
    }

    /// @notice Any erc20 token can be used for collateral in vaults, permissionless & immutable
    function setCollateralTokenIsPermissionlessImmutable() external isDefaultAdmin isMutable(collateralTokenIsPermissionless) {
        emit SetGlobalBoolState(_msgSender(),SetVariableType.CollateralTokenIsPermissionless, collateralTokenIsPermissionless, BoolState.TrueImmutable);
        collateralTokenIsPermissionless = BoolState.TrueImmutable;
    }

    /// @notice Allow an oracle to be whitelisted. Whitelisted oracles can be linked and unlinked to vaults.
    /// @param _oracle Oracle address
    /// @param _value Change the value to
    function setOracleWhitelisted(IOracle _oracle, bool _value) external isDefaultAdmin {
        emit SetGlobalBool(_msgSender(),SetVariableType.OracleWhitelisted, oracleWhitelisted[_oracle], _value);
        oracleWhitelisted[_oracle] = _value;
    }

    /// @notice Allow a token to be whitelisted. Whitelisted tokens can be used for collateral in vaults.
    /// @param _collateralToken The erc20 token used for collateral
    /// @param _value Change the value to
    function setCollateralTokenWhitelisted(IERC20 _collateralToken, bool _value) external isDefaultAdmin {
        emit SetGlobalBool(_msgSender(),SetVariableType.CollateralTokenWhitelisted, collateralTokenWhitelisted[_collateralToken], _value);
        collateralTokenWhitelisted[_collateralToken] = _value;
    }

    /// @notice A modifer that checks if the caller holds the DEFAULT_ADMIN_ROLE role on the factor contract
    modifier isDefaultAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "OptionsVaultFactory: must have admin role");
        _;
    }

    /// @notice Returns the collateralization ratio for a given vault address in basis points.
    /// @param _address the vault address to check
    function getCollateralizationRatio(IOptionsVaultERC20 _address) external view returns (uint256) {
        if (collateralizationRatio[_address]==0){
            return 10000;
        }
        else{
            return collateralizationRatio[_address];
        }
    }

    /// @notice Bulk update the collatarization ratios for a set of vaults
    /// @param _address the array of vault addresses to update
    /// @param _ratio the array of ratios to be applied
    function setCollateralizationRatioBulk(IOptionsVaultERC20[] calldata _address, uint256[] calldata _ratio) external {
        require(_address.length == _ratio.length, "OptionsVaultFactory: lengths different");
        require(hasRole(COLLATERAL_RATIO_ROLE, _msgSender()), "OptionsVaultFactory: must have collateral ratio role");

        uint arrayLength = _address.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            require(_ratio[i]>1000, "OptionsVaultFactory: must be greather than 1000");
            require(vaultId(address(_address[i]))!=0,"OptionsVaultFactory: address doesn't exist");
            emit SetCollateralRatio(_msgSender(),_address[i],collateralizationRatio[_address[i]],_ratio[i]);
            collateralizationRatio[_address[i]] = _ratio[i];
        }
    }

    /// @notice Update a single collateralization ratio for a vault
    /// @param _address the vault address to update
    /// @param _ratio the ratio to be applied
    function setCollateralizationRatio(IOptionsVaultERC20 _address, uint256 _ratio) public {
        require(_ratio>1000, "OptionsVaultFactory: must be greather than 1000");
        require(hasRole(COLLATERAL_RATIO_ROLE, _msgSender()), "OptionsVaultFactory: must have collateral ratio role");
        require(vaultId(address(_address))!=0,"OptionsVaultFactory: address doesn't exist");

        emit SetCollateralRatio(_msgSender(),_address,collateralizationRatio[_address],_ratio);
        collateralizationRatio[_address] = _ratio;
    }

    /// @notice Gets the vault id for an address or reverts if it doesn't exist
    /// @param _address Address to check
    function vaultId(address _address) public view returns (uint){

        if (vaults.length == 0){
            revert("OptionsVaultFactory: address doesn't exist");
        }

        uint256 id = _vaultId[_address];
        if(id == 0){
            if(address(vaults[0])==_address){
                return 0;
            }
            revert("OptionsVaultFactory: address doesn't exist");
        }
        return id;
    }

    /// modifiers

    /// @notice A modifier that checks if a BoolState is mutable
    /// @param _value Change the value to
    modifier isMutable(BoolState _value) {
        require(_value.IsMutable(),"OptionsVaultERC20: setting is immutable");
        _;
    }

}