// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

interface IDefaultTokenRegistry {
    function initialize(address _owner) external;

    function tokenInfo(address _token)
        external
        view
        returns (
            uint8 index,
            uint8 decimals,
            bool isSupportedOnCompound,
            address cToken,
            address chainLinkOracle,
            uint256 borrowLTV
        );

    function tokens(uint256 _index) external view returns (address);

    function getTokensLength() external view returns (uint256 length);
}