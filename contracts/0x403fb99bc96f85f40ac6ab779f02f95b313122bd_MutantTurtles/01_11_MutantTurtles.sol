// SPDX-License-Identifier: MIT

/*

   _______          _________ _______  _       _________         
  (       )|\     /|\__   __/(  ___  )( (    /|\__   __/         
  | () () || )   ( |   ) (   | (   ) ||  \  ( |   ) (            
  | || || || |   | |   | |   | (___) ||   \ | |   | |            
  | |(_)| || |   | |   | |   |  ___  || (\ \) |   | |            
  | |   | || |   | |   | |   | (   ) || | \   |   | |            
  | )   ( || (___) |   | |   | )   ( || )  \  |   | |            
  |/     \|(_______)   )_(   |/     \||/    )_)   )_(            
                                                                
  _________          _______ _________ _        _______  _______ 
  \__   __/|\     /|(  ____ )\__   __/( \      (  ____ \(  ____ \
    ) (   | )   ( || (    )|   ) (   | (      | (    \/| (    \/
    | |   | |   | || (____)|   | |   | |      | (__    | (_____ 
    | |   | |   | ||     __)   | |   | |      |  __)   (_____  )
    | |   | |   | || (\ (      | |   | |      | (            ) |
    | |   | (___) || ) \ \__   | |   | (____/\| (____/\/\____) |
    )_(   (_______)|/   \__/   )_(   (_______/(_______/\_______)
                                                               

  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#BP5YJ??777??J5PB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&YJJJJJJJJJJYPBBBBBBBBGGP5YJ?7!!!!!!!!!!!7Y#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@5JJJJJJJJYG#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#YYYY55PGBGGG##GGGGGB##BBGGGGGGBBGGGBBBGGGGBGGG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#####BBGGGGG#&BGGGG5JP#BB#BGGGGGGGGGGGGGGB#B&GG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&###BGGGGGGGGB&BBGGGB####GB#&###BBBGBBGG#&PGB#GG#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#######BBGGGG########BBBB#&#BGP5Y5PGB#&#####BGG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#######BBGGGG###BGGGGB#B5?7!!!!!!!!!7JG&#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#&#BBBBB####BGGGGGBBB#BJ!!!7Y?7????????JJ#B#BB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&5PJJ5?Y5PGBBBBBP55J!!!!!!J55JJJJJJJP5!?PY&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@[email protected]@@@@#@@@@@@@@@@@@@@@@@@@@@@@&#&G#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@BYPGGPJ?YG#&@@@@@@@@@@@@@@@@@@@B#&B#&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@#GGGG55YYY??JP&@@@@@@@@@@@@@@B&#B#&G57J#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@#[email protected]@@@@@@@@@@@@@B##B#@#[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@&[email protected]@@@@@@@@@@@B##B&@#[email protected]?77!!!!!!!7777?J?&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@@@@@@@@@@@@G5Y?!7&@@@@@@@@@@@G#&B&@#JJYGYBGY5Y55JP5GBP757YY775?JJ7757G7:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@@@@&&###&@@@@@@&##[email protected]@@@@@@@@@@G#&B&@&5P55PYJJ7J5PPPP5GYY5~JY:^G!Y5!!5YJ5:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@@@@[email protected]@@@@@@@@@@&G#@B&@@B?7JYY55GPGJ?JJ!P!?JJY5:Y7:!Y^:[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@@&&[email protected]@@@@@@@@@@@&G#@##@P??YPPBBPB?G?!7J^[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@#?7!?YY?JYYJ77?JYY5GYY#@@@@@@@@@@@@@@@&G#@&#5!?YYGPJPGP5YJ7!Y~~YJ7!!PY!!!!!!!!!?P7~J&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@&?77JP5P5555G#&&&#&&#&@@@@@@@@@@@@@@@@#G#@@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@&JYYYPPP#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@BG&@@&Y!!?PP5GG55PBPYJJJJJYYY?!!!!!!!!!!!!J#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@#GB&@@##[email protected]@@@@@@@@@@@@@@@@@@@@@@&#&@@@@@@@@@@@@
  @@&[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@#B#&@@#[email protected]??J??YJ!!JJG?!7?5B&@@@@@@@@@@@@@@@@@@@BPYYY?7??JG#&@@@@@@@@
  @@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@@&#PY???^JP^~5#5GBPGPGGPYY55Y55Y?7!PY5P#@@@@@@@@@@@@@@@@@@@@[email protected]@@@@
  @@@[email protected]@@@@@@@@@@@@@@@@@@@&GY!^~~^!YPPP~!55G~7PYJJJJ5GGYPGGPPJJJGJY7~~!YG#@@@@@@@@@@@@@@[email protected]@@@#[email protected]@@@
  @@@@[email protected]@@@@@@@@@@@@@@@@&GY7::~JG&@@@&G7~YP??55P?^:[email protected]@@&#GP?~!Y#@@@@@@@@@@@P!7YGP&@@@@@@&@@@&5YPGBG
  @@@@@#[email protected]@@@@@@@@@@@@&[email protected]@@@BY5PY?^557!7?7!::[email protected]@@@@@@@&[email protected]@@@@@@@@@[email protected]@@@@@@@@@@@@&##&
  @@@@@@@@GY5PPPY7JP#&@@@@@@@@P?^:[email protected]@@&GY7?J!7?J?PJ?JJJYYJ?J55JJ5B5Y55Y7?G?P&@@@@@@@@G^^[email protected]@@@@@@@G7JYPBP&@@@@@@@@@@@@@@@@
  @@@@@@@@@PYYY5YY7!7JYYPG&@@?.:!5&&GY?!~!7J7!7?YYJYYJJ?77?JY55PPYG5YJ??!YBYYYPBB#@@@@@B~^[email protected]@@@@@@#PP?J5YYPGB#@@@@@@@@@@@@
  @@@@@@@@@@[email protected]?77?7!7!7????7!!!!!!!~^::::!BYYPP5J7!?G~^^~!!!7J5GB#&?~~&@@@@@@@@&[email protected]@@@@@@@@@
  @@@@@@@@@@@@@@PYYY555PPY7?PYJ?!Y&J!!7?7?YYJJYPGJ!!!!!!!!!!!?55YYY???JY57~!!!!!!!?5PJ7?YYJPB&@@@@@@@@@P!77JYYYY5&@@@@@@@@
  @@@@@@@@@@@@@@&[email protected]&Y???YY!!!!~~^PJ~:~?J?77YPP555PPJ7GJ7!!!!!!!!!~~77J55JJ??7!?5#@@@@@@&[email protected]@@@@@@@
  @@@@@@@@@@@@@@@@&[email protected]~5JJ?Y~::~P7!5BGP555YYY555Y7PJ~?PGGPP5?~::JJY75YYY!JG7!~^J&@@@@@&[email protected]@@@@@@@
  @@@@@@@@@@@@@@@@@@J?JPPYYYYY5P&#JPJ~:::PYJJBJ77!7GG5YYY555YYYY555PJ^^&@GJ77YPJ~J5:!7~::?P7555P7:[email protected]@@@@@[email protected]@@@@@@@
  @@@@@@@@@@@@@@@@@?:^!7JPBBB#&BY~J!:::::P5YP#[email protected]??J?JYJJJ????:JP??7G5J?G&#[email protected]@@@@@@@
  @@@@@@@@@@@@@@@@B::!5P57YB5YBY7~5~:::::^[email protected]!!!~#&YYYJJYYJJJ?777JPGJJG5PY5YJYYP?75J??J5YP&@@@@@@@@@@
  @@@@@@@@@@@@@@@@5:^?B??YY?!7JPY^~5^:::::[email protected]~:P?!~!^[email protected][email protected]@@@@@@@@@@@
  @@@@@@@@@@@@@@#5G^~YG7!~^?7!7YGY??::::::::[email protected]#5YYYYYYYG5YY7~::^G?^:^?5#@PYYY555YYYY55YYYYY5P5PYYY5YYYYYYP#&@@@@@@@@@@@@@@
  @@@@@@@@@@@@@P7!YJJG??Y7:?5?JJJGP::::::::::~P##BGPPPP7::::::::75JYP?:^JP5YYJ5P555YYY5555YYY555PP55PPGB&@@@@@@@@@@@@@@@@@
  @@@@@@@@@@@@[email protected]?^^^^^^^^^:~??5PP5?^:^^^^^^^^:^~B&~^^::^^^:^!?JY55YJ7!Y#GGGB5?777#@@@@@@@@@@@@@@@@@@@@@

  The only official site:
  https://www.mutantturtles.club/

*/

pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract MutantTurtles is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;
  string public uriPrefix;
  string public uriSuffix = '.json';

  string public hiddenMetadataUri;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerWallet;
  uint256 public maxFreeMintAmountPerWallet;
  uint256 public teamSupply;
  uint256 public publicMintCost;
  bool public paused = true;
  bool public revealed = true;

  mapping(address => bool) freeMint;

  constructor(
      uint256 _maxSupply,
      uint256 _publicMintCost,
      uint256 _maxMintAmountPerWallet,
      uint256 _maxFreeMintAmountPerWallet,
      uint256 _teamSupply,
      string memory _uriPrefix
    )  ERC721A("Mutant Turtles", "MUTATED")  {
      maxMintAmountPerWallet = _maxMintAmountPerWallet;
      maxSupply = _maxSupply;
      uriPrefix = _uriPrefix;
      maxFreeMintAmountPerWallet = _maxFreeMintAmountPerWallet;
      publicMintCost = _publicMintCost;
      teamSupply = _teamSupply;
      _safeMint(msg.sender, 1);
  }

  modifier verifyTx(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply - teamSupply, 'Max Supply Exceeded!');
    _;
  }

  function mint(uint256 _mintAmount) public payable verifyTx(_mintAmount) nonReentrant {
    require(!paused, 'The portal is not open yet!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxMintAmountPerWallet, 'Max Limit per Wallet!');

    if(freeMint[_msgSender()]) {
      require(msg.value >= _mintAmount * publicMintCost, 'Insufficient Funds!');
    }
    else {
      require(msg.value >= (_mintAmount - 1) * publicMintCost, 'Insufficient Funds!');
      freeMint[_msgSender()] = true;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function setMintCritera(
    uint256 _maxSupply,
    uint256 _publicMintCost,
    uint256 _maxMintAmountPerWallet,
    uint256 _maxFreeMintAmountPerWallet,
    uint256 _teamSupply,
    string memory _uriPrefix
  ) public onlyOwner {
    maxSupply = _maxSupply;
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
    maxFreeMintAmountPerWallet = _maxFreeMintAmountPerWallet;
    uriPrefix = _uriPrefix;
    teamSupply = _teamSupply;
    publicMintCost = _publicMintCost;
  }

  function staffMint(address[] memory _staff_address) public onlyOwner payable {
    require(_staff_address.length <= teamSupply, '');
    for (uint256 i = 0; i < _staff_address.length; i ++) {
      _safeMint(_staff_address[i], 1);
    }
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

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setMintCost(uint256 _cost) public onlyOwner {
      publicMintCost = _cost;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setTeamAmount(uint256 _teamSupply) public onlyOwner {
    teamSupply = _teamSupply;
  }

  function payout() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable
    override
    onlyAllowedOperator(from)
    {
      super.safeTransferFrom(from, to, tokenId, data);
    }
}