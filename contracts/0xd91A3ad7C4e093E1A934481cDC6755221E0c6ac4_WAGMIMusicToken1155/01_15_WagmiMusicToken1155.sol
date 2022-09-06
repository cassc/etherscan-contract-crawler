// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
__        ___    ____ __  __ ___ __  __ _   _ ____ ___ ____ 
\ \      / / \  / ___|  \/  |_ _|  \/  | | | / ___|_ _/ ___|
 \ \ /\ / / _ \| |  _| |\/| || || |\/| | | | \___ \| | |    
  \ V  V / ___ \ |_| | |  | || || |  | | |_| |___) | | |___ 
   \_/\_/_/   \_\____|_|  |_|___|_|  |_|\___/|____/___\____|
*/

import {IERC2981Upgradeable, IERC165Upgradeable}
from '@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol';
import {ERC1155Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {CountersUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
// ToDo:optimization
import {MerkleProofUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @title WAGMIMusicToken1155
 * @author WAGMIMusic
 */
contract WAGMIMusicToken1155 is ERC1155Upgradeable, IERC2981Upgradeable, OwnableUpgradeable {
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using StringsUpgradeable for uint256;

  struct Music {
    address payable[] stakeHolders;// 収益の受領者(筆頭受領者=二次流通ロイヤリティの受領者)
    uint256[2] prices;// [preSale価格，publicSale価格]
    uint32[] share;// 収益の分配率
    uint32[2] purchaseLimits; // 購入制限
    uint32 numSold;// 現在のトークン発行量
    uint32 quantity;// トークン発行上限
    uint32 presaleQuantity;// プレセール配分量
    uint32 royalty;// 二次流通時の印税(using 2 desimals)
    uint32 album;// 収録アルバムid
    bytes32 merkleRoot;// マークルルート
  }

  struct Album {
    address payable[] _stakeHolders;
    uint256[] _presalePrices;
    uint256[] _prices;
    uint32[] _presaleQuantities;
    uint32[] _quantities;
    uint32[] _share;
    uint32[] _presalePurchaseLimits;
    uint32[] _purchaseLimits;
    uint32 _royalty;
    bytes32 _merkleRoot;
  }

  // ベースURI(tokenURI=baseURI+editionId+/+tokenId)
  string internal baseURI;
  // トークンの名称
  string private _name;
  // トークンの単位
  string private _symbol;
  // 楽曲のID
  CountersUpgradeable.Counter private newTokenId;
  // アルバムのID
  CountersUpgradeable.Counter private newAlbumId;
  // 販売状態(列挙型)
  enum SaleState {Prepared, Presale, PublicSale, Suspended} 

  // 楽曲id => 楽曲データ
  mapping(uint256 => Music) public musics;
  // 楽曲id => 販売状態
  mapping(uint256 => SaleState) public sales;
  // アルバムid => アルバムサイズ
  mapping(uint256 => uint32) private _albumSize;
  // 楽曲id, アドレス => mint数
  mapping(uint256=>mapping(address => uint32)) private _tokenClaimed;
  // 実行権限のある執行者
  mapping(address => bool) private _agent;
  // 楽曲id => 累積デポジット
  mapping(uint256 => uint256) private _deposit;
  mapping(uint256 => mapping(address => uint256)) private _withdrawnForEach;

  event MusicCreated(
    uint256 indexed tokenId,
    address payable[] stakeHolders,
    uint256[2] prices,
    uint32[] share,
    uint32 quantity,
    uint32 presaleQuantity,
    uint32 royalty,
    uint32 album,
    bytes32 merkleRoot
  );

  event MusicPurchased(
    uint256 indexed tokenId,
    uint32 indexed album,
    uint32 numSold,
    address indexed buyer
  );

  event NowOnSale(
    uint256 indexed tokenId,
    SaleState indexed sales
  );

  /**
    @dev 実行権限の確認
   */
  modifier onlyOwnerOrAgent {
    require(msg.sender == owner() || _agent[msg.sender], "This is not allowed except for owner or agent");
    _;
  }

  /**
    @dev コンストラクタ(Proxyを利用したコントラクトはinitializeでconstructorを代用)
    @param _artist コントラクトのオーナーアドレス
    @param name_ コントラクトの名称
    @param symbol_ トークンの単位
    @param _baseURI ベースURI
   */
  function initialize(
        address _artist,
        string memory name_,
        string memory symbol_,
        string memory _baseURI
  ) public initializer {
      __ERC1155_init(_baseURI);
      __Ownable_init();

      // コントラクトのデプロイアドレスに関わらずownerをartistに設定する
      transferOwnership(_artist);

      baseURI = _baseURI;
      _name = name_;
      _symbol = symbol_;

      // 楽曲idとアルバムidの初期値は1
      newTokenId.increment();
      newAlbumId.increment();// albumId=0 => universal album
  }

  // ============ Main Function ============
  /**
    @dev 楽曲データの作成(既存のアルバムに追加)
    @param _stakeHolders 収益の受領者
    @param _share 収益の分配率
    @param _purchaseLimits [presale購入制限数, publicSale購入制限数]
    @param _prices [presale価格, publicSale価格]
    @param _presaleQuantity プレセール配分量
    @param _quantity トークン発行量
    @param _royalty 二次流通時の印税
    @param _merkleRoot マークルルート
    @param _albumId アルバムID(universalAlbum=0)
   */
  function createMusic(
    address payable[] calldata _stakeHolders,
    uint256[2] memory _prices,
    uint32[] calldata _share,
    uint32[2] calldata _purchaseLimits,
    uint32 _quantity,
    uint32 _presaleQuantity,
    uint32 _royalty,
    bytes32 _merkleRoot,
    uint256 _albumId
  ) public virtual onlyOwnerOrAgent {
    // データの有効性を確認
    _validateShare(_stakeHolders, _share);
    // _albumIdの有効性を確認
    require(_existsAlbum(_albumId), 'The album does not exist');
    musics[newTokenId.current()] =
    Music({
      stakeHolders: _stakeHolders,
      prices: _prices,
      share: _share,
      purchaseLimits: _purchaseLimits,
      numSold: 0,
      quantity: _quantity,
      presaleQuantity: _presaleQuantity,
      royalty: _royalty,
      album: uint32(_albumId),
      merkleRoot: _merkleRoot
    });

    emit MusicCreated(
      newTokenId.current(),
      _stakeHolders,
      _prices,
      _share,
      _quantity,
      _presaleQuantity,
      _royalty,
      uint32(_albumId),
      _merkleRoot
    );

    // sales: default => prepared
    sales[newTokenId.current()] = SaleState.Prepared;
    // increment TokenId and AlbumId
    newTokenId.increment();
    ++_albumSize[_albumId];
  }

  /**
    @dev アルバムデータの作成
    @param album AlbumData(Struct)
   */
  function createAlbum(
    Album calldata album
  ) external virtual onlyOwnerOrAgent {
    // データの有効性を確認
    _validateAlbum(album);
    for(uint256 i=0; i<album._quantities.length; ++i){
      musics[newTokenId.current()] =
      Music({
        stakeHolders: album._stakeHolders,
        prices: [album._presalePrices[i], album._prices[i]],
        share: album._share,
        numSold: 0,
        quantity: album._quantities[i],
        presaleQuantity: album._presaleQuantities[i],
        royalty: album._royalty,
        album: uint32(newAlbumId.current()),
        purchaseLimits: [album._presalePurchaseLimits[i],album._purchaseLimits[i]],
        merkleRoot: album._merkleRoot
      });

      emit MusicCreated(
        newTokenId.current(),
        album._stakeHolders,
        [album._presalePrices[i], album._prices[i]],
        album._share,
        album._quantities[i],
        album._presaleQuantities[i],
        album._royalty,
        uint32(newAlbumId.current()),
        album._merkleRoot
      );
      // sales: default => suspended
      sales[newTokenId.current()] = SaleState.Prepared;
      // increment TokenId and AlbumId
      newTokenId.increment();
      ++_albumSize[newAlbumId.current()];
    }
    newAlbumId.increment();
  }

  // function omniMint(
  //   uint256 _tokenId,
  //   uint32 _amount
  // ) external virtual payable {
  //   bytes32[] memory empty;
  //   omniMint(_tokenId, _amount, "", empty);
  // }

  /**
    @dev NFTの購入
    @param _tokenId 購入する楽曲のid
    @param _merkleProof マークルプルーフ
   */
  function omniMint(
    uint256 _tokenId, 
    uint32 _amount,
    bytes memory _data,
    bytes32[] memory _merkleProof
  ) public virtual payable {
    
    // _tokenIdの有効性を確認
    require(_exists(_tokenId), 'The music does not exist');
    // 在庫の確認
    require(musics[_tokenId].numSold + _amount <= musics[_tokenId].quantity, 'Amount exceed stock');

    // セール期間による分岐
    if (sales[_tokenId] == SaleState.Presale) {
      // 購入制限数の確認
      require(_tokenClaimed[_tokenId][_msgSender()] + _amount <=  musics[_tokenId].purchaseLimits[0], "Accumulayion amount of mint exceeds limit");
      _validateWhitelist(_tokenId, _merkleProof);
      // プレセール時の支払価格の確認
      require(msg.value >= musics[_tokenId].prices[0] * _amount,'Must send enough to purchase token.');
    }else if(sales[_tokenId] == SaleState.PublicSale){
      // 購入制限数の確認
      require(_tokenClaimed[_tokenId][_msgSender()] + _amount <=  musics[_tokenId].purchaseLimits[1], "Accumulayion amount of mint exceeds limit");
      // パブリックセール時の支払価格の確認
      require(msg.value >= musics[_tokenId].prices[1] * _amount,'Must send enough to purchase token.');
    }else{
      // SaleState: prepared or suspended
      revert("Tokens aren't on sale now");
    }
    // Reentrancy guard
    // 発行量+_amount
    musics[_tokenId].numSold += _amount;
    // 購入履歴+_amount
    _tokenClaimed[_tokenId][_msgSender()] += _amount;
    // デポジットを更新
    _deposit[_tokenId] += msg.value;
    _mint(_msgSender(), _tokenId, _amount, _data);

    uint32 _albumId = musics[_tokenId].album;
    emit MusicPurchased(
      _tokenId, 
      _albumId,
      musics[_tokenId].numSold, 
      _msgSender()
    );
  }

  /**
    @dev セール状態の停止(列挙型で管理)
    @param _tokenIds 楽曲のid列
   */
  function suspendSale (
    uint256[] calldata _tokenIds
  ) external virtual onlyOwnerOrAgent {
    for(uint256 i=0; i<_tokenIds.length; ++i){
      sales[_tokenIds[i]] = SaleState.Suspended;
      emit NowOnSale(_tokenIds[i], sales[_tokenIds[i]]);
    }
  }

  /**
    @dev プレセールの開始(列挙型で管理)
    @param _tokenIds 楽曲のid列
   */
  function startPresale (
    uint256[] calldata _tokenIds
  ) external virtual onlyOwnerOrAgent {
    for(uint256 i=0; i<_tokenIds.length; ++i){
      sales[_tokenIds[i]] = SaleState.Presale;
      emit NowOnSale(_tokenIds[i], sales[_tokenIds[i]]);
    }
  }

  /**
    @dev パブリックセールの開始(列挙型で管理)
    @param _tokenIds 楽曲のid列
   */
  function startPublicSale (
    uint256[] calldata _tokenIds
  ) external virtual onlyOwnerOrAgent {
    for(uint256 i=0; i<_tokenIds.length; ++i){
      sales[_tokenIds[i]] = SaleState.PublicSale;
      emit NowOnSale(_tokenIds[i], sales[_tokenIds[i]]);
    }
  }

  /**
    @dev マークルルートの設定
    @param _tokenIds 楽曲id
    @param _merkleRoot マークルルート
   */
  function setMerkleRoot(
    uint256[] calldata _tokenIds,
    bytes32 _merkleRoot
  ) public virtual onlyOwnerOrAgent {
    for(uint256 i=0; i<_tokenIds.length; ++i){
      musics[_tokenIds[i]].merkleRoot = _merkleRoot;
    }
  }

  // ============ utility ============

  /**
    @dev newTokenId is totalSupply+1
    @return totalSupply 各トークンの発行量
   */
  function totalSupply(uint256 _tokenId) external virtual view returns (uint256) {
    require(_exists(_tokenId), 'query for nonexistent token');
    return musics[_tokenId].numSold;
  }

  /**
    @dev 特定のアルバムのtokenId列を取得
    @param _albumId アルバムid
    @return _tokenIdsOfMusic tokenId
   */
  function getTokenIdsOfAlbum(
      uint256 _albumId
  ) public virtual view returns (uint256[] memory){
      // _albumIdの有効性を確認
      require(_existsAlbum(_albumId), 'The album does not exist');
      uint256[] memory _tokenIdsOfAlbum = new uint256[](_albumSize[_albumId]);
      uint256 index = 0;
      for (uint256 id = 1; id < newTokenId.current(); ++id){
        if (musics[id].album == _albumId) {
          _tokenIdsOfAlbum[index] = id;
          ++index;
        }
      }
      return _tokenIdsOfAlbum;
  }

  // ============ Revenue Pool ============
  /**
    @dev 収益の引き出し
    @param _recipient 受領者
    @dev param: _withdrawable 引き出し可能な資産総額
    @dev param: dist Editionごとの引き出し可能な資産額
   */
  function withdraw(
    address payable _recipient
  ) external virtual {
    uint256 _withdrawable = 0;
    for(uint256 id=1; id < newTokenId.current(); ++id){
      uint256 dist = _getDistribution(id) - _withdrawnForEach[id][_msgSender()];
      _withdrawnForEach[id][_msgSender()] += dist;
      _withdrawable += dist;
    }
    require(_withdrawable > 0, 'withdrawable distribution is zero');
    _sendFunds(_recipient, _withdrawable);
  }

  /**
    @dev 引き出し可能な資産額の確認
    @param _distribution 配分された資産総額
    @param _withdrawable 引き出し可能な資産総額
   */
  function withdrawable() public virtual view returns(
    uint256 _distribution,
    uint256 _withdrawable
  ){
    _distribution = 0;
    for(uint256 id=1; id < newTokenId.current(); ++id){
      _distribution += _getDistribution(id);
      _withdrawable += _getDistribution(id) - _withdrawnForEach[id][_msgSender()];
    }
    return(_distribution, _withdrawable);
  }

  /**
    @dev 分配資産額の確認
   */
  function _getDistribution(
    uint256 _tokenId
  ) internal virtual view returns(uint256 _distribution){
    uint256 _share = 0;
    for(uint32 i=0; i < musics[_tokenId].stakeHolders.length; ++i){
      if(musics[_tokenId].stakeHolders[i]==_msgSender()){
        _share = musics[_tokenId].share[i];
        break;
      }
    }
    _distribution = _share * _deposit[_tokenId] / 100;
    return(_distribution);
  }

  /**
    @dev 送金機能(fallback関数を呼び出すcallを使用)
   */
  function _sendFunds(
    address payable _recipient,
    uint256 _amount
  ) internal virtual {
    require(address(this).balance >= _amount, 'Insufficient balance for send');
    (bool success, ) = _recipient.call{value: _amount}('');
    require(success, 'Unable to send value: recipient may have reverted');
  }

  // ============ Oparational Function ============

  /**
    @dev NFTのMintオペレーション
    @notice WIP-1: this function should be able to invalidated for the future
   */
  function oparationalMint (
    address _recipient,
    uint256 _tokenId,
    uint32 _amount,
    bytes memory _data
  )external virtual onlyOwnerOrAgent {
    bytes32 digest = keccak256(abi.encode('oparationalMint(uint256 _tokenId,uint32 _amount)', _tokenId, _amount));
    _validateOparation(digest);
    // _tokenIdの有効性を確認
    require(_exists(_tokenId), 'The music does not exist');
    // // 在庫の確認
    // require(musics[_tokenId].numSold + _amount <= musics[_tokenId].quantity, 'Amount exceed stock');
    // // 発行量+_amount(Reentrancy guard)
    // musics[_tokenId].numSold += _amount;
    _mint(_recipient, _tokenId, _amount, _data);
  }

  /**
    @dev 資産の引き出しオペレーション
    @notice WIP-1: this function should be able to invalidated for the future
   */
  function operationalWithdraw(address payable _recipient, uint256 _claimed) external virtual onlyOwner {
    bytes32 digest = keccak256(abi.encode('operationalWithdraw(address payable _recipient, uint256 _claimed)', _recipient, _claimed));
    _validateOparation(digest);
    require(_claimed <= address(this).balance, "Claimed amount is exceeding funding");
    _sendFunds(_recipient, _claimed);
  }

  /**
    @dev エージェントの設定
    @param _agentAddr エージェントのアドレス
    @param _licensed 権限の可否
  */
  function license(address _agentAddr, bool _licensed) external virtual onlyOwner {
    _agent[_agentAddr] = _licensed;
  }

  // ============ Token Standard ============

  /**
    @dev コントラクトの名称表示インターフェース
   */
  function name() public view virtual returns(string memory){
      return(_name);
  }

  /**
    @dev トークンの単位表示インターフェース
   */
  function symbol() public view virtual returns(string memory){
      return(_symbol);
  }

  /**
    @dev Returns e.g. https://.../{tokenId}
    @param _tokenId トークンID
    @return _tokenURI
   */
  function uri(uint256 _tokenId) public virtual view override returns (string memory) {
    require(_exists(_tokenId), 'ERC1155URIStorage: URI query for nonexistent token');
    return string(abi.encodePacked(baseURI,_tokenId.toString()));
  }

  /**
    @dev ベースURIの設定
   */
  function setBaseURI(
    string memory _uri
  ) external virtual onlyOwnerOrAgent {
    baseURI = _uri;
  }

  /**
    @dev トークンのロイヤリティを取得(https://eips.ethereum.org/EIPS/eip-2981)
    @param _tokenId トークンid
    @param _salePrice トークンの二次流通価格
    @return _recipient ロイヤリティの受領者
    @return _royaltyAmount ロイヤリティの価格
   */
  function royaltyInfo(
    uint256 _tokenId,
    uint256 _salePrice
  ) external virtual view override 
  returns(
    address _recipient, uint256 _royaltyAmount
  ){
    Music memory music = musics[_tokenId];
    // ToDo: decimalのテスト必須
    // 100_00 = 100%
    _royaltyAmount = (_salePrice * music.royalty) / 100_00;
    return(music.stakeHolders[0], _royaltyAmount);
  }

  function supportsInterface(
    bytes4 _interfaceId
  )public virtual view override(ERC1155Upgradeable, IERC165Upgradeable)returns (bool)
  {
    return
      type(IERC2981Upgradeable).interfaceId == _interfaceId || ERC1155Upgradeable.supportsInterface(_interfaceId);
  }

  // ============ helper function ============
  function _exists(
    uint256 _tokenId
  ) internal virtual view returns(bool){
    if(_tokenId!=0){
      return musics[_tokenId].quantity != 0;
    }
    return true;
  }

  function _existsAlbum(uint256 _albumId) internal virtual view returns(bool){
    return _albumId < newAlbumId.current();
  }

  function _validateOparation(bytes32 digest) internal virtual {}

  function _validateShare(
    address payable[] calldata _stakeHolders,
    uint32[] calldata _share
  ) internal virtual {
    require(_stakeHolders.length==_share.length, "stakeHolders' and share's length don't match");
    uint32 s;
    for(uint256 i=0; i<_share.length; ++i){
      s += _share[i];
    }
    require(s == 100, 'total share must match to 100');
  }

  function _validateAlbum(
    Album calldata album
  ) internal virtual {
    _validateShare(album._stakeHolders, album._share);
    uint256 l = album._quantities.length;
    require(album._presaleQuantities.length == l, "presaleQuantities length isn't enough");
    require(album._presalePrices.length == l, "presalePrices length isn't enough");
    require(album._prices.length == l, "prices length isn't enough");
    require(album._presalePurchaseLimits.length == l, "presalePurchaseLimits length isn't enough");
    require(album._purchaseLimits.length == l, "purchaseLimit length isn't enough");
  }

  /**
    @dev whitelistの認証(マークルツリーを利用)
    @param _tokenId 購入する楽曲のid
    @param _merkleProof マークルプルーフ
   */
  function _validateWhitelist (
    uint256 _tokenId,
    bytes32[] memory _merkleProof
  ) internal virtual {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(
      MerkleProofUpgradeable.verify(_merkleProof, musics[_tokenId].merkleRoot, leaf),
      "Invalid Merkle Proof"
    );
  }
}