// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MultiD is ERC721A, Ownable, ReentrancyGuard {
    enum SaleStage{ INACTIVE, PRESALE, PUBLIC }
    enum MintType{ TEAM, PRIZE, PRIVATE, PRESALE, PUBLIC }

    string private _URI = "https://kleks.academy/metadata/hidden.json?";
    address private signer;
    uint256 private presalePrice = 0.15 ether;
    uint256 private publicPrice = 0.2 ether;
        
    SaleStage public saleStage = SaleStage.INACTIVE;
    uint256 public constant MAX_SUPPLY = 12345;
    uint256 public constant maxPerWallet = 3;
    mapping(MintType => uint256) public supply;
    mapping(MintType => uint256) public minted;
    mapping(address => uint256) public walletMint;
    address public developer;

    event Minted(address sender, uint amount, MintType mintType);
    error InvalidSignature();

    constructor() ERC721A("Kleks Academy Multi-D NFT", "MultiDNFT") {
        signer = msg.sender;
        developer = msg.sender;
        supply[MintType.PRIZE] = 123;
        supply[MintType.TEAM] = 345;
        supply[MintType.PRIVATE] = 1234;
        supply[MintType.PRESALE] = 1234;
        supply[MintType.PUBLIC] = 2345;
    }

    function setSaleStage(SaleStage _newStage) external onlyOwnerOrDev {
        saleStage = _newStage;
    }

    function setPrice(uint256 _presalePrice, uint256 _publicPrice) external onlyOwnerOrDev {
        presalePrice = _presalePrice;
        publicPrice = _publicPrice;
    }

    function adjustSupply(MintType _type, uint256 _newSupply) external onlyOwnerOrDev {
        require(_newSupply + 1 > minted[_type], "Cannot adjust supply below minted");
        supply[_type] = _newSupply;
    }

    function setBaseURI(string memory _newURI) external onlyOwnerOrDev {
        _URI = _newURI;
    }

    function setDeveloper(address _developer) external onlyOwnerOrDev {
        developer = _developer;
    }

    function setSigner(address _signer) external onlyOwnerOrDev {
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

    function preSaleMint(bytes calldata signature, uint256 amount)
    external
    payable
    validateMint(SaleStage.PRESALE, amount)
    validateSupply(MintType.PRESALE, amount)
    nonReentrant
    {
        if(!_isVerifiedSignature(signature)) {
            revert InvalidSignature();
        }

        minted[MintType.PRESALE] += amount;
        walletMint[msg.sender] += amount;
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount, MintType.PRESALE);
    }

    function publicMint(uint256 amount)
    external
    payable
    validateMint(SaleStage.PUBLIC, amount)
    validateSupply(MintType.PUBLIC, amount)
    nonReentrant
    {
        minted[MintType.PUBLIC] += amount;
        walletMint[msg.sender] += amount;
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount, MintType.PUBLIC);
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

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    modifier onlyOwnerOrDev() {
        require(msg.sender == owner() || msg.sender == developer, "Invalid Access");
        _;
    }

    modifier validateSupply(MintType _type, uint256 amount) {
        require(minted[_type] + amount < supply[_type] + 1, "Mint would exceed supply");
        require(totalSupply() + amount < MAX_SUPPLY + 1, "Mint would exceed max supply of multi-D NFT");
        _;
    }

    modifier validateMint(SaleStage _stage, uint256 amount) {
        uint256 price = _stage == SaleStage.PRESALE ? presalePrice : publicPrice;
        require(_stage == saleStage, "Current type of sale is not active");
        require(walletMint[msg.sender] + amount < maxPerWallet + 1, "Can only mint 3 multi-D NFT per wallet");
        require(msg.value >= price * amount, "Ether value sent is not correct");
        _;
    }
}