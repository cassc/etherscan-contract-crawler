// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../ImplBase.sol";
import "../../helpers/errors.sol";
import "../../interfaces/optimism.sol";

/**
// @title Native Optimism Bridge Implementation.
// @author Socket Technology.
*/
contract NativeOptimismImpl is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
    // @notice We set all the required addresses in the constructor while deploying the contract.
    // These will be constant addresses.
    // @dev Please use the Proxy addresses and not the implementation addresses while setting these 
    // @param _registry address of the registry contract that calls this contract
    */
    constructor(address _registry) ImplBase(_registry) {}

    /**
    // @param _amount amount to be sent.
    // @param _from sending address.
    // @param _receiverAddress receiving address.
    // @param _token address of the token to be bridged to optimism.
     */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256,
        bytes memory _extraData
    ) external payable override onlyRegistry nonReentrant {
        OptimismBridgeExtraData memory _optimismBridgeExtraData = abi.decode(
            _extraData,
            (OptimismBridgeExtraData)
        );
        require(
            _optimismBridgeExtraData._interfaceId != 0,
            MovrErrors.UNSUPPORTED_INTERFACE_ID
        );
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value != 0, MovrErrors.VALUE_SHOULD_NOT_BE_ZERO);
            L1StandardBridge(_optimismBridgeExtraData._customBridgeAddress)
                .depositETHTo{value: _amount}(
                _receiverAddress,
                _optimismBridgeExtraData._l2Gas,
                _optimismBridgeExtraData._data
            );
            return;
        }
        require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
        IERC20 token = IERC20(_token);
        // set allowance for erc20 predicate
        token.safeTransferFrom(_from, address(this), _amount);
        token.safeIncreaseAllowance(
            _optimismBridgeExtraData._customBridgeAddress,
            _amount
        );

        if (_optimismBridgeExtraData._interfaceId == 1) {
            // deposit into standard bridge
            L1StandardBridge(_optimismBridgeExtraData._customBridgeAddress)
                .depositERC20To(
                    _token,
                    _optimismBridgeExtraData._l2Token,
                    _receiverAddress,
                    _amount,
                    _optimismBridgeExtraData._l2Gas,
                    _optimismBridgeExtraData._data
                );
            return;
        }

        // Deposit Using Old Standard - iOVM_L1TokenGateway(Example - SNX Token)
        if (_optimismBridgeExtraData._interfaceId == 2) {
            OldL1TokenGateway(_optimismBridgeExtraData._customBridgeAddress)
                .depositTo(_receiverAddress, _amount);
        }

        if (_optimismBridgeExtraData._interfaceId == 3) {
            OldL1TokenGateway(_optimismBridgeExtraData._customBridgeAddress)
                .initiateSynthTransfer(
                    _optimismBridgeExtraData._currencyKey,
                    _receiverAddress,
                    _amount
                );
        }
    }
}