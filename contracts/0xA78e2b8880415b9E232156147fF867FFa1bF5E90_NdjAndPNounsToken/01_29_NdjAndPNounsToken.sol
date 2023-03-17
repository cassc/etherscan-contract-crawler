// SPDX-License-Identifier: MIT

/*
 * Created by Eiba (@eiba8884)
 */
/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './pNounsContractFilter2.sol';

contract NdjAndPNounsToken is pNounsContractFilter2 {
  using Strings for uint256;

  enum SalePhase {
    Locked,
    PreSale,
    PublicSale
  }
  SalePhase public phase = SalePhase.Locked; // セールフェーズ
  uint256 public purchaceMax = 10; // １回当たりの最大購入数

  address public treasuryAddress = 0x4e06186A2C78986BB478A4dC4aB3FF3918937627; // トレジャリーウォレット
  uint256 public maxMintPerAddress = 100; // 1人当たりの最大ミント数
  uint256 constant mintForTreasuryAddress = 100; // トレジャリーへの初回配布数

  mapping(address => uint256) public mintCount; // アドレスごとのミント数

  // PreSaleでミントOKとするコントラクト
    IERC721[] whitelist ;

  constructor(IAssetProvider _assetProvider, address[] memory _administrators, IERC721[] memory _whiteList)
    pNounsContractFilter2(_assetProvider, 'NDJ & pNouns collaboration NFT', 'NDJ&pNouns', _administrators)
  {
    description = 'This is the collaboration NFT between Nouns DAO Japan and pNouns.';
    mintPrice = 0 ether;
    mintLimit = 10000;

    whitelist = _whiteList;
    _setDefaultRoyalty(payable(treasuryAddress), 1000);

    _safeMint(treasuryAddress, mintForTreasuryAddress);
    nextTokenId += mintForTreasuryAddress;

    mintCount[treasuryAddress] += mintForTreasuryAddress;
  }

  function adminMint(address[] memory _to, uint256[] memory _num) public onlyAdminOrOwner {
    uint256 mintTotal = 0;
    uint256 limitAdminMint = 100; // 引数間違いに備えてこのトランザクション内での最大ミント数を設定しておく

    // 引数配列の整合性チェック
    require(_to.length == _num.length, 'args error');

    for (uint256 i = 0; i < _num.length; i++) {
      mintTotal += _num[i];
      require(_num[i] > 0, 'mintAmount is zero');
    }

    // ミント数合計が最大ミント数を超えていないか
    require(mintTotal <= limitAdminMint, 'exceed limitAdminMint');
    require(totalSupply() + mintTotal <= mintLimit, 'exceed mintLimit');

    // ミント処理
    for (uint256 i = 0; i < _to.length; i++) {
      _safeMint(_to[i], _num[i]);
      mintCount[_to[i]] += _num[i];
    }
    nextTokenId += mintTotal;
  }

  // whiteListを持っているか?
  function hasWhiteList(address addr) public view returns (bool) {
    uint256 balance = 0;
    for (uint256 i = 0; i < whitelist.length; i++) {
      balance += whitelist[i].balanceOf(addr);
    }

    return balance > 0;
  }

  function mintPNouns(
    uint256 _mintAmount // ミント数
  ) external payable {
    // オーナーチェック
    if (!hasAdminOrOwner()) {
      // originチェック
      require(tx.origin == msg.sender, 'cannot mint from non-origin');

      // セールフェイズチェック
      if (phase == SalePhase.Locked) {
        revert('Sale locked');
      } else if (phase == SalePhase.PreSale) {
        // whitelistチェック
        require(hasWhiteList(msg.sender), 'have any token of whitelist');
      } else if (phase == SalePhase.PublicSale) {
        // チェック不要
      }

      // ミント数が購入Max以下であること,ミント数が設定されていること
      require(_mintAmount <= purchaceMax && _mintAmount > 0, 'invalid mint amount');

      // アドレスごとのミント数上限チェック
      require(mintCount[msg.sender] + _mintAmount <= maxMintPerAddress, 'exceeds number of per address');
    } else {
      require(msg.value == 0, 'owners mint price is free');
    }

    // 最大供給数に達していないこと
    require(totalSupply() + _mintAmount <= mintLimit, 'Sold out');

    // ミント
    _safeMint(msg.sender, _mintAmount);
    nextTokenId += _mintAmount;

    // ミント数カウントアップ
    mintCount[msg.sender] += _mintAmount;
  }

  function withdraw() external payable onlyAdminOrOwner {
    require(treasuryAddress != address(0), "treasuryAddress shouldn't be 0");
    (bool sent, ) = payable(treasuryAddress).call{ value: address(this).balance }('');
    require(sent, 'failed to move fund to treasuryAddress contract');
  }

  function setTreasuryAddress(address _treasury) external onlyAdminOrOwner {
    treasuryAddress = _treasury;
  }

  function setPhase(SalePhase _phase) external onlyAdminOrOwner {
    phase = _phase;
  }

  function setPurchaceMax(uint256 _purchaceMax) external onlyAdminOrOwner {
    purchaceMax = _purchaceMax;
  }

  function setMaxMintPerAddress(uint256 _maxMintPerAddress) external onlyAdminOrOwner {
    maxMintPerAddress = _maxMintPerAddress;
  }

  function setWhitelist(IERC721[] memory _whitelist) external onlyAdminOrOwner {
    whitelist = _whitelist;
  }

  function mint() public payable override returns (uint256) {
    revert('this function is not used');
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenName(uint256 _tokenId) internal view virtual override returns (string memory) {
    return string(abi.encodePacked('#', _tokenId.toString()));
  }

  // 10% royalties for treasuryAddressß
  function _processRoyalty(uint256 _salesPrice, uint256) internal virtual override returns (uint256 royalty) {
    royalty = (_salesPrice * 100) / 1000; // 10.0%
    address payable payableTo = payable(treasuryAddress);
    payableTo.transfer(royalty);
  }
}