// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../interfaces/IERCHandler.sol";
import "../interfaces/IFeeManager.sol";
import "../interfaces/IHandlerReserve.sol";

/// @title Function used across handler contracts.
/// @author Router Protocol.
/// @notice This contract is intended to be used with the Bridge contract.
contract HandlerHelpersUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable, IERCHandler {
    address public _bridgeAddress;
    address public _oneSplitAddress;
    address public override _ETH;
    address public override _WETH;
    bool public _isFeeEnabled;
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    IFeeManagerUpgradeable public feeManager;
    IHandlerReserve public _reserve;

    // resourceID => token contract address
    mapping(bytes32 => address) internal _resourceIDToTokenContractAddress;

    // token contract address => resourceID
    mapping(address => bytes32) public _tokenContractAddressToResourceID;

    // token contract address => is whitelisted
    mapping(address => bool) public _contractWhitelist;

    // token contract address => is burnable
    mapping(address => bool) public _burnList;

    // bytes32 public constant FEE_SETTER_ROLE = keccak256("FEE_SETTER_ROLE");

    function __HandlerHelpersUpgradeable_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(BRIDGE_ROLE, _msgSender());
        _isFeeEnabled = false;
    }

    function __HandlerHelpersUpgradeable_init_unchained() internal initializer {}

    // function grantFeeRole(address account) public virtual override onlyRole(BRIDGE_ROLE) {
    //     grantRole(FEE_SETTER_ROLE, account);
    //     totalFeeSetters = totalFeeSetters + 1;
    // }

    // function revokeFeeRole(address account) public virtual override onlyRole(BRIDGE_ROLE) {
    //     revokeRole(FEE_SETTER_ROLE, account);
    //     totalFeeSetters = totalFeeSetters - 1;
    // }

    /// @notice Function to set the fee manager address
    /// @dev Can only be called by default admin
    /// @param _feeManager address of the fee manager
    function setFeeManager(IFeeManagerUpgradeable _feeManager) public onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager = _feeManager;
    }

    /// @notice Function to set the bridge fee.
    /// @dev Can only be called by resource setter.
    /// @param destinationChainID chainId for destination chain.
    /// @param feeTokenAddress address of the fee token.
    /// @param transferFee fee for cross-chain transfer.
    /// @param exchangeFee fee for cross-chain swaps.
    /// @param accepted true if the fee token is an accepted fee token.
    function setBridgeFee(
        uint8 destinationChainID,
        address feeTokenAddress,
        uint256 transferFee,
        uint256 exchangeFee,
        bool accepted
    ) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        feeManager.setFee(destinationChainID, feeTokenAddress, transferFee, exchangeFee, accepted);
    }

    /// @notice Function to get the bridge fee
    /// @param destinationChainID chainId for destination chain
    /// @param feeTokenAddress address of the fee token
    /// @param widgetID widgetID
    /// @return fees struct
    function getBridgeFee(uint8 destinationChainID, address feeTokenAddress, uint256 widgetID)
        public
        view
        virtual
        override
        returns (uint256, uint256, uint256)
    {
        return feeManager.getFee(destinationChainID, feeTokenAddress, widgetID);
    }

    /// @notice Function to set fee status
    /// @dev Can only be called by bridge
    /// @param status true to enable the fees
    function toggleFeeStatus(bool status) public virtual override onlyRole(BRIDGE_ROLE) {
        _isFeeEnabled = status;
    }

    /// @notice Function to get the fee status
    /// @return feeStatus
    function getFeeStatus() public view virtual override returns (bool) {
        return _isFeeEnabled;
    }

    /// @notice Function to get the token contract address from resource Id
    /// @param resourceID resourceID for the token
    /// @return tokenAddress
    function resourceIDToTokenContractAddress(bytes32 resourceID) public view virtual override returns (address) {
        return _resourceIDToTokenContractAddress[resourceID];
    }

    /// @notice First verifies {_resourceIDToContractAddress}[{resourceID}] and
    /// {_contractAddressToResourceID}[{contractAddress}] are not already set,
    /// then sets {_resourceIDToContractAddress} with {contractAddress},
    /// {_contractAddressToResourceID} with {resourceID},
    /// and {_contractWhitelist} to true for {contractAddress}.
    /// @dev Can only be called by the bridge
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) public virtual override onlyRole(BRIDGE_ROLE) {
        _setResource(resourceID, contractAddress);
    }

    /// @notice First verifies {contractAddress} is whitelisted, then sets {_burnList}[{contractAddress}]
    /// to true.
    /// @dev Can only be called by the bridge
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    /// @param status Boolean flag to change burnable status.

    function setBurnable(address contractAddress, bool status) public virtual override onlyRole(BRIDGE_ROLE) {
        _setBurnable(contractAddress, status);
    }

    /// @notice Used to manually release funds from ERC safes.
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount the amount of ERC20 tokens to release.
    function withdraw(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override {}

    /// @notice Used to withdraw fees from fee manager.
    /// @param tokenAddress Address of token contract to release.
    /// @param recipient Address to release tokens to.
    /// @param amount the amount of tokens to release.
    function withdrawFees(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) public virtual override {}

    /// @notice Sets oneSplitAddress for the handler
    /// @dev Can only be set by the bridge
    /// @param contractAddress Address of oneSplit contract
    function setOneSplitAddress(address contractAddress) public virtual override onlyRole(BRIDGE_ROLE) {
        _setOneSplitAddress(contractAddress);
    }

    /// @notice Sets liquidity pool for given ERC20 address. These pools will be used to
    /// stake and unstake liqudity.
    /// @dev Can only be set by the bridge
    /// @param contractAddress Address of contract for which LP contract should be set.
    /// @param lpAddress Address of lp contract.
    function setLiquidityPool(
        // string memory name,
        // string memory symbol,
        // uint8 decimals,
        address contractAddress,
        address lpAddress
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        // address newLPAddress = _reserve._setLiquidityPool(name, symbol, decimals, contractAddress, lpAddress);
        address newLPAddress = _reserve._setLiquidityPool(contractAddress, lpAddress);
        _contractWhitelist[newLPAddress] = true;
        _burnList[newLPAddress] = true;
    }

    /// @notice Sets liquidity pool owner for an existing LP.
    /// @dev Can only be set by the bridge
    /// @param oldOwner Address of the old owner of LP
    /// @param newOwner Address of the new owner for LP
    /// @param tokenAddress Address of ERC20 token
    /// @param lpAddress Address of LP.
    function setLiquidityPoolOwner(
        address oldOwner,
        address newOwner,
        address tokenAddress,
        address lpAddress
    ) public virtual override onlyRole(BRIDGE_ROLE) {
        _reserve._setLiquidityPoolOwner(oldOwner, newOwner, tokenAddress, lpAddress);
    }

    /// @notice Sets resource for the bridge.
    /// @param resourceID resourceID of ERC20 tokens
    /// @param contractAddress Address of ERC20 tokens
    function _setResource(bytes32 resourceID, address contractAddress) internal virtual {
        require(contractAddress != address(0), "contract address can't be zero");

        _resourceIDToTokenContractAddress[resourceID] = contractAddress;
        _tokenContractAddressToResourceID[contractAddress] = resourceID;
        _contractWhitelist[contractAddress] = true;
    }

    /// @notice Sets a resource burnable.
    /// @param contractAddress Address of ERC20 token
    /// @param status true for burnable, false for not burnable
    function _setBurnable(address contractAddress, bool status) internal virtual {
        require(_contractWhitelist[contractAddress], "provided contract is not whitelisted");
        _burnList[contractAddress] = status;
    }

    /// @notice Sets onesplit address.
    /// @param contractAddress Address of OneSplit contract
    function _setOneSplitAddress(address contractAddress) internal virtual {
        require(contractAddress != address(0), "ERC20Handler: contractAddress cannot be null");
        _oneSplitAddress = address(contractAddress);
    }
}