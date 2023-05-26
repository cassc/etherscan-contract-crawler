// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface DogcInterface {
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface DogcSerumInterface {
  function balanceOf(address account, uint256 id)
    external
    view
    returns (uint256);

  function isApprovedForAll(address account, address operator)
    external
    view
    returns (bool);

  function burn(
    address account,
    uint256 id,
    uint256 value
  ) external;
}

contract MutantDoge is ERC721, Ownable, ReentrancyGuard {
  uint256[3] public price = [0, 0, 0]; // free mint by default
  uint256 megaPrice = 0;
  // max supply
  uint256 public maxSupply = 10000;
  uint256[3] public MUTATION_OFFSET = [0, 10000, 20000];
  uint256 public megaTokenId = 30000;

  mapping(uint8 => bool) public mintState;

  uint256[3] public totalSupply = [0, 0, 0];

  DogcSerumInterface public serum;
  DogcInterface public dogc;

  string public baseURI;
  event SetBaseURI(string indexed _baseURI);

  constructor(address _serum, address _dogc) ERC721("Mutant Doge", "MDOG") {
    serum = DogcSerumInterface(_serum);
    dogc = DogcInterface(_dogc);
    mintState[0] = false;
    mintState[1] = false;
    mintState[2] = false;
    mintState[3] = false;
  }

  function contractURI() public pure returns (string memory) {
    return
      "https://ipfs.filebase.io/ipfs/QmY1xSQyRiD8erkHDNjgMHrmKq9kpCnu9CYBK99sNXExrL";
  }

  function updateSerumAddress(address _serum) external onlyOwner {
    serum = DogcSerumInterface(_serum);
  }

  function flipMintState(uint8 _serumType) external onlyOwner {
    mintState[_serumType] = !mintState[_serumType];
  }

  function mintBatch(uint256[] memory _tokenIds, uint8 _type)
    external
    payable
    nonReentrant
  {
    require(_type >= 0 && _type <= 2, "Invalid serum type");
    require(mintState[_type], "Mint haven't started");
    require(
      msg.value >= price[_type] * _tokenIds.length,
      "Insufficient payment"
    );
    require(
      totalSupply[_type] + _tokenIds.length <= maxSupply,
      "Insufficient remains"
    );
    require(
      serum.balanceOf(msg.sender, _type) >= _tokenIds.length,
      "Insufficient serum token"
    );
    require(
      serum.isApprovedForAll(msg.sender, address(this)),
      "Haven't approve"
    );

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      if (dogc.ownerOf(_tokenIds[i]) == msg.sender) {
        totalSupply[_type] = totalSupply[_type] + 1;
        serum.burn(msg.sender, _type, 1);
        _safeMint(msg.sender, _tokenIds[i] + MUTATION_OFFSET[_type]);
      }
    }
  }

  function mintMega() external payable nonReentrant {
    require(mintState[3], "Mint haven't started");
    require(msg.value >= megaPrice, "Insufficient payment");
    require(
      serum.isApprovedForAll(msg.sender, address(this)),
      "Haven't approve"
    );
    require(serum.balanceOf(msg.sender, 3) >= 1, "Insufficient serum token");

    serum.burn(msg.sender, 3, 1);
    _safeMint(msg.sender, megaTokenId);
    megaTokenId = megaTokenId + 1;
  }

  function setBaseURI(string memory _baseuri) external onlyOwner {
    baseURI = _baseuri;
    emit SetBaseURI(baseURI);
  }

  function _baseURI()
    internal
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    return baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  // rescue
  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawToken(address _tokenContract) external onlyOwner {
    IERC20 tokenContract = IERC20(_tokenContract);

    bool success = tokenContract.transfer(
      msg.sender,
      tokenContract.balanceOf(address(this))
    );
    require(success, "Transfer failed.");
  }
}