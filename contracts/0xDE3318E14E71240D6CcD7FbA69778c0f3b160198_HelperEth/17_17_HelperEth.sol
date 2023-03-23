// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {PausableUpgradeable} from "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {IWETH} from "../interface/IWETH.sol";
import {IStargateRouter} from "../interface/IStargateRouter.sol";
import {ILayerZeroEndpoint} from "../interface/ILayerZeroEndpoint.sol";

/// @title deposit/withdraw token between ethereum and optimism powerbomb nft
/// @author siew
contract HelperEth is Initializable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for IWETH;

    IERC20Upgradeable private constant WETH = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable private constant USDC = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IWETH private constant SG_ETH = IWETH(0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c);
    IStargateRouter private constant STARGATE_ROUTER = IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98);
    ILayerZeroEndpoint private constant LZ_ENDPOINT = ILayerZeroEndpoint(0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675);

    event Deposit(address token, uint amount, address pbNft);
    event Withdraw(address token, uint amount, address pbNft);

    function initialize() external initializer {
        __Ownable_init();

        SG_ETH.safeApprove(address(STARGATE_ROUTER), type(uint).max);
        USDC.safeApprove(address(STARGATE_ROUTER), type(uint).max);
    }

    /// @param gasLimit gas limit for calling sgReceive() on optimism
    /// @param pbNft powerbomb nft contract address on optimism
    /// @dev msg.value = eth deposit + bridge gas fee if deposit eth
    /// @dev msg.value = bridge gas fee if deposit usdc
    /// @dev bridge gas fee can retrieve from stargateRouter.quoteLayerZeroFee()
    function deposit(
        IERC20Upgradeable token,
        uint amount,
        uint gasLimit,
        address pbNft,
        bytes memory params
    ) external payable whenNotPaused {
        require(token == WETH || token == USDC, "weth or usdc only");
        uint msgValue = msg.value;
        uint poolId;
        
        if (token == WETH) {
            require(amount >= 0.1 ether, "min 0.1 ether");
            require(msgValue > amount, "msg.value < amount");
            // deposit native eth into sgEth
            SG_ETH.deposit{value: amount}();
            // remaining msg.value for gas fee for stargate router swap
            msgValue -= amount;
            // poolId 13 = eth in stargate for both ethereum & optimism
            poolId = 13;

        } else { // token == usdc
            require(amount >= 100e6, "min $100");
            
            USDC.safeTransferFrom(msg.sender, address(this), amount);
            // poolId 1 = usdc in stargate for both ethereum & optimism
            poolId = 1;
        }

        // deliberately assign minAmount, lzTxParams and payload to solve stack too deep error
        uint minAmount = amount * 995 / 1000;
        IStargateRouter.LzTxObj memory lzTxParams = IStargateRouter.LzTxObj(gasLimit, 0, "0x");
        bytes memory payload = abi.encode(msg.sender, params);
        _swap(msgValue, poolId, amount, minAmount, lzTxParams, pbNft, payload);

        emit Deposit(address(token), amount, pbNft);
    }

    function _swap(
        uint msgValue,
        uint poolId,
        uint amount,
        uint minAmount,
        IStargateRouter.LzTxObj memory lzTxParams,
        address pbNft,
        bytes memory payload
    ) private {
        STARGATE_ROUTER.swap{value: msgValue}(
            111, // _dstChainId, optimism
            poolId, // _srcPoolId
            poolId, // _dstPoolId
            payable(msg.sender), // _refundAddress
            amount, // _amountLD
            minAmount, // _minAmountLD, 0.5% slippage
            lzTxParams, // _lzTxParams
            abi.encodePacked(pbNft), // _to
            payload // _payload
        );
    }

    /// @param gasLimit gas limit for calling lzReceive() on optimism
    /// @param nativeForDst gas fee used by stargate router optimism to bridge token to msg.sender in ethereum
    /// @dev msg.value = bridged gas fee + nativeForDst, can retrieve from lzEndpoint.estimateFees()
    /// @dev nativeForDst can retrieve from stargateRouter.quoteLayerZeroFee()
    /// @param pbNft powerbomb nft contract address on optimism
    function withdraw(
        IERC20Upgradeable token,
        uint amount,
        uint gasLimit, 
        uint nativeForDst,
        address pbNft,
        bytes memory params
    ) external payable {
        require(token == WETH || token == USDC, "weth or usdc only");
        require(amount > 0, "invalid amount");
        address msgSender = msg.sender;

        // solhint-disable-next-line check-send-result
        LZ_ENDPOINT.send{value: msg.value}(
            111, // _dstChainId, optimism
            abi.encodePacked(pbNft, address(this)), // _destination
            abi.encode(amount, msgSender, params), // _payload
            payable(msgSender), // _refundAddress
            address(0), // _zroPaymentAddress
            abi.encodePacked( // _adapterParams
                uint16(2), // version 2, set gas limit + airdrop nativeForDst
                gasLimit, // gasAmount
                nativeForDst, // nativeForDst, refer @param above
                pbNft // addressOnDst
            )
        );

        emit Withdraw(address(token), amount, pbNft);
    }

    /// @notice to receive eth send from user
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @notice pause deposit, only callable by owner
    function pauseContract() external onlyOwner {
        _pause();
    }

    /// @notice unpause deposit, only callable by owner
    function unPauseContract() external onlyOwner {
        _unpause();
    }

    /// @dev for uups upgradeable
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address) internal override onlyOwner {}
}