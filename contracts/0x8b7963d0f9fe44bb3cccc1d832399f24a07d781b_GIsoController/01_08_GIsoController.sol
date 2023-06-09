// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IsoToken.sol";

contract GIsoController is Ownable {
    mapping(address => uint256) public withdrawRecord;
    address public signer = 0x8168e7d3a63b08f8E4609cA74547e911809140d7;
    uint256 public maxWithdrawalLimit;

    event WithdrawRecord(address owner, uint256 value);
    
    IsoToken token;

    constructor(IsoToken _token, uint256 _initLimit) { 
      token = _token;
      maxWithdrawalLimit = _initLimit;
    }

    function updateSigner(address _signer) external onlyOwner {
      signer = _signer;
    }

    function updateMaxWithdrawalLimit(uint256 _limit) external onlyOwner {
      maxWithdrawalLimit = _limit;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
      assembly {
        addr := mload(add(bys,20))
      } 
    }

    function withdrawIso(bytes calldata _message, uint8 _v, bytes32 _r, bytes32 _s) 
      external
    {
        address targetAddress = bytesToAddress(_message[:20]);
        require(msg.sender == targetAddress, "Not target address");

        uint32 amount = uint32(bytes4(_message[20:24]));
        uint256 finalAmount = uint256(amount) * 10 ** 18; 
        require(finalAmount > withdrawRecord[msg.sender], "Withdraw amount exceed");
        require(finalAmount <= maxWithdrawalLimit, "Withdraw amount exceed 2");

        bytes memory prefix = "\x19Ethereum Signed Message:\n24";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _message));
        
        address recoveredSigner = ecrecover(prefixedHashMessage, _v, _r, _s);
        require(signer == recoveredSigner, "Not correct signer");

        uint withdrawableAmount = (finalAmount - withdrawRecord[msg.sender]);
        withdrawRecord[msg.sender] = finalAmount;

        token.mint(msg.sender, withdrawableAmount);
        emit WithdrawRecord(msg.sender, withdrawableAmount);
    }
}