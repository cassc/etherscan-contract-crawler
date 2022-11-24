// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IAccount {
    function owner() external view returns (address);

    function createSubAccount(bytes memory _data, uint256 _costETH)
        external
        payable
        returns (address newSubAccount);

    function executeOnAdapter(bytes calldata _callBytes, bool _callType)
        external
        payable
        returns (bytes memory);

    function multiCall(
        bool[] calldata _callType,
        bytes[] calldata _callArgs,
        bool[] calldata _isNeedCallback
    ) external;

    function setAdvancedOption(bool val) external;

    function callOnSubAccount(
        address _target,
        bytes calldata _callArgs,
        uint256 amountETH
    ) external;

    function withdrawAssets(
        address[] calldata _tokens,
        address _receiver,
        uint256[] calldata _amounts
    ) external;

    function approve(
        address tokenAddr,
        address to,
        uint256 amount
    ) external;

    function approveTokens(
        address[] calldata _tokens,
        address[] calldata _spenders,
        uint256[] calldata _amounts
    ) external;

    function isSubAccount(address subAccount) external view returns (bool);
}