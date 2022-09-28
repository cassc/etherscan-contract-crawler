// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";

contract KawaiiDragonz is Ownable, ERC721A {
    uint256 public cost = 0.003 ether;
    uint256 public max_supply = 333;
    uint256 public max_per_wallet = 3;
    bool public mint_open = false;
    mapping(address => uint256) public minted_amount;
    mapping(address => bool) public allowlist_mint;

    string private base_uri;

    constructor() ERC721A("Kawaii Dragonz", "KD") {
        base_uri = "ipfs://bafybeig22jpighjxf2goktv7sn5hbsz36pxlyyad7ygbwnseu3hpevplbm/";
        allowlist_mint[address(0x0A66F418d9B49966142d17873c77D292E89Bab7a)] = true;
        allowlist_mint[address(0xa8771fD60920f165Fb4E4CFCA2Cb1ab055f9ED53)] = true;
        allowlist_mint[address(0x8D4b3C9543C6a360453F31C6650f112607FcB884)] = true;
        allowlist_mint[address(0xEA2ADb6cb646437b2197aA689e40d27B31a7a884)] = true;
        _mint(msg.sender, 1);
    }

    function mint(uint256 _quantity) external payable mintCompliance() {
        require(msg.value >= cost * _quantity, "Not enough Eth");
        require(minted_amount[msg.sender] + _quantity <= max_per_wallet, "Already minted max");
        require(max_supply >= totalSupply() + _quantity, "Sold out");
        minted_amount[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }

    function allowlistMint() external mintCompliance() {
        require(allowlist_mint[msg.sender], "Already minted max");
        require(max_supply >= totalSupply() + 1, "Sold out");
        allowlist_mint[msg.sender] = false;
        _mint(msg.sender, 1);
    }

    function toggleOpen() external onlyOwner {
        mint_open = !mint_open;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        base_uri = baseURI;
    }

    function setCost(uint256 _price) external onlyOwner {
        cost = _price;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId+1),".json")) : '';
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return base_uri;
    }

    function withdraw() external onlyOwner {
		(bool os,) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}

    function _startTokenId() internal view virtual override returns(uint256) {
        return 0;
    }

    modifier mintCompliance() {
        require(tx.origin == msg.sender, "Caller cannot be a contract");
        require(mint_open, "Sale is not active yet");
        _;
    }
}