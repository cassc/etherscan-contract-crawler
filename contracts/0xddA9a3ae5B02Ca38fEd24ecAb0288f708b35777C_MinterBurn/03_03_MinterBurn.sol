// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function mint(address _to, uint256 _quantity) external;

  function burn(uint256 _tokenId) external;

  function ownerOf(uint256 _tokenId) external view returns (address);
}

// must be granted burner role by access token
contract MinterBurn is Ownable {
  address public accessToken;
  address public erc721Token;

  bool public claimStarted;

  /// @notice Constructor for the ONFT
  /// @param _accessToken address for the nft used to claim via burn
  /// @param _erc721Token address for nft to be minted
  constructor(address _accessToken, address _erc721Token) {
    accessToken = _accessToken;
    erc721Token = _erc721Token;
  }

  function _claim(uint256 _tokenId) internal {
    address owner = IERC721(accessToken).ownerOf(_tokenId);
    require(owner == msg.sender, "Must be access token owner");
    IERC721(accessToken).burn(_tokenId);
  }

  function claim(uint256 _tokenId) public {
    require(claimStarted, "Claim period has not begun");
    _claim(_tokenId);
    issueToken(msg.sender, 1);
  }

  function claimBatch(uint256[] memory _tokenIds) public {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _claim(_tokenIds[i]);
    }
    issueToken(msg.sender, _tokenIds.length);
  }

  function issueToken(address _to, uint256 _quantity) internal {
    IERC721(erc721Token).mint(_to, _quantity);
  }

  function setClaimStart(bool _isStarted) public onlyOwner {
    claimStarted = _isStarted;
  }

  function setERC721(address _erc721Token) public onlyOwner {
    erc721Token = _erc721Token;
  }

  function setAccessToken(address _accessToken) public onlyOwner {
    accessToken = _accessToken;
  }
}