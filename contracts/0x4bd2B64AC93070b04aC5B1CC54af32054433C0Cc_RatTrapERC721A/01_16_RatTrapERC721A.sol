// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Rat Trap

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract RatTrapERC721A is Ownable, ERC721A, PaymentSplitter {
    using Strings for uint;
    enum Step {
        Before,
        WhitelistSale,
        PublicSale,
        SoldOut,
        Reveal
    }

    Step public sellingStep;

    uint private constant MAX_SUPPLY = 5555;
    uint private constant MAX_GIFT = 55;
    uint private constant MAX_WHITELIST = 4000;
    uint private constant MAX_SUPPLY_MINUS_GIFT = MAX_SUPPLY - MAX_GIFT;

    uint public wlSalePrice = 59000000000000000; 
    uint public publicSalePrice = 69000000000000000;
  
    bytes32 public merkleRoot;
    string public baseURI;
    uint public maxPerAddressDuringWhitelistMint = 2;
    uint public maxPerAddressDuringPublicMint = 1;
    uint private teamLength;    
    mapping(address => uint) public amountNFTsperWalletWhitelistSale;
    mapping(address => uint) public amountNFTsperWalletPublicSale;
    bool public isPaused;

    constructor(
        address[] memory _team, 
        uint[] memory _teamShares, 
        bytes32 _merkleRoot, 
        string memory _baseURI) 
    ERC721A("Rat Trap", "TRT") 
    PaymentSplitter(_team, _teamShares) {
        merkleRoot = _merkleRoot;
        baseURI = _baseURI;
        teamLength = _team.length;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function whitelistMint(address _account, uint _quantity, bytes32[] calldata _proof) external payable callerIsUser {
        require(!isPaused, "Contract is paused");
        uint price = wlSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.WhitelistSale, "Whitelist sale is not activated");
        require(isWhiteListed(msg.sender, _proof), "Not whitelisted");
        require(amountNFTsperWalletWhitelistSale[msg.sender] + _quantity <= maxPerAddressDuringWhitelistMint, 
        "You can't mint more NFT during this phase");
        require(totalSupply() + _quantity <= MAX_WHITELIST, "Max supply exceeded for the Whitelist Sale");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletWhitelistSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        require(!isPaused, "Contract is paused");
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY_MINUS_GIFT, "The sale is sold out");
        require(amountNFTsperWalletPublicSale[msg.sender] + _quantity <= maxPerAddressDuringPublicMint,
        "You can't mint more NFT during this phase");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletPublicSale[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function gift(address[] calldata _to) external onlyOwner {
        require(sellingStep > Step.PublicSale, "Gift is after the public sale");
        require(totalSupply() + 1 <= MAX_SUPPLY, "Reached max supply");
        for(uint i = 0 ; i < _to.length ; i++) {
            _safeMint(_to[i], 1);
        }
    }

    function setWlSalePrice(uint _wlSalePrice) external onlyOwner {
        wlSalePrice = _wlSalePrice;
    }

    function setMaxUserSupplyForWl(uint _wlMaxUserSupply) external onlyOwner {
        maxPerAddressDuringWhitelistMint = _wlMaxUserSupply;
    }

    function setMaxUserSupplyForPublic(uint _publicMaxUserSupply) external onlyOwner {
        maxPerAddressDuringPublicMint = _publicMaxUserSupply;
    }

    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
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

    function setPaused(bool _isPaused) external onlyOwner {
        isPaused = _isPaused;
    }
 
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isWhiteListed(address _account, bytes32[] calldata _proof) internal view returns(bool) {
        return _verify(leaf(_account), _proof);
    }

    function leaf(address _account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_account));
    }

    function _verify(bytes32 _leaf, bytes32[] memory _proof) internal view returns(bool) {
        return MerkleProof.verify(_proof, merkleRoot, _leaf);
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