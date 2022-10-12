// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IINFPermissionManager {
    event LogWhiteListInvestor(address indexed investor, address indexed operator, bool approved);
    event LogBlackListInvestor(address indexed investor, address indexed operator, bool approved);
    event LogSetFeeAndFeeRecipient(uint256 fee, address indexed feeRecipient);
    event LogSetTokenFee(uint256 fee, address indexed tokenId);
    event LogFeeExempt(address indexed user, address indexed operator, uint256 status);

    function getStatusAndFee(
        address sender,
        address receiver
    ) external view returns (bool exempt, uint256 fee, uint256 feePrecision, address feeRecipient);

    function setFeeExempt(address user, bool senderExempt, bool recipientExempt, bool onlyWhitelisted) external;

    function setTokenFee(uint256 _fee, address _tokenId) external;

    function fee() external returns (uint256 fee);

    function whitelistInvestor(address investor, bool approved) external;

    function whitelistedInvestors(address _account) external view returns (bool);

    function blackListed(address _account) external view returns (bool);

    function setInvestorWhitelisting(
        address operator,
        address investor,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}