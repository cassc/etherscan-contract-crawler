// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract UnknownSociety is DefaultOperatorFilterer, ERC721A, Ownable, ReentrancyGuard {
    enum SaleStage{ INACTIVE, WHITELIST, SOLDOUT }
    enum MintType{ TEAM, WHITELIST, AIRDROP }

    string private _URI = "https://unknown777.net/nft/metadata/unrevealed.json?";
    address private signer;
    uint256 private salePrice = 0.069 ether;
        
    SaleStage public saleStage = SaleStage.INACTIVE;
    uint256 public constant MAX_SUPPLY = 777;
    uint256 public constant maxPerWallet = 1;
    mapping(MintType => uint256) public supply;
    mapping(MintType => uint256) public minted;
    mapping(address => uint256) public walletMint;

    struct Airdrop {
        address holder;
        uint256 amount;
    }

    event Minted(address sender, uint amount, MintType mintType);

    constructor() ERC721A("Unknown Society", "UNK") {
        signer = msg.sender;
        supply[MintType.TEAM] = 10;
        supply[MintType.WHITELIST] = 767;
    }

    function setSaleStage(SaleStage _newStage) external onlyOwner {
        saleStage = _newStage;
    }

    function setPrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    function adjustSupply(MintType _type, uint256 _newSupply) external onlyOwner {
        require(_newSupply + 1 > minted[_type], "Cannot adjust supply below minted");
        supply[_type] = _newSupply;
    }

    function setBaseURI(string memory _newURI) external onlyOwner {
        _URI = _newURI;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _URI;
    }

    function ownerMint(MintType _type, address receiver, uint256 amount)
    external
    validateSupply(_type, amount)
    onlyOwner
    {
        minted[_type] += amount;
        _mint(receiver, amount);
        emit Minted(receiver, amount, _type);
    }

    function whitelistMint(bytes calldata signature, uint256 amount)
    external
    payable
    validateMint(SaleStage.WHITELIST, amount)
    validateSupply(MintType.WHITELIST, amount)
    nonReentrant
    {
        require(_isVerifiedSignature(signature), "Invalid Signature");
        minted[MintType.WHITELIST] += amount;
        walletMint[msg.sender] += amount;
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount, MintType.WHITELIST);
    }

    function sendAirdrop(Airdrop[] memory _aidrops)
    external
    onlyOwner
    {
        for (uint256 i = 0; i < _aidrops.length; ++i) {
            minted[MintType.AIRDROP] += _aidrops[i].amount;
            _mint(_aidrops[i].holder, _aidrops[i].amount);
        }
    }

    function _isVerifiedSignature(bytes calldata signature)
    internal
    view
    returns (bool)
    {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                bytes32(uint256(uint160(msg.sender)))
            )
        );
        return ECDSA.recover(digest, signature) == signer;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
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

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier validateSupply(MintType _type, uint256 amount) {
        require(minted[_type] + amount < supply[_type] + 1, "Mint would exceed supply");
        require(totalSupply() + amount < MAX_SUPPLY + 1, "Mint would exceed max supply");
        _;
    }

    modifier validateMint(SaleStage _stage, uint256 amount) {
        require(_stage != SaleStage.SOLDOUT, "Sold Out");
        require(_stage == saleStage, "Current type of sale is not active");
        require(walletMint[msg.sender] + amount < maxPerWallet + 1, "Max mint per wallet");
        require(msg.value >= salePrice * amount, "Ether value sent is not correct");
        _;
    }
}