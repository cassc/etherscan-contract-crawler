// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract SoldiersOftheMetaverse is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;
    
    // Set variables
    
    uint256 public constant SOTM_SUPPLY = 7500;
    uint256 public constant SOTM_PRICE = 75000000000000000 wei;
    bool private _saleActive = false;
    bool private _presaleActive = false;
    uint256 public constant presale_supply = 1000;
    
    address team1 =     0x3479Bb56816B2822B208F7175EF0D33990025c89;
    address team2 =     0xcf2572c15EaF52925dEF103B78F80960024ca878;
    address team3 =     0xF1976b10eC89003786C5A692B09e4546fdd972Cc;
    address team4 =     0x11Df0d56200201F273bbCcF5627A66c254bCF086;
    address team5 =     0xE15da470B6cc8F18B347e0dD83c3830d1fA0c376;
    address team6 =     0x70fB8203B83a27A0f8767AE2F171a74A8417D32C;
    address dev =       0x0ECbE30790B6a690D4088B70dCC27664ca530D55;
    address design=     0x0313B09E8Ee8A0932dBEb76c4D7c46055969C7C4;
    address payrol =    0x7A8F1Ef6Fb05E0471Ce21243883E6544C78CA56F;
    address marketing = 0xd92f5A592F2c9a42c73e7CBaa63580a7B4C758c2;
    address influencer = 0x87bAe07d064f83c417D24f1F994eb2D797FAf00A;

    string private _metaBaseUri = "";
    
    // Public Functions
    
    constructor() ERC721("Soldiers Of The Metaverse", "SOTM") {}
    
    function mint(uint16 numberOfTokens) public payable {
        require(isSaleActive(), "SOTM sale not active");
        require(totalSupply().add(numberOfTokens) <= SOTM_SUPPLY, "Sold Out");
        require(SOTM_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        require(numberOfTokens<=20, "Max 20 are allowed" );

        _mintTokens(numberOfTokens);
    }
    
     function premint(uint16 numberOfTokens) public payable {
        require(ispreSaleActive(), "Presale Of SOTM is not active");
        require(totalSupply().add(numberOfTokens) <= presale_supply, "Insufficient supply, Try in public sale");
        require(SOTM_PRICE.mul(numberOfTokens) <= msg.value, "Ether amount sent is incorrect");
        require(numberOfTokens<=10, "Max 10 are allowed" );
        _mintTokens(numberOfTokens);
    }
    
    function isSaleActive() public view returns (bool) {
        return _saleActive;
    }
    
    function ispreSaleActive() public view returns (bool) {
        return _presaleActive;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "", uint256(tokenId).toString()));
    }
    
    // Owner Functions

    function setSaleActive(bool active) external onlyOwner {
        _saleActive = active;
    }
    
    function setpreSaleActive(bool active) external onlyOwner {
        _presaleActive = active;
    }

    function setMetaBaseURI(string memory baseURI) external onlyOwner {
        _metaBaseUri = baseURI;
    }


    function withdrawAll() external onlyOwner {
        uint256 _9percent = address(this).balance*9/100;
        uint256 _7percent = address(this).balance*7/100;
        uint256 _14percent =address(this).balance*14/100;
        uint256 _8percent = address(this).balance*8/100;
        uint256 _15percent = address(this).balance*15/100;
        uint256 _2percent = address(this).balance*2/100;
        require(payable(team1).send(_9percent));
        require(payable(team2).send(_9percent));
        require(payable(team3).send(_9percent));
        require(payable(team4).send(_9percent));
        require(payable(team5).send(_9percent));
        require(payable(team6).send(_9percent));
        require(payable(dev).send(_7percent));
        require(payable(design).send(_8percent));
        require(payable(payrol).send(_14percent));
        require(payable(marketing).send(_15percent));
        require(payable(influencer).send(_2percent));
    }

    // Internal Functions
    
    function _mintTokens(uint16 numberOfTokens) internal {
        for (uint16 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = totalSupply();
            _safeMint(msg.sender, tokenId);
        }
    }

    function _baseURI() override internal view returns (string memory) {
        return _metaBaseUri;
    }
    

    // The following functions are overrides required by Solidity.

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