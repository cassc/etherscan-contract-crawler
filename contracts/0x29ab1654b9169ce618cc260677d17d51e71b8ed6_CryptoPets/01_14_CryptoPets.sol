//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoPets is ERC721, Ownable, ERC721Enumerable {
    using SafeMath for uint256;

    string tokenBaseURI;
    uint public maxTokens;
    bool public saleIsActive = false;
    bool publicSaleOpen = false;
    uint public tokenReserve;

    mapping(address => uint8) public approvedAddresses;
    mapping(address => uint8) public mintedTokens;

    constructor(
        uint _maxTokens, 
        uint _tokenReserve, 
        string memory _tokenURI,
        string memory _name,
        string memory _tokenName
    ) ERC721(_name, _tokenName) {
        maxTokens = _maxTokens;
        tokenReserve = _tokenReserve;
        tokenBaseURI = _tokenURI;
    }

    function withdraw() public onlyOwner {
        address _owner = owner();
        payable(_owner).transfer(address(this).balance);
    }    

    function reserve(address _to, uint256 _reserveAmount)
        public
        onlyOwner
    {
        uint256 supply = totalSupply();
        require(
            _reserveAmount > 0 && _reserveAmount <= tokenReserve,
            "Not enough reserve left for team"
        );
        
        for (uint256 i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i);
        }

        tokenReserve = tokenReserve.sub(_reserveAmount);
    }    

    function approveAddress(address _addr, uint8 _amount) public onlyOwner {
        approvedAddresses[_addr] = _amount;
    }

    function approveAddresses(address[] memory _addrs, uint8[] memory _amounts) public onlyOwner{
        require(_addrs.length == _amounts.length, "lengths of addresses and amounts should be equal");

        for ( uint i = 0; i < _addrs.length; i++ ) {
            approvedAddresses[_addrs[i]] = _amounts[i];
        }
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        tokenBaseURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }    

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function flipPublicSaleState() public onlyOwner {
        publicSaleOpen = !publicSaleOpen;
    }

    function approvedTokensOf(address _owner) public view returns (uint) {
        uint approvedTokens = approvedAddresses[_owner];
        uint addressBalance = mintedTokens[_owner];
        uint availableTokens = 0;
        if (approvedTokens >= addressBalance) {
            availableTokens = approvedTokens - addressBalance;
        }

        return availableTokens;
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }  

    function mintNft(uint8 numberOfTokens) public {
        require(saleIsActive, "Sale must be active to mint token");
        require(
            numberOfTokens > 0,
            "You should provide positive tokens number"
        );
        require(
            totalSupply().add(numberOfTokens) <= maxTokens,
            "Purchase would exceed max supply of tokens"
        );

        if (!publicSaleOpen) {
            require(
                approvedTokensOf(msg.sender) >= numberOfTokens,
                "Your address don't have enough approved tokens"
            );        
        } else {
            numberOfTokens = 1;
        }

        // Increase minted tokens
        mintedTokens[msg.sender] += numberOfTokens;        

        // Mint tokens one-by-one
        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < maxTokens) {
                _safeMint(msg.sender, mintIndex);
            }
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }    

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }                           
}