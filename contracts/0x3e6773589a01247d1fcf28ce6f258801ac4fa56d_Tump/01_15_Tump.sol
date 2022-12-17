// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "openzeppelin-contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Strings.sol";
import "./Base64.sol";

contract Tump is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string DESCRIPTION =
    "Attention all MAGA fans! Are you tired of boring old campaign posters and hats to show off your love for Donald Tump? Well, we've got the solution for you: the Donald Tump NFT Collection! These one-of-a-kind digital tokens are the ultimate way to show your support for the 45th President of the United States, whether you're a member of the alt-right or just a proud member of the Covfefe Nation.\\n\\nFeaturing high-resolution artwork of the President in all his regal splendor, these NFTs capture the essence of Tump in all his glory - from his iconic hairstyle to his signature red tie. And with a limited edition run, you'll want to act fast to get your hands on one of these rare collectibles.\\n\\nSo why wait? Add a Tump NFT to your collection today and become the envy of all your friends (and enemies). Make America Great Again!";
  string BASE_URI;
  uint currentId;

  constructor(string memory uri) ERC721("TUMP!", "TUMP") Ownable() {
    BASE_URI = uri;
    for (uint i = 0; i < 20; i++) {
      _mint(msg.sender, ++currentId);
    }
  }

  function setBaseUri(string memory uri) public onlyOwner {
    BASE_URI = uri;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BASE_URI;
  }

  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string(
                abi.encodePacked(
                  '{"name":"TUMP!",',
                  '"image":"',
                  baseURI,
                  tokenId.toString(),
                  ".png",
                  '",',
                  '"description":"',
                  DESCRIPTION,
                  '"}'
                )
              )
            )
          )
        )
      );
  }

  error MaxMintExceeded();
  error InvalidMintAmount();
  error MintedOut();

  mapping(address => uint) amountMinted;

  function mint(uint amount) public {
    if (currentId == 162) {
      revert MintedOut();
    }
    if (currentId + amount > 162) {
      revert InvalidMintAmount();
    }
    if (amount > 2) {
      revert MaxMintExceeded();
    }
    if (amountMinted[msg.sender] + amount > 2) {
      revert InvalidMintAmount();
    }

    amountMinted[msg.sender] += amount;

    for (uint i = 0; i < amount; i++) {
      _mint(msg.sender, ++currentId);
    }
  }
}