// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract KYOTO is ERC721Enumerable, Ownable {
    uint public price;
    uint public immutable maxSupply;
    uint public supplyCap;
    bool public mintingEnabled;
    bool public whitelistMintingEnabled;
    uint public walletLimit;
    address public whitelistSigner;
    mapping(address => uint) public mints;

    string private _baseURIPrefix;
    enum Sale { WHITELIST, PUBLIC }

    constructor (
        string memory _name, 
        string memory _symbol, 
        uint _maxSupply, 
        uint _supplyCap, 
        uint _price,
        uint _walletLimit, 
        string memory _uri
    ) ERC721(_name, _symbol) {
        maxSupply = _maxSupply;
        supplyCap = _supplyCap;
        price = _price;
        walletLimit = _walletLimit;
        _baseURIPrefix = _uri;
        whitelistSigner = owner();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIPrefix;
    }
    
    function info(address addr) external view returns (uint256, uint256, uint256, uint256, uint256, bool, bool, uint256, address) {
        return (mints[addr], maxSupply, supplyCap, totalSupply(), price, mintingEnabled, whitelistMintingEnabled, walletLimit, whitelistSigner);
    }

    function setBaseURI(string memory newUri) external onlyOwner {
        _baseURIPrefix = newUri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setWalletLimit(uint256 newWalletLimit) external onlyOwner {
        walletLimit = newWalletLimit;
    }

    function setSupplyCap(uint256 newSupplyCap) external onlyOwner {
        supplyCap = newSupplyCap;
    }
    
    function setWhitelistSigner(address newWhitelistSigner) external onlyOwner {
        whitelistSigner = newWhitelistSigner;
    }

    function toggleMinting() external onlyOwner {
        mintingEnabled = !mintingEnabled;
    }

    function toggleWhitelistMinting() external onlyOwner {
        whitelistMintingEnabled = !whitelistMintingEnabled;
    }

    function mintReserves(uint256 qty) external onlyOwner checkSupply(qty) {
        batchMint(qty);
    }

    function mintWhitelisted(uint256 qty, bytes memory sig) 
        external 
        payable
        checkSupply(qty)
        saleOpen(Sale.WHITELIST)
        onWhitelist(sig)
        validateInput(qty)
    {
        batchMint(qty);
    }

    function mint(uint256 qty) external payable checkSupply(qty) saleOpen(Sale.PUBLIC) validateInput(qty) {
        batchMint(qty);
    }
    
    modifier saleOpen(Sale saleType) {
        if (saleType == Sale.WHITELIST)
            require(whitelistMintingEnabled, "Whitelist minting has not been enabled");
        else
            require(mintingEnabled, "Minting has not been enabled");
            
        _;
    }
    
    modifier onWhitelist(bytes memory sig) {
        require(isWhitelisted(_msgSender(), sig), "Not whitelisted");
        _;
    }
    
    modifier checkSupply(uint256 qty) {
        require(totalSupply() + qty <= maxSupply, "Max supply exceeded");
        require(totalSupply() + qty <= supplyCap, "Supply cap exceeded");
        _;
    }

    modifier validateInput(uint256 qty) {
        require(qty > 0, "Invalid quantity");
        require(mints[_msgSender()] + qty <= walletLimit, "Wallet limit exceeded");
        require(price * qty == msg.value, "Incorrect ETH value");
        _;
    }

    function batchMint(uint256 qty) internal {
        for (uint i = 0; i < qty; i++) {
            _safeMint(_msgSender(), totalSupply() + 1);
        }
        mints[_msgSender()] += qty;
    }

    function isWhitelisted(address addr, bytes memory sig) public view returns (bool) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := and(mload(add(sig, 65)), 255)
        }
        if (v < 27) v += 27;
        
        bytes32 hash = keccak256(abi.encodePacked(address(this), addr));
        bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        
        return whitelistSigner == ecrecover(message, v, r, s);
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}