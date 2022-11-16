// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IERC20.sol";
import "./libraries/PbPool.sol";



contract Vault is Ownable {


    struct SwapInfo {
                address dstToken;
                uint64 chainId;
                uint256 amount;
    }

    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address srcReceiver;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    struct BridgeDescription {
        address receiver;
        uint64 dstChainId; 
        uint64 nonce; 
        uint32 maxSlippage;
    }

    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);    

    address private immutable ROUTER;
    address private immutable BRIDGE;
    
    mapping(address => mapping(uint64 => SwapInfo)) public userSwapInfo;

    // returns (uint64 chainid, address token, uint256 amount)
    event with(uint64 id, address token, uint256 amount, uint64 wdmsgId, address wdmsgToken, uint256 wdmsgAmount);

    constructor(address router, address bridge) {
        ROUTER = router;
        BRIDGE = bridge;
    }

    function bridge( address _token, uint256 _amount, BridgeDescription calldata bDesc) external payable {
        bool isNotNative = !_isNative(IERC20(_token));

        if (isNotNative) {
            IERC20(_token).transferFrom(
                msg.sender,
                address(this),
                _amount
            );
            IERC20(_token).approve(BRIDGE, _amount);

            IBridge(BRIDGE).send(bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        } else {
            IBridge(BRIDGE).sendNative{value:msg.value}(bDesc.receiver, _amount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
        }

        SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
        sif.dstToken = _token;
        sif.chainId = bDesc.dstChainId;
        sif.amount = _amount;
        userSwapInfo[msg.sender][bDesc.nonce] = sif;

    }

    function swap(uint minOut, bytes calldata _data) external payable {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount, uint gasLeft) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
        } else {
            revert();
        }
    }

    function uno(uint minOut, bytes calldata _data) external payable {
        (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));

        bool isNotNative = !_isNative(srcToken);

        if (isNotNative) {
            srcToken.transferFrom(msg.sender, address(this), amount);
            srcToken.approve(ROUTER, amount);
        }
        

        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
        } else {
            revert();
        }
    }

    function v3swap(uint minOut, IERC20 srcToken, bytes calldata _data) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(srcToken);
        if (isNotNative) {
            srcToken.transferFrom(msg.sender, address(this), amount);
            srcToken.approve(ROUTER, amount);   
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
        } else {
            revert();
        }
    }

    function swapBridge(uint minOut, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
        IERC20(desc.srcToken).transferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            (uint returnAmount, ) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(IERC20(desc.dstToken));
            if (isNotNative) {
            IERC20(desc.dstToken).approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, address(desc.dstToken) , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
            require(sif.dstToken != address(0));
            sif.dstToken = address(desc.dstToken);
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            userSwapInfo[msg.sender][bDesc.nonce] = sif;
            
            
        } 
        else {
            revert();
        }
    }

    function unoBridge(uint minOut,IERC20 toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));

        bool isNotNative = !_isNative(srcToken);

        if (isNotNative) {
        srcToken.transferFrom(msg.sender, address(this), amount);
        srcToken.approve(ROUTER, amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            uint returnAmount = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(toToken);
            if (isNotNative) {
            toToken.approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, address(toToken) , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
            sif.dstToken = address(toToken);
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            userSwapInfo[msg.sender][bDesc.nonce] = sif;
            
            
        } 
        else {
            revert();
        }
    }

    function v3Bridge(uint minOut,IERC20 fromToken, IERC20 toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(fromToken);

        if (isNotNative) {
        fromToken.transferFrom(msg.sender, address(this), amount);
        fromToken.approve(ROUTER, amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            uint returnAmount = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(toToken);
            if (isNotNative) {
            toToken.approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, address(toToken) , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            SwapInfo memory sif = userSwapInfo[msg.sender][bDesc.nonce];
            sif.dstToken = address(toToken);
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            userSwapInfo[msg.sender][bDesc.nonce] = sif;
            
            
        } 
        else {
            revert();
        }
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == ETH_ADDRESS);
    }

    function _safeNativeTransfer(address to_, uint256 amount_) private {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe transfer fail");
    }     

    function withdraw(address _srcAddress, uint64 _nonce, bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        SwapInfo memory sif = userSwapInfo[_srcAddress][_nonce];
        IBridge(BRIDGE).withdraw(_wdmsg,_sigs,_signers,_powers);
        IERC20(sif.dstToken).transfer(_srcAddress,sif.amount);
    }

    }