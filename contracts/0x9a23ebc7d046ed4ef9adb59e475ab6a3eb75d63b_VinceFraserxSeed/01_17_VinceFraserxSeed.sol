// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "./helpers/Ownable.sol";
import "./helpers/Pausable.sol";
import "./helpers/ERC721AWithRoyalties.sol";
import {LicenseVersion, CantBeEvil} from "./licenses/CantBeEvil.sol";

/*
. . . .. . . . . . .. . . . . . . . . . . . . . . .. . . . . . . . . . . . .. .. . . . .. . .. . . .. .. . . . . . .  
 .:ttt;t;tt;ttt;ttt;t;tt;t;t;ttt;ttt;ttt;tt;tt;ttt;t;tt;ttt;ttt;ttttttttttt;t;t;;tt;ttt;t;tt;t;tt;t;t;t;tttt%ttttttt.  .
. 8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8  8 8  8     ..   
. 88             88             88                      8           88 8   8  .          88                       8.S   
. [email protected]     . .  .   .     .  . .  .   .    . . . . . .    .  .  .  .        . .. . . .  .  .   . . . .  .       .  .      
. @X888 .  8. . .   .. . . 8.  . .   . .  .   .  .8 .. . .  .  .  . . . . . .   .   .  .. . .  . .8 . .. . . . .  ..8   
. 8X     . . . . ..   .   .  .  . ..  . .  . . .  .   .   . .. ..  . .. .. .. . . .. . . . . .  . .  .  .  .  . .   @   
. [email protected]     . . .    . .  . . . .. .  .  . .  .   .  . .  .  .  .  . .   .  .. ..... . .  . .   . .8 .  .  .  . .  . 8X . 
. S 88  .    . . .  . .  . . ..   .  . .  .  . . . .  .  .  . .. .. . . .  . . 8  . ... .  . . . .  . 8   .8 .8 . .88   
. 88 88  . .  . . .    .  . .  . . .  . .  . 8   . ..  . . . .  .8 . .  . .   . .  . 8.  .  .   . .8SX 8   .  .  .  ;   
. [email protected]@ 8   . . .    . . . . . .  .   .    .8X 88  .  .8.8.  .  .  .  . . .  ... . .  .  .  .  . .    8 8 8 .8.  .    8;. 
. SS 8   .  .  . . .  .   .   . . .  . .    8 8   .. .  . .  . . . .  .  ..   .  ..  .  .  .  . .   8 8    . .  .     . 
. [email protected]@     .  .  .   .  . . . .   . .  . .        .  . .  . .  . . . .  .   .  . .8 . . . . . .  .. 8     .    . . . .   
. 8X @8  . .  8    . .  . . . . .   . .         . .    .  .8.  .   . .  . . .888 8 .  8     .8.   .     . . . .  .      
. [email protected] 8     .8 8 8  . .   .    .  . .  .       .  . . . .    .  . .   .8 . 8 @ 8 ....  8  .   . . .  . .   .  . .   ; . 
. 8SX 8  . .   8   .   . . . .  . .  .  . . . . . .  .   . . . . . . . .    8 8  . .       . . . . .  .  .  .  . ..     
. [email protected]    .8 8 8    . 8 8 8 . . .  .  . .  .  . .  .. . . . .8.   . .   .    8    .      . . . .  . .  .  .  .  .   : . 
. 8S 8     .      .  8 8      .  . . .   .  . .  ..  . . .. . . .   ... . .      . .     .  .   .  . . . . .  .  .      
. [email protected]@    .  .  . . .   8   . . . .  . . . .  . .  .. .. .8. . . ... .  . .          ....  .  . . .  .   .  . . .  8.8 . 
. 8X 8    . ..  .         . .   . .   .    . .  .  .   . .  . .  . . .    .   . . .. .. .8 .  .  . . .  . .   . . . .   
. [email protected]@      .:.:  . .       .  .    . . . . .  . . . . .  . . . .  . . . .  . .  .  8  .  .  .  . .  . .  .  .   .   8;. 
. SSX  8 .  . .  8  . . . . .  . .  .   .   .  . .  .  .  . .  . .   . . .8 . .  .8 8  . 8   . .  .  . 8    . .  . 88. .
. 8SX8 8  .  [email protected]    .  .  . . .  .  . . . . .    . . . . .  ..   ..  .  .. .  .    888X 8   .  . . . 8 8    . .    . . 
. 8X 8     .   8    . .  . .. . .  . 8    .   . .  . . . . . .  .   . . . .  . .     8 88 8   .  .      8  .. . .   8;  
. [email protected] 8  .   8 8    .  .  . . 8   8X 8   .  . . . .  . . . . . . . . . .   . . . .          .  .  . .       .   .     . 
. 8SX8    .        . .  .  8XX      8 8   8    .   . . . . . .  .  .  . .. .  . .  .   8     .  .  .      .  . . .  :   
. 8X 8     .       .  .  .   888  8 8    8 88   .. .  . .......  .8 .  .  . .  . . . .     .  .  .  . . .  .. .         
. [email protected]    .  .   . . . ..   8 8    8 8  .   8  .  . ......  .   .  .  .  . .  . .  . .  . .  .  .  .  .  . .  . . .  ; . 
. 8SX  8  .  . .   .    .   8       .  .      . . .   . ..  . .8. . . .  . . .  .  . .  . .  . . . .  .  .  .   .       
. 8XX8     . .  . . . .  . 8 8  . .  ....  . . . .  . .   ..  .  . . . .    . .  .    . .  . .  .   .  .  .8 .8. .  : . 
. SS 8  8.  . .  .   . .  . . .  .  .  . . 8 8  . . . . ..  .  .  .. .  .. .   . . . . . .  . .  . . .  .  .  . .       
. [email protected]@    8.    .  . .   .  .   . .8.  .  8 8   . .  .. .   . .  .. . . .  . . .  .  .   . . .  .8.  . .  . . . . .  ;   
. 8SX      . . ..  . . . .  . [email protected]   . .  8 88  .. .8 8  . 8    .  . . . .  . . . . . ..    .   . . .   . . .    . .   . 
. SSX8   .  . . .. . .  . .  8  8 . .     8    ...8 8   .  88   .  . .   .  . .  .     . .  ..    .  . . .  . .    .: . 
. 8X 88  8.  .   . . ..  . .  8 8 . . .       .  8 8 8      8  ...  . ..  .  ...  . . . . .  . ..  . .  . . . . ..      
. [email protected] 8    . . .  . . . . .  8   . .  .      .  .   8  .      ... .  .  . . .   . . . .  . .  .  . .8 . 8.   . .  8 @  .
. 8X 8 8 .   .. 88 . . .  . .   . . .  .  . . .  .   .. ...  . . . .. . .  . . . . ..... .  . .. .  .  8    .   . . : . 
. [email protected]@ 8   . . 8X 8  . . .. . . . . . .  .  . .:;%[email protected]%@[email protected]@@[email protected]@%.;8S8 .. . .   . .   .  .  . . . . . .  8  8   .  .8   . 
. SSX 8    . 8 8     .  .   ..: .   . .  .  8888S8S;XXt88:XXXXS;XX%888%    . . . . .... . . .  .  .    88 8 . . .       
. 8SX8    .   8 8   . . . . ...  ..    .  .8 8888St%ttXX;@t%[email protected]@8X;:%;S%%%8.. . .  :%8   . .8 . . . . .8 8  . .   .  t . 
. 8X 8     .     8 .  .  . .   .  8   . .. 88%Xt:tS%[email protected]@%[email protected]@ ::88 8  .. t8%;   . .  .   .         . . .       
. [email protected]    . .        .  . .  . . .8 8    . 8888%@[email protected]@SS%SS8S8X8SXtXS8;S.:8tSt 8   :8% . .   .   .  . .  . .S   8  8 @   
. 8SX  8    .   . .  .  . . . 8.8 8    . SSt%%@[email protected]%[email protected]@[email protected]@[email protected]: . ...S;X:8:[email protected]%%888 .. . . . .  . .  @ 88  .      .
. 8XX8 8   . . . . . . . .  . .       . 88 :88t;;t%@t88%%X [email protected] %   t8X [email protected] 8   . . . .  .  .   8 8 8  . .% . 
. SS 88 8. .  . .   .   . .  .      .. [email protected]%@t:.;.8%.X8 X %X;88 [email protected] 8;888X  :8St : t888    . .  . .  .  . 8 8    .       
. [email protected] 8    .8.   ..  .. ..8. . .. .  . 8X%[email protected] : S;t888 @ @8%[email protected]:[email protected];tX:[email protected]%;;%.;%X8 8   .   . . ..  ..    8   .  . 8   
. 8X 8 8  .8  . .  .  .88 8;8.:... .:[email protected]@tXtXS %%8X8888X:;;%@%%@8X.S%t%. [email protected]@8.;;88 88   .. .  .  ..  .        .   :   
. [email protected] 8    . 8   . [email protected]:8;  [email protected]:..:;SX%88SS88X%@tSt888888: .:[email protected];t8%[email protected]:@X 8 8   .   .  . . .  . .  . . . [email protected] . 
. [email protected]    .   8 [email protected];::  .   :;;X8888X: @888X%@X  8   ;.X   ;;S8%XS88S.. 8S. ;@88S8:8   . . .  .8    . . .  . .    88. .
. 8X 8          ;8. .....    .:;:.:%[email protected]%@X8888;   [email protected]   S  X 8 .%XS. [email protected]@  8.  . .8S     . .  .  .  .88 :.  
. [email protected]    .    [email protected] ....::::;:::.::[email protected];;;;;:...   .::t8S   [email protected]@8 88XX.X;      :ttX ::X8 .. . .8 8  8 .  . .8.  .8 @ 88.  
. @XX  8  .  :@8%. .....::::SS;;:;;::::;:..... ...:::.;@tS%8X8:8 888 ;:@:t%%X 8:[email protected] .. .8 8      . .   8. 8 8 8 8t. 
..8X 8 8   .. 8Xt:......:....:;;;;;tt;::.... .. ..:t8t8X%X%.:88;[email protected];X.Xttt%@[email protected];tt: 88.88:8X:[email protected]%8  . .. . . . 8 8 88.. 
. [email protected]@    .8 [email protected]:........  .::;8tS8:tttXS;St88X88t:.:;8888SXttt::tt;@X8888X%;%[email protected]%8X88X8S;[email protected]%%  .  .     8 :   
. SSX    8.  .8%S:.. ...   .:::;;@:@  S..S8XX88X;8S88S;[email protected] XS888888S8 ;tX;;[email protected];:.;t;;;t;[email protected]@X8  .  .        . 
. 8SX8  8  . . 8X:..... ..;t;:.::..:t:88 @ t8t X8.%%  8  8:: [email protected];@[email protected]@88X;:...;[email protected] %8SX;:::;;;tttXXXXX%88   .  .     %   
. 8X 88  .  .  ;8t;X8;:..;t;:..... S. ;%8...::..    %X t8:888:@ %[email protected]@.S:8; ;:%;88%.....:;t;t%;[email protected]@[email protected]   .  . .      
. [email protected] 8   .  . tX8%88t:.:;;:...... [email protected] ..:::::::. .; t%[email protected]@88 S;t% 8X [email protected]  8888;.....::::;;[email protected]@ 8 8  .. .   S . 
. 8SX 8   . .. .8%@[email protected];:tt;........:8t8 .:...:.:.... %S;  : [email protected];:.X   S :88XtS t X8X:tt:......::;%@[email protected] 8  . . .  .     
. 8XX8 8  .   .  8%8%tt;;t:........;@%@t..::::::... . tXt.SX  ; ..; % [email protected]:% t ;SX:t8t..X ......;[email protected]: 8    . . .   : . 
. SS 8 8   . .  8 [email protected]%;:.......t;@8..:;:;%88tXS;8;tX88 S  :;:.;8 8;[email protected];t ;8%888;;[email protected]%@@8 8  .  .   .    . 
. [email protected]   8.  .     :;888;8XX;tt:...:[email protected]:SSX888S:: :;::[email protected]%@S8;@.: [email protected]:8t%[email protected]@ Xt ;X ; [email protected] 8    .  88        
. 8XX     .  . . .  88;;;%X:@@. ...;:;; :88X%S:::%@;XX:::@8t;XX%t.Xt8  [email protected]% @.t;tt;;S% ;:@[email protected] 8   .  . @     8t. 
. 8SX88    . . . t88Xtt;X8XSX.:....:::;[email protected];;tt;XXX%[email protected]  [email protected]%:X @.:8;X::[email protected]%[email protected]@[email protected]@  .  .   8     .   
. @X 8   . ... ;[email protected]%tt;tXXS::::;t:...::;;t8StS;tt%;;:tt;t88t%t%%;::;[email protected];[email protected];% :8X8t:X.  8 88%X 8 8   . .    8    t . 
[email protected]@ 8   . .: [email protected]%;8S..:.;S;:;8:....:;8t;;%;tt%%t;;;;::X8%:;%:8X;[email protected]%@[email protected]@8t:@ %;  @;X:[email protected] [email protected]:8 8   . . .    .  8;  
. 8X 8     . :8SX;%%@@;::..X8%%%tt;....::;;%t;;;%;:;;::. [email protected]:.%SS;::  .t:. Stt X8 [email protected] :;@ 8 %tXS8  8 .   .  . .    .
. [email protected] 8 . . :8tS8X;::::....t8%8;;%t:......::[email protected]@t%t;;;:..;8: %St%S:.::. 8 [email protected]  X 8 8 tS8.. :tX;[email protected] . ..  .  .  : . 
. 8SX 8  .  [email protected]@8X.::......::S888:;;;;:.......;[email protected];[email protected]:;..:;@8tt%StS8S;8  SXt:  [email protected] [email protected] @:::.::;SX%; :8     .  .. .     
. [email protected]   . %8tXX..........:;t8888.::::::.:..:;::::@ttt::.;[email protected]@[email protected]@8S8tX%8X XS @ %@[email protected]::..:;;%[email protected]%:8   . .  .   :   
. SS 8   . @:@t:.........:@[email protected]:;;:ttttXSX:;Xt;:.%@XXSSSXS%SS%: %%8SS [email protected]@X;.8% :...t%%t%[email protected] 8  . . .    .
. [email protected]@     8S Xt;:.... .. :[email protected]@88;:...;;::tXt%%888;;;:.:88:[email protected]@@[email protected]@%8..tXX @[email protected]:8%@% ...:%X;t%S8888%.%8   .   :   
. 8SX     88:8;:..... ...;8S%@@t88X;:.....:::%@tSXXS;;:[email protected]  .t%%S%[email protected]%X;X8 [email protected]@X888t:..::;;8t;;t88t8X 8   .  8t .
. SSX8    88;%t::..  ....:%[email protected]%[email protected];;:....:::%tXS:S:::;;.tS;.. ;t%[email protected];[email protected]  % 888;%%8S ....:.:t;;;t:SXS:8 .      . 
. 8S 88  8 8:.%.... .....;X:8t8::;[email protected];;;:...:t8X%tt;:;X:::;@@XX%%[email protected]@%[email protected]:t;8S. @ X %X88:;.   ....:tSt%St;;S8 8 . . %   
. [email protected]@ 88 8 8t8t:.. ......;[email protected]@tS8XSS%;;:...:;@X8X:::::..:.tX8;.tSXS8XXt;;:@S 8% S [email protected];8:.......:;XSXtt;%88          
. S [email protected] 8   8.:;:.........8t. [email protected]@@;;;;[email protected];[email protected]@%t%X8%S%tt;..:8; [email protected] XX.88S;8X8.......:t%[email protected]@%;:%.  8 . 8   
. .8 8 8  [email protected]:::.........:8:. ..:;[email protected]@8.%t;%S:SSt%[email protected];:8;.::[email protected];;[email protected];:....8; @@S [email protected] [email protected]::[email protected];%88;.;888    .  .
. @ 8 8 . [email protected]:.......:S;:[email protected]@[email protected]@S.;:;;;;::;t:[email protected];;SXXSt;t8t:.... ;8S% @ %:8. X8888;8;.:[email protected]%88S.:@8     8t  
. X8 %888;[email protected];@@t;[email protected]@;t;;;tt%8X::@8%;.8;@S:;@XXt;:..  .:8S @[email protected]%X 88X8S:@@::[email protected]@SSS%@@t:.%8  8    . 
. S [email protected]@X 8 8%88... .tt::::.:[email protected]:8  S;t%88888X;:[email protected]::8S%@@[email protected]%t%;.    .t  tX%tS;@S %@X;:.;XS:[email protected]@[email protected]:8X   8  t . 
. X8 88%8  X;[email protected]@8;tX8S;:::.....88%S:;tt;;t%[email protected];t88XX88888888tX8SSStSX%:.   .8S8 @8 .X8 tS 8:@:t%%@%8t%%%%[email protected]@    .     
. [email protected] :8 t%;@[email protected]:...::....:XXStt%%[email protected]@[email protected]%%t88:8::;t;t%%X;:[email protected]@888.;S%%:t;8S;8t X   :;@[email protected];[email protected];t8  ; . 
. X 88;[email protected]:XtS  [email protected]%...::::..:..X8%Xt8S.   : [email protected] :[email protected];888;::;[email protected];SX;;@@@..8X;[email protected];%tS%[email protected]@[email protected] .   
. @  88tX.;@8 SS.S8888X::..;t;::::;;[email protected]@ :8  . ..:[email protected]: @[email protected]@[email protected]@@S   %@XSS%t8St:SSX:  .%8X.;:.:@:S%X:;.X8Xt;88Stt8.. 
.  8%;8S t;;.8t%[email protected] :.;@8t;:..:;;:. X:@@% %8 88SX  88.:::;;[email protected]%StX 8;8 [email protected]::%8St8tS8:.. ;%:@%tt8S%Xtttt88:. 
. 8888t. ;::8;[email protected]:.::S%t88;..:X:.. :[email protected]@:@X:t   Xt:8 S8ttt;;%X8S%[email protected] @: %::%[email protected]:;:XX8 :..   @S%%;[email protected]@@..t8:. 
. 8t%:[email protected]:@: %8888888.:t8%%@;8: ;@:.....:@[email protected]@@[email protected] 8S ;%; X:8;%[email protected]@:[email protected]@[email protected]:8:.   ;88 %;SS%@:tX8;. 
. X8t:tt.t.SX .X88888;:[email protected]@:........:[email protected]@@[email protected];     : ;;    [email protected]@[email protected]%: :[email protected]@@;t% X...;@@8t8%@8t88XX . 
.  ;;:::t 8XX8 S8888S:;%[email protected];[email protected]  .  .......:%[email protected]@888. % ;SS%;  ;8t;t;;t%[email protected] 8;;@[email protected]:..;;[email protected]:[email protected]%8.. 
. @.::.X X8X%  [email protected];;;t888:@ [email protected]%@8t8.  .;X;;:. .::..;;X8;t888S.      [email protected]@@8;%%X: @88t%%8t8%[email protected]@t8;;;t;S;:[email protected] . 
.  :;[email protected]:  8S88;t;:;t%%[email protected]@;:  t:@..8S88:;::....::[email protected]%;:[email protected]@X % t:@@t;8X;%;[email protected]%:X:[email protected]@8%[email protected]% . 
. [email protected]@[email protected]@88% 8 @[email protected]@[email protected]@8888XSX8t888S.8X 8.t8.88 [email protected]@[email protected]@88::S:@ [email protected]@@[email protected] . 
   :;.t%SX;  :t:;:;:; S8%X:  [email protected]:   .;%SSt;t   .:    ::; .:   .t:t; :;: . :   t: .     ;;; :%; :.:%%;[email protected]::::; .  
   .   .         .      ..      . .       . .                         .   .               .             . .. .  .      .
*/

contract VinceFraserxSeed is Ownable, ERC721AWithRoyalties, Pausable, CantBeEvil(LicenseVersion.CBE_PR_HS) {
  string public _baseTokenURI;

  uint256 public _price;
  uint256 public _maxSupply;
  uint256 public _maxPerAddress;
  uint256 public _publicSaleTime;
  uint256 public _maxTxPerAddress;
  mapping(address => uint256) private _purchases;

  event Purchase(address indexed addr, uint256 indexed atPrice, uint256 indexed count);

  constructor(
    // name, symbol, baseURI, price, maxSupply, maxPerAddress, publicSaleTime, maxTxPerAddress, royaltyRecipient, royaltyAmount
    string memory name,
    string memory symbol,
    string memory baseTokenURI,
    uint256 price,
    uint256 maxSupply,
    uint256 maxPerAddress,
    uint256 publicSaleTime,
    uint256 maxTxPerAddress,
   // price - 0, maxSupply - 1, maxPerAddress - 2, publicSaleTime - 3, _maxTxPerAddress - 4
    address royaltyRecipient,
    uint256 royaltyAmount
  ) ERC721AWithRoyalties(name, symbol, maxSupply, royaltyRecipient, royaltyAmount) {
    _baseTokenURI = baseTokenURI;
    _price = price;
    _maxSupply = maxSupply;
    _maxPerAddress = maxPerAddress;
    _publicSaleTime = publicSaleTime;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setSaleInformation(
    uint256 publicSaleTime,
    uint256 maxPerAddress,
    uint256 price,
    uint256 maxTxPerAddress
  ) external onlyOwner {
    _publicSaleTime = publicSaleTime;
    _maxPerAddress = maxPerAddress;
    _price = price;
    _maxTxPerAddress = maxTxPerAddress;
  }

  function setBaseUri(
    string memory baseUri
  ) external onlyOwner {
    _baseTokenURI = baseUri;
  }

  function _baseURI() override internal view virtual returns (string memory) {
    return string(
      abi.encodePacked(
        _baseTokenURI
      )
    );
  }

  function mint(address to, uint256 count) external payable onlyOwner {
    ensureMintConditions(count);
    _safeMint(to, count);
  }

  function purchase(uint256 count) external payable whenNotPaused {
    require(msg.value == count * _price);
    ensurePublicMintConditions(msg.sender, count, _maxPerAddress);
    require(isPublicSaleActive(), "BASE_COLLECTION/CANNOT_MINT");

    _purchases[msg.sender] += count;
    _safeMint(msg.sender, count);
    uint256 totalPrice = count * _price;
    emit Purchase(msg.sender, totalPrice, count);
  }

  function ensureMintConditions(uint256 count) internal view {
    require(totalSupply() + count <= _maxSupply, "BASE_COLLECTION/EXCEEDS_MAX_SUPPLY");
  }

  function ensurePublicMintConditions(address to, uint256 count, uint256 maxPerAddress) internal view {
    ensureMintConditions(count);
    require((_maxTxPerAddress == 0) || (count <= _maxTxPerAddress), "BASE_COLLECTION/EXCEEDS_MAX_PER_TRANSACTION");
    uint256 totalMintFromAddress = _purchases[to] + count;
    require ((maxPerAddress == 0) || (totalMintFromAddress <= maxPerAddress), "BASE_COLLECTION/EXCEEDS_INDIVIDUAL_SUPPLY");

  }

  function isPublicSaleActive() public view returns (bool) {
    return (_publicSaleTime == 0 || _publicSaleTime < block.timestamp);
  }

  function isPreSaleActive() public pure returns (bool) {
    return false;
  }

  function MAX_TOTAL_MINT() public view returns (uint256) {
    return _maxSupply;
  }

  function PRICE() public view returns (uint256) {
    return _price;
  }

  function MAX_TOTAL_MINT_PER_ADDRESS() public view returns (uint256) {
    return _maxPerAddress;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
  function supportsInterface(bytes4 interfaceId) public view virtual override(CantBeEvil, ERC721AWithRoyalties) returns (bool) {
    return
        super.supportsInterface(interfaceId);
  }
}