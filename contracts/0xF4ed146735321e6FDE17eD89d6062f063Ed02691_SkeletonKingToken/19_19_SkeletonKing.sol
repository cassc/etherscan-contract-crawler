// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { ERC721Enumerable, ERC721 } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { DefaultOperatorFilterer } from "./royalty/DefaultOperatorFilterer.sol";

//                                      *
//                                      @@*
//                                     @@@%.
//           .,                     */@@@@@#,               ,%##,
//          @@@@%&*                [email protected]@@@@@@@/.           *%&%(/.
//           @@@@@@&%#,           @@@@@@@@@@%*,,      ,%@@%((/
//           ,@@@@@@@@@@(**     @@@@@@@@@@@@@%*,. *%%&@@%#((/
//            *@@@@@@@@@@@@%#&#@&@@(((#(#@&%#(,  *%&@@&%#((#
// ..,*&@@@@@@&/@@@@@@&&%#@@@@@@@@@@&&&&&%%%%#%%#/#@@@*.(#%*
//    ,*////(##&(@@%@@@@@@&(##%%%%%%&@&&&%%%%%%#####(/((*@@,
//      .,*//*(.,@@@(##((#%%%&&&&&&&&&&&&&&&&%%%%%###((((//*(
//        .,,//#/*   /(#%&&&&&&&&&&&%%&&&&&&%%%%###*(/..*****/
//          */,      /#%&&&&&&@@@@&&&&&%%%%%/%#(///,          *,
//         ,,,      .*/&@@@@@@@@@@@@@@&&%%%#(/*,,..              /
//       ,,,,,     ./(@%@@@@@@@@@@@@@@@&&%##(/*,,..               .
//      .,,,,     .*(%@&@@@@@@@@@@@@@@@@@&%##/**,...              .*
//      ,..,      ,*#&@@(@@@@@@@@@@@@@@@@&&%#(/*,,..              ...
//      .      ., ./#&@@&@@@@@@@@@@@@@@@&&%##(//,,,..              .*
//     *       .,,*# /#&*@@@@@@@@@@@@@@&&%##(///*,,..              .*
//     *      ..*##&@  .(@@@&&&&&&&@@&%%%##(///***,,..    . ..      *
//     ,     .../%&&@@ #@@@@@@@@@@@@@@@@&(%#***,***,,.              *
//            .,,(%%& @@@@@@@@@@@@@@@@@@@@@%@%((((((/*#@&@@@@@@@@@@@@.
//      .,     . .*([email protected]@@@@@@@@@@@@@@@@@@@@@@@@%###((@(@@@@@@@@@@@@@@@
//     ,,/  /%&.  .&@@@@@@@@@@@@@@@@@@@@@@@@@@@/,..*#@@@@@@@@@@@@@@@*
//     *@#         .#@@@@@@@@@@@@@@@@@@@@@@@&%//    #@@@@@@@@@@@@@@@.
//    [email protected]@  .       .,#@@@@@@@@@@@@@@@@@@@@@(@(%@# #  *#@@@@@@@@@@@@*
//    [email protected]@&@//       ///%/@@@@@@@@@@@&/(%(  *(@@@@@@@&   (#@@@@@@@@@,
//     &@@&@       (***/%@@@@@@@@@@@@@@@&@@@@@@@@@@@@@./@@@@@&.
//      .%@@@(%#%&@&%#((&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&*#&@@@@@@@#(.
//         ,#@@@&# ,,..(@@@@@@@%%@@@@@@@@@@@*@@@@@@@@@ .(##%%@@@&*,
//             &( .  *@@#@@@@@@@@@@@@@@@@@@@@@@@#@#,    ,(/#&@@@@%
//                    (@#@@@@@@@@ @@@@@@@@@@@@@@.#/      /@@@,
//                 .  .&@/@@@@@@  &&@@@@@@@@@&&@ /,.     (@@*
//                    .%@@%@@@@@( @,@&@@@@@@@@@@@@@@@@@@&@@#,
//                     (&&@@@@@@&%#@@%@@&@&(@%/@/,#,% //*(*,
//                    ,(%%@@@%@@@%##@@@@@@@&@##&*.. @ &,**,,
//                        ##%(@%&%%&@@@@@@@@@@@@&%#(/*,*,,(
//                            /(*/(%@@@@@@@@%#(@,.    ,*(
//                                ,%@@@@@@@@%((@(,. .,/
//                                     /@@@@@@@@@&%(
//
// DRP + LightLink + Pellar 2023

contract SkeletonKingToken is Ownable2Step, ERC721Enumerable, DefaultOperatorFilterer {
  using ECDSA for bytes32;
  // method_id; // 0 = whitelist, 1 = public

  struct ClaimInfo {
    uint256 claimed;
    mapping(address => uint256) claimedPerWallet;
  }

  // verified
  bool public revealed;
  bool public enableTokenURI;
  uint16 public teamClaimed;
  uint16 public boundary = 8688; // = MAX_SALE
  address public verifier = 0xE9A3F5261f3776B0B344916aD7Fe19172c17E668;

  string public baseURI;

  mapping(uint16 => uint16) randoms;
  mapping(uint8 => ClaimInfo) public claimedInfo;
  mapping(uint256 => string) public tokenURIs;

  constructor() ERC721("SkeletonKing", "SK") {}

  /* User */
  // verified
  function claim(
    uint8 _methodId,
    uint256 _amount,
    bytes calldata _encodedParams,
    bytes calldata _signature
  ) external payable {
    require(tx.origin == msg.sender, "Not allowed");
    bytes32 message = keccak256(abi.encodePacked(msg.sender, address(this), _encodedParams));
    require(message.toEthSignedMessageHash().recover(_signature) == verifier, "Invalid signature");
    (uint8 methodId, uint256 maxPerWallet, uint256 maxPerTxn, uint256 maxSupply, uint64 startTime, uint64 endTime, uint256 price) = getClaimParams(
      _encodedParams
    );

    uint256 totalClaimed;
    for (uint8 i = 0; i <= methodId; i++) {
      totalClaimed += claimedInfo[i].claimed;
    }

    uint256 totalClaimedPerWallet;
    for (uint8 i = 0; i <= methodId; i++) {
      totalClaimedPerWallet += claimedInfo[i].claimedPerWallet[msg.sender];
    }
    require(methodId == _methodId, "Invalid method id");
    require(startTime <= block.timestamp && block.timestamp <= endTime, "Expired");
    require(_amount <= maxPerTxn, "Exceed max per txn");
    require(totalClaimedPerWallet + _amount <= maxPerWallet, "Exceed max per wallet");
    require(totalClaimed + _amount <= maxSupply, "Exceed max supply");
    require(msg.value >= _amount * price, "Ether value incorrect");

    for (uint16 i = 0; i < _amount; i++) {
      _mintToken(msg.sender);
    }
    claimedInfo[methodId].claimedPerWallet[msg.sender] += _amount;
    claimedInfo[methodId].claimed += _amount;
  }

  // verified
  function _mintToken(address _to) internal {
    require(boundary > 0, "Sold out");
    uint16 index = uint16(uint256(keccak256(abi.encodePacked(block.timestamp, _to, block.number, address(this)))) % boundary) + 1;
    uint16 tokenId = randoms[index] > 0 ? randoms[index] - 1 : index - 1;
    randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
    boundary -= 1;
    _mint(_to, tokenId);
  }

  /* View */
  // verified
  function getClaimParams(bytes calldata _encodedParams)
    public
    pure
    returns (
      uint8 methodId,
      uint16 maxPerWallet,
      uint16 maxPerTxn,
      uint32 maxSupply,
      uint64 startTime,
      uint64 endTime,
      uint256 price
    )
  {
    (methodId, maxPerWallet, maxPerTxn, maxSupply, startTime, endTime, price) = abi.decode(
      _encodedParams,
      (uint8, uint16, uint16, uint32, uint64, uint64, uint256)
    );
  }

  // verified
  function getClaimedPerWallet(uint8 _methodId, address _account) public view returns (uint256 claimed) {
    return claimedInfo[_methodId].claimedPerWallet[_account];
  }

  // verified
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for non exists token.");
    if (!revealed) {
      return "ipfs://QmfVjGM9gSWuBCiDrTepyyuAdidnbGLbCQvXgXyV2uRfey";
    }
    if (enableTokenURI && bytes(tokenURIs[_tokenId]).length > 0) {
      return tokenURIs[_tokenId];
    }
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  /** Admin **/
  // verified
  function setVerifier(address _account) external onlyOwner {
    verifier = _account;
  }

  // verified
  function setBaseURI(string calldata _uri) external onlyOwner {
    baseURI = _uri;
  }

  // verified
  function setRevealed(bool _status) external onlyOwner {
    revealed = _status;
  }

  // verified
  function setEnableTokenURI(bool _enable) external onlyOwner {
    enableTokenURI = _enable;
  }

  // verified
  function setTokenURIs(uint256[] calldata _tokenIds, string[] calldata _uris) external onlyOwner {
    require(_tokenIds.length == _uris.length, "Invalid input");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokenURIs[_tokenIds[i]] = _uris[i];
    }
  }

  function teamClaim(address _to, uint8 _amount) external onlyOwner {
    require(teamClaimed <= 200, "Already claimed");
    for (uint8 i = 0; i < _amount; i++) {
      _mint(_to, 8688 + i + teamClaimed);
    }
    teamClaimed += _amount;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}