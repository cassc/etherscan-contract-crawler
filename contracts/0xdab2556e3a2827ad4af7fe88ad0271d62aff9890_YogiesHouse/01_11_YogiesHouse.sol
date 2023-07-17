// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IYogiesStaking {
    function getCapacityNeeded(address user) external view returns (uint256) {}
}

contract YogiesHouse is ERC721A, Ownable {
    using Strings for uint256;

    // ERC 721
    address public openseaProxyRegistryAddress;
    string public baseURIString = "https://storage.googleapis.com/yogies-assets/metadata/items/house/";

    IYogiesStaking public staking;

    mapping(address => bool) public yogiesOperator;

    modifier onlyOperator() {
        require(yogiesOperator[msg.sender] || msg.sender == owner(), "Sender not operator");
        _;
    }

    constructor(
        address _openseaProxyRegistryAddress,
        address _staking
    ) ERC721A("Yogies Mansion", "Yogies Mansion") Ownable() {
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
        staking = IYogiesStaking(_staking);
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from != address(0)) {
            uint256 balance = balanceOf(from);
            uint256 capacityNeeded = staking.getCapacityNeeded(from);
            require(balance - 1 >= capacityNeeded, "Cannot transfer house when yogies are in it");
        }       
    }

    function mint(address recipient, uint256 amount) external onlyOperator {
        _safeMint(recipient, amount);
    }

    function burn(uint256 tokenId) external onlyOperator {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString(), ".json"));     
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
    }

    function setYogiesOperator(address _operator, bool isOperator)
        external
        onlyOwner {
            yogiesOperator[_operator] = isOperator;
        }

    function setStaking(address _Staking) external onlyOwner {
        staking = IYogiesStaking(_Staking);
    }
    
    receive() external payable {}
}