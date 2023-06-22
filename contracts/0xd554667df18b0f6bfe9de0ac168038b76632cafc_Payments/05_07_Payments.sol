pragma solidity ^0.5.16;

import './Ownable.sol';
import './ERC20.sol';
import './PermitToken.sol';


interface KyberNetworkProxy {
  function getExpectedRate(address src, address dest, uint srcQty) external view returns(uint, uint);
  function swapEtherToToken(address token, uint minConversionRate) external payable returns(uint);
}


contract Payments is Ownable {
  address constant internal ETH_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  event Paid(bytes32 paymentId);
  KyberNetworkProxy kyber;
  ERC20 public target_token;
  ERC20 public convert_token;
  address signerAddress;
  constructor(address target, address convert, address _kyber, address signer) Ownable() public {
    target_token = ERC20(target);
    convert_token = ERC20(convert);
    kyber = KyberNetworkProxy(_kyber);
    signerAddress = signer;
  }

  function payERC20(bytes32 paymentId, uint expiration, uint tokAmt, uint ethAmt, address depositAddress, bytes memory signature) public {
    require(expiration > block.timestamp, "expired");
    require(isValidSignature(keccak256(abi.encodePacked(address(this), paymentId, expiration, tokAmt, ethAmt, depositAddress)), signature), "invalid signature");
    require(target_token.transferFrom(msg.sender, depositAddress, tokAmt), "tokens unavailable");
    emit Paid(paymentId);
  }

  function payERC20Permit(bytes32 paymentId, uint expiration, uint tokAmt, uint ethAmt, address depositAddress, bytes memory signature, bytes memory permitsignature) public {
    PermitToken(address(target_token)).permit(msg.sender, address(this), PermitToken(address(target_token)).nonces(msg.sender), expiration, true, uint8(permitsignature[0]), toBytes32(permitsignature, 1), toBytes32(permitsignature, 33));
    payERC20(paymentId, expiration, tokAmt, ethAmt, depositAddress, signature);
  }

  function payETH(bytes32 paymentId, uint expiration, uint tokAmt, address payable depositAddress, bytes calldata signature) external payable {
    require(expiration > block.timestamp, "expired");
    require(isValidSignature(keccak256(abi.encodePacked(address(this), paymentId, expiration, tokAmt, msg.value, depositAddress)), signature), "bad-signature");
    if(address(convert_token) == address(0)) {
      depositAddress.transfer(address(this).balance); // Forward all ETH, in case we got some from somewhere else
    } else {
      uint minRate;
      (, minRate) = kyber.getExpectedRate(ETH_TOKEN_ADDRESS, address(convert_token), msg.value);
      uint destAmount = kyber.swapEtherToToken.value(msg.value)(address(convert_token), minRate);
      require(convert_token.transfer(depositAddress, destAmount), "token transfer failed");
    }
    emit Paid(paymentId);
  }

  function setTargetTokens(address target, address convert) external onlyOwner {
    target_token = ERC20(target);
    convert_token = ERC20(convert);
  }
  function setSigner(address signer) external onlyOwner {
    signerAddress = signer;
  }
  function setKyber(address _kyber) external onlyOwner {
    kyber = KyberNetworkProxy(_kyber);
  }
  function withdrawTokens(address _token) external onlyOwner {
    // In case someone sent tokens directly to the payment contract, instead of
    // making calls properly.
    ERC20 target = ERC20(_token);
    target.transfer(msg.sender, target.balanceOf(address(this)));
  }
  function isValidSignature(
    bytes32 _hash,
    bytes memory signature
  ) internal view returns (bool) {
    bytes32 hash = keccak256(abi.encodePacked(signerAddress, _hash));
    uint8 v = uint8(signature[0]);
    bytes32 r = toBytes32(signature, 1);
    bytes32 s = toBytes32(signature, 33);
    return ecrecover(hash, v, r, s) == signerAddress;
  }
  // toBytes32
  // @param _bytes - A byte string
  // @param _start - The offset within _bytes to extract a `bytes32`
  // @returns tempBytes32  - bytes32(_bytes[_start:_start+32])
  function toBytes32(bytes memory _bytes, uint _start) internal  pure returns (bytes32) {
    require(_bytes.length >= (_start + 32));
    bytes32 tempBytes32;
    assembly {
        tempBytes32 := mload(add(add(_bytes, 0x20), _start))
    }
    return tempBytes32;
  }
}
