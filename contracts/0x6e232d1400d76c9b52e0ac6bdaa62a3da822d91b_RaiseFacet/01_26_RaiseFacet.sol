// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin imports
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local imports
import { AccessTypes } from "../structs/AccessTypes.sol";
import { BaseTypes } from "../structs/BaseTypes.sol";
import { RequestTypes } from "../structs/RequestTypes.sol";
import { LibAccessControl } from "../libraries/LibAccessControl.sol";
import { LibMilestone } from "../libraries/LibMilestone.sol";
import { LibNonce } from "../libraries/LibNonce.sol";
import { LibRaise } from "../libraries/LibRaise.sol";
import { LibSignature } from "../../libraries/LibSignature.sol";
import { IRaiseFacet } from "../interfaces/IRaiseFacet.sol";

/**************************************

    Raise facet

**************************************/

contract RaiseFacet is IRaiseFacet {
    using SafeERC20 for IERC20;

    // versioning: "release:major:minor"
    bytes32 constant EIP712_NAME = keccak256(bytes("Fundraising:Raise"));
    bytes32 constant EIP712_VERSION = keccak256(bytes("1:0:0"));

    // typehashes
    bytes32 constant STARTUP_CREATE_RAISE_TYPEHASH = keccak256("CreateRaiseRequest(bytes raise,bytes vested,bytes milestones,bytes base)");
    bytes32 constant INVESTOR_INVEST_TYPEHASH = keccak256("InvestRequest(string raiseId,uint256 investment,uint256 maxTicketSize,bytes base)");

    // constants
    uint256 constant USDT_DECIMALS = 10**6;

    /**************************************

        Create new raise

     **************************************/

    function createRaise(
        RequestTypes.CreateRaiseRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {

        // tx.members
        address sender_ = msg.sender;
        address self_ = address(this);

        // request.members
        BaseTypes.Raise memory raise_ = _request.raise;
        string memory raiseId_ = raise_.raiseId;

        // validate request
        _validateCreateRaiseRequest(_request);

        // verify if raise does not exist
        LibRaise.verifyRaise(raiseId_);

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeCreateRaise(_request);

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

        // erc20
        IERC20 erc20_ = IERC20(_request.vested.erc20);

        // allowance check
        uint256 allowance_ = erc20_.allowance(
            sender_,
            self_
        );
        if (allowance_ < _request.vested.amount) {
            revert NotEnoughAllowance(sender_, self_, allowance_);
        }

        // vest erc20
        erc20_.safeTransferFrom(
            sender_,
            self_,
            _request.vested.amount
        );

        // save storage
        LibNonce.setNonce(sender_, _request.base.nonce);
        LibRaise.saveRaise(
            raiseId_,
            raise_,
            _request.vested
        );
        LibMilestone.saveMilestones(
            raiseId_,
            _request.milestones
        );

        // emit event
        emit NewRaise(sender_, raise_, _request.milestones, _message);

    }

    function _validateCreateRaiseRequest(
        RequestTypes.CreateRaiseRequest memory _request
    ) internal view {

        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;
        if (nonce_ <= LibNonce.getLastNonce(sender_)) {
            revert NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestExpired(sender_, abi.encode(_request));
        }

        // check request sender
        if (sender_ != _request.base.sender) {
            revert IncorrectSender(sender_);
        }

        // check raise id
        if (bytes(_request.raise.raiseId).length == 0) {
            revert InvalidRaiseId(_request.raise.raiseId);
        }

        // check milestone count
        if (_request.milestones.length == 0) {
            revert InvalidMilestoneCount(_request.milestones);
        }

        // check start and end date
        if (_request.raise.start >= _request.raise.end) {
            revert InvalidMilestoneStartEnd(_request.raise.start, _request.raise.end);
        }

    }

    function _encodeCreateRaise(
        RequestTypes.CreateRaiseRequest memory _request
    ) internal pure
    returns (bytes memory) {

        // raise
        bytes memory encodedRaise_ = abi.encode(_request.raise);

        // vested
        bytes memory encodedVested_ = abi.encode(_request.vested);

        // milestones
        bytes memory encodedMilestones_ = abi.encode(_request.milestones);

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            STARTUP_CREATE_RAISE_TYPEHASH,
            keccak256(encodedRaise_),
            keccak256(encodedVested_),
            keccak256(encodedMilestones_),
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;

    }

    /**************************************

        Invest

     **************************************/

    function invest(
        RequestTypes.InvestRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {

        // tx.members
        address sender_ = msg.sender;

        // request.members
        uint256 investment_ = _request.investment;
        string memory raiseId_ = _request.raiseId;

        // validate request
        _validateInvestRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeInvest(
            _request
        );

        // verify message
        LibSignature.verifyMessage(
            EIP712_NAME,
            EIP712_VERSION,
            keccak256(encodedMsg_),
            _message
        );

        // verify signature
        _verifySignature(
            _message,
            _v,
            _r,
            _s
        );

        // collect investment
        LibRaise.collectUSDT(sender_, _request.investment);

        // equity id
        uint256 badgeId_ = LibRaise.convertRaiseToBadge(
            raiseId_
        );

        // increase nonce
        LibNonce.setNonce(sender_, _request.base.nonce);

        // mint badge
        LibRaise.mintBadge(
            badgeId_,
            investment_ / USDT_DECIMALS
        );

        // storage
        LibRaise.saveInvestment(
            raiseId_,
            investment_
        );

        // event
        emit NewInvestment(
            sender_,
            raiseId_,
            investment_,
            _message,
            badgeId_
        );

    }

    function _validateInvestRequest(
        RequestTypes.InvestRequest calldata _request
    ) internal view {

        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;

        // check replay attack
        uint256 nonce_ = _request.base.nonce;
        if (nonce_ <= LibNonce.getLastNonce(sender_)) {
            revert NonceExpired(sender_, nonce_);
        }

        // check request expiration
        if (now_ > _request.base.expiry) {
            revert RequestExpired(sender_, abi.encode(_request));
        }

        // verify sender
        if (sender_ != _request.base.sender) {
            revert IncorrectSender(sender_);
        }

        // check if fundraising is active (in time)
        if (!LibRaise.isRaiseActive(_request.raiseId)) {
            revert RaiseNotActive(_request.raiseId, now_);
        }

        // verify amount + storage vs ticket size
        uint256 existingInvestment = LibRaise.getInvestment(_request.raiseId, sender_);
        if (existingInvestment + _request.investment > _request.maxTicketSize) {
            revert InvestmentOverLimit(existingInvestment, _request.investment, _request.maxTicketSize);
        }

        // check if the investement does not make the total investment exceed the limit
        uint256 existingTotalInvestment = LibRaise.getTotalInvestment(_request.raiseId);
        uint256 hardcap = LibRaise.getHardCap(_request.raiseId);
        if (existingTotalInvestment + _request.investment > hardcap) {
            revert InvestmentOverHardcap(existingInvestment, _request.investment, hardcap);
        }

    }

    function _encodeInvest(
        RequestTypes.InvestRequest memory _request
    ) internal pure
    returns (bytes memory) {

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            INVESTOR_INVEST_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            _request.investment,
            _request.maxTicketSize,
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;

    }

    /**************************************

        Refund funds

     **************************************/

    function refundInvestment(string memory _raiseId) external {

        address sender_ = msg.sender;

        // check if raise is finished already
        if (!LibRaise.isRaiseFinished(_raiseId)) {
            revert RaiseNotFinished(_raiseId);
        }

        // check if raise didn't reach softcap
        if (LibRaise.isSoftcapAchieved(_raiseId)) {
            revert SoftcapAchieved(_raiseId);
        }

        // refund
        LibRaise.refundUSDT(sender_, _raiseId);

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
        if (!LibAccessControl.hasRole(AccessTypes.SIGNER_ROLE, signer_)) {
            revert IncorrectSigner(signer_);
        }

    }

    /**************************************

        View: Convert raise to badge

     **************************************/

    function convertRaiseToBadge(string memory _raiseId) external view
    returns (uint256) {

        // return
        return LibRaise.convertRaiseToBadge(_raiseId);

    }

}