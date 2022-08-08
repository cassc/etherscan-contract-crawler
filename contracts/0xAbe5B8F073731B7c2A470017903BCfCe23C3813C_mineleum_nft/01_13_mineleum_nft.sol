// SPDX-License-Identifier: MIT
// Amended by Mineleum
pragma solidity >=0.7.0 <0.8.7;
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract mineleum_nft is ERC721Enumerable, Ownable {
    using Strings for uint256;
    string baseURI;
    // string public notRevealedUri;
    string public baseExtension = ".json";
    string public baseExtensionSecret = "secret.json";
    uint256 public sendCost = 0.0 ether;
    uint256 public mintCost = 0.0 ether;
    uint256 public sellRate = 100;//一回にmintできる数
    uint256 public maxSupply = 100000;//最大供給量
    uint256 public maxMintAmount = 10;//一回にmintできる数
    bool public paused = false;//falseでmint可能
    mapping(uint256 => bool) public tokenRevealed;//トークン別シークレット公開
    mapping(address => bool) public mintAddressList;//mint可能アドレス
    mapping(uint256 => uint256) public tokenSellCost;//トークン別値段
    //一番最初に実行される
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
    }
    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
    // public  mint
    function mint(uint256 _mintAmount) public payable{
        uint256 supply = totalSupply();
        require(!paused,"mint: this mint is paused");
        require(supply + _mintAmount <= maxSupply,"mint: max supply");
        require(_mintAmount > 0,"mint: 0");
        require(_mintAmount <= maxMintAmount,"mint: max mint over");
        if (msg.sender != owner()) {
            require(mintAddressList[msg.sender],"mint: impossible address");//mintaddresslistに登録してないaddressは弾く
            require(msg.value >= mintCost * _mintAmount);
        }
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, supply + i);
        }
    }
    //ミント可能なアドレスリストを登録する
    function setMintAddressList(address[] memory _addresses) public onlyOwner{
        for (uint256 i = 0; i < _addresses.length; i++) {
            mintAddressList[_addresses[i]] = true;
        }
    }
    //ウォレットアドレスを入れると何個持ってるか調べられる
    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }
    //トークンidを入れるとtokenURIが見れる
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
        
        string memory currentBaseURI = _baseURI();
        //シークレット解放していなければシークレット
        if(tokenRevealed[tokenId] == false) {
            return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtensionSecret))
            : "";
        }
        //難しく見えるがbaseURI + tokenID + 修飾子を繋げてるだけ
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
    //秘密の画像を公開
    function reveal(uint256 _tokenId) public payable{
        require(_exists(_tokenId),"Reveal: URI query for nonexistent token");
        require(!tokenRevealed[_tokenId],"Reveal: Issued");
        if (msg.sender != owner()) {
            require(ownerOf(_tokenId) == msg.sender,"Reveal: Not owner");
            require(msg.value >= sendCost);
        }
        tokenRevealed[_tokenId] = true;
    }
    //秘密の画像の確認
    function checkReveal(uint256 _tokenId) public view returns (bool){
        require(_exists(_tokenId),"Reveal: URI query for nonexistent token");
        return tokenRevealed[_tokenId];
    }
    //秘密の画像を戻す
    function hide(uint256 _tokenId) public onlyOwner{
        require(_exists(_tokenId),"Reveal: URI query for nonexistent token");
        require(tokenRevealed[_tokenId],"Reveal: Not Issued");
        tokenRevealed[_tokenId] = false;
    }
    //送料を変える
    function setSendCost(uint256 _newCost) public onlyOwner{
        //1000 = 1.0eth
        uint256 cost = _newCost * 1000000000000000;
        sendCost = cost;
    }
    //mint値段を変える
    function setMintCost(uint256 _newCost) public onlyOwner {
        uint256 cost = _newCost * 1000000000000000;
        mintCost = cost;
    }

    //売値を設定してこのコントラクトにNFTを送る
    function sendNFT(uint256 _tokenId,uint256 _sellCost) public {
        address _owner = ownerOf(_tokenId);
        require(_owner == msg.sender, "NFT none");
        if(_sellCost == 0){
            tokenSellCost[_tokenId] = 1000;
        }else{
            tokenSellCost[_tokenId] = _sellCost;
        }
        transferFrom(_owner, address(this), _tokenId);
    }
    //nftを買う
    function buyNFT(uint256 _tokenId,address _to) public payable{
        address _owner = ownerOf(_tokenId);
        require(_owner == address(this), "NFT none");
        if (msg.sender != owner()) {
            //1000 = 1.0eth
            uint256 c = tokenSellCost[_tokenId] * sellRate / 100;
            uint256 cost = c * 1000000000000000;
            require(msg.value >= cost);
        }
        _transfer(address(this), _to, _tokenId);
    }
    //売値をみる
    function showBuyCost(uint256 _tokenId) public view returns(uint256){
        //1000 = 1.0eth
        uint256 c = tokenSellCost[_tokenId] * sellRate / 100;
        uint256 cost = c * 1000000000000000;
        return cost;
    }
    //レートを変える
    function setSellRate(uint256 _rate) public onlyOwner{
        //nomal 100
        sellRate = _rate;
    }
    //一度に最大mint数を変える
    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }
    //最大供給数を変える
    function setmaxSuplly(uint256 _newmaxSupply) public onlyOwner {
        maxSupply = _newmaxSupply;
    }
    //NFTのURI
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    //tokenURIの修飾子を設定（.json）
    function setBaseExtension(string memory _newBaseExtension,string memory _newBaseExtensionSecret) public onlyOwner {
        baseExtension = _newBaseExtension;
        baseExtensionSecret = _newBaseExtensionSecret;
    }
    //mintを有効にするか設定
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
    //ethのバランス
    function ethBlance() public onlyOwner view returns(uint256){
        return(address(this).balance);
    }
    //
    function stateNFT() public view returns(string memory){
        uint256 b = address(this).balance;
        bytes memory str = abi.encodePacked(
            '{"sendcost":"' , sendCost.toString() , '",' ,
            '"mintcost":"' , mintCost.toString() , '",' ,
            '"maxmint":"' , maxMintAmount.toString() , '",'
        );
        bytes memory str2 = abi.encodePacked(
            str,
            '"maxsuplly":"' , maxSupply.toString() , '",' ,
            '"sellrate":"' , sellRate.toString() , '",' ,
            '"balance":"' , b.toString() , '"' ,
            '}'
        );

        return string(str2);
    }
    function withdraw() public payable onlyOwner {
        // これを削除しないでください。削除すると、資金を引き出すことができなくなります。
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }
}