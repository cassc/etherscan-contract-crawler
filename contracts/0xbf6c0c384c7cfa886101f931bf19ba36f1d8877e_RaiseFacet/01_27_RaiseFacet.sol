// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
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
import { LibNonce } from "../libraries/LibNonce.sol";
import { LibRaise } from "../libraries/LibRaise.sol";
import { LibSignature } from "../../libraries/LibSignature.sol";
import { LibEscrow } from "../libraries/LibEscrow.sol";
import { VerifySignatureMixin } from "../mixins/VerifySignatureMixin.sol";
import { IRaiseFacet } from "../interfaces/IRaiseFacet.sol";

/**************************************

    Raise facet

**************************************/

/// @notice Raise facet implementing raise creation, investment, refund and reclaim.
contract RaiseFacet is IRaiseFacet {
    // -----------------------------------------------------------------------
    //                              Libraries
    // -----------------------------------------------------------------------

    using SafeERC20 for IERC20;

    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev EIP712 name
    bytes32 constant EIP712_NAME = keccak256(bytes("Fundraising:Raise"));
    /// @dev EIP712 versioning: "release:major:minor"
    bytes32 constant EIP712_VERSION = keccak256(bytes("1:0:0"));

    /// @dev Typehash for create raise by startup
    bytes32 constant STARTUP_CREATE_RAISE_TYPEHASH = keccak256("CreateRaiseRequest(bytes raise,bytes vested,bytes base)");
    /// @dev Typehash for set token by an early stage startup
    bytes32 constant STARTUP_SET_TOKEN_TYPEHASH = keccak256("SetTokenRequest(string raiseId,address token,bytes base)");
    /// @dev Typehash for investing into raise by investor
    bytes32 constant INVESTOR_INVEST_TYPEHASH = keccak256("InvestRequest(string raiseId,uint256 investment,uint256 maxTicketSize,bytes base)");

    /// @dev USDT decimals
    uint256 constant USDT_DECIMALS = 10 ** 6;

    // -----------------------------------------------------------------------
    //                              Raise section
    // -----------------------------------------------------------------------

    /// @dev Create new raise and initializes fresh escrow clone for it.
    /// @dev Validation: Supports standard and early stage raises.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewRaise(address sender, BaseTypes.Raise raise, uint256 badgeId, bytes32 message).
    /// @param _request CreateRaiseRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function createRaise(RequestTypes.CreateRaiseRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // tx.members
        address sender_ = msg.sender;

        // request.members
        BaseTypes.Raise memory raise_ = _request.raise;
        string memory raiseId_ = raise_.raiseId;

        // validate request
        _validateCreateRaiseRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeCreateRaise(_request);

        // verify message
        LibSignature.verifyMessage(EIP712_NAME, EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signer of signature
        VerifySignatureMixin.verifySignature(_message, _v, _r, _s);

        // create Escrow
        address escrow_ = LibEscrow.createEscrow(raiseId_);

        // save storage
        LibNonce.setNonce(sender_, _request.base.nonce);
        LibRaise.saveRaise(raiseId_, raise_, _request.vested);

        if (raise_.raiseType != BaseTypes.RaiseType.EarlyStage) {
            // transfer vested token to escrow
            LibRaise.collectVestedToken(_request.vested.erc20, sender_, escrow_, _request.vested.amount);
        }

        // get badge id
        uint256 badgeId_ = LibRaise.convertRaiseToBadge(raiseId_);

        // set uri
        LibRaise.setUri(badgeId_, raise_.raiseDetails.badgeUri);

        // emit event
        emit NewRaise(sender_, raise_, badgeId_, _message);
    }

    /// @dev Validate create raise request.
    /// @dev Validation: Checks validity of sender, request and contained raise.
    /// @param _request CreateRaiseRequest struct
    function _validateCreateRaiseRequest(RequestTypes.CreateRaiseRequest calldata _request) internal view {
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

        // verify if raise does not exist
        if (LibRaise.raiseExists(_request.raise.raiseId)) {
            revert RaiseAlreadyExists(_request.raise.raiseId);
        }

        // check start and end date
        if (_request.raise.raiseDetails.start >= _request.raise.raiseDetails.end) {
            revert InvalidRaiseStartEnd(_request.raise.raiseDetails.start, _request.raise.raiseDetails.end);
        }

        // check if tokens are vested
        if (_request.vested.amount == 0) {
            revert InvalidVestedAmount();
        }

        // validate price per token == vested / hardcap
        if (
            _request.raise.raiseDetails.price.tokensPerBaseAsset !=
            (_request.vested.amount * LibRaise.PRICE_PRECISION) / _request.raise.raiseDetails.hardcap
        ) {
            revert PriceNotMatchConfiguration(
                _request.raise.raiseDetails.price.tokensPerBaseAsset,
                _request.raise.raiseDetails.hardcap,
                _request.vested.amount
            );
        }

        // validate token address for Early Stage type
        if (_request.raise.raiseType != BaseTypes.RaiseType.EarlyStage && _request.vested.erc20 == address(0)) {
            revert InvalidTokenAddress(_request.vested.erc20);
        }
    }

    /// @dev Encode create raise request to validate the EIP712 message.
    /// @param _request CreateRaiseRequest struct
    /// @return EIP712 encoded message containing request
    function _encodeCreateRaise(RequestTypes.CreateRaiseRequest calldata _request) internal pure returns (bytes memory) {
        // raise
        bytes memory encodedRaise_ = abi.encode(_request.raise);

        // vested
        bytes memory encodedVested_ = abi.encode(_request.vested);

        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            STARTUP_CREATE_RAISE_TYPEHASH,
            keccak256(encodedRaise_),
            keccak256(encodedVested_),
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }

    // -----------------------------------------------------------------------
    //                              Early stage section
    // -----------------------------------------------------------------------

    /// @dev Sets token for early stage startups, that haven't set ERC-20 token address during raise creation.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: TokenSet(address sender, string raiseId, address token).
    /// @param _request SetTokenRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function setToken(RequestTypes.SetTokenRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // tx.members
        address sender_ = msg.sender;

        // request.members
        string memory raiseId_ = _request.raiseId;
        address token_ = _request.token;

        // validate request
        _validateSetTokenRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeSetToken(_request);

        // verify message
        LibSignature.verifyMessage(EIP712_NAME, EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        VerifySignatureMixin.verifySignature(_message, _v, _r, _s);

        // set token address
        LibRaise.setVestedERC20(raiseId_, token_);

        // emit event
        emit TokenSet(sender_, raiseId_, token_);
    }

    /// @dev Validate set token request.
    /// @dev Validation: Checks validity of sender, request, raise and contained ERC20.
    /// @param _request SetTokenRequest struct
    function _validateSetTokenRequest(RequestTypes.SetTokenRequest calldata _request) internal view {
        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;
        string memory raiseId_ = _request.raiseId;

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

        // existence check
        if (!LibRaise.raiseExists(raiseId_)) {
            revert RaiseDoesNotExists(raiseId_);
        }

        // validate if sender is startup
        if (LibRaise.getRaiseOwner(raiseId_) != sender_) {
            revert CallerNotStartup(sender_, raiseId_);
        }

        // validate raise type
        if (LibRaise.getRaiseType(raiseId_) != BaseTypes.RaiseType.EarlyStage) {
            revert OnlyForEarlyStage(raiseId_);
        }

        // validate if address hasn't been already set
        if (LibRaise.getVestedERC20(raiseId_) != address(0)) {
            revert TokenAlreadySet(raiseId_);
        }
    }

    /// @dev Encode set token request to validate the EIP712 message.
    /// @param _request SetTokenRequest struct
    /// @return EIP712 encoded message containing request
    function _encodeSetToken(RequestTypes.SetTokenRequest calldata _request) internal pure returns (bytes memory) {
        // base
        bytes memory encodedBase_ = abi.encode(_request.base);

        // msg
        bytes memory encodedMsg_ = abi.encode(
            STARTUP_SET_TOKEN_TYPEHASH,
            keccak256(bytes(_request.raiseId)),
            _request.token,
            keccak256(encodedBase_)
        );

        // return
        return encodedMsg_;
    }

    // -----------------------------------------------------------------------
    //                              Invest section
    // -----------------------------------------------------------------------

    /// @dev Invest in a raise and mint ERC1155 equity badge for it.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data).
    /// @param _request InvestRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function invest(RequestTypes.InvestRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external {
        // tx.members
        address sender_ = msg.sender;

        // request.members
        string memory raiseId_ = _request.raiseId;
        uint256 investment_ = _request.investment;

        // validate request
        _validateInvestRequest(_request);

        // eip712 encoding
        bytes memory encodedMsg_ = _encodeInvest(_request);

        // verify message
        LibSignature.verifyMessage(EIP712_NAME, EIP712_VERSION, keccak256(encodedMsg_), _message);

        // verify signature
        VerifySignatureMixin.verifySignature(_message, _v, _r, _s);

        // get Escrow address
        address escrow_ = LibEscrow.getEscrow(raiseId_);

        // collect investment
        LibRaise.collectUSDT(sender_, _request.investment, escrow_);

        // equity id
        uint256 badgeId_ = LibRaise.convertRaiseToBadge(raiseId_);

        // increase nonce
        LibNonce.setNonce(sender_, _request.base.nonce);

        // mint badge
        LibRaise.mintBadge(badgeId_, investment_ / USDT_DECIMALS);

        // storage
        LibRaise.saveInvestment(raiseId_, investment_);

        // event
        emit NewInvestment(sender_, raiseId_, investment_, _message, badgeId_);
    }

    /// @dev Validate invest request.
    /// @dev Validation: Checks validity of sender, request, raise and investment.
    /// @param _request InvestRequest struct
    function _validateInvestRequest(RequestTypes.InvestRequest calldata _request) internal view {
        // tx.members
        address sender_ = msg.sender;
        uint256 now_ = block.timestamp;
        string memory raiseId_ = _request.raiseId;

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

        // existence check
        if (!LibRaise.raiseExists(raiseId_)) {
            revert RaiseDoesNotExists(raiseId_);
        }

        // startup owner cannot invest
        if (sender_ == LibRaise.getRaiseOwner(raiseId_)) {
            revert OwnerCannotInvest(sender_, raiseId_);
        }

        // check if fundraising is active (in time)
        if (!LibRaise.isRaiseActive(raiseId_)) {
            revert RaiseNotActive(raiseId_, now_);
        }

        // verify amount + storage vs ticket size
        uint256 existingInvestment_ = LibRaise.getInvestment(raiseId_, sender_);
        if (existingInvestment_ + _request.investment > _request.maxTicketSize) {
            revert InvestmentOverLimit(existingInvestment_, _request.investment, _request.maxTicketSize);
        }

        // check if the investement does not make the total investment exceed the limit
        uint256 existingTotalInvestment_ = LibRaise.getTotalInvestment(raiseId_);
        uint256 hardcap_ = LibRaise.getHardCap(raiseId_);
        if (existingTotalInvestment_ + _request.investment > hardcap_) {
            revert InvestmentOverHardcap(existingTotalInvestment_, _request.investment, hardcap_);
        }
    }

    /// @dev Encode invest request to validate the EIP712 message.
    /// @param _request InvestRequest struct
    /// @return EIP712 encoded message containing request
    function _encodeInvest(RequestTypes.InvestRequest calldata _request) internal pure returns (bytes memory) {
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

    // -----------------------------------------------------------------------
    //                              Reclaim section
    // -----------------------------------------------------------------------

    /// @dev Reclaim unsold ERC20 by startup if raise went successful, but did not reach hardcap.
    /// @dev Validation: Validate raise, sender and ability to reclaim.
    /// @dev Events: UnsoldReclaimed(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function reclaimUnsold(string memory _raiseId) external {
        // tx.members
        address sender_ = msg.sender;

        // existence check
        if (!LibRaise.raiseExists(_raiseId)) {
            revert RaiseDoesNotExists(_raiseId);
        }

        // check if token for EarlyStage type is set
        if (LibRaise.getRaiseType(_raiseId) == BaseTypes.RaiseType.EarlyStage && LibRaise.getVestedERC20(_raiseId) == address(0)) {
            revert TokenNotSet(_raiseId);
        }

        // validate if sender is startup
        if (LibRaise.getRaiseOwner(_raiseId) != sender_) {
            revert IncorrectSender(sender_);
        }

        // check if raise is finished already
        if (!LibRaise.isRaiseFinished(_raiseId)) {
            revert RaiseNotFinished(_raiseId);
        }

        // check if raise reach softcap
        if (!LibRaise.isSoftcapAchieved(_raiseId)) {
            revert SoftcapNotAchieved(_raiseId);
        }

        // check if hardcap achieved
        uint256 hardcap_ = LibRaise.raiseStorage().raises[_raiseId].raiseDetails.hardcap;
        uint256 raised_ = LibRaise.raiseStorage().investInfo[_raiseId].raised;
        uint256 diff_ = hardcap_ - raised_;
        if (diff_ == 0) {
            revert HardcapAchieved(_raiseId);
        }

        // get unsold tokens
        uint256 unsold_ = LibRaise.getUnsold(_raiseId, diff_);
        if (unsold_ == 0) {
            revert NothingToReclaim(_raiseId);
        }

        // get escrow
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // mark as reclaimed
        if (LibRaise.raiseStorage().investInfo[_raiseId].reclaimed) {
            revert AlreadyReclaimed(_raiseId);
        }
        LibRaise.raiseStorage().investInfo[_raiseId].reclaimed = true;

        // send tokens
        LibRaise.reclaimUnsold(escrow_, sender_, _raiseId, unsold_);

        // emit
        emit UnsoldReclaimed(sender_, _raiseId, unsold_);
    }

    // -----------------------------------------------------------------------
    //                              Refund section
    // -----------------------------------------------------------------------

    /// @dev Refund investment to investor, if raise was not successful (softcap hasn't been reached).
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: InvestmentRefunded(address sender, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundInvestment(string memory _raiseId) external {
        // tx.members
        address sender_ = msg.sender;

        // validate request
        _validateRefundInvestment(_raiseId);

        // get Escrow address
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // get investment
        uint256 investment_ = LibRaise.getInvestment(_raiseId, sender_);

        // refund
        LibRaise.refundUSDT(sender_, escrow_, _raiseId, investment_);

        // emit
        emit InvestmentRefunded(sender_, _raiseId, investment_);
    }

    /// @dev Validate refund investment.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @param _raiseId ID of raise
    function _validateRefundInvestment(string memory _raiseId) internal view {
        // tx.members
        address sender_ = msg.sender;

        // check if raise exists
        if (!LibRaise.raiseExists(_raiseId)) {
            revert RaiseDoesNotExists(_raiseId);
        }

        // check if raise is finished already
        if (!LibRaise.isRaiseFinished(_raiseId)) {
            revert RaiseNotFinished(_raiseId);
        }

        // check if raise didn't reach softcap
        if (LibRaise.isSoftcapAchieved(_raiseId)) {
            revert SoftcapAchieved(_raiseId);
        }

        // check if user invested
        if (LibRaise.getInvestment(_raiseId, sender_) == 0) {
            revert UserHasNotInvested(sender_, _raiseId);
        }

        // check if already refunded
        if (LibRaise.investmentRefunded(_raiseId, sender_)) {
            revert AlreadyRefunded(sender_, _raiseId);
        }
    }

    /// @dev Refund ERC20 to startup, if raise was not successful.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: CollateralRefunded(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundStartup(string memory _raiseId) external {
        // tx.members
        address sender_ = msg.sender;

        // validate request
        _validateRefundStartup(_raiseId);

        // get Escrow address
        address escrow_ = LibEscrow.getEscrow(_raiseId);

        // get collateral
        uint256 collateral_ = LibRaise.getVestedAmount(_raiseId);

        // refund
        LibRaise.refundCollateral(sender_, escrow_, _raiseId, collateral_);

        // emit
        emit CollateralRefunded(sender_, _raiseId, collateral_);
    }

    /// @dev Validate refund collateral to startup.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @param _raiseId ID of raise
    function _validateRefundStartup(string memory _raiseId) internal view {
        // tx.members
        address sender_ = msg.sender;

        // check if raise exists
        if (!LibRaise.raiseExists(_raiseId)) {
            revert RaiseDoesNotExists(_raiseId);
        }

        // check if token for EarlyStage type is set
        if (LibRaise.getRaiseType(_raiseId) == BaseTypes.RaiseType.EarlyStage && LibRaise.getVestedERC20(_raiseId) == address(0)) {
            revert TokenNotSet(_raiseId);
        }

        // check if raise is finished already
        if (!LibRaise.isRaiseFinished(_raiseId)) {
            revert RaiseNotFinished(_raiseId);
        }

        // check if raise didn't reach softcap
        if (LibRaise.isSoftcapAchieved(_raiseId)) {
            revert SoftcapAchieved(_raiseId);
        }

        // check if _sender is startup of this raise
        if (LibRaise.getRaiseOwner(_raiseId) != sender_) {
            revert CallerNotStartup(sender_, _raiseId);
        }

        // check collateral
        if (LibRaise.collateralRefunded(_raiseId)) {
            revert CollateralAlreadyRefunded(_raiseId);
        }
    }

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev Calculate ID of equity badge based on ID of raise.
    /// @param _raiseId ID of raise
    /// @return ID of badge (derived from hash of raise ID)
    function convertRaiseToBadge(string memory _raiseId) external pure returns (uint256) {
        // return
        return LibRaise.convertRaiseToBadge(_raiseId);
    }
}