// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
/*


______  ___  ___  ____ _          _   _           _                               
|  _  \|_  | |  \/  (_) |        | \ | |         | |                              
| | | |  | | | .  . |_| | _____  |  \| | __ _ ___| |_ _   _                       
| | | |  | | | |\/| | | |/ / _ \ | . ` |/ _` / __| __| | | |                      
| |/ /\__/ / | |  | | |   <  __/ | |\  | (_| \__ \ |_| |_| |                      
|___/\____/  \_|  |_/_|_|\_\___| \_| \_/\__,_|___/\__|\__, |                      
                                                       __/ |                      
                                                      |___/                       
                                                                                  
                                                                                  
__  __                                                                            
\ \/ /                                                                            
 >  <                                                                             
/_/\_\                                                                            
                                                                                  
                                                                                  
______ _         _____                                                            
| ___ (_)       |_   _|                                                           
| |_/ /_  __ _    | |_ __ __ ___   __                                             
| ___ \ |/ _` |   | | '__/ _` \ \ / /                                             
| |_/ / | (_| |   | | | | (_| |\ V /                                              
\____/|_|\__, |   \_/_|  \__,_| \_/                                               
          __/ |                                                                   
         |___/                                                                    
__   __                                                                           
\ \ / /                                                                           
 \ V /                                                                            
 /   \                                                                            
/ /^\ \                                                                           
\/   \/                                                                           
                                                                                  
                                                                                  
 _____ _            _               _     _____ _            ______       _       
|_   _| |          | |             | |   |  __ (_)           | ___ \     | |      
  | | | |__   ___  | |     __ _ ___| |_  | |  \/_  __ _  __ _| |_/ /_   _| |_ ___ 
  | | | '_ \ / _ \ | |    / _` / __| __| | | __| |/ _` |/ _` | ___ \ | | | __/ _ \
  | | | | | |  __/ | |___| (_| \__ \ |_  | |_\ \ | (_| | (_| | |_/ / |_| | ||  __/
  \_/ |_| |_|\___| \_____/\__,_|___/\__|  \____/_|\__, |\__,_\____/ \__, |\__\___|
                                                   __/ |             __/ |        
                                                  |___/             |___/                                     
                                                                                                                                                                     
 */

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NstyPass is ERC721, PaymentSplitter, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private supply;
    uint256 public cost = 0.18 ether;
    uint256 public maxSupply = 160;
    uint256 public maxMintAmountPerTx = 3;
    bool public paused = true;
    string public uriPrefix;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address[] memory payees,
        uint256[] memory shares
    ) ERC721(name, symbol) PaymentSplitter(payees, shares) {
        uriPrefix = baseURI;
    }

    modifier mintCompliance(uint256 _mintAmount) {
        require(
            _mintAmount > 0 && _mintAmount <= maxMintAmountPerTx,
            "Invalid mint amount!"
        );
        require(
            supply.current() + _mintAmount <= maxSupply,
            "Max supply exceeded!"
        );
        require(!paused, "The contract is paused!");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return supply.current();
    }

    function mint(uint256 _mintAmount)
        public
        payable
        mintCompliance(_mintAmount)
    {
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        _mintLoop(msg.sender, _mintAmount);
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function _mintLoop(address _receiver, uint256 _mintAmount) internal {
        for (uint256 i = 0; i < _mintAmount; i++) {
            supply.increment();
            _safeMint(_receiver, supply.current());
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}