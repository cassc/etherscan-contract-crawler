// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

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

contract DIDNFT is ERC721, AccessControl, IERC5192 {

    mapping(uint256 => bool) private _lock;
    bytes32 public constant GAMER_ROLE = keccak256("GAMER_ROLE");
    uint256 public constant RESERVED_IDS = 10000;
    uint256 private _tokenIdCounter;

    constructor() ERC721("Hooked SoulBound Token", "HST") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _tokenIdCounter = RESERVED_IDS;
    }

    function locked(uint256 tokenId) external view override returns (bool){
        return _lock[tokenId];
    }

    function setLock(uint256 tokenId, bool value) external onlyRole(GAMER_ROLE) {
        _lock[tokenId] = value;
    }

    function mint(address to) public onlyRole(GAMER_ROLE) {
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter += 1;
        _mint(to, tokenId);
    }

    function reservedMint(address to,uint256 tokenId) public onlyRole(GAMER_ROLE) {
        require(!_exists(tokenId) && tokenId < RESERVED_IDS,"Invalid token ID");
        _mint(to,tokenId);
    }

    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);
        _lock[tokenId] = true;
        emit Locked(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override
    {
        require(_lock[tokenId] == false,"NFT locked");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return interfaceId == type(IERC5192).interfaceId || super.supportsInterface(interfaceId);
    }
}