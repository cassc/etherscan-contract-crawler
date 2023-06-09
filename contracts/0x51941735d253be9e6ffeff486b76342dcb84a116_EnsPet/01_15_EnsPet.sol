//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./libraries/ENS.sol";

contract EnsPet is ERC721Enumerable, Ownable {
    event SetNode(uint256 _tokenId,bytes32 node);

    ENS immutable ens;
    using Counters for Counters.Counter;
    using Strings for uint256;
    uint256 MAX_TO_MINT = 1333;
    bool public frozen=false;
    string public baseURI;
    uint256[6] private _prices;
    uint256[6] private _priceSteps;
    address cOwner;
    address payable wWallet;
    mapping (bytes32 => uint256) public nodes;
    

    constructor(
        string memory name,
        string memory symbol,
        ENS _ens,
        string memory i_baseURI,
        address _cOwner, 
        address payable _wWallet
    ) ERC721(name, symbol) {
        ens = _ens;
        baseURI = i_baseURI;
        cOwner = _cOwner;
        wWallet = _wWallet;
         _prices = [0.03 ether,0.06 ether, 0.09 ether, 0.12 ether, 0.15 ether, 0.18 ether];
        _priceSteps = [
            1, 
            51,
            201,
            501,
            801,
            1101
        ];
    }

    modifier authorised(bytes32 node) {
        address eow = ens.owner(node);
        require(eow == msg.sender || ens.isApprovedForAll(eow,msg.sender));
        _;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public {
        require(!frozen);
        require(msg.sender == cOwner);
        baseURI = _baseTokenURI;
    }
    function setFrozen() public {
        require(msg.sender == cOwner);
        frozen=true;
    }
    function withdraw() public {
        require(msg.sender == cOwner);
        wWallet.transfer(address(this).balance);
    }
    function getPriceForId(uint256 tokenId) internal view virtual returns (uint256) {
        uint256 _priceStepsLen=_priceSteps.length;
        for (uint8 i = 0; i < _priceStepsLen; i++) {
            if (_priceSteps[i] > tokenId) {
                return _prices[i - 1];
            }
        }
        return _prices[_prices.length - 1];
    }
    function noccupy(bytes32 node) internal view virtual returns (bool) {
        if(nodes[node]>0){
            if(ownerOf(nodes[node])==msg.sender){
                return true;
            }
        }
        return false;
    }
    function setNode(uint256 _tokenId,bytes32 o_node,bytes32 node) public authorised(node) {
        require(!noccupy(node));
        require(ownerOf(_tokenId)==msg.sender,"Not the owner of the token");
        if(nodes[o_node]==_tokenId){
            nodes[o_node]=0;
        }
        nodes[node]=_tokenId;
        emit SetNode(_tokenId, node);
    }
    function mint(bytes32 node) public payable authorised(node) {
        require(!noccupy(node));
        require(tx.origin == msg.sender, "The caller is another contract");
        uint256 tokenId = totalSupply() + 1;
        uint256 price = getPriceForId(tokenId);
        require(msg.value >= price, "insufficient funds");
        require(tokenId <= MAX_TO_MINT, "Would exceed max supply");
        _safeMint(msg.sender, tokenId);
        nodes[node]=tokenId;
        emit SetNode(tokenId, node);
    }

}