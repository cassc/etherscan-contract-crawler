pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract golferz is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string public baseTokenURI = "https://storage.googleapis.com/golferz-nft/json/";
    uint public TOTAL_SUPPLY = 5555;
    uint public WHITELIST_PRICE = 0.05 ether;
    uint public PRICE = 0.075 ether;
    bool public isPaused = true;
    bool public isWhitelistMint = true;
    uint public MAX_PER_MINT = 10;
    mapping(address => uint) public whitelist;

    constructor() ERC721("Golferz", "GOLFERZ") {
    }

    function reserveNFTs() public onlyOwner {
         uint totalMinted = _tokenIds.current();

         require(totalMinted.add(100) < TOTAL_SUPPLY, "Not enough NFTs left to mint");

         for (uint i = 0; i < 100; i++) {
            _mintSingleNFT();
         }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI (string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setPaused(bool newPaused) public onlyOwner {
        isPaused = newPaused;
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        PRICE = newPrice;
    }

    function setWhitelistPrice(uint256 newPrice) public onlyOwner {
        WHITELIST_PRICE = newPrice;
    }

    function setMaxPerMint(uint newMax) public onlyOwner {
        MAX_PER_MINT = newMax;
    }

    function setWhitelistMint(bool newWhitelistMint) public onlyOwner {
        isWhitelistMint = newWhitelistMint;
    }

    function setWhiteListVal(address _user, uint256 _val) public onlyOwner{
        whitelist[_user] = _val;
    }

    function setWhiteListVals(address[] memory _addresses, uint256 _amount) public onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            setWhiteListVal(_addresses[i], _amount);
        }
    }

    function mintNFTs(uint _count) public payable {
        require(!isPaused, "Cannot mint at this time");
        uint totalMinted = _tokenIds.current();
        require(totalMinted.add(_count) <= TOTAL_SUPPLY, "Not enough NFTs left!");

        if(isWhitelistMint)
        {
            require(whitelist[msg.sender] >= _count, "Can't mint that many NFTs, chief!");
            require(msg.value >= _count.mul(WHITELIST_PRICE), "Not enough cash, dawg!");
            whitelist[msg.sender] = whitelist[msg.sender].sub(_count);
        } else {
            require(_count > 0 && _count <= MAX_PER_MINT, "Can't mint that many NFTs, chief!");
            require(msg.value >= PRICE.mul(_count), "Not enough cash, dawg!");
        }
        

        for(uint i = 0; i < _count; i++) {
            _mintSingleNFT();
        }
    }

    function _mintSingleNFT() private {
        uint newTokenID = _tokenIds.current();
        _safeMint(msg.sender, newTokenID);
        _tokenIds.increment();
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint[] memory) {
            uint tokenCount = balanceOf(_owner);
            uint[] memory tokensId = new uint256[] (tokenCount);

            for(uint i = 0; i < tokenCount; i++)
            {
                tokensId[i] = tokenOfOwnerByIndex(_owner, i);
            }
            return tokensId;
        }
    
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}