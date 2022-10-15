// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@opengsn/contracts/src/forwarder/IForwarder.sol";
import "@opengsn/contracts/src/BasePaymaster.sol";
import "@opengsn/contracts/src/utils/GsnTypes.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 


/**
 * A Token-based paymaster.
 * - each request is paid for by the caller.
 * - acceptRelayedCall - verify the caller can pay for the request in tokens.
 * - preRelayedCall - pre-pay the maximum possible price for the tx
 * - postRelayedCall - refund the caller for the unused gas
 */
contract TokenPaymaster is BasePaymaster {

    function versionPaymaster() external override virtual view returns (string memory){
        return "2.2.0+opengsn.token.ipaymaster";
    }

    
    // uint256 public gasCharge = 700000;
    uint256 public gasUsedByPost = 80000; //gas used on _postRelayedcall
    uint256 public minGas = 400000;
    uint256 public minBalance = 0.8 ether;
    uint256 private _fee;
    address public target;
    address private _paymentToken;

    bool private _pause;

    IUniswapV2Router02 private immutable _router;
    mapping(address => bool) private _isTokenWhitelisted;

    constructor(
        address uniswapRouter, 
        address forwarder, 
        address paymentToken,
        uint256 fee,
        IRelayHub hub
    ) {
        _router = IUniswapV2Router02(uniswapRouter);
        _paymentToken = paymentToken;
        _fee = fee;
        setTrustedForwarder(forwarder);
        setRelayHub(hub);
    }

    function setMinBalance(uint256 _minBalance) external onlyOwner {
        require(_minBalance > 0, "Wrong min balance");
        minBalance = _minBalance;
    }

    function setPaymentToken(address paymentToken) external onlyOwner {
        require(paymentToken != address(0), "Wrong Payment Token");
        _paymentToken = paymentToken;
    }

    function setFee(uint256 fee) external onlyOwner {
        _fee = fee;
    }

    function whitelistToken(address token, bool whitelist) external onlyOwner {
        require(token != address(0), "Token address is 0");
        _isTokenWhitelisted[token] = whitelist;
    }

    function isTokenWhitelisted(address token) external view returns(bool) {
        return _isTokenWhitelisted[token];
    }

    function setGasUsedByPost(uint256 _gasUsedByPost) external onlyOwner {
        gasUsedByPost = _gasUsedByPost;
    }

    function setMinGas(uint256 _minGas) external onlyOwner {
        minGas = _minGas;
    }

    function setTarget(address _target) external onlyOwner {
        target = _target;
    }

    function togglePause() external onlyOwner {
        _pause = !_pause;
    }

    function getTokenToEthOutput(uint256 amountIn, address[] memory path) public view returns (uint256) {
        uint256 amountOut = _router.getAmountsOut(amountIn, path)[1];
        return amountOut;
    }

    function _getPath(address token1, address token2) private pure returns(address[] memory path) {
        path = new address[](2);
        path[0] = token1;
        path[1] = token2;
    }

    function getPaymentData() external view returns(address, uint256) {
        return (_paymentToken, _fee);
    }

     function preRelayedCall(
        GsnTypes.RelayRequest calldata relayRequest,
        bytes calldata /*signature*/,
        bytes calldata /*approvalData*/,
        uint256 maxPossibleGas
    )
    external
    override
    virtual
    returns (bytes memory context, bool revertOnRecipientRevert) {
        _verifyForwarder(relayRequest);
        require(!_pause, "Swap paused");
        IForwarder.ForwardRequest calldata request = relayRequest.request;
        GsnTypes.RelayData memory relayData = relayRequest.relayData;

        require(request.to == target, "Unknown target");

        (address tokenAddress, uint256 amount) = abi.decode(request.data[4:], (address, uint256));
        require(_isTokenWhitelisted[tokenAddress], "Token not whitelisted");

        address payer = request.from;

        IERC20 paymentToken = IERC20(_paymentToken);

        if(_paymentToken == tokenAddress) {
            require(paymentToken.allowance(payer, target) >= _fee + amount, "Fee+amount: Not enough allowance");
            require(paymentToken.balanceOf(payer) >= _fee + amount, "Fee+amount: Not enough balance");
        } else {
            require(paymentToken.allowance(payer, target) >= _fee, "Fee: Not enough allowance");
            require(paymentToken.balanceOf(payer) >= _fee, "Fee: Not enough balance");

            IERC20 token = IERC20(tokenAddress);
            require(token.allowance(payer, target) >= amount, "Not enough allowance");
            require(paymentToken.balanceOf(payer) >= amount, "Not enough balance");
        }

        address[] memory path = _getPath(tokenAddress, _router.WETH());
        uint256 amountOut = getTokenToEthOutput(amount, path);

        uint256 ethPrecharge = relayHub.calculateCharge(maxPossibleGas, relayData);
    
        require(amountOut > ethPrecharge, "Not enough to pay for tx");

        require(request.gas >= minGas, "Not enough gas");
        return (abi.encode(request.from, ethPrecharge, amountOut), true);
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        uint256 gasUseWithoutPost,
        GsnTypes.RelayData calldata relayData
    )
    external
    override
    virtual
    relayHubOnly {
        
        require(success, "No success");
        (address payer, uint256 ethPrecharge, uint256 amountOut) = abi.decode(context, (address, uint256, uint256));
        IRelayHub _relayHub = relayHub;
        uint256 ethActualCharge = _relayHub.calculateCharge(gasUseWithoutPost + gasUsedByPost, relayData);
        uint256 hubBalance = relayHub.balanceOf(address(this));

        uint256 totalCharge = ethActualCharge;
        uint256 refund = amountOut - totalCharge;
        if(hubBalance - refund < minBalance) {
            totalCharge = ethPrecharge;
            refund = amountOut - totalCharge;
        }
        _relayHub.withdraw(refund, payable(payer));
    }

}