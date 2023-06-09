/**
 *Submitted for verification at Etherscan.io on 2023-05-19
*/

/*=======================================================================================================================
#                                                           ..                                                          #
#                                                           ::                                                          #
#                                                           !!                                                          #
#                                                          .77.                                                         #
#                                                          ~77~                                                         #
#                                                         .7777.                                                        #
#                                                         !7777!                                                        #
#                                                        ^777777^                                                       #
#                                                       ^77777777^                                                      #
#                                                      ^777!~~!777^                                                     #
#                                                     ^7777!::!7777^                                                    #
#                                                   .~77777!  !77777~.                                                  #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                 ~777777!^    ^!777777~                                                #
#                                               :!7777777^      ^7777777!:                                              #
#                                             :!77777777:        :77777777!:                                            #
#                                           :!77777777!.          .!77777777!:                                          #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                           :!77777777!.          .!77777777!:                                          #
#                                             :!77777777:        :77777777!:                                            #
#                                               :!7777777^      ^7777777!:                                              #
#                                                 ~777777!^    ^!777777~                                                #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                   .~77777!  !77777~.                                                  #
#                                                     ^7777!::!7777^                                                    #
#                                                      ^777!~~!777^                                                     #
#                                                       ^77777777^                                                      #
#                                                        ^777777^                                                       #
#                                                         !7777!                                                        #
#                                                         .7777.                                                        #
#                                                          ~77~                                                         #
#                                                          .77.                                                         #
#                                                           !!                                                          #
#                                                           ::                                                          #
#                                                           ..                                                          #
#                                                                                                                       #
/*=======================================================================================================================
#                                                                                                                       #
#     ██████╗ ███████╗███████╗████████╗██╗███╗   ██╗██╗   ██╗████████╗███████╗███╗   ███╗██████╗ ██╗     ███████╗       #   
#     ██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║████╗  ██║╚██╗ ██╔╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝       #
#     ██║  ██║█████╗  ███████╗   ██║   ██║██╔██╗ ██║ ╚████╔╝    ██║   █████╗  ██╔████╔██║██████╔╝██║     █████╗         #
#     ██║  ██║██╔══╝  ╚════██║   ██║   ██║██║╚██╗██║  ╚██╔╝     ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝         #
#     ██████╔╝███████╗███████║   ██║   ██║██║ ╚████║   ██║      ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗███████╗       #
#     ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝   ╚═╝      ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝       #
#                                                                                                                       #
========================================================================================================================*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 *  @notice Allows exchange, burning, and minting between DIY, DST, and DSE tokens at a fixed exchange rate.
 */
contract IDestinySwap{
    address public constant DESTINYTEMPLE = 0x777750401bCacA779C0d53434D4c4d24Cc657777;
    address public constant DST = 0x012312cb7fd428eC140fF55fC5Ac46144b474567;
    address public constant DIY = 0x0000bDC584DB9DEbaF780915bdb26095C8e50007;
    address public constant LIQUIDITY = 0x7777777777777777777777777777777777777777;
	uint public constant RATE = 7777;

    modifier _onlyDestinytemple(){
        require(msg.sender == DESTINYTEMPLE,"not _destinyTemple.");
        _;
    }
    /**
     *  @notice Destroy 7777 $DST tokens from the specified address and mint one $DSE token for the specified recipient.
     *          The specified burn address needs to be approved by you to allow access to a sufficient amount of $DST tokens.
     *          Only allow calls to swapDSE functions via DestinyTempleV7 Constart.
     *          Note: that each address is only allowed to hold at most one $DSE token.
     */
    function swapDSE(address DST_burnFrom, address DSE_mintTo) public _onlyDestinytemple returns (bool) {
        (bool DST_burnFromSuccess,) = DST.call(abi.encodeWithSignature("burn(address,uint256)", DST_burnFrom, RATE));
        (bool DSE_mintToSuccess,) = DESTINYTEMPLE.call(abi.encodeWithSignature("mint(address)", DSE_mintTo));
        require(DST_burnFromSuccess && DSE_mintToSuccess);
        return true;
    }
    /**
     *  @notice Destroy 1 $DSE token from the specified address, and mint 7777 $DST tokens for the specified recipient.
     *          The specified burn address needs to be approved by you to allow access to a sufficient amount of $DSE tokens
     *          Only allow calls to swapDSE functions via DestinyTempleV7 Constart.
     */
    function redeemDST(address DSE_burnFrom,address DST_mintTo) public _onlyDestinytemple returns (bool) {
        (bool DSE_burnFromSuccess,) = DESTINYTEMPLE.call(abi.encodeWithSignature("burn(address)", DSE_burnFrom));
        (bool DST_mintToSuccess,) = DST.call(abi.encodeWithSignature("mint(address,uint256)",DST_mintTo,RATE));
        require(DSE_burnFromSuccess && DST_mintToSuccess);
        return true;
    }
    /**
    *   @notice Transfer DIY_burnAmount of $DIY tokens from DIY_sender address to LIQUIDITY address, and exchange $DST tokens at an exchange rate of 7777 : 1, and send them to the address of DST_recipient.
    *           The DIY_sender address needs to approve you to allow access to a sufficient amount of $DIY tokens.
    *           Or you are the DIY_sender address yourself.
    *           Note: If there is insufficient liquidity, the transaction may fail.
    */
    function swapDST(uint DIY_burnAmount, address DST_recipient) public returns (bool) {
        (bool transferSuccess,) = DIY.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,LIQUIDITY,DIY_burnAmount));
        (bool swapSuccess,) = DST.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",LIQUIDITY,DST_recipient,DIY_burnAmount / RATE));
        require(transferSuccess && swapSuccess);
        return true;
    }
    /**
    *   @notice Transfer DST_burnAmount of $DST tokens from DST_sender address to LIQUIDITY address, and exchange $DIY tokens at an exchange rate of 1 : 7777, and send them to the address of DIY_recipient.
    *           The DST_sender address needs to approve you to allow access to a sufficient amount of $DST tokens.
    *           Or you are the DST_sender address yourself.
    *           Note: If there is insufficient liquidity, the transaction may fail.
    */
    function redeemDIY(uint DST_burnAmount, address DIY_recipient) public returns (bool) {
        (bool transferSuccess,) = DST.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",msg.sender,LIQUIDITY,DST_burnAmount));
        (bool swapSuccess,) = DIY.call(abi.encodeWithSignature("transferFrom(address,address,uint256)",LIQUIDITY,DIY_recipient,DST_burnAmount * RATE));
        require(transferSuccess && swapSuccess);
        return true;
    }
}
/*=======================================================================================================================
#                                                                                                                       #
#     ██████╗ ███████╗███████╗████████╗██╗███╗   ██╗██╗   ██╗████████╗███████╗███╗   ███╗██████╗ ██╗     ███████╗       #
#     ██╔══██╗██╔════╝██╔════╝╚══██╔══╝██║████╗  ██║╚██╗ ██╔╝╚══██╔══╝██╔════╝████╗ ████║██╔══██╗██║     ██╔════╝       #
#     ██║  ██║█████╗  ███████╗   ██║   ██║██╔██╗ ██║ ╚████╔╝    ██║   █████╗  ██╔████╔██║██████╔╝██║     █████╗         #
#     ██║  ██║██╔══╝  ╚════██║   ██║   ██║██║╚██╗██║  ╚██╔╝     ██║   ██╔══╝  ██║╚██╔╝██║██╔═══╝ ██║     ██╔══╝         #
#     ██████╔╝███████╗███████║   ██║   ██║██║ ╚████║   ██║      ██║   ███████╗██║ ╚═╝ ██║██║     ███████╗███████╗       #
#     ╚═════╝ ╚══════╝╚══════╝   ╚═╝   ╚═╝╚═╝  ╚═══╝   ╚═╝      ╚═╝   ╚══════╝╚═╝     ╚═╝╚═╝     ╚══════╝╚══════╝       #
#                                                                                                                       #
*=======================================================================================================================*
#                                                           ..                                                          #
#                                                           ::                                                          #
#                                                           !!                                                          #
#                                                          .77.                                                         #
#                                                          ~77~                                                         #
#                                                         .7777.                                                        #
#                                                         !7777!                                                        #
#                                                        ^777777^                                                       #
#                                                       ^77777777^                                                      #
#                                                      ^777!~~!777^                                                     #
#                                                     ^7777!::!7777^                                                    #
#                                                   .~77777!  !77777~.                                                  #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                 ~777777!^    ^!777777~                                                #
#                                               :!7777777^      ^7777777!:                                              #
#                                             :!77777777:        :77777777!:                                            #
#                                           :!77777777!.          .!77777777!:                                          #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#           ...::^^~!!77777777~~^^:..              .:^!777777777777!^:.              ..:^^~~77777777!!~^^::...          #
#                     ..:^~!77777777!!~^:.             .^!777777!^.             .:^~!!77777777!~^:..                    #
#                           .:^!7777777777!~:             ^7777^             :~!7777777777!^:.                          #
#                               .:~!777777777!~:           :77:           :~!777777777!~:.                              #
#                                   .^!777777777!^.         ^^         .^!777777777!^.                                  #
#                                      :~7777777777^.       ..       .^7777777777~:                                     #
#                                        .^!77777777!^              ^!77777777!^.                                       #
#                                           :!77777777!.          .!77777777!:                                          #
#                                             :!77777777:        :77777777!:                                            #
#                                               :!7777777^      ^7777777!:                                              #
#                                                 ~777777!^    ^!777777~                                                #
#                                                  :!77777!:  :!77777!:                                                 #
#                                                   .~77777!  !77777~.                                                  #
#                                                     ^7777!::!7777^                                                    #
#                                                      ^777!~~!777^                                                     #
#                                                       ^77777777^                                                      #
#                                                        ^777777^                                                       #
#                                                         !7777!                                                        #
#                                                         .7777.                                                        #
#                                                          ~77~                                                         #
#                                                          .77.                                                         #
#                                                           !!                                                          #
#                                                           ::                                                          #
#                                                           ..                                                          #
#                                                                                                                       #
========================================================================================================================*/