// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//
//                                          ,((*,
//                                /%%*@((@(@*@@(&&/#/@&/@*
//                            @*#%/&#(*(& #(%#,%%(//%@%#@&**%
//                         #,##%@@%.#@[email protected]#@%#*/ #@./%#@@@@.*,/#@
//                       /@&@#&#,,&(#..(@,##&.,. ,(@%@@@(@#(#(#((@
//                      #@@&@&%/,/%* ###*(,#,,###% (##@(&%#@/%/&*/
//                    @(%&@%/,/ %##. ,,@#((#*[email protected]& [email protected] ,,@@#, @@&*%/%@@
//                   %&@&(*/&*@//[email protected]#/ /# &(%@&@,%&@   ,@%%# %#@*/@,,[email protected]
//                  @@@%@##(/ %(#@,@@,*[email protected]@@&/#/ #@    .&@@&*(@/(/(,,/*@
//                 @#@&@#@/(@(,*%* /%#%/[email protected]%#&&@%#      *@@@@*@&/##@/@((
//                @#(@/@*/ /@@%%#@*                      @@@@ #*@///@#.,
//                &%,*&*@.                                  &/(//(((/#&@
//               @/%#*@(    @@@@                   @@@@@@@     /#&@.(@&@@
//               @&/,(%. &@  @&#@ @              ,@      @@*     #@&&@(#/
//              @#@,(#/ *@   *&%@  .             @   (/@  [email protected]&*    @(/%**.
//              @*#*#%/..                        %@ @#&@   @&     (@(%  **
//             @%/&*#.%.                         /@@, &  #        *&&@*//@
//             @@#@#.,@                         , @( %@*%, @     @,,&@,%#/
//             @%##@**@,.            [email protected]/  @      , @[email protected]    ,      &%,,@/%% ,
//             @@@#(,..%.                           @     %     @,%@#@/#/ *
//             @(*@*(,%%,.                         ,[email protected]@@@#     @.*/&&@ ./.#
//             @%@(#/@,***.          @/(,(,**@@   ,/ / * /    &% (,&%@* *% ,
//             @%&#@@(%.(  .         @(...,**,@     .( #.    @/  @@ @@%%%..*%
//              (#@/&// *@( ,..        @/* /@           , (&[email protected]&.,@@ % @*%*#&,
//        *,%       #&@*,##(/,@,        ..,.           .#.  #@(  / ,  @@..#. @
//      @  *&.       #/(# *&*& # @  .                 @ [email protected], /@@.,@ *  *%,..,#
//    @,    .        /@%,&* @,@,%(@ .%.           @ @   @@    %,   #, # , @ ,@@
//   %   /  ,@        %@@@.& &*@,%&@% *  ,@@@*       /&.  @@,  ,,@ (@[email protected]/*%,*(@&
//        %# ,&       %&%(&,@ .*% *# /.*          %%  %@,  @@,  %@# %@@  . , #
//    @@   .#  #       @/*(,, ( @&    [email protected],.      (%@@.   @(       &*@  @        (. @
//   &(@                %,%,#%# @& ,    @ @     @.  &        ,    ./%*         (.
//   ,          @,@    ((%@,@@. @ #(      @& &[email protected] @   *   ,   ,    ,#@@
//  @              *     @@*@% *#@%&.      @[email protected]   [email protected]   ,          @%@@.      . *
//  @        %       *   ,#/@#  @% @@.  %%. [email protected]  , %  @*@         (@        .
//   #        /.           @@# ,@,@@ .   ..*@,, [email protected],,,@ @@@       * .     [email protected]   %/.
//   @*                    %(% ,@,@( @,     ,/%  ,.. .          @#(       @ * ,  @
//   @@@.           # @*   & @ ,@%&%  . , .*@ @.   ,             *.    ,*.#@,.
//   #, &,@ #@         &    ( @@,..,   @,/*@.,     .,          / .     @/
//   ./         %%,    @.         @,%   /*,#.,[email protected]  @@   .     [email protected]  .    ,
//      ,( (*@@         .     (   , *&   *.   [email protected]  . @..  .         .  @..       &,
//                     @,      @         &,. .   @.  .  .     @     *@../(
//    @,@       ,      ,@..     ,@        @.  ,@ *,. , @.,  @      %   @%       .(
//     ..  .         (#,,, .       @       @     ,. & @*         @       @,*.     ,
//      ,    %    (*%,*.,#  @       %,     ,  /  /   @,. /     @           @..
// ,   %, #,,   .      #.  *@@&     &@@     @     *@ *,  @@ @,              [email protected]
//
//
//     DRP + Pellar 2022
//     Drop 5 - Shintaro!

contract DRPToken is Ownable, ERC721Enumerable {
  using Strings for uint256;

  // variables
  bool public tradingPaused;
  string public defaultBaseURI;
  mapping(uint256 => string) uri;

  constructor() ERC721("DRPToken", "DRP") {}

  /* View */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Non exists token");

    if (!isBlank(uri[_tokenId])) {
      return uri[_tokenId];
    }
    return string(abi.encodePacked(defaultBaseURI, Strings.toString(_tokenId)));
  }

  // verified
  function isBlank(string memory _string) public pure returns (bool) {
    return bytes(_string).length == 0;
  }

  /* Admin */
  function toggleTrading(bool _status) external onlyOwner {
    tradingPaused = _status;
  }

  // verified
  function setBaseURI(string calldata _uri) external onlyOwner {
    defaultBaseURI = _uri;
  }

  // verified
  function setTokenUri(uint256 _tokenId, string calldata _uri) external onlyOwner {
    uri[_tokenId] = _uri;
  }

  // verified
  function adminMint(string calldata _uri) external onlyOwner {
    uint256 tokenId = totalSupply();
    _mint(msg.sender, tokenId);
    uri[tokenId] = _uri;
  }

  // verified
  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal virtual override {
    require(_from == address(0) || !tradingPaused, "Token paused");
    super._beforeTokenTransfer(_from, _to, _tokenId);
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}