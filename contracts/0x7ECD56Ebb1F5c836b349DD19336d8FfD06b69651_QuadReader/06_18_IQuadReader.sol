//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import "../storage/QuadPassportStore.sol";

interface IQuadReader {
    event QueryEvent(address indexed _account, address indexed _caller, bytes32 _attribute);
    event QueryBulkEvent(address indexed _account, address indexed _caller, bytes32[] _attributes);
    event QueryFeeReceipt(address indexed _receiver, uint256 _fee);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);

    function queryFee(
        address _account,
        bytes32 _attribute
    ) external view returns(uint256);

    function queryFeeBulk(
        address _account,
        bytes32[] calldata _attributes
    ) external view returns(uint256);

    function getAttributes(
        address _account, bytes32 _attribute
    ) external payable returns(QuadPassportStore.Attribute[] memory attributes);

    function getAttributesLegacy(
        address _account, bytes32 _attribute
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function getAttributesBulk(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(QuadPassportStore.Attribute[] memory);

    function getAttributesBulkLegacy(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function balanceOf(address _account, bytes32 _attribute) external view returns(uint256);

    function latestEpoch(address _account, bytes32 _attribute) external view returns(uint256);

    function hasPassportByIssuer(address _account, bytes32 _attribute, address _issuer) external view returns(bool);

    function withdraw(address payable _to, uint256 _amount) external;

    // @dev DEPRECATED - use `queryFee` instead
    function calculatePaymentETH(
        bytes32 _attribute,
        address _account
    ) external view returns(uint256);


    // @dev DEPRECATED - use `getAttributesLegacy` instead
    function getAttributesETH(
        address _account,
        uint256 _tokenId,
        bytes32 _attribute
    ) external payable returns(bytes32[] memory, uint256[] memory, address[] memory);
}