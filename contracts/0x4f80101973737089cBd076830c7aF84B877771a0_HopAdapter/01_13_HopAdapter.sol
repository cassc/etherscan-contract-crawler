// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IBridgeAdapter.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IHopBridge.sol";
import "../lib/NativeWrap.sol";

contract HopAdapter is IBridgeAdapter, NativeWrap {
    using SafeERC20 for IERC20;

    bool public immutable isL1;

    mapping(address => address) public bridges;

    event BridgeUpdated(address[] tokens, address[] bridges);

    constructor(
        address[] memory _tokens,
        address[] memory _bridges,
        bool _isL1,
        address _nativeWrap
    ) NativeWrap(_nativeWrap) {
        isL1 = _isL1;
        _setBridges(_tokens, _bridges);
    }

    struct BridgeParams {
        uint256 bonderFee;
        uint256 deadline;
        uint256 amountOutMin;
        uint256 dstDeadline;
        uint256 dstAmountOutMin;
    }

    function bridge(
        uint64 _dstChainId,
        address _receiver,
        uint256 _amount,
        address _token,
        bytes memory _bridgeParams,
        bytes memory //_requestMessage
    ) external payable returns (bytes memory bridgeResp) {
        BridgeParams memory p = abi.decode(_bridgeParams, (BridgeParams));
        address _bridge = bridges[_token];
        require(_bridge != address(0), "bridge not found");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        if (isL1) {
            uint256 value;
            if (_token == nativeWrap) {
                IWETH(_token).withdraw(_amount);
                value = _amount;
            } else {
                IERC20(_token).safeIncreaseAllowance(_bridge, _amount);
            }
            IHopBridge(_bridge).sendToL2{value: value}(
                _dstChainId,
                _receiver,
                _amount,
                p.amountOutMin,
                p.deadline,
                address(0),
                0
            );
        } else {
            uint256 value;
            if (_token == nativeWrap && IHopBridge(_bridge).l2CanonicalTokenIsEth()) {
                IWETH(_token).withdraw(_amount);
                value = _amount;
            } else {
                IERC20(_token).safeIncreaseAllowance(_bridge, _amount);
            }
            IHopBridge(_bridge).swapAndSend{value: value}(
                _dstChainId,
                _receiver,
                _amount,
                p.bonderFee,
                p.amountOutMin,
                p.deadline,
                p.dstAmountOutMin,
                p.dstDeadline
            );
        }
        return bridgeResp;
    }

    function setBridges(address[] calldata _tokens, address[] calldata _bridges) external onlyOwner {
        _setBridges(_tokens, _bridges);
    }

    function _setBridges(address[] memory _tokens, address[] memory _bridges) private {
        require(_tokens.length == _bridges.length, "len mismatch");
        for (uint8 i = 0; i < _tokens.length; i++) {
            bridges[_tokens[i]] = _bridges[i];
        }
        emit BridgeUpdated(_tokens, _bridges);
    }
}