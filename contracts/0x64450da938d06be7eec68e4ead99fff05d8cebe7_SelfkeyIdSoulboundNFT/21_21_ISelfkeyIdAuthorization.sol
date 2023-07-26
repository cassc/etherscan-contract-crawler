// SPDX-License-Identifier: proprietary
pragma solidity >=0.8.19;

interface ISelfkeyIdAuthorization {

    function authorize(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp, address _signer, bytes memory _signature) external;

    function getMessageHash(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp) external view returns (bytes32);

    function getEthSignedMessageHash(bytes32 _messageHash) external view returns (bytes32);

    function verify(address _from, address _to, uint256 _amount, string memory _scope, bytes32 _param, uint _timestamp, address _signer, bytes memory _signature) external view returns (bool);

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) external view returns (address);

    function splitSignature(bytes memory sig) external view returns (bytes32 r, bytes32 s, uint8 v);
}