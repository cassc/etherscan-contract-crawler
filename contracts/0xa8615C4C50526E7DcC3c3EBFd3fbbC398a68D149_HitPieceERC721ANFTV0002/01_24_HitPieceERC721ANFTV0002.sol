// SPDX-License-Identifier: MIT
// Creator: HitPiece

pragma solidity ^ 0.8.4;

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721ABurnableUpgradeable.sol";
import "erc721a-upgradeable/contracts/extensions/ERC721AQueryableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./extensions/ERC721ARoyaltyUpgradeable.sol";
import "../extensions/HPApprovedMarketplaceUpgradeable.sol";
import "../extensions/IHPEvent.sol";
import "../extensions/IHPRoles.sol";
import "../extensions/NFTContractMetadataUpgradeable.sol";

// TODO: Add Royalties
// TODO: Add Pausable?

contract HitPieceERC721ANFTV0002 is Initializable, ERC721AUpgradeable, HPApprovedMarketplaceUpgradeable, NFTContractMetadataUpgradeable, ERC721ABurnableUpgradeable, ERC721AQueryableUpgradeable, ERC721ARoyaltyUpgradeable {
  bool private hasInitialized;
  uint256 public maxSupply;

  address public hpEventEmitterAddress;
  address private hpRolesContractAddress;

  string private allTokensURI;

  uint public maxArrayLength;
  
  mapping(uint256 => string) public tokenSpecificURI;

  function initialize(
    address royaltyAddress,
    uint96 feeNumerator,
    string memory tokenName,
    string memory token,
    string memory _contractMetadataURI,
    string memory _allTokensURI,
    address _hpEventEmitterAddress,
    address _hpRolesContractAddress
    ) initializerERC721A initializer public {
      require(hasInitialized == false, "This has already been initialized");
      

      __ERC721A_init(tokenName, token);
      __ERC2981_init();
      __Ownable_init();

      hasInitialized = true;
      hpEventEmitterAddress = _hpEventEmitterAddress;
      _baseContractURI = _contractMetadataURI;
      allTokensURI = _allTokensURI;
      hpRolesContractAddress = _hpRolesContractAddress;

      _setDefaultRoyalty(royaltyAddress, feeNumerator);

      IHPEvent hpEventEmitter = IHPEvent(address(hpEventEmitterAddress));
      hpEventEmitter.setAllowedContracts(address(this));
      hpEventEmitter.emitNftContractInitialized(address(this));

      maxArrayLength = 50;
    }

    function approve(address operator, uint256 tokenId) public override(IERC721AUpgradeable, ERC721AUpgradeable) {
      super.approve(operator, tokenId);

      IHPEvent hpEventEmitter = IHPEvent(address(hpEventEmitterAddress));
      hpEventEmitter.emitApproved(
        address(this),
        operator,
        tokenId
      );
    }

    // ERC2981Upgradeable overrides
  function supportsInterface(bytes4 interfaceId) public view override(IERC721AUpgradeable, ERC721AUpgradeable, ERC721ARoyaltyUpgradeable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function isApprovedForAll(address owner, address operator) override(IERC721AUpgradeable, ERC721AUpgradeable) public view returns (bool) {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    if (hpRoles.isApprovedMarketplace(operator)) {
        return true;
    }
    return ERC721AUpgradeable.isApprovedForAll(owner, operator);
  }

    // Royalties
  function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
    require(hpRoles.isAdmin(msg.sender) == true, "Admin rights required");
    _setTokenRoyalty(tokenId, receiver, feeNumerator);
  }


  // Token URI
  function tokenURI(uint256 tokenId) public view override(IERC721AUpgradeable, ERC721AUpgradeable) returns (string memory) {
    if (bytes(tokenSpecificURI[tokenId]).length > 0) {
      return tokenSpecificURI[tokenId];
    }

    if (bytes(allTokensURI).length > 0) {
      return allTokensURI;
    }
    return super.tokenURI(tokenId);
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
    tokenSpecificURI[tokenId] = _tokenURI;
  }

  function setAllTokensURI(string memory _tokensURI) public onlyOwner{
    allTokensURI = _tokensURI;
  }

  function burn(uint256 tokenId) override public {
    require(msg.sender == ownerOf(tokenId), "You must be the owner to burn token");
    _burn(tokenId);
  }

  // Burn
  function _burn(uint256 tokenId) internal override(ERC721AUpgradeable, ERC721ARoyaltyUpgradeable) {
    ERC721AUpgradeable._burn(tokenId);
    ERC721ARoyaltyUpgradeable._burn(tokenId);
  }

  // Limit
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function adminMint(address to, uint256 quantity) external {
    IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));

    require(hpRoles.isAdmin(msg.sender), "Ownable: caller is not the admin");
    _mint(to, quantity);
  }

  // Transfer
    function transferFrom(address from, address to, uint256 tokenId) public override(IERC721AUpgradeable, ERC721AUpgradeable) {
      super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(IERC721AUpgradeable, ERC721AUpgradeable) {
      super.safeTransferFrom(from, to, tokenId);
    }

    function sendNft(address[] memory _to, uint256[] memory _id) public {
      IHPRoles hpRoles = IHPRoles(address(hpRolesContractAddress));
      require(hpRoles.isAdmin(msg.sender) == true, "Admin rights required");
      require(_to.length <= maxArrayLength,"array length limit higher than expected");
      require(_to.length == _id.length,"array length doesn't match");
      

      for (uint8 i = 0; i < _to.length; i++){
          safeTransferFrom(msg.sender,_to[i],_id[i]);
      }
    }

}