// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IEscrow {
    enum EscrowStatuses {
        Launched,
        Pending,
        Partial,
        Paid,
        Complete,
        Cancelled
    }

    function status() external view returns (EscrowStatuses);

    function addTrustedHandlers(address[] memory _handlers) external;

    function setup(
        address _reputationOracle,
        address _recordingOracle,
        uint8 _reputationOracleFeePercentage,
        uint8 _recordingOracleFeePercentage,
        string memory _url,
        string memory _hash
    ) external;

    function abort() external;

    function cancel() external returns (bool);

    function complete() external;

    function storeResults(string memory _url, string memory _hash) external;

    function bulkPayOut(
        address[] memory _recipients,
        uint256[] memory _amounts,
        string memory _url,
        string memory _hash,
        uint256 _txId
    ) external;
}