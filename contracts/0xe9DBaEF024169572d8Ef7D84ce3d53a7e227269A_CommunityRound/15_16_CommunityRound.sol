// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

// Local
import { Configurable } from "../utils/Configurable.sol";
import { LibSignature } from "../libraries/LibSignature.sol";
import { ICommunityRound } from "../interfaces/ICommunityRound.sol";

/**************************************

    Community Phase contract

 **************************************/


contract CommunityRound is ICommunityRound, AccessControl, ReentrancyGuard, Configurable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    // versioning: "release:major:minor"
    bytes32 public constant EIP712_NAME = keccak256(bytes("Presale:Community"));
    bytes32 public constant EIP712_VERSION = keccak256(bytes("1:0:0"));
    uint256 public immutable MIN_USDT_TO_RESERVE;
    uint256 public immutable MAX_USDT_TO_RESERVE;

    // typehashes
    bytes32 public constant RESERVE_TYPEHASH = keccak256("ReserveRequest(uint256 amount,bytes base)");

    // roles
    bytes32 public constant SIGNER_ROLE = keccak256("IS SIGNER");
    bytes32 public constant WITHDRAWAL_ROLE = keccak256("CAN WITHDRAW");

    // structs: requests
    struct BaseRequest {
        address sender;
        uint256 expiry;
        uint256 nonce;
    }

    struct ReserveRequest {
        uint256 amount;
        BaseRequest base;
    }

    // contracts
    IERC20 public usdt;

    // storage
    mapping (address => uint256) public balances;
    mapping (address => uint256) public nonces;
    uint256 public deadline;

    /**************************************
    
        Constructor

     **************************************/

    constructor(bytes memory _arguments) {

        // tx.members
        address sender_ = msg.sender;

        // decode arguments
        (
            address signer_,
            uint256 deadline_
        ) = abi.decode(
            _arguments,
            (
                address,
                uint256
            )
        );

        // set min and max reserve amount
        MIN_USDT_TO_RESERVE = 500 * 10**6;
        MAX_USDT_TO_RESERVE = 25000 * 10**6;

        // admin setup
        _setupRole(DEFAULT_ADMIN_ROLE, sender_);

        // signer role
        _setRoleAdmin(SIGNER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(SIGNER_ROLE, signer_);

        // withdrawal role
        _setRoleAdmin(WITHDRAWAL_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(WITHDRAWAL_ROLE, sender_);

        // save storage
        deadline = deadline_;

    }

    /**************************************
    
        Configure

     **************************************/

    function configure(
        bytes calldata _arguments
    ) external virtual override
    onlyRole(DEFAULT_ADMIN_ROLE)
    onlyInState(State.UNCONFIGURED) {

        // decode arguments
        (
            address usdt_
        ) = abi.decode(
            _arguments,
            (
                address
            )
        );

        // storage
        usdt = IERC20(usdt_);

        // state
        state = State.CONFIGURED;

        // events
        emit Configured(_arguments);

    }

    /**************************************
    
        Reserve

     **************************************/

    function reserve(
        ReserveRequest memory _request,
        bytes32 _message, 
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    ) external
    onlyInState(State.CONFIGURED)
    nonReentrant {

        // tx.members
        address sender_ = msg.sender;
        address self_ = address(this);
        uint256 now_ = block.timestamp;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;
        if (nonce_ <= nonces[sender_]) {
            revert NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestExpired(sender_, abi.encode(_request));
        }

        // check reserve expiration
        if (now_ > deadline) {
            revert ReserveDeadlineMet();
        }

        // check request sender
        if (sender_ != _request.base.sender) {
            revert IncorrectSender(sender_);
        }

        // check already invested
        if (balances[sender_] != 0) {
            revert AlreadyReserved(sender_);
        }

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeReserve(_request);

        // verify message
        LibSignature.verifyMessage(
            EIP712_NAME,
            EIP712_VERSION,
            keccak256(encodedMsg_),
            _message
        );

        // verify signer of signature
        _verifySignature(
            _message,
            _v,
            _r,
            _s
        );

        // verify amount
        if (_request.amount < MIN_USDT_TO_RESERVE || _request.amount > MAX_USDT_TO_RESERVE) {
            revert InvalidAmount(abi.encode(_request), MIN_USDT_TO_RESERVE, MAX_USDT_TO_RESERVE);
        }

        // collect usdt
        usdt.safeTransferFrom(sender_, self_, _request.amount);

        // save storage
        nonces[sender_] = _request.base.nonce;
        balances[sender_] = _request.amount;

        // event
        emit Reserved(sender_, _request.amount);

    }

    /**************************************
    
        Withdraw

     **************************************/

    function withdraw() external
    onlyInState(State.CONFIGURED)
    onlyRole(WITHDRAWAL_ROLE) {

        // tx.members
        address sender_ = msg.sender;
        uint256 balance_ = usdt.balanceOf(address(this));

        // check balance
        if (balance_ == 0) {
            revert NothingToWithdraw();
        }

        // withdraw
        usdt.safeTransfer(sender_, balance_);

        // event
        emit Withdraw(sender_, balance_);

    }

    /**************************************
    
        Internal: Encode reserve

     **************************************/

    function _encodeReserve(
        ReserveRequest memory _request
    ) internal pure
    returns (bytes memory) {

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            RESERVE_TYPEHASH,
            _request.amount,
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;

    }

    /**************************************
    
        Internal: Verify signature

     **************************************/

    function _verifySignature(
        bytes32 _message,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    ) internal view {

        // signer of message
        address signer_ = LibSignature.recoverSigner(
            _message,
            _v, 
            _r, 
            _s
        );

        // validate signer
        if (!hasRole(SIGNER_ROLE, signer_)) {
            revert IncorrectSigner(signer_);
        }

    }

    /**************************************
    
        View: Allowed to reserve

     **************************************/
    
    function isAllowed(address _owner) external view returns (bool) {
        return balances[_owner] == 0;
    }

    /**************************************
    
        View: Balance

     **************************************/
    
    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

}