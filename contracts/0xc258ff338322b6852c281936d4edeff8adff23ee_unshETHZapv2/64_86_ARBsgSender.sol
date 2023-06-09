// SPDX-License-Identifier: No License
pragma solidity ^0.8.0;

import "layerzerolabs/contracts/token/oft/OFT.sol";
import "layerzerolabs/contracts/interfaces/IStargateRouter.sol";
import "communal/Owned.sol";
import "communal/TransferHelper.sol";

interface ISGETH is IERC20{
    function deposit() payable external;
}

contract ARBUnshethMinter is Owned {

    address public immutable stargateRouterAddress;          // address of the stargate router
    address public immutable sgethAddress;             // address of the sgeth token - 0x82cbecf39bee528b5476fe6d1550af59a9db6fc0
    uint16 public immutable dstChainId;                      // Stargate/LayerZero chainId
    uint16 public immutable srcPoolId;                       // stargate poolId - *must* be the poolId for the qty asset
    uint16 public immutable dstPoolId;                       // stargate destination poolId
    address public sgReceiverAddress;                         // destination contract. it must implement sgReceive()
    bool paused = false;

    constructor(
        address _owner, //address of the user deploying this contract
        address _stargateRouterAddress, //address of the stargate router on Arbitrum - 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614 as per https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
        address _sgReceiver, //address of the sgReceiver deployed on ETH
        uint16 _dstChainId, //101 - as per https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet'
        uint16 _srcPoolId, // 13 - as per https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet
        uint16 _dstPoolId, // 13 - as per https://stargateprotocol.gitbook.io/stargate/developers/contract-addresses/mainnet,
        address _sgethAddress // 0x82cbecf39bee528b5476fe6d1550af59a9db6fc0
    ) Owned(_owner){
        stargateRouterAddress = _stargateRouterAddress;
        sgReceiverAddress = _sgReceiver;
        dstChainId = _dstChainId;
        srcPoolId = _srcPoolId;
        dstPoolId = _dstPoolId;
        sgethAddress = _sgethAddress;

        TransferHelper.safeApprove(sgethAddress, stargateRouterAddress, type(uint256).max);
    }

    modifier onlyWhenUnpaused {
        require(paused == false, "Contract is paused");
        _;
    }

    // owner function that sets the pause parameter
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function changeSgReceiver(address _sgReceiver) public onlyOwner {
        require(_sgReceiver!= address(0), "sgReceiver cannot be zero address");
        sgReceiverAddress = _sgReceiver;
    }

    // mint_unsheth function that sends ETH to the sgReceiver on Mainnet contract to mint unshETH tokens
    function mint_unsheth(
        uint256 amount,                         // the amount of ETH
        uint256 min_amount_stargate,            // the minimum amount of ETH to receive on stargate,
        uint256 min_amount_unshethZap,          // the minimum amount of unshETH to receive from the unshETH Zap
        uint256 dstGasForCall,                  // the amount of gas to send to the sgReceive contract
        uint256 dstNativeAmount,                // leftover eth that will get airdropped to the sgReceive contract
        uint256 unsheth_path                    // the path that the unsheth Zap will take to mint unshETH
    ) external payable onlyWhenUnpaused {
        // ensure the msg.value is greather than the amount of ETH being sent
        require(msg.value > amount, "Not enough ETH provided as msg.value");

        // deposit the ETH into the sgeth contract
        ISGETH(sgethAddress).deposit{value:amount}();

        //calculate the fee that will be used to pay for the swap 
        uint256 feeAmount = msg.value - amount;

        bytes memory data = abi.encode(msg.sender, min_amount_unshethZap, unsheth_path);

        // Encode payload data to send to destination contract, which it will handle with sgReceive()
        IStargateRouter(stargateRouterAddress).swap{value:feeAmount}( //call estimateGasFees to get the msg.value
            dstChainId,                                               // the destination chain id - ETH
            srcPoolId,                                                // the source Stargate poolId
            dstPoolId,                                                // the destination Stargate poolId
            payable(msg.sender),                                      // refund address. if msg.sender pays too much gas, return extra ETH to this address
            amount,                                                   // total tokens to send to destination chain
            min_amount_stargate,                                      // min amount allowed out
            IStargateRouter.lzTxObj(dstGasForCall, dstNativeAmount, abi.encodePacked(sgReceiverAddress)), // default lzTxObj
            abi.encodePacked(sgReceiverAddress),                   // destination address, the sgReceive() implementer
            data                                                      // bytes payload which sgReceive() will parse into an address that the unshETH will be sent too.
        );
    }
}