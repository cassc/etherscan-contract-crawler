pragma solidity 0.7.6;
pragma abicoder v2;
// SPDX-License-Identifier: GPL-3.0-only

interface IStafiSuperNode {
    function depositEth() external payable;
    function deposit(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) external;
    function stake(bytes[] calldata _validatorPubkeys, bytes[] calldata _validatorSignatures, bytes32[] calldata _depositDataRoots) external;
    function getSuperNodePubkeyCount(address _nodeAddress) external view returns (uint256);
    function getSuperNodePubkeyAt(address _nodeAddress, uint256 _index) external view returns (bytes memory);
    function getSuperNodePubkeyStatus(bytes calldata _validatorPubkey) external view returns (uint256);
    function voteWithdrawCredentials(bytes[] calldata _pubkey, bool[] calldata _match) external;
}