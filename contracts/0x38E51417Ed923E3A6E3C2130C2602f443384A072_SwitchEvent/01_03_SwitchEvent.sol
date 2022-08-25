// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/DataTypes.sol";

contract SwitchEvent {

    event Swapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    );

    event ParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    );

    event CrosschainSwapRequest(
        bytes32 indexed id,
        bytes32 bridgeTransferId,
        bytes32 indexed bridge, // bridge slug
        address indexed from, // user address
        address fromToken, // source token on sending chain
        address bridgeToken, // bridge token on sending chain
        address destToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 bridgeAmount, // swapped amount on sending chain
        uint256 dstAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    );

    event CrosschainSwapDone(
        bytes32 indexed id,
        bytes32 indexed bridge,
        address indexed from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    );

    function emitSwapped(
        address from,
        address recipient,
        IERC20 fromToken,
        IERC20 destToken,
        uint256 fromAmount,
        uint256 destAmount,
        uint256 reward
    )
        public
    {
        emit Swapped(from, recipient, fromToken, destToken, fromAmount, destAmount, reward);
    }

    function emitParaswapSwapped(
        address from,
        IERC20 fromToken,
        uint256 fromAmount
    )
    public
    {
        emit ParaswapSwapped(from, fromToken, fromAmount);
    }

    function emitCrosschainSwapRequest(
        bytes32 id,
        bytes32 bridgeTransferId,
        bytes32 bridge, // bridge slug
        address from, // user address
        address fromToken, // source token on sending chain
        address bridgeToken, // bridge token on sending chain
        address destToken, // dest token on receiving chain
        uint256 fromAmount, // source token amount on sending chain
        uint256 bridgeAmount, // swapped amount on sending chain
        uint256 dstAmount, // estimated amount of dest token on receiving chain
        DataTypes.SwapStatus status
    ) public {
        emit CrosschainSwapRequest(id, bridgeTransferId, bridge, from, fromToken, bridgeToken, destToken, fromAmount, bridgeAmount, dstAmount, status);
    }

    function emitCrosschainSwapDone(
        bytes32 id,
        bytes32 bridge,
        address from, // user address
        address bridgeToken, // source token on receiving chain
        address destToken, // dest token on receiving chain
        uint256 bridgeAmount, // bridge token amount on receiving chain
        uint256 destAmount, //dest token amount on receiving chain
        DataTypes.SwapStatus status
    ) public {
        emit CrosschainSwapDone(id, bridge, from, bridgeToken, destToken, bridgeAmount, destAmount, status);
    }


}