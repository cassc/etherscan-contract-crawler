// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interface/IWETH.sol";
import "../interface/IStargateRouter.sol";
import "../interface/ILayerZeroEndpoint.sol";

contract PengHelperEth is Initializable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable {

    IERC20Upgradeable constant weth = IERC20Upgradeable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20Upgradeable constant usdc = IERC20Upgradeable(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IWETH constant sgEth = IWETH(0x72E2F4830b9E45d52F80aC08CB2bEC0FeF72eD9c);
    IStargateRouter constant stargateRouter = IStargateRouter(0x8731d54E9D02c286767d56ac03e8037C07e01e98);
    ILayerZeroEndpoint constant lzEndpoint = ILayerZeroEndpoint(0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675);
    address public pengHelperOp; // optimism

    event Deposit(address token, uint amount);
    event Withdraw(address token, uint amount);
    event SetPengHelperOp(address _pengHelperOp);

    function initialize(address _pengHelperOp) external initializer {
        __Ownable_init();

        pengHelperOp = _pengHelperOp;

        sgEth.approve(address(stargateRouter), type(uint).max);
        usdc.approve(address(stargateRouter), type(uint).max);
    }

    ///@param amountOutMin amount minimum lp token to receive after deposit on peng together optimism
    ///@dev msg.value = eth deposit + bridge gas fee if deposit eth
    ///@dev msg.value = bridge gas fee if deposit usdc
    ///@dev bridge gas fee can retrieve from stargateRouter.quoteLayerZeroFee()
    function deposit(IERC20Upgradeable token, uint amount, uint amountOutMin) external payable {
        require(token == weth || token == usdc, "weth or usdc only");
        address msgSender = msg.sender;
        uint msgValue = msg.value;
        uint poolId;
        
        if (token == weth) {
            require(amount >= 0.1 ether, "min 0.1 ether");
            require(msgValue > amount, "msg.value < amount");
            // deposit native eth into sgEth
            sgEth.deposit{value: amount}();
            // remaining msg.value for gas fee for stargate router swap
            msgValue -= amount;
            // poolId 13 = eth in stargate for both ethereum & optimism
            poolId = 13;

        } else { // token == usdc
            require(amount >= 100e6, "min $100");
            
            usdc.transferFrom(msgSender, address(this), amount);
            // poolId 1 = usdc in stargate for both ethereum & optimism
            poolId = 1;
        }

        // deliberately assign payload value to solve stack too deep error
        bytes memory payload = abi.encode(msgSender, address(token), amountOutMin);
        stargateRouter.swap{value: msgValue}(
            111, // _dstChainId, optimism
            poolId, // _srcPoolId
            poolId, // _dstPoolId
            payable(msgSender), // _refundAddress
            amount, // _amountLD
            amount * 995 / 1000, // _minAmountLD, 0.5% slippage
            IStargateRouter.lzTxObj(600000, 0, "0x"), // _lzTxParams, 600k = gas limit for sgReceive() in optimism
            abi.encodePacked(pengHelperOp), // _to
            payload // _payload
        );

        emit Deposit(address(token), amount);
    }

    ///@param amountOutMin amount minimum token to receive after withdraw from peng together on optimism side
    ///@param nativeForDst gas fee used by stargate router optimism to bridge token to msg.sender in ethereum
    ///@dev msg.value = bridged gas fee + nativeForDst, can retrieve from lzEndpoint.estimateFees()
    ///@dev nativeForDst can retrieve from stargateRouter.quoteLayerZeroFee()
    function withdraw(IERC20Upgradeable token, uint amount, uint amountOutMin, uint nativeForDst) external payable {
        require(token == weth || token == usdc, "weth or usdc only");
        require(amount > 0, "invalid amount");
        address msgSender = msg.sender;
        address _pengHelperOp = pengHelperOp;

        lzEndpoint.send{value: msg.value}(
            111, // _dstChainId, optimism
            abi.encodePacked(_pengHelperOp, address(this)), // _destination
            abi.encode(address(token), amount, amountOutMin, msgSender), // _payload
            payable(msgSender), // _refundAddress
            address(0), // _zroPaymentAddress
            abi.encodePacked( // _adapterParams
                uint16(2), // version 2, set gas limit + airdrop nativeForDst
                uint(600000), // gasAmount, gas limit for destination function call
                nativeForDst, // nativeForDst, refer @param above
                _pengHelperOp // addressOnDst
            )
        );

        emit Withdraw(address(token), amount);
    }

    receive() external payable {}

    function pauseContract() external onlyOwner {
        _pause();
    }

    function unPauseContract() external onlyOwner {
        _unpause();
    }

    function setPengHelperOp(address _pengHelperOp) external onlyOwner {
        pengHelperOp = _pengHelperOp;

        emit SetPengHelperOp(_pengHelperOp);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}