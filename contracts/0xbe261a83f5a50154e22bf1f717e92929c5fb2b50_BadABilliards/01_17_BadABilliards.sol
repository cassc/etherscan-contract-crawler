// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {DefaultOperatorFilterer721, OperatorFilterer721} from "./DefaultOperatorFilterer721.sol";

/*
*                                                                            .
*                                                              ..       ... ...      .
*                                                           ...............   ... .      .   .
*                                           . ..    .  . .................  ....... .. . .... ..
*                                          ....     . . .... .............   . .... .   ... ... .
*                                      ........  ..  .......  ..... ....   ....... .. ....... .
*                              . ...... ......... ..........  ..........  ...............  ..  .
*                              ... ..... ...... ....... ...   ... .....  ..............  ...  ..
*                        .   ..............................   ........   ...........   ....
*                     . .. .......... ...........  ..... ..   ..... .   .........    ....
*                       ................ ..... ....   .....    .....   ........    .....
*                      ..................  .... ...     ...   ....   .......   ...... .  .
*                    . ....... ..........  .. .. ...           .  ..  ....     ...... . ...
*                       ........   ....                           ..  .  .   ... .  .
*                      .........                 ...               ..       .  ... ..
*              .  .     .....             .........                          . ... .
*                       ...           ......  .............                 .... .
*           .   . . .. .  .         ..... ...................                  . .
*                  ........    .  .............................               .... ..
*                . ......     . .................................           ........ ..
*                   .. .    .. ......................................     ........... .. .
*               .  .....   .. ........................................................... .
*                 . ..... ... ..............................................................
*              . .. .  .  ...................................................................
*                . .. .. .....................................................................
*                . .  .. ...........................................................    .... ..
*             .  ..  ... ........................................................        .... .
*                    ... .......................................       .........         ......
*                    .... ....................................         .........         .... .
*                     ........................................         .........       ........
*                 .   .......................................         ...........    ........ .
*                      .......................................       ..................... . .
*                  .    ...............................................              ....... .
*                   .    ..........................................       .......     .......
*                    .    .......................................            ....      .....
*                          ......................................          ....      .....
*                       .    ....................................        ....       .....
*                         .    ..................................      ....       .....
*                           .     ... .............................              ..
*                              .     .... ................................  .......
*                                         ....  ..............................
*                                      .        ..................      ...
*/

contract BadABilliards is ERC721A, DefaultOperatorFilterer721, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => bool) public whitelistClaimed;
  mapping(address => bool) public mintClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;

  address[] public whitelistAddresses;

  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = true;
  bool public limitClaimsPerWallet = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    address[] memory _whitelistAddresses
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost = _cost;
    maxSupply = _maxSupply;
    maxMintAmountPerTx = _maxMintAmountPerTx;
    whitelistAddresses = _whitelistAddresses;
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
  {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(!paused, 'The contract is paused!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(isWhitelisted(_msgSender()), 'Not whitelisted!');
    if (limitClaimsPerWallet) {
      require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
      whitelistClaimed[_msgSender()] = true;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!whitelistMintEnabled, 'The whitelist sale is enabled!');
    if (limitClaimsPerWallet) {
      require(!mintClaimed[_msgSender()], 'Address already claimed!');
      mintClaimed[_msgSender()] = true;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function airDrop(uint256 _mintAmount, address[] calldata _receivers) public mintCompliance(_mintAmount) onlyOwner {
    for (uint256 i = 0; i < _receivers.length; i++) {
      _safeMint(_receivers[i], _mintAmount);
    }
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = _startTokenId();
    uint256 ownedTokenIndex = 0;
    address latestOwnerAddress;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      TokenOwnership memory ownership = _ownerships[currentTokenId];
      if (!ownership.burned && ownership.addr != address(0)) {
        latestOwnerAddress = ownership.addr;
      }
      if (latestOwnerAddress == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
    : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function isWhitelisted(address _user) public view returns (bool) {
    for(uint256 i = 0; i < whitelistAddresses.length; i++ ) {
      if(whitelistAddresses[i] == _user) {
        return true;
      }
    }
    return false;
  }

  function addToWhitelist(address[] memory _users) public onlyOwner {
    for(uint256 i = 0; i < _users.length; i++ ) {
      whitelistAddresses.push(_users[i]);
    }
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setLimitClaimsPerWallet(bool _state) public onlyOwner {
    limitClaimsPerWallet = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}