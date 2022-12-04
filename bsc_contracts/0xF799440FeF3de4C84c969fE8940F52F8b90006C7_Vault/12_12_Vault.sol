// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IERC20.sol";
import "./libraries/PbPool.sol";
import "./Signers.sol";



contract Vault is Ownable, Signers {


    struct BridgeInfo {
        address dstToken;
        uint64 chainId;
        uint256 amount;
        // bytes32 transferId;
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

    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);    

    address public  ROUTER;
    address public  BRIDGE;
    
    mapping(address => mapping(uint64 => BridgeInfo)) public userBridgeInfo;
    mapping(bytes32 => BridgeInfo) public transferInfo;

    event Swap(address user, address srcToken, address toToken, uint256 amount, uint256 returnAmount);
    event send(address user, uint64 chainId, address dstToken , uint256 amount, uint64 nonce, bytes32 transferId );
    event Relayswap(address receiver, address toToken, uint256 returnAmount);

    receive() external payable {

    }
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
        bytes32 transferId = keccak256(
            abi.encodePacked(address(this), bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
        );

        BridgeInfo memory tif = transferInfo[transferId];
        require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = _token;
        tif.chainId = bDesc.dstChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        transferInfo[transferId] = tif;
        
        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );

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
            emit Swap(msg.sender, address(desc.srcToken), address(desc.dstToken), desc.amount, returnAmount);
        } else {
            revert();
        }

        
    }

    // function unoswap(uint minOut, address toToken, bytes calldata _data) external payable {
    //     (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));

    //     bool isNotNative = !_isNative(srcToken);

    //     if (isNotNative) {
    //         srcToken.transferFrom(msg.sender, address(this), amount);
    //         srcToken.approve(ROUTER, amount);
    //     }
        
    //     (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
    //     if (succ) {
    //         (uint returnAmount) = abi.decode(_data, (uint));
    //         require(returnAmount >= minOut);
    //         emit Swap(msg.sender, address(srcToken), toToken, amount, returnAmount);
            
    //     } else {
    //         revert();
    //     }
        
    // }

    function unoswapTo(uint minOut, address toToken, bytes calldata _data) external payable {
        (address user, IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c) = abi.decode(_data[4:], (address, IERC20, uint256, uint256, bytes32[]));

        bool isNotNative = !_isNative(srcToken);

        if (isNotNative) {
            srcToken.transferFrom(msg.sender, address(this), amount);
            srcToken.approve(ROUTER, amount);
        }
        
        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            emit Swap(msg.sender, address(srcToken), toToken, amount, returnAmount);
            
        } else {
            revert();
        }
        
    }

    // delete
    function viewV3swap(bytes calldata _data) external view returns (uint256 amount, uint256 b, uint256[] memory c) {
        (  amount, b, c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));
    }
    // delete   
    function viewUnoswap(bytes calldata _data) external view returns (IERC20 srcToken, uint256 amount, uint256 b, bytes32[] memory c ) {
        ( srcToken, amount, b, c) = abi.decode(_data[4:], (IERC20, uint256, uint256, bytes32[]));
    }
    // delete
    function viewSwap(bytes calldata _data) external view returns (address c, SwapDescription memory desc, bytes memory d) {
        (c, desc, d) = abi.decode(_data[4:], (address, SwapDescription, bytes));
    }

    // function v3swap(uint minOut, address srcToken, address toToken, bytes calldata _data) external payable {
    //     ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

    //     bool isNotNative = !_isNative(IERC20(srcToken));
    //     if (isNotNative) {
    //         IERC20(srcToken).transferFrom(msg.sender, address(this), amount);
    //         IERC20(srcToken).approve(ROUTER, amount);   
    //     }

    //     (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
    //     if (succ) {
    //         (uint returnAmount) = abi.decode(_data, (uint));
    //         require(returnAmount >= minOut);
    //         emit Swap(msg.sender, srcToken, toToken, amount, returnAmount);
            
    //     } else {
    //         revert();
    //     }
        
    // }

    function v3swapTo(uint minOut, address srcToken, address toToken, bytes calldata _data) external payable {
        ( address user, uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( address, uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(IERC20(srcToken));
        if (isNotNative) {
            IERC20(srcToken).transferFrom(msg.sender, address(this), amount);
            IERC20(srcToken).approve(ROUTER, amount);   
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            emit Swap(msg.sender, srcToken, toToken, amount, returnAmount);
            
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
            bytes32 transferId = keccak256(
            abi.encodePacked(address(this), bDesc.receiver, address(desc.dstToken), returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory tif = transferInfo[transferId];
            require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce.");
            tif.dstToken = address(desc.dstToken);
            tif.chainId = bDesc.dstChainId;
            tif.amount = returnAmount;
            tif.user = msg.sender;
            tif.nonce = bDesc.nonce;
            transferInfo[transferId] = tif;

        // emit Swap(msg.sender, address(desc.srcToken), address(desc.dstToken), desc.amount, returnAmount);
        emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );
            
            
        } 
        else {
            revert();
        }
    }

    function unoBridge(uint minOut,address toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
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
            isNotNative = !_isNative(IERC20(toToken));
            if (isNotNative) {
            IERC20(toToken).approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, toToken , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            bytes32 transferId = keccak256(
            abi.encodePacked(address(this), bDesc.receiver, toToken, returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory tif = transferInfo[transferId];
            require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce."); 
            tif.dstToken = toToken;
            tif.chainId = bDesc.dstChainId;
            tif.amount = returnAmount;
            tif.user = msg.sender;
            tif.nonce = bDesc.nonce;
            transferInfo[transferId] = tif;
            // emit Swap(msg.sender, address(srcToken), toToken, amount, returnAmount);
            emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );            
        } 
        else {
            revert();
        }
    }

    function v3Bridge(uint minOut,address fromToken, address toToken, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(IERC20(fromToken));

        if (isNotNative) {
        IERC20(fromToken).transferFrom(msg.sender, address(this), amount);
        IERC20(fromToken).approve(ROUTER, amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            uint returnAmount = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(IERC20(toToken));
            if (isNotNative) {
            IERC20(toToken).approve(BRIDGE, returnAmount);
            IBridge(BRIDGE).send(bDesc.receiver, toToken , returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            } else {
            IBridge(BRIDGE).sendNative{value:returnAmount}(bDesc.receiver, returnAmount, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
            }

            bytes32 transferId = keccak256(
            abi.encodePacked(address(this), bDesc.receiver, toToken, returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory tif = transferInfo[transferId];
            require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce.");
            tif.dstToken = toToken;
            tif.chainId = bDesc.dstChainId;
            tif.amount = returnAmount;
            tif.user = msg.sender;
            tif.nonce = bDesc.nonce;
            transferInfo[transferId] = tif;
            
            // emit Swap(msg.sender, fromToken, toToken, amount, returnAmount);
            emit send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId );
            
        } 
        else {
            revert();
        }
    }

    function relaySwap(uint minOut, bytes calldata _data ) external payable onlyOwner {
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bool isNotNative = !_isNative(IERC20(desc.srcToken));

        if (isNotNative) {
        IERC20(desc.srcToken).approve(ROUTER, desc.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value : msg.value}(_data);
        if (succ) {
            (uint returnAmount, uint gasLeft) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
            emit Relayswap(desc.dstReceiver,  address(desc.dstToken), returnAmount);
        } else {
            revert();
        }
    }

    // delete
    function EmergencyWithdraw(address _tokenAddress, uint256 amount) public onlyOwner {
        bool isNotNative = !_isNative(IERC20(_tokenAddress));
        if(isNotNative) {
            IERC20(_tokenAddress).transfer(owner(),amount);
        } else {
            _safeNativeTransfer(owner(), amount);
        }
    }

        function sigWithdraw(bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external {
        IBridge(BRIDGE).withdraw(_wdmsg,_sigs,_signers,_powers);
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, BRIDGE,"WithdrawMsg"));
        verifySigs(abi.encodePacked(domain, _wdmsg), _sigs, _signers, _powers);
        PbPool.WithdrawMsg memory wdmsg = PbPool.decWithdrawMsg(_wdmsg);
        // require(wdmsg.receiver == address(this));
        BridgeInfo memory tif = transferInfo[wdmsg.refid];
        
        bool isNotNative = !_isNative(IERC20(tif.dstToken));
        if(isNotNative) {
            IERC20(tif.dstToken).transfer(tif.user,tif.amount);
        } else {
            _safeNativeTransfer(tif.user, tif.amount);
        }
    }

    function setRouterBridge(address _router, address _bridge) public onlyOwner {
        ROUTER = _router;
        BRIDGE = _bridge;
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == NATIVE_ADDRESS);
    }

    function _safeNativeTransfer(address to_, uint256 amount_) private {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe transfer fail");
    }     

    }