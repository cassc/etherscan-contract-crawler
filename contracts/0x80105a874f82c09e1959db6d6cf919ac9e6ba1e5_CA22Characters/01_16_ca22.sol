// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "contracts/ERC721A.sol";

contract CA22Characters is ERC721A, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Strings for uint256;
    event Mint(address indexed to, uint256 nonce, uint256 amount, uint256 step);

    address public decisionsContractAddressStates;
    address public verifyAddress = 0xd329159BbF6247Da4f365bc1e6e90cBE06d4748B;
    bool public locked;
    bool public presalelocked;
    bool public wllocked;
    bool public salelocked;

    uint256 private constant CA22_MAX = 8000;
    uint256 private constant PRESALE_PRICE = 0.069 ether;
    uint256 private constant PUBLIC_PRICE = 0.08 ether;
    uint256 public preSaleStartTimestamp;
    uint256 public publicSaleStartTimestamp;
    mapping(address => uint256) public freeNonce;
    mapping(address => uint256) public presaleNonce;

    string private tokenBaseURIStates = "https://ca22.xyz/api/v1/metadata/";
    bytes32 public roleMerkelRoot;
    uint constant Free = 1;
    uint constant Presale = 2;
    constructor(uint256 maxBatchSize, uint256 collectionSize) ERC721A("Cthulhu Armageddon 2022", "CA22", maxBatchSize, collectionSize) {
        _safeMint(msg.sender, 1);
    }

    modifier whenPublicSaleActive() {
        require(isPublicSaleOpen(), "Public sale not open");
        _;
    }

    modifier whenPreSaleActive() {
        require(isPreSaleOpen(), "Early access not open");
        _;
    }

    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    function setBaseURI(string calldata _BaseURI) external onlyOwner notLocked {
        tokenBaseURIStates = _BaseURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");      
        return string(abi.encodePacked(tokenBaseURIStates, tokenId.toString()));
    }

    function mintPublicSale(uint256 _count) external payable nonReentrant whenPublicSaleActive {
        require(!salelocked, "sale ended");
        require(tx.origin == msg.sender, "Contract is not allowed.");
        require(_count > 0, "Invalid CA22 characters count");
        require(totalSupply() + _count <= CA22_MAX, "All CA22 characters have been minted");
        require(msg.value >= _count * PUBLIC_PRICE, "Incorrect amount of ether sent");
        _safeMint(msg.sender, _count);
    }

    function mintPreSale(uint256 _count, uint256 _nonce, bytes calldata signature) external payable nonReentrant whenPreSaleActive {
        require(!presalelocked, "presale ended");
        require(_count > 0, "Invalid CA22 characters count");
        require(totalSupply() + _count <= CA22_MAX, "All early access CA22 characters have been minted");
        require(msg.value >= _count * PRESALE_PRICE, "Incorrect amount of ether sent");

        require(_nonce >= presaleNonce[msg.sender] + 1, "Nonce too old");
        require(verify(verifyAddress, msg.sender, _count, _nonce, Presale, signature), "Signature verification failed");
        _safeMint(msg.sender, _count);
        presaleNonce[msg.sender] = _nonce;
        emit Mint(msg.sender, _nonce, _count, Presale);
    }

    function freeMint(uint256 _count, uint256 _nonce, bytes calldata signature) external nonReentrant whenPreSaleActive {
        require(!wllocked, "free mint ended");
        require(_count > 0, "Invalid CA22 characters count");
        require(totalSupply() + _count <= CA22_MAX, "All early access CA22 characters have been minted");
        require(_nonce >= freeNonce[msg.sender] + 1, "Nonce too old");
        require(verify(verifyAddress, msg.sender, _count, _nonce, Free, signature), "Signature verification failed");
        _safeMint(msg.sender, _count);
        freeNonce[msg.sender] = _nonce;
        emit Mint(msg.sender, _nonce, _count, Free);
    }


    function verify(address _signer, address _to, uint256 _amount, uint256 _nounce, uint _step,bytes calldata signature) internal pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _nounce, _step);
        return recoverSigner(messageHash, signature) == _signer;
    }

    function getMessageHash(address _to, uint256 _amount, uint256 _nonce, uint _step) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _nonce, _step));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v ) {
        require(sig.length == 65, "Invalid signature length!");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function isPublicSaleOpen() public view returns (bool) {
        return block.timestamp >= publicSaleStartTimestamp && publicSaleStartTimestamp != 0;

    }

    function isPreSaleOpen() public view returns (bool) {
        return !isPublicSaleOpen() && block.timestamp >= preSaleStartTimestamp && preSaleStartTimestamp != 0;
    }

    function setPublicSaleTimestamp(uint256 timestamp) external onlyOwner {
        publicSaleStartTimestamp = timestamp;
    }

    function setPreSaleTimestamp(uint256 timestamp) external onlyOwner {
        preSaleStartTimestamp = timestamp;
    }

    function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
        _setOwnersExplicit(quantity);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function withdraw() public onlyOwner {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "Withdrawal failed");
    }

    function lockPreSale() external onlyOwner {
        presalelocked = true;
    }

    function lockWL() external onlyOwner {
        wllocked = true;
    }

    function lockSale() external onlyOwner {
        salelocked = true;
    }

    function lockMetadata() external onlyOwner {
        locked = true;
    }

    function setdecisionsContractAddress(address _decisionsAddress) public onlyOwner {
        decisionsContractAddressStates = _decisionsAddress;
    }

    function decisionsContractAddress() public view returns (address) {
        return decisionsContractAddressStates;
    }

    function setRoleMerkelRoot(bytes32 _role) public onlyOwner notLocked {
        roleMerkelRoot = _role;
    }

    function verifyProof(bytes32 _value, bytes32[] calldata _proof)
        public view returns (bool) {
        bytes32 result = _value;
        for(uint i = 0; i < _proof.length; i++) {
            if (result < _proof[i]){
                result = pairHash(result, _proof[i]);
            } else {
                result = pairHash(_proof[i], result);
            }
            
        }
        return result == roleMerkelRoot; 
    }

    function pairHash(bytes32 _left, bytes32 _right) internal pure returns(bytes32 value) {
        assembly {
            mstore(0x00, _left)
            mstore(0x20, _right)
            value := keccak256(0x00, 0x40)
        }
    }
    
}