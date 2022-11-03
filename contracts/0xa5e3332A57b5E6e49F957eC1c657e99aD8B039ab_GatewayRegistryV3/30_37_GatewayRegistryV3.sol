// SPDX-License-Identifier: GPL-3.0

// solhint-disable-next-line
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {IMintGateway} from "../Gateways/interfaces/IMintGateway.sol";
import {ILockGateway} from "../Gateways/interfaces/ILockGateway.sol";
import {StringV1} from "../libraries/StringV1.sol";
import {RenAssetFactory} from "./RenAssetFactory.sol";
import {StringSet} from "../libraries/StringSet.sol";
import {GatewayRegistryStateV2, GatewayRegistryGettersV2, GatewayRegistryV2} from "./GatewayRegistry.sol";

/// @dev if any new values are being added, GatewayRegistryStateV3 should
/// be updated to have all the values from GatewayRegistryStateV2 instead of
/// inheriting from it, to that values can be added before the __gap.
contract GatewayRegistryStateV3 is GatewayRegistryStateV2 {

}

contract GatewayRegistryGettersV3 is GatewayRegistryGettersV2, GatewayRegistryStateV3 {}

/// GatewayRegistry is a mapping from assets to their associated
/// RenERC20 and Gateway contracts.
contract GatewayRegistryV3 is
    Initializable,
    AccessControlEnumerableUpgradeable,
    RenAssetFactory,
    GatewayRegistryStateV3,
    GatewayRegistryGettersV3
{
    using StringSet for StringSet.Set;

    string public constant NAME = "GatewayRegistry";
    bytes32 public constant CAN_UPDATE_GATEWAYS = keccak256("CAN_UPDATE_GATEWAYS");
    bytes32 public constant CAN_ADD_GATEWAYS = keccak256("CAN_ADD_GATEWAYS");

    function __GatewayRegistry_init(
        uint256 chainId_,
        address signatureVerifier_,
        address transferContract,
        address renAssetProxyBeacon_,
        address mintGatewayProxyBeacon_,
        address lockGatewayProxyBeacon_,
        address adminAddress,
        address[] calldata gatewayDeployers
    ) external initializer {
        __AccessControlEnumerable_init();
        __RenAssetFactory_init(renAssetProxyBeacon_, mintGatewayProxyBeacon_, lockGatewayProxyBeacon_);
        _chainId = chainId_;
        _signatureVerifier = signatureVerifier_;
        _transferContract = transferContract;

        AccessControlEnumerableUpgradeable._setupRole(AccessControlUpgradeable.DEFAULT_ADMIN_ROLE, adminAddress);
        AccessControlEnumerableUpgradeable._setupRole(CAN_UPDATE_GATEWAYS, adminAddress);
        AccessControlEnumerableUpgradeable._setupRole(CAN_ADD_GATEWAYS, adminAddress);
        for (uint256 i = 0; i < gatewayDeployers.length; ++i) {
            _setupRole(CAN_ADD_GATEWAYS, gatewayDeployers[i]);
        }
    }

    /// @dev The symbol is included twice because strings have to be hashed
    /// first in order to be used as a log index/topic.
    event LogMintGatewayAdded(
        string symbol,
        address indexed token,
        address indexed gatewayContract,
        // Indexed versions of previous parameters.
        string indexed indexedSymbol
    );
    event LogMintGatewayRemoved(
        string symbol,
        // Indexed versions of previous parameters.
        string indexed indexedSymbol
    );
    event LogLockGatewayAdded(
        string symbol,
        address indexed token,
        address indexed gatewayContract,
        // Indexed versions of previous parameters.
        string indexed indexedSymbol
    );
    event LogLockGatewayRemoved(
        string symbol,
        // Indexed versions of previous parameters.
        string indexed indexedSymbol
    );

    event LogSignatureVerifierUpdated(address indexed oldSignatureVerifier, address indexed newSignatureVerifier);
    event LogTransferContractUpdated(address indexed oldTransferContract, address indexed newTransferContract);

    // MODIFIERS ///////////////////////////////////////////////////////////////

    modifier onlyValidString(string calldata str_) {
        require(StringV1.isValidString(str_), "GatewayRegistry: empty or invalid string input");
        _;
    }

    function checkRoleVerbose(
        bytes32 role,
        string memory roleName,
        address account
    ) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "GatewayRegistry: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        roleName
                    )
                )
            );
        }
    }

    modifier onlyRoleVerbose(bytes32 role, string memory roleName) {
        checkRoleVerbose(role, roleName, _msgSender());
        _;
    }

    // GOVERNANCE //////////////////////////////////////////////////////////////

    /// @notice Allow the owner to update the signature verifier contract.
    ///
    /// @param newSignatureVerifier The new verifier contract address.
    function updateSignatureVerifier(address newSignatureVerifier)
        external
        onlyRoleVerbose(CAN_UPDATE_GATEWAYS, "CAN_UPDATE_GATEWAYS")
    {
        require(newSignatureVerifier != address(0x0), "GatewayRegistry: invalid signature verifier");
        address oldSignatureVerifier = _signatureVerifier;
        _signatureVerifier = newSignatureVerifier;
        emit LogSignatureVerifierUpdated(oldSignatureVerifier, newSignatureVerifier);
    }

    /// @notice Allow the owner to update the TransferContract contract.
    ///
    /// @param newTransferContract The new TransferContract contract address.
    function updateTransferContract(address newTransferContract)
        external
        onlyRoleVerbose(CAN_UPDATE_GATEWAYS, "CAN_UPDATE_GATEWAYS")
    {
        require(newTransferContract != address(0x0), "GatewayRegistry: invalid transfer with log");
        address oldTransferContract = _transferContract;
        _transferContract = newTransferContract;
        emit LogTransferContractUpdated(oldTransferContract, newTransferContract);
    }

    // MINT GATEWAYS ///////////////////////////////////////////////////////////

    /// @notice Allow the owner to set the Gateway contract for a given
    ///         RenERC20 token contract.
    ///
    /// @param symbol A string that identifies the token and gateway pair.
    /// @param renAsset The address of the RenERC20 token contract.
    /// @param mintGateway The address of the Gateway contract.
    function addMintGateway(
        string calldata symbol,
        address renAsset,
        address mintGateway
    ) public onlyValidString(symbol) onlyRoleVerbose(CAN_ADD_GATEWAYS, "CAN_ADD_GATEWAYS") {
        if (mintGatewaySymbols.contains(symbol)) {
            // If there is an existing gateway for the symbol, delete it. The
            // caller must also have the CAN_UPDATE_GATEWAYS role.
            removeMintGateway(symbol);
        }

        // Check that token, Gateway and symbol haven't already been registered.
        if (StringV1.isNotEmpty(mintSymbolByToken[renAsset])) {
            revert(
                string(
                    abi.encodePacked(
                        "GatewayRegistry: ",
                        symbol,
                        " token already registered as ",
                        mintSymbolByToken[renAsset]
                    )
                )
            );
        }

        // Add to list of gateways.
        mintGatewaySymbols.add(symbol);

        mintGatewayDetailsBySymbol[symbol] = GatewayDetails({token: renAsset, gateway: mintGateway});
        mintSymbolByToken[renAsset] = symbol;

        emit LogMintGatewayAdded(symbol, renAsset, mintGateway, symbol);
    }

    function deployMintGateway(
        string calldata symbol,
        address renAsset,
        string calldata version
    ) external onlyRoleVerbose(CAN_ADD_GATEWAYS, "CAN_ADD_GATEWAYS") {
        if (mintGatewaySymbols.contains(symbol)) {
            // Check role before expensive contract deployment.
            checkRoleVerbose(CAN_UPDATE_GATEWAYS, "CAN_UPDATE_GATEWAYS", _msgSender());
        }

        address mintGateway = address(_deployMintGateway(symbol, getSignatureVerifier(), renAsset, version));
        addMintGateway(symbol, renAsset, mintGateway);
    }

    function deployMintGatewayAndRenAsset(
        string calldata symbol,
        string calldata erc20Name,
        string calldata erc20Symbol,
        uint8 erc20Decimals,
        string calldata version
    ) external onlyRoleVerbose(CAN_ADD_GATEWAYS, "CAN_ADD_GATEWAYS") {
        if (mintGatewaySymbols.contains(symbol)) {
            // Check role before expensive contract deployment.
            checkRoleVerbose(CAN_UPDATE_GATEWAYS, "CAN_UPDATE_GATEWAYS", _msgSender());
        }

        address renAsset = address(
            _deployRenAsset(getChainId(), symbol, erc20Name, erc20Symbol, erc20Decimals, version)
        );
        address mintGateway = address(_deployMintGateway(symbol, getSignatureVerifier(), renAsset, version));
        OwnableUpgradeable(renAsset).transferOwnership(mintGateway);
        addMintGateway(symbol, renAsset, mintGateway);
    }

    /// @notice Allows the owner to remove the Gateway contract for a given
    ///         RenERC20 contract.
    ///
    /// @param symbol The symbol of the token to deregister.
    function removeMintGateway(string calldata symbol)
        public
        onlyRoleVerbose(CAN_UPDATE_GATEWAYS, "CAN_UPDATE_GATEWAYS")
    {
        address renAsset = mintGatewayDetailsBySymbol[symbol].token;
        require(renAsset != address(0x0), "GatewayRegistry: gateway not registered");

        // Remove token and Gateway contract
        delete mintSymbolByToken[renAsset];
        delete mintGatewayDetailsBySymbol[symbol];
        mintGatewaySymbols.remove(symbol);

        emit LogMintGatewayRemoved(symbol, symbol);
    }

    // LOCK GATEWAYS ///////////////////////////////////////////////////////////

    /// @notice Allow the owner to set the Gateway contract for a given
    ///         RenERC20 token contract.
    ///
    /// @param symbol A string that identifies the token and gateway pair.
    /// @param lockAsset The address of the RenERC20 token contract.
    /// @param lockGateway The address of the Gateway contract.
    function addLockGateway(
        string calldata symbol,
        address lockAsset,
        address lockGateway
    ) public onlyValidString(symbol) onlyRoleVerbose(CAN_ADD_GATEWAYS, "CAN_ADD_GATEWAYS") {
        if (lockGatewaySymbols.contains(symbol)) {
            // If there is an existing gateway for the symbol, delete it. The
            // caller must also have the CAN_UPDATE_GATEWAYS role.
            removeLockGateway(symbol);
        }

        // Check that token hasn't already been registered.
        if (StringV1.isNotEmpty(lockSymbolByToken[lockAsset])) {
            revert(
                string(
                    abi.encodePacked(
                        "GatewayRegistry: ",
                        symbol,
                        " token already registered as ",
                        lockSymbolByToken[lockAsset]
                    )
                )
            );
        }

        // Add to list of gateways.
        lockGatewaySymbols.add(symbol);

        lockGatewayDetailsBySymbol[symbol] = GatewayDetails({token: lockAsset, gateway: lockGateway});
        lockSymbolByToken[lockAsset] = symbol;

        emit LogLockGatewayAdded(symbol, lockAsset, lockGateway, symbol);
    }

    function deployLockGateway(
        string calldata symbol,
        address lockToken,
        string calldata version
    ) external onlyRoleVerbose(CAN_ADD_GATEWAYS, "CAN_ADD_GATEWAYS") {
        if (lockGatewaySymbols.contains(symbol)) {
            // Check role before expensive contract deployment.
            checkRoleVerbose(CAN_UPDATE_GATEWAYS, "CAN_UPDATE_GATEWAYS", _msgSender());
        }

        address lockGateway = address(_deployLockGateway(symbol, getSignatureVerifier(), lockToken, version));
        addLockGateway(symbol, lockToken, lockGateway);
    }

    /// @notice Allows the owner to remove the Gateway contract for a given
    ///         asset contract.
    ///
    /// @param symbol The symbol of the token to deregister.
    function removeLockGateway(string calldata symbol)
        public
        onlyRoleVerbose(CAN_UPDATE_GATEWAYS, "CAN_UPDATE_GATEWAYS")
    {
        require(lockGatewaySymbols.contains(symbol), "GatewayRegistry: gateway not registered");

        address lockAsset = lockGatewayDetailsBySymbol[symbol].token;

        // Remove token and Gateway contract
        delete lockSymbolByToken[lockAsset];
        delete lockGatewayDetailsBySymbol[symbol];
        lockGatewaySymbols.remove(symbol);

        emit LogLockGatewayRemoved(symbol, symbol);
    }
}