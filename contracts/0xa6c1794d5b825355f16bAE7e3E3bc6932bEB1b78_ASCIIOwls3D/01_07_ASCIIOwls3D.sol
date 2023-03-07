// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ERC721A/contracts/ERC721A.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/Strings.sol";

contract ASCIIOwls3D is ERC721A, Ownable {
    using Strings for uint256;

    uint public constant TOTAL_SUPPLY = 3999;
    uint public constant FREE_SUPPLY = 500;

    uint public constant MAX_PER_WALLET = 20;

    uint public mintPrice = 0.003 ether;
    
    constructor() ERC721A("ASCII Owls 3D", "ASCIIOwls3D") {}

    function mint(uint amount) external payable {
        require(msg.sender == tx.origin, "no bot");
        uint mintedCount = _numberMinted(msg.sender);
        require(mintedCount + amount <= MAX_PER_WALLET, "mint too many");
        uint nextTokenId = _nextTokenId();
        require(nextTokenId + amount <= TOTAL_SUPPLY, "sold out");
        
        uint fee = 0;
        // first 500 free
        // mint first one free
        if (!(nextTokenId + amount <= FREE_SUPPLY || (mintedCount == 0 && amount == 1))) {
            uint payMount = nextTokenId + amount - FREE_SUPPLY;
            payMount = payMount > amount ? amount : payMount;
            fee = mintPrice * payMount;
        }
        require(msg.value >= fee, "not enough money");
        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory currentBaseURI = "ipfs://bafybeiacaoytsqbxh2w5tz2lhkefzaky2issh2rhmjk36hg266tfoeevru/";
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
            : '';
    }

    receive() external payable {}

    function setMintPrice(uint price) external onlyOwner {
        mintPrice = price;
    }

    function withdraw() external onlyOwner {
        (bool success,)= owner().call{value: address(this).balance}("");
        require(success);
    }
}