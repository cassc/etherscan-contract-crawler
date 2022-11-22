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
        bytes permit;
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
            abi.encodePacked(msg.sender, bDesc.receiver, _token, _amount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
        );

        // BridgeInfo memory sif = userBridgeInfo[msg.sender][bDesc.nonce];
        BridgeInfo memory tif = transferInfo[transferId];
        // // // require(tif.nonce == 0," PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = _token;
        tif.chainId = bDesc.dstChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        transferInfo[transferId] = tif;
        // sif.dstToken = _token;
        // sif.chainId = bDesc.dstChainId;
        // sif.amount = _amount;
        // // sif.transferId = transferId;
        // userBridgeInfo[msg.sender][bDesc.nonce] = sif;

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
            if (isNotNative) {
            _safeNativeTransfer(msg.sender, returnAmount);
        }
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
            if (isNotNative) {
            _safeNativeTransfer(msg.sender, returnAmount);
        }
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

    function v3swap(uint minOut, address srcToken, bytes calldata _data) external payable {
        ( uint256 amount, uint256 b, uint256[] memory c) = abi.decode(_data[4:], ( uint256, uint256, uint256[]));

        bool isNotNative = !_isNative(IERC20(srcToken));
        if (isNotNative) {
            IERC20(srcToken).transferFrom(msg.sender, address(this), amount);
            IERC20(srcToken).approve(ROUTER, amount);   
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            (uint returnAmount) = abi.decode(_data, (uint));
            require(returnAmount >= minOut);
            if (isNotNative) {
            _safeNativeTransfer(msg.sender, returnAmount);
        }
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
            abi.encodePacked(msg.sender, bDesc.receiver, address(desc.dstToken), returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory sif = userBridgeInfo[msg.sender][bDesc.nonce];
            // require(sif.transferId == 0," PLEXUS: transferId already exists. Check the nonce.");
            sif.dstToken = address(desc.dstToken);
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            // sif.transferId = transferId;
            userBridgeInfo[msg.sender][bDesc.nonce] = sif;
            
            
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
            abi.encodePacked(msg.sender, bDesc.receiver, toToken, returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory sif = userBridgeInfo[msg.sender][bDesc.nonce];
            
            // require(sif.transferId == 0," PLEXUS: transferId already exists. Check the nonce.");
            sif.dstToken = toToken;
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            // sif.transferId = transferId;
            userBridgeInfo[msg.sender][bDesc.nonce] = sif;
            
            
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
            abi.encodePacked(msg.sender, bDesc.receiver, toToken, returnAmount, bDesc.dstChainId, bDesc.nonce, uint64(block.chainid))
            );

            BridgeInfo memory sif = userBridgeInfo[msg.sender][bDesc.nonce];
            // require(sif.transferId == 0," PLEXUS: transferId already exists. Check the nonce.");
            sif.dstToken = toToken;
            sif.chainId = bDesc.dstChainId;
            sif.amount = returnAmount;
            // sif.transferId = transferId;
            userBridgeInfo[msg.sender][bDesc.nonce] = sif;
            
            
        } 
        else {
            revert();
        }
    }

    function relaySwap(address vaultAddress, uint minOut, uint64 nonce, uint64 srcChainId, bytes calldata _data ) external payable {
        
        (address _c, SwapDescription memory desc, bytes memory _d) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        bytes32 srcTransferId = keccak256(
            abi.encodePacked(desc.dstReceiver, address(this), desc.srcToken, desc.amount, uint64(block.chainid), nonce, srcChainId)
            );

        bytes32 transferId = keccak256(
            abi.encodePacked(vaultAddress,address(this), desc.srcToken, desc.amount, srcChainId, uint64(block.chainid), srcTransferId)
        );

        bool isNotNative = !_isNative(IERC20(desc.srcToken));
        
        if(isNotNative) {
            IERC20(desc.srcToken).approve(ROUTER,desc.amount);
        }
        
        (bool succ, bytes memory _data) = address(ROUTER).call{value:msg.value}(_data);
        if (succ) {
            (uint returnAmount, ) = abi.decode(_data, (uint, uint));
            require(returnAmount >= minOut);
            isNotNative = !_isNative(IERC20(desc.dstToken));
            if (isNotNative) {
             IERC20(desc.dstToken).transfer(desc.dstReceiver,returnAmount);
        } else {
            _safeNativeTransfer(desc.dstReceiver, returnAmount);
        }

        
    }
    }


    // delete
    function withdraw(address _srcAddress, uint64 _nonce, bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        BridgeInfo memory sif = userBridgeInfo[_srcAddress][_nonce];
        IBridge(BRIDGE).withdraw(_wdmsg,_sigs,_signers,_powers);
        require(sif.amount > 0);
        // require(IERC20(sif.dstToken).balanceOf(address(this)) == sif.amount);
        
        bool isNotNative = !_isNative(IERC20(sif.dstToken));
        if(isNotNative) {
            IERC20(sif.dstToken).transfer(_srcAddress,sif.amount);
        } else {
            _safeNativeTransfer(_srcAddress, sif.amount);
        }
    }

    // F48A0D32941F08A9EBDA761A6480B14E15423136F9BDB0D8EB493631750C7795
    // 1A4DF9B0420C396A8E7EF0C982EEDF8DF3B85C7AE7746B730C043236FAC9AB7B

    function sigWithdraw(address _srcAddress, uint64 _nonce, bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
        BridgeInfo memory sif = userBridgeInfo[_srcAddress][_nonce];
        IBridge(BRIDGE).withdraw(_wdmsg,_sigs,_signers,_powers);
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, BRIDGE,"WithdrawMsg"));
        verifySigs(abi.encodePacked(domain, _wdmsg), _sigs, _signers, _powers);
        PbPool.WithdrawMsg memory wdmsg = PbPool.decWithdrawMsg(_wdmsg);
        // require(wdmsg.refid == sif.transferId);
        IERC20(sif.dstToken).transfer(_srcAddress,sif.amount);
        sif.amount = 0;
        sif.dstToken = address(0);
        userBridgeInfo[_srcAddress][_nonce] = sif;
    }

        function sigWithdraw(bytes calldata _wdmsg, bytes[] calldata _sigs, address[] calldata _signers, uint256[] calldata _powers) external onlyOwner {
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