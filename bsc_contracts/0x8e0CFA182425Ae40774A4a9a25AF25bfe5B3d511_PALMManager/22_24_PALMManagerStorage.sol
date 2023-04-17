// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IPALMManager} from "../interfaces/IPALMManager.sol";
import {
    IArrakisV2
} from "@arrakisfi/v2-core/contracts/interfaces/IArrakisV2.sol";
import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {
    PausableUpgradeable
} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {VaultInfo} from "../structs/SPALMManager.sol";

// solhint-disable-next-line max-states-count
abstract contract PALMManagerStorage is
    IPALMManager,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    // #region PALMTerms.

    address public immutable terms;

    // #endregion PALMTerms.

    // #region PALMTerms Market Making Duration.

    uint256 public immutable termDuration;

    // #endregion PALMTerms Market Making Duration.

    // #region manager Fee BPS.

    uint16 public immutable managerFeeBPS;

    // #endregion manager Fee BPS.

    // #region whitelisted strategies.

    EnumerableSet.Bytes32Set internal _whitelistedStrat;

    // #endregion whitelisted strategies.

    // #region operators.

    EnumerableSet.AddressSet internal _operators;

    // #endregion operators.

    // #region vaults related data.

    mapping(address => VaultInfo) public vaults;

    // #endregion vaults related data.

    // #region gelato bots.

    address payable public gelatoFeeCollector;

    // #endregion gelato bots.

    // #region modifiers.

    modifier onlyPALMTerms() {
        require(msg.sender == terms, "PALMManager: only PALMTerms");
        _;
    }

    modifier onlyVaultOwner(address vault) {
        require(
            IArrakisV2(vault).owner() == msg.sender,
            "PALMManager: only vault owner"
        );
        _;
    }

    modifier onlyManagedVaults(address vault) {
        require(vaults[vault].termEnd != 0, "PALMManager: Vault not managed");
        _;
    }

    modifier onlyOperators() {
        require(_isOperator(msg.sender), "PALMManager: no operator");
        _;
    }

    modifier requireAddressNotZero(address addr) {
        require(addr != address(0), "PALMManager: address Zero");
        _;
    }

    // #endregion modifiers.

    // #region constructor.

    constructor(
        address terms_,
        uint256 termDuration_,
        uint16 _managerFeeBPS_
    ) {
        terms = terms_;
        termDuration = termDuration_;
        managerFeeBPS = _managerFeeBPS_;
    }

    // #endregion constructor.

    // #region initialize function.

    function initialize(address owner_, address gelatoFeeCollector_)
        external
        initializer
    {
        require(owner_ != address(0), "PALMManager: owner is address zero");
        require(
            gelatoFeeCollector_ != address(0),
            "PALMManager: gelatoFeeCollector is address zero"
        );
        _transferOwnership(owner_);
        __Pausable_init();
        gelatoFeeCollector = payable(gelatoFeeCollector_);
        emit SetGelatoFeeCollector(gelatoFeeCollector_);
    }

    // #endregion initialize function.

    // #region permissioned owner functions.

    function pause() external override onlyOwner {
        _pause();
    }

    function unpause() external override onlyOwner {
        _unpause();
    }

    // #endregion permissioned owner functions.

    /// @notice add vault to manage
    /// @param vault_ Arrakis V2 vault address
    /// @param datas_ metadata that be used by PALM to manage vault
    /// @param strat_ strategy type chosen by client
    /// @dev only callable by Terms and only for Terms owned vault.
    function addVault(
        address vault_,
        bytes calldata datas_,
        string calldata strat_
    )
        external
        payable
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyPALMTerms
        onlyVaultOwner(vault_)
    {
        _addVault(vault_, datas_, strat_);
        if (msg.value > 0) _fundVaultBalance(vault_);
    }

    /// @notice remove vault from management
    /// @param vault_ Arrakis V2 vault address
    /// @param to_ address that will left over balance.
    /// @dev only callable by Terms and only for Terms owned vault.
    function removeVault(address vault_, address payable to_)
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyPALMTerms
        onlyManagedVaults(vault_)
    {
        _removeVault(vault_, to_);
    }

    /// @notice for setting managed vault meta data
    /// @param vault_ Arrakis V2 vault address
    /// @param data_ metadata used by PALM to manage the vault
    /// @dev only callable by Terms and only for Terms owned vault.
    function setVaultData(address vault_, bytes calldata data_)
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyPALMTerms
        onlyManagedVaults(vault_)
    {
        _setVaultData(vault_, data_);
    }

    /// @notice for changing strategy type
    /// @param vault_ Arrakis V2 vault address
    /// @param strat_ strategy type chosen by client
    /// @dev only callable by Terms and only for Terms owned vault.
    function setVaultStratByName(address vault_, string calldata strat_)
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyPALMTerms
        onlyManagedVaults(vault_)
    {
        _setVaultStrat(vault_, keccak256(abi.encodePacked(strat_)));
    }

    /// @notice for setting gelato fee collector
    /// @param gelatoFeeCollector_ new gelato fee collector address
    /// @dev only callable by owner
    function setGelatoFeeCollector(address payable gelatoFeeCollector_)
        external
        override
        whenNotPaused
        onlyOwner
        requireAddressNotZero(gelatoFeeCollector_)
    {
        require(
            gelatoFeeCollector != gelatoFeeCollector_,
            "PALMManager: gelatoFeeCollector"
        );
        gelatoFeeCollector = gelatoFeeCollector_;
        emit SetGelatoFeeCollector(gelatoFeeCollector_);
    }

    /// @notice for setting manager fee
    /// @param vault_ Arrakis V2 vault address
    /// @dev only callable by owner
    function setManagerFeeBPS(address vault_)
        external
        override
        whenNotPaused
        onlyPALMTerms
    {
        IArrakisV2(vault_).setManagerFeeBPS(managerFeeBPS);
        emit SetManagerFeeBPS(vault_, managerFeeBPS);
    }

    /// @notice for adding operators
    /// @param operators_ list of operators to add
    /// @dev only callable by owner
    function addOperators(address[] calldata operators_)
        external
        override
        whenNotPaused
        onlyOwner
    {
        for (uint256 i; i < operators_.length; ++i) {
            require(
                operators_[i] != address(0) && _operators.add(operators_[i]),
                "PALMManager: operator"
            );
        }

        emit AddOperators(operators_);
    }

    /// @notice for removing operators
    /// @param operators_ list of operators to remove
    /// @dev only callable by owner
    function removeOperators(address[] calldata operators_)
        external
        override
        whenNotPaused
        onlyOwner
    {
        _removeOperators(operators_);
    }

    /// @notice for withdrawing fee earn as manager
    /// @param tokens_ list of tokens where withdrawing fees
    /// @param to_ receiver of fees
    /// @dev only callable by owner
    function withdrawFeesEarned(address[] calldata tokens_, address to_)
        external
        override
        whenNotPaused
        onlyOwner
    {
        for (uint256 i; i < tokens_.length; i++) {
            uint256 balance = IERC20(tokens_[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(tokens_[i]).safeTransfer(to_, balance);
            }
        }
    }

    /// @notice for withdrawing vault fund balance
    /// @param vault_ Arrakis V2 vault address
    /// @param amount_ amount of balance to retrieve
    /// @param to_ receiver of balance
    /// @dev only callable by palm term and managed vault
    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    )
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyPALMTerms
        onlyManagedVaults(vault_)
        requireAddressNotZero(address(to_))
    {
        _withdrawVaultBalance(vault_, amount_, to_);
    }

    /// @notice fund vault balance
    /// @param vault_ Arrakis V2 vault address
    /// @dev only for managed vault
    function fundVaultBalance(address vault_)
        external
        payable
        override
        whenNotPaused
        onlyManagedVaults(vault_)
    {
        _fundVaultBalance(vault_);
    }

    /// @notice fund vault balance
    /// @param vault_ Arrakis V2 vault address
    /// @dev only for managed vault
    function renewTerm(address vault_)
        external
        override
        whenNotPaused
        onlyPALMTerms
        requireAddressNotZero(vault_)
        onlyManagedVaults(vault_)
    {
        emit SetTermEnd(
            vault_,
            vaults[vault_].termEnd,
            // solhint-disable-next-line not-rely-on-time
            vaults[vault_].termEnd = block.timestamp + termDuration
        );
    }

    /// @notice whitelist strategy as owner
    /// @param strat_ strategy type to whitelist
    /// @dev only for managed vault
    function whitelistStrat(string calldata strat_)
        external
        whenNotPaused
        onlyOwner
    {
        bytes32 stratB32 = keccak256(abi.encodePacked(strat_));
        require(
            stratB32 != keccak256(abi.encodePacked("")),
            "PALMManager: empty string"
        );
        require(
            !_whitelistedStrat.contains(stratB32),
            "PALMManager: strat whitelisted."
        );
        _whitelistedStrat.add(stratB32);

        emit WhitelistStrat(strat_);
    }

    /// @notice get whitelisted list of strategies
    function getWhitelistedStrat()
        external
        view
        override
        returns (bytes32[] memory)
    {
        return _whitelistedStrat.values();
    }

    /// @notice get vault info
    /// @param vault_ Arrakis V2 vault address
    /// @return vaultInfo data related to Arrakis V2 vault managed
    function getVaultInfo(address vault_)
        external
        view
        override
        requireAddressNotZero(vault_)
        returns (VaultInfo memory)
    {
        return vaults[vault_];
    }

    /// @notice get list of operators
    /// @return operators array of address representing operators
    function getOperators() external view override returns (address[] memory) {
        return _operators.values();
    }

    // #region internal functions.

    function _addVault(
        address vault_,
        bytes calldata datas_,
        string calldata strat_
    ) internal {
        bytes32 stratEncoded = keccak256(abi.encodePacked(strat_));
        require(
            _whitelistedStrat.contains(stratEncoded),
            "PALMManager: Not whitelisted"
        );
        require(
            vaults[vault_].termEnd == 0,
            "PALMManager: Vault already added"
        );
        vaults[vault_].datas = datas_;
        vaults[vault_].strat = stratEncoded;

        // solhint-disable-next-line not-rely-on-time
        vaults[vault_].termEnd = block.timestamp + termDuration;

        emit AddVault(vault_, datas_, strat_);
    }

    function _fundVaultBalance(address vault_) internal {
        require(msg.value > 0, "PALMManager: cannot fund with 0");
        vaults[vault_].balance += msg.value;
        emit UpdateVaultBalance(vault_, vaults[vault_].balance);
    }

    function _removeVault(address vault_, address payable to_) internal {
        uint256 balance = vaults[vault_].balance;

        IArrakisV2(vault_).withdrawManagerBalance();

        delete vaults[vault_];

        if (balance > 0) to_.sendValue(balance);

        emit RemoveVault(vault_, balance);
    }

    function _setVaultData(address vault_, bytes memory data_) internal {
        require(
            keccak256(vaults[vault_].datas) != keccak256(data_),
            "PALMManager: data"
        );

        vaults[vault_].datas = data_;

        emit SetVaultData(vault_, data_);
    }

    function _setVaultStrat(address vault_, bytes32 strat_) internal {
        require(vaults[vault_].strat != strat_, "PALMManager: strat");

        require(
            _whitelistedStrat.contains(strat_),
            "PALMManager: strat not whitelisted."
        );

        vaults[vault_].strat = strat_;

        emit SetVaultStrat(vault_, strat_);
    }

    function _removeOperators(address[] memory operators_) internal {
        for (uint256 i; i < operators_.length; ++i) {
            require(
                _operators.remove(operators_[i]),
                "PALMManager: no operator"
            );
        }

        emit RemoveOperators(operators_);
    }

    function _withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) internal {
        uint256 oldBalance = vaults[vault_].balance;
        require(
            oldBalance >= amount_,
            "PALMManager: amount exceeds available balance"
        );
        uint256 newBalance = oldBalance - amount_;
        vaults[vault_].balance = newBalance;
        to_.sendValue(amount_);

        emit WithdrawVaultBalance(vault_, amount_, to_, newBalance);
    }

    function _isOperator(address operator_)
        internal
        view
        requireAddressNotZero(operator_)
        returns (bool)
    {
        return _operators.contains(operator_);
    }

    // #endregion internal functions.
}