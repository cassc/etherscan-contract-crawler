// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface ILenderLike {

    function poolDelegate() external view returns (address poolDelegate_);

}

interface IMapleGlobalsLike {

    /// @dev The address of the security admin
    function globalAdmin() external view returns (address globalAdmin_);

    /// @dev The address of the Governor responsible for management of global Maple variables.
    function governor() external view returns (address governor_);

    /// @dev The fee rate directed to Pool Delegates.
    function investorFee() external view returns (uint256 investorFee_);

    /// @dev The Treasury where all fees pass through for conversion, prior to distribution.
    function mapleTreasury() external view returns (address mapleTreasury_);

    /// @dev A boolean indicating whether the protocol is paused.
    function protocolPaused() external view returns (bool paused_);

    /// @dev The fee rate directed to the Maple Treasury.
    function treasuryFee() external view returns (uint256 treasuryFee_);

}