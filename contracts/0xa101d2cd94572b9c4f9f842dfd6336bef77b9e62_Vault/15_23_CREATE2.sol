// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


library CREATE2 {
  error ContractNotCreated();

  function addressOf(address _creator, uint256 _salt, bytes32 _creationCodeHash) internal pure returns (address payable) {
    return payable(
        address(
        uint160(
          uint256(
            keccak256(
              abi.encodePacked(
                bytes1(0xff),
                _creator,
                _salt,
                _creationCodeHash
              )
            )
          )
        )
      )
    );
  }

  function deploy(uint256 _salt, bytes memory _creationCode) internal returns (address payable _contract) {
    assembly {
      _contract := create2(callvalue(), add(_creationCode, 32), mload(_creationCode), _salt)
    }

    if (_contract == address(0)) {
      revert ContractNotCreated();
    }
  }
}