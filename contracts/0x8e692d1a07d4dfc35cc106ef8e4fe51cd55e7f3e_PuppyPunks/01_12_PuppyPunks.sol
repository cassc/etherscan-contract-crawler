// SPDX-License-Identifier: MIT


 
 /*

 /$$$$$$$  /$$   /$$ /$$$$$$$  /$$$$$$$  /$$     /$$       /$$$$$$$  /$$   /$$ /$$   /$$ /$$   /$$  /$$$$$$ 
| $$__  $$| $$  | $$| $$__  $$| $$__  $$|  $$   /$$/      | $$__  $$| $$  | $$| $$$ | $$| $$  /$$/ /$$__  $$
| $$  \ $$| $$  | $$| $$  \ $$| $$  \ $$ \  $$ /$$/       | $$  \ $$| $$  | $$| $$$$| $$| $$ /$$/ | $$  \__/
| $$$$$$$/| $$  | $$| $$$$$$$/| $$$$$$$/  \  $$$$/        | $$$$$$$/| $$  | $$| $$ $$ $$| $$$$$/  |  $$$$$$ 
| $$____/ | $$  | $$| $$____/ | $$____/    \  $$/         | $$____/ | $$  | $$| $$  $$$$| $$  $$   \____  $$
| $$      | $$  | $$| $$      | $$          | $$          | $$      | $$  | $$| $$\  $$$| $$\  $$  /$$  \ $$
| $$      |  $$$$$$/| $$      | $$          | $$          | $$      |  $$$$$$/| $$ \  $$| $$ \  $$|  $$$$$$/
|__/       \______/ |__/      |__/          |__/          |__/       \______/ |__/  \__/|__/  \__/ \______/ 

============================================== PUPPYPUNKS.CLUB ==============================================
*/                                                                                                         



pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title PuppyPunks
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */
                                                                                                     
                                                                                            

 
 
contract PuppyPunks is ERC721, Ownable {

    bool public saleIsActive = false;
    string private _baseURIextended;
    address payable public immutable shareholderAddress;

    string public PROVENANCE;

    uint256 public publicTokenPrice = 0.015 ether;
	uint public maxPerTx = 5;
	uint public maxFreeMintPerWallet = 15;
	uint public amountAvailableFreeMint = 1000;
	uint public maxSupply = 3000;
	
	mapping(address => uint) public addressFreeMinted;
	
	
	

    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;



    constructor(address payable shareholderAddress_) ERC721("Puppy Punks", "PUPPY") {
        require(shareholderAddress_ != address(0));
        shareholderAddress = shareholderAddress_;
    }

    function totalSupply() public view returns (uint256 supply) {
        return _tokenSupply.current();
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }

    function setProvenance(string memory provenance) public onlyOwner {
        PROVENANCE = provenance;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }

    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function isSaleActive() external view returns (bool) {
        return saleIsActive;
    }

    function updatePublicPrice(uint256 newPrice) public onlyOwner {
        publicTokenPrice = newPrice;
    }


    function mint(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale is inactive.");
        require(numberOfTokens <= maxPerTx, "You can only mint 5 at a time.");
        require(_tokenSupply.current() + numberOfTokens <= maxSupply, "Purchase would exceed max supply of tokens");
        
        if (_tokenSupply.current() + numberOfTokens > amountAvailableFreeMint) {
            require((publicTokenPrice * numberOfTokens) == msg.value, "Don't send over or under (in ETH).");
        } else {
			require(msg.value == 0, "Don't send ether for the free mint.");
			require(addressFreeMinted[msg.sender] < maxFreeMintPerWallet, "You can only adopt 15 free puppies per wallet. Wait for the paid adoption.");
		}
		
		addressFreeMinted[msg.sender] += numberOfTokens;
        for(uint i = 0; i < numberOfTokens; i++) {
		  uint256 _tokenId = _tokenSupply.current() + 1;
            _safeMint(msg.sender, _tokenId);
            _tokenSupply.increment();
        }
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(shareholderAddress, balance);
    }

}