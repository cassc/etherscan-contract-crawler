// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
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

contract SkeletonkingsGlitchdroid is Ownable2Step, ERC721, DefaultOperatorFilterer {
  using ECDSA for bytes32;

  bool public revealed;
  bool public enableTokenURI;
  address public verifier = 0xE9A3F5261f3776B0B344916aD7Fe19172c17E668;
  uint16 public totalClaimed;
  uint16 public teamClaimed;
  string public baseURI;

  mapping(address => uint16) public nClaimed;

  mapping(uint256 => string) public tokenURIs;

  constructor() ERC721("SK - Glitch Droids", "SKGD") {}

  /* User */
  function claim(uint16 _amount, bytes calldata _encodedParams, bytes calldata _signature) external {
    address user = msg.sender;
    require(tx.origin == user, "Not allowed");
    bytes32 message = keccak256(abi.encode(user, address(this), keccak256(_encodedParams)));
    require(message.toEthSignedMessageHash().recover(_signature) == verifier, "Invalid signature");
    (uint16 maxPerWallet, uint16 maxSupply, uint64 startTime, uint64 endTime) = getClaimParams(_encodedParams);

    require(startTime <= block.timestamp && block.timestamp <= endTime, "Expired");
    require(nClaimed[user] + _amount <= maxPerWallet, "Exceed max per wallet");
    require(totalClaimed + _amount <= maxSupply, "Exceed max supply");

    for (uint16 i = 0; i < _amount; i++) {
      _safeMint(user, totalClaimed + i);
    }
    nClaimed[user] += _amount;
    totalClaimed += _amount;
  }

  /* View */
  function getClaimParams(
    bytes calldata _encodedParams
  ) public pure returns (uint16 maxPerWallet, uint16 maxSupply, uint64 startTime, uint64 endTime) {
    (maxPerWallet, maxSupply, startTime, endTime) = abi.decode(_encodedParams, (uint16, uint16, uint64, uint64));
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Nonexistent token");
    if (!revealed) {
      return "ipfs://QmaU1Lpp4gJfTVmhaoo9ZyhVUbHrSoRot5xp7t9juii7wC";
    }
    if (enableTokenURI && bytes(tokenURIs[_tokenId]).length > 0) {
      return tokenURIs[_tokenId];
    }
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  /** Admin **/
  function setVerifier(address _account) external onlyOwner {
    verifier = _account;
  }

  function setBaseURI(string calldata _uri) external onlyOwner {
    baseURI = _uri;
  }

  function setRevealed(bool _status) external onlyOwner {
    revealed = _status;
  }

  function setEnableTokenURI(bool _enable) external onlyOwner {
    enableTokenURI = _enable;
  }

  function setTokenURIs(uint256[] calldata _tokenIds, string[] calldata _uris) external onlyOwner {
    require(_tokenIds.length == _uris.length, "Invalid input");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      tokenURIs[_tokenIds[i]] = _uris[i];
    }
  }

  function teamClaim(address _to, uint16 _amount) external onlyOwner {
    require(teamClaimed + _amount <= 40, "Exceed team reserved");
    for (uint16 i = 0; i < _amount; i++) {
      _safeMint(_to, totalClaimed + i);
    }
    totalClaimed += _amount;
    teamClaimed += _amount;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  /* Royalty */
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }
}