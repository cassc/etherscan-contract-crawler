// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
                                                                 
contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract ERC721Tradeable is ERC721, ContextMixin, NativeMetaTransaction, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  //Mint price 0.007 ETH
  uint256 internal PRICE = 7000000;
  string public _contractURI;
  string internal _baseTokenURI;
  bool internal _isActive;
  string internal name_;
  string internal symbol_;
  uint256 internal MAX_FREE = 1;
  address proxyRegistryAddress;
  uint256 internal constant MAX_SUPPLY = 222;
  uint256 internal constant MAX_PER_TX = 3;
  uint256 internal constant MAX_PER_WALLET = 6;
  address[] allowlist = [0x6aA032dec7072f97cf364f5f96508AA69f3624d6,0x5eCd62E06971E2Ae4B8c1E69f3EeF2F2FA774d3B,0xa52F9AfdbFbCf829Cd6Ca893b6F6EF0C9D25Fa27,0x4e6a2122cbf2e11650c69F1e60a8074ee0a529B7,0x26dd9186060e9D16A3c9d49BE63F079Aafc96909,0xBA346d4676E917885A29424a8347dCA2ac0dEBDA,0x785F7a990507833BeE231a8F3a1dBf00DC9034Df,0x5a37B98Ea2BD1fa36cE7798B78733CEcC3b9F11d,0x0D3c05276db2e65fc4E94dbe09eFEF3B81588255,0x708C14cA468dd7FBEE9723F1bf8729C3d1e08Fff,0x51bdecad4824eC97b327731803e469876E263C36,0x11884b192e445da651151E97a83Dbb61cA32b009,0xd9fFE414E12a0Cda46F08eA69033c558CE617Ef1,0xFa4FbCbD324910309e03116395271Eb6018265E0,0x05a4D0B48de7Ffd610be8cdA698725370c975cfa,0xFa05c81ff9CAB893A98999bd7fd7530F5d53a780,0x8892fC3B8478bc292A8F60c71657b9095058B1FA,0x4f54681e61BEF61ec85914Fe5Ec7ea8B3f77677A,0xfcFb26da6089B65c6a4F2bB047561974A4b95e4f,0xb601246d6F66516cdA3648C34D4D8bA21Fa1a833,0xD29d6Df8eC0D8D5B208151196Ff0969988A8f909,0x8f48e1cb1831992C658251Ef6de8be0F9b824E40,0x4AB59d6caC15920b2f2909C0529995e12C509b80,0xb98296C9b2D75C6c358cc9367ACb4Ff433F0a742,0xA03E4E02B213A9E11bd3cE4DF190564355f7A9E7,0x799a343A127E45bA2001CDc95747baB4CBe5415E,0xF1BdD1279d6E2787dCE77988096d53e39623Fa27,0x1151920cE5B8E259C07a56694dbDbA7961ADE5FC,0xCE447D814FEA1c83d30C1b1a61D5b248Adf58ece,0xCc973DB3ac0D77544b43101D3CEcC7254172F279,0x3BF856111223340b1b0D84265c6836776630aB1a,0x8726E84Ae4887a55aAB65968D0451C26A7175986,0x1AD99Da542Bf27eafF24a2a6dc47911aE5aB83D1,0x07e3b460dDA6186aE7e7e9988bDA8A31c0c85999,0x9fd3FE90d991207645E88F6D827418679b5B6244,0xb915d1e50b237A1C3A12a1487F3510cddb466Dd6,0x9e91c46209fB8F83650c3C082A3D3De72dB62818,0x78e50f93bb4c3bBA7b7873b0CD370c27c79A0C8f,0x9fa3C87Eb4668984b87E185b24ae08759b0f50BD,0x382C6f4DD388A71458AaeFA837b385aC6C33ddf0,0xf88bA999020B7bae8186Efb2a4912038E6cb7AD6,0x33Bca50B5432aFd362cd976Ac9900B48b925c94f,0xE68E26DdB1D898684f6d9D676a924c3AE4C2052b,0xaC35ddfBDaeB568d165C2F78fED58F4BED734EAB,0xD30f558fc6261C5B53E35a11001932902d7662F7,0x048eb03324123C8413993d0517542C48BFA35878,0xE24a157fC29799a7e3417D27FEe4DA1f028D132B,0x84c83687CA8cBcB7D93Ae749C72f5bd2CB85B4b4,0x2F7320dC403f35692afb44172cAF581eD352A865,0x3C2526e5a9918dB632b9B82cBe941C64D181d4fd,0x0755fba838D560B3e2bb41A9747e4BE44824Ee1a,0xEc7b358258478180060897de6658Fd9abBe69E32,0x6ED75E43E7eeC0b3f95E2daC87920dE66f1E494f,0xdccf70D069d93E1aA5cC42AE4FC205c9d77d9E4a,0xf8a448f0E4B9B3dDcEcC695266d37DC4CF6E701C,0xdDF3c8d51D07eE993C0Ab670194a68f4B81B3654,0xbD5be705b96f858aA975D862dc017B4B9972393A,0x6E619AC069D8696077266dAaEec5aB64eb009deD,0x4A26fD2C016AD2949B14c7606114C4D8247b2bF6,0xfA1E52C3747cBF8802477A2eD6492694486D1Ad0,0xDc49105BC68cB63a79dF50881be9300ACb97dEd5,0xfd34611f8e285B3624eAF9D2366B1D7cdB2f3d30,0xc3925CcB3547f45C3a8B7EBA14a8aAda957e6A80,0x1d8da89911359DD7288508231fb61d5123b5feD5,0x8Bc80B66996E60dacD5d0aC9F2843aCC9E01Ecf0,0x68ca9064D6F50AF5d507A999BC238F8736BCe6E1,0x5115EE34406Be22bae90D24f066b4682b44d07bA,0xE15f6f1E4cC7299bE2eC786817dC700D602C7EC7,0xeE97cbF18Fc41C068eb8AFE67025353346c5fA02,0x9266D4795f1871E2b410aB4af62454b5e00E6805,0x2D7CF39E1f50eFc84334aE7d5044dBC6c6241798,0xCd11aBBC370dbCe80B81a250DF87b3226f2B1a49,0xb0F2aBE38179BaCD3Fb2625F3993Ae77bE621C6e,0x4455Bc56E2A05Ef14B668098AF10Ecd8A36FC369,0x76D0AD6863b627F5786E7C6d17BC67426A9a2787,0xeE4C26Da3F63A53F8101c922edc404D0A6a5bec8,0x995074dd1EF159baDF3e04A49881072365A23BDC,0xD190d284971951DD1B8DFc600677eeC77016a517,0x73B41FAfc67fbee0Afd35EAEAba76e7468083f07,0x1b48012465eD4b770Ce11AB18aE1e701E6DfaF58,0xD1E2Fec054B84a7f501818C7849817dD3065610d,0xc1876bb98Df09206a7929350e40eb0b970b2C05A,0xDd9D8407f632287566f6A1b41A7BD2d94cfD4afc,0x4576ecF4E25aaCfaA65a97DF02B1a5fa9B4C8d26,0x70BcB41c857CD7A8Fcbe37AefD2090a1D4B8DD8f,0x9b2726AdCF67B20f98e6D34e80370CA25125A845,0x4167B32BB11907f400D510Bf590aAc413C9195a0,0xB8a2fE7E27E27762ab82c1767Cd393AC7834b198,0x1b9B31b6F2AB65e70a3d4Fa7150add08cA55B91C,0xFEC6C76fC788e493D8991011c92e7c3b9c5Ec969,0xFc869dc94d2d7b522D3A05FBb4ADfAaE9063F36c,0x345Ba24532Ee95BA0f5e7C00782e576e39541aBe,0xd4F54c9EB860DC6d9901938b2BBE18190c90F316,0x2BFc667416130115dC984f996668A916122b0675,0x8f48e1cb1831992C658251Ef6de8be0F9b824E40,0x425DE7D06D25B254dB50236a079055077D5890E6];
  mapping (address => bool) internal approvedAddresses;
  Counters.Counter internal _nextTokenId;
     
    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _nextTokenId.increment();
        _initializeEIP712(_name);
        name_ = _name;
        symbol_ = _symbol;
        for(uint i; i < allowlist.length; i++) {
          approvedAddresses[allowlist[i]] = true;
        }
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
      _safeMint(to, tokenId, data);
    }

    function name() public view virtual override returns (string memory) {
        return name_;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        //metadata
        string memory base = _baseTokenURI;
        return string.concat(
          string.concat(base, Strings.toString(id)),
          ".json");
    }

    function setFreePerWallet(uint256 amount) public onlyOwner {
      MAX_FREE = amount;
    }

    function setMintPriceInGWei(uint256 price) public onlyOwner {
      PRICE = price;
    }

    function symbol() public view virtual override returns (string memory) {
        return symbol_;
    }

    function mintPriceInWei() public view virtual returns (uint256) {
        return SafeMath.mul(PRICE, 1e9);
    }

    function maxFree() public view virtual returns (uint256) {
        return MAX_FREE;
    }
}