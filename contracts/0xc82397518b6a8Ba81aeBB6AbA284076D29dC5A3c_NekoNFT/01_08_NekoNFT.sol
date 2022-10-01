// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Administration.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NekoNFT is ERC721A, Ownable, Administration { 

    uint public price = 0.00777 ether;
    uint public maxSupply = 4444;
    uint private maxTx = 20;
    string internal baseTokenURI = "https://us-central1-nekonft.cloudfunctions.net/api/asset/";
    bool public mintOpen = false;
    bool public presaleOpen = true;

    address private _signer;

    mapping(address => uint) public free;
    
    constructor() ERC721A("NEKO NFT", "NEKO") {
        setSigner(_msgSender());
    }

    function isInWhitelist(bytes calldata signature_) private view returns (bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender())), signature_) == _signer;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external onlyAdmin {
        _mintTo(to, qty);
    }

    function mintPresale(uint qty, bytes calldata signature_) external payable {
        require(presaleOpen, "closed");
        require(isInWhitelist(signature_), "address not in whitelist");
        require(balanceOf(_msgSender()) + qty <= maxTx, "You can't buy more");
        _buy(qty);
    }
    
    function mint(uint qty) external payable {
        require(mintOpen, "closed");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        uint free_ = free[_msgSender()] == 0 ? 1 : 0;
        require(msg.value >= price * (qty - free_), "PAYMENT: invalid value");
        if(free[_msgSender()] == 0){
            free[_msgSender()] = 1;
        }
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        _mint(to, qty);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
    }

    function setSigner(address newSigner) public onlyOwner {
        _signer = newSigner;
    }
    
    function setPrice(uint newPrice) external onlyOwner {
        price = newPrice;
    }
    
    function setBaseTokenURI(string calldata _uri) external onlyOwner {
        baseTokenURI = _uri;
    }
    
    function setMaxSupply(uint newSupply) external onlyOwner {
        maxSupply = newSupply;
    }
    
    function setMaxTx(uint newMax) external onlyOwner {
        maxTx = newMax;
    }
    
}