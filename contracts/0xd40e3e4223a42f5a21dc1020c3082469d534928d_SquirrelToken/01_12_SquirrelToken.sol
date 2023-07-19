// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SquirrelToken is ERC721, Ownable {

    using Strings for uint;
    using Address for address;
    using Address for address payable;
    using Counters for Counters.Counter;

    string internal constant HIDDEN_META_PATH = "https://static.convictedsquirrels.com/meta/live/ph";

    Counters.Counter private _tokenIds;
    mapping(address => bool) private _presaleEligible;
    mapping(address => uint) private _mintings;
    bool private _publicSaleStarted = false;
    bool private _imagesRevealed = false;
    string private _metaPath;

    uint internal _mintingFee = 4e16; //0,04ETH
    uint internal _maxNumberPerTx = 10;
    uint internal _totalMintLimitPerAddress = 20;
    uint internal _totalTokenCount;

    event EthersWithdrawn(address indexed operator, address indexed to, uint amount);
    
    constructor(uint count) ERC721("ConvictedSquirrels", "CS") {
        _totalTokenCount = count;
    }

    function totalTokenCount() public view returns(uint) {
       return _totalTokenCount;
    }

    function totalMintLimitPerAddress() public view returns(uint) {
       return _totalMintLimitPerAddress;
    }

    function setTotalMintLimitPerAddress(uint newValue) external onlyOwner {
       _totalMintLimitPerAddress = newValue;
    }

    function mintedBy(address addr) public view returns(uint) {
        return _mintings[addr];
    }

    function mintingFee() public view returns(uint) {
       return _mintingFee;
    }
    
    function setMintingFee(uint newValue) external onlyOwner {
       _mintingFee = newValue;
    }

    function maxNumberPerTx() public view returns(uint) {
       return _maxNumberPerTx;
    }

    function setMaxNumberPerTx(uint newValue) external onlyOwner {
       _maxNumberPerTx = newValue;
    }

    function publicSaleStarted() external view returns(bool) {
       return _publicSaleStarted;
    }

    function togglePublicSaleStarted() external onlyOwner {
       _publicSaleStarted = true;
    }

    function revealImages(string memory metaPath) external onlyOwner {
        require(bytes(metaPath).length > 12, "SquirrelToken: suspicious path value");
       _imagesRevealed = true;
       _metaPath = metaPath;
    }

    function addToPresale(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0) && !addresses[i].isContract(), "SquirrelToken: wrong address");
            _presaleEligible[addresses[i]] = true;
        }
    }

    function checkPresaleEligibility(address addr) external view returns (bool) {
        return _presaleEligible[addr];
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory imgPath = _imagesRevealed ? _metaPath : HIDDEN_META_PATH;
        return string(abi.encodePacked(imgPath, tokenId.toString(), ".json"));
    }

    function mintGift(address to, uint number) external onlyOwner {
        require(to != address(0) && !to.isContract(), "SquirrelToken: wrong address");
        require((_tokenIds.current() + number) <= totalTokenCount(), "SquirrelToken: the limit of 10000 tokens is going to be exceeded");
        require(number <= maxNumberPerTx(), "SquirrelToken: the given number exceeds the allowed max per transaction");
        
        for (uint i = 0; i < number; i++) {
            _tokenIds.increment();
            uint newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }
    }

    function mint(address to, uint number) external payable {
        require(to != address(0) && !to.isContract(), "SquirrelToken: wrong address");
        require((_tokenIds.current() + number) <= totalTokenCount(), "SquirrelToken: the limit of 10000 tokens is going to be exceeded");
        require(number <= maxNumberPerTx(), "SquirrelToken: the given number exceeds the allowed max per transaction");
        require((mintedBy(_msgSender()) + number) <= totalMintLimitPerAddress(), "SquirrelToken: the limit of minting per address is going to be exceeded");
        require(msg.value >= number * mintingFee(), "SquirrelToken: incorrect amount sent to the contract");

        if (!_publicSaleStarted && !_presaleEligible[_msgSender()]) {
            revert("SquirrelToken: a public sale is not started");
        }
        
        for (uint i = 0; i < number; i++) {
            _tokenIds.increment();
            uint newTokenId = _tokenIds.current();
            _mint(to, newTokenId);
        }

        _mintings[_msgSender()] += number;
    }

    function withdrawEthers(uint amount, address payable to) public virtual onlyOwner {
        to.sendValue(amount);
        emit EthersWithdrawn(_msgSender(), to, amount);
    }
}