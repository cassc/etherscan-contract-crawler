/***
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMWXKXNWMMMMMMMMMMMMMMMMWNNXKKKKKKKKKKKKK0000000KNMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMW0:.,:d0NMMMMMMMMMMWXx:'......................dNMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.   .;xXMMMMMMMWx'         .'''''.        .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.      :KMMMMMMk.        .xXNNNNNO'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.      .dWMMMMWl         cNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.       lWMMMMWl         lWMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.       lNMMMMWl         lWMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMx.       lNMMMMWl         lWMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMWl         lNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMO.        lNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMWO,       lNMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMMMNkc'..  ;XMMMMMM0'       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMd.       lNMMMMMMMMMWNK0xoo0WMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       lNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMMMMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMWWMMMMMMMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMWkccokOKWMMMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMK,    .;dXMMMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:       ,kWMMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        '0MMMMMK,       .kMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        .xMMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        .dMMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX:        .dMMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMX;        .dWMMMMK,       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       cNMMMMMMK,        .xMMMMMNc       .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.       ;k00000k:         :XMMMMMMK:      .OMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWd.                       .lKMMMMMMMMNk:.   .kWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMXl'..'''''',,,,,,,,,,,;:cxKWMMMMMMMMMMMWXko::oXMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMWNNNNNNNNNNWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMWNWMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 * MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
 *
 * @title: LadyLlamas.sol
 * @author: MaxFlowO2 on Twitter/GitHub
 */

// SPDX-License-Identifier: MIT
pragma solidity >0.8.0 <=0.9.0;

import "./token/ERC721/ERC721.sol";
import "./eip/2981/ERC2981Collection.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./lib/CountersV2.sol";
import "./utils/ContextV2.sol";
import "./modules/WhitelistV2.sol";
import "./access/MaxAccessControl.sol";
import "./modules/PaymentSplitterV2.sol";
import "./modules/Llamas.sol";
import "./modules/ContractURI.sol";

contract LadyLlamas is ERC721
                     , ERC2981Collection
                     , ContractURI
                     , Llamas
                     , WhitelistV2
                     , PaymentSplitterV2
                     , MaxAccess
                     , ReentrancyGuard {

  using CountersV2 for CountersV2.Counter;
  using Strings for uint256;

  CountersV2.Counter private _tokenIdCounter;
  uint private mintStartID;
  uint private constant MINT_FEE_ONE = 0.1 ether; // 5+ on day 1
  uint private constant MINT_FEE_TWO = 0.15 ether; // 3-4 on day 1 + whitelist day 2
  uint private constant MINT_FEE_THREE = 0.2 ether; // 1-2 on day 3
  uint private timeOneStart;
  uint private timeTwoStart;
  uint private timeThreeStart;
  uint private timeThreeEnd;
  uint private constant MINT_SIZE = 3000;
  string private unrevealedBase;
  string private base;
  bool private revealedNFT;
  bool private enableMinter;
  bool private lockedProvenance;
  bool private lockedPayees;
  bool private lockedAirdrop;
  mapping(uint => bool) private LBLUsed;
  mapping(address => bool) public oneToOne;
  mapping(address => bool) public threeToOne;
  IERC721 private LBLNFT; // don't forget to add this later

  error ToEarly(uint time, uint startTime);
  error ToLate(uint time, uint endTime);
  error AlreadyClaimed(uint tokenID);
  error NotEnoughETH(uint required, uint sent);
  error AlreadyMinted();
  error NotOnWhitelist();
  error OverMaximumMint();
  error CanNotMintThatMany(uint requested, uint allowed);
  error ProvenanceNotSet();
  error ProvenanceAlreadySet();
  error PayeesNotSet();
  error PayeesAlreadySet();
  error NFTsAlreadyRevealed();
  error NonMintedToken(uint token);
  error NullArray();
  error AirdropLocked();
  error NoTimesSet();

  event NFTReveal(bool status, uint time);
  event UpdatedUnrevealedBaseURI(string _old, string _new);
  event UpdatedBaseURI(string _old, string _new);
  event ProvenanceLocked(bool _status);
  event PayeesLocked(bool _status);
  event DayOneTimes(uint start, uint end);
  event DayTwoTimes(uint start, uint end);
  event DayThreeTimes(uint start, uint end);
  event LBLContractAddressUpdated(address _update);
  event AirdropIsLocked(bool _status);

  constructor() ERC721("Lady Llamas", "LL") {}

/***
 *    ███╗   ███╗██╗███╗   ██╗████████╗
 *    ████╗ ████║██║████╗  ██║╚══██╔══╝
 *    ██╔████╔██║██║██╔██╗ ██║   ██║   
 *    ██║╚██╔╝██║██║██║╚██╗██║   ██║   
 *    ██║ ╚═╝ ██║██║██║ ╚████║   ██║   
 *    ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   
 */

  // @notice: this is the 5+ mint for the UX/UI team
  // @param ids: Array of LBL id's to mint off of
  // This will take ids, and lock them out of the mapping
  // so an id can not remint a LL. Cost will be .1 eth per
  // length.ids/5. Can mint multiple.
  function publicMintFiveToOne(
    uint256[] memory ids
    ) 
    public 
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeOneStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeOneStart
      });
    }
    if (block.timestamp >= timeTwoStart) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeTwoStart
      });
    }
    // checks & effects
    uint length = ids.length;
    uint quant;
    for(uint x=0; x < length;) {
      if (LBLUsed[ids[x]]) {
        revert AlreadyClaimed({
          tokenID: ids[x]
        });
      }
      if (LBLNFT.ownerOf(ids[x]) == user){
        ++quant;
        LBLUsed[ids[x]] = true;
      }
      unchecked { ++x; }
    }
    quant = quant / 5; // 5:1 ratio for 0.1 eth
    if (_msgValue() != quant * MINT_FEE_ONE) {
      revert NotEnoughETH({
        required: quant * MINT_FEE_ONE
      , sent: _msgValue()
      });
    }

    // minting
    if (quant + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    for(uint x=0; x < quant;) {
      _safeMint(user, mintID());
      _tokenIdCounter.increment();
      unchecked { ++x; }
    }
  }

  // @notice: this is the 3/4 mint for the UX/UI team
  // @param ids: Array of LBL id's to mint off of
  // This will take ids, and lock them out of the mapping
  // so an id can not remint a LL. Cost will be .15 eth 
  // Can only mint one, locks out the mapping for threeToOne
  function publicMintThreeToOne(
    uint256[] memory ids
    ) 
    public 
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeOneStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeOneStart
      });
    }
    if (block.timestamp >= timeTwoStart) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeTwoStart
      });
    }
    if (threeToOne[user]) {
      revert AlreadyMinted();
    }
    // checks & effects
    threeToOne[user] = true; // locks them out
    uint length = ids.length;
    uint quant = 0;
    for(uint x=0; x < length;) {
      if (LBLUsed[ids[x]]) {
        revert AlreadyClaimed({
          tokenID: ids[x]
        });
      }
      if (LBLNFT.ownerOf(ids[x]) == user){
        ++quant;
        LBLUsed[ids[x]] = true;
      }
      unchecked { ++x; }
    }
    if (quant == 0) {
      revert NullArray();
    }
    if (quant >= 3) {
      if (_msgValue() !=  MINT_FEE_TWO) {
        revert NotEnoughETH({
          required: MINT_FEE_TWO
        , sent: _msgValue()
        });
      }

      // minting
      if (1 + _tokenIdCounter.current() >= MINT_SIZE) {
        revert OverMaximumMint();
      }
      _safeMint(user, mintID());
      _tokenIdCounter.increment();
    }
  }

  // @notice: this is the whitelist mint funtion for UX/UI team
  // This will do the same checks, then set whitelist to false
  // then mint one LL for .15 eth.
  function whitelistMint()
    public
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeTwoStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeTwoStart
      });
    }
    if (block.timestamp >= timeThreeStart) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeThreeStart
      });
    }
    // checks & effects
    bool check = _myWhitelistStatus(user);
    if (!check) {
      revert NotOnWhitelist();
    }
    removeWhitelist(user);
    if (_msgValue() != MINT_FEE_TWO) {
      revert NotEnoughETH({
        required: MINT_FEE_TWO
      , sent: _msgValue()
      });
    }

    // minting
    if (1 + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    _safeMint(user, mintID());
    _tokenIdCounter.increment();
  }

  // @notice: this is the 1/2 mint for the UX/UI team
  // @param ids: Array of LBL id's to mint off of
  // This will take ids, and lock them out of the mapping
  // so an id can not remint a LL. Cost will be .15 eth
  // Can only mint one, locks out the mapping for oneToOne
  function publicMintOneToOne(
    uint256 id
    )
    public
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeThreeStart) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeThreeStart
      });
    }
    if (block.timestamp >= timeThreeEnd) {
      revert ToLate({
        time: block.timestamp
      , endTime: timeThreeEnd
      });
    }
    if (oneToOne[user]) {
      revert AlreadyMinted();
    }
    if (_msgValue() != MINT_FEE_THREE) {
      revert NotEnoughETH({
        required: MINT_FEE_THREE
      , sent: _msgValue()
      });
    }
    if (LBLUsed[id]) {
      revert AlreadyClaimed({
        tokenID: id
      });
    }
    // checks & effects
    oneToOne[user] = true; // locks them out
    if (LBLNFT.ownerOf(id) == user){
      LBLUsed[id] = true;
    } // consumes id

    // minting
    if (1 + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    _safeMint(user, mintID());
    _tokenIdCounter.increment();
  }

  // @notice: this is the boss llama "airdrop" mint
  // @param ids: Array of address taken from snapshot
  // Will mint one token to each address in the array of 
  // addresses.
  function bossLlamaAirdrop(
    address [] memory addresses
    )
    public
    onlyOwner {
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (lockedAirdrop) {
      revert AirdropLocked();
    }
    uint length = addresses.length;
    if (length + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    for(uint x=0; x < length;) {
      _safeMint(addresses[x], mintID());
      _tokenIdCounter.increment();
      unchecked { ++x; }
    }
  }

  // @notice: this is the public mint funtion for UX/UI team
  // This will do the same checks then mint quant of LL for .2 eth.
  // @param quant: amount to be minted
  function publicMint(uint quant)
    public
    payable
    nonReentrant() {
    // locals
    address user = _msgSender();

    // errors
    if (!lockedProvenance) {
      revert ProvenanceNotSet();
    }
    if (timeOneStart == 0) {
      revert NoTimesSet();
    }
    if (block.timestamp < timeThreeEnd) {
      revert ToEarly({
        time: block.timestamp
      , startTime: timeThreeEnd
      });
    }
    if (quant > 2) {
      revert CanNotMintThatMany({
        requested: quant
      , allowed: 2
      });
    }
    // checks & effects
    if (_msgValue() != quant * MINT_FEE_THREE) {
      revert NotEnoughETH({
        required: MINT_FEE_THREE * quant
      , sent: _msgValue()
      });
    }

    // minting
    if (quant + _tokenIdCounter.current() >= MINT_SIZE) {
      revert OverMaximumMint();
    }
    for(uint x=0; x < quant;) {
      _safeMint(user, mintID());
      _tokenIdCounter.increment();
      unchecked { ++x; }
    }
  }

  // @notice this shifts the _tokenIdCounter to proper mint number
  function mintID() internal view returns (uint) {
    return (mintStartID + _tokenIdCounter.current()) % MINT_SIZE;
  }

  // Function to receive ether, msg.data must be empty
  receive() external payable {
    // From PaymentSplitter.sol, 99% of the time won't register
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  // Function to receive ether, msg.data is not empty
  fallback() external payable {
    // From PaymentSplitter.sol, 99% of the time won't register
    emit PaymentReceived(_msgSender(), _msgValue());
  }

  function getBalance() external view returns (uint) {
    return address(this).balance;
  }

/***
 *     ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗ 
 *    ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
 *    ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
 *    ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
 *    ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
 *     ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
 * This section will have all the internals set to onlyOwner
 */

  // edit me...
  // @notice click this to start it up initally, for ease by onlyOwner
  // param timeOne: unix timestamp
  function startMinting(uint _start)
    public
    onlyOwner {
    timeOneStart = _start;
    timeTwoStart = _start + 1 days;
    timeThreeStart = _start + 2 days;
    timeThreeEnd = _start + 3 days;
    emit DayOneTimes(timeOneStart, timeTwoStart);
    emit DayTwoTimes(timeTwoStart, timeThreeStart);
    emit DayThreeTimes(timeThreeStart, timeThreeEnd);
  }

  // @notice external to the internal on WhitelistV2.sol
  // @param _addresses - array of addresses to add
  function addWhitelistBatch(
    address [] memory _addresses
    )
    public
    onlyOwner {
    _addBatchWhitelist(_addresses);
  }

  // @notice adding functions to mapping
  // @param _address - address to add
  function addWhitelist(
    address _address
    )
    public
    onlyOwner {
    _addWhitelist(_address);
  }

  // @notice removing functions to mapping
  // @param _addresses - array of addresses to remove
  function removeWhitelistBatch(
    address [] memory _addresses
    )
    public
    onlyOwner {
    _removeBatchWhitelist(_addresses);
  }

  // @notice removing functions to mapping
  // @param _address - address to remove
  function removeWhitelist(
    address _address
    )
    public
    onlyOwner {
    _removeWhitelist(_address);
  }

/***
 *    ██████╗ ███████╗██╗   ██╗
 *    ██╔══██╗██╔════╝██║   ██║
 *    ██║  ██║█████╗  ██║   ██║
 *    ██║  ██║██╔══╝  ╚██╗ ██╔╝
 *    ██████╔╝███████╗ ╚████╔╝ 
 *    ╚═════╝ ╚══════╝  ╚═══╝  
 * This section will have all the internals set to onlyDeveloper()
 * also contains all overrides required for funtionality
 */

  // @notice will add an address to PaymentSplitter by onlyDeveloper() role
  // @param newAddy: new address to add
  // @param newShares: amount of shares for newAddy
  function addPayee(
    address newAddy
  , uint newShares
    )
    public
    onlyDeveloper() {
    // error
    if(lockedPayees) {
      revert PayeesAlreadySet();
    }
    _addPayee(newAddy, newShares);
  }

  // @notice will lock payees on PaymentSplitter.sol
  function lockPayees()
    public
    onlyDeveloper() {
    // error
    if(lockedPayees) {
      revert PayeesAlreadySet();
    }
    lockedPayees = true;
    emit PayeesLocked(lockedPayees);
  }

  // @notice will set IERC721 for LBL
  // @param update: LBL CA
  function setLBLCA(
    address update
    )
    public
    onlyDeveloper() {
    LBLNFT = IERC721(update);
    emit LBLContractAddressUpdated(update);
  }

  // @notice will lock airdrop
  function lockAirdrop()
    public
    onlyDeveloper() {
    lockedAirdrop = true;
    emit AirdropIsLocked(lockedAirdrop);
  }

  // @notice will update _baseURI() by onlyDeveloper() role
  // @param _base: Base for NFT's
  function setBaseURI(
    string memory _base
    )
    public
    onlyDeveloper() {
    string memory old = base;
    base = _base;
    emit UpdatedBaseURI(old, base);
  }

  // @notice will update by onlyDeveloper() role
  // @param _base: Base for unrevealed NFT's
  function setUnrevealedBaseURI(
    string memory _base
    )
    public
    onlyDeveloper() {
    string memory old = base;
    unrevealedBase = _base;
    emit UpdatedUnrevealedBaseURI(old, unrevealedBase);
  }

  // @notice will reveal NFT's via tokenURI override
  function revealNFTs() public onlyDeveloper() {
    if (revealedNFT) {
      revert NFTsAlreadyRevealed();
    }
    revealedNFT = true;
    emit NFTReveal(revealedNFT, block.timestamp);
  }

  // @notice will set the ContractURI for OpenSea
  function setContractURI(string memory _contractURI) public onlyDeveloper() {
    _setContractURI(_contractURI);
  }

  // @notice this will set the Provenance Hashes
  // This will also set the starting order as well!
  // Only one shot to do this, otherwise it shows as invalid
  function setProvenance(string memory _images, string memory _json) public onlyDeveloper() {
    // errors
    if (!lockedPayees) {
      revert PayeesNotSet();
    }
    if (lockedProvenance) {
      revert ProvenanceAlreadySet();
    }
    // This is the initial setting
    _setProvenanceImages(_images);
    _setProvenanceJSON(_json);
    // Now to psuedo-random the starting number
    // Your API should be a random before this step!
    mintStartID = uint(keccak256(abi.encodePacked(block.timestamp, _msgSender(), _images, _json, block.difficulty))) % MINT_SIZE;
    _setStartNumber(mintStartID);
    // @notice Locks sequence
    lockedProvenance = true;
    emit ProvenanceLocked(lockedProvenance);
  }

  ///
  /// Developer, these are the overrides
  ///

  // @notice solidity required override for _baseURI()
  function _baseURI() internal view override returns (string memory) {
    return base;
  }

  // @notice internal function for unrevealedBase
  function _unrevealedURI() internal view returns (string memory) {
    return unrevealedBase;
  }

  // @notice this is the toggle between revealed and non revealed NFT's
  function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
    if (ownerOf(tokenId) == address(0)) {
      revert NonMintedToken({
        token: tokenId
      });
    }
    if (!revealedNFT) {
      string memory baseURI = _unrevealedURI();
      return bytes(baseURI).length > 0 ? string(unrevealedBase) : "";
    } else {
      string memory baseURI = _baseURI();
      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
  }

  // @notice solidity required override for supportsInterface(bytes4)
  // @param bytes4 interfaceId - bytes4 id per interface or contract
  //  calculated by ERC165 standards automatically
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return (
      interfaceId == type(ReentrancyGuard).interfaceId  ||
      interfaceId == type(WhitelistV2).interfaceId ||
      interfaceId == type(MaxAccess).interfaceId ||
      interfaceId == type(PaymentSplitterV2).interfaceId ||
      interfaceId == type(Llamas).interfaceId ||
      interfaceId == type(ContractURI).interfaceId ||
      super.supportsInterface(interfaceId)
    );
  }

  // @notice will return bool for isClaimed
  function isClaimed(uint _tokenId) external view returns (bool) {
    return LBLUsed[_tokenId];
  }

  // @notice will return epoch 1
  function epochOne() external view returns (uint, uint) {
    return (timeOneStart, timeTwoStart);
  }

 // @notice will return epoch 2
  function epochTwo() external view returns (uint, uint) {
    return (timeTwoStart, timeThreeStart);
  }

 // @notice will return epoch 3
  function epochThree() external view returns (uint, uint) {
    return (timeThreeStart, timeThreeEnd);
  }

  // @notice will return minting fees
  function minterFeesFivePlus() external view returns (uint) {
    return MINT_FEE_ONE;
  }

  // @notice will return minting fees
  function minterFeesThreePlusOrWL() external view returns (uint) {
    return MINT_FEE_TWO;
  }

  // @notice will return minting fees
  function minterFeesOnePlusDayThree() external view returns (uint) {
    return MINT_FEE_THREE;
  }

  // @notice will return maximum mint capacity
  function minterMaximumCapacity() external view returns (uint) {
    return MINT_SIZE;
  }

  // @notice will return current token count
  function totalSupply() external view returns (uint) {
    return _tokenIdCounter.current();
  }
}