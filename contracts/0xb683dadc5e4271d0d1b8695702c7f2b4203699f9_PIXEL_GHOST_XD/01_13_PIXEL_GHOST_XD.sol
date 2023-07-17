// SPDX-License-Identifier: MIT
/*

 ███████████  █████ █████ █████ ██████████ █████            █████████  █████   █████    ███████     █████████  ███████████
░░███░░░░░███░░███ ░░███ ░░███ ░░███░░░░░█░░███            ███░░░░░███░░███   ░░███   ███░░░░░███  ███░░░░░███░█░░░███░░░█
 ░███    ░███ ░███  ░░███ ███   ░███  █ ░  ░███           ███     ░░░  ░███    ░███  ███     ░░███░███    ░░░ ░   ░███  ░ 
 ░██████████  ░███   ░░█████    ░██████    ░███          ░███          ░███████████ ░███      ░███░░█████████     ░███    
 ░███░░░░░░   ░███    ███░███   ░███░░█    ░███          ░███    █████ ░███░░░░░███ ░███      ░███ ░░░░░░░░███    ░███    
 ░███         ░███   ███ ░░███  ░███ ░   █ ░███      █   ░░███  ░░███  ░███    ░███ ░░███     ███  ███    ░███    ░███    
 █████        █████ █████ █████ ██████████ ███████████    ░░█████████  █████   █████ ░░░███████░  ░░█████████     █████   
░░░░░        ░░░░░ ░░░░░ ░░░░░ ░░░░░░░░░░ ░░░░░░░░░░░      ░░░░░░░░░  ░░░░░   ░░░░░    ░░░░░░░     ░░░░░░░░░     ░░░░░    

*/
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//PROVENANCE HASH FILE   : https://ipfs.io/ipfs/QmPYUN9HArV2LEEeiyWSyYV5wuiGNBUSaJ1gQVZqZsHQfB
//PROVENANCE HASH SHA256 : e77b7422d5912d3088f75ac0941b6def3ecc0ded21959022efd943c628dc6d07

contract PIXEL_GHOST_XD is ERC721, ERC721Enumerable, Ownable {
    uint256 public constant MAX_TOKENS = 10000;
    uint256 public constant MAX_TOKENS_PER_PURCHASE = 5;
    uint256 public RANGE_MIN_TOKEN_FOR_FREE_MINT = 100;
    uint256 public RANGE_MAX_TOKEN_FOR_FREE_MINT = 200;
    uint256 public MAX_TOKEN_MINT_ON_FREE_MINT = 5;
    uint256 public PRICE = 0.025 ether;

    constructor() ERC721("PIXEL GHOST", "PXLG") {}

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://ipfs.io/ipfs/QmWj1SpYnX4VMNdiowKDCdwk3q9TTXNrQnTo5vLbbZ3za2/";
    }

    function mint(address _to, uint256 _count) public payable {
        uint256 supply = totalSupply();
        require(supply + _count <= MAX_TOKENS, "Max limit");
        require(supply <= MAX_TOKENS, "Sale end");
        require(msg.value >= PRICE*_count, "Value below price");
        for (uint256 i = 0; i < _count; i++) {
        _safeMint(_to, supply + i);
        }
    }

    function tokensByOwnerForFreeMint(address sender) public view returns(uint256) {
        uint256 tokenCount = balanceOf(sender);
            uint256 index;
            uint256 indextwo;
            uint256 countInRange;
            for (index = 0; index < tokenCount; index++) {
                indextwo = tokenOfOwnerByIndex(sender, index);
                if (indextwo >= RANGE_MIN_TOKEN_FOR_FREE_MINT && indextwo <= RANGE_MAX_TOKEN_FOR_FREE_MINT) {
                    countInRange++;
                }
            }
            return countInRange;
        }

    function freeMint() public {
        uint256 supply = totalSupply();
        require(supply >= RANGE_MIN_TOKEN_FOR_FREE_MINT && supply <= RANGE_MAX_TOKEN_FOR_FREE_MINT, "Is not a freemint periods");
        require(tokensByOwnerForFreeMint(msg.sender) <= MAX_TOKEN_MINT_ON_FREE_MINT - 1, "Max Token minted on freemint period reached, please use a default mint fonction");
        require(supply < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
        _safeMint(_msgSender(), supply);
    }

    function safeMint(address _to) public onlyOwner {
        uint256 supply = totalSupply();
        require(supply < MAX_TOKENS + 1, "Exceeds maximum tokens available for purchase");
        _safeMint(_to, supply);
    }

    function setMAX_TOKEN_MINT_ON_FREE_MINT(uint256 _newMAX_TOKEN_MINT_ON_FREE_MINT) public onlyOwner() {
        MAX_TOKEN_MINT_ON_FREE_MINT = _newMAX_TOKEN_MINT_ON_FREE_MINT;
    }

    function setRANGE_MIN_TOKEN_FOR_FREE_MINT(uint256 _newRANGE_MIN_TOKEN_FOR_FREE_MINT) public onlyOwner() {
        RANGE_MIN_TOKEN_FOR_FREE_MINT = _newRANGE_MIN_TOKEN_FOR_FREE_MINT;
    }

    function setRANGE_MAX_TOKEN_FOR_FREE_MINT(uint256 _newRANGE_MAX_TOKEN_FOR_FREE_MINT) public onlyOwner() {
        RANGE_MAX_TOKEN_FOR_FREE_MINT = _newRANGE_MAX_TOKEN_FOR_FREE_MINT;
    }

    function setPRICE(uint256 _newPRICE) public onlyOwner() {
        PRICE = _newPRICE;
    }

  function withdraw() public onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }

      function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}