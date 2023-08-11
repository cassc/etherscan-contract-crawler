// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// helper contracts
import { MultiCall } from "../../utils/MultiCall.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { VersionedInitializable } from "../../dependencies/openzeppelin/VersionedInitializable.sol";
import { IncentivisedERC20 } from "./IncentivisedERC20.sol";
import { Modifiers } from "../earn-protocol-configuration/contracts/Modifiers.sol";
import { VaultStorageV3 } from "./VaultStorage.sol";
import { EIP712Base } from "../../utils/EIP712Base.sol";

// libraries
import { Errors } from "../../utils/Errors.sol";
import { DataTypes } from "../earn-protocol-configuration/contracts/libraries/types/DataTypes.sol";

// interfaces
import { IRegistry } from "../earn-protocol-configuration/contracts/interfaces/opty/IRegistry.sol";

/**
 * @title Vault Migrator
 * @author opty.fi
 * @notice Implementation to admin mint the opToken
 */

contract VaultMigrator is
    VersionedInitializable,
    IncentivisedERC20,
    MultiCall,
    Modifiers,
    ReentrancyGuard,
    VaultStorageV3,
    EIP712Base
{
    /**
     * @dev The version of the Vault implementation
     */
    uint256 public constant opTOKEN_REVISION = 0x0;

    /**
     * @dev hash of the permit function
     */
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    //===Constructor===//

    /* solhint-disable no-empty-blocks */
    constructor(address _registry)
        public
        IncentivisedERC20(string(abi.encodePacked("opTOKEN_IMPL")), string(abi.encodePacked("opTOKEN_IMPL")))
        EIP712Base()
        Modifiers(_registry)
    {
        // Intentionally left blank
    }

    /**
     * @dev Initialize the vault
     * @param _registry The address of registry for helping get the protocol configuration
     * @param _underlyingTokensHash The keccak256 hash of the tokens and chain id
     * @param _whitelistedAccountsRoot Whitelisted accounts root hash
     * @param _symbol The symbol of the underlying  asset
     * @param _riskProfileCode Risk profile code of this vault
     * @param _vaultConfiguration Bit banging value for vault config
     * @param _userDepositCapUT Maximum amount in underlying token allowed to be deposited by user
     * @param _minimumDepositValueUT Minimum deposit value in underlying token required
     * @param _totalValueLockedLimitUT Maximum TVL in underlying token allowed for the vault
     */
    function initialize(
        address _registry,
        bytes32 _underlyingTokensHash,
        bytes32 _whitelistedAccountsRoot,
        string memory _symbol,
        uint256 _riskProfileCode,
        uint256 _vaultConfiguration,
        uint256 _userDepositCapUT,
        uint256 _minimumDepositValueUT,
        uint256 _totalValueLockedLimitUT
    ) external virtual initializer {
        require(bytes(_symbol).length > 0, Errors.EMPTY_STRING);
        registryContract = IRegistry(_registry);
        DataTypes.RiskProfile memory _riskProfile = registryContract.getRiskProfile(_riskProfileCode);
        _setRiskProfileCode(_riskProfileCode, _riskProfile.exists);
        _setUnderlyingTokensHash(_underlyingTokensHash);
        _setName(string(abi.encodePacked("OptyFi ", _symbol, " ", _riskProfile.name, " Vault")));
        _setSymbol(string(abi.encodePacked("op", _symbol, "-", _riskProfile.symbol)));
        _setDecimals(IncentivisedERC20(underlyingToken).decimals());
        _setWhitelistedAccountsRoot(_whitelistedAccountsRoot);
        _setVaultConfiguration(_vaultConfiguration);
        _setValueControlParams(_userDepositCapUT, _minimumDepositValueUT, _totalValueLockedLimitUT);
        _domainSeparator = _calculateDomainSeparator();
    }

    /* solhint-enable no-empty-blocks */

    //===External functions===//

    function adminCall(bytes[] memory _codes) external onlyGovernance {
        executeCodes(_codes, Errors.ADMIN_CALL);
    }

    function adminMint(address[] memory _accounts, uint256[] memory _amounts) external onlyGovernance {
        uint256 _count = _accounts.length;
        require(_count == _amounts.length, Errors.LENGTH_MISMATCH);
        for (uint256 _i; _i < _count; _i++) {
            _mint(_accounts[_i], _amounts[_i]);
        }
    }

    function adminBurn(address[] memory _accounts, uint256[] memory _amounts) external onlyGovernance {
        uint256 _count = _accounts.length;
        require(_count == _amounts.length, Errors.LENGTH_MISMATCH);
        for (uint256 _i; _i < _count; _i++) {
            _burn(_accounts[_i], _amounts[_i]);
        }
    }

    /* solhint-disable-next-line func-name-mixedcase */
    function _EIP712BaseId() internal view override returns (string memory) {
        return name();
    }

    /**
     * @inheritdoc EIP712Base
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        uint256 __chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            __chainId := chainid()
        }
        if (__chainId == _chainId) {
            return _domainSeparator;
        }
        return _calculateDomainSeparator();
    }

    /**
     * @inheritdoc EIP712Base
     */
    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner];
    }

    /* solhint-enable-next-line func-name-mixedcase */

    //===Internal pure functions===//

    /**
     * @inheritdoc VersionedInitializable
     */
    function getRevision() internal pure virtual override returns (uint256) {
        return opTOKEN_REVISION;
    }

    /**
     * @dev Internal function to save risk profile code
     * @param _riskProfileCode risk profile code
     * @param _exists true if risk profile exists
     */
    function _setRiskProfileCode(uint256 _riskProfileCode, bool _exists) internal {
        require(_exists, Errors.RISK_PROFILE_EXISTS);
        vaultConfiguration =
            (_riskProfileCode << 240) |
            (vaultConfiguration & 0xFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    /**
     * @dev Internal function to save underlying tokens hash
     * @param _underlyingTokensHash keccak256 hash of underlying token address and chain id
     */
    function _setUnderlyingTokensHash(bytes32 _underlyingTokensHash) internal {
        address[] memory _tokens = registryContract.getTokensHashToTokenList(_underlyingTokensHash);
        require(_tokens.length == 1, Errors.UNDERLYING_TOKENS_HASH_EXISTS);
        require(registryContract.isApprovedToken(_tokens[0]), Errors.UNDERLYING_TOKEN_APPROVED);
        underlyingTokensHash = _underlyingTokensHash;
        underlyingToken = _tokens[0];
    }

    /**
     * @dev Internal function to configure the vault's fee params
     * @param _vaultConfiguration bit banging value for vault config
     */
    function _setVaultConfiguration(uint256 _vaultConfiguration) internal {
        vaultConfiguration = _vaultConfiguration;
    }

    /**
     * @dev Internal function to control the allowance of user interaction
     *         only when vault's whitelistedstate is enabled
     * @param _whitelistedAccountsRoot whitelisted accounts root hash
     */
    function _setWhitelistedAccountsRoot(bytes32 _whitelistedAccountsRoot) internal {
        whitelistedAccountsRoot = _whitelistedAccountsRoot;
    }

    /**
     * @dev Internal function to configure the vault's value control params
     * @param _userDepositCapUT maximum amount in underlying token allowed to be deposited by user
     * @param _minimumDepositValueUT minimum deposit value in underlying token required
     * @param _totalValueLockedLimitUT maximum TVL in underlying token allowed for the vault
     */
    function _setValueControlParams(
        uint256 _userDepositCapUT,
        uint256 _minimumDepositValueUT,
        uint256 _totalValueLockedLimitUT
    ) internal {
        _setUserDepositCapUT(_userDepositCapUT);
        _setMinimumDepositValueUT(_minimumDepositValueUT);
        _setTotalValueLockedLimitUT(_totalValueLockedLimitUT);
    }

    /**
     * @dev Internal function to set the maximum amount in underlying token
     *      that a user could deposit in entire life cycle of this vault
     * @param _userDepositCapUT maximum amount in underlying allowed to be deposited by user
     */
    function _setUserDepositCapUT(uint256 _userDepositCapUT) internal {
        userDepositCapUT = _userDepositCapUT;
        emit LogUserDepositCapUT(userDepositCapUT, msg.sender);
    }

    /**
     * @dev Internal function to set minimum amount in underlying token required
     *      to be deposited by the user
     * @param _minimumDepositValueUT minimum deposit value in underlying token required
     */
    function _setMinimumDepositValueUT(uint256 _minimumDepositValueUT) internal {
        minimumDepositValueUT = _minimumDepositValueUT;
        emit LogMinimumDepositValueUT(minimumDepositValueUT, msg.sender);
    }

    /**
     * @dev Internal function to set the total value locked limit in underlying token
     * @param _totalValueLockedLimitUT maximum TVL in underlying allowed for the vault
     */
    function _setTotalValueLockedLimitUT(uint256 _totalValueLockedLimitUT) internal {
        totalValueLockedLimitUT = _totalValueLockedLimitUT;
        emit LogTotalValueLockedLimitUT(totalValueLockedLimitUT, msg.sender);
    }

    /**
     * @notice Emitted when setUserDepositCapUT is called
     * @param userDepositCapUT Cap in underlying token for user deposits in OptyFi's Vault contract
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogUserDepositCapUT(uint256 indexed userDepositCapUT, address indexed caller);

    /**
     * @notice Emitted when setMinimumDepositValueUT is called
     * @param minimumDepositValueUT Minimum deposit in OptyFi's Vault contract - only for deposits (without rebalance)
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogMinimumDepositValueUT(uint256 indexed minimumDepositValueUT, address indexed caller);

    /**
     * @notice Emitted when setTotalValueLockedLimitUT is called
     * @param totalValueLockedLimitUT Maximum limit for total value locked of OptyFi's Vault contract
     * @param caller Address of user who has called the respective function to trigger this event
     */
    event LogTotalValueLockedLimitUT(uint256 indexed totalValueLockedLimitUT, address indexed caller);
}