/**
 *Submitted for verification at Etherscan.io on 2023-10-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transferFrom(address from, address to, uint256 amount) external;
}

library LibBytes {
    function addressToBytes32(address addr) external pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function bytes32ToAddress(bytes32 _buf) public pure returns (address) {
        return address(uint160(uint256(_buf)));
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(_length, 31)

                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

library CCTPMessage {
    using LibBytes for *;
    uint8 public constant MESSAGE_BODY_INDEX = 116;

    function body(bytes memory message) public pure returns (bytes memory) {
        return
            message.slice(
                MESSAGE_BODY_INDEX,
                message.length - MESSAGE_BODY_INDEX
            );
    }

    /*function testGetCCTPMessageBody() public pure {
        bytes
            memory message = hex"0000000000000003000000000000000000000071000000000000000000000000aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000233333";
        bytes memory messageBody = body(message);
        require(keccak256(messageBody) == keccak256(hex"233333"));
    }*/
}

struct SwapMessage {
    uint32 version;
    bytes32 bridgeNonceHash;
    uint256 sellAmount;
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
    bytes32 recipient;
}

struct Fee {
    uint256 bridgeFee;
    uint256 swapFee;
}

library SwapMessageCodec {
    using LibBytes for *;

    uint8 public constant VERSION_END_INDEX = 4;
    uint8 public constant BRIDGENONCEHASH_END_INDEX = 36;
    uint8 public constant SELLAMOUNT_END_INDEX = 68;
    uint8 public constant BUYTOKEN_END_INDEX = 100;
    uint8 public constant BUYAMOUNT_END_INDEX = 132;
    uint8 public constant RECIPIENT_END_INDEX = 164;

    function encode(
        SwapMessage memory swapMessage
    ) public pure returns (bytes memory) {
        return
            abi.encodePacked(
                swapMessage.version,
                swapMessage.bridgeNonceHash,
                swapMessage.sellAmount,
                swapMessage.buyToken,
                swapMessage.guaranteedBuyAmount,
                swapMessage.recipient
            );
    }

    function decode(
        bytes memory message
    ) public pure returns (SwapMessage memory) {
        uint32 version;
        bytes32 bridgeNonceHash;
        uint256 sellAmount;
        bytes32 buyToken;
        uint256 guaranteedBuyAmount;
        bytes32 recipient;
        assembly {
            version := mload(add(message, VERSION_END_INDEX))
            bridgeNonceHash := mload(add(message, BRIDGENONCEHASH_END_INDEX))
            sellAmount := mload(add(message, SELLAMOUNT_END_INDEX))
            buyToken := mload(add(message, BUYTOKEN_END_INDEX))
            guaranteedBuyAmount := mload(add(message, BUYAMOUNT_END_INDEX))
            recipient := mload(add(message, RECIPIENT_END_INDEX))
        }
        return
            SwapMessage(
                version,
                bridgeNonceHash,
                sellAmount,
                buyToken,
                guaranteedBuyAmount,
                recipient
            );
    }
}

interface ITokenMessenger {
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 destinationCaller
    ) external returns (uint64 _nonce);
}

interface IMessageTransmitter {
    function sendMessageWithCaller(
        uint32 destinationDomain,
        bytes32 recipient,
        bytes32 destinationCaller,
        bytes calldata messageBody
    ) external returns (uint64);

    function receiveMessage(
        bytes calldata message,
        bytes calldata attestation
    ) external returns (bool success);

    function replaceMessage(
        bytes calldata originalMessage,
        bytes calldata originalAttestation,
        bytes calldata newMessageBody,
        bytes32 newDestinationCaller
    ) external;

    function usedNonces(bytes32) external view returns (uint256);

    function localDomain() external view returns (uint32);
}

abstract contract AdminControl {
    address public admin;
    address public pendingAdmin;

    event ChangeAdmin(address indexed _old, address indexed _new);
    event ApplyAdmin(address indexed _old, address indexed _new);

    function initAdmin(address _admin) internal {
        require(_admin != address(0), "AdminControl: address(0)");
        admin = _admin;
        emit ChangeAdmin(address(0), _admin);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "AdminControl: not admin");
        _;
    }

    function changeAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "AdminControl: address(0)");
        pendingAdmin = _admin;
        emit ChangeAdmin(admin, _admin);
    }

    function applyAdmin() external {
        require(msg.sender == pendingAdmin, "AdminControl: Forbidden");
        emit ApplyAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
}

struct MessageWithAttestation {
    bytes message;
    bytes attestation;
}

struct SellArgs {
    address sellToken;
    uint256 sellAmount;
    uint256 guaranteedBuyAmount;
    uint256 sellcallgas;
    bytes sellcalldata;
}

struct BuyArgs {
    bytes32 buyToken;
    uint256 guaranteedBuyAmount;
}

interface IValueRouter {
    event TakeFee(address to, uint256 amount);

    event SwapAndBridge(
        address sellToken,
        address buyToken,
        uint256 bridgeUSDCAmount,
        uint32 destDomain,
        address recipient,
        uint64 bridgeNonce,
        uint64 swapMessageNonce,
        bytes32 bridgeHash
    );

    event ReplaceSwapMessage(
        address buyToken,
        uint32 destDomain,
        address recipient,
        uint64 swapMessageNonce
    );

    event LocalSwap(
        address msgsender,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 boughtAmount
    );

    event BridgeArrive(bytes32 bridgeNonceHash, uint256 amount);

    event DestSwapFailed(bytes32 bridgeNonceHash);

    event DestSwapSuccess(bytes32 bridgeNonceHash);

    function version() external view returns (uint16);

    function fee(uint32 domain) external view returns (uint256, uint256);

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) external payable;

    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) external payable returns (uint64, uint64);

    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) external;
}

contract ValueRouterImpl is AdminControl, IValueRouter {
    using LibBytes for *;
    using SwapMessageCodec for *;
    using CCTPMessage for *;

    mapping(uint32 => Fee) public fee;

    function setFee(
        uint32[] calldata domain,
        Fee[] calldata price
    ) public onlyAdmin {
        for (uint i = 0; i < domain.length; i++) {
            fee[domain[i]] = price[i];
        }
    }

    bool initialized;
    address public usdc;
    IMessageTransmitter public messageTransmitter;
    ITokenMessenger public tokenMessenger;
    address public zeroEx;
    uint16 public version;

    mapping(uint32 => bytes32) public remoteRouter;
    mapping(bytes32 => address) swapHashSender;

    function initialize(
        address _usdc,
        address _messageTransmtter,
        address _tokenMessenger,
        address _zeroEx,
        address _admin
    ) public {
        require(initialized == false);
        initAdmin(_admin);
        usdc = _usdc;
        messageTransmitter = IMessageTransmitter(_messageTransmtter);
        tokenMessenger = ITokenMessenger(_tokenMessenger);
        zeroEx = _zeroEx;
        initialized = true;
        version = 1;
    }

    receive() external payable {}

    function setRemoteRouter(
        uint32[] calldata remoteDomains,
        address[] calldata routers
    ) public onlyAdmin {
        for (uint i = 0; i < remoteDomains.length; i++) {
            remoteRouter[remoteDomains[i]] = routers[i].addressToBytes32();
        }
    }

    function takeFee(address to, uint256 amount) public onlyAdmin {
        (bool succ, ) = to.call{value: amount}("");
        require(succ);
        emit TakeFee(to, amount);
    }

    function safeZeroExSwap(
        bytes memory swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient,
        uint256 value
    ) public payable returns (uint256 boughtAmount) {
        require(msg.sender == address(this));
        return
            _safeZeroExSwap(
                swapcalldata,
                callgas,
                sellToken,
                sellAmount,
                buyToken,
                guaranteedBuyAmount,
                recipient,
                value
            );
    }

    /// @param recipient set recipient to address(0) to save token in the router contract.
    function _safeZeroExSwap(
        bytes memory swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient,
        uint256 value
    ) internal returns (uint256 boughtAmount) {
        // before swap
        // approve
        if (sellToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            IERC20(sellToken).approve(zeroEx, sellAmount);
        }
        // check balance 0
        uint256 buyToken_bal_0;
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            buyToken_bal_0 = address(this).balance;
        } else {
            buyToken_bal_0 = IERC20(buyToken).balanceOf(address(this));
        }

        _zeroExSwap(swapcalldata, callgas, value);

        // after swap
        // cancel approval
        if (sellToken != 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            // cancel approval
            IERC20(sellToken).approve(zeroEx, 0);
        }
        // check balance 1
        uint256 buyToken_bal_1;
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            buyToken_bal_1 = address(this).balance;
        } else {
            buyToken_bal_1 = IERC20(buyToken).balanceOf(address(this));
        }
        boughtAmount = buyToken_bal_1 - buyToken_bal_0;
        require(boughtAmount >= guaranteedBuyAmount, "swap output not enough");
        // send token to recipient
        if (recipient == address(0)) {
            return boughtAmount;
        }
        if (buyToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool succ, ) = recipient.call{value: boughtAmount}("");
            require(succ, "send eth failed");
        } else {
            IERC20(buyToken).transfer(recipient, boughtAmount);
        }

        return boughtAmount;
    }

    function _zeroExSwap(
        bytes memory swapcalldata,
        uint256 callgas,
        uint256 value
    ) internal {
        (bool succ, ) = zeroEx.call{value: value, gas: callgas}(swapcalldata);
        require(succ, "call swap failed");
    }

    function swap(
        bytes calldata swapcalldata,
        uint256 callgas,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 guaranteedBuyAmount,
        address recipient
    ) public payable {
        if (sellToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(msg.value >= sellAmount, "tx value is not enough");
        } else {
            IERC20(sellToken).transferFrom(
                msg.sender,
                address(this),
                sellAmount
            );
        }
        uint256 boughtAmount = _safeZeroExSwap(
            swapcalldata,
            callgas,
            sellToken,
            sellAmount,
            buyToken,
            guaranteedBuyAmount,
            recipient,
            msg.value
        );
        emit LocalSwap(
            msg.sender,
            sellToken,
            sellAmount,
            buyToken,
            boughtAmount
        );
    }

    /// User entrance
    /// @param sellArgs : sell-token arguments
    /// @param buyArgs : buy-token arguments
    /// @param destDomain : destination domain
    /// @param recipient : token receiver on dest domain
    function swapAndBridge(
        SellArgs calldata sellArgs,
        BuyArgs calldata buyArgs,
        uint32 destDomain,
        bytes32 recipient
    ) public payable returns (uint64, uint64) {
        uint _fee = fee[destDomain].swapFee;
        if (buyArgs.buyToken == bytes32(0)) {
            _fee = fee[destDomain].bridgeFee;
        }
        require(msg.value >= _fee);
        if (recipient == bytes32(0)) {
            recipient = msg.sender.addressToBytes32();
        }

        // swap sellToken to usdc
        if (sellArgs.sellToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            require(
                msg.value >= sellArgs.sellAmount + _fee,
                "tx value is not enough"
            );
        } else {
            IERC20(sellArgs.sellToken).transferFrom(
                msg.sender,
                address(this),
                sellArgs.sellAmount
            );
        }
        uint256 bridgeUSDCAmount;
        if (sellArgs.sellToken == usdc) {
            bridgeUSDCAmount = sellArgs.sellAmount;
        } else {
            bridgeUSDCAmount = _safeZeroExSwap(
                sellArgs.sellcalldata,
                sellArgs.sellcallgas,
                sellArgs.sellToken,
                sellArgs.sellAmount,
                usdc,
                sellArgs.guaranteedBuyAmount,
                address(0),
                msg.value - _fee
            );
        }

        // bridge usdc
        IERC20(usdc).approve(address(tokenMessenger), bridgeUSDCAmount);

        bytes32 destRouter = remoteRouter[destDomain];

        uint64 bridgeNonce = tokenMessenger.depositForBurnWithCaller(
            bridgeUSDCAmount,
            destDomain,
            destRouter,
            usdc,
            destRouter
        );

        bytes32 bridgeNonceHash = keccak256(
            abi.encodePacked(messageTransmitter.localDomain(), bridgeNonce)
        );

        // send swap message
        SwapMessage memory swapMessage = SwapMessage(
            version,
            bridgeNonceHash,
            bridgeUSDCAmount,
            buyArgs.buyToken,
            buyArgs.guaranteedBuyAmount,
            recipient
        );
        bytes memory messageBody = swapMessage.encode();
        uint64 swapMessageNonce = messageTransmitter.sendMessageWithCaller(
            destDomain,
            destRouter, // remote router will receive this message
            destRouter, // message will only submited through the remote router (handleBridgeAndSwap)
            messageBody
        );
        emit SwapAndBridge(
            sellArgs.sellToken,
            buyArgs.buyToken.bytes32ToAddress(),
            bridgeUSDCAmount,
            destDomain,
            recipient.bytes32ToAddress(),
            bridgeNonce,
            swapMessageNonce,
            bridgeNonceHash
        );
        swapHashSender[
            keccak256(abi.encode(destDomain, swapMessageNonce))
        ] = msg.sender;
        return (bridgeNonce, swapMessageNonce);
    }

    function replaceSwapMessage(
        uint64 bridgeMessageNonce,
        uint64 swapMessageNonce,
        MessageWithAttestation calldata originalMessage,
        uint32 destDomain,
        BuyArgs calldata buyArgs,
        address recipient
    ) public {
        require(
            swapHashSender[
                keccak256(abi.encode(destDomain, swapMessageNonce))
            ] == msg.sender
        );

        bytes32 bridgeNonceHash = keccak256(
            abi.encodePacked(
                messageTransmitter.localDomain(),
                bridgeMessageNonce
            )
        );

        SwapMessage memory swapMessage = SwapMessage(
            version,
            bridgeNonceHash,
            0,
            buyArgs.buyToken,
            buyArgs.guaranteedBuyAmount,
            recipient.addressToBytes32()
        );

        messageTransmitter.replaceMessage(
            originalMessage.message,
            originalMessage.attestation,
            swapMessage.encode(),
            remoteRouter[destDomain]
        );
        emit ReplaceSwapMessage(
            buyArgs.buyToken.bytes32ToAddress(),
            destDomain,
            recipient,
            swapMessageNonce
        );
    }

    /// Relayer entrance
    function relay(
        MessageWithAttestation calldata bridgeMessage,
        MessageWithAttestation calldata swapMessage,
        bytes calldata swapdata,
        uint256 callgas
    ) public {
        // 1. decode swap message, get binding bridge message nonce.
        SwapMessage memory swapArgs = swapMessage.message.body().decode();

        // 2. check bridge message nonce is unused.
        require(
            messageTransmitter.usedNonces(swapArgs.bridgeNonceHash) == 0,
            "bridge message nonce is already used"
        );

        // 3. verifys bridge message attestation and mint usdc to this contract.
        // reverts when atestation is invalid.
        uint256 usdc_bal_0 = IERC20(usdc).balanceOf(address(this));
        messageTransmitter.receiveMessage(
            bridgeMessage.message,
            bridgeMessage.attestation
        );
        uint256 usdc_bal_1 = IERC20(usdc).balanceOf(address(this));
        require(usdc_bal_1 >= usdc_bal_0, "usdc bridge error");

        // 4. check bridge message nonce is used.
        require(
            messageTransmitter.usedNonces(swapArgs.bridgeNonceHash) == 1,
            "bridge message nonce is incorrect"
        );

        // 5. verifys swap message attestation.
        // reverts when atestation is invalid.
        messageTransmitter.receiveMessage(
            swapMessage.message,
            swapMessage.attestation
        );

        address recipient = swapArgs.recipient.bytes32ToAddress();

        emit BridgeArrive(swapArgs.bridgeNonceHash, usdc_bal_1 - usdc_bal_0);

        uint256 bridgeUSDCAmount;
        if (swapArgs.sellAmount == 0) {
            bridgeUSDCAmount = usdc_bal_1 - usdc_bal_0;
        } else {
            bridgeUSDCAmount = swapArgs.sellAmount;
            require(
                bridgeUSDCAmount <= (usdc_bal_1 - usdc_bal_0),
                "router did not receive enough usdc"
            );
        }

        uint256 swapAmount = bridgeUSDCAmount;

        require(swapArgs.version == version, "wrong swap message version");

        if (
            swapArgs.buyToken == bytes32(0) ||
            swapArgs.buyToken == usdc.addressToBytes32()
        ) {
            // receive usdc
            IERC20(usdc).transfer(recipient, bridgeUSDCAmount);
        } else {
            try
                this.safeZeroExSwap(
                    swapdata,
                    callgas,
                    usdc,
                    swapAmount,
                    swapArgs.buyToken.bytes32ToAddress(),
                    swapArgs.guaranteedBuyAmount,
                    recipient,
                    0
                )
            {} catch {
                IERC20(usdc).transfer(recipient, swapAmount);
                emit DestSwapFailed(swapArgs.bridgeNonceHash);
                return;
            }
            // TODO get usdc_bal_2
            // rem = usdc_bal_1 - usdc_bal_2
            // transfer rem to recipient
            emit DestSwapSuccess(swapArgs.bridgeNonceHash);
        }
    }

    /// @dev Does not handle message.
    /// Returns a boolean to make message transmitter accept or refuse a message.
    function handleReceiveMessage(
        uint32 sourceDomain,
        bytes32 sender,
        bytes calldata messageBody
    ) external returns (bool) {
        require(
            msg.sender == address(messageTransmitter),
            "caller not allowed"
        );
        if (remoteRouter[sourceDomain] == sender) {
            return true;
        }
        return false;
    }

    function usedNonces(bytes32 nonce) external view returns (uint256) {
        return messageTransmitter.usedNonces(nonce);
    }

    function localDomain() external view returns (uint32) {
        return messageTransmitter.localDomain();
    }
}