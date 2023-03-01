// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract EncodeKey is ERC721 {
  uint16[] public keyTypes = [1, 1, 1, 1];
  uint16[] public startOfBlock = [0, 50, 450, 1450];
  string bURI = "https://api.encode.network/metadata/keys/";

	constructor() ERC721("Encode Key", "ENK") {
    uint256 tokenId = startOfBlock[3] + keyTypes[3];
    _mint(msg.sender, tokenId);
    keyTypes[3]++;
	}

  function hasMasterKey(address _owner) public view returns (bool) {
    for (uint16 i = 1; i < keyTypes[3]; i++) {
      if (ownerOf(startOfBlock[3] + i) == _owner) {
        return true;
      }
    }
    return false;
  }

  function setURI(string calldata u) public {
    require(hasMasterKey(msg.sender), "You need a master key for this");
    bURI = u;
  }

  function lastIndex() public view returns (uint256) {
    return startOfBlock[3] + keyTypes[3] - 1;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    uint256 balance = balanceOf(_owner);
    require(_index < balance, "index is greater than balance");
    for (uint16 k = 0; k < keyTypes.length; k++) {
      uint16 end = startOfBlock[k] + keyTypes[k];
      for (uint16 start = startOfBlock[k] + 1; start < end; start++) {
        if (ownerOf(start) == _owner) {
          if (_index == 0) {
            return start;
          }
          _index--;
        }
      }
    }
    revert("no token found");
  }

  function tokensOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(_owner);
    uint256[] memory tokens = new uint256[](balance);
    uint256 index = 0;
    for (uint16 k = 0; k < keyTypes.length; k++) {
      uint16 end = startOfBlock[k] + keyTypes[k];
      for (uint16 start = startOfBlock[k] + 1; start < end; start++) {
        if (ownerOf(start) == _owner) {
          tokens[index] = start;
          index++;
        }
      }
    }
    return tokens;
  }

	function mint(address _to, uint8 _quantity, uint8 _type) public {
    require(hasMasterKey(msg.sender), "must have master key");
    require(_type == 3 || startOfBlock[_type] + keyTypes[_type] + _quantity <= (startOfBlock[_type + 1] + 1), "not enough tokens to mint");
		for (uint8 i = 0; i < _quantity; i++) {
      uint256 tokenId = startOfBlock[_type] + keyTypes[_type] + i;
      _mint(_to, tokenId);
    }
    keyTypes[_type] += _quantity;
	}

  function multiMint(address[] calldata _to, uint8[] calldata _quantity, uint8[] calldata _types) public {
    require(hasMasterKey(msg.sender), "must have master key");
    require(_to.length == _quantity.length && _to.length == _types.length, "to, quantity and types arrays must be the same length");
    uint16[] memory types = new uint16[](4);
    for (uint8 i = 0; i < _to.length; i++) {
      address to = _to[i];
      uint16 quantity = _quantity[i];
      uint16 _type = _types[i];
      require(_type == 3 || (startOfBlock[_type] + keyTypes[_type] + types[_type] + quantity <= (startOfBlock[_type + 1] + 1)), "not enough tokens to mint");
      for (uint16 j = 0; j < quantity; j++) {
        uint256 tokenId = startOfBlock[_type] + keyTypes[_type] + types[_type]++;
        _mint(to, tokenId);
      }
    }
    if (types[0] > 0) {
      keyTypes[0] += types[0];
    }
    if (types[1] > 0) {
      keyTypes[1] += types[1];
    }
    if (types[2] > 0) {
      keyTypes[2] += types[2];
    }
    if (types[3] > 0) {
      keyTypes[3] += types[3];
    }
  }

  function _baseURI() internal view override returns (string memory) {
    return bURI;
  }
}