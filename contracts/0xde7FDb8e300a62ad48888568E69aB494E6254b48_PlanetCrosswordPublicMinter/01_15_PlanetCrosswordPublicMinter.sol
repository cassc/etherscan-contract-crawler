// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./PlanetCrossword721.sol";

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

  PlanetCrossword721 immutable public planetCrosswordContract;
  uint256 immutable public initialSupply;
  address immutable public paymentRecipient;

  constructor(PlanetCrossword721 _planetCrosswordContract, uint256 _initialSupply, address _paymentRecipient) {
    planetCrosswordContract = _planetCrosswordContract;
    initialSupply = _initialSupply;
    paymentRecipient = _paymentRecipient;
  }

  function mint() external {
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