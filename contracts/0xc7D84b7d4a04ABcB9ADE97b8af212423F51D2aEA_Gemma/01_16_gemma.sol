// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./ERC721Sequential.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

/*
                                   .      .
                                  AM      MA
                        A      AMMMM      MMMMA      A
                      AMM   AMMMMMMM      MMMMMMMA   MMA
                    AMMMM   MMMMMMM   AA   MMMMMMM   MMMMA
               A   MMMMM   MMMMAAA   AMMA   AAAMMMM   MMMMM   A
             AMM   MMMMA    A  AAAMMAA  AAMMAAA  A    AMMMM   MMA
            AMMM   MMA    AAMMMAAAA        AAAAMMMAA    AMM   MMMA
         A  MMMMM    AAMMAA                        AAMMAA    MMMMM  A
        MA   MMM  AA              GEMMAGEMMA              AA  MMM   AM
       AMM   MA  AMM         GEMMAGEMMAGEMMAGEMMA         MMA  AM   MMA
       MMMMA   EMM       AMMA                    AMMA       MME   AMMMM
    E   AMMM  MMMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMMM  MMMA   E
    MM    M  MMMAAAAAAAAAAAAAAAAAAAAAMMMMAAAAAAAAAAAAAAAAAAAAAMMM  M    MM
    GMMMA   AMM      MMA             MMMM             AMM      MMA   AMMMG
      MMMM  MMM     AMMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMMA     MMM  MMMM
   A    AM  MMM     AMMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA     MMM  MA    A
    MMAA    AMM      MMA             MMMM                      MMA    AAMM
     AMMMMM  MMM      MMA            MMMM            AAA      MMM  MMMMMA
       AAAMA  MMA      MMA           MMMM           AMM      AMM  AMAAA
     AA        GMM       AMMA        MMMM        AMMA       MMG        AA
       AMMMMMM      A        AAMAAA  MMMM  AAAMAA        A      MMMMMMA
         AAAAAA    EMGA          AA  AAAA  AA          AGME    AAAAAA
                    AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
            AAMMMM                                          MMMMAA
                    AAAAAAAAAAAAAAA        AAAAAAAAAAAAAAA

                    MMMMMMMMMMMMMMM        MMMMMMMMMMMMMMM

                                  G.E.M.M.A.
              The Generative Electronic Museum of Metaverse Art
              5000  generative  art  pieces  by  Tristan  Eaton
              tristaneaton.com  +  +  gemma.art  +  +  0x420.io
 */

contract Gemma is ERC721Sequential, ReentrancyGuard, Ownable, PaymentSplitter {
  using Strings for uint256;
  using ECDSA for bytes32;
  mapping(bytes => uint256) private usedTickets;
  mapping(uint256 => address) private burnedTokens;
  string public baseTokenURI;
  bool public burnActive;
  uint256 public startPresaleDate = 1642021200;
  uint256 public startMintDate = 1642032000;
  uint256 public constant MAX_SUPPLY = 5000;
  uint256 public constant MINT_PRICE = 0.1 ether;
  uint256 public constant MAX_PURCHASE_COUNT = 20;
  uint256 public constant MINTABLE_PRESALE = 4;
  address private presaleSigner;

  constructor(
    uint256 _startPresaleDate,
    uint256 _startMintDate,
    string memory _baseTokenURI,
    address _presaleSigner,
    address[] memory _payees,
    uint256[] memory _shares
  ) ERC721Sequential("GEMMA", "GEMMA") PaymentSplitter(_payees, _shares) {
    startPresaleDate = _startPresaleDate;
    startMintDate = _startMintDate;
    baseTokenURI = _baseTokenURI;
    presaleSigner = _presaleSigner;
  }

  function mint(uint256 numberOfTokens, bytes memory pass)
    public
    payable
    nonReentrant
  {
    if (
      startPresaleDate <= block.timestamp && startMintDate > block.timestamp
    ) {
      uint256 mintablePresale = validateTicket(pass);
      require(numberOfTokens <= mintablePresale, "G: Minting Too Many Presale");
      useTicket(pass, numberOfTokens);
    } else {
      require(startMintDate <= block.timestamp, "G: Sale Not Started");
      require(numberOfTokens <= MAX_PURCHASE_COUNT, "G: Minting Too Many");
    }

    require(totalMinted() + numberOfTokens <= MAX_SUPPLY, "G: Sold Out");

    require(
      msg.value >= numberOfTokens * MINT_PRICE,
      "G: Insufficient Payment"
    );

    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender);
    }
  }

  function artistComps(uint256 numberOfTokens, address to) public onlyOwner {
    require(totalMinted() + numberOfTokens <= MAX_SUPPLY, "G: Sold Out");
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(to);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  function getHash() internal view returns (bytes32) {
    return keccak256(abi.encodePacked("GEMMA", msg.sender));
  }

  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    return hash.toEthSignedMessageHash().recover(signature);
  }

  function validateTicket(bytes memory pass) internal view returns (uint256) {
    bytes32 hash = getHash();
    address signer = recover(hash, pass);
    if (signer != presaleSigner) {
      revert("G: Presale Invalid");
    }
    require(usedTickets[pass] < MINTABLE_PRESALE, "G: Presale Used");
    return MINTABLE_PRESALE - usedTickets[pass];
  }

  function useTicket(bytes memory pass, uint256 quantity) internal {
    usedTickets[pass] += quantity;
  }

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setStartPresaleDate(uint256 _startPresaleDate) external onlyOwner {
    startPresaleDate = _startPresaleDate;
  }

  function setStartMintDate(uint256 _startMintDate) external onlyOwner {
    startMintDate = _startMintDate;
  }

  function setBurningTo(bool _burnActive) external onlyOwner {
    burnActive = _burnActive;
  }

  function burn(uint256 tokenId) external {
    address owner = ERC721Sequential.ownerOf(tokenId);
    require(owner == _msgSender(), "G: Not allowed to burn");
    require(burnActive, "G: Burn inactive");
    burnedTokens[tokenId] = owner;
    _burn(tokenId);
  }

  function burnerOf(uint256 tokenId) external view returns (address) {
    return burnedTokens[tokenId];
  }

  function withdraw(address payable account) public virtual {
    release(account);
  }

  function withdrawERC20(IERC20 token, address to) external onlyOwner {
    token.transfer(to, token.balanceOf(address(this)));
  }
}
/* Development by 0x420.io */