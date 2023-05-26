// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Supply, ERC1155 } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
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


contract DRPToken is ERC1155Supply, Ownable {
  struct Config {
    uint16 MAX_SUPPLY;
    uint16 TEAM_SUPPLY;
    uint256 PRICE;
  }

  struct TokenInfo {
    bool tradingPaused;
    bool saleActive;
    bool teamClaimed;
    string uri;
    Config config;
    mapping(address => uint16) claimed;
  }

  // constants
  // A = 0, B = 1, C = 2, D = 3, E = 4, F = 5, G = 6, H = 7
  enum TOKEN {A, B, C, D, E, F, G, H}

  string public constant name = "DRPToken";
  string public constant symbol = "DRP";

  // variables
  TokenInfo[8] public tokens;

  string public hashKey = "shintaro-drp";
  address public signer = 0x046c2c915d899D550471d0a7b4d0FaCF79Cde290;

  function(uint8, uint16, address, bytes memory, uint8) internal view returns (bool)[8] ELIGIBLES = [
    eligibleByWhitelist,
    eligibleByWhitelist,
    eligibleByWhitelist,
    eligibleByWhitelist,
    eligibleByWhitelist,
    eligibleByWhitelist,
    eligibleByPrerequisite,
    eligibleByWhitelist
  ];

  constructor() ERC1155("") {
    tokens[uint8(TOKEN.A)].config = Config({ MAX_SUPPLY: 10, TEAM_SUPPLY: 0, PRICE: 0.5 ether });
    tokens[uint8(TOKEN.B)].config = Config({ MAX_SUPPLY: 10, TEAM_SUPPLY: 0, PRICE: 0.5 ether });
    tokens[uint8(TOKEN.C)].config = Config({ MAX_SUPPLY: 25, TEAM_SUPPLY: 0, PRICE: 0.3 ether });
    tokens[uint8(TOKEN.D)].config = Config({ MAX_SUPPLY: 25, TEAM_SUPPLY: 0, PRICE: 0.3 ether });
    tokens[uint8(TOKEN.E)].config = Config({ MAX_SUPPLY: 50, TEAM_SUPPLY: 0, PRICE: 0.15 ether });
    tokens[uint8(TOKEN.F)].config = Config({ MAX_SUPPLY: 50, TEAM_SUPPLY: 0, PRICE: 0.15 ether });
    tokens[uint8(TOKEN.G)].config = Config({ MAX_SUPPLY: 444, TEAM_SUPPLY: 20, PRICE: 0.1 ether });
    tokens[uint8(TOKEN.H)].config = Config({ MAX_SUPPLY: 444, TEAM_SUPPLY: 0, PRICE: 0.1 ether });

    tokens[uint8(TOKEN.A)].uri = 'ipfs://QmZy3pCNzJrEQimqV4DUjSmLNKzqtE3KF8fnxJ7fUwYmQG';
    tokens[uint8(TOKEN.B)].uri = 'ipfs://QmRXVxWPhR5wtsuTsMHzPvg8LLcRufjibUzDrzzMth7Nzz';
    tokens[uint8(TOKEN.C)].uri = 'ipfs://QmfZ7viDWW54zijzUda8N3JxEPCpiuqYGHxa4iq64CndFT';
    tokens[uint8(TOKEN.D)].uri = 'ipfs://QmarT1nA3Rt3Ux2VgC253mGptnNDMUv7GhdrxNitorPQTZ';
    tokens[uint8(TOKEN.E)].uri = 'ipfs://QmVf6dm1MoiWZLt29UGbSZaHy1gm7LCTihYdNxNFf6WNP2';
    tokens[uint8(TOKEN.F)].uri = 'ipfs://QmVgWEEFucAEWBwvLdurVsrxcweWoETDhGGwruXEoR1TC3';
    tokens[uint8(TOKEN.G)].uri = 'ipfs://QmVr4m15DCMgFY3nk4TarFjbZaba2Gkni4VGc9Ecbd2CPA';
    tokens[uint8(TOKEN.H)].uri = 'ipfs://QmcD9qUCxyqETeV4d2NmcxRWeAoHLa2PBjKGDMF2W9p9oN';
  }

  /* User */
  function claim(TOKEN _tokenId, uint16 _maxAmount, bytes calldata _signature) external payable {
    uint8 tokenId = uint8(_tokenId);
    uint8 amount = 1;

    require(tokens[tokenId].saleActive, "Sale not active");
    require(tx.origin == msg.sender, "Not allowed");
    require(eligibleClaim(_tokenId, _maxAmount, msg.sender, _signature, amount), "Not eligible");
    require(tokens[tokenId].config.MAX_SUPPLY > totalSupply(tokenId), "Exceed max");
    require(msg.value >= tokens[tokenId].config.PRICE, "Ether value incorrect");

    tokens[tokenId].claimed[msg.sender] += amount;
    _mint(msg.sender, tokenId, amount, "");
  }

  /* View */

  // verified
  function uri(uint256 _id) public view virtual override returns (string memory) {
    require(exists(_id), "Non exist token");

    return tokens[uint8(_id)].uri;
  }

  // verified
  function eligibleClaim(TOKEN _tokenId, uint16 _maxAmount, address _account, bytes memory _signature, uint8 _amount) public view returns (bool) {
    uint8 tokenId = uint8(_tokenId);
    return ELIGIBLES[tokenId](tokenId, _maxAmount, _account, _signature, _amount);
  }

  function eligibleByWhitelist(uint8 _tokenId, uint16 _maxAmount, address _account, bytes memory _signature, uint8 _amount) internal view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked(hashKey, _tokenId, _maxAmount, msg.sender));
    return validSignature(message, _signature) && tokens[_tokenId].claimed[_account] + _amount <= _maxAmount;
  }

  function eligibleByPrerequisite(uint8 _tokenId, uint16, address _account, bytes memory, uint8) internal view returns (bool) {
    uint256 preTokenBalance = IDRPM(0xc46077AaE8f87b10bE3a1fe8E4E69eE135eC6759).balanceOf(_account, 0) +
      IDRPM(0xb09e99F8bFc11f6C311E7d63EFc42F26c51017A6).balanceOf(_account, 0);
    return balanceOf(_account, _tokenId) == 0 && preTokenBalance > 0;
  }

  /* Admin */
  function setSignerInfo(address _signer, string calldata _hashKey) external onlyOwner {
    signer = _signer;
    hashKey = _hashKey;
  }

  // verified
  function toggleSaleActive(TOKEN[] calldata _tokenIds, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[uint8(_tokenIds[i])].saleActive = _status;
    }
  }

  // verified
  function toggleTrading(TOKEN[] calldata _tokenIds, bool _status) external onlyOwner {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[uint8(_tokenIds[i])].tradingPaused = _status;
    }
  }

  // verified
  function setTokensUri(TOKEN[] calldata _tokenIds, string[] calldata _uri) external onlyOwner {
    require(_tokenIds.length == _uri.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[uint8(_tokenIds[i])].uri = _uri[i];
    }
  }

  // verified
  function teamClaim(TOKEN _tokenId) external onlyOwner {
    uint8 tokenId = uint8(_tokenId);
    require(!tokens[tokenId].teamClaimed, "Already claimed");

    _mint(msg.sender, tokenId, tokens[tokenId].config.TEAM_SUPPLY, "");
    tokens[tokenId].teamClaimed = true;
  }

  // verified
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual override {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      uint256 tokenId = ids[i];
      require(from == address(0) || !tokens[tokenId].tradingPaused, "Token paused");
    }
  }

  // verified
  function splitSignature(bytes memory _sig) internal pure returns (uint8, bytes32, bytes32) {
    require(_sig.length == 65, "Invalid signature length");

    uint8 v;
    bytes32 r;
    bytes32 s;
    assembly {
      r := mload(add(_sig, 32))
      s := mload(add(_sig, 64))
      v := byte(0, mload(add(_sig, 96)))
    }
    return (v, r, s);
  }

  // verified
  function validSignature(bytes32 _message, bytes memory _signature) public view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == signer;
  }
}

interface IDRPM {
  function balanceOf(address, uint256) external view returns (uint256);
}