// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MutantKongzLab is ERC721, Ownable { 

    using ECDSA for bytes32; 
    
    string internal baseTokenURI = 'https://us-central1-mutant-kongz.cloudfunctions.net/api/asset/';

    uint public price = 0.08 ether;

    uint public maxSupply = 9999;
    uint public totalSupply = 0;

    uint public referralBonus = 0.005 ether;

    uint public maxTx = 5;
    uint public maxAssetsPresale = 3;

    bool public mintOpen = false;
    bool public presaleOpen = false;
    
    mapping(address => uint) private presaleMints;
    
    event TransferFailed(address to, uint amount);

    address private _signer = 0x0EeCf11819a8929513d6DDFD50219CaACfbc494D;
    
    constructor() ERC721("Mutant Kongz Lab", "MKL") {}

    function toggleMint() external onlyOwner {
        mintOpen = !mintOpen;
    }

    function setSigner(address newSigner) public onlyOwner {
        _signer = newSigner;
    }

    function togglePresale() external onlyOwner {
        presaleOpen = !presaleOpen;
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

    function setMaxAssetsPresale(uint newMax) external onlyOwner {
        maxAssetsPresale = newMax;
    }

    function _baseURI() internal override view returns (string memory) {
        return baseTokenURI;
    }

    function giveaway(address to, uint qty) external onlyOwner {
        _mintTo(to, qty);
    }

    function buyPresale(uint qty, address referral, bytes calldata signature_) external payable {
        _buyPresale(qty, referral, signature_);
    }

    function buyPresale(uint qty, bytes calldata signature_) external payable {
        _buyPresale(qty, address(0), signature_);
    }

    function _buyPresale(uint qty, address referral, bytes calldata signature_) internal {
        require(presaleOpen, "presale closed");
        require(isInWhitelist(signature_), "address not in whitelist");
        require(presaleMints[_msgSender()] + qty <= maxAssetsPresale, "max presale mints reached");
        presaleMints[_msgSender()] += qty;
        _buy(qty, referral);
    }

    function buy(uint qty) external payable {
        require(mintOpen, "store closed");
        _buy(qty, address(0));
    }
    
    function buy(uint qty, address referral) external payable {
        require(mintOpen, "store closed");
        _buy(qty, referral);
    }

    function _buy(uint qty, address referral) internal {
        require(qty <= maxTx && qty > 0, "TRANSACTION: qty of mints not alowed");
        require(msg.value >= price * qty, "PAYMENT: invalid value");
        require(qty + totalSupply <= maxSupply, "Sold out");
        if(referral != _msgSender() && referral != address(0)){
            (bool success, ) = payable(referral).call{value:referralBonus * qty}("");
            if(!success){
                emit TransferFailed(referral, referralBonus * qty);
            }
        }
        _mintTo(_msgSender(), qty);
    }

    function _mintTo(address to, uint qty) internal {
        require(qty + totalSupply <= maxSupply, "SUPPLY: Value exceeds totalSupply");
        for(uint i = 0; i < qty; i++){
            totalSupply++;
            _safeMint(to, totalSupply);
        }
    }

    function isInWhitelist(bytes calldata signature_) private view returns (bool) {
        return ECDSA.recover(ECDSA.toEthSignedMessageHash(abi.encodePacked(_msgSender())), signature_) == _signer;
    }
    
    function withdraw() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
}