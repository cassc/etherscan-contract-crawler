// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IClipperExchangeInterface.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IERC20.sol";
import "./libraries/PbPool.sol";
import "./Signers.sol";
import "./libraries/OrderLib.sol";
import "./VerifySigEIP712.sol";
import "./interfaces/IMultichainRouter.sol";

interface IMultichainERC20 {
    function Swapout(uint256 amount, address bindaddr) external returns (bool);
}

contract Vault is Ownable, Signers, VerifySigEIP712 {
    struct BridgeInfo {
        string bridge;
        address dstToken;
        uint64 chainId;
        uint256 amount;
        address user;
        uint64 nonce;
    }

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    struct BridgeDescription {
        address receiver;
        uint64 dstChainId;
        uint64 nonce;
        uint32 maxSlippage;
    }

    struct SwapData {
        IERC20 srcToken;
        IERC20 dstToken;
        uint256 amount;
        uint256 mintReturnAmount;
    }

    struct MultiChainDescription {
        address receiver;
        uint64 dstChainId;
        uint64 nonce;
        address router;
    }

    struct AnyMapping {
        address anyTokenAddress;
        address tokenAddress;
    }

    bytes4 private constant ROUTER_SWAP_CALL_SELECTOR = 0x12aa3caf;
    bytes4 private constant ROUTER_UNO_CALL_SELECTOR = 0xf78dc253;
    bytes4 private constant ROUTER_V3_CALL_SELECTOR = 0xbc80f1a8;
    bytes4 private constant ROUTER_RFQ_CALL_SELECTOR = 0x5a099843;
    bytes4 private constant ROUTER_CLIPPER_CALL_SELECTOR = 0x093d4fa5;
    bytes4 private constant ROUTER_ORDER_CALL_SELECTOR = 0xe5d7bde6;

    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public ROUTER;
    address public BRIDGE;
    address public MULTICHAIN;
    mapping(address => mapping(uint64 => BridgeInfo)) public userBridgeInfo;
    mapping(bytes32 => BridgeInfo) public transferInfo;
    mapping(bytes32 => bool) public transfers;
    mapping(address => address) public anyTokenAddress;
    mapping(address => bool) allowedRouter;

    event Swap(address user, address srcToken, address toToken, uint256 amount, uint256 returnAmount);
    event send(address user, uint64 chainId, address dstToken, uint256 amount, uint64 nonce, bytes32 transferId);
    event Relayswap(address receiver, address toToken, uint256 returnAmount);

    receive() external payable {}

    constructor(address router, address bridge) {
        ROUTER = router;
        BRIDGE = bridge;
    }

    function initMultichain(address[] calldata routers) external onlyOwner {
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

    function updateAddressMapping(AnyMapping[] calldata mappings) external onlyOwner {
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
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
            IERC20(_token).approve(BRIDGE, _amount);

            IBridge(BRIDGE).send(bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
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

        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId);
    }

    function multiChainBridge(
        address tokenAddress,
        uint256 _amount,
        MultiChainDescription calldata _mDesc
    ) public payable {
        MultiChainDescription memory mDesc = _mDesc;
        address anyToken = anyTokenAddress[tokenAddress];

        if (mDesc.router == anyToken) {
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
            IMultichainERC20(anyToken).Swapout(_amount, mDesc.receiver);
        } else {
            if (_isNative(IERC20(tokenAddress))) {
                IMultichainRouter(mDesc.router).anySwapOutNative{value: msg.value}(anyToken, mDesc.receiver, mDesc.dstChainId);
            } else {
                IERC20(tokenAddress).transferFrom(msg.sender, address(this), _amount);
                IERC20(tokenAddress).approve(mDesc.router, _amount);
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

        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId);
    }

    function swap(bytes calldata _data) external payable {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
            IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
            IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            (uint256 returnAmount, uint256 spentAmount) = abi.decode(_data, (uint256, uint256));
            require(returnAmount >= desc.minReturnAmount);
            if (desc.amount > spentAmount) {
                uint256 unspentAmount = desc.amount - spentAmount;
                if (!_isNative(IERC20(desc.srcToken))) {
                    IERC20(desc.srcToken).transfer(msg.sender, unspentAmount);
                } else {
                    _safeNativeTransfer(msg.sender, unspentAmount);
                }
            }
            emit Swap(msg.sender, address(desc.srcToken), address(desc.dstToken), desc.amount, returnAmount);
        } else {
            revert();
        }
    }

    function swapRouter(SwapData calldata _swap, bytes calldata _data) external payable {
        SwapData memory swapData = _swap;

        bool isNotNative = _isNativeSwap(swapData.srcToken, swapData.amount);

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            uint256 dstAmount;
            bytes4 selector = bytes4(_data);
            if (selector == ROUTER_SWAP_CALL_SELECTOR) {
                (uint256 returnAmount, uint256 spentAmount) = abi.decode(_data, (uint256, uint256));
                require(returnAmount >= swapData.mintReturnAmount);
                uint256 unspentAmount = swapData.amount - spentAmount;
                if (unspentAmount > 0) {
                    if (isNotNative) {
                        IERC20(swapData.srcToken).transfer(msg.sender, unspentAmount);
                    } else {
                        _safeNativeTransfer(msg.sender, unspentAmount);
                    }
                }
                dstAmount = returnAmount;
            } else if (selector == ROUTER_RFQ_CALL_SELECTOR || selector == ROUTER_ORDER_CALL_SELECTOR) {
                (uint256 sentAmount, uint256 returnAmount, ) = abi.decode(_data, (uint256, uint256, bytes32));
                require(returnAmount >= swapData.mintReturnAmount);
                dstAmount = returnAmount;
            } else {
                uint256 returnAmount = abi.decode(_data, (uint256));
                require(returnAmount >= swapData.mintReturnAmount);
                dstAmount = returnAmount;
            }
            emit Swap(msg.sender, address(swapData.srcToken), address(swapData.dstToken), swapData.amount, dstAmount);
            // (uint returnAmount, ) = abi.decode(_data, (uint256, uint256, bytes32));
        } else {
            revert();
        }
    }

    function swapCBridge(
        SwapData calldata _swap,
        bytes calldata _data,
        BridgeDescription calldata bDesc
    ) external payable {
        SwapData memory swapData = _swap;

        bool isNotNative = _isNativeSwap(swapData.srcToken, swapData.amount);

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            uint256 dstAmount;
            bytes4 selector = bytes4(_data);
            if (selector == ROUTER_SWAP_CALL_SELECTOR) {
                (uint256 returnAmount, uint256 spentAmount) = abi.decode(_data, (uint256, uint256));
                require(returnAmount >= swapData.mintReturnAmount);
                uint256 unspentAmount = swapData.amount - spentAmount;
                if (unspentAmount > 0) {
                    if (isNotNative) {
                        IERC20(swapData.srcToken).transfer(msg.sender, unspentAmount);
                    } else {
                        _safeNativeTransfer(msg.sender, unspentAmount);
                    }
                }
                dstAmount = returnAmount;
            } else if (selector == ROUTER_RFQ_CALL_SELECTOR || selector == ROUTER_ORDER_CALL_SELECTOR) {
                (uint256 sentAmount, uint256 returnAmount, ) = abi.decode(_data, (uint256, uint256, bytes32));
                require(returnAmount >= swapData.mintReturnAmount);
                dstAmount = returnAmount;
            } else {
                uint256 returnAmount = abi.decode(_data, (uint256));
                require(returnAmount >= swapData.mintReturnAmount);
                dstAmount = returnAmount;
            }
            uint256 fee = (dstAmount * 5) / 10000;
            dstAmount = dstAmount - fee;
            swapData.dstToken.transfer(owner(), fee);
            _cBridgeStart(swapData.dstToken, dstAmount, bDesc);
        } else {
            revert();
        }
    }

    function swapMultichain(
        SwapData calldata _swap,
        bytes calldata _data,
        MultiChainDescription calldata mDesc
    ) external payable {
        SwapData memory swapData = _swap;

        bool isNotNative = _isNativeSwap(swapData.srcToken, swapData.amount);

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            uint256 dstAmount;
            bytes4 selector = bytes4(_data);
            if (selector == ROUTER_SWAP_CALL_SELECTOR) {
                (uint256 returnAmount, uint256 spentAmount) = abi.decode(_data, (uint256, uint256));
                require(returnAmount >= swapData.mintReturnAmount);
                uint256 unspentAmount = swapData.amount - spentAmount;
                if (unspentAmount > 0) {
                    if (isNotNative) {
                        IERC20(swapData.srcToken).transfer(msg.sender, unspentAmount);
                    } else {
                        _safeNativeTransfer(msg.sender, unspentAmount);
                    }
                }
                dstAmount = returnAmount;
            } else if (selector == ROUTER_RFQ_CALL_SELECTOR || selector == ROUTER_ORDER_CALL_SELECTOR) {
                (uint256 sentAmount, uint256 returnAmount, ) = abi.decode(_data, (uint256, uint256, bytes32));
                require(returnAmount >= swapData.mintReturnAmount);
                dstAmount = returnAmount;
            } else {
                uint256 returnAmount = abi.decode(_data, (uint256));
                require(returnAmount >= swapData.mintReturnAmount);
                dstAmount = returnAmount;
            }
            uint256 fee = (dstAmount * 5) / 10000;
            dstAmount = dstAmount - fee;
            swapData.dstToken.transfer(owner(), fee);
            if (!allowedRouter[mDesc.router]) revert();
            _multiChainBridgeStart(address(swapData.dstToken), dstAmount, mDesc);
        } else {
            revert();
        }
    }

    function relaySwapRouter(
        bytes calldata _data, // =>
        Input calldata _sigCollect,
        bytes[] memory signature
    ) external onlyOwner {
        Input calldata sig = _sigCollect;
        relaySig(sig, signature);
        require(transfers[sig.txHash] == false, "transfer exists"); // 추가
        transfers[sig.txHash] = true; // 추가
        bool isNotNative = !_isNative(IERC20(sig.fromTokenAddress));
        uint256 tokenAmount = 0;
        uint256 fromAmount = sig.amount - sig.gasFee;
        if (isNotNative) {
            IERC20(sig.fromTokenAddress).approve(ROUTER, fromAmount); //desc.amount 는 amount - gasFee
            IERC20(sig.fromTokenAddress).transfer(owner(), sig.gasFee);
        } else {
            tokenAmount = fromAmount;
            _safeNativeTransfer(owner(), sig.gasFee);
        }
        bytes4 selector = bytes4(_data);
        (bool succ, bytes memory _data) = address(ROUTER).call{value: tokenAmount}(_data);
        if (succ) {
            if (selector == ROUTER_SWAP_CALL_SELECTOR) {
                (uint256 returnAmount, uint256 spentAmount) = abi.decode(_data, (uint256, uint256));
                require(returnAmount >= sig.minOut);
                uint256 unspentAmount = fromAmount - spentAmount;
                if (unspentAmount > 0) {
                    if (isNotNative) {
                        IERC20(sig.fromTokenAddress).transfer(sig.userAddress, unspentAmount);
                    } else {
                        _safeNativeTransfer(sig.userAddress, unspentAmount);
                    }
                }
                emit Relayswap(sig.userAddress, sig.toTokenAddress, returnAmount);
            } else if (selector == ROUTER_RFQ_CALL_SELECTOR || selector == ROUTER_ORDER_CALL_SELECTOR) {
                (uint256 sentAmount, uint256 returnAmount, ) = abi.decode(_data, (uint256, uint256, bytes32));
                require(returnAmount >= sig.minOut);
                emit Relayswap(sig.userAddress, sig.toTokenAddress, returnAmount);
            } else {
                uint256 returnAmount = abi.decode(_data, (uint256));
                require(returnAmount >= sig.minOut);
                emit Relayswap(sig.userAddress, sig.toTokenAddress, returnAmount);
            }
        } else {
            revert();
        }
    }

    // delete
    function EmergencyWithdraw(address _tokenAddress, uint256 amount) public onlyOwner {
        bool isNotNative = !_isNative(IERC20(_tokenAddress));
        if (isNotNative) {
            IERC20(_tokenAddress).transfer(owner(), amount);
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
        // require(wdmsg.receiver == address(this));
        BridgeInfo memory tif = transferInfo[wdmsg.refid];

        bool isNotNative = !_isNative(IERC20(tif.dstToken));
        if (isNotNative) {
            IERC20(tif.dstToken).transfer(tif.user, tif.amount);
        } else {
            _safeNativeTransfer(tif.user, tif.amount);
        }
    }

    function setRouterBridge(address _router, address _bridge) public onlyOwner {
        ROUTER = _router;
        BRIDGE = _bridge;
    }

    function setMultichain(address _multichain) public onlyOwner {
        MULTICHAIN = _multichain;
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == NATIVE_ADDRESS);
    }

    function _isNativeSwap(IERC20 _token, uint256 _amount) internal returns (bool isNotNative) {
        isNotNative = !_isNative(_token);

        if (isNotNative) {
            _token.transferFrom(msg.sender, address(this), _amount);
            _token.approve(ROUTER, _amount);
        }
    }

    function _cBridgeStart(
        IERC20 _token,
        uint256 _amount,
        BridgeDescription calldata bDesc
    ) internal {
        bool isNotNative = !_isNative(_token);
        if (isNotNative) {
            _token.approve(BRIDGE, _amount);
            IBridge(BRIDGE).send(bDesc.receiver, address(_token), _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            IBridge(BRIDGE).sendNative{value: _amount}(bDesc.receiver, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        }

        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), bDesc.receiver, address(_token), _amount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = address(_token);
        tif.chainId = bDesc.dstChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        tif.bridge = "cBridge";
        transferInfo[transferId] = tif;
        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId);
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
                IERC20(tokenAddress).approve(mDesc.router, _amount);
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

        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId);
    }

    function _safeNativeTransfer(address to_, uint256 amount_) private {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe transfer fail");
    }
}