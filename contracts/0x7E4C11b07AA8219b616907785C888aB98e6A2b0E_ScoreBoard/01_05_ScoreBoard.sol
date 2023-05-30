// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/** @title ScoreBoard Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract ScoreBoard is Ownable {

  mapping(uint256 => bytes) public _mintPayloads;
  mapping(uint256 => bytes) public _burnPayloads;

  address public _eetContract;

  constructor() Ownable() { }

  function setEET(address eetContract_) external onlyOwner {
    _eetContract = eetContract_;
  }

  /**
    * @dev Mint Payload setter
    * @param _eetTokenId the corresponding EET token
    * @param _mintPayload the mmint payload
    */
  function addMintPayload(uint256 _eetTokenId, address _msgSender, bytes memory _mintPayload) external {
    require(msg.sender == _eetContract, toAsciiString(msg.sender));//"only EET can add mint payload"
    _mintPayloads[_eetTokenId] = _mintPayload;
  }

  function toAsciiString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);
    }
    return string(s);
  }

  function char(bytes1 b) internal pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  /**
    * @dev Burn Payload setter
    * @param _eetTokenId the corresponding EET token
    * @param _burnPayload the burn payload
    */
  function addBurnPayload(uint256 _eetTokenId, address _msgSender, bytes memory _burnPayload) external {
    require(msg.sender == _eetContract, "only EET can add burn payload");
    _burnPayloads[_eetTokenId] = _burnPayload;
  }

  /**
    * @dev Mint Payload getter
    * @param _eetTokenId the corresponding EET token
    */
  function getMintPayload(uint256 _eetTokenId) external view returns(bytes memory){
    return _mintPayloads[_eetTokenId];
  }

  /**
    * @dev Burn Payload getter
    * @param _eetTokenId the corresponding EET token
    */
  function getBurnPayload(uint256 _eetTokenId) external view returns(bytes memory){
    return _burnPayloads[_eetTokenId];
  }



}//end