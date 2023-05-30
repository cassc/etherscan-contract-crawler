pragma solidity 0.7.6;
pragma abicoder v2;
// SPDX-License-Identifier: GPL-3.0-only

interface IStafiLightNode {
    function depositEth() external payable;
    function deposit(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) external payable;
    function stake(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) external;
    function offBoard(bytes calldata _validatorPubkey) external;
    function provideNodeDepositToken(bytes calldata _validatorPubkey) external payable;
    function withdrawNodeDepositToken(bytes calldata _validatorPubkey) external;
    function getLightNodePubkeyCount(address _nodeAddress) external view returns (uint256);
    function getLightNodePubkeyAt(address _nodeAddress, uint256 _index) external view returns (bytes memory);
    function getLightNodePubkeyStatus(bytes calldata _validatorPubkey) external view returns (uint256);
    function voteWithdrawCredentials(bytes[] calldata _pubkey, bool[] calldata _match) external;
}