// SPDX-License-Identifier: MIT
//
//
//                              ▐▌▀▀▀▀*∞w▄▄
//                       ╓▄▄▄mKK╣▌          ─╙?∞▄,
//                ,▄Æ▀▀╙└       ╞▌           ~.   └7w,
//             ▄▀▀└             ╞▌                .   └W
//          ▄▀╙              ┌▄▄██▄▄▄,              '    *
//        ▄▀¬        .~▄#▀▀╙└         ─└╙▀▀W▄▄        ^    ¼
//       █┘     .⌐` ,█▀' ,▄▀▀╙└└└    `¬.    ~ └▀▀▄,     ¼   \
//      █U  ,⌐     █▀  ╓▀└   ▄██████▄    `    ┐   └▀%▄   t   ┌
//      ▌,⌐`      ▐▌  ▐▌   ████████████        ─      ╙▀▄▐
// ¬┘   ▌^w       ╟µ  ▐▌   ████████████    >   ═      ,▄▀▐   └└
//  \   █   "w     █,  ╙▄   ╙▀██████▀╙   ┌┘   ╛    ,Æ▀└  ╛
//   ┐   █     ─"w, ╙¼,  └▀wµ        ,»⌐└   A└ ,▄▀╙     Æ
//    \   ▀▄       ¬"ⁿ═█╗▄,   ─└────    ▄p█═⌐▀┘       ,▀
//     "┐   ▀▄            └└╙╙7²%▌²7╙└└└            ▄┘
//       └V   └▀▄               ╟▌               ▄²└
//          └∞▄   └▀═▄,         ╞▌          ╓÷²└
//             ¬└Yw▄   ¬└└²²**≈═╫▌≈≈⌐⌐²²└└¬
//                   └┘ΓY*═▄▄▄▄▄╟▌
//
//
//                       The Order of Ink
//                Smart Contract by Ryan Meyers
//                      beautifulcode.eth
//
//               Generosity attracts generosity
//             The world will be saved by beauty
//

pragma solidity ^0.8.17;

import "ERC721AQueryable.sol";
import "Ownable.sol";
import "ERC2981.sol";
import "draft-EIP712.sol";
import "ECDSA.sol";

import "RevokableDefaultOperatorFilterer.sol";
import "UpdatableOperatorFilterer.sol";


contract OrderOfInk is ERC2981, EIP712, ERC721AQueryable, Ownable, RevokableDefaultOperatorFilterer {

    /* *//////////////////////,▄▄▄▌▓▓▓▓▓╬▓██
    /* *///////////////µe═Q▓▓╫Φ╙╨╙╙╨╨▀▀▀╬▒░░╚╩╚╙╨▀╝▀█
    /* *////////,╓##▀▀▀▄▓▀╬O└       ' ^"^└╨▀▄░;;└≈ç'j▓███
    /* */////▄#╨└.╗╩┌╓╬╠<└             '' '''╨▀▄^:▄▓▀╠▓███▓
    /* *///▄▀ ''φ▀░φ╟╫╙                '      ' ╨█▄▓▀╙^╙███▓
    /* * .▓▀^':╬╬░╓╬╩,µµ≈⌐TéM≤╓,  .. ..'..~.   ▄▓▀╙▀▄^.'▐j╠█▄ 
    /* * ╟▌^.╓▓╙.]▓▀╠═≈∞∞≈-µ╓└v#φ░≥>"""▒░"^^""╙█=«, ╙▓▄.^M╚╣█~
    /* * █⌐.]╬⌐╥▓╩░^7"µse⌐^^^╙╙¥╠φ▒░/w!└░░'⌐.       "ª╬▓▄@≤▒▓▓ 
    /* *▐█'.▓░╫▒╙)ε░░;;;,µµ¿:µµ,,╙╪╬7Φ▒▒δ░░φ,~   .'.."└(╙▓J▒║▓▌
    /* *▓▌^▐█▓▓▓▀▓▓▀▀▀╬╬▀╟╨╝▄▄╙Σb╪µ╙╣▒╨╬▒╦╠╬G┌.,,.~''.~┌>╫▒╢▓╬█µ
    /* *╫▌╫▓█╠╬▀╨!░░░¡¡∩>!└░Γ#╪╬╪▄╙╠╫▒╧▓╠╬╣╠╠░¡░"~',┌¡∩.~^▒,╙█▀▀
    /* *^█╫▒█▌╠!┌!]Ä╛5∩╦▄µ▄▄░≥≥░▒╫▓▒╣█▓▓▓██▓▓╩░j▓▓██▓▒▒~.,▒┌"╟,j▌
    /* * /▓█▓█░▒┌"▐▌#Γ╙│;=░≥=¡╨▀▒░╠╬████▓▓███▒"▓████▓▓██▓▓▄b/Σ███
    /* * /╫▓█▄▄▓▀▀▓╩▀▀▀▀▒╬▌▀▀▀▌▓█▓▌███████▀╫└╠████████▓███▄╣▄,╨█▌
    /* * /▄▀██▓▒φ∩!ÅQ╠╬δ╩╫╬▄▄╫╬▓█████████╣╬▀░;█████████▄██╬█████>
    /* * /╙╝█████▌▌▌▀▀▀▓▓█▓▓██████▓▓█████╩╬φΘε╨██▌███████╫██▒███▓
    /* *///╬╫▓███▓╫╬╬▓█████████▓▓█▓█████▒▒!└▓▌⌐╨╨▀███▀ .╣█╣¬████
    /* *///▐⌐╫╬████▀╬█████▓▓██▓╫╣▒▄▒╓░╚▀╬''.└"▀~'j╫*└\ ▐╫╩ ▓██╣
    /* *////:▌╣███▒Σ╨▀█████╬▓███▓▓╣╬╣╬╠░Γµ⌐⌐^;Q╛╙│^⌐^' ^ j███╫
    /* */////Å╠╬╣████╣▌╬████▌▓╣█████▓▓╬╬║▒j▓╨╥▄ε  1Θ╣╣⌐    ██╫▌
    /* *///E//└▀█╬███████████▓█▓████▓▓█████▓██▌ê, ⌐└╚▌ Q∩ `^▓█
    /* *////R/E//▀█╫███████████▓██▓▓╬╠╠▓█╨▀█████▓█▓▒]▐ ╬╠▌ ▌ ▓
    /* *///E/R/R//╙▓▄¡¡└╫███████▓██╬╬╬╠▓█  └╨███▓▓▀▐└▓▓▓╬▌⌐███▌
    /* *////R/0/R///╙▀▄▓████████▌▓█▓╬╟╬▓██┬~ ╙▀██████▄██▀╙ █Æ▀─
    /* *///E/R/R/0/R/S/██████████▓╬█▓╬╫╫█████▓▄█████████▌▌▄,╓
    /* *////R/0///R////]█████████▓▓╫███▓▌▒,▀███████████████╫█
    /* */////R/R//////'`██████████▓████▓▓╬║▌ ║╣▌▓▓╬╠▒▓╚=/▒▓ █
    /* *//////0/////////'╫███████████████▓▓▓▌╬▒▌▓█▒╣╬▓  ]▓▓▄▐-
    /* */error Paused();//─████████████████████▓▄▓▒▌▓▌╓╓╠╬▓╙ █ .
    /* */error InvalidMintKey();///╙╙▀╟█▌▄▌▄╠██████████████▓▀╩ ¬
    /* */error ExceedsMaxSupply();//╬╟╙▓█MΦW▄╫▓▓██▀▓█▌╬▀▓▓╬╙╛b
    /* */error ExceedsAllowance();//▓▌▀╙▀█     ╙▓██▌█ ┘╠█
    /* */error PublicSaleNotStarted();///╙▓▀▌▄┐ ╙████╨╙▓▀
    /* */error InsufficientAmountSent();///─  ╙▀██████╙─╙▄
    /* */error NoMoreThanTwentyPerTransaction();//▀███▌¬└
    /* */error WalletNotSender();//////////////////└╙
    // *////////////////////////////////////////


    
    /* C                 ,  */
    /* O               ▐ █ */ address private constant _TEAM = 0x5e5A5450548829Ad30B10Bcb81c4Cf5Fb609FEff;
    /* N               ▄██ */                   uint public constant SESSION_ONE_BLACK_PRICE = 0.08 ether;
    /* S               ╫█ ▓▌ */                   uint public constant SESSION_ONE_GOLD_PRICE = 0.4 ether;
    /* T           ▀▓▄ ▌█╜╟▌ */                uint public constant SESSION_TWO_BLACK_PRICE = 0.123 ether;
    /* A             ╙▀╝█▌▀  ▄ */                 uint public constant SESSION_TWO_GOLD_PRICE = 0.5 ether;
    /* N      ▐╣╣╣╣╣╬▀▄   ⌐▐█▀ */                                 uint private constant _maxSupply = 4444;
    /* T      ▐╣╣╣╣╣╣ ╙▀ █╦██▀╙ */                              uint private constant _maxGoldSupply = 67;
    /* S      ▐╣╣╣╬▓╣    ╚  █ */                              uint private constant _teamBlackMints = 150;
    /*        ▐╣╣╣╣╬█▌   | ╫█▀┌▄C */                            uint private constant _teamGoldMints = 10;
    /*        ▐╣╣╣╣╣╣w█=,╫▌▓▓█▀ */
    /* K      ▐╣╣╣╣▓▓  ╙▀▓└▀└ ▄▌ */
    /* E      ▐╣╣╣╬▓█▌   ┤   ⌠█Æ^ */   struct MintKey {
    /* Y      ▐╣╣╣╣╣╬▀=  ╪█▀╦▄▄▄▄ */       address wallet;
    /* S     ,▐█╬█╬▓╣ ▀▀▄╫Γ,▄▓█▄ */          uint8 free;
    /*     4╬Æ╬██████▌,  ╫ */                  uint8 allowed; }
    /*   Æ╬▀╬╙╚╝╩╝╩▓█▀▄▀µ▐ */          bytes32 private constant MINTKEY_TYPE_HASH = keccak256(
    /*  ▄▀▄▀         ▀▄▀▄▐ */                    "MintKey(address wallet,uint8 free,uint8 allowed)");
    /*  ▐╩X╛         └▄▀▄╟ */
    /*  ▐╬▀╬»       «╫▀▌▀▐ */              struct CombineKey {uint256[] tokenIds;}
    /*    ▀╬▀▄Æ▄*▄▀▄▀▄▀▄ ▐ */                  bytes32 private constant COMBINEKEY_TYPE_HASH = keccak256(
    /*      ╨▄╨▄▀▄▀▄▀    ▐ */                      "CombineKey(uint256[] tokenIds)");
    /*                ,,╓╫╓╓╓╓,, */
    /* V         ,φ▒╠╠╠╠╠╫╠╠╠╠╠╠╠╠▒╦, */
    /* A      ╓å╠╠╠╠╠╠╠╠╠▓╠╠╠╠╠╠╠╠╠╠╠╠▒╓ */    address private _signer;  
    /* R    φ╠╠╠╠╠╠╠╠╠╠╠╠█╠╠╠╠╠╠╠╬▒╠╠╠╠╠╠╔ */    address private _receiver;
    /* S  ╓╠╠╠╠╠╠╠╠╠╠╠╠╠╠█╩╩╩▓██▓╬╬╬╬╬▀▀▓██▄ */    
    /*   φ╠╠╠╠╠╠╠╠╠╠╩╙   ▓ ╓█╙  ╙╠╠╠╠╠╠╠╠╠╠╬╬ */  bool public paused = true;
    /*  φ╠╠╠╠╠╠╠╠╠╚      ▓╓█      ^╠╠╠╠╠╠╠╠╠╠╦ */   string public baseURI;
    /* ]╠╠╠╠╠╠╠╠╠╙       ██─        ╙╠╠╠╠╠╠╠╠╠⌐ */   uint8 public session = 1;
    /* ╠╠╠╠╠╠╠╠╠╙        █┌          ╚╠╠╠╠╠╠╠╠▒ */     uint private _goldMinted = 0;
    /* ╠╠╠╠╠╠╠╠╠⌐        ▌           ]╠╠╠╠╠╠╠╠╠ */   
    /* ╠╠╠╠╠╠╠╠╠ε       j▌           ]╠╠╠╠╠╠╠╠╠ */
    /* ╚╠╠╠╠╠╠╠╠╠       ▐⌐           ╠╠╠╠╠╠╠╠╠▒ */    constructor( 
    /*  ╠╠╠╠╠╠╠╠╠▒      ▓           ╠╠╠╠╠╠╠╠╠╠ */    string memory name, string memory symbol,
    /*  ╙╠╠╠╠╠╠╠╠╠╠╔   ,█         ╔╠╠╠╠╠╠╠╠╠╠⌐ */   address signer, address receiver
    /* C └╠╠╠╠╠╠╠╠╠╠╠▒█▌█▌   ,,╔▒╠╠╠╠╠╠╠╠╠╠╠" */   ) ERC721A(name, symbol) EIP712(name, "1") {
    /* O   ╚╠╠╠╠╠╠╠╠╠▓█╠███╠╠╠╠╠╠╠╠╠╠╠╠╠╠╠╚ */   _signer = signer; _receiver = receiver;
    /* N    `╚╠╠╠╠╠╠╠██╠█╠▓█▒╠╠╠╠╠╠╠╠╠╠╠╚ */    _setDefaultRoyalty(receiver, 1000);
    /* S       ╙╩╠╠╠╠██╠█╠╠╠▓╫╠╠╠╠╠╠╠╩╙ */    baseURI = "https://bafybeidmchhjl2nraifqwymp44s3vaemvewa5f65o5gpn6qztjliryadle.ipfs.nftstorage.link/";
    /* T          └╙╚╬█╠█╠╠╠╠╠╠╠╩╙╙ */  
    /* R    T         █ ▐µ */         _goldMinted += _teamGoldMints;
    /* U    E  M       ▌ ▌ */   _mintERC2309(_TEAM, _teamGoldMints);
    /* C    A  I       ╙▄▌ */   _setExtraDataAt(_startTokenId(), 1);
    /* T    M  N        ╙█ */   _mintERC2309(_TEAM, _teamBlackMints);
    /* O       T         ╫ */   }
    /* R       S         ╙ */


    //                                ,
    //                       "δ≥  φ╧╙└
    //                 ,,,,╓╓╦▄▓███▓╗╓,
    //    ,╦▄▓▓╬╬╣╣╣▓▓╣╫█▓╫▓██████████▓╬╠╬▓╬╬▓▓▒▒╦╗╓
    //  ,▓█▓█▓╬╬╬▓███▌╚▓╬▓█████MINT██████▓╬▓╩╬██▓╣▓▓▓█▌▄
    //  ▓╬▓███╬▒░▓███▌╠╣▓█▓███METHOD██▓▓██▓╬▒▓████╠╣╫██▓█#
    //  ╙█▓▄╬▀▀▓╣╣╬╣▀╬▓▓╫╣▌╣╬▓▓▒▓████╬▓╣╬▓▓╬▓╬╣▓█▌▌▓█▓██▓▓Ö
    //     └╙▀▓▄╟▀▀╣▓▀▀▓███▄▓▓▌▒╙▀██▌╣▓▄▓▓▓▓▓█▓█▓▓▀╠▄█▓▀▀
    //         └╙▀▀▓╣▄#╫███╫╠▓▒╬▓█▓█▒▒░▓███╫▄▄▄▄╣▓▓▀╙
    //             ▓▒╢▓▓▓▓╣▓██▓▌██▓██▌╣▌▓▓╬▓█▒█─
    //              ╙╣▄▄╠▀▀▀╬▒╥╨  ╙█╩▀▀██▓▀╬▄▓▀
    //                  ╙▀▀╙▀└     └╙▀╝▀▀▀▀▀└
    // *  For the sake of transparency, the code for the mint method  * //
    // *     will be unadorned. Please reach out if anything seems    * //
    // *   unclear or un-readable or insecure(!) Twitter: @sreyeMnayR * //
    //
    function getInked(
      bytes calldata signature, // a typed message (EIP712) signed with a secret private key
      MintKey calldata key,     // a struct representing the message
      uint8 howManyBlack,       // how many editions of 8 or 15 to mint
      uint8 howManyGold,        // how many 1 of 1 editions to mint
      uint24 choiceData         // a packed integer representing artist preference
    ) external payable {

      if(paused) revert Paused();

      uint256 nextTokenId;
      uint8 howMany = howManyGold + howManyBlack;

      // if there are free tokens in the mint key, check if they're already minted
      // if not, add them to the "howMany" variable.
      if(0<key.free){ howMany += key.free - uint8(_getAux(msg.sender)); }
      
      // if there aren't enough tokens left to fulfill the order... sorry, bye!
      if (totalSupply() + howMany > _maxSupply) revert ExceedsMaxSupply();

      // if not enough $ETH was sent with the transaction... sorry, bye!
      if (msg.value < (
        (blackPrice() * howManyBlack) + (goldPrice() * howManyGold)
        )) revert InsufficientAmountSent();

      // the first two minting sessions require a mint key (allow list)
      if (session < 3){
        // if the sender has already minted their allotment... sorry, bye!
        if (_numberMinted(msg.sender) + howMany > key.allowed) revert ExceedsAllowance();

        // if the sender isn't the wallet in the mint key... sorry, bye!
        if (msg.sender != key.wallet) revert WalletNotSender();

        // if the signed, typed message doesn't match the data sent... sorry, bye!
        if (!autoclave(signature, key)) revert InvalidMintKey();
        
        // if there are free tokens to claim...
        if (0 < key.free) {
          uint64 aux = _getAux(msg.sender);
          // if free tokens haven't yet been minted...
          if (aux < key.free) {
              // set the aux before minting to avoid reentrancy attacks
              _setAux(msg.sender, key.free);
              // add the free tokens to the black tokens being minted
              howManyBlack += uint8(key.free - aux);
            }
        }
      } else {
        // no more than 10 of any tier per mint transaction in public sale
        if(howManyGold > 10) revert ExceedsAllowance();
        if(howManyBlack > 10) revert ExceedsAllowance();
      }

      // if the mint includes editions of 8/15...
      if(howManyBlack > 0){
        // make sure there are enough black tokens remaining
        if (howManyBlack > blackRemaining()) revert ExceedsMaxSupply();
        // store the next tokenId. can't write choice data until it's been initialized.
        nextTokenId = _nextTokenId();
        // mint the tokens
        _mint(msg.sender, howManyBlack);
        // record the artist choice data
        _setExtraDataAt(nextTokenId, choiceData);
      }

      // if the mint includes 1 of 1 editions...
      if(howManyGold > 0){
        // make sure there are enough gold tokens remaining
        if (howManyGold > goldRemaining()) revert ExceedsMaxSupply();
        // store the next token id
        nextTokenId = _nextTokenId();
        
        // increment the number of gold tokens minted
        _goldMinted += howManyGold;
        // mint the gold tokens
        _mint(msg.sender, howManyGold);
        // include the choice data (+1, as the first bit indicates the tier)
        _setExtraDataAt(nextTokenId, choiceData+1);
      }
    // That's it!
    }
      
    /*                    ,,,,,,,
    /*            ,╔@▒╣╬╬╣╬╬╬╬╬╬╬╬╬╬▒╗╓*/
    /*         ,#╬╬╠╠╩╩╩▒▒╚╠╩╠▒╚╚╚╚╚╚╚╩╩╠╗,*/ function finalSession(
    /*       ,╠╩╚▒▒▒╚░░░░░░░╚░░░░φ▒≥Ä▒▒╩╠╬╬╬▒▒*/ bytes calldata signature,
    /*      φ▒Γ░!░▒░░▐░░░░░░≥╙░└░░░░░░▄▄▄╬╩╝╝╝╬╣*/ uint256[] calldata tokenIds
    /*     φΓ░ ';∩''ε╡░φ▒╜└  ''╓▄#▀╙╙└└''''~!└░╚▒*/ ) external {
    /*    ;░░  '  '~└╚²`  ',Æ▀╙.    ' ' ' '   ''!╙*/ if (!autoclaveCombine(
    /*    ░░⌐      ,∩   ,▄▒;;;┐,,.,┐,╓▄▓╗▄µ╓▄▄,,,,│*/ signature, tokenIds
    /*    ░░░.  .;ε'',▄▓╬╠╬▓▓███▓█▓█████▓╬▒┤╙╙└└└└└╠*/ )) revert InvalidMintKey();
    /*    ░░░;>^╙╣▄░#▀Γ░▒╠╠╬╣███████████▀╬╩╩∩  ^  ,╬*/ 
    /*    φ░░wµ ╙░╫█▓▄;φ▒╠╠╬███████╬▒;▐⌐╫▀. .,,;φ╠╠╠*/ uint howMany = tokenIds.length;
    /*    '░│░╣Q'¡░▓█▒╣▓▓▓╣╬██▓██▀╙╙▓╜╫▌▄"¥╢▓▒░░░░▒╠*/ for (uint i = 0; i != howMany; ++i){
    /*     Γ░▒╫▌░⌠▀╟█╬╫▓▓▓▓▓▓▓▌╙│▓ ▀▄░╠╬╬╬╣▓▓▓▄▒░░╠▒*/ _burn(tokenIds[i], true); }
    /*     ╙▌Å▀▒¡╓└╟█▒╣▓▓▀▓▓▓▀▀µ░░▓µ █▒╬╙╙▓╬╣▓▓▓░▒╠*/ 
    /*      ▓▌▄▓▄░]▓█▓╠╫▓╫▄  ╔ ╫φ▒╠╬▓φ▓▓█▓╬╬╬╬▓▓▒╠*/ uint nextTokenId = _nextTokenId();
    /*       █░▀▓▒▓░░╫█▒╣▓╬▓╗▓▓▓▓╗▓▓▓╬╬╬╬╬╠╬╬▓▓▓╬*/ _mint(msg.sender, 1);
    /*     ╓#██╬▓▓▓▓▄░╙╙▓▓▓▓▓█████▓▓█▓▓▓▓▓▓▓╬╬╣╣*/ _setExtraDataAt(nextTokenId, 1);
    /*   ╔▓▓▓█▒╠╣█╬▓█╬▒░¡╙╙▀▓▓╫╫╣╬╬╬╣╫╣╫╬╬╬╬╠╫╬*/ }
    /*  ╣▓╫▓██▌╠╝╬╬╬╬▒╠╠╠φ╦▒▒▒▒▒▒▒▒▒╠▒▒╠╬╠▒╬▓╩*/ 
    /* ▐╬╢╬╫█╩╬▀█▓▓▓▓▓▓▓▓▓▓▓▓▓▓╬╣█╬╣╫╣╬╬╫▓▀▀╙*/ 
    /*  ▓╬▓▒╬▒▄,▀▀▓▓█████▀▀╙╙╙╣▓▓╙╙╙╙╙└─ ,╗▄▄▄▓▓▓█*/
    //   ╚█▓▓╣╬▓██▓██╣╬╬▓▓▓▓▒▓╫╢╬▓▓▓▓▓█▓╣╬╬▓██████*/
    //     └╙▀▀▓█████▓╣▓███╣▓█▓╣▓██▓▓███▓█████▀▀╙*/
    //           └└╙╙╙╙╙╙╙╙╙╙╙╙╙╙└└└──


     /*                 ,▄▄Æ▓▓▓▓▓▓▓▓▌▄▄▄, */
     /*             ▄▌▓╬╬╠╩╚╚╚╙╚╙╙╙╚╚╚╚╠╬▓▌▄, */ function autoclave (
     /*          ▄██╬╚ΓΓ░░░└░░!!!!!!└└░░░Γ╙╩╬▓▄ */ bytes calldata signature,
     /*        ▄█╬╚Γ░░└:⌐".▄'^'.▄µ^'.,""":!!░╙╩╬▌µ */ MintKey calldata key
     /*      ╓█▀░░└"^'^███▄█▌''▓█ ▄████─'''"^"!░╚╬▌ */ ) public view returns (bool) {
     /*     ▄▓░░└^''''    ╙██▌ █▌█▓        '''^':└╚╣▄ */ bytes32 digest = _hashTypedDataV4(
     /*    ▄▀░⌐^''.      ╓████▄██▀▀▌▄    ,µ    '^┌'╚╫µ */ keccak256(abi.encode(
     /*   ▐╬░⌐'^^.      ▄██╫██▀░▓█████▌▓▀██     '.┌'╚█ */  MINTKEY_TYPE_HASH,
     /*   ▓░⌐'^^..     ▄█████bφ██▓╙└└▄▄▓████▄  .'''^!╠▌ */ msg.sender,
     /*  j▒░⌐~.~.    .████▓█▓▒▐██▀ :█╙└╙▓███J    ''~^φ█ */ key.free,
     /*  ▐▒░~.^~'    ████▓▓████▓▓¼Q█▄▓▀▓╫▌       ''^:░█ */ key.allowed )));
     /*   ▒░⌐.^~.    ██████┐~╙▀█▄⌐▐██▌  █─       .^.]░█ */ return ECDSA.recover(
     /*   ╬╚░.^~    µ▐█████ÿ¿ ^m╙╙└██████┬-▄⌐   .'.:░╠▌ */ digest, signature
     /*   └▒▒∩'^.'  ╙Q████▒░>  ╓''╥█▌╙███µ]▀    ''┌░▒▓ */ ) == _signer; }
     /*    ╙▒▒⌐'^.'. └▄████▌┌,Σ▌▀╙█b╙▓'╫█½╨  ..'^┌;▐▓ */
     /*     ╘▒▒░'^.~  └p▀███▄ " .██'.▀╦█▀╩  ...'┌░φ▓ */ function autoclaveCombine(
     /*      └╬▒░┌^... ╙µ└████▄╓█ ╙b╓██▀▀   ..,┌░╠╩ */ bytes calldata signature,
     /* C      ╠▒░-^... ╙µ ╙████▄;╔▓███╩ .....:φ▒▀ */ uint256[] calldata tokenIds
     /* H  S    ╚▒░⌐^... ╙µ  ╙███████▀╩  .'..:φ▄╨ */ ) public view returns (bool) {
     /* E  I     ╟▒░'┌^~' ╙µ  ^▒╙█╙└ ╩  '.,.┌░▓⌐ */ bytes32 digest = _hashTypedDataV4(
     /* C  G  M   ╠╚~\"^   ╫,,"▀¥▀,╓▌  ...,^]╠b */ keccak256(abi.encode(
     /* K  N  E   ▐░∩┌┌.~' ]█  ▄æµ █▌ . .^┌~φ▓ */ COMBINEKEY_TYPE_HASH,
     /*    E  S    ▒░:┌''~..█▄╣▄,█▄█T. '.┌┌,▐▌ */ keccak256(abi.encodePacked(tokenIds)))));
     /* E  D  S    ╟╠░\┌'^' ▐█▓╬██╣█ '..^┌:φ╣T */ return ECDSA.recover(
     /* I     A    ▀█▄▄▄▓▓▌▓▄╫╣╫▀W▓▓▌▌▄▄▌▓▓ */ digest, signature
     /* P  T  G     ╫██▓▓╬▄▄█████▌╠╫▓█████µ */ ) == _signer; }
     /* 7  Y  E     ╫▓╬╬▒Q,╓▄███▓░«╥▓█████ */
     /* 1  P  S      ████▓▒░╫████▒τ╫██████µ */
     /* 2  E         ▀████▓▒δ▓████Θ∞╫██████ */
     /*    D         ▄██▓▌╬▒Γ╫████░=╠██████ */
     /*              ███▓╣æs╣████G-╜██▓███⌐ */
     /*              ╙███▓▀╨╙╫████L.╠██▓██▓ */
     /*               ╙██▓▓▌▒▒╬╬╬╬╣╣▓▓▓███╙ */
     /*                 ╙▀███▓▓▓▓▓▄▓███▀─ */
     /*                    ╙████████▀╙ */
     /*                       ╙▀▀▀─ */


     /*                    .⌐≈*/
     /*      ,⌐"^ⁿ   ┌¬*  ┘    */ function setDefaultRoyalty(
     /*    ,.▌    j  ▐   ▐   ,═\``*/ address receiver, uint96 points
     /* ε`    ]──,╨¬}J   ⌐¬'\     */ ) external onlyOwner {
     /* └ç   j    ─  {┴∞*,  ,Γ```▀*/  _setDefaultRoyalty(receiver, points);
     /*   '7T─ⁿ╗-╫-─└│   ,▌─     */  _receiver = receiver; }
     /*   ┘    ▌  ╞Y `─ ƒ ⌐ \  ,*/ 
     /*  ╘  .─└└.,╛ \    */  function startNextSession() onlyOwner external {
     /*                  */   session++; }
     /*              Γ   */    
     /*  A           ▐   */   function withdraw() public payable {(bool success, ) = payable(
     /*  D            µ  */    _receiver).call{value: address(this).balance}("");
     /*  M          ,,╞ , */    require(success); }
     /*  I         ⌐   p⌡  */   
     /*  N         ▌¬¬¬╧▌¬¬`*/   function tattooReveal(string memory newBaseURI
     /*                 ▌    */  ) public onlyOwner { 
     /*           ┘    j ─   */   baseURI = newBaseURI; }
     /*           ─    ▐ ╘    */  
     /*          ⌠     ╞  µ   */   function eject() public onlyOwner {
     /*          b     │  Γ    */  if (blackRemaining() > 0) {
     /*         j      │  ╞    */   if (blackRemaining() > 250) { _mint(_TEAM, 250); }
     /*         ╞      │  ▐     */   else { _mint(_TEAM, blackRemaining()); }}
     /*         ▐      │  j     */    if(goldRemaining() > 0) {
     /*         j      Γ        */     uint _goldRemaining = goldRemaining();
     /*          ─     ═   ⌐     */    _goldMinted += _goldRemaining;
     /*          ▌    j    \     */    uint nextTokenId = _nextTokenId();
     /*          ╘    ▐     p   */    _mint(_TEAM, _goldRemaining);
     /*           \            ,*/   _setExtraDataAt(nextTokenId, 1); }}
     /*            \         ,*/    
     /*            '"¬───¬`'*/     function pauseSwitch() public onlyOwner { paused = !paused; }


    /*         ,▄████████▌╥ */
    /* H     ╓██████████████▄ */ function goldRemaining() public view returns (uint256) {
    /* E    ╣█████▓▓╣▓▓▓█████▌ */ return _maxGoldSupply - _goldMinted; }
    /* L   ╠▓▓███╬╣Å▒▒╠▌▌███▓▓▌ */
    /* P   ▌▓▓██████▓▓███████▓╬⌐ */ function blackRemaining() public view returns (uint256) {
    /* E  j╟╬▓▒ë⌂╕,    ,«TêÉ╫╫╠▌ */  return _maxSupply - totalSupply() - goldRemaining(); }
    /* R  ▐╠╬██▓▀╝▓╬  ╠▓▀╩╫██╣╠▌ */ 
    /* S  ▐╚╠▓╬▀Θ²╙└░,┘╙"²▀╬█╠▒▌ */ function goldPrice() public view returns (uint256) {
    /*    ▐╠╬╬╬ε   ç▒φ░   ,╣╣╠╠▌ */  if(session > 1) return SESSION_TWO_GOLD_PRICE;
    /*    ▐╣╬█'░░  ╙▀▀╙  ;░└█╣╬▌ */  return SESSION_ONE_GOLD_PRICE; }
    /*    ▐▓▓██, *Φ▓▓▓▓▀═  ▓█▓▓▌ */ 
    /*    ▐█████▄  ╙╙╙╙  ▄▓████▌ */ function blackPrice() public view returns (uint256) {
    /*    ▐████▌░╙▒╦╥╥╦#▀└╙████▌ */  if(session > 1) return SESSION_TWO_BLACK_PRICE;
    /*    ▓████░    └^    φ█████ */  return SESSION_ONE_BLACK_PRICE; }
    /*  æΦ█▀▓Q╩╞¼        6╡╝b╬▀▀▀╥ */
    /*  ╫,¥╬Åσ▐÷Γ¼¬    ⌐¥▐}Γ}Å╬Mç╝ */ function mintInfo() public view returns (
    /*   ╟-╚▄j¼m╔╛,`  "┐└æbMΓ▄╩-╢ */   uint256, uint256, uint256, uint256, uint256) { 
    /*    ²,╙▒░╥,"⌐  ¬ ."g╓│#▒.ó */   return (
    /*      X VÜε)  ⌐¬  τ,ÜΓ Æ */    goldRemaining(), blackRemaining(), 
    /*        *,`╚▄╠▒b╠▄Å^,<─ */     goldPrice(), blackPrice(), session
    /*          '╙qµ   µ╜` */      );}
    //
    


    /*               ▐ */
    /*               ▐▄ */
    /*               ▐µ */
    /*               ╫ */
    /*               █              ,..--.., */
    /*               █       ,æOΓ┘¬```` ¬~    `- */
    /*               █   ,▄▀╨                 `  . */
    /*               █ ▄▓▀       ▄▄▄             `, */
    /*               █▀▀  A└⌐     ███████▄        ╫▌ */
    /*          ¬  - ╚  ,╙ ╫      └▀███████       ██▄ */
    /*       '         Æ  ╒        ▄███████▓▄    ███▌ */
    /*      ⌐     , ' ╩   ╜  ' ,  '▓█████████▓ ╓████ */
    /*     Γ  ,-⌐ÆΓ▌╓╨   ▐ /    .φ▄██████████╓█████ */
    /*      ⌂   ╜ ▐▄┐. ''└  »[╓φÄ╠███████████████╙ */
    /*    ╫╚  ,╛  ┘     ..╓▄▄φ╠╣╬█▓████████████╙  */
    /*    ╚⌐  └:. '     ╥▄██████████████████▀─   */
    /*   '    .,»ⁿ~ƒ ╫█████████████████╝╩╩▀▀█▀  */
    /*    ▌ -/Ç ''.⌐~▐████████████╫████▓█ ⌐ ╞" */  function _startTokenId() internal pure override returns (uint256) {
    /*    ╟  '"²,.∩,╓▓████████████╬▓╬█████   */     return 1; }
    /*     µ    ┌∩░-█████████████▓▓███▓ ╠█  */
    /*     ╙╙▀▀█▄;»██████████▓▓█▌╬███▄▌ │ */  function _extraData(
    /*     ─█▄▀▀█▄░█▓▓▓█▓▓╬╬╢╬▒╟█╬███▄   */    address, address, uint24 previousExtraData
    /*       .,φ╚█░░╙╚┤░≤√≥░░Γ╚╫█▓████▀ */    ) internal pure override returns (uint24) {
    /*       ]▒φΓ█≥░▄▄▄>░7²⌠░φ╠▓██████ */       return previousExtraData;}
    /*       `╙╚▒╬▀█▀╨╛⌐»"'░░▒╬██████▌ */ 
    /*          └╟▒▓█▓▓▓▀Ü░φ▒╬█████▐█Γ */  function supportsInterface(bytes4 interfaceId
    /*         ,. ╬▀▌▓█▒░φ╠╬██████ └▀  */   ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
    /*          \   ╓▄╫╣╣▓████████    */     return ERC721A.supportsInterface(interfaceId) ||
    /*  O       ~²▄██████▀▀╙╙█▄██▌ ╓  */      ERC2981.supportsInterface(interfaceId);}
    /*  V         ╙╙└         ▐██▌ █  */
    /*  E          ^          ╫███ █µ */  function explicitOwnershipsOfAll(
    /*  R                     ████ █▌ */   ) external view returns (TokenOwnership[] memory) {
    /*  R                     ████ █▌ */    unchecked {
    /*  I                     ████ █▌ */     uint256 tokenIdsLength = _nextTokenId()+_startTokenId();
    /*  D                     ████ █▌ */     TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
    /*  E                     ╟██  █▓ */     for (uint256 i=_startTokenId(); i != tokenIdsLength; ++i) {
    /*  S                      ██  █╣ */       ownerships[i] = explicitOwnershipOf(i); }
    /*                         ██ b█▓ */     return ownerships; }}
    /*                         ██ ▄╫▌ */
    /*                         ╟█ ┼╫▌ */  function getAux(address _owner) external view returns (uint64) {
    /*                          █µ▐╚█ */    return _getAux(_owner); }
    /*                         j█ j│█ */
    /*                          █⌐j▐█ */  function _baseURI() internal view override returns (string memory) {
    /*                          █▌j╫█ */    return baseURI; }
    /*                                */ 



        
    //* */f u n c t i o n noRagrets(,▄▄▓██████▄▄╖
    //* */fu n c ti on noRagrets(╓█████████████████▌,
    //* */fun ctio n noRagrets(╓██████████████████████
    //* */function  noRagrets(Æ████████████████████████▄
    //* */function noRagrets(]████████████████████████████▄╖
    //* */function noRagrets(║███████████████╣▓█████╣████████µ
    //* */function noRagrets(╘███████████▓█▀▀▀    `╙▀██╣██████µ
    //* */function  noRagrets(║████████▓▀¬"²t    -ε≤o═╩██╣█████
    //* */function  noRagrets( ███████▌  ──. '          ╙███████
    //* */fun ctio n  noRagrets(╙████▀ ^⌐▀▀╛      ¬▀█.>   █▓▓████
    //* */fu n c ti on  noRagrets(╙█▌     ╘    `.          ▓▓████b
    //* */fu n c t i o n noRagrets(       <"""≥.           ╙▓╣███
    //* */fu n c t i on  noRagrets(╒     Φ≡╦╦╦╦╣ⁿ▄        '  ▓██▀
    /** */function/* */noRagrets(//(▀      ,,                 ║▌
    //* */f u n c t i o n  noRagrets(L                     , ^
    /** */uint256/*** ***/tokenId//(╬█   `-,              /`╖▄æ
    //* */f u n c ti o n noRagrets(@╬╬╔    :   |-  ∩╓]   ▄| Æ║╬╣╬µ
    /** */)/** **/public/** **/{//█╬╬╣▓⌐ ▐             »'   ██╬╬╬╣
    //* */ function noRagrets(//Æ╠╬╬╣                     ╬╬╬╬╬╬█
    /** */_burn(    //_burn( //,▓╬╬╬╬╣                    ╓╠╬╬╬╬╬╬
    //* */function noRagrets(╬█╬╬╬╬╬╬╣                   {▌╬╬╬╬╬╬╬█
    /** */tokenId,/** ***///█▀╓█╬╬╬╣╬█                   ▓ ╙█╬╬╬╬╬╬█
    //* */function noRagrets(█╬╬╬╣█▀ ▐                   ╙▄  ╘██╬╬╬╠█
    /** */true);}/* *///╓Æ█╠╬╬╬╬▀ ╞                       ╙█ ╪ ▐ ╙▀╬╠█╖
    //* *//**//**/╖▓╬╬╬█▀║ ║╬▀ ╛  Ç                        ╢█▄│     ▀█╬█▌▄
    //* *//**/╓Æ█╬╬╬▀    ∩╒█  ╒   ╚                     ,t^   ╚▀▄      ╙▀▓╬█╖
    //* */ ╓██▓███▀     ƒ╒█   ∩     k▄              ,▄─'      │    ▐       ╙▀█▄
    //* */  É  Æ       ,╓█   j        `▀º─▄▄-─╖J▀^            ⌐    ╞           ▀▄
    //* */ │          ┌{▀    ▐                                     Γ             ▀─
    //* */┌        .─⌐▀K*    ▐     𝕹𝕺𝕺𝕽𝕽𝔄𝕲    𝕲𝕽𝕰𝕰𝔗𝔗𝕾   ▐     ▌              "
    //* */╛   ,⌐ >   .≈*-          𝓝 𝓞 𝓡 𝓐 𝓖 𝓡 𝓔 𝓣 𝓢    [  ,▄,⌐                p
    //* */⌠ ,⌐     -     . ,╖.╘          𝕹𝕺𝕽𝔄𝕲𝕽𝕰𝔗𝕾        /▀^╙▄   `w
    //* */└~ⁿⁿⁿ~^└~╜ⁿ²  ─└~ⁿ╜ └ⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿⁿ²²²²²ⁿⁿⁿ~~~²~~~~~ ┴~~~┴┴~~~~╙┴~~~~~~~~~~~~╜      


    // Below are some overrides required by OpenSea's Operator Filter Registry

    /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721A, IERC721A)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev See {Ownable-owner}.
     *      Thanks, OpenSea
     */
    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns(address) {
      return super.owner();
    }

}

//
// Congratulations, you made it to the end of the Smart Contract! 
// Go mint a fork and feed someone in New Orleans: https://forkhunger.art
//