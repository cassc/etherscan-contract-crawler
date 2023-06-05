// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title IcyNFT contract
 * @author @icy_tools
 * https://club.icy.tools
 */

interface IIcyRegister {
  function isAddressRegistered(address _account) external view returns (bool);
}

contract IcyNFT is ERC721Burnable, ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;
  using SafeMath for uint256;

  // Events
  event Claim(address indexed _address);

  Counters.Counter private _tokenIdTracker;

  // 1700 Max Supply (set on contract deployment)
  uint256 public maxSupply;

  address private _icyRegisterAddress;
  string private _baseTokenURI;
  string private _contractURI;

  // 30 reserved for promotional purposes (i.e giveaways & contests).
  // Etherscan txn will be provided in discord (icy.community).
  uint256 public icyReserve = 30;
  // Reserve can only be minted once.
  bool public hasMintedReserve = false;

  // Enable/disable claim
  bool public isClaimActive = false;

  mapping(address => bool) private hasClaimed;

  // Construct with a name, symbol, max supply, and base token URI.
  constructor(
    string memory name,
    string memory symbol,
    uint256 _maxSupply,
    string memory baseTokenURI
  ) ERC721(name, symbol) {
    maxSupply = _maxSupply;
    _baseTokenURI = baseTokenURI;
    // Sets token ID to start at '1' for UX.
    _tokenIdTracker.increment();
  }

  function _baseURI() internal view override returns (string memory) {
    return _baseTokenURI;
  }

  function baseURI() public view returns (string memory) {
    return _baseURI();
  }

  function icyRegisterAddress() public view returns (address) {
    return _icyRegisterAddress;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  // See {IERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  // Check if an address is eligible to claim NFT
  function canClaim(address _address) public view returns (bool) {
    return
      IIcyRegister(_icyRegisterAddress).isAddressRegistered(_address) &&
      !hasClaimed[_address];
  }

  // Claim IcyNFT
  function claim() external nonReentrant {
    require(isClaimActive == true, "Claim is not active");
    address _claimer = _msgSender();

    bool _canClaim = canClaim(_claimer);
    require(_canClaim == true, "Not eligible to claim");

    uint256 _totalSupply = totalSupply();
    uint256 total = _totalSupply.add(1);
    require(total <= maxSupply, "Claim would exceed max supply");

    hasClaimed[_claimer] = true;
    _safeMint(_msgSender(), _tokenIdTracker.current());
    _tokenIdTracker.increment();

    emit Claim(_claimer);
  }

  /*
   *   ADMIN FUNCTIONS
   */

  // Allows `owner` to toggle if claiming is active
  function toggleIsClaimActive() external nonReentrant onlyOwner {
    isClaimActive = !isClaimActive;
  }

  // Just in case...
  function withdraw() external nonReentrant onlyOwner {
    address owner = _msgSender();
    uint256 balance = address(this).balance;
    payable(owner).transfer(balance);
  }

  // Ability to change the URI. i.e self hosted api -> ipfs
  function setBaseURI(string memory _newBaseURI)
    external
    nonReentrant
    onlyOwner
  {
    _baseTokenURI = _newBaseURI;
  }

  // Ability to change the contractURI. i.e self hosted api -> ipfs
  function setContractURI(string memory _newContractURI)
    external
    nonReentrant
    onlyOwner
  {
    _contractURI = _newContractURI;
  }

  // Set the OG IcyRegister Contract
  function setIcyRegisterAddress(address _newIcyRegisterAddress)
    external
    nonReentrant
    onlyOwner
  {
    _icyRegisterAddress = _newIcyRegisterAddress;
  }

  // 30 reserved for promotional purposes (i.e giveaways & contests).
  // Etherscan txns will be provided in discord (icy.community).
  function mintReserve() external nonReentrant onlyOwner {
    require(hasMintedReserve == false, "Has already claimed reserve");
    uint256 _totalSupply = totalSupply();
    uint256 total = _totalSupply.add(icyReserve);
    require(total <= maxSupply, "Claim would exceed max supply");

    for (uint256 i = 0; i < icyReserve; i++) {
      if (totalSupply() <= maxSupply) {
        _safeMint(_msgSender(), _tokenIdTracker.current());
        _tokenIdTracker.increment();
      }
    }
    hasMintedReserve = true;
  }
}