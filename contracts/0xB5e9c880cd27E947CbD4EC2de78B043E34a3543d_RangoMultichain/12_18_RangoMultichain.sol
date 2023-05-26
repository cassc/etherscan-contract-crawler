// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../libs/BaseContract.sol";
import "../../rango/bridges/multichain/IRangoMultichain.sol";
import "./RangoMultichainModels.sol";
import "./MultichainRouter.sol";

/// @title The root contract that handles Rango's interaction with MultichainOrg bridge
/// @author Uchiha Sasuke
/// @dev This is deployed as a separate contract from RangoV1
contract RangoMultichain is IRangoMultichain, BaseContract {

    /// @notice Notifies that some new router addresses are whitelisted
    /// @param _addresses The newly whitelisted addresses
    event MultichainRoutersAdded(address[] _addresses);

    /// @notice Notifies that some router addresses are blacklisted
    /// @param _addresses The addresses that are removed
    event MultichainRoutersRemoved(address[] _addresses);

    /// @notice An event showing that a MultichainOrg bridge call happened
    /// @param _actionType The type of bridge action which indicates the name of the function of MultichainOrg contract to be called
    /// @param _fromToken The address of bridging token
    /// @param _underlyingToken For _actionType = OUT_UNDERLYING, it's the address of the underlying token
    /// @param _inputAmount The amount of the token to be bridged
    /// @param multichainRouter Address of MultichainOrg contract on the current chain
    /// @param _receiverAddress The address of end-user on the destination
    /// @param _receiverChainID The network id of destination chain
    event MultichainBridge(
        RangoMultichainModels.MultichainBridgeType _actionType,
        address _fromToken,
        address _underlyingToken,
        uint _inputAmount,
        address multichainRouter,
        address _receiverAddress,
        uint _receiverChainID
    );

    /// @notice List of whitelisted MultichainOrg routers in the current chain
    mapping(address => bool) public multichainRouters;


    /// @notice The constructor of this contract that receives WETH address and initiates the settings
    /// @param _nativeWrappedAddress The address of WETH, WBNB, etc of the current network
    constructor(address _nativeWrappedAddress) {
        BaseContractStorage storage baseStorage = getBaseContractStorage();
        baseStorage.nativeWrappedAddress = _nativeWrappedAddress;
    }

    /// @notice Enables the contract to receive native ETH token from other contracts including WETH contract
    receive() external payable { }

    /// @notice Adds a list of new addresses to the whitelisted MultichainOrg routers
    /// @param _addresses The list of new routers
    function addMultichainRouters(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            multichainRouters[_addresses[i]] = true;
        }

        emit MultichainRoutersAdded(_addresses);
    }

    /// @notice Removes a list of routers from the whitelisted addresses
    /// @param _addresses The list of addresses that should be depricated
    function removeMultichainRouters(address[] calldata _addresses) external onlyOwner {
        for (uint i = 0; i < _addresses.length; i++) {
            delete multichainRouters[_addresses[i]];
        }

        emit MultichainRoutersRemoved(_addresses);
    }

    /// @inheritdoc IRangoMultichain
    function multichainBridge(
        RangoMultichainModels.MultichainBridgeType _actionType,
        address _fromToken,
        address _underlyingToken,
        uint _inputAmount,
        address _multichainRouter,
        address _receiverAddress,
        uint _receiverChainID
    ) external override payable whenNotPaused nonReentrant {
        require(multichainRouters[_multichainRouter], 'Requested router address not whitelisted');
        if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT_NATIVE) {
            require(msg.value >= _inputAmount, 'Insufficient ETH sent for OUT_NATIVE action');
            require(_fromToken == NULL_ADDRESS, 'Invalid _fromToken, it must be equal to null address');
        }

        if (_actionType != RangoMultichainModels.MultichainBridgeType.OUT_NATIVE) {
            SafeERC20.safeTransferFrom(IERC20(_fromToken), msg.sender, address(this), _inputAmount);
            approve(_fromToken, _multichainRouter, _inputAmount);
        }

        MultichainRouter router = MultichainRouter(_multichainRouter);

        if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT) {
            router.anySwapOut(_underlyingToken, _receiverAddress, _inputAmount, _receiverChainID);
        } else if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT_UNDERLYING) {
            router.anySwapOutUnderlying(_underlyingToken, _receiverAddress, _inputAmount, _receiverChainID);
        } else if (_actionType == RangoMultichainModels.MultichainBridgeType.OUT_NATIVE) {
            router.anySwapOutNative{value: msg.value}(_underlyingToken, _receiverAddress, _receiverChainID);
        } else {
            revert();
        }

        emit MultichainBridge(_actionType, _fromToken, _underlyingToken, _inputAmount, _multichainRouter, _receiverAddress, _receiverChainID);
    }
}