// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DefaultOperatorFilterer.sol";
import "./ERC721A_royalty.sol";

contract GullyDonsEC is Ownable, ERC721A, PaymentSplitter, DefaultOperatorFilterer {

    using Strings for uint;

    enum Step {
        Before,
        PublicSale,
        SoldOut
    }

    string public baseURI;

    Step public sellingStep;

    uint public  MAX_SUPPLY = 4111;

    uint public MAX_PER_WALLET_PUBLIC = 5;

    uint public publicSalePrice = 0.125 ether;

    mapping(address => uint) public amountNFTsperWalletPUBLIC;

    uint private teamLength;

    uint96 royaltyFeesInBips;
    address royaltyReceiver;

    constructor(uint96 _royaltyFeesInBips, address[] memory _team, uint[] memory _teamShares, string memory _baseURI) ERC721A("GullyDonsEC", "GullyDonsEC")
    PaymentSplitter(_team, _teamShares) {
        baseURI = _baseURI;
        teamLength = _team.length;
        royaltyFeesInBips = _royaltyFeesInBips;
        royaltyReceiver = msg.sender;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function publicSaleMint(address _account, uint _quantity) external payable callerIsUser {
        uint price = publicSalePrice;
        require(price != 0, "Price is 0");
        require(sellingStep == Step.PublicSale, "Public sale is not activated");
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Max supply exceeded");
        require(amountNFTsperWalletPUBLIC[msg.sender] + _quantity <= MAX_PER_WALLET_PUBLIC, "Max per wallet limit reached");
        require(msg.value >= price * _quantity, "Not enought funds");
        amountNFTsperWalletPUBLIC[msg.sender] += _quantity;
        _safeMint(_account, _quantity);
    }

    function gift(address _to, uint _quantity) external onlyOwner {
        require(totalSupply() + _quantity <= MAX_SUPPLY, "Reached max Supply");
        _safeMint(_to, _quantity);
    }

    function lowerSupply (uint _MAX_SUPPLY) external onlyOwner{
        
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setMaxPerWalletPUBLIC(uint _MAX_PER_WALLET_PUBLIC) external onlyOwner {
        MAX_PER_WALLET_PUBLIC = _MAX_PER_WALLET_PUBLIC;
    }

    function setPublicSalePrice(uint _publicSalePrice) external onlyOwner {
        publicSalePrice = _publicSalePrice;
    }

    function setBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function setStep(uint _step) external onlyOwner {
        sellingStep = Step(_step);
    }

    function tokenURI(uint _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        return string(abi.encodePacked(baseURI, _tokenId.toString(), ".json"));
    }
    
    function royaltyInfo (
    uint256 _tokenId,
    uint256 _salePrice
     ) external view returns (
        address receiver,
        uint256 royaltyAmount
     ){
         return (royaltyReceiver, calculateRoyalty(_salePrice));
     }

    function calculateRoyalty(uint256 _salePrice) view public returns (uint256){
        return(_salePrice / 10000) * royaltyFeesInBips;
    }

    function setRoyaltyInfo (address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        royaltyReceiver = _receiver;
        royaltyFeesInBips = _royaltyFeesInBips;
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    //ReleaseALL
    function releaseAll() external onlyOwner {
        for(uint i = 0 ; i < teamLength ; i++) {
            release(payable(payee(i)));
        }
    }

    receive() override external payable {
        revert('Only if you mint');
    }

}