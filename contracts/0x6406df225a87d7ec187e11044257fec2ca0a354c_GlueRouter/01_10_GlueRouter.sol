// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";
import "./BridgeBase.sol";
import "./SwapBase.sol";

contract GlueRouter is Ownable, ReentrancyGuard, EIP712 {
    using ECDSA for bytes32;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    address public feeAddress;
    string public name;
    string public symbol;

    string private constant SIGNING_DOMAIN = "Glue";
    string private constant SIGNATURE_VERSION = "1";

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        name = "Glue Router";
        symbol = "GLUE";
    }


    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Glue: EXPIRED");
        _;
    }

    struct SwapBridgeDex {
        address dex;
        bool isEnabled;
    }

    SwapBridgeDex[] public swapDexs;
    SwapBridgeDex[] public bridgeDexs;

    receive() external payable {}

    event NewSwapDexAdded(address dex, bool isEnabled);
    event NewBridgeDexAdded(address dex, bool isEnabled);
    event SwapDexDisabled(uint256 dexID);
    event BridgeDexDisabled(uint256 dexID);
    event SetFeeAddress(address feeAddress);
    event WithdrawETH(uint256 amount);
    event Withdraw(address token, uint256 amount);
    
    struct SwapBridgeRequest {
        uint256 id;
        uint256 nativeAmount;
        address inputToken;
        bytes data;
    }

    // **** USER REQUEST ****
    struct UserSwapRequest {
        address receiverAddress;
        uint256 amount;
        SwapBridgeRequest swapRequest;
        uint256 deadline;
    }

    struct UserBridgeRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        SwapBridgeRequest bridgeRequest;
        uint256 deadline;
    }

    struct UserSwapBridgeRequest {
        address receiverAddress;
        uint256 toChainId;
        uint256 amount;
        SwapBridgeRequest swapRequest;
        SwapBridgeRequest bridgeRequest;
        uint256 deadline;
    }

    bytes32 private constant SWAP_REQUEST_TYPE =
        keccak256(
            "UserSwapRequest(address receiverAddress,uint256 amount,SwapBridgeRequest swapRequest,uint256 deadline)SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );
    bytes32 private constant BRIDGE_REQUEST_TYPE =
        keccak256(
            "UserBridgeRequest(address receiverAddress,uint256 toChainId,uint256 amount,SwapBridgeRequest bridgeRequest,uint256 deadline)SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );
    bytes32 private constant SWAP_AND_BRIDGE_REQUEST_TYPE =
        keccak256(
            "UserSwapBridgeRequest(address receiverAddress,uint256 toChainId,uint256 amount,SwapBridgeRequest swapRequest,SwapBridgeRequest bridgeRequest,uint256 deadline)SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );
    bytes32 private constant REQUEST_TYPE =
        keccak256(
            "SwapBridgeRequest(uint256 id,uint256 nativeAmount,address inputToken,bytes data)"
        );

    function _hashSwapRequest(UserSwapRequest memory _userRequest) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SWAP_REQUEST_TYPE,
                    _userRequest.receiverAddress,
                    _userRequest.amount,
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.swapRequest.id, _userRequest.swapRequest.nativeAmount, _userRequest.swapRequest.inputToken, keccak256(_userRequest.swapRequest.data))),
                    _userRequest.deadline
                )
            );
    }
    function _hashBridgeRequest(UserBridgeRequest memory _userRequest) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BRIDGE_REQUEST_TYPE,
                    _userRequest.receiverAddress,
                    _userRequest.toChainId,
                    _userRequest.amount,
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.bridgeRequest.id, _userRequest.bridgeRequest.nativeAmount, _userRequest.bridgeRequest.inputToken, keccak256(_userRequest.bridgeRequest.data))),
                    _userRequest.deadline
                )
            );
    }
    function _hashSwapAndBridgeRequest(UserSwapBridgeRequest memory _userRequest) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SWAP_AND_BRIDGE_REQUEST_TYPE,
                    _userRequest.receiverAddress,
                    _userRequest.toChainId,
                    _userRequest.amount,
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.swapRequest.id, _userRequest.swapRequest.nativeAmount, _userRequest.swapRequest.inputToken, keccak256(_userRequest.swapRequest.data))),
                    keccak256(abi.encode(REQUEST_TYPE, _userRequest.bridgeRequest.id, _userRequest.bridgeRequest.nativeAmount, _userRequest.bridgeRequest.inputToken, keccak256(_userRequest.bridgeRequest.data))),
                    _userRequest.deadline
                )
            );
    }

    // **** SWAP ****
    function swap(UserSwapRequest calldata _userRequest, bytes memory _sign)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            owner() == _hashTypedDataV4(_hashSwapRequest(_userRequest)).recover(_sign),
            Errors.CALL_DATA_MUST_SIGNED_BY_OWNER
        );
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);
        require(
            _userRequest.swapRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory swapInfo = swapDexs[_userRequest.swapRequest.id];

        require(
            swapInfo.dex != address(0) && swapInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );
        uint256 nativeSwapAmount = _userRequest.swapRequest.inputToken ==
            NATIVE_TOKEN_ADDRESS
            ? _userRequest.amount + _userRequest.swapRequest.nativeAmount
            : _userRequest.swapRequest.nativeAmount;
        require(
            msg.value == nativeSwapAmount,
            Errors.VALUE_NOT_EQUAL_TO_AMOUNT
        );

        // swap
        SwapBase(swapInfo.dex).swap{value: nativeSwapAmount}(
            msg.sender,
            _userRequest.swapRequest.inputToken,
            _userRequest.amount,
            _userRequest.receiverAddress,
            _userRequest.swapRequest.data,
            feeAddress
        );
    }

    // **** BRIDGE ****
    function bridge(UserBridgeRequest calldata _userRequest, bytes memory _sign)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            owner() == _hashTypedDataV4(_hashBridgeRequest(_userRequest)).recover(_sign),
            Errors.CALL_DATA_MUST_SIGNED_BY_OWNER
        );
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);
        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory bridgeInfo = bridgeDexs[
            _userRequest.bridgeRequest.id
        ];

        require(
            bridgeInfo.dex != address(0) && bridgeInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        // bridge
        BridgeBase(bridgeInfo.dex).bridge{value: msg.value}(
            msg.sender,
            _userRequest.bridgeRequest.inputToken,
            _userRequest.amount,
            _userRequest.receiverAddress,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data,
            feeAddress
        );
    }

    // **** SWAP AND BRIDGE ****
    function swapAndBridge(UserSwapBridgeRequest calldata _userRequest, bytes memory _sign)
        external
        payable
        ensure(_userRequest.deadline)
        nonReentrant
    {
        require(
            owner() == _hashTypedDataV4(_hashSwapAndBridgeRequest(_userRequest)).recover(_sign),
            Errors.CALL_DATA_MUST_SIGNED_BY_OWNER
        );
        require(
            _userRequest.receiverAddress != address(0),
            Errors.ADDRESS_0_PROVIDED
        );
        require(_userRequest.amount != 0, Errors.INVALID_AMT);

        require(
            _userRequest.swapRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        require(
            _userRequest.bridgeRequest.inputToken != address(0),
            Errors.ADDRESS_0_PROVIDED
        );

        SwapBridgeDex memory swapInfo = swapDexs[_userRequest.swapRequest.id];

        require(
            swapInfo.dex != address(0) && swapInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        SwapBridgeDex memory bridgeInfo = bridgeDexs[
            _userRequest.bridgeRequest.id
        ];
        require(
            bridgeInfo.dex != address(0) && bridgeInfo.isEnabled,
            Errors.DEX_NOT_ALLOWED
        );

        uint256 nativeSwapAmount = _userRequest.swapRequest.inputToken ==
            NATIVE_TOKEN_ADDRESS
            ? _userRequest.amount + _userRequest.swapRequest.nativeAmount
            : _userRequest.swapRequest.nativeAmount;
        uint256 _amountOut = SwapBase(swapInfo.dex).swap{
            value: nativeSwapAmount
        }(
            msg.sender,
            _userRequest.swapRequest.inputToken,
            _userRequest.amount,
            address(this),
            _userRequest.swapRequest.data,
            feeAddress
        );

        uint256 nativeInput = _userRequest.bridgeRequest.nativeAmount;

        if (_userRequest.bridgeRequest.inputToken != NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeApprove(
                _userRequest.bridgeRequest.inputToken,
                bridgeInfo.dex,
                _amountOut
            );
        } else {
            nativeInput = _amountOut + _userRequest.bridgeRequest.nativeAmount;
        }

        BridgeBase(bridgeInfo.dex).bridge{value: nativeInput}(
            address(this),
            _userRequest.bridgeRequest.inputToken,
            _amountOut,
            _userRequest.receiverAddress,
            _userRequest.toChainId,
            _userRequest.bridgeRequest.data,
            feeAddress
        );
    }

    // **** ONLY OWNER ****
    function addSwapDexs(SwapBridgeDex calldata _dex) external onlyOwner {
        require(_dex.dex != address(0), Errors.ADDRESS_0_PROVIDED);
        swapDexs.push(_dex);
        emit NewSwapDexAdded(_dex.dex, _dex.isEnabled);
    }

    function addBridgeDexs(SwapBridgeDex calldata _dex) external onlyOwner {
        require(_dex.dex != address(0), Errors.ADDRESS_0_PROVIDED);
        bridgeDexs.push(_dex);
        emit NewBridgeDexAdded(_dex.dex, _dex.isEnabled);
    }

    function disableSwapDex(uint256 _dexId) external onlyOwner {
        swapDexs[_dexId].isEnabled = false;
        emit SwapDexDisabled(_dexId);
    }

    function disableBridgeDex(uint256 _dexId) external onlyOwner {
        bridgeDexs[_dexId].isEnabled = false;
        emit BridgeDexDisabled(_dexId);
    }

    function setFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
        emit SetFeeAddress(_newFeeAddress);
    }

    function withdraw(
        address _token,
        address _receiverAddress,
        uint256 _amount
    ) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount)
        external
        onlyOwner
    {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }
}