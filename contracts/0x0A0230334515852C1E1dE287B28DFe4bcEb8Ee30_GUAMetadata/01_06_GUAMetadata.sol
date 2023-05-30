// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./BytesLib.sol";
import "./Strings.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface iFetusMovement {
  function getGif() external view returns(bytes memory);
  function getMetadata() external view returns(string memory);
}

/** @title GUAMetadata Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract GUAMetadata is Ownable {

  address public _fetusMovementContract;

  constructor () Ownable() {}

  function setFetusMovementContract(address fetusMovementContract_) external onlyOwner {
    _fetusMovementContract = fetusMovementContract_;
  }

  function render(bytes memory _gif, string memory _metadata) public pure returns (string memory) {
    string memory json = string(abi.encodePacked(
      '{"image": "data:image/gif;base64,',
      Base64.encode(_gif),
      '", ',
      _metadata,
      '}'
    ));

    return _pack(json);
  }//end render()


  function _pack(string memory _json) public pure returns (string memory) {
    string memory base64json = Base64.encode(bytes(_json));

    return string(abi.encodePacked('data:application/json;base64,', base64json));
  }

  function fetusMovementGif() external view returns (bytes memory gif) {
    return iFetusMovement(_fetusMovementContract).getGif();
  }


  function getMetadata(uint256 _tokenId, bytes32 _seed, bytes32 _queryhash, uint256 _timestamp, uint256 _rand, string memory _query, uint8 _colorIndex, bytes2 _bitstream) external view returns (string memory) {
    if(_tokenId == 0){
      return iFetusMovement(_fetusMovementContract).getMetadata();
    }else{
      string memory attributes =
        string(
          abi.encodePacked(
            '"attributes": [{"trait_type": "seed", "value": "',
            BytesLib.toHex(bytes(abi.encodePacked(_seed))),
            '"}, {"trait_type": "queryhash", "value": "',
            BytesLib.toHex(bytes(abi.encodePacked(_queryhash))),
            '"}, {"display_type": "date", "trait_type": "minted", "value":',
            Strings.toString(_timestamp),
            '}, {"display_type":"number", "trait_type": "color", "value":',
            Strings.toString(uint256(_colorIndex)),
            '}, {"display_type":"number", "trait_type": "bitstream", "value":',
            Strings.toString(uint256(uint16(_bitstream))),
            '}, {"display_type":"number", "trait_type": "entropy", "value":',
            Strings.toString(_rand)
          )
        );

      if(!Strings.compareStrings(_query,"")){
        attributes = string(abi.encodePacked(
          attributes,
          '}, {"trait_type": "query", "value": "',
          _query,
          '"'
        ));
      }

      string memory description;
      bytes memory empty = bytes(_query);
      if(empty.length == 0){
        description = toHex(_queryhash);
      }else{
        description = _query;
      }

      return
        string(
          abi.encodePacked(
            '"description": "',
            description,
            '", "name": "GUA #',
            Strings.toString(_tokenId),
            '", "createdBy": "Cai Guo-Qiang x Kanon",',
            attributes,
            '}]'
          )
        );
    }
  }

  function toHex16 (bytes16 data) internal pure returns (bytes32 result) {
    result = bytes32 (data) & 0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000 |
          (bytes32 (data) & 0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >> 64;
    result = result & 0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000 |
          (result & 0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >> 32;
    result = result & 0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000 |
          (result & 0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >> 16;
    result = result & 0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000 |
          (result & 0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >> 8;
    result = (result & 0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >> 4 |
          (result & 0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >> 8;
    result = bytes32 (0x3030303030303030303030303030303030303030303030303030303030303030 +
           uint256 (result) +
           (uint256 (result) + 0x0606060606060606060606060606060606060606060606060606060606060606 >> 4 &
           0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) * 7);
  }

  function toHex (bytes32 data) public pure returns (string memory) {
    return string (abi.encodePacked ("0x", toHex16 (bytes16 (data)), toHex16 (bytes16 (data << 128))));
  }



}//end