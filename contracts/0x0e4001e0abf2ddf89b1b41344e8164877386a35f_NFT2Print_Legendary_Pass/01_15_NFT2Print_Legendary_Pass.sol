// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFT2Print_Legendary_Pass is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    Ownable
{

    struct TokenInfo{
        IERC20 paytoken;
        uint256 costvalue;

    }

    mapping (uint256 => TokenInfo) public AllowedCrypto;


    using Strings for uint256;
    string baseURI;
    string public baseExtension = ".json";
    uint256 public maxSupply = 2500;
    uint256 public mintPriceETH = 0.125 ether;
    bool public saleActive;
    uint256 public legendaryReserve = 400; // Reserve  max 400 legendary passes
    uint256 public maxMintPerPurchase = 10;
    
    constructor(string memory _initBaseURI)
        ERC721("NFT2Print_Legendary_Pass", "$N2PRINT")
    {
        setBaseURI(_initBaseURI);
    }


    function addMintCurrency (
        uint256 _pid,
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        
            TokenInfo storage token = AllowedCrypto[_pid];
                token.paytoken = _paytoken;
                token.costvalue = _costvalue;
       
    }
    

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    
    // public
    function mintLegendaryPass(uint256 _amount) public payable {
        require(totalSupply() + _amount <= maxSupply, "Can not mint more than max supply.");
        require(saleActive, "Sale is disabled");
        require(msg.value >= mintPriceETH * _amount, "Ether value sent is not correct");
        require(_amount > 0 && _amount <= maxMintPerPurchase, "Can only mint 10 passes at a time");

                uint256 supply = totalSupply();
        
        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(msg.sender, supply + i);
        }
       
    }

    
    function mintPassERC20(uint256 _amount, uint256 _pid) public {
        
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;

        uint256 mintPrice;
        uint256 supply = totalSupply();
        
        mintPrice = tokens.costvalue;
        
        
        require(supply + _amount <= maxSupply, "Can not mint more than max supply.");
        require(saleActive, "Sale is disabled");
        require(_amount > 0 && _amount <= maxMintPerPurchase, "Can only rmint 10 passes at a time");
                        
        
        for (uint256 i = 0; i < _amount; i++) {
            require(paytoken.transferFrom(msg.sender, address(this), mintPrice));
            _safeMint(msg.sender, supply + i);
        }
        
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent pass"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function getERC20_mintPrice(uint256 _pid) public view virtual returns(uint256) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            uint256 cost;
            cost = tokens.costvalue;
            return cost;
        }

    function getERC20_tokenAddress(uint256 _pid) public view virtual returns(IERC20) {
            TokenInfo storage tokens = AllowedCrypto[_pid];
            IERC20 paytoken;
            paytoken = tokens.paytoken;
            return paytoken;
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


    //only owner
    function reservePass(address _to, uint256 _amount) public onlyOwner {
        uint256 supply = totalSupply();
        require(_amount > 0 && _amount <= legendaryReserve, "Not enough reserve left");
        require(supply + _amount <= maxSupply, "Can not mint more than max supply.");

        for (uint256 i = 0; i < _amount; i++) {
            _safeMint(_to, supply + i);
        }
        legendaryReserve = legendaryReserve - _amount;
    }

    function toggleSaleActive() public onlyOwner {
        saleActive = !saleActive;
    }

    function withdrawERC20(uint256 _pid) external onlyOwner {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }

     function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension)
        public
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }


    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
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