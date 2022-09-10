// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IClaimer {
    function id() external view returns (string memory);

    function token() external view returns (address);

    function getAccounts(uint256 _unused) external view returns (address[] memory);

    function getTransferredAccounts() external view returns (address[2][] memory);

    function claim(address account, uint256 idx) external;

    function claimAll(address account) external;

    function isPaused() external view returns (bool);

    function isClaimable(address account, uint256 claimIdx) external view returns (bool);

    function isClaimed(address account, uint256 claimIdx) external view returns (bool);

    // Total, claimed, remaining
    function getTotalStats()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    // Total, claimed, claimable
    function getAccountStats(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}