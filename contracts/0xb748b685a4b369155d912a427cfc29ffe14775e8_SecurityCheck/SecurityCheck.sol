/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

contract SecurityCheck {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    function executeMetaTransaction(
        address payable _to,
        uint256 _value,
        bytes memory _data,
        bytes memory _signature
    ) public {
        bytes32 hash = getMessageHash(_to, _value, _data);
        address signer = recoverSigner(hash, _signature);
        require(signer != address(0), "Invalid signature");

        // Perform additional checks if necessary, e.g., validate the signer's permissions.

        (bool success, ) = _to.call{value: _value}(_data);
        require(success, "Transaction execution failed");
    }

    function getMessageHash(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _value, _data));
    }

    function recoverSigner(bytes32 _hash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (_signature.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        return ecrecover(_hash, v, r, s);
    }

    function withdrawEther() public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(address(this).balance > 0, "No Ether to withdraw");
        payable(msg.sender).transfer(address(this).balance);
    }
}