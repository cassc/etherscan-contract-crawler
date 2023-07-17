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

// Local imports
import { BaseTypes } from "../structs/BaseTypes.sol";
import { RequestTypes } from "../structs/RequestTypes.sol";

/**************************************

    Raise facet interface

**************************************/

/// Interface for raise facet.
interface IRaiseFacet {
    // -----------------------------------------------------------------------
    //                              Events
    // -----------------------------------------------------------------------

    event NewRaise(address sender, BaseTypes.Raise raise, uint256 badgeId, bytes32 message);
    event TokenSet(address sender, string raiseId, address token);
    event NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data);
    event InvestmentRefunded(address sender, string raiseId, uint256 amount);
    event CollateralRefunded(address startup, string raiseId, uint256 amount);
    event UnsoldReclaimed(address startup, string raiseId, uint256 amount);

    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error NonceExpired(address sender, uint256 nonce); // 0x2b6069a9
    error RequestExpired(address sender, bytes request); // 0xd53e449b
    error IncorrectSender(address sender); // 0x7da9057e
    error InvalidRaiseId(string raiseId); // 0xc2f9a803
    error InvalidRaiseStartEnd(uint256 start, uint256 end); // 0xb2fb4a1d
    error InvalidVestedAmount(); // 0x17329d67
    error PriceNotMatchConfiguration(uint256 price, uint256 hardcap, uint256 vested); // 0x643c0fc5
    error IncorrectAmount(uint256 amount); // 0x88967d2f
    error OwnerCannotInvest(address sender, string raiseId); // 0x44b4eea9
    error InvestmentOverLimit(uint256 existingInvestment, uint256 newInvestment, uint256 maxTicketSize); // 0x3ebbf796
    error InvestmentOverHardcap(uint256 existingInvestment, uint256 newInvestment, uint256 hardcap); // 0xf0152bdf
    error RaiseAlreadyExists(string raiseId); // 0xa7bb9fe0
    error RaiseDoesNotExists(string raiseId); // 0x78134459
    error RaiseNotActive(string raiseId, uint256 currentTime); // 0x251061ff
    error RaiseNotFinished(string raiseId); // 0xab91f47a
    error SoftcapAchieved(string raiseId); // 0x17d74e3f
    error SoftcapNotAchieved(string raiseId); // 0x63117c7e
    error HardcapAchieved(string raiseId); // 0x8e144f11
    error NothingToReclaim(string raiseId); // 0xf803caaa
    error AlreadyReclaimed(string raiseId); // 0x5ab9f7ef
    error UserHasNotInvested(address sender, string raiseId); // 0xf2ed8df2
    error AlreadyRefunded(address sender, string raiseId); // 0x44302120
    error CallerNotStartup(address sender, string raiseId); // 0x73810657
    error CollateralAlreadyRefunded(string raiseId); // 0xc4543938
    error InvalidTokenAddress(address token); // 0x73306803
    error OnlyForEarlyStage(string raiseId); // 0x2e14bd97
    error TokenAlreadySet(string raiseId); // 0x11f125e1
    error TokenNotSet(string raiseId); // 0x64d2ac41

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /**************************************

        Create new raise

     **************************************/

    /// @dev Create new raise and initializes fresh escrow clone for it.
    /// @dev Validation: Supports standard and early stage raises.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewRaise(address sender, BaseTypes.Raise raise, uint256 badgeId, bytes32 message).
    /// @param _request CreateRaiseRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function createRaise(RequestTypes.CreateRaiseRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /**************************************

        Set token

     **************************************/

    /// @dev Sets token for early stage startups, that does not have ERC20 during raise creation.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: TokenSet(address sender, string raiseId, address token).
    /// @param _request SetTokenRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function setToken(RequestTypes.SetTokenRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /**************************************

        Invest

     **************************************/

    /// @dev Invest in a raise and mint ERC1155 equity badge for it.
    /// @dev Validation: Requires valid cosignature from AngelBlock validator to execute.
    /// @dev Events: NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data).
    /// @param _request InvestRequest struct
    /// @param _message EIP712 messages that contains request
    /// @param _v Part of signature for message
    /// @param _r Part of signature for message
    /// @param _s Part of signature for message
    function invest(RequestTypes.InvestRequest calldata _request, bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) external;

    /**************************************

        Reclaim unsold

     **************************************/

    /// @dev Reclaim unsold ERC20 by startup if raise went successful, but did not reach hardcap.
    /// @dev Validation: Validate raise, sender and ability to reclaim.
    /// @dev Events: UnsoldReclaimed(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function reclaimUnsold(string memory _raiseId) external;

    /**************************************

        Refund funds

     **************************************/

    /// @dev Refund investment to investor, if raise was not successful.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: InvestmentRefunded(address sender, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundInvestment(string memory _raiseId) external;

    /**************************************

        Refund collateral to startup

    **************************************/

    /// @dev Refund ERC20 to startup, if raise was not successful.
    /// @dev Validation: Validate raise, sender and ability to refund.
    /// @dev Events: CollateralRefunded(address startup, string raiseId, uint256 amount).
    /// @param _raiseId ID of raise
    function refundStartup(string memory _raiseId) external;

    /**************************************

        View: Convert raise to badge

     **************************************/

    /// @dev Calculate ID of equity badge based on ID of raise.
    /// @param _raiseId ID of raise
    /// @return ID of badge (derived from hash of raise ID)
    function convertRaiseToBadge(string memory _raiseId) external pure returns (uint256);
}