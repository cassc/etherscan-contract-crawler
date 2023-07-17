// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/*       
   ,,                                        
     db        db      `7MMM.     ,MMF'        
              ;MM:       MMMb    dPMM          
   `7MM      ,V^MM.      M YM   ,M MM   ,pP"Ybd 
     MM     ,M  `MM      M  Mb  M' MM   8I   `" 
     MM     AbmmmqMA     M  YM.P'  MM   `YMMMa. 
     MM    A'     VML    M  `YM'   MM   L.   I8 
   .JMML..AMA.   .AMMA..JML. `'  .JMML..M9mmmP'  
                                                 by Bobe.eth
*/

                                          
contract iAMs is ERC721A, Ownable {

    uint256 public constant MAX_SUPPLY = 500;
    string public _baseTokenURI;

    constructor() ERC721A("iAMs", "IAM") {}

    //ENUMERATION - IDs set to start from 1
    function _startTokenId() internal pure override(ERC721A) returns(uint256 startId) {
        return 1;
    }

    //MINT - Provide quantity of tokens to mint
    function mint(uint256 quantity) external payable onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");
        _safeMint(msg.sender, quantity);
    }

    //AIRDROP MINT - Provide array of addresses to mint to ["0x..","0x..."]
    function bulkMintAndDrop(address[] calldata _to) external payable onlyOwner {
        require(totalSupply() + _to.length <= MAX_SUPPLY, "Not enough tokens left");
        for(uint i = 0; i < _to.length; i++){
            _safeMint(_to[i], 1);
        }
    }

    //METADATA - View base TokenURI 
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    //METADATA - Set base TokenURI
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    //WITHDRAW - Funds withdrawal
    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

//dev: 5hady.eth