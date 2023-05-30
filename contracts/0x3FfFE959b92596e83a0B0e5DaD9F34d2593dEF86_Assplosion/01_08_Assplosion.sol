// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Administration.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Assplosion is ERC721A, Ownable, Administration { 

    uint public price = 0.03 ether;
    uint public maxSupply = 5000;
    uint public maxTx = 20;

    bool private mintOpen = false;
    bool private presaleOpen = false;

    address private _signer;
    
    mapping(address => uint[]) private ownership;

    string internal baseTokenURI = 'https://us-central1-crypto-2bf22.cloudfunctions.net/api/asset/';
    
    constructor() ERC721A("Assplosion", "asspls") {}

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

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function buyTo(address to, uint qty) external onlyAdmin {
        _mintTo(to, qty);
    }

    function buy(uint qty, bytes calldata signature_) external payable {
        require(presaleOpen, "store closed");
        require(isInWhitelist(signature_), "address not in whitelist");
        _buy(qty);
    }
    
    function buy(uint qty) external payable {
        require(mintOpen, "store closed");
        _buy(qty);
    }

    function _buy(uint qty) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        uint free = balanceOf(_msgSender()) == 0 ? 1 : 0;
        require(msg.value >= price * (qty - free), "PAYMENT: invalid value");
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply() <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        _mint(to, qty);
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function isInWhitelist(bytes calldata signature_) private view returns (bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender())), signature_) == _signer;
    }
    
}