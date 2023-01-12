// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBridge.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/PbPool.sol";
import "./libraries/Signers.sol";
import "./libraries/OrderLib.sol";
import "./VerifySigEIP712.sol";
import "./interfaces/IMultichainRouter.sol";
import "./interfaces/Structs.sol";
import "./libraries/AssetLib.sol";

interface IMultichainERC20 {
    function Swapout(uint256 amount, address bindaddr) external returns (bool);
}

contract Vault is Ownable, Signers, VerifySigEIP712 {
    using SafeERC20 for IERC20;

    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    //ETH chain
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public ROUTER;
    address public BRIDGE;
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

    constructor(address router, address bridge) {
        ROUTER = router;
        BRIDGE = bridge;
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

    function cBridge(
        address _token,
        uint256 _amount,
        BridgeDescription calldata bDesc
    ) external payable {
        bool isNotNative = !_isNative(IERC20(_token));

        if (isNotNative) {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
            IERC20(_token).safeApprove(BRIDGE, _amount);

            IBridge(BRIDGE).send(bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            _token = WETH;
            IBridge(BRIDGE).sendNative{value: msg.value}(bDesc.receiver, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
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

    function multiChainBridge(
        address tokenAddress,
        uint256 _amount,
        MultiChainDescription calldata _mDesc
    ) public payable {
        MultiChainDescription calldata mDesc = _mDesc;
        address anyToken = anyTokenAddress[tokenAddress];

        if (mDesc.router == anyToken) {
            IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
            IMultichainERC20(anyToken).Swapout(_amount, mDesc.receiver);
        } else {
            if (_isNative(IERC20(tokenAddress))) {
                IMultichainRouter(mDesc.router).anySwapOutNative{value: msg.value}(anyToken, mDesc.receiver, mDesc.dstChainId);
            } else {
                IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
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

    function swapRouter(SwapData calldata _swap) external payable {
        _swapStart(_swap);
    }

    function swapCBridge(SwapData calldata _swap, BridgeDescription calldata bDesc) external payable {
        SwapData calldata swapData = _swap;
        _isNativeDeposit(IERC20(swapData.srcToken), swapData.amount);
        uint256 dstAmount = _swapStart(swapData);
        _cBridgeStart(_swap.dstToken, dstAmount, bDesc);
    }

    function swapMultichain(SwapData calldata _swap, MultiChainDescription calldata mDesc) external payable {
        SwapData calldata swapData = _swap;
        _isNativeDeposit(IERC20(swapData.srcToken), swapData.amount);
        uint256 dstAmount = _swapStart(swapData);
        if (!allowedRouter[mDesc.router]) revert();
        _multiChainBridgeStart(_swap.dstToken, dstAmount, mDesc);
    }

    function _swapStart(SwapData calldata swapData) private returns (uint256 dstAmount) {
        SwapData calldata swap = swapData;
        uint256 initDstTokenBalance = AssetLib.getBalance(IERC20(swap.dstToken));
        (bool succ, bytes memory data) = address(ROUTER).call{value: swap.amount}(swap.callData);
        if (succ) {
            uint256 dstTokenBalance = AssetLib.getBalance(IERC20(swap.dstToken));
            dstAmount = dstTokenBalance > initDstTokenBalance ? dstTokenBalance - initDstTokenBalance : dstTokenBalance;

            if (swap.fee) {
                uint256 fee = (dstAmount * feePercent) / 10000;
                require(fee > 0);
                dstAmount = dstAmount - fee;
                if (!_isNative(IERC20(swap.dstToken))) {
                    IERC20(swap.dstToken).safeTransfer(owner(), fee);
                } else {
                    _safeNativeTransfer(owner(), fee);
                }
            }

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

    function sigWithdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        IBridge(BRIDGE).withdraw(_wdmsg, _sigs, _signers, _powers);
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, BRIDGE, "WithdrawMsg"));
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
        BRIDGE = _bridge;
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

    function _cBridgeStart(
        address _token,
        uint256 _amount,
        BridgeDescription calldata bDesc
    ) internal {
        bool isNotNative = !_isNative(IERC20(_token));
        if (isNotNative) {
            IERC20(_token).safeApprove(BRIDGE, _amount);
            IBridge(BRIDGE).send(bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            IBridge(BRIDGE).sendNative{value: _amount}(bDesc.receiver, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
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

    function _multiChainBridgeStart(
        address tokenAddress,
        uint256 _amount,
        MultiChainDescription calldata _mDesc
    ) internal {
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