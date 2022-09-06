// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

library Errors {
    // Create/Close Account
    string public constant InvalidInitiator = "CA0";
    string public constant InvalidRecipient = "CA1";
    string public constant InvalidGP = "CA2";
    string public constant InvalidNameLength = "CA3";
    string public constant InvalidManagementFee = "CA4";
    string public constant InvalidCarriedInterest = "CA5";
    string public constant InvalidUnderlyingToken = "CA6";
    string public constant InvalidAllowedProtocols = "CA7";
    string public constant InvalidAllowedTokens = "CA8";
    string public constant InvalidRecipientMinAmount = "CA9";

    // Others
    string public constant NotManager = "FM0";
    string public constant NotGP = "FM1";
    string public constant NotLP = "FM2";
    string public constant NotGPOrLP = "FM3";
    string public constant NotEnoughBuyAmount = "FM4";
    string public constant InvalidSellUnit = "FM5";
    string public constant NotEnoughBalance = "FM6";
    string public constant MissingAmount = "FM7";
    string public constant InvalidFundCreateParams = "FM8";
    string public constant InvalidName = "FM9";
    string public constant NotAccountOwner = "FM10";
    string public constant ContractCannotBeZeroAddress = "FM11";
    string public constant ExceedMaximumPositions = "FM12";
    string public constant NotAllowedToken = "FM13";
    string public constant NotAllowedProtocol = "FM14";
    string public constant FunctionCallIsNotAllowed = "FM15";
    string public constant PathNotAllowed = "FM16";
    string public constant ProtocolCannotBeZeroAddress = "FM17";
    string public constant CallerIsNotManagerOwner = "FM18";
    string public constant InvalidInitializeParams = "FM19";
    string public constant InvalidUpdateParams = "FM20";
    string public constant InvalidZeroAddress = "FM21";
    string public constant NotAllowedAdapter = "FM22";
}