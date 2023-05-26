//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IThingiesArtNFT.sol";

contract ThingiesArt is ReentrancyGuard, Ownable {
  using ECDSA for bytes32;
  IERC721 public thingies;
  IThingiesArtNFT public thingiesArtNft;
  string public tokenUriBase;
  address public signer;
  bool public MINTING_ENABLED = false;
  mapping(uint256 => mapping(uint256 => bool)) public mintedArt;

  event ArtMinted(uint256 indexed thingieTokenId, uint256 indexed nonce, uint256 indexed artTokenId);
  event ThingieNFTUpdated(address indexed _address);
  event ThingieUpdated(address indexed _address);
  event SignerUpdated(address indexed _address);
  event EnabledUpdated(bool indexed _state);

  constructor(
    IERC721 _thingies,
    IThingiesArtNFT _thingiesArtNft,
    address _signer
  ) {
    thingies = _thingies;
    thingiesArtNft = _thingiesArtNft;
    signer = _signer;
  }

  modifier noContract() {
    require(msg.sender == tx.origin, "Contract not allowed");
    _;
  }

  /* @dev: Update Thingie Art NFT location
   * @param: _address - Thingie NFT contract address
   */
  function setThingiesArtNft(IThingiesArtNFT _address) external onlyOwner {
    thingiesArtNft = _address;
    emit ThingieNFTUpdated({_address: address(_address)});
  }

  /* @dev: Update Thingie location
   * @param: _address - Thingie contract address
   */
  function setThingiesAddress(IERC721 _address) external onlyOwner {
    thingies = _address;
    emit ThingieUpdated({_address: address(_address)});
  }

  /* @dev: Update signer
   * @param: _sign - New signer to make use of
   */
  function setSigner(address _signer) external onlyOwner {
    signer = _signer;
    emit SignerUpdated({_address: _signer});
  }

  /* @dev: Halts or resumes the minting process
   * @param: _bool - Enable or Disable true/false
   */
  function setEnabled(bool _bool) external onlyOwner {
    MINTING_ENABLED = _bool;
    emit EnabledUpdated({_state: _bool});
  }

  function _verify(
    bytes calldata _encoded,
    bytes calldata _signature,
    address _signer
  ) public pure returns (bool) {
    return keccak256(_encoded).toEthSignedMessageHash().recover(_signature) == _signer;
  }

  /* @dev: Mints the Art to the msg.sender
   * @param: encoded - Encoded ABI of tokenId nonce and the deadline of the
   * @param: _signature - A signature from the signer
   */
  function mintArt(bytes calldata _encoded, bytes calldata _signature) external nonReentrant noContract {
    require(MINTING_ENABLED, "Minting not open");
    (uint256 tokenId, uint256 nonce, uint256 deadline) = abi.decode(_encoded, (uint256, uint256, uint256));
    require(_verify(_encoded, _signature, signer), "Invalid signature");
    require(thingies.ownerOf(tokenId) == msg.sender, "Not your thingie");
    require(deadline >= block.timestamp, "This signature is expired");
    require(!mintedArt[tokenId][nonce], "Already minted");

    mintedArt[tokenId][nonce] = true;

    thingiesArtNft.mint(msg.sender, 1);

    emit ArtMinted({thingieTokenId: tokenId, nonce: nonce, artTokenId: thingiesArtNft.totalSupply() - 1});
  }
}