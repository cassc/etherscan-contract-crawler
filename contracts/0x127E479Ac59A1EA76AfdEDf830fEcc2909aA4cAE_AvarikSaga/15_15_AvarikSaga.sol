// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                          
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract AvarikSaga is EIP712, ERC721Enumerable, Ownable {
    using Strings for uint256;

    bytes32 public constant PRESALE_TYPEHASH = keccak256("Presale(address buyer,uint256 maxCount)");

    uint256 public constant AVARIK_GIFT = 150;
    uint256 public constant AVARIK_PRIVATE = 8738;
    uint256 public constant AVARIK_MAX = AVARIK_GIFT + AVARIK_PRIVATE;
    uint256 public constant AVARIK_PRICE = 0.08 ether;
    
    mapping(address => uint256) public presalerListPurchases;
    
    string private _contractURI;
    string private _tokenBaseURI;
    string private _defaultBaseURI;

    address private _artistAddress = 0x6Fbf131EEaF61A48696d240b168A35fa6431C717;
    address public whitelistSigner;

    uint256 public giftedAmount;
    uint256 public privateAmountMinted;
    bool public presaleLive;

    event WhitelistSignerSettled(address oldSigner, address newSigner);

    constructor(
        string memory tokenBaseURI_,
        address _whitelistSigner
    ) 
        ERC721("Avarik Saga", "AVARIK")  
        EIP712("Avarik Saga", "1.0.0") 
    {
        _tokenBaseURI = tokenBaseURI_;
        whitelistSigner = _whitelistSigner;
    }

    function _hash(address _buyer, uint _maxCount) internal view returns(bytes32 hash) {
        hash = _hashTypedDataV4(keccak256(abi.encode(
            PRESALE_TYPEHASH,
            _buyer,
            _maxCount
        )));
    }

    function _verify(bytes32 digest, bytes memory signature) internal view returns(bool) {
        return ECDSA.recover(digest, signature) == whitelistSigner;
    }

    function setWhitelistSigner(address _whitelistSigner) external onlyOwner {
        require(_whitelistSigner != whitelistSigner, "Signer is still the same!");
        
        address oldSigner = whitelistSigner;
        whitelistSigner = _whitelistSigner;

        emit WhitelistSignerSettled(oldSigner, whitelistSigner);
    }
    
    function presaleBuy(uint256 tokenQuantity, uint256 maxCount, bytes memory signature) external payable {
        require(whitelistSigner != address(0), "Signer is default address!");
        require(_verify(_hash(msg.sender, maxCount), signature), "The Signature is invalid!");
        require(presaleLive, "The presale is closed");
        require(totalSupply() < AVARIK_MAX, "All Avariks are minted");
        require(privateAmountMinted + tokenQuantity <= AVARIK_PRIVATE, "Minting would exceed the presale allocation");
        require(presalerListPurchases[msg.sender] + tokenQuantity <= maxCount, "You can not mint exceeds maximum NFT");
        require(AVARIK_PRICE * tokenQuantity <= msg.value, "Insufficient ETH sent");
        
        presalerListPurchases[msg.sender] += tokenQuantity;

        for (uint256 i = 0; i < tokenQuantity; i++) {
            privateAmountMinted++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }
    
    function gift(address[] calldata receivers) external onlyOwner {
        require(totalSupply() + receivers.length <= AVARIK_MAX, "MAX_MINT");
        require(giftedAmount + receivers.length <= AVARIK_GIFT, "GIFTS_EMPTY");
        
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedAmount++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }
    
    function withdraw() external onlyOwner {
        payable(_artistAddress).transfer(address(this).balance * 2 / 5);
        payable(msg.sender).transfer(address(this).balance);
    }

    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[addr];
    }
    
    function isPresaleActive() external view returns(bool) {
        return presaleLive;
    }
    // Owner functions for enabling presale, sale, revealing and setting the provenance hash
    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }
    
    function setContractURI(string calldata URI) external onlyOwner {
        _contractURI = URI;
    }
    
    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }
    
    function setDefaultBaseURI(string calldata URI) external onlyOwner {
        _defaultBaseURI = URI;
    }
    
    // aWYgeW91IHJlYWQgdGhpcywgc2VuZCBGcmVkZXJpayMwMDAxLCAiZnJlZGR5IGlzIGJpZyI=
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        
        return bytes(_tokenBaseURI).length > 0 ? string(abi.encodePacked(_tokenBaseURI, tokenId.toString())) : _defaultBaseURI;
    }
}