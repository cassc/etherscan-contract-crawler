// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IBridgeAnyswap {
    function anySwapOutAndCall(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID,
        address anycallProxy,
        bytes calldata data
    ) external;
}

contract AnySwapBridgeSimpleWithMessage {
    using SafeERC20 for IERC20;

    address private v7router;

    constructor(address _v7router) {
        v7router = _v7router;
    }

    function transfer(
        uint64 _dstChainId,
        address _receiver,
        uint256 _amount,
        address _token,
        address _dstEoa
    ) external returns (bytes memory bridgeResp) {
        bytes32 transferId = keccak256(
            abi.encodePacked(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                block.timestamp, // as nonce
                uint64(block.chainid)
            )
        );

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeApprove(v7router, _amount);

        IBridgeAnyswap(v7router).anySwapOutAndCall(
            _token,
            _receiver,
            _amount,
            _dstChainId,
            _receiver,
            abi.encode(_dstEoa)
        );

        return abi.encodePacked(transferId);
    }

    function exec(
        address token,
        address receiver,
        uint256 amount,
        bytes calldata data
    )
        external
        returns (
            //onlyAuth Skipped for test
            bool success,
            bytes memory result
        )
    {
        address dstEoa = abi.decode(data, (address));

        IERC20(token).safeTransfer(dstEoa, amount);
    }
}