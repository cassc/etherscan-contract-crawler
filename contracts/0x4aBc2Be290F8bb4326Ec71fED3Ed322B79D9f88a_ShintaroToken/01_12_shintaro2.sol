// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC1155Supply, ERC1155 } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { ERC1155Burnable } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";

// ///#///(#**(,**/.,,,/,,/...../.../..%(%,#.,((,,,#,//.(....    .,,/%%///(,,/(/,*,
// /*%/**///**/*,,,*,/,,*.,/(,,,./,.(./*(.(.(,,,#.(..#((..  ..    ,,(/%/*****,*/*/,
// *///*(/*(/**/.*/,,*(****../..        .,.,/.(.*/. *              ,**(#/**,*,(((*,
// ****(#*//(..,,/,(#/*##((*                            ,(.        /**/////*,/,*(*(
// *#,*/(//,,#(..     ....                                             ,,,/%/(/,,/*
// ,*,/(**#...     .                                                      .,/((#/,/
// (*,*%,...     .                                              .            .*,/#(
// .,,*,.    ..%,,%&%%%%&,.                                ,(#&%(/(&&(./         ,*
// ,,*(,.    #*(/.   /((  &&(.                          .(%%*..       %/% #%       
// *,(/..  **&%   *///****/ && .                       ./#/,           ,%#(,.      
// ,,*/...*(#%    %/****,*.  %..                      ..*#,     (%/    .(,(#./     
// ,,*(....     ((#((#%&&* / ..                      .../#    (*****,, .(/./(.     
// *,/(.......       ..  ..                          *. /%(   (*,***#  (.  .#..    
// (,(/,....                                           .(*,.&    #..(/(  (//(      
// (,,/,...                                              (**/ .  . ..  ,   .(      
// ,,,/,....                     ....                    .(..  %//(***( *%%/       
// ,,,(,...                       ..                      ,(,   . ,,***. .%/       
// ,(,(/,...                     ./                        .,  ,.         #.       
// ,,.,%,......                   ..... ........            ,.,(/.      .,,        
// ,,(,/.,....                            ....               ,,      (&%&#.        
// ,,,,,(,...                                                 ,,      ,.(.         
// %,,,.(/,...                                                 ,#//(///(*.        (
// *#,,(.,*,...                                                 .*%(&#%,.        */
// (,#,,,, ,.......                                               ,,/,**        ,. 
// ,/,(,,,.,*......                #*,,**/*,,,,(&&/                .,, ,       #/(,
// /**,(,,,.*(,.....             %/*,,,,.**,,,,,,**(&(             , #(       *(*..
// *,,,.(..*./(.,....             /#*,......,,,,,,,%               /,   ,   %,,/(#.
// //,*,.,,.(./%*(,....             %*.......,,,,*.                 (,./..#(*,/*..*
// (/#*,,..,.,,(((,(.,...             %(****,,(%.                    *..   ,,,/##.#
// ,/*((,,.,,.,.*(/.,#%.....                                          *..   (,((. *
// **(*#/*,,,..,.*#(,,(*/(.....                                    ,,.*... ./#((.,,
// .%//*%*/,.*..*.*#(,,,,,..%.....                            ....,  .%/,...   ....
// . ,%#*(/*/,*../ ./(,/*((**/ (#.....                      &*.,      &.,#..    ...
//  ../#**/#,,,...(.*,#,*,,,.%( *../*....              #,    *./,.     */(,..    ..
//  ..(((,(,#(,*#../..,/**,/,.% */.....*(/%(**/%##*        /  /..(...   ,,*,..   ,,
//   .,(%/(/(**,*..././,,,%#,.(% */......                 *.,,././*,..   ,#*...   .
//   . **(*,,#(,(...(..,(/%((/.%  .........               .*..   *  ,..   .#       
//
//  DRP + Pellar 2022
//  The Eve of Revolution - Shintaro Kago

contract ShintaroToken is ERC1155Burnable, ERC1155Supply, Ownable {
  struct TokenInfo {
    bool tradingPaused;
    bool isPublic;
    uint64 maxPerTxn;
    uint64[] counterIds;
    uint64 editions;
    uint64 minted;
    uint256 price;
    uint256 start;
    uint256 end;
    string uri;
  }

  address public verifier = 0x046c2c915d899D550471d0a7b4d0FaCF79Cde290;
  string public hashKey = "shintaro-2-drp";

  mapping(uint64 => TokenInfo) public tokens;
  mapping(address => mapping(uint64 => uint32)) public claimed;

  constructor() ERC1155("") {
    init(0, 1, new uint64[](0), 100, 0.1 ether, 1656064800, 1656151200, "ipfs://QmZh7eTRton4tXDz1QKYwR6Q7CTKjreVXivnP82upJ3bFz");
    init(1, 1, new uint64[](0), 100, 0.1 ether, 1656064800, 1656151200, "ipfs://QmNYgc62U4rEZb8KtwK5ZJyGecEpviCq9q882gRdugaxQL");
    init(2, 1, new uint64[](0), 50, 0.2 ether, 1656064800, 1656151200, "ipfs://QmRibdnhwZzrei2AMgJ2gh7BENkiekAA2wTupcEhFRjBcY");
    init(3, 1, new uint64[](0), 50, 0.2 ether, 1656064800, 1656151200, "ipfs://Qmc14sEo7PvtT5EZH5Kp4yp3wY7J9w3txeYpm4KDZsqupx");
    init(4, 1, new uint64[](0), 25, 0.7 ether, 1656064800, 1656151200, "ipfs://QmeDiAPYzxNqZQsFxdMTy7dEMFp4L5h3KX1NGzc7Y6dFk6");
    init(5, 1, new uint64[](0), 10, 1.25 ether, 1656064800, 1656151200, "ipfs://QmeZLNr2g69iKqWRGp4T9Em7ZqnWXWQgVqNniBb9VB6z1w");

    uint64[] memory counters = new uint64[](1);
    counters[0] = 7;
    init(6, 1, counters, 594, 0 ether, 1655676000, 1655762400, "ipfs://Qmd3PcKPTUxTBMkUc5ZxwnmS2XGjL3399uEuJqwtYfsEgy");

    counters[0] = 6;
    init(7, 1, counters, 594, 0 ether, 1655676000, 1655762400, "ipfs://Qmf2rERDrsFqxq76WVCZncBCbCZLn2Jwo32ksXBmKHibmL");
  }

  function init(
    uint64 _tokenId,
    uint64 _maxPerTxn,
    uint64[] memory _counterIds,
    uint64 _editions,
    uint256 _price,
    uint256 _start,
    uint256 _end,
    string memory _uri
  ) internal {
    tokens[_tokenId].maxPerTxn = _maxPerTxn;
    tokens[_tokenId].counterIds = _counterIds;
    tokens[_tokenId].editions = _editions;
    tokens[_tokenId].price = _price;
    tokens[_tokenId].start = _start;
    tokens[_tokenId].end = _end;
    tokens[_tokenId].uri = _uri;
  }

  function mint(
    uint64 _tokenId,
    uint32 _maxAmount,
    bytes calldata _signature,
    uint32 _amount
  ) external payable {
    TokenInfo storage token = tokens[_tokenId];

    require(tx.origin == msg.sender, "Not allowed");
    require(token.start <= block.timestamp && block.timestamp <= token.end, "Sale not active");
    require(_amount <= token.maxPerTxn, "Exceed txn");
    require(token.isPublic || eligibleClaim(_tokenId, _maxAmount, msg.sender, _signature, _amount), "Not eligible");
    require(token.minted + _amount <= token.editions, "Exceed max");
    require(msg.value >= token.price * _amount, "Ether value incorrect");

    _mint(msg.sender, _tokenId, _amount, "");
    token.minted += _amount;
    claimed[msg.sender][_tokenId] += _amount;
  }

  function uri(uint256 _id) public view virtual override returns (string memory) {
    require(exists(_id), "Non exist token");
    return tokens[uint64(_id)].uri;
  }

  function eligibleClaim(
    uint64 _tokenId,
    uint32 _maxAmount,
    address _account,
    bytes memory _signature,
    uint32 _amount
  ) public view returns (bool) {
    TokenInfo memory token = tokens[_tokenId];

    uint16 size = uint16(token.counterIds.length);
    for (uint16 i = 0; i < size; i++) {
      if (claimed[_account][token.counterIds[i]] > 0) {
        return false;
      }
    }

    return eligibleByWhitelist(_tokenId, _maxAmount, _account, _signature, _amount);
  }

  function eligibleByWhitelist(
    uint64 _tokenId,
    uint32 _maxAmount,
    address _account,
    bytes memory _signature,
    uint32 _amount
  ) internal view returns (bool) {
    bytes32 message = keccak256(abi.encodePacked(hashKey, _tokenId, _maxAmount, msg.sender));
    return validSignature(message, _signature) && claimed[_account][_tokenId] + _amount <= _maxAmount;
  }

  function getTokenInfo(uint64 _tokenId) public view returns (TokenInfo memory) {
    return tokens[_tokenId];
  }

  function setSignerInfo(address _signer, string calldata _hashKey) external onlyOwner {
    verifier = _signer;
    hashKey = _hashKey;
  }

  function setupToken(uint64 _tokenId, TokenInfo calldata _info) external onlyOwner {
    tokens[_tokenId].maxPerTxn = _info.maxPerTxn;
    tokens[_tokenId].counterIds = _info.counterIds;
    tokens[_tokenId].editions = _info.editions;
    tokens[_tokenId].price = _info.price;
    tokens[_tokenId].start = _info.start;
    tokens[_tokenId].end = _info.end;
    tokens[_tokenId].uri = _info.uri;
  }

  function setupMaxPerTxn(uint64[] calldata _tokenIds, uint64[] calldata _maxPerTxn) external onlyOwner {
    require(_tokenIds.length == _maxPerTxn.length, "Input mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].maxPerTxn = _maxPerTxn[i];
    }
  }

  function toggleRestriction(uint64[] calldata _tokenIds, bool[] calldata _status) external onlyOwner {
    require(_tokenIds.length == _status.length, "Input mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].isPublic = _status[i];
    }
  }

  function setupCounterTokens(uint64 _tokenId, uint64[] memory _counterIds) external onlyOwner {
    tokens[_tokenId].counterIds = _counterIds;
  }

  function setupEditions(uint64[] calldata _tokenIds, uint64[] memory _editions) external onlyOwner {
    require(_tokenIds.length == _editions.length, "Input mismatch");

    uint16 size = uint16(_tokenIds.length);
    for (uint16 i = 0; i < size; i++) {
      tokens[_tokenIds[i]].editions = _editions[i];
    }
  }

  function setupActiveTime(
    uint64[] calldata _tokenIds,
    uint256[] calldata _start,
    uint256[] calldata _end
  ) external onlyOwner {
    require(_tokenIds.length == _start.length, "Input mismatch");
    require(_tokenIds.length == _end.length, "Input mismatch");

    uint16 size = uint16(_tokenIds.length);
    for (uint16 i = 0; i < size; i++) {
      tokens[_tokenIds[i]].start = _start[i];
      tokens[_tokenIds[i]].end = _end[i];
    }
  }

  function setupPrice(uint64[] calldata _tokenIds, uint256[] calldata _price) external onlyOwner {
    require(_tokenIds.length == _price.length, "Input mismatch");
    uint16 size = uint16(_tokenIds.length);
    for (uint16 i = 0; i < size; i++) {
      tokens[_tokenIds[i]].price = _price[i];
    }
  }

  function setTokensUri(uint64[] calldata _tokenIds, string[] calldata _uri) external onlyOwner {
    require(_tokenIds.length == _uri.length, "Input mismatch");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].uri = _uri[i];
    }
  }

  function toggleTrading(uint64[] calldata _tokenIds, bool[] calldata _status) external onlyOwner {
    require(_tokenIds.length == _status.length, "Input mismatch");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokens[_tokenIds[i]].tradingPaused = _status[i];
    }
  }

  function teamClaim(
    address[] calldata _to,
    uint64[] calldata _tokenIds,
    uint32[] calldata _amount
  ) external onlyOwner {
    require(_to.length == _tokenIds.length, "Input mismatch");
    require(_to.length == _amount.length, "Input mismatch");

    uint16 size = uint16(_to.length);
    for (uint16 i = 0; i < size; i++) {
      _mint(_to[i], _tokenIds[i], _amount[i], "");
    }
  }

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
  ) internal virtual override(ERC1155Supply, ERC1155) {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    for (uint256 i = 0; i < ids.length; i++) {
      require(from == address(0) || !tokens[uint64(ids[i])].tradingPaused, "Token paused");
    }
  }

  function splitSignature(bytes memory _sig)
    internal
    pure
    returns (
      uint8,
      bytes32,
      bytes32
    )
  {
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

  function validSignature(bytes32 _message, bytes memory _signature) public view returns (bool) {
    bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _message));
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);
    return ecrecover(ethSignedMessageHash, v, r, s) == verifier;
  }
}