// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

contract FigmentCountryClub is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public constant maxSupply = 4000; //total NFTs available
    address public royaltyAddress = 0x147398f2CcBB480179A8da8aF95C95C1ac2fBD58; //need to update before deploying
    uint96 public royaltyFee = 1000; //10% royalty
    string public _baseTokenURI = "ipfs://QmP5Yo6Bv7LsJAPbJZYX1MJifY3p18yUekKZgGe1vcevha/"; //FIGMENT IPFS link
    string public _baseTokenEXT = ".json"; 
   
    constructor() ERC721A("Figment Country Club", "FIGMENT") {
         _setDefaultRoyalty(royaltyAddress, royaltyFee); 
    }
    
    /**
     * @notice Mint tokens - owner only 
     */
    function mint(uint256 _mintAmount) external onlyOwner() {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply , "Exceeds max supply");
        _safeMint(msg.sender, _mintAmount);
    }
     
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    /**
     * @notice Obtains metadata url for token
     */
   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
            string memory currentBaseURI = _baseURI();
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, tokenId.toString(),_baseTokenEXT)) : "";
        
    }
    /**
     * @notice Updates the metadata url
     */
    function changeURLParams(string memory _nURL, string memory _nBaseExt) external onlyOwner {
        _baseTokenURI = _nURL;
        _baseTokenEXT = _nBaseExt;
        emit baseTokenURI (_nURL, _nBaseExt);
    }

    /**
     * @notice Mint tokens via airdrop by owner only
     */
    function gift(address _to, uint256 _mintAmount) external onlyOwner {
        uint256 supply = totalSupply();
        require(supply + _mintAmount <= maxSupply, "Exceeds Max Supply");
        _safeMint(_to, _mintAmount);
    }

    /**
     * @notice Change the royalty fee for the collection - denominator out of 10000
     */
    function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
        royaltyFee = _feeNumerator;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        emit RoyaltyFees(royaltyAddress, royaltyFee);
    }

    /**
     * @notice Change the royalty address where royalty payouts are sent
     */
    function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
        royaltyAddress = _royaltyAddress;
        _setDefaultRoyalty(royaltyAddress, royaltyFee);
        emit RoyaltyFees(royaltyAddress, royaltyFee);
    }
    /**
     * @notice Withdraw any funds
     */
    function withdrawFunds() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Event listeners
     */
    event RoyaltyFees(address, uint96);
    event baseTokenURI (string, string);
    event Received (address, uint256);
    
     /**
     * @notice Allow external funds
     */
    receive() external payable {
        emit Received(msg.sender,msg.value);
        }
    


}