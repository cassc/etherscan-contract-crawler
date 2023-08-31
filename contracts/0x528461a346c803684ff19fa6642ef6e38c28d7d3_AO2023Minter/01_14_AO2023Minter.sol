// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { VRFConsumerBase } from "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import { IAoToken } from "./interfaces/IAoToken.sol";
import { IMinter } from "./interfaces/IMinter.sol";

//
//                               ..:-=====--:.
//                          .-*#@@@@@@@@@@@@@@@@#+-.
//                       -*%@@@@@@@@@@@@@@@@@@@@@@@@%+:
//                     +@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#-
//                   +@@@%##*******#########%%%@@@@@@@@@@%=
//                 -@@@@@@@@@%#***++++========-==*#%%@@@@@@#.
//                *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@:
//              +@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@@@@@@.
//             .@@@@@@@@@@@@@@@@@@@@@. .@@@@@@*:    :+@@@@@@@@@#
//             *@@@@@@@@@@@@@@@@@@@@.   :@@@@=  .+#+: .@@@@@@@@@:
//             %@@@@@@@@@@@@@@@@@@@:  :  -@@@   %@@@@  =@@@@@@@@+
//             @@@@@@@@@@@@@@@@@@@:  -@:  =@@-  =@@@#  +@@@@@@@@%
//            .@@@@@@@@@@@@@@@@@@=  .@@@   +@@-   ..  -@@@@@@@@@#
//             %@@@@@@@@@@@@@@@@#---%@@@#---%@@%+-:-+#@@@@@@@@@@*
//             *@@@@@@@@@@@@@@@@@@@@@@@%#@%#@%%@%%@@@@@@@@@@@@@@-
//             .@@@@@@@@@@@@@@@@@@@@@@@**%-+#*#@#%@@@@@@@@@@@@@%
//              +@@@@@@@@@@@@@@@@@@@@@@%%@@@@@@@@@@@@@@@@@@@@@@:
//               *@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
//                +@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@=
//                 -@@@@@@@@@%#**++=====-=====-====++#%%@@@#.
//                  .*@@@@%#*******###########%%%%%%@@@@@#=
//                    .=@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#=
//                       :*%@@@@@@@@@@@@@@@@@@@@@@@@%+.
//                          :=*#@@@@@@@@@@@@@@@%#+:
//                                :--===+==--:
//
// RIW & Pellar 2023

contract AO2023Minter is Ownable2Step, IMinter, VRFConsumerBase {
  using ECDSA for bytes32;
  // method_id; // 0 = whitelist, 1 = waitlist, 2 = public

  struct ClaimInfo {
    uint16 claimed;
    mapping(address => uint16) claimedPerWallet;
  }

  // verified
  bool public revealed;
  bool public enableTokenURI;
  bool public enableBackupURI;
  bool public enableHtmlURI;
  bool public teamClaimed;
  uint16 public boundary = 2454; // = MAX_SUPPLY

  address public verifier = 0x37bBc414c7455cA1D1E78A183001E16a38Dd32C0;
  address public aoToken;

  string public preRevealedURI;
  string public baseURI;
  string public backupURI;
  string public htmlURI;

  uint256 public seedNumber;
  uint256 public publicSaleMinPrice = 0.23 ether;

  mapping(uint16 => uint16) randoms;
  mapping(uint8 => ClaimInfo) public claimedInfo;
  mapping(uint256 => string) public token2URI;

  constructor() VRFConsumerBase(0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, 0x514910771AF9Ca656af840dff83E8264EcF986CA) {}

  /* VRF */
  // verified
  function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
    uint256 vrfFee = 2 * (10**18);
    require(LINK.balanceOf(address(this)) >= vrfFee, "Not enough LINK");
    return requestRandomness(0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445, vrfFee);
  }

  // verified
  function fulfillRandomness(bytes32, uint256 randomness) internal override {
    seedNumber = randomness;
  }

  /* User */
  // verified
  function claim(
    uint8 _methodId,
    uint16 _amount,
    bytes calldata _encodedParams,
    bytes calldata _signature
  ) external payable {
    require(tx.origin == msg.sender, "Not allowed");
    bytes32 message = keccak256(abi.encodePacked(msg.sender, address(this), _encodedParams));
    require(message.toEthSignedMessageHash().recover(_signature) == verifier, "Invalid signature");
    (uint8 methodId, uint16 maxPerWallet, uint16 maxPerTxn, uint32 maxSupply, uint64 startTime, uint64 endTime, uint256 price) = getClaimParams(_encodedParams);

    uint32 totalClaimed;
    for (uint8 i = 0; i <= methodId; i++) {
      totalClaimed += claimedInfo[i].claimed;
    }
    require(methodId == _methodId, "Invalid method id");
    require(startTime <= block.timestamp && block.timestamp <= endTime, "Expired");
    require(_amount <= maxPerTxn, "Exceed max per txn");
    require(claimedInfo[methodId].claimedPerWallet[msg.sender] + _amount <= maxPerWallet, "Exceed max per wallet");
    require(totalClaimed + _amount <= maxSupply, "Exceed max supply");
    require(msg.value >= _amount * price, "Ether value incorrect");

    for (uint16 i = 0; i < _amount; i++) {
      _mintRandomToken(msg.sender);
    }
    claimedInfo[methodId].claimedPerWallet[msg.sender] += _amount;
    claimedInfo[methodId].claimed += _amount;
  }

  // verified
  function _mintRandomToken(address _to) internal {
    require(boundary > 0, "Sold out");
    uint16 index = uint16(uint256(keccak256(abi.encodePacked(seedNumber, block.timestamp, _to, block.number, address(this)))) % boundary) + 1;
    uint16 tokenId = randoms[index] > 0 ? randoms[index] - 1 : index - 1;
    randoms[index] = randoms[boundary] > 0 ? randoms[boundary] : boundary;
    boundary -= 1;
    IAoToken(aoToken).mint(2023, tokenId + 6776, _to);
  }

  /* View */
  // verified
  function getClaimParams(bytes calldata _encodedParams)
    public
    view
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
    bytes memory auction;
    (methodId, maxPerWallet, maxPerTxn, maxSupply, startTime, endTime, price, auction) = abi.decode(_encodedParams, (uint8, uint16, uint16, uint32, uint64, uint64, uint256, bytes));
    (uint32 auctionTimeGap, uint256 discountUnit) = abi.decode(auction, (uint32, uint256));
    if (block.timestamp > startTime) {
      uint256 discount = ((block.timestamp - startTime) / auctionTimeGap) * discountUnit;
      if (discount > 0) {
        if (price > discount + publicSaleMinPrice) {
          price = price - discount;
        } else {
          price = publicSaleMinPrice;
        }
      }
    }
  }

  // verified
  function getClaimedCount()
    public
    view
    returns (
      uint16 whitelistClaimed,
      uint16 waitlistClaimed,
      uint16 publicClaimed,
      uint32 totalClaimed
    )
  {
    whitelistClaimed = claimedInfo[0].claimed;
    waitlistClaimed = claimedInfo[1].claimed;
    publicClaimed = claimedInfo[2].claimed;
    totalClaimed = whitelistClaimed + waitlistClaimed + publicClaimed;
  }

  // verified
  function getClaimedPerWallet(address _account)
    public
    view
    returns (
      uint16 whitelistClaimed,
      uint16 waitlistClaimed,
      uint16 publicClaimed,
      uint32 totalClaimed
    )
  {
    whitelistClaimed = claimedInfo[0].claimedPerWallet[_account];
    waitlistClaimed = claimedInfo[1].claimedPerWallet[_account];
    publicClaimed = claimedInfo[2].claimedPerWallet[_account];
    totalClaimed = whitelistClaimed + waitlistClaimed + publicClaimed;
  }

  // verified
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(IAoToken(aoToken).exists(_tokenId), "URI query for non exists token");
    if (!revealed) {
      return preRevealedURI;
    }
    if (bytes(token2URI[_tokenId]).length > 0 && enableTokenURI) {
      return token2URI[_tokenId];
    }
    if (enableBackupURI) {
      return string(abi.encodePacked(backupURI, Strings.toString(_tokenId)));
    }
    if (enableHtmlURI) {
      return string(abi.encodePacked(htmlURI, Strings.toString(_tokenId)));
    }
    return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
  }

  /** Admin **/
  // verified
  function setVerifier(address _account) external onlyOwner {
    verifier = _account;
  }

  // verified
  function setAoToken(address _aoToken) external onlyOwner {
    aoToken = _aoToken;
  }

  // verified
  function toggleTokenURI(bool _status) external onlyOwner {
    enableTokenURI = _status;
  }

  // verified
  function toggleBackupURI(bool _status) external onlyOwner {
    enableBackupURI = _status;
  }

  // verified
  function toggleHtmlURI(bool _status) external onlyOwner {
    enableHtmlURI = _status;
  }

  // verified
  function toggleReveal(bool _status) external onlyOwner {
    revealed = _status;
  }

  // verified
  function setPreRevealedURI(string calldata _uri) external onlyOwner {
    preRevealedURI = _uri;
  }

  // verified
  function setBaseURI(string calldata _uri) external onlyOwner {
    baseURI = _uri;
  }

  // verified
  function setBackupURI(string calldata _uri) external onlyOwner {
    backupURI = _uri;
  }

  // verified
  function setHtmlURI(string calldata _uri) external onlyOwner {
    htmlURI = _uri;
  }

  // verified
  function setTokensURI(uint16[] calldata _tokenIds, string[] calldata _uris) external onlyOwner {
    require(_tokenIds.length == _uris.length, "Input mismatch");
    for (uint16 i = 0; i < _tokenIds.length; i++) {
      token2URI[_tokenIds[i]] = _uris[i];
    }
  }

  // verified
  function mintTo(address _account, uint256 _amount) external onlyOwner {
    for (uint16 i = 0; i < _amount; i++) {
      _mintRandomToken(_account);
    }
  }

  // verified
  function setPublicSaleMinPrice(uint256 _price) external onlyOwner {
    publicSaleMinPrice = _price;
  }

  function teamClaim() external onlyOwner {
    require(!teamClaimed, "Already claimed");
    for (uint16 i = 0; i < 19; i++) {
      _mintRandomToken(msg.sender);
    }
    teamClaimed = true;
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }

  function withdrawLink() external onlyOwner {
    uint256 balance = LINK.balanceOf(address(this));
    LINK.transfer(msg.sender, balance);
  }
}