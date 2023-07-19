// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IBridge.sol";
import "../interfaces/ICBridge.sol";
import "../Helpers/ReentrancyGuard.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/PbPool.sol";
import "../Helpers/Signers.sol";
import "../libraries/LibData.sol";
import "../libraries/LibPlexusUtil.sol";
import "../Helpers/VerifySigEIP712.sol";
import "hardhat/console.sol";

contract CBridgeFacet is IBridge, ReentrancyGuard, Signers, VerifySigEIP712 {
    using SafeERC20 for IERC20;

    ICBridge private immutable CBRIDGE;
    address private immutable WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(ICBridge cbridge) {
        CBRIDGE = cbridge;
    }

    /**
    @notice bridge via Cbridge logic
    @param _bridgeData Data to Bridge
    @param _cBridgeData Data specific to cBridge
    */
    function bridgeToCbridge(BridgeData memory _bridgeData, CBridgeData memory _cBridgeData) external payable nonReentrant {
        LibPlexusUtil._isTokenDeposit(_bridgeData.srcToken, _bridgeData.amount);
        _cBridgeStart(_bridgeData, _cBridgeData);
    }

    /**
    @notice swap And bridge via Cbridge logic
    @param _bridgeData Data to Bridge
    @param _swap Data specific to Swap
    @param _cBridgeData Data specific to cBridge
    */
    function swapAndBridgeToCbridge(
        SwapData calldata _swap,
        BridgeData memory _bridgeData,
        CBridgeData memory _cBridgeData
    ) external payable nonReentrant {
        _bridgeData.amount = LibPlexusUtil._tokenDepositAndSwap(_swap);
        _cBridgeStart(_bridgeData, _cBridgeData);
    }

    /** @notice Refunds due to errors during cBridge transfer */
    function sigWithdraw(bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external {
        LibData.BridgeDesc storage ds = LibData.bridgeStorage();
        CBRIDGE.withdraw(_wdmsg, _sigs, _signers, _powers);
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, CBRIDGE, "WithdrawMsg"));
        verifySigs(abi.encodePacked(domain, _wdmsg), _sigs, _signers, _powers);
        PbPool.WithdrawMsg memory wdmsg = PbPool.decWithdrawMsg(_wdmsg);
        BridgeInfo memory tif = ds.transferInfo[wdmsg.refid];

        bool isNotNative = !LibPlexusUtil._isNative(tif.dstToken);
        if (isNotNative) {
            IERC20(tif.dstToken).safeTransfer(tif.user, tif.amount);
        } else {
            LibPlexusUtil._safeNativeTransfer(tif.user, tif.amount);
        }
    }

    /**
    @notice Function to start cBridge
    @param _bridgeData Data to Bridge
    @param _cBridgeData Data specific to cBridge
    */
    function _cBridgeStart(BridgeData memory _bridgeData, CBridgeData memory _cBridgeData) internal {
        bool isNotNative = !LibPlexusUtil._isNative(_bridgeData.srcToken);
        if (isNotNative) {
            IERC20(_bridgeData.srcToken).safeApprove(address(CBRIDGE), _bridgeData.amount);
            CBRIDGE.send(
                _bridgeData.recipient,
                _bridgeData.srcToken,
                _bridgeData.amount,
                _bridgeData.dstChainId,
                _cBridgeData.nonce,
                _cBridgeData.maxSlippage
            );
        } else {
            CBRIDGE.sendNative{value: _bridgeData.amount}(
                _bridgeData.recipient,
                _bridgeData.amount,
                _bridgeData.dstChainId,
                _cBridgeData.nonce,
                _cBridgeData.maxSlippage
            );
            _bridgeData.srcToken = WETH;
        }

        bytes32 transferId = keccak256(
            abi.encodePacked(
                address(this),
                _bridgeData.recipient,
                _bridgeData.srcToken,
                _bridgeData.amount,
                _bridgeData.dstChainId,
                _cBridgeData.nonce,
                uint64(block.chainid)
            )
        );
        LibData.BridgeDesc storage ds = LibData.bridgeStorage();
        BridgeInfo memory tif = ds.transferInfo[transferId];
        tif.dstToken = _bridgeData.srcToken;
        tif.chainId = _bridgeData.dstChainId;
        tif.amount = _bridgeData.amount;
        tif.user = msg.sender;
        tif.bridge = "CBridge";
        ds.transferInfo[transferId] = tif;

        emit LibData.Bridge(msg.sender, _bridgeData.dstChainId, _bridgeData.srcToken, _bridgeData.amount, _bridgeData.plexusData);
    }

    function setUser(bytes32 transferId, address user) external {
        require(msg.sender == LibDiamond.contractOwner());
        LibData.BridgeDesc storage ds = LibData.bridgeStorage();
        BridgeInfo memory tif = ds.transferInfo[transferId];
        tif.user = user;
        ds.transferInfo[transferId] = tif;
    }

    function userBalance(address user, address token) external returns (uint256) {
        uint256 balance = LibPlexusUtil.userBalance(user, token);
        return balance;
    }
}