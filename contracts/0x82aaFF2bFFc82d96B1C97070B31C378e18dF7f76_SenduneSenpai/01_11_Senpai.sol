/*
    このコードはERC721トークンのスマートコントラクトで、
    Senpaiというコレクションを作成します。以下は各関数の
    説明です。
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import '@openzeppelin/contracts/access/Ownable.sol';
import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
contract SenduneSenpai is ERC721A, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
  using Strings for uint256;
  // 公開されるメタデータ
  string public metadata;
  // 非公開のメタデータ
  string public hiddenMetadata;
  // 最大供給量
  uint256 public maxSupply = 5000;
  // 最大無料取得数
  uint256 public freeAllocation = 1000;
  // 一人当たりの最大保有量
  uint256 public maxPerWallet;
  // ファイルのサフィックス
  string public suffix = '.json';
  // メルクルルート
  bytes32 public root;
  // 一時停止中かどうか
  bool public paused = true;
  // リーベルが有効かどうか
  bool public revealLive = false;

  constructor() ERC721A("Sendune Senpai", "SENPAI")  {
    _safeMint(msg.sender, 1);
  }

  /*
    @dev オーナーがトークンを発行するための関数です。
  */
  function devMint(uint256 qty) public onlyOwner {
    _safeMint(msg.sender, qty);
  }


  /**
  @dev Senpaiトークンをバーンするための関数です。
  */
  function burnSenpai(uint256 tokenId) external {
    require(ownerOf(tokenId) == _msgSender(), "You do not own the Senpai");
    _burn(tokenId, true);
  }

  /**
  @dev 現在の発行量に応じて価格を取得する関数です。Tiered pricing.
    // トークン (token) 0 - 1000 ~~~~~~~~~~~~~ free フリー
    // トークン (token) 1001 - 3000 ~~~~~~~~~~ .004 eth
    // トークン (token) 3001 - 5000 ~~~~~~~~~~ .005 eth
  */
  function getPrice() public view returns (uint256) {
    uint256 minted = totalSupply();
    uint256 cost = 0;
    if (minted < freeAllocation) {
        cost = 0;
    } else if (minted < 3000) {
        cost = 0.004 ether;
    } else if (minted < 5000) {
        cost = 0.005 ether;
    } else {
        cost = 0.005 ether;
    }
    return cost;
  }

  /**
  @dev Senpaiトークンをマイントするための関数です。
  */
  function mintSenpai(uint256 _mintAmount) public payable nonReentrant {
    require(!paused, 'Senpai mint is paused. Please wait.');
    require(totalSupply() + _mintAmount <= maxSupply, 'Sold out');

    uint256 price = getPrice();
    uint256 _maxPerWallet = 10; // Maximum for order
    if (price == 0) {
      _maxPerWallet = 1;
    }

    if ((msg.value >= _mintAmount * price) && price != 0) {
    } else {
      require(
        _numberMinted(msg.sender) + _mintAmount <= _maxPerWallet,
        "1 free allowed"
      );
    }    

    require(msg.value >= _mintAmount * price, 'Insufficient Funds!');
    _safeMint(_msgSender(), _mintAmount);
  }


  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  /**
  @dev トークンIDを基にURIを取得するための関数です。
  */
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealLive == false) {
      return hiddenMetadata;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
    ? string(abi.encodePacked(currentBaseURI, "/", _tokenId.toString(), suffix))
    : '';
  }

  /**
  @dev Senpaiトークンのメタデータをリークするかどうかを設定する関数です。
  */
  function setReveal(bool _state) public onlyOwner {
    revealLive = _state;
  }

  /**
    @dev 非公開のメタデータURLを設定する関数です。
  */
  function setSenpaiMetadataUrl(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadata = _hiddenMetadataUri;
  }

  /**
    @dev URI接頭辞を設定する関数です。
  */
  function setUriPrefix(string memory _metadata) public onlyOwner {
    metadata = _metadata;
  }

  /**
    @dev URI接尾辞を設定する関数です。
  */
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    suffix = _uriSuffix;
  }

  /**
    @dev セールの状態を設定する関数です。
  */
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  /**
    @dev コレクションの最大供給量を設定する関数です。
  */
  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  /*
    @dev コントラクトから資金を引き出すための関数です。
  */
  function withdraw() public onlyOwner {

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return metadata;
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public payable
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}