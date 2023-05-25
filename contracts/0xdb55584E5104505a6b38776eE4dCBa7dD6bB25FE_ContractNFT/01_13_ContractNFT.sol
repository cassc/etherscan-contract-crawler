// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19 <0.8.5;
import "./Factory.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ContractNFT is Factory, ERC721 { 

    using SafeMath for uint256;
    event AssetsMinted(address owner);
    mapping(uint256 => uint256) private _totalSupply;

    constructor() ERC721("Visitors of Imma Degen", "VOID") {
        contractOnwers.push(ContractOwners(payable(address(0x23A8b7F4cf5FB0D40Aa7DB57b8cd376d3332130e)), 40));
        contractOnwers.push(ContractOwners(payable(address(0x7E145B6B4100188bf8FBC989Afeb17aCe8134446)), 20));
        contractOnwers.push(ContractOwners(payable(address(0x46674Cafc304949787c3ae11103CB9B834FaAEF7)), 20));
        contractOnwers.push(ContractOwners(payable(address(0xBcdc5969Ec1652Bf80fc15edFE50f9834a55067b)), 20));
    }

    modifier canBuy(uint _qty){
        require(msg.value == (assetPrice * _qty));
        _;
    }

    modifier canCreate() {
        require(assets.length < 9999);
        _;
    }

    modifier canWithdraw(){
        require(address(this).balance > 0.2 ether);
        _;
    }

    struct ContractOwners {
        address payable addr;
        uint percent;
    }

    ContractOwners[] contractOnwers;

    uint assetPrice = 0.08 ether;

    function withdraw() external payable onlyOwner() canWithdraw() {
        uint nbalance = address(this).balance - 0.1 ether;
        for(uint i = 0; i < contractOnwers.length; i++){
            ContractOwners storage o = contractOnwers[i];
            o.addr.transfer((nbalance * o.percent) / 100);       
        }
        
    }

    function balance() external view onlyOwner returns (uint)  {
        return address(this).balance;
    }

    function setAssetPrice(uint _fee) external onlyOwner {
        assetPrice = _fee;
    }

    function getAssetPrice() external view returns (uint){
        return assetPrice;
    }

    function getAssetsIdsByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](ownerAssetCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < assets.length; i++) {
            if (assetToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getAssetsCount() external view returns(uint){
        return assets.length;
    }

    function buyAssets(uint _qty) external payable canBuy(_qty) {
        require(_qty <= 20, "max 20 visitors at once");
        uint i = 0;
        while(i < _qty){
            mintAsset();
            i++;
        }
        emit AssetsMinted(msg.sender);
    }

    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId) internal override {
        if(address(0) != _from){
            ownerAssetCount[_to] = ownerAssetCount[_to].add(1);
        } 
        if(_to != assetToOwner[_tokenId]){
            ownerAssetCount[_from] = ownerAssetCount[_from].sub(1);
            assetToOwner[_tokenId] = _to;
        }
        
    }
    
    function mintAsset() internal canCreate() {
        Asset memory asset = Asset(assets.length + 1);
        assets.push(asset);
        uint id = assets.length;
        assetToOwner[id] = msg.sender;
        ownerAssetCount[msg.sender] = ownerAssetCount[msg.sender].add(1);
        _mint(msg.sender, id);
    }

}