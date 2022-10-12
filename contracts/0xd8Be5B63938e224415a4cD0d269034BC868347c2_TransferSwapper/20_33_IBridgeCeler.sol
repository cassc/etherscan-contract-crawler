// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

interface IBridgeCeler {
    // common
    function delayThresholds(address token) external view returns (uint256);

    function delayPeriod() external view returns (uint256);

    function epochVolumes(address token) external view returns (uint256);

    function epochVolumeCaps(address token) external view returns (uint256);

    // liquidity bridge
    function minSend(address token) external view returns (uint256);

    function maxSend(address token) external view returns (uint256);

    // peg vault v0/v2
    function minDeposit(address token) external view returns (uint256);

    function maxDeposit(address token) external view returns (uint256);

    // peg bridge v0/v2
    function minBurn(address token) external view returns (uint256);

    function maxBurn(address token) external view returns (uint256);

    function nativeWrap() external view returns (address);

    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}