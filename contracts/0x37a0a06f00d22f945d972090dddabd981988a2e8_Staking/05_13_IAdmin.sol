pragma solidity ^0.8.10;

import {IExecutor} from "./IExecutor.sol";

interface IAdmin {

    ////////////////////
    ////// Events //////
    ////////////////////

    /// @notice Emited when a new address is set for the Council
    event NewCouncil(address oldCouncil, address newCouncil);
    /// @notice Emited when a new address is set for the Founders
    event NewFounders(address oldFounders, address newFounders);
    /// @notice Emited when a new address is set for the Pauser
    event NewPauser(address oldPauser, address newPauser);
    /// @notice Emited when a new address is set for the Verifier
    event NewVerifier(address oldVerifier, address newVerifier);
    /// @notice Emitted when pendingFounders is changed
    event NewPendingFounders(address oldPendingFounders, address newPendingFounders);

    /////////////////////
    ////// Methods //////
    /////////////////////

    function acceptFounders() external;
    function council() external view returns (address);
    function executor() external view returns (IExecutor);
    function founders() external view returns (address);
    function pauser() external view returns (address);
    function pendingFounders() external view returns (address);
    function revokeFounders() external;
    function setCouncil(address _newCouncil) external;
    function setPauser(address _newPauser) external;
    function setPendingFounders(address _newPendingFounders) external;
}