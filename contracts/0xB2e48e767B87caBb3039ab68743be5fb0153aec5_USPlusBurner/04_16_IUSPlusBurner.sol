// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IUSPlusBurner {
    struct BurnTicket {
        bytes32 refId;
        address redeemerContractAddress;
        address redeemerPerson;
        address fedMemberID;
        uint256 amount;
        uint256 placedBlock;
        uint256 confirmedBlock;
        bool status;
        bool executed;
    }

    ///@dev arrays of refIds
    struct BurnTicketId {
        bytes32 refId;
        address fedMemberId;
    }

    /// @notice Returns a Burn ticket structure
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnReceiptById(
        bytes32 id
    ) external view returns (BurnTicket memory);

    /// @notice Returns Status, Execution Status and the Block Number when the burn occurs
    /// @dev
    /// @param id The Ticket Id generated in Core Banking System
    function getBurnStatusById(
        bytes32 id
    ) external view returns (bool, bool, uint256);

    function toGrantRole(address _to) external;

    /// @notice Execute transferFrom Executer Acc to this contract, and open a burn Ticket
    /// @dev to match the id the fields should be (burnCounter, _refNo, amount, msg.sender)
    /// @param refId Ref Code provided by customer to identify this request
    /// @param redeemerContractAddress The Federation Member´s REDEEMER contract
    /// @param redeemerPerson The person who is requesting USD Redeem
    /// @param fedMemberID Identification for Federation Member
    /// @param amount The amount to be burned
    /// @return isRequestPlaced confirmation if Function gets to the end without revert
    function requestBurnUSPlus(
        bytes32 refId,
        address redeemerContractAddress,
        address redeemerPerson,
        address fedMemberID,
        uint256 amount
    ) external returns (bool isRequestPlaced);

    /// @notice Burn the amount of US defined in the ticket
    /// @dev Be aware that burnID is formed by a hash of (mapping.burnCounter, mapping._refNo, amount, _redeemBy), see requestBurnUSPlus method
    /// @param refId Burn TicketID
    /// @param redeemerContractAddress address from the amount get out
    /// @param fedMemberId Federation Member ID
    /// @param amount Burn amount requested
    /// @return isAmountBurned confirmation if Function gets to the end without revert
    function executeBurn(
        bytes32 refId,
        address redeemerContractAddress,
        address fedMemberId,
        uint256 amount,
        address vault
    ) external returns (bool isAmountBurned);

    function setComplianceManagerAddr(
        address newComplianceManagerAddr
    ) external;

    function setUSPlusAddr(address newUSPlusAddr) external;

    function transferErc20(
        address to,
        address erc20Addr,
        uint256 amount
    ) external;
}