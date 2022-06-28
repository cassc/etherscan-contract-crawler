// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/errors.sol";
import "../../ImplBase.sol";
import "../../interfaces/cbridge.sol";
import "../../helpers/Pb.sol";

/**
@title Celer L2 Implementation.
@notice This is the L2 implementation, so this is used when transferring from
l2 to supported l2s or L1.
Called by the registry if the selected bridge is Celer bridge.
@dev Follows the interface of ImplBase.
@author Socket.
*/

contract CelerImplL1L2 is ImplBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Pb for Pb.Buffer;
    ICBridge public immutable router;
    address immutable wethAddress;
    mapping(bytes32 => address) public transferIdAdrressMap;
    uint64 public immutable chainId;

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    }

    /**
    @notice Constructor sets the router address and registry address.
    @dev Celer Bridge address is constant. so no setter function required.
    */
    constructor(
        ICBridge _router,
        address _registry,
        address _wethAddress
    ) ImplBase(_registry) {
        router = _router;
        chainId = uint64(block.chainid);
        wethAddress = _wethAddress;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    /**
    @notice function responsible for calling cross chain transfer using celer bridge.
    @dev the token to be passed on to the celer bridge.
    @param _amount amount to be sent.
    @param _from sender address. 
    @param _receiverAddress receivers address.
    @param _token this is the main token address on the source chain. 
    @param _toChainId destination chain Id
    @param _data data contains nonce and the maxSlippage.
    */
    function outboundTransferTo(
        uint256 _amount,
        address _from,
        address _receiverAddress,
        address _token,
        uint256 _toChainId,
        bytes memory _data
    ) external payable override onlyRegistry nonReentrant {
        (uint64 nonce, uint32 maxSlippage, address senderAddress) = abi.decode(
            _data,
            (uint64, uint32, address)
        );
        if (_token == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, MovrErrors.VALUE_NOT_EQUAL_TO_AMOUNT);
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _receiverAddress,
                    wethAddress,
                    _amount,
                    uint64(_toChainId),
                    nonce,
                    chainId
                )
            );
            require(
                transferIdAdrressMap[transferId] == address(0),
                "Transfer Id already exist in map"
            );
            transferIdAdrressMap[transferId] = senderAddress;
            router.sendNative{value: _amount}(
                _receiverAddress,
                _amount,
                uint64(_toChainId),
                nonce,
                maxSlippage
            );
        } else {
            require(msg.value == 0, MovrErrors.VALUE_SHOULD_BE_ZERO);
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
            IERC20(_token).safeIncreaseAllowance(address(router), _amount);
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _receiverAddress,
                    _token,
                    _amount,
                    uint64(_toChainId),
                    nonce,
                    chainId
                )
            );
            require(
                transferIdAdrressMap[transferId] == address(0),
                "Transfer Id already exist in map"
            );
            transferIdAdrressMap[transferId] = senderAddress;
            router.send(
                _receiverAddress,
                _token,
                _amount,
                uint64(_toChainId),
                nonce,
                maxSlippage
            );
        }
    }

    function refundCelerUser(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable nonReentrant {
        WithdrawMsg memory request = decWithdrawMsg(_request);
        bytes32 transferId = keccak256(
            abi.encodePacked(
                request.chainid,
                request.seqnum,
                request.receiver,
                request.token,
                request.amount
            )
        );
        uint256 _initialBalanceTokenOut = address(this).balance;
        if (!router.withdraws(transferId)) {
            router.withdraw(_request, _sigs, _signers, _powers);
        }
        require(request.receiver == address(this), "Invalid refund");
        address _receiver = transferIdAdrressMap[request.refid];
        delete transferIdAdrressMap[request.refid];
        require(
            _receiver != address(0),
            "Unknown transfer id or already refunded"
        );
        if (address(this).balance > _initialBalanceTokenOut) {
            payable(_receiver).transfer(request.amount);
        } else {
            IERC20(request.token).safeTransfer(_receiver, request.amount);
        }
    }

    function decWithdrawMsg(bytes memory raw)
        internal
        pure
        returns (WithdrawMsg memory m)
    {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}