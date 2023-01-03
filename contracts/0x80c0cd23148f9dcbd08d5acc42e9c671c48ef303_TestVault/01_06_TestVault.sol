// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/IMultichainRouter.sol";



interface IMultichainERC20 {
    function Swapout(uint256 amount, address bindaddr) external returns (bool);
}


contract TestVault is Ownable {
    struct BridgeInfo {
        string bridge;
        address dstToken;
        uint64 chainId;
        uint256 amount;
        address user;
        uint64 nonce;
    }
    struct BridgeDescription {
        address receiver;
        uint64 dstChainId;
        uint64 nonce;
        uint32 maxSlippage;
    }

    struct MultiChainDescription {
        address receiver;
        uint64 dstChainId;
        uint64 nonce;
        address router;
    }

    struct SwapData {
        IERC20 srcToken;
        IERC20 dstToken;
        uint256 amount;
        uint256 minReturnAmount;
    }

    struct AnyMapping {
        address tokenAddress;
        address anyTokenAddress;
    }

    bytes4 private constant SWAP_CALL_SELECTOR = 0x12aa3caf;
    bytes4 private constant RFQ_CALL_SELECTOR = 0x3eca9c0a;
    bytes4 private constant RFQ_TO_CALL_SELECTOR = 0x5a099843;
    bytes4 private constant CLIPPER_CALL_SELECTOR = 0x84bd6d29;
    bytes4 private constant CLIPPER_TO_CALL_SELECTOR = 0x093d4fa5;
    bytes4 private constant ORDER_CALL_SELECTOR = 0x62e238bb;
    bytes4 private constant ORDER_TO_CALL_SELECTOR = 0xe5d7bde6;

    IERC20 private constant NATIVE_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    address public BRIDGE = 0x5427FEFA711Eff984124bFBB1AB6fbf5E3DA1820;

    
    mapping(address => mapping(uint64 => BridgeInfo)) public userBridgeInfo;
    mapping(bytes32 => BridgeInfo) public transferInfo;
    mapping(bytes32 => bool) public transfers;
    mapping(address => address) public anyTokenAddress;

    event Swap(address user, address srcToken, address toToken, uint256 amount, uint256 returnAmount);
    event Send(address user, uint64 chainId, address dstToken, uint256 amount, uint64 nonce, bytes32 transferId, string bridge);
    event Relayswap(address receiver, address toToken, uint256 returnAmount);

    receive() external payable {}

    function viewNative(IERC20 _address) external pure returns (bool isNotNative) {
        isNotNative = !_isNative(_address);
    }

    function viewFunction(bytes calldata _data) external pure returns (bytes4 selector) {
        selector = bytes4(_data);
    }

    function _isNative(IERC20 token_) internal pure returns (bool) {
        return (token_ == NATIVE_ADDRESS);
    }
  
    function _safeNativeTransfer(address to_, uint256 amount_) private {
        (bool sent, ) = to_.call{value: amount_}("");
        require(sent, "Safe transfer fail");
    }

    function updateAddressMapping(AnyMapping[] calldata mappings) external onlyOwner {
        for (uint64 i; i < mappings.length; i++) {
            anyTokenAddress[mappings[i].tokenAddress] = mappings[i].anyTokenAddress;
        }
    }
    //동작
    function cBridgeNative(address _token, uint256 _amount, BridgeDescription calldata bDesc) external payable {
        IBridge(BRIDGE).sendNative{value: msg.value}(bDesc.receiver, msg.value, bDesc.dstChainId, bDesc.nonce, bDesc.maxSlippage);
    
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

        emit Send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    
    }

    function swapCBridge(SwapData calldata _swap, bytes calldata _data, BridgeDescription calldata bDesc) external payable {
        SwapData calldata swapData = _swap;

        bool isNotNative = !_isNative(swapData.srcToken);

        if (isNotNative) {
            swapData.srcToken.transferFrom(msg.sender, address(this), swapData.amount);
            swapData.srcToken.approve(ROUTER, swapData.amount);
        }

        (bool succ, bytes memory _data) = address(ROUTER).call{value: msg.value}(_data);
        if (succ) {
            uint256 dstAmount;
            bytes4 selector = bytes4(_data);
            if (selector == SWAP_CALL_SELECTOR) {
                (uint256 returnAmount, uint256 spentAmount) = abi.decode(_data, (uint256, uint256));
                require(returnAmount >= swapData.minReturnAmount);
                uint256 unspentAmount = swapData.amount - spentAmount;
                if (unspentAmount > 0) {
                    if (isNotNative) {
                        IERC20(swapData.srcToken).transfer(msg.sender, unspentAmount);
                    } else {
                        _safeNativeTransfer(msg.sender, unspentAmount);
                    }
                }
                dstAmount = returnAmount;
            } else if (selector == RFQ_CALL_SELECTOR || selector == ORDER_CALL_SELECTOR) {
                (uint256 sentAmount, uint256 returnAmount, ) = abi.decode(_data, (uint256, uint256, bytes32));
                // require(returnAmount >= swapData.minReturnAmount);
                dstAmount = returnAmount;
            } else {
                uint256 returnAmount = abi.decode(_data, (uint256));
                // require(returnAmount >= swapData.minReturnAmount);
                dstAmount = returnAmount;
            }
            uint256 fee = (dstAmount * 5) / 10000;
            dstAmount = dstAmount - fee;
            if (!_isNative(swapData.dstToken)) {
                swapData.dstToken.transfer(owner(), fee);
            } else {
                _safeNativeTransfer(owner(), fee);
            }
            _cBridgeStart(swapData.dstToken, dstAmount, bDesc);
        } else {
            revert();
        }
    }

    function _cBridgeStart(IERC20 _token, uint256 _amount, BridgeDescription calldata bDesc) internal {
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
        // require(tif.nonce == 0, " PLEXUS: transferId already exists. Check the nonce.");
        tif.dstToken = address(_token);
        tif.chainId = bDesc.dstChainId;
        tif.amount = _amount;
        tif.user = msg.sender;
        tif.nonce = bDesc.nonce;
        tif.bridge = "cBridge";
        transferInfo[transferId] = tif;
        emit Send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }

    function multiChainBridge(address tokenAddress, uint256 _amount, MultiChainDescription calldata _mDesc) public payable {
        MultiChainDescription calldata mDesc = _mDesc;
        address anyToken = anyTokenAddress[tokenAddress];

  
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

        emit Send(tif.user, tif.chainId, tif.dstToken, tif.amount, tif.nonce, transferId, tif.bridge);
    }



    function EmergencyWithdraw(address _tokenAddress, uint256 amount) public  {
        bool isNotNative = !_isNative(IERC20(_tokenAddress));
        if (isNotNative) {
            IERC20(_tokenAddress).transfer(owner(), amount);
        } else {
            _safeNativeTransfer(owner(), amount);
        }
    }


}