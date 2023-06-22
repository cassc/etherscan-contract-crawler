// SPDX-License-Identifier: MIT
/*
^^^^^^^^^^^^^^^^^^::::::::::::::::::::........................::::::::::::::::::::^^^^^^^^^^^^^^^^^^
^^^^^^^^^^^^^^^::::::::::::::::::::..............................::::::::::::::::::::^^^^^^^^^^^^^^^
^^^^^^^^^^^^^::::::::::::::::::..................:. .................::::::::::::::::::^^^^^^^^^^^^^
^^^^^^^^^^:::::::::::::::::................ ... ~BP~:. ..................:::::::::::::::::^^^^^^^^^^
^^^^^^^^::::::::::::::::..................~5~ . 5BJ5P5?^ ...................::::::::::::::::^^^^^^^^
^^^^^^:::::::::::::::.................. :PB&. . .5G??JYG5: ....................:::::::::::::::^^^^^^
^^^^::::::::::::::.................... .BP?#?    ~&?????PG. ......................::::::::::::::^^^^
^^^:::::::::::::...................... :&J?JG5JJYP5??????&!   ......................:::::::::::::^^^
^:::::::::::::....................      7#???JJJJ???~~!?J#:.!:    ....................:::::::::::::^
:::::::::::.........  ........          JB???!!~!7??^^~?BJ J&G!       ......    ........::::::::::::
:::::::::.:7Y5PPPGPY?!^.              ^PG??!^^^^^^!7!7?Y&:~BYY#.           :~7JYPGPPP5J!:.::::::::::
::::::::.:BB##PP&G55PB&#PJ!:        .JBY???^^^^^^^^^~???PPPJ?5B.       :!YG#&B555B#PP##BP:.:::::::::
::::::::.^&PBB5G&?7?#5??JY5PY!.     !&?????!^^^^^^^^~?????77?#!     :[email protected]#GG#:..::::::::
:::::::...J&55G#P?5G&P7!!!!7?5GJ:  :J&5????7~^^^^^^!?????!~7J&^   ^YG5?!!!!!7G#GY?P#G5P&7....:::::::
:::::......BB5&P75&775GP5J?7!!7YGY55?~J55555PY???Y555YYJJ?JYGG5Y!YGY7!!7?J5PPY!?&Y?G&5BP.......:::::
::::...... J&5P&PJ&YJ???JYPPPY7JB5~:::::^^^^!?JYJ?777?JY555Y!::!P#J!?YPPPYJ??JJ5&JG#55&7 .......::::
:::........:P#B&YGG5Y5PPPY?7?P&P!:::::::::::::::::::::::::::::^::?&BPY?7?5PP5YY5GG5&G#5..........:::
::.......... [email protected]!!!!7JPPPBJ:::::::::::::::!Y5PPPPPP5Y75B5YBBPBG#GJPG5J7!!!77G&PP?^ ...........::
........... .^7JG#&#BGGP5J??&Y::::::::::::::::P&5YJ?JYYP#&#BGPYP&&BP&B?7?J5PGGB#&B57^. .............
.......... !GBGGBBBBBBBB###&G:::7YY55PJ:::::::?P::^?JJ!^Y&##[email protected]&GB###BBBBBBBGGBG7.............
.......... 5#5G&BBBBBBBBBB#@7:::^~~G&B!:::::::7B::~PPJ^:[email protected]@@@5BGG#5P5&#BBBBBGGGGGB&G5G&: ...........
............PBG&GPPGGGBBBB##^:::::::^::::::::::?JJJJJJ?P&BBBGGBB&P55P&&[email protected]#~ ............
........... 5#PBB##BBGGBBB&G:::::::^~~!!7777777777777~~BBGB###B#GPPBG&&BBBBGBBBBBBBPG#. ............
........... :!J#PG#GGBBBBB&G:::::::~#&@[email protected]@B^~BGPB#GG#BPP57^##BBBBBBGG&B5BPJ~  ............
............   J#GGBB#BGBB#B::::::::~YJ^::::::::::?J^::^^:^?J7^^^:::[email protected]#&BBBGPBB.    ............
.............   ^!!~GGGGGGB&~::::::::::::::::::::::::::::::::::^[email protected]#GGGGGPG~!7?7:    .............
.............      JGGG#[email protected]:::::::::::::::::::::::::::::^~!?Y5J7^[email protected]?PBGPPY         .............
..............     ?BPBGGBB#&?!^:::::::::::::::::::^^~!7JJYYYY?7^[email protected]        ..............
...............     !YPGGGP5#BJ5Y?7!~^:::::::::::!YPG?Y?~::!77?YY5#J5GGPGGPY!        ...............
::..............      .:::. :#Y7?7!?B55::::::::::G?:Y5J?~!7JYJJ!~BYYGGPBB&GY?^      ..............::
:::..............            ~&BY?~PY~&J!~^^^^^~!GP?JY??J5Y7::7?7?B&&B#P?&[email protected]   ..............:::
::::..............            ~#J??Y^~&PPPPPPPPPP5#5~::::~^:::^~^~BBB&B5JB&7!75B^ ..............::::
:::::...............           ^BP77^:BPYYYYYYYYYY5#!?Y!^:::::::~B#G#GBY7?&Y:::PB .............:::::
:::::::..............           .YB?^~J#YYYYYYYYYYYPB?J?7!:::::!B#GP#[email protected]::B5 ...........:::::::
::::::::...............           ~5GY7GBYYYYYYYYYYY#7~7~~:^~!?&&B&JGGPB#[email protected]#BG:...........::::::::
:::::::::................           ~5G5BGYYYYYYYYYYGP??:::~?B&#YY&G5J#@&GJ?B&J............:::::::::
:::::::::::................           :?P&G5YYYYYYYYPB^~::~5&GG#5BJ?77?P&@@GJ: ..........:::::::::::
::::::::::::..................           :7YPGGP5YYYY#JY7YG&&GB#B5?JY5PGGY~. ...........::::::::::::
^:::::::::::::....................          .:!?###BG#GGBPBPG&5BBP5YJ7~:.  ...........:::::::::::::^
^^^:::::::::::::......................          5#&GBYY5#&#BPGJ~:..    .............:::::::::::::^^^
^^^^::::::::::::::........................      ^GG######PBJ^.  ..................::::::::::::::^^^^
^^^^^^:::::::::::::::........................... .~?J5PY?!.  ..................:::::::::::::::^^^^^^
^^^^^^^^::::::::::::::::.........................     ..  ..................::::::::::::::::^^^^^^^^
^^^^^^^^^^:::::::::::::::::..............................................:::::::::::::::::^^^^^^^^^^
^^^^^^^^^^^^^::::::::::::::::::......................................::::::::::::::::::^^^^^^^^^^^^^
^^^^^^^^^^^^^^^^:::::::::::::::::::..............................:::::::::::::::::::^^^^^^^^^^^^^^^^
*/
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Viakaverse is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }


  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    
    // =============================================================================
    (bool hs, ) = payable(0x3a6a38469B1e469ae19C91dBf2d54465EF20838f).call{value: address(this).balance * 8 / 100}('');
    require(hs);
    // =============================================================================

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}