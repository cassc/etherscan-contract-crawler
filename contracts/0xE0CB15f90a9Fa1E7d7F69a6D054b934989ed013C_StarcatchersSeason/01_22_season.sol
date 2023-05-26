/*
                                                   ,/(######(,
                                              /################*
                                         ,/###%####(*#//,
                                     ,########/*
                                   (%%%%#,             ./(##################(*.
                                 #%*           .(#%%%%###########%######%#####.
                                         ,#%%%%%%%%%%%%%%###(########//##(##/,
                                    .(#%%%%%%%#%%/..
                                ./(%%%%%%#*.
                             .###%%%#.
                           *####/.
                         *#/.

                                   #%%%%%%%%%%(      .%%%%%%%(   %%*     *##*
                    .#%%#        #%%#.  .. .(%%(    #%%#*.....   #%%,    %%#
                   #%%%%#        %%%,       (#%*    *%%/          %%%   #%%*
                 /%%%%%%#                  ,#%#     /%%*          ,%%# ,%%#
               /%%%/ %%%%                 #%%#      (%%*           /%%%%%%/
             ,%%%(   %%%%               .#%%,       /%%*            #%%%%%
            #%%%/    %%%#  (#%###/     *%%#         ,%%%%##((*       %%%%*
          /%%%%%%%%%%%%%#             (%%*          ,%%%%/,,,,.      /%%%,
        ,#%%%#      .(%%#           .#%%            *%%,             #%%%%
      .(%%%%/        #%%*          *%%#              %%             /%%%%%(
    .#%%%#.          /#(,         #%%/               #%.           .###*%%%*
   #%%##,            /#(,        #%%#*,,,*,,,,*.     ##,           *###  (%%*
 .#%%%#              *#/*        #%%%%%%%%%%%%%#.    ##%###(,...  .###,  .#%%*
                                                      ,########,  /((/    .%%%.
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';
import '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import './StarcatchersInterface.sol';

contract StarcatchersSeason is ERC1155, Ownable, ERC1155Burnable, VRFConsumerBaseV2, ReentrancyGuard {
  using Address for address;

  VRFCoordinatorV2Interface vrfCoordinator;
  bytes32 vrfKeyHash;
  uint64  vrfSubscriptionId;
  uint16  vrfConfirmations;
  uint32  vrfCallbackGasLimit;
  LinkTokenInterface link;

  StarcatchersInterface starsContract;
  string  public  symbol;
  uint256 private _currentTokenId = 1;

  /*
   * Rinkeby
   *   coordinator: 0x6168499c0cFfCaCD319c818142124B7A15E857ab
   *   hash: 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc
   *   link: 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
   * Mainnet
   *   coordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909
   *   hash: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef
   *   link: 0x514910771af9ca656af840dff83e8264ecf986ca
   */
  constructor(
    string memory _symbol,
    address _starsAddress,
    address _vrfCoordinatorAddress,
    bytes32 _vrfKeyHash,
    uint64  _vrfSubscriptionId,
    uint16  _vrfConfirmations,
    uint32  _vrfCallbackGasLimit,
    address _link
  )
    VRFConsumerBaseV2(_vrfCoordinatorAddress)
    ERC1155('')
  {
    symbol = _symbol;
    starsContract = StarcatchersInterface(_starsAddress);
    vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinatorAddress);
    vrfKeyHash = _vrfKeyHash;
    vrfSubscriptionId = _vrfSubscriptionId;
    vrfConfirmations = _vrfConfirmations;
    vrfCallbackGasLimit = _vrfCallbackGasLimit;
    link = LinkTokenInterface(_link);
  }

  function withdraw()
    public
    onlyOwner
    nonReentrant
  {
    Address.sendValue(payable(owner()), address(this).balance);
  }

  function setSymbol(
    string calldata _symbol
  )
    public
    onlyOwner
  {
    require(bytes(_symbol).length > 0, 'Symbol required');
    symbol = _symbol;
  }

  /*
   * VRF
   */

  function setVRFKeyHash(
    bytes32 _vrfKeyHash
  )
    public
    onlyOwner
  {
    vrfKeyHash = _vrfKeyHash;
  }

  function setVRFSubscriptionId(
    uint64 _vrfSubscriptionId
  )
    public
    onlyOwner
  {
    vrfSubscriptionId = _vrfSubscriptionId;
  }

  function setVRFConfirmations(
    uint16 _vrfConfirmations
  )
    public
    onlyOwner
  {
    vrfConfirmations = _vrfConfirmations;
  }

  function setVRFCallbackGasLimit(
    uint32 _vrfCallbackGasLimit
  )
    public
    onlyOwner
  {
    vrfCallbackGasLimit = _vrfCallbackGasLimit;
  }

  struct MintRequest {
    address[] addresses;
    uint64    episodeId;
  }
  /*
   * Maps VRF Request Ids to mint requests.  Mint controls handled inside
   * Episode minting functions for circumventing malicious actions.
   */
  mapping(uint256 => MintRequest) public MintRequests;

  function _requestMint(
    address[] memory _addresses,
    uint32 _quantity,
    uint64 _episodeId
  )
    internal
  {
    uint256 requestId = vrfCoordinator.requestRandomWords(
      vrfKeyHash,
      vrfSubscriptionId,
      vrfConfirmations,
      vrfCallbackGasLimit,
      _quantity
    );
    MintRequests[requestId] = MintRequest(_addresses, _episodeId);
  }

  function fulfillRandomWords(
    uint256 _requestId,
    uint256[] memory _randomWords
  )
    internal
    override
  {
    MintRequest memory r = MintRequests[_requestId];
    Episode storage e = Episodes[r.episodeId];
    for (uint16 i = 0; i < r.addresses.length; i++) {
      uint16 roll = uint16((_randomWords[i] % 10000) + 1); // 1-10000
      for (uint16 j = 0; j < e.tokens.length; j++) {
        Token storage t = Tokens[e.tokens[j]];
        if (roll < t.rarity && t.supply < t.maxSupply) {
          _mint(r.addresses[i], e.tokens[j], 1, '');
          t.supply += 1;
          break;
        }
      }
    }
  }

  /*
   * Tokens are individual items.
   */

  struct Token {
    uint128 rarity;
    uint128 supply;
    uint128 maxSupply;
    string  uri;
  }
  mapping(uint256 => Token) public Tokens;

  function uri(
    uint256 _Id
  )
    public
    view
    override
    returns (string memory)
  {
    string memory r = Tokens[_Id].uri;
    require(bytes(r).length > 0, 'Nonexistent token');
    return r;
  }

  function setTokenURI(
    uint256 _Id,
    string calldata _uri
  )
    public
    onlyOwner
  {
    require(bytes(_uri).length > 0, 'URI required');
    Tokens[_Id].uri = _uri;
    emit URI(_uri, _Id);
  }

  function setTokenRarity(
    uint256 _Id,
    uint128 _rarity
  )
    public
    onlyOwner
  {
    require(_rarity > 0 && _rarity <= 10000, 'Rarity must be >0 and <=10000');
    Tokens[_Id].rarity = _rarity;
  }

  function setTokenMaxSupply(
    uint256 _Id,
    uint128 _maxSupply
  )
    public
    onlyOwner
  {
    require(_maxSupply > 0, 'Max supply must be more than 0');
    Tokens[_Id].maxSupply = _maxSupply;
  }

  function createToken(
    uint128 _rarity,
    uint128 _maxSupply,
    string calldata _uri
  )
    public
    onlyOwner
    returns (uint256)
  {
    require(bytes(_uri).length > 0, 'URI required');
    require(_maxSupply > 0, 'Max supply must be more than 0');
    require(_rarity > 0 && _rarity <= 10000, 'Rarity must be >0 and <=10000');
    uint256 _Id = _currentTokenId;
    _currentTokenId++;

    Tokens[_Id] = Token(_rarity, 0, _maxSupply, _uri);
    emit URI(_uri, _Id);
    return _Id;
  }

  /*
   * Episodes are collections of tokens.
   */

  enum EpisodeStatus {
    STOPPED,
    STARS_MINT,
    PUBLIC_MINT
  }
  struct Episode {
    uint64[] tokens;
    uint64 starPriceWei;
    uint64 publicPriceWei;
    uint64 supply;
    uint64 maxSupply;
    EpisodeStatus status;
    mapping(uint64 => bool) starClaimed;
    mapping(address => bool) publicClaimed;
  }
  mapping(uint64 => Episode) public Episodes;

  function getStarHasMinted(
    uint64 _episodeId,
    uint64 _starId
  )
    public
    view
    returns(bool)
  {
    return Episodes[_episodeId].starClaimed[_starId];
  }

  function setEpisode(
    uint64 _episodeId,
    uint64[] calldata _tokens, // IMPORTANT: order low -> high based on Token.rarity
    uint64 _starPriceWei,
    uint64 _publicPriceWei,
    uint64 _supply,
    uint64 _maxSupply,
    EpisodeStatus _status
  )
    public
    onlyOwner
  {
    Episode storage e = Episodes[_episodeId];
    e.tokens = _tokens;
    e.starPriceWei = _starPriceWei;
    e.publicPriceWei = _publicPriceWei;
    e.supply = _supply;
    e.maxSupply = _maxSupply;
    e.status = _status;
  }

  modifier mintCompliance(
    uint256 _quantity,
    uint64 _episodeId,
    EpisodeStatus _expectedEpisodeStatus
  )
  {
    Episode storage e = Episodes[_episodeId];
    require(
      // O=_quantity*_tokens.length, safe for 16 tokens * 30
      _quantity > 0 && _quantity <= 30,
      "Invalid mint amount"
    );
    require(
      e.supply + _quantity <= e.maxSupply,
      "Maximum supply exceeded"
    );
    require(
      e.tokens.length > 0,
      "Episode must have tokens"
    );
    require(
      e.status == _expectedEpisodeStatus,
      "Episode in incorrect status"
    );
    _;
  }

  function airdrop(
    uint64 _episodeId,
    address[] calldata _addresses
  )
    external
    onlyOwner
    mintCompliance(_addresses.length, _episodeId, EpisodeStatus.STOPPED)
  {
    _requestMint(_addresses, uint32(_addresses.length), _episodeId);
    Episode storage e = Episodes[_episodeId];
    e.supply += uint32(_addresses.length);
  }

  function adminDrop(
    uint64 _episodeId,
    uint64 _tokenId,
    uint64 _quantity,
    address[] calldata _addresses
  )
    external
    onlyOwner
  {
    Episode storage e = Episodes[_episodeId];
    Token storage t = Tokens[_tokenId];
    require(
      e.supply + (_addresses.length * _quantity) <= e.maxSupply,
      "Episode maximum supply exceeded"
    );
    require(
      t.supply + (_addresses.length * _quantity) <= t.maxSupply,
      "Token maximum supply exceeded"
    );
    require(
      e.tokens.length > 0,
      "Episode must have tokens"
    );
    require(
      bytes(t.uri).length > 0,
      "Nonexistent token"
    );
    uint256[] memory _t = new uint256[](1);
    _t[0] = _tokenId;
    uint256[] memory _q = new uint256[](1);
    _q[0] = _quantity;

    for (uint64 i = 0; i < _addresses.length; i++) {
      _mintBatch(_addresses[i], _t, _q, '');
      e.supply += _quantity;
      t.supply += _quantity;
    }
  }

  function starMint(
    uint64 _episodeId,
    uint64[] calldata _stars
  )
    external 
    payable
    mintCompliance(_stars.length, _episodeId, EpisodeStatus.STARS_MINT)
  {
    Episode storage e = Episodes[_episodeId];
    require(
      msg.value == e.starPriceWei, // yes, flat fee intended
      "Incorrect payment"
    );
    for (uint64 i = 0; i < _stars.length; i++) {
      require(!e.starClaimed[_stars[i]], 'Call includes a star which has already claimed');
      require(starsContract.ownerOf(_stars[i]) == msg.sender, 'Caller does not own star');
    }
    address[] memory req = new address[](1);
    req[0] = msg.sender;
    _requestMint(req, uint32(_stars.length), _episodeId);
    e.supply += uint64(_stars.length);
    for (uint64 i = 0; i < _stars.length; i++) {
      e.starClaimed[_stars[i]] = true;
    }
  }

  function publicMint(
    uint64 _episodeId
  )
    public
    payable
    mintCompliance(1, _episodeId, EpisodeStatus.PUBLIC_MINT)
  {
    Episode storage e = Episodes[_episodeId];
    require(
      msg.value == e.publicPriceWei,
      "Incorrect payment"
    );
    require (!e.publicClaimed[msg.sender], 'Address has already claimed');
    address[] memory req = new address[](1);
    req[0] = msg.sender;
    _requestMint(req, 1, _episodeId);
    e.supply += uint64(1);
    e.publicClaimed[msg.sender] = true;
  }
}