// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./PlanetCrossword721.sol";
import "hardhat/console.sol";

/*
                                      ,,,,,ww,,,,,
                              ,a##M""`       ,#########mw,
                          ,##@#^            #################w
                      ,##",;#Qemmmmmmmmmmmw###################`%M,
                   ,##M""7#################   `""%W###########    7m
                 ,#"    ##################             `"%@###      `@p
               ,#"    ,##################                   j#%@m,     @Q
              #M     ,##################                    ]#    "@m,  `@
            ;#      ;##################                     @b       `%#mj#m
           ##      {##################                      #            7###
          #M"`````@#``^""""%WW#######Q                      #             @#@#
         @#      ,#                {#`""%W#Mm,,            ]#             j# ^#
        ]#       #                ,#           ^"%WMm,,    @b              #  ]b
        #b      @b                #                   `"%WM#,              #   @
       ]#      ,#                @M                       @b ""WMw,        #   ]b
       @b      #b               .#                        #       `"%Mw   ]#    #
       ##m     #                @b                       @#            `"@#Q    #
       #b "%m,@b               ]#                        #                ####m #
       @b     ##M,             #                        @b                #######
       @b     #   "%@m,       ]#                       ,#                @#######
       j#     #        "%@mw, @b                       #                 #######b
        @b   j#             `j##Mw,                   @#                @#######
         #    #              @#########Mm,,          ,#                ]#######
         "#,  #              ###################mm,,,#                ,#######b
          "##m#             .########################C""%WM#Mmmw,,,,,,########
           "# @#,           @########################                #^    @"
             @##`%#w        @#######################                #     #
              "#b   "@m,    #######################               ,#    @"
                %#      "WMw######################               {#   sM
                  "#,       #"W##################               #"  #M
                    `%m,    #     `"%W##########              a#,s#^
                       `%M, #              ``@#"%%WWWWWWWW%"@##M"
                           "%#m,            #"          ,a#M"
                                `"%M#mmw,,,#,,,,,sm##M"`

                                         HOVERCATS
                                   PLANET CROSSWORD 2022
                            https://hovercats.gg + hovercats.eth

*/

contract PlanetCrosswordPublicMinter {
  mapping(address => bool) private _mintedPerAddress;

  error AlreadyMinted();
  error SenderOriginMismatch();
  error NoMoreTokensAvailable();
  error WithdrawalFailed();
  error Nope();

  PlanetCrossword721 immutable public planetCrosswordContract;
  uint256 immutable public initialSupply;
  address immutable public paymentRecipient;
  mapping(bytes32 => bool) answers;

  constructor(PlanetCrossword721 _planetCrosswordContract, uint256 _initialSupply, address _paymentRecipient) {
    planetCrosswordContract = _planetCrosswordContract;
    initialSupply = _initialSupply;
    paymentRecipient = _paymentRecipient;
    answers[0xdcce26b484ec1f5fd04a173032aa88014cd7d52c2b1b6f87b975a7ec6ddd57ff] = true;
    answers[0xd9181f11cd3a0079075d0a00cea1b27c720525104b87111bbae5ec5d5069185f] = true;
    answers[0xfd0b3c5ae2780a6eb53b76c45a078fdec2bbda402a0c69d093afc1772713efc0] = true;
    answers[0x6061b7f7186c39b426d88110bff5ec57ce46001d3f564699873a1554cf9b2407] = true;
    answers[0x91045386b56b7ab7d68cb3b8b6e1b0cf5efac24401a6e85b3e22f3a3f9aa1b54] = true;
    answers[0xce71d9fe1f116a2a47d192f044da28e5ef9024f3a37c3bb94dd64bb71d9991c2] = true;
    answers[0x5d615ad14dc8824ace7f8a207fdc021c88b74379f42470bd64bd4c967016994d] = true;
    answers[0x567779674742a8d545c46388243f78ea752170b1c12579491ec3eb28ed4cb1aa] = true;
    answers[0xcde5a5206502103831b662ec1daab4fc5ee4a28be119b107e2dbd56e02c814b0] = true;
    answers[0x7ef75553a406bd1759f6a22b1d084d3d5e1bce4181066b35a8366e896ba310a9] = true;
    answers[0x4a1df76d5fdca1f3267693f5b684847b77f02f85a5d9767d357ab2aa90634fc9] = true;
    answers[0x17ad724de69d8d7da733902ae9c44de3a1994b97c8d126cbe671bdbe1702cc9d] = true;
    answers[0x63901b645aa6e00ea7f6ba69d824d4f5cd2ce7d643330de121686328cc21b0bb] = true;
    answers[0x9e32e51816ae3d879b9aaeceedd531d5abd3640bb8aaa3c6d9e2d10e18b2d9bc] = true;
    answers[0xf73cc5ac0bc073b4918638dddb393051a3ea7179027a3d9f47c9ed136f78e0a5] = true;
    answers[0xe72119f9c1974a06bcd72c51fa3f87473e96a66c1aa3cdd17a8518dd40395ae8] = true;
    answers[0x18ab0a81d3215ed6ad372baff1fe73899b6aa68639f10a87b744d8baa654ad91] = true;
    answers[0xb8a8ada9535fa3053f1b61cbf25ce46ed2f53efa95f0029370b92e6ea3ec7d98] = true;
    answers[0xcfdea7b210a3533c87622e608babd4a691caf2898c3f8901b4b2bdd767cc00eb] = true;
    answers[0x3614f3cc62c7fae8471653830e29081a4f099cbd1161f769d352404b8dfb246e] = true;
    answers[0x3f145c47f25c8c31d11c203d0bd9a075d091309d3d8ed4f955da039b743a8780] = true;
    answers[0xefd31f603dad8d0c79507cec491b96f72ca7f6ce235f442d6a0bad3b12700e67] = true;
    answers[0x99bc8e72a63018f735480e8834a13afe9b3cc6a5c8e65c19ca9f72e554f5ac00] = true;
    answers[0x3d24323f4a67970d031715d65cc76df4380ee24a4fde21bf34565ba80fdcecd3] = true;
    answers[0x84ab6acaa8685d50699c8d133bb2bf922ed38d4d2bfbaca532284f7db802c3e1] = true;
  }

  function mint(string memory _answer) external {
    
    bytes32 key = keccak256(abi.encodePacked(_answer));
    if(!answers[key]){
      revert Nope();
    } else {
      answers[key] = false;
    }

    if(msg.sender != tx.origin){
      revert SenderOriginMismatch();
    }
    
    if(_mintedPerAddress[msg.sender]){
      revert AlreadyMinted();
    } else {
      _mintedPerAddress[msg.sender] = true;

      // Get the next available token ID for giving away.
      uint256[] memory availableTokens = planetCrosswordContract.tokensOfOwnerIn(address(this), 0, initialSupply);
      if(availableTokens.length == 0){
        revert NoMoreTokensAvailable();
      }
      planetCrosswordContract.transferFrom(address(this), msg.sender, availableTokens[0]);
    }

  }

  /// @notice Transfers out the full ETH balance to the paymentRecipient.
  function withdrawAll() external {
    (bool success, ) = payable(paymentRecipient).call{
      value: address(this).balance
      }("");
      if (!success) {
        revert WithdrawalFailed();
      }
    }

  /// @notice Allow us to receive arbitrary ETH if sent directly.
  receive() external payable {}  

}