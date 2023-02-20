// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract EthMint is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private tokenIds;


    uint256 public price;
    uint256 public supply;
    uint256 public maxBuyCount;


    mapping (address => uint256) private whitelist;
    bool buyWhiteList = true;


    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _price,
        uint256 _supply,
        uint256 _maxBuyCount
    ) ERC721(_name, _symbol) {
        price = _price;
        supply = _supply;
        maxBuyCount = _maxBuyCount;
    }


    function _baseURI() internal pure override returns (string memory) {
        return 'https://klaythreekingdomsland.s3.ap-northeast-2.amazonaws.com/metadata/';
    }


    function mintBuy() public payable whenNotPaused {
        require(address(msg.sender) != address(0) && address(msg.sender) != address(this), 'wrong address');
        require(uint256(msg.value) != 0, 'wrong price');
        require(uint256(SafeMath.mod(uint256(msg.value), uint256(price))) == 0, 'wrong price');
        require(buyWhiteList == false || (buyWhiteList == true && whitelist[msg.sender] >= 1), 'for buy must be contains address in whitelist');
        

        uint256 amount = uint256(SafeMath.div(uint256(msg.value), uint256(price)));
        require(amount <= maxBuyCount, 'exceed maxBuyCount');
        require(buyWhiteList == false || (buyWhiteList == true && whitelist[msg.sender] >= amount), 'exceed maxBuyCount whitelist');

        mints(msg.sender, amount);
    }


    function mints(
        address _to,
        uint256 _amount
    ) private {
        for (uint i = 0; i < _amount; i++) {
            require(tokenIds.current() < supply, 'exceed supply');

            tokenIds.increment();
            _safeMint(_to, tokenIds.current());


            if (buyWhiteList == true && whitelist[msg.sender] >= 1){
                whitelist[msg.sender] -= 1;
            }
        }
    }


    // ***** white list *****
    function addWhitelist(address user, uint256 value) public onlyOwner {
        whitelist[user] += value;
    }
    function addWhitelists(address[] memory users, uint256[] memory value) public onlyOwner {
        for (uint256 i = 0 ; i < users.length; i++) {
            whitelist[users[i]] += value[i];
        }
    }
    function containsWhitelist(address user) public view returns (uint256) {
        return whitelist[user];
    }
    function removeWhitelist(address user, uint256 value) public onlyOwner {
        whitelist[user] -= value;
    }
    function setWhitelistForce(address user, uint256 value) public onlyOwner {
        whitelist[user] = value;
    }
    function getWhiteListCount(address user) public view returns (uint256) {
        return whitelist[user];
    }
    function getBuyWhiteList() public view returns (bool) {
        return buyWhiteList;
    }


    // ***** public view *****
    function getCurrentCount() public view returns (uint256) {
        return tokenIds.current();
    }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function getSupply() public view returns (uint256) {
        return supply;
    }
    function getPrice() public view returns (uint256) {
        return price;
    }
    

    // onlyOwner
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
    function withdraw(address payable _to) public onlyOwner {
        _to.transfer(address(this).balance);
    }
    function setMaxAmount(uint256 _maxBuyCount) public onlyOwner {
        maxBuyCount = _maxBuyCount;
    }
    function setBuyWhiteList(bool _buyWhiteList) public onlyOwner {
        buyWhiteList = _buyWhiteList;
    }
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }
    function setSupply(uint256 _supply) public onlyOwner {
        supply = _supply;
    }
    function setTokenIds(uint256 _amount) public onlyOwner {
        for (uint i = 0; i < _amount; i++) {
            tokenIds.increment();
        }
    }
    function mintBatch(address _to, uint256 _tokenId) external onlyOwner {
        _safeMint(_to, _tokenId);
    }
    function mintBatchs(address _to, uint256 _amount) external onlyOwner {
        for (uint i = 0; i < _amount; i++) {
            mints(_to, 1);
        }
    }


    // internal
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    // overrides
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}