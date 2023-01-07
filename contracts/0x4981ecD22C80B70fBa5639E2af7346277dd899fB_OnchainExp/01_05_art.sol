// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract dataPicture {
    function tokenData(uint256 tokenId) virtual public view  returns (string memory);
}

interface passInterface {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

contract OnchainExp is ERC721A, Ownable {
    string private _baseURIPrefix;
    uint256 private _tokenPrice = 70000000000000000; //0.07 ETH
    uint256 private _curLimit = 200;
    uint256 private _perWallet = 20;
    bool private _isPublicSaleActive = false;
    bool private _isPublicClaimActive = false;
    address private _passContract;

    mapping(address => uint) public claimed;
    mapping(uint => address) public collections;
    mapping(uint => bool) public freeClaimed;

  
    constructor() ERC721A("OnChain Artworks", "ONEXP") {}

    function setBaseURI(string memory baseURIPrefix) public onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function setPrice(uint256 price) public onlyOwner {
        _tokenPrice = price;
    }
    
    function setPerWallet(uint256 amount) public onlyOwner {
        _perWallet = amount;
    }
   
    function setLimit(uint256 amount) public onlyOwner {
        _curLimit = amount;
    }
  
    function setPassContract(address add) public onlyOwner {
        uint256 i;

        if (_passContract != address(0))
            for(i=0;i<1000;i++)
                freeClaimed[i] = false;
        
        _passContract = add;

    }

    function setCollection(uint256 numFrom, uint256 numTo, address add) public onlyOwner {
        require(numFrom < numTo, "Wrong interval");
        require(numTo - numFrom <= 1000, "Wrong interval");
        uint256 partNum;

        for(partNum=numFrom/10;partNum<numTo/10;partNum++)
            collections[partNum] = add;
    }

    function flipPublicSaleState() public onlyOwner {
        _isPublicSaleActive = !_isPublicSaleActive;
    }

    function flipPublicClaimState() public onlyOwner {
        _isPublicClaimActive = !_isPublicClaimActive;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory output;
        uint256 partNum;
        partNum = tokenId / 10;
        if (collections[partNum] == address(0)) 
            return '';

        dataPicture contr;

        contr = dataPicture(collections[partNum]);

        output = contr.tokenData(tokenId);

        return output;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function buyTokens(uint amount) public payable {
        require(amount > 0, "Wrong amount");
        require(_isPublicSaleActive, "Later");
        require(totalSupply() + amount < _curLimit, "Sale finished");
        require(_tokenPrice * amount <= msg.value, "Need more ETH");
       require(claimed[msg.sender] + amount <= _perWallet, "Tokens done");

        _safeMint(msg.sender, amount);
        claimed[msg.sender] += amount;
    }

    function claim(uint256 tokenId) public {
        require(_isPublicClaimActive, "Later");
        require(totalSupply() + 1 < _curLimit, "Sale finished");
        require(freeClaimed[tokenId] == false, "Done");
        require(_passContract != address(0));
        passInterface passContract = passInterface(_passContract);
        require(passContract.ownerOf(tokenId) == msg.sender, "No pass");

        _safeMint(msg.sender, 1);
        freeClaimed[tokenId] = true;
    }

    function directMint(address _address, uint256 amount) public onlyOwner {
        require(totalSupply() + amount < _curLimit, "Sale finished");

        _safeMint(_address, amount);
    }
}