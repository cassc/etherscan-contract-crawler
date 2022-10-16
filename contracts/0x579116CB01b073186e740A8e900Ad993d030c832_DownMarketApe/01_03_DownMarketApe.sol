// SPDX-License-Identifier: GPL-3.0
/*
 ___     ___   __    __  ____       ___ ___   ____  ____   __  _    ___  ______       ____  ____    ___ 
|   \   /   \ |  T__T  T|    \     |   T   T /    T|    \ |  l/ ]  /  _]|      T     /    T|    \  /  _]
|    \ Y     Y|  |  |  ||  _  Y    | _   _ |Y  o  ||  D  )|  ' /  /  [_ |      |    Y  o  ||  o  )/  [_ 
|  D  Y|  O  ||  |  |  ||  |  |    |  \_/  ||     ||    / |    \ Y    _]l_j  l_j    |     ||   _/Y    _]
|     ||     |l  `  '  !|  |  |    |   |   ||  _  ||    \ |     Y|   [_   |  |      |  _  ||  |  |   [_ 
|     |l     ! \      / |  |  |    |   |   ||  |  ||  .  Y|  .  ||     T  |  |      |  |  ||  |  |     T
l_____j \___/   \_/\_/  l__j__j    l___j___jl__j__jl__j\_jl__j\_jl_____j  l__j      l__j__jl__j  l_____j
                                                                                                        
 */                                                                                                

pragma solidity >=0.7.0 <0.9.0;
import "./ERC721A.sol";

contract DownMarketApe is ERC721A {
    address owner;
    uint256 maxFree;
    
    uint256 public maxSupply = 5000; // max supply
    mapping(address => uint256) public addrMinted;
    
    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    constructor() ERC721A("DownMarketApe", "DMA") {
        owner = msg.sender;
        maxFree= 2;
    }

    function mint_5() payable public {
        require(totalSupply() + 5 <= maxSupply, "SoldOut");
        require(msg.value >= 0.0015 ether, "Invalid Price");
        mint_internal(5);
    }

    function mint_10() payable public {
        require(totalSupply() + 10 <= maxSupply, "SoldOut");
        require(msg.value >= 0.003 ether, "Invalid Price");
        mint_internal(10);
    }

    function mint_free() public {
        require(msg.sender == tx.origin, "No EOA");
        require(totalSupply() + maxFree <= maxSupply, "SoldOut");
        require(addrMinted[msg.sender] == 0);
        mint_internal(maxFree);
    }

    function mint_internal(uint256 amount) internal  {
        addrMinted[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    function change_free(uint256 free) public onlyOwner {
        maxFree = free;
    } 

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://QmeWMNenMj5RF44JfXPGSmjui1RFDVRJ1pKaYi6EArVQE4/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}