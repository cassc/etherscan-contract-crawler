// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

interface IERC5192 {
  /// @notice Emitted when the locking status is changed to locked.
  /// @dev If a token is minted and the status is locked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Locked(uint256 tokenId);

  /// @notice Emitted when the locking status is changed to unlocked.
  /// @dev If a token is minted and the status is unlocked, this event should be emitted.
  /// @param tokenId The identifier for a token.
  event Unlocked(uint256 tokenId);

  /// @notice Returns the locking status of an Soulbound Token
  /// @dev SBTs assigned to zero address are considered invalid, and queries
  /// about them do throw.
  /// @param tokenId The identifier for an SBT.
  function locked(uint256 tokenId) external view returns (bool);
}

contract HPPv2NFT is ERC721, Ownable, IERC5192 {

    uint256 private _tokenIdCounter;
    string  private _tokenURI;

    constructor() ERC721("Hooked Party Pass v2", "HPPv2") {
        _tokenURI = string(abi.encodePacked('data:application/json;base64,', Base64.encode(bytes(string(abi.encodePacked('{"name": "Hooked Party Pass v2", "description": "Hooked Party Pass Season 2 NFT is designed to reward early Hooked Protocol contributors who actively made significant efforts for the Hooked Protocol community. Each user can claim only 1 Hooked Party Pass NFT or Hooked Party Pass Season 2 NFT.", "image": "ipfs://QmVEvYw6C97biGCf9vQ5BXsM48yTMYwc21vp5K732vZwE8"}'))))));
    }

    function locked(uint256) external pure override returns (bool){
        return true;
    }

    function mint(address to) onlyOwner public {
        require(balanceOf(to) == 0, "PASS limit exceeded");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;
        _mint(to, tokenId);
        emit Locked(tokenId);
    }

    function mint(address[] calldata to) onlyOwner public {
        for (uint256 i = 0; i < to.length; i++){
            mint(to[i]);
        }
    }

    function tokenURI(uint256) public view override returns (string memory) {
        return _tokenURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override
    {
        require(from == address(0),"NFT locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }
}