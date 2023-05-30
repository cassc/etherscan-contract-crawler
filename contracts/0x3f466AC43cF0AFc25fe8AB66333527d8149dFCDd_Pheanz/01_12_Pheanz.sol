// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract Pheanz is ERC721A, Ownable {
    uint256 public constant MINT_PRICE = 0 ether;
    uint256 public constant MAX_SUPPLY = 4444;
    uint256 public constant MAX_PER_WALLET = 20;

    /**
     * Base URI
     */
    string private baseURI = "ipfs://QmcZR7VQ4pctEHwokxndJPRgGF93w4vq3TViH74bpLhARa/";

    constructor() ERC721A("Somephing", "PHEANZ") {}

    /**
     * Public sale and whitelist sale mechansim
     */
    bool public publicSale = false;


    function setPublicSale(bool toggle) external onlyOwner {
        publicSale = toggle;
    }

    /**
     * Public minting
     */
    mapping(address => uint256) public publicAddressMintCount;

    function mintPublic(uint256 _quantity) public payable {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Surpasses supply");
        require(publicSale, "Public sale not started");
        require(_quantity > 0 && publicAddressMintCount[msg.sender] + _quantity <= MAX_PER_WALLET,"Minting above public limit");
        publicAddressMintCount[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * Withdrawal
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(msg.sender), balance);
    }
}