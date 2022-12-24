// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "ERC721A/ERC721A.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/utils/cryptography/ECDSA.sol";
import "openzeppelin/utils/Strings.sol";
import "operator-filter-registry/DefaultOperatorFilterer.sol";

error NotEnoughETH();
error SaleNotLive();
error NoContractCall();
error SaleStepNotActive();
error WrongSignature();
error NonExistentToken();
error OutOfSupply();
error OutOfSupplyForStep();
error AlreadyMintedWalletMaxForStep();
error WithdrawFailed();

contract Seiken is Ownable, ERC721A, ReentrancyGuard, DefaultOperatorFilterer {
    using ECDSA for bytes32;
    address public signer = 0x90F8bf6A479f320ead074411a4B0e7944Ea8c9C1;
    uint256 constant collectionSize = 1111;
    uint256 constant WL_price = 0.012 ether;
    uint256 public public_price = 0.02 ether;
    uint256 public VIP_time = 1672077600;
    uint256 public public_time = 1672079400;
    uint256 public WL_time = 1672083000;
    uint256 public VIP_spots_left = 111;
    uint256 public WL_spots_left = 250;
    uint256 public constant maxPerAddressDuringVIP = 2;
    uint256 public constant maxPerAddressDuringPublic = 5;
    uint256 public constant maxPerAddressDuringWL = 3;
    mapping(address => uint256) public VIPmint;
    mapping(address => uint256) public publicmint;
    mapping(address => uint256) public WLmint;

    string private baseURI = "ipfs://bafybeiaotxx547mgl7fsvmqdbrb7kkgtf2qmq7ulf274paugah2fy3nz3u/";

    modifier mintValidity() {
        if (block.timestamp < VIP_time) revert SaleNotLive();
        if (_totalMinted() >= collectionSize) revert OutOfSupply();
        _;
    }

    constructor() payable ERC721A("Seiken Labs" ,"SKLABS") {
        _mint(msg.sender, 1);
    }

    function saleStep() view public returns (uint256) {
        if (block.timestamp > VIP_time) {
            if (block.timestamp > public_time || VIP_spots_left == 0) {
                if (block.timestamp > WL_time || _totalMinted() > (750+(111-VIP_spots_left)) ) {
                    return 3;
                } else {
                    return 2;
                }
            } else {
                return 1;
            }
        } else {
            return 0;
        }
    }

    function VIP_mint(uint256 _quantity, bytes memory _signature) external nonReentrant mintValidity() {
        if(saleStep() != 1) revert SaleStepNotActive();
        if(VIP_spots_left < _quantity) revert OutOfSupplyForStep();
        if(recoverSigner(_signature) != signer) revert WrongSignature();
        if(VIPmint[msg.sender] + _quantity > maxPerAddressDuringVIP) revert AlreadyMintedWalletMaxForStep();
        VIPmint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
        VIP_spots_left -= _quantity;
    }
    function public_mint(uint256 _quantity) external payable nonReentrant mintValidity() {
        if(saleStep() < 2) revert SaleStepNotActive();
        if(msg.value < public_price * _quantity) revert NotEnoughETH();
        if(publicmint[msg.sender] + _quantity > maxPerAddressDuringPublic) revert AlreadyMintedWalletMaxForStep();
        publicmint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
    }
    function WL_mint(uint256 _quantity, bytes memory _signature) external payable nonReentrant mintValidity() {
        if(saleStep() != 3) revert SaleStepNotActive();
        if(WL_spots_left < _quantity) revert OutOfSupplyForStep();
        if(msg.value < WL_price * _quantity) revert NotEnoughETH();
        if(recoverSigner(_signature) != signer) revert WrongSignature();
        if(WLmint[msg.sender] + _quantity > maxPerAddressDuringWL) revert AlreadyMintedWalletMaxForStep();
        WLmint[msg.sender] += _quantity;
        _mint(msg.sender, _quantity);
        WL_spots_left -= _quantity;
    }

    function getMaxQuantityForUser() public view returns (uint256 maxQuantity){
        uint256 step = saleStep();
        if(step == 1){
            return maxPerAddressDuringVIP - VIPmint[msg.sender];
        } else if(step == 2){
            return maxPerAddressDuringPublic - publicmint[msg.sender];
        } else if(step == 3){
            return maxPerAddressDuringWL - WLmint[msg.sender];
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        if(_exists(_tokenId) == false) revert NonExistentToken();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, Strings.toString(_tokenId),".json")) : "";
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

   function setPublicPrice(uint256 _public_price) external onlyOwner {
        public_price = _public_price;
    }

    function setTimestamps(uint256 _VIP_time, uint256 _public_time, uint256 _WL_time) external onlyOwner{
        VIP_time = _VIP_time;
        public_time = _public_time;
        WL_time = _WL_time;
   }

    function recoverSigner(bytes memory _signature) internal view returns (address) {
        return (ECDSA.recover(ECDSA.toEthSignedMessageHash(keccak256(abi.encodePacked(msg.sender, uint8(saleStep())))), _signature));
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        if(success == false) revert WithdrawFailed();
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}