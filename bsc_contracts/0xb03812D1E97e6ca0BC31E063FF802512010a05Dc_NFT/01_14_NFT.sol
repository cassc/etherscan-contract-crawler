// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
 
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import './interfaces/INFT.sol';
 
contract NFT is INFT, ERC721Enumerable, ERC721URIStorage {
 
    address public owner; // 记录合约发布者
    uint256 public lastTokenId = 100000; // 记录最后1个tokenId，初始tokenId为100000
    string public contractURI; // 如果上opensea会用到此参数
 
    // 发布合约时，传入name和symbol两个参数
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
        owner = _msgSender();
    }
 
    // 设置contractURI参数
    function setContractURI(string memory _contractURI) external override virtual returns(bool) {
        require(msg.sender == owner, 'NFT: 4001');
        contractURI = _contractURI;
        return true;
    }
 
    // 创建token接口，传入tokenURI
    function createToken(string memory _tokenURI) external override virtual returns(uint256 tokenId) {
        // 此处要求只有合约发布者可以创建
        require(_msgSender() == owner, "NFT: 4002");
        tokenId = mint(owner, _tokenURI);
        // 如果没有设置过contractURI，将第一个tokenURI设置给contractURI
        if(bytes(contractURI).length == 0 ){
            contractURI = _tokenURI;
        }
    }
 
    // 传入tokenId，获取token详情（返回owner、symbol、name、tokenURI）
    function getInfo(uint256 _tokenId) external view virtual override returns (address ownerAddress, string memory name, string memory symbol, string memory _tokenURI) {
        ownerAddress = super.ownerOf(_tokenId);
        name = super.name();
        symbol = super.symbol();
        _tokenURI = tokenURI(_tokenId);
    }
 
    // 私有函数，用于打造NFT
    function mint(address _to, string memory _tokenURI) private returns (uint256) {
        lastTokenId++; // tokenId加1
        _mint(_to, lastTokenId); // 将token打造给_to
        _setTokenURI(lastTokenId, _tokenURI); // 设置tokenURI
 
        return lastTokenId;
    }
 
    // 根据tokenId获取tokenURI
    function tokenURI(uint256 tokenId) public view virtual override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
 
    // 燃烧token
    function _burn(uint256 tokenId) internal virtual override (ERC721, ERC721URIStorage) {
        require(tokenId > 0, "GoShard: 4003");
        super._burn(tokenId);
    }
 
    // 在转赠NFT前执行的操作
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        // TODO 此处可以加入自己的逻辑
        super._beforeTokenTransfer(from, to, tokenId);
    }
 
    // 判断支持的接口
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
 
    // 获取指定地址拥有的全部token
    function getTokens(address _user) external view override virtual returns(uint256[] memory) {
        // 第一次遍历所有token，找到属于_user的token，记录到_userTokens数组
        uint256[] memory _userTokens = new uint256[](lastTokenId);
        uint256 idx = 0;
        for(uint256 tokenId = 100000 + 1; tokenId <= lastTokenId; tokenId++){
            if(super.ownerOf(tokenId) == _user){
                _userTokens[idx] = tokenId;
                idx++;
            }
        }
        // idx为_userTokens数组长度，再次遍历，将值赋给新的数组userTokens
        // 遍历两次是因为_userTokens的长度为lastTokenId，中间会有0值，第二次遍历实现将0值排除，保留有效的tokenId并返回
        uint256[] memory userTokens = new uint256[](idx);
        for(uint256 i = 0; i < idx; i++){
            userTokens[i] = _userTokens[i];
        }
        return userTokens;
    }
}