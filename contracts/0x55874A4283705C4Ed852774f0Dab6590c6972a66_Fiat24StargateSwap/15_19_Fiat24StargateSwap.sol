// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateReceiver.sol";
import "./interfaces/IStargateWidget.sol";
import "./interfaces/IStargateEthVault.sol";

error Fiat24StargateSwap__NotOperator(address sender);
error Fiat24StargateSwap__Paused();
error Fiat24StargateSwap__QtyZero(uint256 qty);
error Fiat24StargateSwap__MsgValueZero(uint256 msgValue);
error Fiat24StargateSwap__NotValidOutputToken(address token);

contract Fiat24StargateSwap is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
        
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    uint16 public constant ETH_POOL_ID = 13;

    address public stargateRouter;
    address public stargateEthVault;
    uint16 public dstPoolId;

    mapping (address => bool) public validOutputTokens;

    function initialize(
        address _stargateRouter, 
        address _stargateEthVault, 
        uint16 _destPoolId, 
        address[] memory _validOutputTokens
    ) public initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(OPERATOR_ROLE, _msgSender());
        stargateRouter = _stargateRouter;
        stargateEthVault = _stargateEthVault;
        dstPoolId = _destPoolId;
        for(uint i; i < _validOutputTokens.length; i++) {
            validOutputTokens[_validOutputTokens[i]] = true;
        }
    }

    function swap(
        uint qty,
        address bridgeToken,                    // the address of the native ERC20 to swap() - *must* be the token for the poolId
        uint16 dstChainId,                      // Stargate/LayerZero chainId
        uint16 srcPoolId,                       // stargate poolId - *must* be the poolId for the qty asset
        //uint16 dstPoolId,                       // stargate destination poolId
        address outputToken,                    // xxx24 output token to receive at destination
        address to,                             // the address to send the destination tokens to
        address destStargateComposed,           // destination contract. it must implement sgReceive()
        uint256 dstGasLimit                     // gas limit for destination contract execution
    ) external payable {
        if(paused()) revert Fiat24StargateSwap__Paused();
        if(msg.value == 0) revert Fiat24StargateSwap__MsgValueZero(msg.value);
        if(qty == 0) revert Fiat24StargateSwap__QtyZero(qty);
        if(!validOutputTokens[outputToken]) revert Fiat24StargateSwap__NotValidOutputToken(outputToken);
        
        bytes memory data = abi.encode(to, outputToken);

        IERC20Upgradeable(bridgeToken).safeTransferFrom(msg.sender, address(this), qty);
        IERC20Upgradeable(bridgeToken).safeApprove(address(stargateRouter), qty);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(stargateRouter).swap{value: msg.value}(
            dstChainId,                                      // the destination chain id
            srcPoolId,                                       // the source Stargate poolId
            dstPoolId,                                         // the destination Stargate poolId
            payable(msg.sender),                               // refund adddress. if msg.sender pays too much gas, return extra eth
            qty,                                             // total tokens to send to destination chain
            0,                                                 // min amount allowed out
            IStargateRouter.lzTxObj(dstGasLimit, 0, "0x"),   // default lzTxObj
            abi.encodePacked(destStargateComposed),          // destination address, the sgReceive() implementer
            data                                               // bytes payload
        );
    }

    function swapEth(
        uint qty,
        uint16 dstChainId,                      // Stargate/LayerZero chainId
        //uint16 srcPoolId,                       // stargate poolId - *must* be the poolId for the qty asset
        //uint16 dstPoolId,                       // stargate destination poolId
        address outputToken,                    // xxx24 output token to receive at destination
        address to,                             // the address to send the destination tokens to
        address destStargateComposed,           // destination contract. it must implement sgReceive()
        uint256 dstGasLimit                     // gas limit for destination contract execution
    ) external payable {
        if(paused()) revert Fiat24StargateSwap__Paused();
        if(msg.value == 0) revert Fiat24StargateSwap__MsgValueZero(msg.value);
        if(qty == 0) revert Fiat24StargateSwap__QtyZero(qty);
        if(!validOutputTokens[outputToken]) revert Fiat24StargateSwap__NotValidOutputToken(outputToken);

        bytes memory data = abi.encode(to, outputToken);

        IStargateEthVault(stargateEthVault).deposit{value: qty}();
        IStargateEthVault(stargateEthVault).approve(address(stargateRouter), qty);

        uint256 messageFee = msg.value - qty;
        IStargateRouter(stargateRouter).swap{value: messageFee}(
            dstChainId,                                     // the destination chain id
            ETH_POOL_ID,                                      // the source Stargate poolId
            ETH_POOL_ID,                                      // the destination Stargate poolId
            payable(msg.sender),                              // refund adddress. if msg.sender pays too much gas, return extra eth
            qty,                                            // total tokens to send to destination chain
            0,                                                // min amount allowed out
            IStargateRouter.lzTxObj(dstGasLimit, 0, "0x"),  // default lzTxObj
            abi.encodePacked(destStargateComposed),         // destination address, the sgReceive() implementer
            data                                              // bytes payload
        );
    }

    function pause() external {
        if(!hasRole(OPERATOR_ROLE, msg.sender)) revert Fiat24StargateSwap__NotOperator(_msgSender());
        _pause();
    }
}