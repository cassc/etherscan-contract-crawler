// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IBridge} from "../interfaces/IBridge.sol";
import {ReentrancyGuard} from "../Helpers/ReentrancyGuard.sol";

import "../Helpers/PlexSwap.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/PbPool.sol";

contract CBridgeFacet is PlexSwap, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The contract address of the cbridge on the source chain.
    address public CBRIDGE;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setCBridge(address cbridge) external {
        CBRIDGE = cbridge;
    }

    function callThisAddr() external returns (address) {
        return address(this);
    }

    function cBridgeFunc(CBridgeDescription calldata bDesc) external payable nonReentrant {
        bool isNotNative = !_isNative(IERC20(bDesc.srcToken));
        if (isNotNative) {
            IERC20(bDesc.srcToken).safeTransferFrom(msg.sender, address(this), bDesc.amount);
        }
        _cBridgeStart(bDesc.amount, bDesc);
    }

    function swapCBridge(SwapData calldata _swap, CBridgeDescription calldata bDesc) external payable nonReentrant {
        SwapData calldata swapData = _swap;
        _isNativeDeposit(IERC20(swapData.srcToken), swapData.amount);
        uint256 dstAmount = _swapStart(swapData);
        _cBridgeStart(dstAmount, bDesc);
    }

    function sigWithdraw(bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external {
        IBridge(CBRIDGE).withdraw(_wdmsg, _sigs, _signers, _powers);
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, CBRIDGE, "WithdrawMsg"));
        verifySigs(abi.encodePacked(domain, _wdmsg), _sigs, _signers, _powers);
        PbPool.WithdrawMsg memory wdmsg = PbPool.decWithdrawMsg(_wdmsg);
        BridgeInfo memory tif = transferInfo[wdmsg.refid];

        bool isNotNative = !_isNative(IERC20(tif.dstToken));
        if (isNotNative) {
            IERC20(tif.dstToken).safeTransfer(tif.user, tif.amount);
        } else {
            _safeNativeTransfer(tif.user, tif.amount);
        }
    }

    function _cBridgeStart(uint256 amount, CBridgeDescription calldata bdesc) internal {
        CBridgeDescription memory bDesc = bdesc;
        amount = _fee(bDesc.srcToken, amount);
        bool isNotNative = !_isNative(IERC20(bDesc.srcToken));
        if (isNotNative) {
            IERC20(bDesc.srcToken).safeApprove(CBRIDGE, amount);
            IBridge(CBRIDGE).send(bDesc.receiver, bDesc.srcToken, amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            IBridge(CBRIDGE).sendNative{value: amount}(bDesc.receiver, amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            bDesc.srcToken = WETH;
        }

        //edit : address(this) => msg.sender
        bytes32 transferId = keccak256(
            abi.encodePacked((msg.sender), bDesc.receiver, bDesc.srcToken, amount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = bDesc.srcToken;
        tif.chainId = bDesc.dstChainId;
        tif.amount = amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        tif.bridge = "CBridge";
        transferInfo[transferId] = tif;
        emit Bridge(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }
}