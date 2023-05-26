// SPDX-License-Identifier: MIT

// ............................................................................................................................~
// :::::::::::::::::::::::::.........::::....!777:.:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::.~
// ::::::::::.......::::::::~~JPPP!~^....:!PPPPPPG~.:::::::::::::::::::::::::::::....:::::::::::::::::::::::::::::::::::::::::.~
// ::::::::..^:7YYY~:.::::.^BGPPPGBBPYJ^7PG5YJ??JP5!.:::::::::::::::::::::::::::.:^^^..:::::::::::::::::::::::::::::::::::::::.~
// :::::.:.^?PG5YJJPJ~.::.^75YY5G##BGG#GGP555YYJJ?GP!:::::::::::::::::::::::::::!YPGGJ~..:::::::::::::::::::::::::::::::::::::.~
// :::..!YPPPYYJJJJ?J5P:..7#[email protected]##GPPGBGGGPP5YJG#.::::::::::::::::::::::::::5PPBPPPY~:::::::::::::::::::::::::::::::::::::.~
// ::.~5P555555YYYYYJYG^.!YPJJPBBGGG#&PB##BP55PGGP5BG.::::::::::::::::::::::::::.Y&GBB5P#:.:::::........::::::::::::::::::::::.~
// ::[email protected]#BBBGP5YJJ&YGB?JJB#PPGGB#B###G?7YPPPBP7::::::::::::::::::::..::..::.!5GP#PG#:.:..::!JJJJJJ?:..:::::::::::::::::::.~
// ::[email protected]####[email protected]##BY?JMUTANTGB#@&P~?GBP5!:..::::::::::::::::::.:!55??GP7~J&PBPG#:..^?PPPPGPPPPPP7:.::::::::::::::::::.~
// ::.^?GBBB###5JYGBG55&BGB#J??P#GGPPGB#[email protected]  ..........:::::.......7P55JG&BGBBBBBG5G#:.?MTNTRHNCLLCTNPG?.:::::::::::::::::.~
// :::..:?PBB##YJBBBB##[email protected]@GBPYYJY7:::::::.....::::::?PGYYJG&GGGGGGGPGGJ:.P#5PGGPPGGP55YJ#5.:::::::::::::::::.~
// :::::..:!YG&[email protected]#BP55PBB!?P#&[email protected]?777?GBBBBBB#BYYYYP&BBGPPPP#P.:.:J&GGBG555PGPPP7^.:::::::::::::::::.~
// ::::::.:?&G&[email protected]?~7B#BGB###BB##$RHNOGB#PPB#BGBGGGGGGGGG###############PP55PPGBBBG#Y^....^?G&Y^.:.5#5!...::::::::::::::::::.~
// ::::::.Y&PP&5!5#BBBGPP#&#BBGGGGB#BGPP555555PBBBBBBGGGPPGGGGG#GYJJJ??YPPPPGBG55YY5GPYJJ^^:.:5Y~..::P#YYY!:::::::::::::::::::.~
// ::::::.Y&PPP#P~PBGG#GBBBGGGGGGPPPPPP55YY5555Y55PPGBBBBGPPPB#5J???777!!!77JYYPGPYYYJY55PPJ?JP:...:B#BBBG#Y.:::::::::::::::::.~
// ::::::.Y&GPPGBB!?5B&#BGGGGGGGPPP5555YYYYYYYYYYYY5555GGBBP#BP5YJ?!::~7?!7777??BG5YYYYYYYJY5YY!:.^GGPGBGP#5.:::::::::::::::::.~
// ::::::.Y&RHNOGBP?YG#BGGGGGPPPP55555555YYYYYYYYYYYYYY555PG&B55YYJ?~^^13J08?77??G#YYYYYYYYJJ??557!#~.~J!GYJY..:::::::::::::::.~
// ::::::.7PBGGGPPB#&#GGGGGPPPPP55555555555YYYYYYYYYYYYYYY55PB#P5YYYJ5PGG577777??5GGYYYYYYYYJ???J5PY~7YJJ&?Y&?^..:::::::::::::.~
// :::::::[email protected]JJJJJJJ?5&5YYYYYYJJ??JJYPG#J^[email protected]!5&J5?~.::::::::::::.~
// :::::::.^?#BGGB#BGGGGGGPPPP5555555YYY5[email protected]?77JG?G5^::::::::::::.~
// ::::::::.:JGGB&BGGGGPPPPPPP55555YYY555PPPPPPPPPPPPPP5YYJJJJJYYYY5PGBBBBBBBB####G55P55YYJJYPPPPP5YJJ7?&?7~!&5JPG.:::::::::::.~
// ::::::::::.^YBBBGGGGGPPPPPP55555YY555PPPP5YYJJJ55PPPPPPP5YYJJYJJYYYY55PPPGGBBBBGPGPPPYYY5PPP5YJ?7JJP#Y77!^!5BY^::::::::::::.~
// ::::::::::.7P#BGGG[email protected]7YBP55PP5YYJYPPG#BY77!~^^^J?.::::::::::::.~
// ::::::::.:?GBBBGGG[email protected]7!Y#PP5YYGBB###&&G7777!^^^Y?.::::::::::::.~
// ::::::::.:JB#BBGGB5~~5GPPP55555555PPPP5YJYGBB##BGG$RHNOBBGPPPPPP55555555555P&YJYGG!^J&P55PBBGY?JPB5?77!~~^^~Y?.::::::::::::.~
// ::::::::.:PB###BBY~^PGGGPPPPPPPPPPPPPPP5J5GB#&PY?21^^~07?##GPPPPPPP55555PPGBYPGPJ7~^J&55BB5YJJ5G5?7777~~~^~75?.::::::::::::.~
// :::::::.^Y#BBB###G?^?PGGGGPPPPPGPGPPPPPP55GBBG5YJ21~^^JULYGBGGPP555Y5PGBBG5J77777!~~Y&PP##5GGGPJ777777~~~~77PJ.::::::::::::.~
// :::::[email protected]#GJ~~?5BGGGGGGGGGGGGPPPP55PGGP5YYJ?YPGGPJ?5&G555PPGGB&5YJJJJ777!~~!5&GG##G55YJJ77777!~~!777GY.::::::::::::.~
// ::..:!!?5BBBBBBBBBBB5~:?&BBBB##BBBBBBBGGGPPPPGBGGPY5YY5YJJ5BG55PGBB5?JBPYYYJJ77!~~77Y&P#G5JJJJ?77777!~~~!777B5.::::::::::::.~
// :.:!5BB##BBBBBBBBB57^~JGB####BPPP5YJJ5PBGGGGGPPG#&BBBBBBGPPP555B#5YJ??7J5555Y7!!7775##B#G5Y5JJJJ777!~~!7777GP7..:::::::::::.~
// :.J#GGBBBBBBBBBB57^~YGBBBB&#GGBGPPPG5Y5PGPPPPPPPPPPPPGGGPPPPPGB##5J5GGGP5555GYYYJ?5GBBY?GB55YYJ77!!!77777?5PJ!~7:.:::::::::.~
// .5P5GG##BBBBBBB5^~YGBBBBBB&#GPP5J??J#YJP?5PPPPPPGBBBBBBBBBBBB&#GP5Y&#PPPPGGYYGBBBGP5PBPPYYPGG5YYJJJJJ?YY55YB#57G:.:::::::::.~
// ~PPYB#BBBBBBBBG!~Y#BBBBBBB&#GGPYJ??J#YJP?PPP55PB&#GGPPPPPPPPPG5YYYY5PPYYJJ5GB5YY5BYJJ5&&GJ?Y5GBBGGGGGG55J7!#@5~55~.::::::::.~
// &5YPB&BBBBBBBBBP5B#BBBBBBB&BGGBGGPPGYY5GGB#BGPP&#55YY55555YJ7J???????JP&BGGBG5J7?#Y7Y&P5#B?77???!!!!!?7?!~5PPY~^&7.::::::::.~
// &PYPB#BBBBBBBBB###BBBBBBBBB##BP5YYJJ5PGGPPPGB###BGPG&#BBGGPPYYYG#[email protected]#G!!J?!!JJJJ5BBBPY#5JY5J&7.::::::::.~
// PBPYG#BBBBBBBBBBBBBBBBBBBBBBBBGBBBBB#&&#BG555PP55PPB&[email protected]?!?B7!~J&Y?YPGGBBBGBGGGGPBP5P5PY?JBJ^.::::::::.~
// ^GGYP#BBBBBBBBBBBBBBBBBBBBGGGGBB##BB&GB&5GBBBGGBGPPB&GYY?!^7G5PB#YJ!!Y#GBGGPJ?Y5Y?77Y#Y7!?5PG##P5YJ?JP#5?7?PB577#7.::::::::.~
// &&GYY#BBBBBBBBBBB#BBBGPGBBBBBBGGGGGG&GGBGYJJ?77BB5BGYJ?7JJP#55PY??YJPBP&G55PGGBBGGBP55J!!7YGBPPGGY7!~?BP?!J&GGB!#7.::::::::.~
// &&GYY#BBBBBBBBGPGPPGGBBBBBGGGGGGGGGG&[email protected]&PYYYJBBYPPGGGPP5##JY5GBP5&#5YY#B5J??J5GBBGPYJ77?5&5YY5&5?7!?#BGGB#GB#?&7.::::::::.~
// B#GYJY##BBBGG57!75#BBBGGGGGGGGGGGGGG&B5Y5#@@@@@@BYYY5YYYYYG#J?YPBBYBGYJJ5BG?!!5BPYY5GBPPPG#P5YY5P#P?75&#GGGP5G#PY57.:::::::.~
// BBBPJ?B#BGPBBBBY!?5GGGGGGGPPPPGGGGGGG#BY7?5PGB#&BY55YY5555YP&YJPBB&PYYYYJGB?77G#YJYPBBBB&&GYYYPBGBB5?BBPY5PP5P#&7B5.:::::::.~
// BG#BY?J5PPBBBBG5?!?GGGGGGPGGGGPPGGGGGGBB5?7!!77GGYYYY555555Y5GG55#PYYYYJJYG#JBG5PGBGPPGB#BPY5PBBPY#B5&5YPG5BBGP&Y#Y.:::::::.~
// BBB#GY?5#BGGGY7!7YPGGGGGPP##BGPPPP5JYPGGBB5YYYY##[email protected]@GBGP5PB&BP&P5BB~!7^^BPBJ.:::::::.~
// BBBB#5YG#GGBJ!!YPGGGGGGGPPBBG5Y5YJYPYJYPG#BBBGGGGGGGGBBBBBBBBGG#&GG5YJ~~~P#[email protected]&&G55PBBPPGBBPPGG?:..::?^.::::::::.~
// BBBBBG5PBBGBJ!7GBGGGGGGGPPPPPP5Y5PGGGPY?JPP55YY55555YB&P555555#B555#GJ!!~P#[email protected]#5:.::::...:::::::::.~
// BBBGG&GPG&GBY7!7YPGGGGPPGPPPPPGGGGGGB#PJ??YP5Y5555Y5BBPYY55555BGYY5&GJY5PPP5YB#GPPB&&BBYGBPPGGPPPP##PP5BP~:::::::::::::::::.~
// BBBGBB#GGB#BGPY77?YGPPPPPPPPGGGGGGG#BGP5J5PP5Y555P5B&#BBP555Y&PYY55PGB#&BBGBG&#BBGGGGPGY#P.: 5&PPGB#GPPG#G:::::::::::::::::.~
// BBGGBG#BPP#BGGGPPGB#[email protected]&P5555555G&Y55YYGB&P.:?GB55&?~5B#P7::::::::::::::::::.~
// STKSYSTMBPG#BGGGB##BPPPPPPGGGGGGGGGB##BBBPP5YP&BPYJJJY555&B5&5Y555Y5PGB5555Y55B#PY5PGGPP5PG:#B5YP&?.:~~:..:::::::::::::::::.~
// BGGGBGBB##GGBBGGGPPPPPPPGGGGGGGGGGGGGGB#PP555P#BP555PPGBBGGBG5555Y55B#5Y555Y55BB55BG5JYGBP!:[email protected]?.:...:::::::::::::::::::.~
// BBBBBBBBBGPYPBBGGPPPPPPPGGGGGGGGGGGGGBBGP5Y5PPYGB####BBB55B#5Y55YY55BB5Y55555GGPP&G55GBP&P.::75BBY~.:::::::::::::::::::::::.~
// BBBBGG5PGPPYJJ5GGBGPGPGGGGGGGGGGGGGGB&#55Y5PP5YPBBP5PP55YBB5Y5555GG&#GY5555PG#GG#P5PB#PGG?.::.:~^..::::::::::::::::::::::::.~
// #BGPPBBBBBBBGPYY5PGB#BGGGGGGGGGGGGGB&BP5Y5PP5Y5##5555P5Y5#BY555G#G555GBGP55P&PG#G5#BGPP&?.::::...::::::::::::::::::::::::::.~
// GGGBBBBBGGGGBBBBGP55PGBBBGGGGGGGGGBGPP555PP5Y5BBG555PP5YBBPY55YB&[email protected]&GB#GBGGGBB&J::::::::::::::::::::::::::::::::::.~
// BBBBBBGGGGGGGGGGBBBBGP55PGBBBBGGBBBPP555PP5Y5B#G555PP5YP&PY55Y5G#BGPPGBBP5MTNTRHNCLLCTNB#5.::::::::::::::::::::::::::::::::.~
// #BBBBBGGGGGGGGGGGGGBBBBGP55PGGB&BPPP5Y5P55YPB#P555PP5YP#G55P5Y5B#GB##BGY5B#BBP5YJ13/08?5Y^.::::::::::::::::::::::::::::::::.~
// BBBBBBBBBGGGGGGGGGGGGGBBB#BGP55GBGP5Y5P5Y5PB#PP55PPP55G#5555Y5BBG555PPPGBGP5YYY5PPG##B?:..:::::::::::::::::::::::::::::::::.~
// BBBBBBBBBBBGGGGGGGGGGGGGB&BBBGP5PBBGP55Y5GBGP555PP5Y5B#P55P55P&B555GBBBP5YYY13MTNTRHNO:..:::::::::::::::::::::::::::::::::::.~

pragma solidity ^0.8.7;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MekaRhinos is ERC721AQueryable, Ownable {
  string public baseURI;
  string public notRevealedUri;
  string public baseExtension = ".json";
  uint256 public maxSupply = 3333;
  uint256 public maxMintAmount = 2;
  bool public publicsale = false;

  mapping(address => uint256) public mintedBalance;

  constructor() ERC721A("Meka Rhinos", "RHNO") {
    setBaseURI("ipfs://bafybeidr47rw7ez5sd5joiocl7d7je6korfvriju5rql7pqll6chatuzva/");
  }

  // ====== Settings ======
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "cannot be called by a contract");
    _;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
  
  function _startTokenId() internal pure override returns (uint256){
    return 1;
  }
  //

  // ====== public ======
  function mint(uint256 _mintAmount) public callerIsUser {
    // Is publicsale active
    require(publicsale, "publicsale is not active");
    //

    // Amount control
    uint256 supply = totalSupply();
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    require(mintedBalance[msg.sender] + _mintAmount <= maxMintAmount, "max NFT limit exceeded for this user");
    //

    mintedBalance[msg.sender] += _mintAmount;

    _safeMint(msg.sender, _mintAmount);
  }

  function ownerMint(uint256 _mintAmount) public onlyOwner {
    // Amount Control
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");
    //

    _safeMint(msg.sender, _mintAmount);
  }

  // ====== View ======
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(tokenId), baseExtension))
        : "";
  }

  // ====== Only Owner ======
  function setPublicsale() public onlyOwner {
    publicsale = !publicsale;
  }

  function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
    maxMintAmount = _newMaxMintAmount;
  }

  // Metadata
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  //
 
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}