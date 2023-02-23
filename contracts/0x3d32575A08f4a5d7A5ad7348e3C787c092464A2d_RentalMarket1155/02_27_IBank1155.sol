// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {TokenType} from "../constant/TokenEnums.sol";
import "../erc5006/IERC5006.sol";

interface IBank1155 {
    struct RecordParam {
        uint256 recordId;
        TokenType tokenType;
        address oNFT;
        uint256 oNFTId;
        uint256 oNFTAmount;
        address owner;
        address user;
        uint256 expiry;
    }

    struct RentingRecord{
        TokenType tokenType;
        address oNFT;
        uint256 oNFTId;
        address lender;
        uint256 recordId;
    }

    struct Renting{
        address lender;
        uint256 amount;
    }

    event CreateUserRecord(RecordParam param);

    event DeleteUserRecord(RentingRecord param);

    function createUserRecord(RecordParam memory param) external;

    function deleteUserRecords(RentingRecord[] calldata toDeletes) external;

    function frozenAmountOf(
        address oNFT,
        uint256 oNFTId,
        address from
    ) external view returns (uint256);
}