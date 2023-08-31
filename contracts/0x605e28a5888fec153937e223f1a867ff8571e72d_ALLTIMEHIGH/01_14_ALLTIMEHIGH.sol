// SPDX-License-Identifier: MIT

/*
                                                                                                                                                              
                                                                                                                                       
                                                                                                                                       
                                                                                                                                       
            .:oxkOOOkxoc,.                                                                          .;ooooo:.                          
          ;k00NMMMMKl:OMW0l.                                              cOOOOo'      ;Oc .dx,    .,kMMMMMO.                          
         '0MWWWMNK0OdoKMMMWo                                              dMMMMWO'     cWKdkNN:     .:kOOOOo.                         
          lWMMM0;...,kWWWWWk.  ....... .';,. .             .;::,.      ..,kMMMMMXc''..'dWMMMMNo...   .,,,,,.        .,::;,'.           
        'lOWMMMNkc;'..,,,,,'. .oNXXXNOdONWNkdOOc.     .cxo'lXMMNOkko'  oNX0KWMMMWXo;xXNWMMMMMMNXNk..'dNNNXNx.   .cl,lNMMMWNKkl.        
        .xWWMMMWOoOXKOxo;..   .xMNNWMMMWWWMMMWMWk'   :0WMWKXWWWWMMMMNo.lXKkOWMMMWKdlxKXNMMN0KWNKXx..,xNWMMMO.  :0WWNNNK00NMNKNKc       
         .cOXWMM0d0WMMMMWNKo. .xWdc0MWO:',oXMWMMWk. :XMMMMWk:',dXWMXKXd..'kMMMMMK:.....oWMXdkXl... ..',xMMMO. cNMMMWO;. .,kKkXMNc      
            .:ldOKXWMMMMMMMM0,.dWX0NM0'    lWMMMMN:.kMMMMMO.    dWMKkKK,  dMMMMWk.     cWMMMMN:    .,lxKMMMO.'OMMMMMx.'ddd0WMMMMk.      
       .,;;;;,'. ..;ckNMMMMMK; 'OWMMMk.    :NMMMMN:.OMMWWWx.    lWMMMMN:  dMMMMWx.     cWMMMMN:    .,kMMMMMO.,KMMMMWKxONNNNNNNNN0,     
       ,0WWMMWNo.    'dxOWMMX: 'OWMMMK,    oWMMMMX;.xMWx,x0,   .xMMMMM0,  ;cxWMMX;     cWMMMMWl    .,kMMMMMk..OMMMMWx,'''''','''.      
        ,kWMMMMW0doox0d;xNMM0'.xMMMMWNOo:ckNMMMMMk. ,KWOoOW0l:ckXkldXNl   ckKWMMWKxd;  cNMMMMMXkdc..,kMMMMMk. :XMMMMKo,'';ol',od,       
         ;OWMMWWWWMMMMWWMMXx' .xMMMMNkOWMMMWXXWWO'   'kNMMMMNWMMXc.:x:    ;XMMMMMMMMd. '0MMMMMMMMO..,dKXWMMO.  ,kNMMMKoo0WMXdxOc.       
          .,lx0OkKWWNXKOdc'   .xMMMMM0lo0XNXd:o:.      ,ok0KxxNXKxl;.      ,dOKKKKK0l   'lokKKKK0d..':,,x00o.    ,ok0d.'kXKOd:.        
              ...''''..       .xMMMMM0'  .''..            .......             ......        .....                   .. ....            
                              .xMMXO0O'                                                                                               
                               cOk: 'c.                                                                                                
                                                                                                                                       
                                                                                                                                      
                                                                                                                                   
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract Parent {
    function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract ALLTIMEHIGH is ReentrancyGuard, ERC721Enumerable, Ownable {

    Parent private parent;
    string public PROVENANCE;
    bool public claimIsActive = false;
    bool public saleIsActive = false;
    string private baseURI;

    uint256 public constant SALE_SUPPLY = 1997;
    uint256 public constant MAX_PUBLIC_MINT = 10;
    uint256 public constant PRICE_PER_TOKEN = 0.05 ether;
    uint256 public immutable PARENT_SUPPLY;
    uint256 public immutable MAX_SUPPLY;

    uint256 internal numSales = 0;

    constructor(address parentAddress, uint _parentSupply) ERC721("ALL TIME HIGH", "ATH") {
        parent = Parent(parentAddress);
        PARENT_SUPPLY = _parentSupply;
        MAX_SUPPLY = _parentSupply + SALE_SUPPLY;
    }

    function setProvenanceHash(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function isMinted(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
  
    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    function setClaimState(bool newState) public onlyOwner {
        claimIsActive = newState;
    }

    function claimByTokenIds(uint256[] calldata tokenIds) public nonReentrant {
        require(claimIsActive, "Claim period is not active.");
        require(tokenIds.length > 0, "Must claim at least one token.");

        for (uint i = 0; i < tokenIds.length; i++) {
            require(parent.ownerOf(tokenIds[i]) == msg.sender, "Must own all parent tokens.");
            if (!_exists(tokenIds[i])) {
                _safeMint(msg.sender, tokenIds[i]);
            }
        }
    }

    function _mintSale(address to, uint i) internal {
        numSales++;
        _safeMint(to, PARENT_SUPPLY + i + 1); // manifold contracts are 1-indexed
    }

    function devMint(uint256 n) public onlyOwner {
      uint startingId = numSales;
      uint i;
      for (i = 0; i < n; i++) {
          _mintSale(msg.sender, startingId + i);
      }
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function mint(uint numberOfTokens) public payable nonReentrant {
        uint startingIndex = numSales;
        require(saleIsActive, "Sale must be active to mint tokens");
        require(numberOfTokens <= MAX_PUBLIC_MINT, "Exceeded max token purchase");
        require(startingIndex + numberOfTokens <= SALE_SUPPLY, "Purchase would exceed max tokens");
        require(PRICE_PER_TOKEN * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mintSale(msg.sender, startingIndex + i);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function totalSales() public view returns (uint) {
        return numSales;
    }
}