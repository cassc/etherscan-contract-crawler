// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IPALMManager} from "../interfaces/IPALMManager.sol";
import {IArrakisV2} from "../interfaces/IArrakisV2.sol";
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

/// @dev owner should be the PALMTerms smart contract.
abstract contract PALMManagerStorage is
    IPALMManager,
    OwnableUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // #region gelato bots.

    address payable public immutable gelato;

    // #endregion gelato bots.

    // #region manager fees.

    uint16 public immutable managerFeeBPS;

    // #endregion manager fees.

    // #region PALMTerms.

    address public immutable terms;

    // #endregion PALMTerms.

    // #region PALMTerms Market Making Duration.

    uint256 public immutable termDuration;

    // #endregion PALMTerms Market Making Duration.

    // #region whitelisted strategies.

    EnumerableSet.Bytes32Set internal _whitelistedStrat;

    // #endregion whitelisted strategies.

    // #region vaults related data.

    mapping(address => VaultInfo) public vaults;

    // #endregion vaults related data.

    // #region operators.

    address[] public operators;

    // #endregion operators.

    // #region modifiers.

    modifier onlyPALMTerms() {
        require(msg.sender == terms, "PALMManager: only PALMTerms");
        _;
    }

    modifier onlyPALMTermsVaults(address vault) {
        require(
            IArrakisV2(vault).owner() == terms,
            "PALMManager: owner no PALMTerms"
        );
        _;
    }

    modifier onlyManagedVaults(address vault) {
        require(vaults[vault].termEnd != 0, "PALMManager: Vault not managed");
        _;
    }

    modifier onlyVaultOwner(address vault) {
        require(
            IArrakisV2(vault).owner() == msg.sender,
            "PALMManager: only vault owner"
        );
        _;
    }

    modifier onlyOperators() {
        (bool isOperator, ) = _isOperator(msg.sender);
        require(isOperator, "PALMManager: no operator");
        _;
    }

    modifier requireAddressNotZero(address addr) {
        require(addr != address(0), "PALMManager: address Zero");
        _;
    }

    // #endregion modifiers.

    // #region constructor.

    constructor(
        address gelato_,
        uint16 managerFeeBPS_,
        address terms_,
        uint256 termDuration_
    ) {
        gelato = payable(gelato_);
        managerFeeBPS = managerFeeBPS_;
        terms = terms_;
        termDuration = termDuration_;
    }

    // #endregion constructor.

    // #region initialize function.

    function initialize(address owner_) external initializer {
        _transferOwnership(owner_);
        __Pausable_init();
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
        onlyPALMTermsVaults(vault_)
    {
        _addVault(vault_, datas_, strat_);
        if (msg.value > 0) _fundVaultBalance(vault_);
    }

    function removeVault(address vault_, address payable to_)
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyVaultOwner(vault_)
    {
        require(vaults[vault_].termEnd != 0, "PALMManager: Vault not managed");
        _removeVault(vault_, to_);
    }

    function setVaultData(address vault_, bytes calldata data_)
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyVaultOwner(vault_)
        onlyManagedVaults(vault_)
    {
        _setVaultData(vault_, data_);
    }

    function setVaultStraByName(address vault_, string calldata strat_)
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyVaultOwner(vault_)
        onlyManagedVaults(vault_)
    {
        _setVaultStrat(vault_, keccak256(abi.encodePacked(strat_)));
    }

    function addOperators(address[] calldata operators_)
        external
        override
        whenNotPaused
        onlyOwner
    {
        for (uint256 i = 0; i < operators_.length; i++) {
            (bool isOperator, ) = _isOperator(operators_[i]);
            require(!isOperator, "PALMManager: operator");
            operators.push(operators_[i]);
        }

        emit AddOperators(address(this), operators_);
    }

    function removeOperators(address[] calldata operators_)
        external
        override
        whenNotPaused
        onlyOwner
    {
        _removeOperators(operators_);
    }

    function withdrawFeesEarned(address[] calldata tokens_, address to_)
        external
        override
        whenNotPaused
        onlyOwner
    {
        for (uint256 i = 0; i < tokens_.length; i++) {
            uint256 balance = IERC20(tokens_[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(tokens_[i]).safeTransfer(to_, balance);
            }
        }
    }

    function withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    )
        external
        override
        whenNotPaused
        requireAddressNotZero(vault_)
        onlyVaultOwner(vault_)
        onlyManagedVaults(vault_)
        requireAddressNotZero(address(to_))
    {
        _withdrawVaultBalance(vault_, amount_, to_);
    }

    function fundVaultBalance(address vault_)
        external
        payable
        override
        whenNotPaused
        onlyManagedVaults(vault_)
    {
        _fundVaultBalance(vault_);
    }

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

        emit WhitelistStrat(address(this), strat_);
    }

    function getWhitelistedStrat()
        external
        view
        override
        returns (bytes32[] memory)
    {
        return _whitelistedStrat.values();
    }

    function getVaultInfo(address vault_)
        external
        view
        override
        requireAddressNotZero(vault_)
        returns (VaultInfo memory)
    {
        return vaults[vault_];
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
        vaults[vault_].balance += msg.value;
        emit UpdateVaultBalance(vault_, vaults[vault_].balance);
    }

    function _removeVault(address vault_, address payable to_) internal {
        uint256 balance = vaults[vault_].balance;
        vaults[vault_].balance = 0;

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
        for (uint256 i = 0; i < operators_.length; i++) {
            (bool isOperator, uint256 index) = _isOperator(operators_[i]);
            require(isOperator, "PALMManager: no operator");

            delete operators[index];
        }

        emit RemoveOperators(address(this), operators_);
    }

    function _withdrawVaultBalance(
        address vault_,
        uint256 amount_,
        address payable to_
    ) internal {
        require(
            vaults[vault_].balance >= amount_,
            "PALMManager: amount exceeds available balance"
        );
        vaults[vault_].balance -= amount_;
        to_.sendValue(amount_);

        emit WithdrawVaultBalance(vault_, amount_, to_, vaults[vault_].balance);
    }

    function _isOperator(address operator_)
        internal
        view
        requireAddressNotZero(operator_)
        returns (bool, uint256)
    {
        for (uint256 index = 0; index < operators.length; index++) {
            if (operators[index] == operator_) return (true, index);
        }
        return (false, 0);
    }

    // #endregion internal functions.
}