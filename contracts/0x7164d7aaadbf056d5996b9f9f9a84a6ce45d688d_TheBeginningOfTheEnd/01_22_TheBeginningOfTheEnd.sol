// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ConfigSettings} from "gwei-slim-nft-contracts/contracts/base/ERC721Base.sol";
import {ERC721Delegated} from "gwei-slim-nft-contracts/contracts/base/ERC721Delegated.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TheBeginningOfTheEnd is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "The Beginning Of The End",
      "TBoTE",
      ConfigSettings({
        royaltyBps: 650,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {
    allowedMintCountMap[msg.sender] = 33;

    allowedMintCountMap[0xdf9e6a194F3d4DC2571158F4bA7CFA9696AA9274] = 3;

    allowedMintCountMap[0x6Fc5891d3daF91555f7b9C70eB9657A4dF59176f] = 3;

    allowedMintCountMap[0x7f5afC67d4C3AE0182354ea6e785FdEb20150f15] = 3;

    allowedMintCountMap[0x85cA7d812127677FFE9B5672DA40459348a8FF85] = 3;

    allowedMintCountMap[0x2EE54D8eB4F898c285b9fce4320D0bA6725E1704] = 3;

    allowedMintCountMap[0x8E74351b6C91e729395560438f6c85a16dD4cce4] = 3;

    allowedMintCountMap[0xECe055ea28bE3c1D9b08B8883b52700fFFaae20c] = 3;

    allowedMintCountMap[0xe6d6c64a981385f2e93196833a162655d6F8a8Fb] = 3;

    allowedMintCountMap[0xB58D73997C1CA0E1812c60A7eC69683eEFc098B8] = 3;

    allowedMintCountMap[0x4e07751EA822dBc8c71B1aC89e971Ed88a089b3f] = 3;

    allowedMintCountMap[0xCe6DB393C736A65e0B21d10A92B97418ABd0a2dE] = 3;

    allowedMintCountMap[0xD8f2c8dE147EdE45D00c1f1ba529Db5486F8b922] = 3;

    allowedMintCountMap[0xA7D775FB03F699bEAbbdc18FF97D1385feeB3EB9] = 3;

    allowedMintCountMap[0x819Aa1675c4baBa624A5E061F4F4cE05095A4AC2] = 3;

    allowedMintCountMap[0x7c192a1fF95c3254abc1B34B493E2fFCCdF3836F] = 3;

    allowedMintCountMap[0x85eEFFB8e62a2F196BDe282621368eb6839C6109] = 3;

    allowedMintCountMap[0x78161b0c34DA8bBf88DC73bC214d37616A927ae7] = 3;

    allowedMintCountMap[0xE0C9B6BeD7ecA8F9bCAaeC1763f73606967283c8] = 3;

    allowedMintCountMap[0xd17f430E0B973218576a37cc447F5910ED1BE9FE] = 3;

    allowedMintCountMap[0x9B5F74C8c979F3F34fc1aF43242FDf1683070D0D] = 3;

    allowedMintCountMap[0x85026596042Cf8CAB1b521bCca86C56cf2D2ecAe] = 2;

    allowedMintCountMap[0x580b1E94Dad298f5CD32E3C38B9faf4a25c08Ea4] = 2;

    allowedMintCountMap[0x91c2edF643304e983e35e572898B014AB0E7e64E] = 2;

    allowedMintCountMap[0x8A0ba5E4063C1FFA294FA6Bd9dE937f1B5BD4600] = 2;

    allowedMintCountMap[0x63C242920eD0e137cC7cBc6D2cDB5B1fccD050cE] = 2;

    allowedMintCountMap[0xfcfF7E05177619e187e337C5210685f06F725d13] = 2;

    allowedMintCountMap[0x324825B5B28b056d32757f0877411cb031810Ca9] = 2;

    allowedMintCountMap[0x28156730f1F2f588fcc3e9ED2f5793CAD354282c] = 2;

    allowedMintCountMap[0x3e051B18A633A48998CB1656817cA74DEbF37fab] = 2;

    allowedMintCountMap[0xf148d310ee342cd1A8ac15AFCF75BA7a7F6CB9Fb] = 2;

    allowedMintCountMap[0x53c68d3F629B53c27Cd658D41dC836F38603eD0c] = 2;

    allowedMintCountMap[0xD50a89b8f99EAFd815E1F552522632e673d1f73a] = 2;

    allowedMintCountMap[0x0e4230c3cbAFbACa98E1419721deC3D108767B72] = 2;

    allowedMintCountMap[0x91fe628414A41074Eb841da04B4D6992cF5f90e5] = 2;

    allowedMintCountMap[0x974Ab44B53a46875e4Cf0471FAEBF35b2F9d8561] = 2;

    allowedMintCountMap[0x199e024CD5eBB205c7A2EEBE4eBB33630D7b1d35] = 2;

    allowedMintCountMap[0xa0E84D22d5429C4E55d086F47D1BAb006E5ADEBB] = 2;

    allowedMintCountMap[0x4D2b5A91e41c933c190aaAbDa54B2Ed8765AEfAC] = 2;

    allowedMintCountMap[0xE436BeA44E9734220509E3d1fd501443eBFb2A7C] = 2;

    allowedMintCountMap[0x2C1C90B44Bf1f40A851B04146A358B053A74F067] = 2;

    allowedMintCountMap[0x20bE3D159eD81Ed9fa73432414Ea0460D1Ba94a5] = 2;

    allowedMintCountMap[0xA14626C73A39F4Ab461D3afAeCC3A4A8B2Aa6367] = 2;

    allowedMintCountMap[0xE1F0D43469492FcAc3eF69D8732bDBa1e65fcD63] = 2;

    allowedMintCountMap[0xAdBA3C3e04F77123e00cAB16FD1b9cD3cCCAB4aC] = 2;

    allowedMintCountMap[0x80f6391F15D77fD4051685121ea3BcC2cEc8959c] = 2;

    allowedMintCountMap[0x3d4c0f2f46b7c16117D1184Ed2B1878293614a86] = 2;

    allowedMintCountMap[0x060233eB6867f329C57586d9Be5BD918Ad06adF2] = 2;

    allowedMintCountMap[0xdf6B4D90860a0579d55737824Ce6f5aF7d378b7a] = 2;

    allowedMintCountMap[0x050f5Fb2314242c2560305574A35439aA006e0B6] = 2;

    allowedMintCountMap[0x3aAAE5C3c0f1F3b239cb6a5F02e105674De13bB2] = 2;

    allowedMintCountMap[0xFc2cEfF32e3a534b78C729fD23973CB9ce98FBAC] = 2;

    allowedMintCountMap[0xB67710d029B2A702d54E0F41BB5dC2ADd72C5DfF] = 2;

    allowedMintCountMap[0xa2DA32691EE54f3089d8328039Da3bFBa71f31A1] = 2;

    allowedMintCountMap[0xe4F93B524b742A6A76882C94D66F9d4f4B0583C5] = 2;

    allowedMintCountMap[0xf7f532af44b7DCd017f107EA7cc19F87f40c69e9] = 2;

    allowedMintCountMap[0x2DeD7A9a7C6aa52540E556c9660D505da0b10203] = 2;

    allowedMintCountMap[0x401B185d9a57a34e7888f6363AFf4B54E535A872] = 2;

    allowedMintCountMap[0xF338aE28794bc7a79c94Daaa8657aaC3CA65768b] = 2;

    allowedMintCountMap[0xC489042128d3ba383BcE79eaEef1dc69EfC40416] = 2;

    allowedMintCountMap[0xae68a4AB5228229391225283c899E88E4741c62A] = 2;

    allowedMintCountMap[0xEc44d23f2f2e1fB07d8B38207470Cf9d841e247D] = 2;

    allowedMintCountMap[0xf1d23725a29f80d6996b435D78b21596435B6c54] = 2;

    allowedMintCountMap[0xB6c64C6Ab138CF4439754566faA15E9c796f2B3b] = 2;

    allowedMintCountMap[0xc3E10c4b00D393F515B391b69504b76a219b2132] = 2;

    allowedMintCountMap[0xDfb5e6170eA423c4EF32bf49907B884e8Cb9dCed] = 2;

    allowedMintCountMap[0xA54cE875d138260315359b35a252303E75317efe] = 2;

    allowedMintCountMap[0x914d1eb2E0d63c29CF8df21830f1CabB9F53B377] = 2;

    allowedMintCountMap[0x7Fe178A16dC4b2EeCB34B860AB501a8AE017a729] = 2;

    allowedMintCountMap[0x8a622Bc901de1fa2384d42FFA79606e446eD788F] = 2;

    allowedMintCountMap[0x44B2945F9EC50ad1562c28CB7dF2077fC09F1427] = 2;

    allowedMintCountMap[0x68Db5E9B182Af5AffEfDBe102dEd829C018328f6] = 2;

    allowedMintCountMap[0xb5619Ba9D7f67254e4C53c8bE903d951B551C9a5] = 2;

    allowedMintCountMap[0x15B985DC531593b65d219C4f6947369345D713A0] = 2;

    allowedMintCountMap[0xD4BBe225b6A92cdadC69301Dd54C1Cf0E437B659] = 2;

    allowedMintCountMap[0x36c1238af9cd4D640e6c5D4184Fc88A2117265F3] = 2;

    allowedMintCountMap[0xe969C2dA5940eafe62e416983366A14F16B35FAe] = 2;

    allowedMintCountMap[0x0b8242F72ccf49E4C47C74d784fDd68e7bfdd62D] = 2;

    allowedMintCountMap[0x37328808192d370203F8dD85F7663C2E7FCd856f] = 2;

    allowedMintCountMap[0xe9F755Eba18CE85CAe770e0F4Ec0EC948c8d9779] = 2;

    allowedMintCountMap[0x8453B32B87e33ffE570Be91f1Ad1181F7037e0cf] = 2;

    allowedMintCountMap[0xAa73537FD1E34cd9E6bfD04270f9A0F160C39069] = 2;

    allowedMintCountMap[0xC7d21a6a1174fd3fa1E24b1BF2CfA1eE7b7FAa40] = 2;

    allowedMintCountMap[0xBe327B8AD8AEb1374962652b8B1B2465A0c234cA] = 2;
  }

  /** MINTING LIMITS **/

  mapping(address => uint256) private mintCountMap;

  mapping(address => uint256) private allowedMintCountMap;

  uint256 public constant MINT_LIMIT_PER_WALLET = 1;

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    return a >= b ? a : b;
  }

  function allowedMintCount(address minter) public view returns (uint256) {
    if (saleIsActive) {
      return (
        max(allowedMintCountMap[minter], MINT_LIMIT_PER_WALLET) -
        mintCountMap[minter]
      );
    }

    return allowedMintCountMap[minter] - mintCountMap[minter];
  }

  function updateMintCount(address minter, uint256 count) private {
    mintCountMap[minter] += count;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 3333;

  uint256 public constant MAX_MULTIMINT = 3;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public nonReentrant {
    if (allowedMintCount(msg.sender) >= count) {
      updateMintCount(msg.sender, count);
    } else {
      revert(saleIsActive ? "Minting limit exceeded" : "Sale not active");
    }

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 3 at a time");

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_tokenURI(tokenId), ".json"));
  }

  /** PAYOUT **/

  function withdraw() public nonReentrant {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(_owner()), balance);
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so