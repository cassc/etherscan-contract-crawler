// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICBridge.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/PbPool.sol";
import "./libraries/Signers.sol";
import "./libraries/OrderLib.sol";
import "./VerifySigEIP712.sol";
import "./interfaces/IMultichainRouter.sol";
import "./interfaces/Structs.sol";
import "./libraries/AssetLib.sol";
import "./interfaces/IPolyBridge.sol";

interface IMultichainERC20 {
    function Swapout(uint256 amount, address bindaddr) external returns (bool);
}

contract Vault is Ownable, Signers, VerifySigEIP712 {
    using SafeERC20 for IERC20;

    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    //ETH chain
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public ROUTER;
    address public CBRIDGE;
    address public POLYBRIDGE;
    address private dev;
    uint256 feePercent = 5;
    mapping(address => mapping(uint64 => BridgeInfo)) public userBridgeInfo;
    mapping(bytes32 => BridgeInfo) public transferInfo;
    mapping(bytes32 => bool) public transfers;
    mapping(address => address) public anyTokenAddress;
    mapping(address => bool) public allowedRouter;

    event Swap(address user, address srcToken, address toToken, uint256 amount, uint256 returnAmount);
    event Bridge(address user, uint64 chainId, address dstToken, uint256 amount, uint64 nonce, bytes32 transferId, string bridge);
    event Relayswap(address receiver, address toToken, uint256 returnAmount);

    receive() external payable {}

    constructor(address router, address cbridge, address poly) {
        ROUTER = router;
        CBRIDGE = cbridge;
        POLYBRIDGE = poly;
    }

    function initMultichain(address[] calldata routers) external {
        require(msg.sender == dev || msg.sender == owner());
        uint256 len = routers.length;
        for (uint256 i; i < len; ) {
            if (routers[i] == address(0)) {
                revert();
            }
            allowedRouter[routers[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function updateAddressMapping(AnyMapping[] calldata mappings) external {
        require(msg.sender == dev || msg.sender == owner());
        for (uint64 i; i < mappings.length; i++) {
            anyTokenAddress[mappings[i].tokenAddress] = mappings[i].anyTokenAddress;
        }
    }

    function cBridge(BridgeDescription calldata bdesc) external payable {
        BridgeDescription memory bDesc = bdesc;
        bool isNotNative = !_isNative(IERC20(bDesc.srcToken));
        bDesc.amount = _fee(bDesc.srcToken, bDesc.amount);
        if (isNotNative) {
            IERC20(bDesc.srcToken).safeTransferFrom(msg.sender, address(this), bDesc.amount);
            IERC20(bDesc.srcToken).safeApprove(CBRIDGE, bDesc.amount);

            ICBridge(CBRIDGE).send(bDesc.receiver, bDesc.srcToken, bDesc.amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            bDesc.srcToken = WETH;
            ICBridge(CBRIDGE).sendNative{value: bDesc.amount}(bDesc.receiver, bDesc.amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        }
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), bDesc.receiver, bDesc.srcToken, bDesc.amount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = bDesc.srcToken;
        tif.chainId = bDesc.dstChainId;
        tif.amount = bDesc.amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        tif.bridge = "cBridge";
        transferInfo[transferId] = tif;

        emit Bridge(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }

    function polyBridge(PolyBridgeDescription calldata _pDesc) public payable {
        PolyBridgeDescription memory pDesc = _pDesc;

        bool isNotNative = !_isNative(IERC20(pDesc.fromAsset));
        uint256 amount = _fee(pDesc.fromAsset, pDesc.amount);
        if (isNotNative) {
            IERC20(pDesc.fromAsset).safeTransferFrom(msg.sender, address(this), amount);
            IERC20(pDesc.fromAsset).safeApprove(POLYBRIDGE, amount);
        } else {
            pDesc.fromAsset = address(0);
        }

        IPolyBridge(POLYBRIDGE).lock{value: pDesc.fee}(pDesc.fromAsset, pDesc.toChainId, pDesc.toAddress, amount, pDesc.fee, pDesc.id);
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), pDesc.toAddress, pDesc.fromAsset, amount, pDesc.toChainId, pDesc.nonce, uint64(block.chainid))
        );
        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = pDesc.fromAsset;
        tif.chainId = pDesc.toChainId;
        tif.amount = amount;
        tif.user = msg.sender;
        tif.nonce = pDesc.nonce;
        tif.bridge = "polyBridge";
        transferInfo[transferId] = tif;

        emit Bridge(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }

    function multiChainBridge(MultiChainDescription calldata _mDesc) public payable {
        MultiChainDescription memory mDesc = _mDesc;
        address anyToken = anyTokenAddress[mDesc.srcToken];
        mDesc.amount = _fee(mDesc.srcToken, mDesc.amount);
        if (mDesc.router == anyToken) {
            IERC20(mDesc.srcToken).safeTransferFrom(msg.sender, address(this), mDesc.amount);
            IMultichainERC20(anyToken).Swapout(mDesc.amount, mDesc.receiver);
        } else {
            if (_isNative(IERC20(mDesc.srcToken))) {
                IMultichainRouter(mDesc.router).anySwapOutNative{value: mDesc.amount}(anyToken, mDesc.receiver, mDesc.dstChainId);
            } else {
                IERC20(mDesc.srcToken).safeTransferFrom(msg.sender, address(this), mDesc.amount);
                IERC20(mDesc.srcToken).safeApprove(mDesc.router, mDesc.amount);
                IMultichainRouter(mDesc.router).anySwapOutUnderlying(
                    anyToken != address(0) ? anyToken : mDesc.srcToken,
                    mDesc.receiver,
                    mDesc.amount,
                    mDesc.dstChainId
                );
            }
        }

        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), mDesc.receiver, mDesc.srcToken, mDesc.amount, mDesc.dstChainId, mDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = mDesc.srcToken;
        tif.chainId = mDesc.dstChainId;
        tif.amount = mDesc.amount;
        tif.user = msg.sender;
        tif.nonce = mDesc.nonce;
        tif.bridge = "MultiChainBridge";
        transferInfo[transferId] = tif;

        emit Bridge(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }

    function swapRouter(SwapData calldata _swap) external payable {
        _isNativeDeposit(IERC20(_swap.srcToken), _swap.amount);
        _swapStart(_swap);
    }

    function swapCBridge(SwapData calldata _swap, BridgeDescription calldata bDesc) external payable {
        SwapData calldata swapData = _swap;
        _isNativeDeposit(IERC20(swapData.srcToken), swapData.amount);
        uint256 dstAmount = _swapStart(swapData);
        dstAmount = _fee(swapData.dstToken, dstAmount);
        _cBridgeStart(_swap.dstToken, dstAmount, bDesc);
    }

    function swapPolyBridge(SwapData calldata _swap, PolyBridgeDescription calldata pdesc) external payable {
        SwapData calldata swapData = _swap;
        _isNativeDeposit(IERC20(swapData.srcToken), swapData.amount);
        uint256 dstAmount = _swapStart(swapData);
        dstAmount = _fee(swapData.dstToken, dstAmount);

        // PolyBridgeDescription memory pDesc = pdesc;
        // pDesc.amount = dstAmount;
        _polyBridgeStart(dstAmount, pdesc);
    }

    function swapMultichain(SwapData calldata _swap, MultiChainDescription calldata mDesc) external payable {
        SwapData calldata swapData = _swap;
        _isNativeDeposit(IERC20(swapData.srcToken), swapData.amount);
        uint256 dstAmount = _swapStart(swapData);
        dstAmount = _fee(swapData.dstToken, dstAmount);
        if (!allowedRouter[mDesc.router]) revert();
        _multiChainBridgeStart(_swap.dstToken, dstAmount, mDesc);
    }

    function _fee(address dstToken, uint256 dstAmount) private returns (uint256 returnAmount) {
        uint256 fee = (dstAmount * feePercent) / 10000;
        returnAmount = dstAmount - fee;
        if (fee > 0) {
            if (!_isNative(IERC20(dstToken))) {
                IERC20(dstToken).safeTransferFrom(dstToken, owner(), fee);
            } else {
                _safeNativeTransfer(owner(), fee);
            }
        }
    }

    function _swapStart(SwapData calldata swapData) private returns (uint256 dstAmount) {
        SwapData calldata swap = swapData;

        bool isNative = _isNative(IERC20(swap.srcToken));

        uint256 initDstTokenBalance = AssetLib.getBalance(swap.dstToken);

        (bool succ, bytes memory data) = address(ROUTER).call{value: isNative ? swap.amount : 0}(swap.callData);
        if (succ) {
            uint256 dstTokenBalance = AssetLib.getBalance(swap.dstToken);
            dstAmount = dstTokenBalance > initDstTokenBalance ? dstTokenBalance - initDstTokenBalance : dstTokenBalance;

            emit Swap(swap.user, swap.srcToken, swap.dstToken, swap.amount, dstAmount);
        } else {
            revert();
        }
    }

    function relaySwapRouter(
        SwapData calldata _swap, // =>
        Input calldata _sigCollect,
        bytes[] memory signature
    ) external onlyOwner {
        SwapData calldata swap = _swap;
        Input calldata sig = _sigCollect;
        require(sig.userAddress == swap.user && sig.amount - sig.gasFee == swap.amount && sig.toTokenAddress == swap.dstToken);
        relaySig(sig, signature);
        require(transfers[sig.txHash] == false, "safeTransfer exists"); // 추가
        transfers[sig.txHash] = true; // 추가
        bool isNotNative = !_isNative(IERC20(sig.fromTokenAddress));
        uint256 tokenAmount = 0;
        uint256 fromAmount = sig.amount - sig.gasFee;
        if (isNotNative) {
            IERC20(sig.fromTokenAddress).safeApprove(ROUTER, fromAmount); //desc.amount 는 amount - gasFee
            if (sig.gasFee > 0) IERC20(sig.fromTokenAddress).safeTransfer(owner(), sig.gasFee);
        } else {
            tokenAmount = fromAmount;
            if (sig.gasFee > 0) _safeNativeTransfer(owner(), sig.gasFee);
        }
        uint256 dstAmount = _swapStart(swap);
        emit Relayswap(sig.userAddress, sig.toTokenAddress, dstAmount);
    }

    // delete
    function EmergencyWithdraw(address _tokenAddress, uint256 amount) public onlyOwner {
        bool isNotNative = !_isNative(IERC20(_tokenAddress));
        if (isNotNative) {
            IERC20(_tokenAddress).safeTransfer(owner(), amount);
        } else {
            _safeNativeTransfer(owner(), amount);
        }
    }

    function sigWithdraw(bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external {
        ICBridge(CBRIDGE).withdraw(_wdmsg, _sigs, _signers, _powers);
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

    function setRouterBridge(address _router, address _bridge) public {
        require(msg.sender == dev || msg.sender == owner());
        ROUTER = _router;
        CBRIDGE = _bridge;
    }

    function setFeePercent(uint256 percent) external {
        require(msg.sender == dev || msg.sender == owner());
        feePercent = percent;
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == NATIVE_ADDRESS);
    }

    function _isNativeDeposit(IERC20 _token, uint256 _amount) internal returns (bool isNotNative) {
        isNotNative = !_isNative(_token);

        if (isNotNative) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            IERC20(_token).safeApprove(ROUTER, _amount);
        }
    }

    function _cBridgeStart(address _token, uint256 _amount, BridgeDescription calldata bDesc) internal {
        bool isNotNative = !_isNative(IERC20(_token));
        if (isNotNative) {
            IERC20(_token).safeApprove(CBRIDGE, _amount);
            ICBridge(CBRIDGE).send(bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            ICBridge(CBRIDGE).sendNative{value: _amount}(bDesc.receiver, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            _token = WETH;
        }

        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = _token;
        tif.chainId = bDesc.dstChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        tif.bridge = "cBridge";
        transferInfo[transferId] = tif;
        emit Bridge(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }

    function _polyBridgeStart(uint256 _amount, PolyBridgeDescription calldata pDesc) private {
        bool isNative = _isNative(IERC20(pDesc.fromAsset));
        if (!isNative) {
            IERC20(pDesc.fromAsset).safeApprove(POLYBRIDGE, _amount);
        }
        IPolyBridge(POLYBRIDGE).lock{value: pDesc.fee}(pDesc.fromAsset, pDesc.toChainId, pDesc.toAddress, _amount, pDesc.fee, pDesc.id);
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), pDesc.toAddress, pDesc.fromAsset, _amount, pDesc.toChainId, pDesc.nonce, uint64(block.chainid))
        );
        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = pDesc.fromAsset;
        tif.chainId = pDesc.toChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = pDesc.nonce;
        tif.bridge = "polyBridge";
        transferInfo[transferId] = tif;

        emit Bridge(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }

    function _multiChainBridgeStart(address tokenAddress, uint256 _amount, MultiChainDescription calldata _mDesc) internal {
        MultiChainDescription memory mDesc = _mDesc;
        address anyToken = anyTokenAddress[tokenAddress];

        if (mDesc.router == anyToken) {
            IMultichainERC20(anyToken).Swapout(_amount, mDesc.receiver);
        } else {
            if (_isNative(IERC20(tokenAddress))) {
                IMultichainRouter(mDesc.router).anySwapOutNative{value: _amount}(anyToken, mDesc.receiver, mDesc.dstChainId);
            } else {
                IERC20(tokenAddress).safeApprove(mDesc.router, _amount);
                IMultichainRouter(mDesc.router).anySwapOutUnderlying(
                    anyToken != address(0) ? anyToken : tokenAddress,
                    mDesc.receiver,
                    _amount,
                    mDesc.dstChainId
                );
            }
        }

        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), mDesc.receiver, tokenAddress, _amount, mDesc.dstChainId, mDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = tokenAddress;
        tif.chainId = mDesc.dstChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = mDesc.nonce;
        tif.bridge = "MultiChainBridge";
        transferInfo[transferId] = tif;

        emit Bridge(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }

    function _safeNativeTransfer(address to_, uint256 amount_) private {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe safeTransfer fail");
    }
}