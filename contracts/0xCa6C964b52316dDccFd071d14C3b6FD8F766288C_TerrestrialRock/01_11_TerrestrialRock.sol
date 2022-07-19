//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface RandomNumberContractInterface {
    function randomResult() external returns(uint256);
    function getRandomNumber() external returns(bytes32 requestId);
}

contract TerrestrialRock is ERC721, Ownable{

    using Strings for uint256;

    bool public permitBurd;
    bool public permitMint;
    uint8 public royaltyFeesInPercentage;
    uint32 public maxTokenMint;
    uint32 public maxTokenForUser;
    uint32 public idForToken;
    address internal royaltyAddress;
    uint public priceBuyToken;
    string public baseURI;
    
    RandomNumberContractInterface public randomContract;
    uint256[3] public randomResults;

//Event
    event MINT(address user, uint tokenID);
    event BURN(address user, uint tokenID);

//Modifier

modifier checkBurn() {
    require( permitBurd == true, "Burn Function are inactive" );
    _;
}

modifier checkMint() {
    require( permitMint == true, "Mint Function are inactive" );
    _;
}

//Constructor
    constructor(string memory _baseURI, address _royaltyAddress) ERC721("Terrestrial Rock", "TSL"){

        royaltyAddress = _royaltyAddress;
        priceBuyToken = 0.5 ether;
        maxTokenMint = 3333;
        maxTokenForUser = 10;
        royaltyFeesInPercentage = 10;
        baseURI = _baseURI;
        permitBurd = false;
        permitMint = false;

        for( uint i = 0; i < 99; i++){

            idForToken++;
            _mint(_royaltyAddress,idForToken);
            emit MINT(_royaltyAddress, idForToken);
        }
    }

//Override Functions

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        string memory _baseURI = baseURI;
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString(), ".json")) : "";
    }

//Public and External

    function mint(uint _amountForMint) public payable checkMint() {

        require(_amountForMint > 0, "Need to mint at least one token");
        require((idForToken + _amountForMint) <= maxTokenMint, "No can mint more token");
        require((balanceOf(msg.sender) + _amountForMint) <= maxTokenForUser, "As a user reached the maximum token");
        
        uint priceBuy = priceBuyToken * _amountForMint;
        require(msg.value >= priceBuy, "No enaugh money for buy");

        for( uint i = 0; i < _amountForMint; i++){

            idForToken++;
            _mint(msg.sender,idForToken);
            emit MINT(msg.sender, idForToken);
        }

        if(msg.value > priceBuy){

            uint surplusToReturn = msg.value - priceBuy;
            (bool success,) = msg.sender.call{ value: surplusToReturn }("");
            require(success, "refund failed");
        }
    }

    function burn(uint256 tokenId) public virtual checkBurn() {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
        emit BURN(msg.sender, tokenId);
    }

    function royaltyInfo(uint256 _salePrice) external view virtual returns (address, uint256){
        
        return (royaltyAddress, calculateRoyalty(_salePrice));
    }

//Only Owner

    function setRoyaltyFeesInPercentage(uint8 _royaltyFeesInPercentage) public onlyOwner {
        require(_royaltyFeesInPercentage > 0 && _royaltyFeesInPercentage < 100, "Invalid percentage");
        royaltyFeesInPercentage = _royaltyFeesInPercentage;
    }

    function setRoyaltyAddress(address _royaltyAddress) public onlyOwner {
        require( _royaltyAddress != address(0), "Invalid Address");
        royaltyAddress = _royaltyAddress;
    }

    function setBaseUri(string memory _newBaseUri) public onlyOwner {
        baseURI = _newBaseUri;
    }

    function setPriceBuyToken(uint _priceBuyToken) public onlyOwner {
        require(_priceBuyToken > 0, "Shoul set a value more big than 0");
        priceBuyToken = _priceBuyToken;
    }

    function setPermitBurd(bool _permitBurd) public onlyOwner{
        permitBurd = _permitBurd;
    }

    function setPermitMint(bool _permitMint) public onlyOwner{
        permitMint = _permitMint;
    }

    function setMaxTokenForUser(uint32 _maxTokenForUser) public onlyOwner {
        require(_maxTokenForUser > 0, "Shoul set a value more big than 0");
        maxTokenForUser = _maxTokenForUser;
    }

    function setMaxTokenMint(uint32 _maxTokenMint) public onlyOwner {
        require(_maxTokenMint > 0, "Shoul set a value more big than 0");
        maxTokenMint = _maxTokenMint;
    }

    function withdrawMoney() public onlyOwner {
        
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function getRandomNumberOne() public onlyOwner {
        randomContract.getRandomNumber();
        randomResults[0] = randomContract.randomResult();
    }

    function getRandomNumberTwo() public onlyOwner {
        randomContract.getRandomNumber();
        randomResults[1] = randomContract.randomResult();
    }
    function getRandomNumberThree() public onlyOwner {
        randomContract.getRandomNumber();
        randomResults[2] = randomContract.randomResult();
    }

    function getRandomResults() public view returns(uint256[] memory) {
        uint256[] memory _results = new uint256[](3);
        for(uint i = 0;i<3;i++)
            _results[i] = randomResults[i];
        return _results;
    }

    function setRandomContract(address addr) public onlyOwner {
        randomContract = RandomNumberContractInterface(addr);
    }

//Internal

    function calculateRoyalty(uint256 _salePrice) internal view returns (uint256){
        return (_salePrice * royaltyFeesInPercentage) / 100;
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
}