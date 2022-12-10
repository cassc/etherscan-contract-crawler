// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/stargate.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";

/**
@title StargateEth Implementation.
@notice This is the implementation of stargate, this does not support native tokens.
Called by the registry if the selected bridge is Stargate Bridge.
@dev Follows the interface of ImplBase.
@author Socket.
*/

contract StargateIpml is ImplBase {
    using SafeERC20 for IERC20;
    IBridgeStargate public immutable router;
    IBridgeStargate public immutable routerETH;

    /**
    @notice Constructor sets the router address and registry address.
    @dev anyswap v3 address is constant. so no setter function required.
    */
    constructor(
        IBridgeStargate _router,
        IBridgeStargate _routerETH,
        address _registry
    ) ImplBase(_registry) {
        router = _router;
        routerETH = _routerETH;
    }

    struct StargateData {
        // a unique identifier that is uses to dedup transfers
        // this value is the a timestamp sent from frontend, but in theory can be any unique number
        uint256 srcPoolId;
        uint256 dstPoolId;
        uint256 minReceivedAmt; // defines the slippage, the min qty you would accept on the destination
        uint16 stargateDstChainId; // stargate defines chain id in its way
        address senderAddress;
        uint256 destinationGasLimit;
        bytes destinationPayload;
    }

    /**
    @notice function responsible for calling cross chain transfer using anyswap bridge.
    @dev the token to be passed on to anyswap function is supposed to be the wrapper token
    address.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. ah
    @param _data data contains the wrapper token address for the token
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256,
        bytes memory _data
    ) external payable override onlyRegistry {
        StargateData memory _stargateData = abi.decode(_data, (StargateData));
        if (_token == NATIVE_TOKEN_ADDRESS) {
            routerETH.swapETH{value: msg.value}(
                _stargateData.stargateDstChainId,
                payable(_stargateData.senderAddress),
                abi.encodePacked(_receiverAddress),
                _amount,
                _stargateData.minReceivedAmt
            );
            return;
        }
        
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(address(router), _amount);
        router.swap{value: msg.value}(
            _stargateData.stargateDstChainId,
            _stargateData.srcPoolId,
            _stargateData.dstPoolId,
            payable(_stargateData.senderAddress), // default to refund to main contract
            _amount,
            _stargateData.minReceivedAmt,
            IBridgeStargate.lzTxObj( _stargateData.destinationGasLimit, 0, "0x"),
            abi.encodePacked(_receiverAddress),
            _stargateData.destinationPayload
        );
    }
}