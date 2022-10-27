// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/Parsing.sol";
import "./features/AuthorizableUpgradeable.sol";

contract Collection is ERC721Upgradeable, AuthorizableUpgradeable {
  using StringsUpgradeable for uint256;

  uint256 public supply;
  string public baseTokenURI;

  mapping(uint256 => string) private _tokenURIs;

  event AssetMinted(address to, uint256 id);

  function init(
    string memory _name,
    string memory _symbol,
    string memory _baseTokenURI,
    address _seller,
    uint256 _supply,
    address[] memory _authorized,
    address _owner
  ) public initializer {
    __ERC721_init(_name, _symbol);
    __Ownable_init();
    supply = _supply;
    for (uint256 i = 0; i < _authorized.length; i++) {
      authorize(_authorized[i], true);
    }
    authorize(_seller, true);
    authorize(_owner, true);
    baseTokenURI = _baseTokenURI;
    transferOwnership(_owner);
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return _calculateTokenURI(_tokenId);
  }

  function mintFor(
    address _user,
    uint256 _quantity,
    bytes calldata _mintingBlob
  ) external onlyAuthorized {
    require(_quantity == 1, "Mintable: invalid quantity");
    uint256 id = Parsing.getTokenId(_mintingBlob);
    mint(_user, id);
  }

  function mint(address _user, uint256 _id) public onlyAuthorized {
    _safeMint(_user, _id);
    emit AssetMinted(_user, _id);
  }

  function _calculateTokenURI(uint256 _tokenId)
    internal
    view
    returns (string memory)
  {
    return
      string(abi.encodePacked(baseTokenURI, "/", Strings.toString(_tokenId)));
  }
}