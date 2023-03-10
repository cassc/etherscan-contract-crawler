//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YureiPhurba is ERC721A, ERC2981, Ownable {
    //events

    using Strings for uint256;
    //var
    uint256 MAX_SUPPLY = 1111;
    bool public paused = false;
    string public URIOdd;
    string public URIEven;
    string public uriSuffix = ".json";
    bool public REVEAL = false;
    mapping(address => uint256) public Claimable;

    constructor(string memory _URIOdd,string memory initialURI,address _RoyaltyReceiver, uint96 _royaltyAmount)  ERC721A("Yurei Key", "YUKEY")  {
        URIEven = initialURI;
        URIOdd = _URIOdd;
        setRoyaltyInfo(_RoyaltyReceiver,_royaltyAmount);
    }

    
    function _checkEven(uint _TokenNumber) internal view returns (bool){
        uint remainder = _TokenNumber%2;
        if(remainder==0)
            return true;
        else
            return false;
    }
   
    modifier IsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }

    //Metadata

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return URIEven;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        if (_checkEven(tokenId)) {
            return URIEven;
        }
        return URIOdd;
    }

    /*function toggleReveal(string memory updatedURI) public onlyOwner {
        REVEAL = !REVEAL;
        URI = updatedURI;
    }*/

    function setBaseURI(string memory _newBaseURI, string memory _newBaseURIOdd) public onlyOwner {
        URIEven = _newBaseURI;
        URIOdd = _newBaseURIOdd;
    }

    //General


    function DestroyKey(uint256 tokenId) public {
        _burn(tokenId, true);
    } 

    function setPause(bool ispaused) public onlyOwner {
        paused = ispaused;
    }

    function whitelisAddress(
        address[] calldata _users,
        uint256[] calldata _amount
    ) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            Claimable[_users[i]] = _amount[i];
        }
    }

    //Claiming Airdrop


    function ClaimKey() public IsUser {
        uint256 supply = totalSupply();
        uint256 _mintAmount = Claimable[msg.sender];
        require(!paused, "the contract is paused");
        require(supply + _mintAmount <= MAX_SUPPLY, "max supply reached");
        require(Claimable[msg.sender] > 0, "no claim available");
        //require(Whitelisted[msg.sender] >= _mintAmount, "Amount is higher than available claim");
        
        _safeMint(msg.sender, _mintAmount);
        Claimable[msg.sender] = Claimable[msg.sender] - _mintAmount;

    }





    //owner mint
    function OwnerMint(address to, uint256 amount) public onlyOwner {
        _safeMint(to, amount);
    }


    //royalty 100 is 1%
    
     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
         return super.supportsInterface(interfaceId);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyAmount) public onlyOwner {
        _setDefaultRoyalty(_receiver,_royaltyAmount);
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}