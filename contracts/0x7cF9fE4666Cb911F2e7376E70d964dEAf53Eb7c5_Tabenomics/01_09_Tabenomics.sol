// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Tabenomics is ERC721A, Ownable, ERC721ABurnable, ERC721AQueryable{
    string public baseURI = "ipfs://bafybeidclrnogqvtp2ahfy4tq4tg6xj7y6axb7ng4uavapbsqjm4ysm6ea/metadata";   //ベースURI
    uint256 constant confirmMaxMint = 2;   //非確定WL、確定WL、1人辺りのミント最大数
    uint256 constant MaxMint = 3;   //パブリック1人辺りのミント最大数
    uint256 constant MaxNfts = 1500;   //NFTの総数
    uint256 constant MaxNftsOw = 2000;   //NFTの総数オーナー用
    uint256 constant startTokenId = 1;   //NFTミントスタートID
    uint256 constant NftSalePrice = 25000000000000000;   //確定、プレセール値
    uint256 constant NftPrice = 30000000000000000;   //パブリックセール値

    uint256 nowTokenId = 0;
    uint256 totalNFTs = 0;

    uint256 public saleStartTime1st = 1677582000; // 2023/02/28 20:00:00 JST
    uint256 public saleStartTime2nd = 1677583800; // 2023/02/28 20:30:00 JST
    uint256 public saleStartTimePublic = 1677592800; // 2023/02/28 23:00:00 JST
    uint256 public saleFinish = 1677679200; // 2023/02/29 23:00:00 JST

    uint256 totalMint;   //今までのミントされた合計数
    uint256[] MyNftTokenId;   //ユーザーの総トークンID
    address[] public whitelistedAddresses;   //非確定ホワイトリストアドレス
    address[] public confirmwhitelistedAddresses;   //確定ホワイトリストアドレス
    bool public onlyconfirmWhitelisted = false;   //確定ホワイトリストメンバーしかミントできない状態
    bool public onlyWhitelisted = false;   //ホワイトリストメンバーしかミントできない状態
    bool public onlypublic = false;   //パブリックセールの状態

    mapping(address => bool)public whitelist;
    mapping(address => bool)public oglist;
    uint256[] whitelist_max = [0,2,4,6,8,10];
    uint256[] oglist_max = [0,2,4,6,8,10,12];
    mapping(address => uint256) public WhitelistAddressMintedBalance;   //非確定ホワイトリストMint数
    mapping(address => uint256) public confirmWhitelistAddressMintedBalance;   //確定ホワイトリストMint数
    mapping(address => uint256) public WhitelistAddressMaxmint;   //非確定ホワイトリストMaxMint数
    mapping(address => uint256) public confirmWhitelistAddressMaxmint;   //確定ホワイトリストMaxMint数
    mapping(address => uint256) public stertWhitelistAddressMaxmint;   //初期確定ホワイトリストMaxMint数
    mapping(address => uint) public confirmWhitelistAddressRemainingmint;   //確定ホワイトリスト残りMint数
    mapping(address => uint) public WhitelistAddressRemainingmint;   //非確定ホワイトリスト残りMint数
    mapping(address => uint256) public addressMintedBalance;   //ユーザーMint数
    mapping(address => uint256) public UserBurnBalance;   //ユーザーバーン数


    constructor() ERC721A("Tabenomics", "NHA") {
    }

    event MintLog(address to, uint256 quantity);
    event TransferLog(address from, address to, uint256 tokenId);
    event TokenTransfer(address from, address receiver, uint amount);

    /// @dev ベースURI:ipfs//~
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @dev URIのスタートナンバー
    function _startTokenId() internal view virtual override returns (uint256){
        //nowTokenId = startTokenId;
        return startTokenId;
    }

    /// @dev URI次のIdナンバー
    function _nextTokenId() internal view virtual override returns (uint256){
        return nowTokenId;
    }

    /// @dev Mintされた合計数
    function _totalMinted() internal view override returns (uint256){
        return totalNFTs;
    }

    /// @dev 登録非確定ホワイトリストアドレス一覧取得関数
    function viewOGaddress()external view returns(address[] memory){
        return confirmwhitelistedAddresses;
    }

    /// @dev 登録確定ホワイトリストアドレス一覧取得関数
    function viewWLaddress()external view returns(address[] memory){
        return whitelistedAddresses;
    }

    /// @dev チェッカー関数
    function checker(address _user)external view returns(uint256){
        uint256 ans = 0;
        ans = ans + confirmWhitelistAddressMaxmint[_user];
        ans = ans << 8;
        ans = ans + WhitelistAddressMaxmint[_user];
        return ans;
    }

    /// @dev タイムスタンプ取得
    function getTime() external view  returns (uint256){
        return block.timestamp;
    }

    /**
    * @dev
    * - 最大数までMintされていたらMintしない
    */
    modifier MaxMints(){
        require(MaxNfts >= totalSupply(),"sold out");
        _;
    }

    /**
    * @dev
    * - 最大数までMintされていたらMintしない
    */
    modifier MaxMintsow(){
        require(MaxNftsOw >= totalSupply(),"sold out");
        _;
    }

    /**
    * @dev
    * - 最大数以上Mintしないよう制限
    */
    modifier NosingOverMints(uint256 quatity){
        require(quatity <= MaxNfts - totalSupply(),"Mints less please");
        _;
    }

    modifier NosingOverMintsow(uint256 quatity){
        require(quatity <= MaxNftsOw - totalSupply(),"Mints less please");
        _;
    }

    /// @dev ベースURI変更 リビール手動用、非常用
    function chngebaseURI(string memory uri) external onlyOwner () {
        baseURI = uri;
    }

    /**
    * @dev
    * - プレセール、通常時の価格設定
    * - プレセールファーストセールへの切り替え
    */
    function FirstSale()
    external
    onlyOwner
    {
        onlyconfirmWhitelisted = true;
        onlyWhitelisted = false;
        onlypublic = false;
    }

    /**
    * @dev
    * - プレセール、通常時の価格設定
    * - プレセールセカンドセールへの切り替え
    */
    function SecondSale()
    external
    onlyOwner
    {
        onlyconfirmWhitelisted = false;
        onlyWhitelisted = true;
        onlypublic = false;
    }

    /**
    * @dev
    * - セール、通常時の価格設定
    * - ノーマルセールへの切り替え
    */
    function NomalSale()
    external
    onlyOwner
    {
        onlyconfirmWhitelisted = false;
        onlyWhitelisted = false;
        onlypublic = true;
    }

    /**
    * @dev
    * - 販売なし状態切り替え
    */
    function NullSale()
    external
    onlyOwner
    {
        onlyconfirmWhitelisted = false;
        onlyWhitelisted = false;
        onlypublic = false;
    }

    function confirmwhitelistUsers(uint[] calldata ogmax)public onlyOwner{
        for(uint i = 1; i < ogmax.length + 1; i++){
            oglist_max[i] = ogmax[i];
            //confirmWhitelistAddressMaxmint[ogmax[i]] = oglist_max[i];
        }
        oglist_max[0] = 0;
    }

    function whitelistUsers(uint[] calldata whitelistmax)public onlyOwner{
        for(uint i = 1; i < whitelistmax.length + 1; i++){
            whitelist_max[i] = whitelistmax[i];
            //WhitelistAddressMaxmint[_users[i]] += confirmMaxMint;
            //stertWhitelistAddressMaxmint[_users[i]] += confirmMaxMint;
        }
        whitelist_max[0] = 0;
    }


    /**
    * @dev
    * - 確定ホワイトリストチェック関数
    */
    function confirmisWhitelisted(uint256 num)public view returns(bool){
        if(oglist_max[num] != 0){
            return true;
        }
        return false;
    }

    /**
    * @dev
    * - ホワイトリストチェック格納関数
    */
    function isWhitelisted(uint256 num)public view returns(bool){
        if(whitelist_max[num] != 0){
            return true;
        }
        return false;
    }
    
    /**
    * @dev
    * - ユーザーMint
    * - 一度のMint最大数3
    * - 最大数以上Mintしないように制限
    * - プレセール時はホワイトリストメンバーのみ制限
    */
    function MintUser(uint256 quantity, uint256 user_num) external
    payable
    MaxMints
    NosingOverMints(quantity)
    {
        require(onlypublic == true || onlyWhitelisted == true || onlyconfirmWhitelisted == true || (block.timestamp >= saleStartTime1st && block.timestamp <= saleFinish),"Time Out");
        if(onlyconfirmWhitelisted == true || (block.timestamp >= saleStartTime1st && block.timestamp <= saleStartTime2nd)){
            require(msg.value >= quantity * NftSalePrice, "Not enough money");
            require(confirmisWhitelisted(user_num),"user is not OG");
            
            uint256 confirmsalemaxmint = oglist_max[user_num];
            require(confirmWhitelistAddressMintedBalance[msg.sender] + quantity <= confirmsalemaxmint, "MaxMint Over");
            confirmWhitelistAddressRemainingmint[msg.sender] = confirmsalemaxmint - (confirmWhitelistAddressMintedBalance[msg.sender] + quantity);

            _nextTokenId();
            _safeMint(msg.sender, quantity);
            emit MintLog(msg.sender, quantity);
            withdraw();
            confirmWhitelistAddressMintedBalance[msg.sender] += quantity;
        }else if(onlyWhitelisted == true || (block.timestamp >= saleStartTime2nd && block.timestamp <= saleStartTimePublic)){
            require(msg.value >= quantity * NftSalePrice, "Not enough money");
            require(isWhitelisted(user_num),"user is not WL");
            
            uint256 salemaxmint = whitelist_max[user_num] + confirmWhitelistAddressRemainingmint[msg.sender];
            require(WhitelistAddressMintedBalance[msg.sender] + quantity <= salemaxmint, "MaxMint Over");
            WhitelistAddressRemainingmint[msg.sender] = salemaxmint - (WhitelistAddressMintedBalance[msg.sender] + quantity);

            _nextTokenId();
            _safeMint(msg.sender, quantity);
            emit MintLog(msg.sender, quantity);
            withdraw();
            WhitelistAddressMintedBalance[msg.sender] += quantity;
        }else if(onlypublic == true || (block.timestamp >= saleStartTimePublic && block.timestamp <= saleFinish)){
            require(msg.value >= quantity * NftPrice, "Not enough money");
            uint256 MintCount = addressMintedBalance[msg.sender];
            require(MintCount + quantity <= (MaxMint + WhitelistAddressRemainingmint[msg.sender]), "MaxMint Over");

            _nextTokenId();
            _safeMint(msg.sender, quantity);
            emit MintLog(msg.sender, quantity);
            withdraw();
            addressMintedBalance[msg.sender] += quantity;
        }
    }

    /**
    * @dev
    * - オーナーMint
    * - 一度のMint上限数なし
    * - 最大数以上Mintしないように制限
    * - Mintする
    * - クレジットカード支払い兼用 
    */
    function MintOwnerToCredit(address _to, uint256 quantity) external
     onlyOwner
     MaxMintsow
     NosingOverMintsow(quantity)
     {
        //require(MaxNfts >= totalNFTs,"sold out");
        //オーナー以外アドレスへのMintで合計数へ合算
        if(_to != owner()){
            addressMintedBalance[_to] += quantity;
        }
        _nextTokenId();
        _safeMint(_to, quantity);
        emit MintLog(_to, quantity);
    }

    /**
    * @dev
    * - オーナーMint
    * - 一度のMint上限数なし
    * - 最大数以上Mintしないように制限
    * - Mintする
    * - ギブアウェイ兼用
    */
    function MintOwnerToGive(address _to, uint256 quantity) external
     onlyOwner
     MaxMintsow
     NosingOverMintsow(quantity)
     {
        //require(MaxNfts >= totalNFTs,"sold out");
        _nextTokenId();
        _safeMint(_to, quantity);
        emit MintLog(_to, quantity);
    }

    /**
    * @dev
    * - バーン関数
    */
    function burn(uint256 tokenId, bool approvalCheck) internal virtual {
        _burn(tokenId, approvalCheck);
    }

    /**
    * @dev
    * - ここから送金等に関するスクリプト
    * - 特定アドレスのみフリーミント可能
    * - 最大数以上Mintしないように制限
    */

    // 接続アドレスのether残高を返す関数
    function getBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    // オーナーアドレスへコントラクトアドレスのethを全て送金
    function withdraw() public payable {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    /**
    * @dev
    * - ユーザートランスファー
    * - ユーザーの持っているNFTの数とTokenIdを出す
    * - 個数指定でランダムバーン
    * - その後条件にかけてburn
    */
    function UserBurn(
    uint256 quantity
    ) public virtual{
        uint256[] memory tokenNumber = MyTokenId();
        uint256 tokenleng = tokenNumber.length;
        uint256 index = 0;
        require(tokenleng >= quantity,"NFT Nons");
        while(quantity > index){
            _burn(tokenNumber[index], true);
            UserBurnBalance[msg.sender]++;
            index = index + 1;
        }
    }

    /**
    * @dev
    * - ユーザートランスファー
    * - ユーザーの持っているNFTの数とTokenIdを出す
    * - ID選択でバーン
    * - その後条件にかけてburn
    */
    function UserBurnSelect(
    uint256[] memory quantity
    ) public virtual{
        uint256[] memory tokenNumber = MyTokenId();
        uint256 tokenleng = tokenNumber.length;
        uint256 repetition = quantity.length;
        require(tokenleng >= repetition,"NFT Nons");
        for(uint i = 0; i < repetition; i++){
            bool chack = false;
            for(uint j = 0; j < tokenleng; j++){
                if(quantity[i] == tokenNumber[j]){
                    chack = true;
                }
            }
            require(chack, "NFT Nons");
        }
        for(uint i = 0; i < repetition; i++){
            _burn(quantity[i], true);
            UserBurnBalance[msg.sender]++;
        }
    }

    /**
    * @dev
    * - ユーザーバーン数の確認
    */
    function UserBurnView(address to)public view returns(uint256){
        return UserBurnBalance[to];
    }

    /**
    * @dev
    * - ユーザーバーン数のリセット
    */
    function UserBurnReset(address to, uint256 quantity)external onlyOwner (){
        UserBurnBalance[to] = UserBurnBalance[to] - quantity;
    }

    /**
    * @dev
    * - オーナートランスファー
    */
    function OwnerTransfer(
    address to,
    uint256 tokenId
    ) public virtual onlyOwner{
        transferFrom(owner(), to, tokenId);
        emit TransferLog(owner(), to, tokenId);
    }

    /**
    * @dev
    * - ユーザーの所持トークンIDを取得
    */
    function MyTokenId() private returns(uint256[] memory) {
        uint256 index = 1;
        uint256 dindex = 0;
        address user;
        uint leng = 0;
        totalMint = totalSupply();
        leng = MyNftTokenId.length;
        while (dindex < leng){
            MyNftTokenId.pop();
            dindex = dindex + 1;
        }
        while (index <= totalMint){
            user = ownerOf(index);
            if (user == msg.sender){
                MyNftTokenId.push(index);
            }
            index = index + 1;
        }
        return MyNftTokenId;
    }
}