// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721URIStorage.sol";

error AdminSameAsDeployer();
error Unauthorized();
error AlreadyExists(string sha);
error IncorrectMintPrice(uint256 required, uint256 sent);
error NotEnoughFunds(uint256 current, uint256 minimum);

contract XPFP is ERC721, ERC721URIStorage {
  uint256 private _tokenIds = 0;
  uint256 public mintPrice;
  address public secondAdmin;

  mapping(string => bool) private _hashes;
  uint256 public immutable deployedTimestamp = block.timestamp;
  uint256 public immutable deployedBlock = block.number;
  address public immutable deployerAddress = msg.sender;
  uint256 public totalWithdrawnFunds = 0;

  event BurntByRequest(uint256 indexed tokenId);
  event Minted(uint256 indexed tokenId, address indexed to, string uri);
  event MintPriceChanged(
    address indexed admin,
    uint256 indexed oldPrice,
    uint256 indexed newPrice
  );
  event FundsWithdrawn(
    uint256 indexed amount,
    address indexed admin1,
    address indexed admin2
  );

  modifier onlyAdmins() {
    if (msg.sender != deployerAddress && msg.sender != secondAdmin) {
      revert Unauthorized();
    }
    _;
  }

  constructor(
    uint256 _mintPrice,
    address _secondAdmin
  ) ERC721("XPFPs", "XPFP") {
    if (secondAdmin == msg.sender) {
      revert AdminSameAsDeployer();
    }
    mintPrice = _mintPrice;
    secondAdmin = _secondAdmin;
  }

  function mint(
    string memory sha,
    string memory uri
  ) public payable returns (uint256) {
    if (_hashes[sha]) {
      revert AlreadyExists({sha: sha});
    }
    if (msg.value != mintPrice) {
      revert IncorrectMintPrice({required: mintPrice, sent: msg.value});
    }

    address toAddress = msg.sender;
    uint256 tokenId = _tokenIds;

    _safeMint(toAddress, tokenId);
    _setTokenURI(tokenId, uri);
    _hashes[sha] = true;

    emit Minted(tokenId, toAddress, uri);

    _tokenIds += 1;

    return tokenId;
  }

  function exists(string memory sha) public view returns (bool) {
    return _hashes[sha];
  }

  function totalSupply() public view returns (uint256) {
    return _tokenIds;
  }

  // Admins methods

  function resetByHash(string memory sha) public onlyAdmins {
    _hashes[sha] = false;
  }

  function setMintPrice(uint256 newMintPrice) public onlyAdmins {
    emit MintPriceChanged(msg.sender, mintPrice, newMintPrice);

    mintPrice = newMintPrice;
  }

  function withdrawFunds() public onlyAdmins {
    uint256 balance = address(this).balance;

    if (balance < 0.1 ether) {
      revert NotEnoughFunds({current: balance, minimum: 0.1 ether});
    }

    uint256 half = balance / 2;

    payable(deployerAddress).transfer(half);
    payable(secondAdmin).transfer(half);

    totalWithdrawnFunds += balance;

    emit FundsWithdrawn(balance, deployerAddress, secondAdmin);
  }

  function burn(uint256 id) public onlyAdmins {
    emit BurntByRequest(id);
    _burn(id);
  }

  function burnMany(uint256[] memory ids) public onlyAdmins {
    for (uint i = 0; i < ids.length; i++) {
      uint256 id = ids[i];

      burn(id);
    }
  }

  // The following functions are overrides required by Solidity.

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function tokenURI(
    uint256 tokenId
  ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
    return super.tokenURI(tokenId);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) public view override(ERC721, ERC721URIStorage) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}