// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// Local imports
import { BaseTypes } from "../structs/BaseTypes.sol";
import { RequestTypes } from "../structs/RequestTypes.sol";

/**************************************

    Raise facet interface

**************************************/

interface IRaiseFacet {

    // events
    event NewRaise(address sender, BaseTypes.Raise raise, BaseTypes.Milestone[] milestones, bytes32 message);
    event NewInvestment(address sender, string raiseId, uint256 investment, bytes32 message, uint256 data);

    // errors
    error NonceExpired(address sender, uint256 nonce);
    error RequestExpired(address sender, bytes request);
    error IncorrectSender(address sender);
    error IncorrectSigner(address signer);
    error InvalidRaiseId(string raiseId);
    error InvalidMilestoneCount(BaseTypes.Milestone[] milestones);
    error InvalidMilestoneStartEnd(uint256 start, uint256 end);
    error NotEnoughAllowance(address sender, address spender, uint256 amount);
    error IncorrectAmount(uint256 amount);
    error InvestmentOverLimit(uint256 existingInvestment, uint256 newInvestment, uint256 maxTicketSize);
    error InvestmentOverHardcap(uint256 existingInvestment, uint256 newInvestment, uint256 hardcap);
    error RaiseNotActive(string raiseId, uint256 currentTime);
    error RaiseNotFinished(string raiseId);
    error SoftcapAchieved(string raiseId);

    /**************************************

        Create new raise

     **************************************/

    function createRaise(
        RequestTypes.CreateRaiseRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**************************************

        Invest

     **************************************/

    function invest(
        RequestTypes.InvestRequest calldata _request,
        bytes32 _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**************************************

        Refund funds

     **************************************/

    function refundInvestment(string memory _raiseId) external;

    /**************************************

        View: Convert raise to badge

     **************************************/

    function convertRaiseToBadge(string memory _raiseId) external view
    returns (uint256);

}