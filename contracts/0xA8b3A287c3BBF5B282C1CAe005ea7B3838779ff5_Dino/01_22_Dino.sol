// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./IDino.sol";

contract Dino is IDino, ERC721AQueryable, PaymentSplitter, Ownable, DefaultOperatorFilterer {
  using Strings for uint256;

  MintRules public mintRules;

  string public baseTokenURI;

  uint256 public constant CHECKPOINT_TIME = 8 hours;

  bytes32 private _root;
  uint8 private _finalPhase;
  bool _revealed;

  mapping(uint256 => uint256) private _tokenPhases;
  mapping(Rarity => string[5]) private _rarityTraits;

  constructor(
    address[] memory _payees,
    uint256[] memory _shares
  ) ERC721A("XZZ", "XZZ") PaymentSplitter(_payees, _shares) {}

  /*//////////////////////////////////////////////////////////////
                         Public getters
  //////////////////////////////////////////////////////////////*/

  function totalMinted() external view returns (uint256) {
    return _totalMinted();
  }

  function numberMinted(address _owner) external view returns (uint256) {
    return _numberMinted(_owner);
  }

  function nonFreeAmount(address _owner, uint256 _amount, uint256 _freeAmount) external view returns (uint256) {
    return _calculateNonFreeAmount(_owner, _amount, _freeAmount);
  }

  function rarityOf(uint256 _tokenId) external pure returns (Rarity) {
    return _tokenRarity(_tokenId);
  }

  function phaseOf(uint256 _tokenId) external view returns (uint256) {
    return _tokenPhase(_tokenId);
  }

  function traitOf(uint256 _tokenId) external view returns (string memory) {
    return _tokenTrait(_tokenId);
  }

  /*//////////////////////////////////////////////////////////////
                         Minting functions
  //////////////////////////////////////////////////////////////*/

  function whitelistMint(uint256 _amount, bytes32[] memory _proof) external payable {
    _verify(_proof);

    uint256 _nonFreeAmount = _calculateNonFreeAmount(msg.sender, _amount, mintRules.whitelistFreePerWallet);

    if (_nonFreeAmount != 0 && msg.value < mintRules.whitelistPrice * _nonFreeAmount) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _amount > mintRules.whitelistMaxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _amount);
  }

  function mint(uint256 _amount) external payable {
    uint256 _nonFreeAmount = _calculateNonFreeAmount(msg.sender, _amount, mintRules.freePerWallet);

    if (_nonFreeAmount != 0 && msg.value < mintRules.price * _nonFreeAmount) {
      revert InvalidEtherValue();
    }

    if (_numberMinted(msg.sender) + _amount > mintRules.maxPerWallet) {
      revert MaxPerWalletOverflow();
    }

    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(msg.sender, _amount);
  }

  function burn(uint256 _tokenId) external {
    if (_tokenPhase(_tokenId) < _finalPhase) {
      revert InvalidBurnPhase();
    }

    _burn(_tokenId, true);
  }

  /*//////////////////////////////////////////////////////////////
                          Owner functions
  //////////////////////////////////////////////////////////////*/

  function setBaseURI(string memory _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  function setMintRules(MintRules memory _mintRules) external onlyOwner {
    mintRules = _mintRules;
  }

  function airdrop(address _to, uint256 _amount) external onlyOwner {
    if (_totalMinted() + _amount > mintRules.totalSupply) {
      revert TotalSupplyOverflow();
    }

    _safeMint(_to, _amount);
  }

  function setRoot(bytes32 _newRoot) external onlyOwner {
    _root = _newRoot;
  }

  function setFinalPhase(uint8 _phase) external onlyOwner {
    _finalPhase = _phase;
  }

  function setRarityTraits(Rarity _rarity, string[5] memory _traits) external onlyOwner {
    _rarityTraits[_rarity] = _traits;
  }

  function setRaritiesTraits(string[5][6] memory _traits) external onlyOwner {
    for (uint8 i = 0; i < 6; ) {
      _rarityTraits[Rarity(i)] = _traits[i];
      unchecked {
        ++i;
      }
    }
  }

  function setRevealed(bool _value) external onlyOwner {
    _revealed = _value;
  }

  /*//////////////////////////////////////////////////////////////
                         Internal functions
  //////////////////////////////////////////////////////////////*/

  function _calculateNonFreeAmount(
    address _owner,
    uint256 _amount,
    uint256 _freeAmount
  ) internal view returns (uint256) {
    uint256 _freeAmountLeft = _numberMinted(_owner) >= _freeAmount ? 0 : _freeAmount - _numberMinted(_owner);

    return _freeAmountLeft >= _amount ? 0 : _amount - _freeAmountLeft;
  }

  function _verify(bytes32[] memory _proof) private view {
    bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(msg.sender))));

    if (!MerkleProof.verify(_proof, _root, leaf)) {
      revert InvalidProof();
    }
  }

  function _tokenRarity(uint256 _tokenId) internal pure returns (Rarity) {
    uint256 _random = uint256(keccak256(abi.encodePacked(_tokenId))) % 100;

    if (_random < _rarityDistribution(Rarity.COMMON)) {
      return Rarity.COMMON;
    } else if (_random < _rarityDistribution(Rarity.COMMON) + _rarityDistribution(Rarity.UNCOMMON)) {
      return Rarity.UNCOMMON;
    } else if (
      _random <
      _rarityDistribution(Rarity.COMMON) + _rarityDistribution(Rarity.UNCOMMON) + _rarityDistribution(Rarity.RARE)
    ) {
      return Rarity.RARE;
    } else if (
      _random <
      _rarityDistribution(Rarity.COMMON) +
        _rarityDistribution(Rarity.UNCOMMON) +
        _rarityDistribution(Rarity.RARE) +
        _rarityDistribution(Rarity.MYTHICAL)
    ) {
      return Rarity.MYTHICAL;
    } else if (
      _random <
      _rarityDistribution(Rarity.COMMON) +
        _rarityDistribution(Rarity.UNCOMMON) +
        _rarityDistribution(Rarity.RARE) +
        _rarityDistribution(Rarity.MYTHICAL) +
        _rarityDistribution(Rarity.EPIC)
    ) {
      return Rarity.EPIC;
    } else {
      return Rarity.LEGENDARY;
    }
  }

  function _tokenTrait(uint256 _tokenId) internal view returns (string memory) {
    Rarity _rarity = _tokenRarity(_tokenId);
    uint256 _random = uint256(keccak256(abi.encodePacked(_tokenId))) % (_rarityTraits[_rarity].length - 1);
    return _rarityTraits[_rarity][_random];
  }

  function _tokenImageURI(uint256 _tokenId) internal view returns (string memory) {
    uint256 _phase = _tokenPhase(_tokenId);

    return string(abi.encodePacked(baseTokenURI, _phase.toString(), "/", _tokenTrait(_tokenId), ".gif"));
  }

  function _tokenAnimationURI(uint256 _tokenId) internal view returns (string memory) {
    if (_tokenPhase(_tokenId) == _finalPhase) {
      return "";
    }

    TokenOwnership memory _tokenOwnership = _ownershipOf(_tokenId);
    uint256 _timestamp = _tokenOwnership.startTimestamp - _tokenPhases[_tokenId] * CHECKPOINT_TIME;
    string memory _imageURI = _tokenImageURI(_tokenId);
    bytes memory _dataURI = abi.encodePacked(
      '<html><head><link rel=preconnect href=https://fonts.googleapis.com><link rel=preconnect href=https://fonts.gstatic.com crossorigin><link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel=stylesheet><style>body{padding:0;margin:0;image-rendering:pixelated;font-family:"Press Start 2P",cursive;color:#fff}img{width:100%;object-fit:contain;object-position:top}#age{position:absolute;left:0;right:0;padding:20px;padding-top:40px;font-size:5.5vmin;letter-spacing:-1px;text-align:center;line-height:1.25}</style></head><body><div id=age></div>',
      '<img src="',
      _imageURI,
      '"/>',
      "<script>const TIMESTAMP=",
      _timestamp.toString(),
      'e3,age=document.getElementById("age");function pad(e){return e.toString().padStart(2,"0")}function getTimeDifference(e,t){const n=t-e,a=Math.floor(n/864e5),o=Math.floor(n%864e5/36e5),r=Math.floor(n%36e5/6e4),f=Math.floor(n%6e4/1e3);return`${pad(a)}d ${pad(o)}h ${pad(r)}m ${pad(f)}s`}age.textContent=getTimeDifference(TIMESTAMP,Date.now()),setInterval((()=>{age.textContent=getTimeDifference(TIMESTAMP,Date.now())}),1e3)</script></body></html>'
    );

    return string(abi.encodePacked("data:text/html;base64,", Base64.encode(_dataURI)));
  }

  function _tokenPhase(uint256 _tokenId) internal view returns (uint256 _phase) {
    TokenOwnership memory _tokenOwnership = _ownershipOf(_tokenId);

    _phase = _tokenPhases[_tokenId] + (block.timestamp - _tokenOwnership.startTimestamp) / CHECKPOINT_TIME;

    if (_phase > _finalPhase) {
      _phase = _finalPhase;
    }
  }

  function _rarityDistribution(Rarity _rarity) internal pure returns (uint256) {
    if (_rarity == Rarity.COMMON) {
      return 38;
    } else if (_rarity == Rarity.UNCOMMON) {
      return 28;
    } else if (_rarity == Rarity.RARE) {
      return 18;
    } else if (_rarity == Rarity.MYTHICAL) {
      return 9;
    } else if (_rarity == Rarity.EPIC) {
      return 5;
    } else {
      return 2;
    }
  }

  /*//////////////////////////////////////////////////////////////
                          Overriden ERC721A
  //////////////////////////////////////////////////////////////*/

  function _baseURI() internal view override returns (string memory) {
    return baseTokenURI;
  }

  function tokenURI(uint256 _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
    if (_revealed) {
      return super.tokenURI(_tokenId);
    }

    bytes memory _dataURI = abi.encodePacked(
      "{",
      '"name": "',
      symbol(),
      " #",
      _tokenId.toString(),
      '",',
      '"image": "',
      _tokenImageURI(_tokenId),
      '",',
      '"animation_url": "',
      _tokenAnimationURI(_tokenId),
      '",',
      '"attributes": [{"trait_type": "Egg", "value": "',
      _tokenTrait(_tokenId),
      '"}]',
      "}"
    );
    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(_dataURI)));
  }

  function _beforeTokenTransfers(address _from, address _to, uint256 _tokenId, uint256) internal virtual override {
    if (_from == address(0) || _to == address(0)) return;

    _tokenPhases[_tokenId] = _tokenPhase(_tokenId);
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  /*//////////////////////////////////////////////////////////////
                        DefaultOperatorFilterer
  //////////////////////////////////////////////////////////////*/

  function setApprovalForAll(
    address operator,
    bool approved
  ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(
    address operator,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}