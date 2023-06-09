// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "ERC721.sol";
import "AccessControl.sol";
import "Address.sol";
import "Ownable.sol";
import "IERC721A.sol";

error Soulbound(uint256 tokenId);
error CantApprove();
error AlreadyMinted(uint256 tokenId);
error NotOwnerOfToken(uint256 tokenId);

contract SoulboundFoundersKey is ERC721, Ownable, AccessControl {
    using Address for address;
    IERC721A public FoundersKeysAddress;
    bytes32 public constant STAKING_CONTRACT_ROLE = keccak256("STAKING_CONTRACT");

    event Minted(uint256 tokenId, address owner);
    event Burned(uint256 tokenId);
    constructor(address _foundersKeysAddress) ERC721("Soulbound Naffles Founders Keys", "SBNFLS") {
      FoundersKeysAddress = IERC721A(_foundersKeysAddress);

      _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function safeMint(address _to, uint256 _tokenId) public onlyRole(STAKING_CONTRACT_ROLE) {
      if (FoundersKeysAddress.ownerOf(_tokenId) != _to) {
        revert NotOwnerOfToken(_tokenId);
      }
      _safeMint(_to, _tokenId);

      emit Minted(_tokenId, _to);
    }

    function burn(uint256 _tokenId) external onlyRole(STAKING_CONTRACT_ROLE) {
      _burn(_tokenId);

      emit Burned(_tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
      internal
      virtual
      override(ERC721)
    {
      if(from != address(0) && to != address(0)) {
        revert Soulbound(tokenId);
      }
      super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        revert CantApprove();
    }

    function approve(address operator, uint256 tokenId) public override {
        revert CantApprove();
    }

    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
      return FoundersKeysAddress.tokenURI(tokenId);
    }

    function setFoundersKeysAddress(address _foundersKeysAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
      FoundersKeysAddress = IERC721A(_foundersKeysAddress);
    }

    function supportsInterface(bytes4 _interfaceId)
      public
      view
      virtual
      override(ERC721, AccessControl)
      returns (bool)
    {
        return (ERC721.supportsInterface(_interfaceId) ||
        AccessControl.supportsInterface(_interfaceId));
    }
}