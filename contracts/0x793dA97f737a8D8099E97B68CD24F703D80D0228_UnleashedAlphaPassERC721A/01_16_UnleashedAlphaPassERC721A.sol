// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Unleashed Alpha Pass ERC721A

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract UnleashedAlphaPassERC721A is Ownable, ERC721A, PaymentSplitter {
    using Strings for uint;

    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 1333;
    uint private constant MAX_GIFT = 533;
    uint private constant MAX_SUPPLY_MINUS_GIFT = MAX_SUPPLY - MAX_GIFT;

    address public pledgeContractAddress = 0x036d5E237EfBdb1583c29B8648f637812A94cdF2;

    uint public wlSalePrice = 49000000000000000; 
    uint public publicSalePrice = 100000000000000000;
  
    uint public constant maxPerAddressDuringPublicMint = 4;
    uint public constant maxPerAddressDuringWhitelistMint = 5;

    bytes32 public wlMerkleRoot;
    string public baseURI;
    uint private teamLength;
    bool public isPaused;

    mapping(address => uint) public amountNFTsperWalletWhitelistSale;
    mapping(address => uint) public amountNFTsperWalletPublicSale;

    constructor(
        address[] memory _team, 
        uint[] memory _teamShares, 
        bytes32 _wlMerkleRoot, 
        string memory _baseURI) 
    ERC721A("UnleashedAlphaPass", "UAP") 
    PaymentSplitter(_team, _teamShares) {
        wlMerkleRoot = _wlMerkleRoot;
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        uint price = wlSalePrice;
        require(!isPaused, "Contract is paused");
        require(price != 0, "Price is 0");
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= maxPerAddressDuringWhitelistMint, 
        "You can only get 5 NFT on the Whitelist Sale");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "Max supply exceeded for WL Mint");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(!isPaused, "Contract is paused");
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "Max supply exceeded : Sold out");
        require(amountNFTsperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicMint,"You can only get 4 NFT on the Public Sale");
        require(msg.value >= price * _quantity, "Not enought funds");
        _safeMint(_account, _quantity);
    }

    function gift(address[] calldata _to) external onlyOwner {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        for(uint i = 0 ; i < _to.length ; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function specialGift(address[] calldata _to) external payable callerIsUser {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        require(!isPaused, "Contract is paused");
        for(uint i = 0 ; i < _to.length ; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }

    function setWlSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }

    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function pledgeMint(address to, uint8 quantity) external payable {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Max supply exceeded!");
        require(pledgeContractAddress == msg.sender, "The caller is not PledgeMint");
        _safeMint(to, quantity);
    }

    function setPledgeContractAddress(address _pledgeContractAddress) public onlyOwner {
        pledgeContractAddress = _pledgeContractAddress;
    }
    
    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
 
    function setWlMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        wlMerkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verifyWl(leaf(_account), _proof);
    }
   
    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verifyWl(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, wlMerkleRoot, _leaf);
    }

    function releaseAll() external onlyOwner  {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }
}