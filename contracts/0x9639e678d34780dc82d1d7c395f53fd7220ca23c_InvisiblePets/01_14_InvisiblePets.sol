//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*

.___            .__       ._____.   .__           __________        __          
|   | _______  _|__| _____|__\_ |__ |  |   ____   \______   \ _____/  |_  ______
|   |/    \  \/ /  |/  ___/  || __ \|  | _/ __ \   |     ___// __ \   __\/  ___/
|   |   |  \   /|  |\___ \|  || \_\ \  |_\  ___/   |    |   \  ___/|  |  \___ \ 
|___|___|  /\_/ |__/____  >__||___  /____/\___  >  |____|    \___  >__| /____  >
         \/             \/        \/          \/                 \/          \/ 

*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC721A.sol";

contract InvisiblePets is ERC721A, Ownable, Pausable {
    using SafeMath for uint256;

    uint public MAX_SUPPLY = 5000;
    uint public PRICE = 0.055 ether;
    string public BASE_URI = "ipfs://QmNZCfuYdRwchx1ng9sBP1DNYHXtUh8zzWBZod2yemVeFr/";

    uint public RESERVE_SUPPLY = 100;
    
    constructor() ERC721A("InvisiblePets", "PETS") {
        reserve(RESERVE_SUPPLY);
        _pause();
    }

    function updateBaseUri(string memory baseUri) public onlyOwner {
        BASE_URI = baseUri;
    }
    
    function update(uint maxSupply, uint price, string memory baseUri) public onlyOwner {
        MAX_SUPPLY = maxSupply;
        PRICE = price;
        BASE_URI = baseUri;
    }

    function reserve(uint256 quantity) public onlyOwner {
        secureMint(quantity);
    }

    function mint(uint256 quantity) external payable whenNotPaused {
        require(PRICE * quantity <= msg.value, "Insufficient funds sent");
        secureMint(quantity);
    }

    function secureMint(uint256 quantity) internal {
        require(quantity > 0, "Quantity cannot be zero");
        require(totalSupply().add(quantity) < MAX_SUPPLY, "No items left to mint");
        _safeMint(msg.sender, quantity);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
}