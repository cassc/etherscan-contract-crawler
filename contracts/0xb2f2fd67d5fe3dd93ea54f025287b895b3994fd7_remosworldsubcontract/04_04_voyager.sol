// SPDX-License-Identifier: MIT


/*

$$$$$$$\  $$$$$$$$\ $$\      $$\  $$$$$$\         
$$  __$$\ $$  _____|$$$\    $$$ |$$  __$$\       
$$ |  $$ |$$ |      $$$$\  $$$$ |$$ /  $$ |      
$$$$$$$  |$$$$$\    $$\$$\$$ $$ |$$ |  $$ |       
$$  __$$< $$  __|   $$ \$$$  $$ |$$ |  $$ |     
$$ |  $$ |$$ |      $$ |\$  /$$ |$$ |  $$ |     
$$ |  $$ |$$$$$$$$\ $$ | \_/ $$ | $$$$$$  |   
\__|  \__|\________|\__|     \__| \______/    


$$\    $$\                                                                   $$$$$$$$\      $$\ $$\   $$\     $$\                     
$$ |   $$ |                                                                  $$  _____|     $$ |\__|  $$ |    \__|                    
$$ |   $$ | $$$$$$\  $$\   $$\  $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\        $$ |      $$$$$$$ |$$\ $$$$$$\   $$\  $$$$$$\  $$$$$$$\  
\$$\  $$  |$$  __$$\ $$ |  $$ | \____$$\ $$  __$$\ $$  __$$\ $$  __$$\       $$$$$\   $$  __$$ |$$ |\_$$  _|  $$ |$$  __$$\ $$  __$$\ 
 \$$\$$  / $$ /  $$ |$$ |  $$ | $$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|      $$  __|  $$ /  $$ |$$ |  $$ |    $$ |$$ /  $$ |$$ |  $$ |
  \$$$  /  $$ |  $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$   ____|$$ |            $$ |     $$ |  $$ |$$ |  $$ |$$\ $$ |$$ |  $$ |$$ |  $$ |
   \$  /   \$$$$$$  |\$$$$$$$ |\$$$$$$$ |\$$$$$$$ |\$$$$$$$\ $$ |            $$$$$$$$\\$$$$$$$ |$$ |  \$$$$  |$$ |\$$$$$$  |$$ |  $$ |
    \_/     \______/  \____$$ | \_______| \____$$ | \_______|\__|            \________|\_______|\__|   \____/ \__| \______/ \__|  \__|
                     $$\   $$ |          $$\   $$ |                                                                                   
                     \$$$$$$  |          \$$$$$$  |                                                                                   
                      \______/            \______/                                                                                    


$$\                        $$$$$$\  $$\                 $$\                                $$\     $$\       
$$ |                      $$  __$$\ \__|                $$ |                               $$ |    $$ |      
$$$$$$$\  $$\   $$\       $$ /  \__|$$\ $$\   $$\  $$$$$$$ | $$$$$$\ $$\    $$\  $$$$$$\ $$$$$$\   $$$$$$$\  
$$  __$$\ $$ |  $$ |      $$ |$$$$\ $$ |$$ |  $$ |$$  __$$ |$$  __$$\\$$\  $$  |$$  __$$\\_$$  _|  $$  __$$\ 
$$ |  $$ |$$ |  $$ |      $$ |\_$$ |$$ |$$ |  $$ |$$ /  $$ |$$$$$$$$ |\$$\$$  / $$$$$$$$ | $$ |    $$ |  $$ |
$$ |  $$ |$$ |  $$ |      $$ |  $$ |$$ |$$ |  $$ |$$ |  $$ |$$   ____| \$$$  /  $$   ____| $$ |$$\ $$ |  $$ |
$$$$$$$  |\$$$$$$$ |      \$$$$$$  |$$ |\$$$$$$  |\$$$$$$$ |\$$$$$$$\   \$  /$$\\$$$$$$$\  \$$$$  |$$ |  $$ |
\_______/  \____$$ |       \______/ \__| \______/  \_______| \_______|   \_/ \__|\_______|  \____/ \__|  \__|
          $$\   $$ |                                                                                         
          \$$$$$$  |                                                                                         
           \______/          
                                                                                           
*/


import "./contract.sol";
import "./library.sol";

pragma solidity ^0.8.14;

contract remosworldsubcontract is ERC721A, Ownable, ReentrancyGuard {
    using Strings for uint256;

    IERC721A public remosAddress;

    string public uriPrefix = "";
    string public uriSuffix = "";

    bool public revealed = false;
    bool public paused = true;
    
    mapping(address => uint) public minted;
    mapping(uint => bool) public idMinted;

    uint256 public maxSupply = 500;
    uint256 public maxWalletAmount;
    

    uint256 public mintedNFT;
    
    uint256 public priceNFT = 0 ether;
    string public hiddenMetadataUri = "ipfs://";

    string public _name = "REMO: Voyager Edition";
    string public _symbol = "REM001";
    
    constructor() ERC721A(_name, _symbol) {}

    modifier mintCompliance(uint256 _mintAmount) {
        require(msg.value >= priceNFT * _mintAmount, "Insufficient Funds");
        require(totalSupply() + _mintAmount <= maxSupply, "Mintable supply exceeded!");
        require(paused == false, "Contract paused");
        _;}

    function checkBalance(address _addr) public view returns (uint256) {
        uint256 balance = remosAddress.balanceOf(_addr);
        return balance;}

    function checkNFT(uint256[]memory _tokenId) public view returns (uint256[] memory, uint256[] memory) {
        
        uint256 _mintedAmount;
        uint256 _notMintedAmount;

        for (uint256 i = 0; i < _tokenId.length; i++) {
            if (idMinted[_tokenId[i]] == false) {
                _notMintedAmount ++;}
            else {
                _mintedAmount ++;}}

        uint256[] memory _notMintedNFT = new uint256[](_notMintedAmount);
        uint256[] memory _mintedNFT = new uint256[](_mintedAmount);
        uint256 _counterNotMinted;
        uint256 _counterMinted;

        for (uint256 i = 0; i < _tokenId.length; i++) {
            if (idMinted[_tokenId[i]] == false) {
                _notMintedNFT[_counterNotMinted] = _tokenId[i];
                _counterNotMinted ++;}
            else {
                _mintedNFT[_counterMinted] = _tokenId[i];
                _counterMinted ++;}}

        return (_notMintedNFT, _mintedNFT);}

    function setPrice(uint256 _price) public onlyOwner {
        priceNFT = _price;}

    function setNFTAddress(address _addr) public onlyOwner {
        remosAddress = IERC721A(_addr);}

    function ownerBlacklistBatchNFT(uint256[]memory _nftId) public onlyOwner {
        for (uint256 i = 0; i < _nftId.length; i++) {
            idMinted[_nftId[i]] = true;}}

    function blacklistBatchNFT(uint256[]memory _nftId) private {
        for (uint256 i = 0; i < _nftId.length; i++) {
            idMinted[_nftId[i]] = true;}}

    function mint(uint256[] memory _tokenId) public payable mintCompliance(_tokenId.length) nonReentrant {
        for (uint256 i = 0; i < _tokenId.length; i++) {
            require(remosAddress.ownerOf(_tokenId[i]) == _msgSender() && idMinted[_tokenId[i]] == false, "Not NFT owner or NFT not valid");}
        _safeMint(_msgSender(), _tokenId.length);
        blacklistBatchNFT(_tokenId);}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;}

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;}
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)): '';}
    
    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;}

    function setPause(bool _state) public onlyOwner {
        paused = _state;}

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;}

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;}

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;}

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;}

    function getMinted() public view returns (uint256, uint256) {
        uint256 _mintedNFT = totalSupply();
        uint256 _totalSupply = maxSupply;
        return (_mintedNFT, _totalSupply);}

    receive() external payable {}

    fallback() external payable {}

    function transferERC20(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {  
        require(new_type_IERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferERC20O(address _tokenAddr, address _to, uint _amount) public onlyOwner nonReentrant {    
        old_type_IERC20(_tokenAddr).transfer(_to, _amount);}
        
    function withdrawEther(address _to) public onlyOwner nonReentrant {
        (bool os, ) = payable(_to).call{value: address(this).balance}('');
        require(os);}}
