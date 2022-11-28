// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721 {
  function mint(address _to) external;

  function burn(uint256 _tokenId) external;

  function ownerOf(uint256 _tokenId) external view returns (address);
}

// must be granted burner role by access token
contract SluggaClaim is Ownable {
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

  function claim(uint256 _tokenId) public {
    require(claimStarted, "Claim period has not begun");
    address owner = IERC721(accessToken).ownerOf(_tokenId);
    require(owner == msg.sender, "Must be access token owner");
    IERC721(accessToken).burn(_tokenId);
    issueToken(msg.sender);
  }

  function claimBatch(uint256[] memory _tokenIds) public {
    require(claimStarted, "Claim period has not begun");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      address owner = IERC721(accessToken).ownerOf(_tokenIds[i]);
      require(owner == msg.sender, "Must be access token owner");
      IERC721(accessToken).burn(_tokenIds[i]);
      issueToken(msg.sender);
    }
  }

  function issueToken(address _to) internal {
    IERC721(erc721Token).mint(_to);
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