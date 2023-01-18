// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";

contract KUROSHIO is ERC721A, Ownable {

    constructor() ERC721A("KUROSHIO", "KUROSHIO") {}

    string private _uri;

    uint public maxSupply = 4444;
    bool public saleStatus = false;
    uint public price = 44 * 10**14;
    uint public maxFreePerTx = 1;
    uint public maxFreePerWallet = 1;
    uint public maxFreeMintCount = 2222;
    uint public freeMintCount = 0;

    bool public isOpenBox = false;
    
 
    // ---------------------------------------------------------------------------------------------
    // MAPPINGS
    // ---------------------------------------------------------------------------------------------

    mapping(address => uint) public freeMinted; 

    mapping(address => uint) public feeMinted; 
    // ---------------------------------------------------------------------------------------------
    // OWNER SETTERS
    // ---------------------------------------------------------------------------------------------

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setMaxFreeMintCount(uint _count) external onlyOwner {
        maxFreeMintCount = _count;
    }

    function setSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }

    function setMaxSupply(uint supply) external onlyOwner {
        maxSupply = supply;
    }

    function setPrice(uint amount) external onlyOwner {
        price = amount;
    }

    function setMaxFreePerTx(uint amount) external onlyOwner {
        maxFreePerTx = amount;
    }
    
    function setMaxFreePerWallet(uint amount) external onlyOwner {
        maxFreePerWallet = amount;
    }
    
    function setBaseURI(string calldata uri_) external onlyOwner {
        _uri = uri_;
    }

    function openBox(string calldata uri_) external onlyOwner {
        _uri = uri_;
        isOpenBox = true;
    }

    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }

    function devMint(uint256 amount) external onlyOwner {
        require(amount > 0, "AMOUNT_ERROR!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS");
        _safeMint(msg.sender, amount);
    }

    function airdrop(address[] calldata addrs, uint256 amount) external onlyOwner {
        require(amount > 0, "AMOUNT_ERROR!");
        require((_totalMinted() + amount * addrs.length) <= maxSupply, "NOT_ENOUGH_TOKENS");

        for (uint i = 0; i < addrs.length; i++) {
            _safeMint(addrs[i], amount);
        }
    }

    function mint(uint256 amount) external payable {
        require(amount > 0, "AMOUNT_ERROR!");
        require(saleStatus, "SALE_NOT_ACTIVE!");
        require(tx.origin == msg.sender, "NOT_ALLOW_CONTRACT_CALL!");
        require((_totalMinted() + amount) <= maxSupply, "NOT_ENOUGH_TOKENS!");
        if (freeMinted[msg.sender] + amount <= maxFreePerWallet && freeMintCount + amount <= maxFreeMintCount) {
            // free mint
            require(amount <= maxFreePerTx, "EXCEEDS_MAX_PER_TX!");
            freeMintCount += amount;
            _safeMint(msg.sender, amount);
            freeMinted[msg.sender] += amount;
        } else {
            require(amount * price <= msg.value, "NOT_ENOUGH_MONEY!");
            _safeMint(msg.sender, amount);
            feeMinted[msg.sender] += amount;
        }
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        if (!isOpenBox) {
            return bytes(baseURI).length != 0 ? baseURI : '';
        }
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }
}