// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Gridcraft_Bits is ERC20, Ownable {
  using ECDSA for bytes32;

  address signer;

  mapping(uint256 => bool) withdrawn;

  constructor(
  ) ERC20("Gridcraft","BITS"){
    _mint(0xFaF53800a1fB124e58b5680d4d139f84284709ae, 2500000000 ether);     // 2.5B BITS
  }

  function mint(uint256 _amount, uint256 _timestamp, bytes memory _signature) external {
		require(block.timestamp <= _timestamp, "Transaction expired");
    bytes32 hash = hashTransaction(_msgSender(), _amount, _timestamp);
    require(!withdrawn[uint(hash)], "Transaction already spent");
    require(matchSignerAdmin(signTransaction(hash), _signature), "Signature mismatch");
    withdrawn[uint(hash)] = true;
    _mint(_msgSender(), _amount);
  }

  function deposit(uint256 _amount) external {
    _burn(_msgSender(), _amount);
  }

  function hashTransaction(address _sender, uint256 _amount, uint256 _timestamp) public pure returns (bytes32) {
    bytes32 _hash = keccak256(abi.encode(_sender, _amount, _timestamp));
    return _hash;
	}
	
	
	function signTransaction(bytes32 _hash) public pure returns (bytes32) {
	  return _hash.toEthSignedMessageHash();
	}

	function matchSignerAdmin(bytes32 _payload, bytes memory _signature) public view returns (bool) {
		return signer == _payload.recover(_signature);
	}

  // owner setters

  function setSignerAddress(address _newSigner) external onlyOwner {
    signer = _newSigner;
  }

}