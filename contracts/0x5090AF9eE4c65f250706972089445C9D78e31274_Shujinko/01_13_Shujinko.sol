// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";

/**
 * @title Shujinkō
 * @author @shujinkonft
 */
contract Shujinko is ERC721AQueryable, ERC721ABurnable, Ownable {
    using PRBMathUD60x18 for uint256;
    using Strings for uint256;

    uint256 private constant ONE_PERCENT = 10000000000000000; // 1% (18 decimals)

    // @dev nft のベース uri
    string private baseURI;

    // @dev nft の隠し uri
    string public hiddenURI =
        "ipfs://bafybeidrxvcgnns2kb4mp34jd7npnydnwmzypryntjjzv3os2gm2jgkuv4/prereveal.json";

    // @dev マークルルート証明
    bytes32 public merkleRoot =
        0x4c85142df33a2228d9a113e22859c0352e9f07feaf54dbc983d67b5475222bcb;

    // @dev ob リストのマークルルート
    bytes32 public obMerkleRoot =
        0xf7d9a2553ecd1312f34ff996374143812f5b960489f0a4057edaa1b264b2fac0;

    // @dev 公開フラグ
    bool public isRevealed = false;

    // @dev ミントの値段
    uint256 public price = 0.015 ether;

    // @dev 引き出しアドレス
    address public treasury =
        payable(0xF8114e3D55A25b4bC79e9A7306912fF1294A61FD);

    // @dev チームアドレス
    address public team = payable(0x6d9ed472Da62B604eD479026185995889ae8f80e);

    // @dev 合計ミントのアドレス マッピング
    mapping(address => uint256) public addressToWL;

    // @dev oblis mintsのアドレスマッピング
    mapping(address => uint256) public addressToFree;

    // @dev ウォレットごとの最大合計 (n - 1)
    uint256 public maxPerWallet = 3;

    // @notice ~ 9:15am EST 9/25/22
    uint256 public whitelistLiveAt = 1664111700;

    // @notice ~ 12:15pm EST 9/25/22
    uint256 public publicLiveAt = 1664122500;

    // @notice ~ 5:00pm EST 9/25/22
    uint256 public oblisLiveAt = 1664139600;

    // @dev コレクションの総供給量 (n - 1)
    uint256 public maxSupply = 5556;

    // @dev ホワイトリストの供給 (n - 1)
    uint256 public whitelistSupply = 3756;

    // @dev 予約済みの供給 (n - 1)
    uint256 public reservedSupply = 1801;

    // @dev ホワイトリストのミントカウントを追跡する
    uint256 public whitelistMinted = 0;

    // @dev obリストのミントカウントを追跡する
    uint256 public oblisMinted = 0;

    constructor() ERC721A("Shujinko", "Shujinko") {
        _mintERC2309(treasury, 55); // チームミント
    }

    /**
     * @notice ミント フェーズのライブ タイムスタンプを設定する
     * @param _whitelistLiveAt A base uri
     */
    function setLiveAt(
        uint256 _whitelistLiveAt,
        uint256 _publicLiveAt,
        uint256 _oblisLiveAt
    ) external onlyOwner {
        whitelistLiveAt = _whitelistLiveAt;
        publicLiveAt = _publicLiveAt;
        oblisLiveAt = _oblisLiveAt;
    }

    // @dev ホワイトリストのミントがライブかどうかを確認する
    function isWhitelistLive() public view returns (bool) {
        return block.timestamp > whitelistLiveAt;
    }

    // @dev 公開ミントがライブかどうかを確認する
    function isPublicLive() public view returns (bool) {
        return block.timestamp > publicLiveAt;
    }

    // @dev oblis mint がライブかどうかを確認する
    function isOblisLive() public view returns (bool) {
        return block.timestamp > oblisLiveAt;
    }

    /**
     * @notice マークルプルーフを必要とするホワイトリストに登録されたミント機能 (ウォレットあたりの最大数)
     * @param _amount ミントの量
     * @param _proof マークル ルートを検証するための bytes32 配列の証明
     */
    function whitelistMint(uint256 _amount, bytes32[] calldata _proof)
        external
        payable
    {
        require(isWhitelistLive(), "0");
        require(whitelistMinted + _amount < whitelistSupply, "1");
        require(msg.value >= _amount * price, "2");
        require(addressToWL[_msgSender()] + _amount < maxPerWallet, "3");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "4");
        addressToWL[_msgSender()] += _amount;
        whitelistMinted += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @notice Ob list マークルプルーフを必要とするFREE Minting機能（ウォレットあたりの最大）
     * @param _amount ミントの量
     * @param _proof マークル ルートを検証するための bytes32 配列の証明
     */
    function oblisMint(uint256 _amount, bytes32[] calldata _proof) external {
        require(isOblisLive(), "0");
        require(oblisMinted + _amount < reservedSupply, "1");
        require(addressToFree[_msgSender()] + _amount < maxPerWallet, "2");
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(MerkleProof.verify(_proof, obMerkleRoot, leaf), "4");
        addressToFree[_msgSender()] += _amount;
        oblisMinted += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @notice パブリックミント
     * @param _amount 鋳造するトークンの数
     */
    function mint(uint256 _amount) external payable {
        require(isPublicLive(), "0");
        require(msg.value >= _amount * price, "1");
        require(whitelistMinted + _amount < whitelistSupply, "3");
        whitelistMinted += _amount;
        _mint(_msgSender(), _amount);
    }

    /**
     * @dev ミントの残量を確認する
     * @param _address ミントアドレスルックアップ
     */
    function remainingWhitelistMints(address _address)
        public
        view
        returns (uint256)
    {
        if ((maxPerWallet - 1) > addressToWL[_address]) {
            return maxPerWallet - addressToWL[_address] - 1;
        }
        return 0;
    }

    /**
     * @dev ミントの残量を確認する
     * @param _address ミントアドレスルックアップ
     */
    function remainingoblisMints(address _address)
        public
        view
        returns (uint256)
    {
        if ((maxPerWallet - 1) > addressToFree[_address]) {
            return maxPerWallet - addressToFree[_address] - 1;
        }
        return 0;
    }

    /**
     * @dev 開始トークン ID を返します
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @notice 指定されたトークン ID の URI を返します
     * @param _tokenId トークン ID
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenId)) revert OwnerQueryForNonexistentToken();
        if (!isRevealed) return hiddenURI;
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId)));
    }

    /**
     * @notice 公開フラグを設定します
     * @param _isRevealed コレクションが公開されているかどうかのフラグ
     */
    function setIsRevealed(bool _isRevealed) external onlyOwner {
        isRevealed = _isRevealed;
    }

    /**
     * @notice NFT の隠し URI を設定します
     * @param _hiddenURI 隠しウリ
     */
    function setHiddenURI(string calldata _hiddenURI) external onlyOwner {
        hiddenURI = _hiddenURI;
    }

    /**
     * @notice NFT のベース URI を設定します
     * @param _baseURI ベース uri
     */
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    /**
     * @notice ミントのマークルルートを設定します
     * @param _merkleRoot 設定するマークル ルート
     */
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
     * @notice ミントのマークルルートを設定します
     * @param _obMerkleRoot 設定するマークル ルート
     */
    function setObMerkleRoot(bytes32 _obMerkleRoot) external onlyOwner {
        obMerkleRoot = _obMerkleRoot;
    }

    /**
     * @notice ウォレットごとの最大値を設定します
     * @param _maxPerWallet アドレスごとの最大ミントカウント
     */
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    /**
     * @notice コレクションの最大供給量を設定します
     * @param _whitelistSupply コレクションのホワイトリスト供給
     * @param _reservedSupply コレクションの予約供給
     */
    function setMaxSupplies(uint256 _whitelistSupply, uint256 _reservedSupply)
        external
        onlyOwner
    {
        whitelistSupply = _whitelistSupply;
        reservedSupply = _reservedSupply;
    }

    /**
     * @notice 価格設定
     * @param _price 魏の価格
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice 財務受取人を設定します
     * @param _treasury 財務省の住所
     */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = payable(_treasury);
    }

    // @notice 契約から資金を引き出す
    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool s1, ) = treasury.call{value: amount.mul(ONE_PERCENT * 92)}("");
        (bool s2, ) = team.call{value: amount.mul(ONE_PERCENT * 8)}("");
        if (s1 && s2) return;
        // fallback to owner
        (bool s4, ) = payable(_msgSender()).call{value: amount}("");
        require(s4, "Payment failed");
    }
}