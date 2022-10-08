// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721AV4.sol";

contract MysteriousEgg is ERC721A, Ownable, ReentrancyGuard {
    uint256 public MAX_SUPPLY = 444;
    uint256 public MINT_LIMIT = 1;

    uint256 public WL_PRICE = 0.02 ether;
    uint256 public PUBLIC_PRICE = 0.03 ether;

    enum SaleState {
        Closed,
        WlSale,
        PublicSale
    }

    SaleState private saleState = SaleState.Closed;

    bool _revealed = false;
    string private baseURI = "https://nftstorage.link/ipfs/bafkreiezxveasc5golp3mkxp2bezyqnhtgut6pgpzvq6wsxhs44shjozrm";

    bytes32 wlRoot;

    address public constant DEV_ADDRESS = 0x033AbDd37403eDA919dEfB17eee9D619B6d91AE0; 
    address public constant PROJECT_ADDRESS = 0x58613D4a7DFF82345CF5708BE052fda367286152; 
    address public constant TEAM_ADDRESS = 0x9e43d1a79517992d0683490b58e1F3B0ecb4D61E; 
  

    constructor() ERC721A("MysteriousEgg", "MysteriousEgg") {}

    modifier isSecured(uint8 mintType) {
        require(tx.origin == msg.sender,"CONTRACTS_NOT_ALLOWED_TO_MINT");

        if(mintType == 1) {
            require(saleState == SaleState.WlSale, "WL_MINT_IS_NOT_YET_ACTIVE");
        }

        if(mintType == 2) {
            require(saleState == SaleState.PublicSale, "PUBLIC_MINT_IS_NOT_YET_ACTIVE");
        }
        _;
    }

    function hatchAllowedEgg(bytes32[] memory proof) external isSecured(1) payable{
        require(MerkleProof.verify(proof, wlRoot, keccak256(abi.encodePacked(msg.sender))),"PROOF_INVALID");
        require(1 + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(numberMinted(msg.sender) + 1 <= MINT_LIMIT,"ONLY_1_IS_ALLOWED");
        require(msg.value == WL_PRICE, "WRONG_ETH_VALUE");
        _safeMint(msg.sender, 1);
    }

    function hatchPublicEgg() external isSecured(2) payable {
        require(numberMinted(msg.sender) + 1 <= MINT_LIMIT,"ONLY_1_IS_ALLOWED");
        require(1 + totalSupply() <= MAX_SUPPLY,"NOT_ENOUGH_SUPPLY");
        require(msg.value == PUBLIC_PRICE, "WRONG_ETH_VALUE");
        _safeMint(msg.sender, 1);
    }

    // URI
    function setBaseURI(string calldata URI) external onlyOwner {
        baseURI = URI;
    }

    function reveal(bool revealed, string calldata _baseURI) public onlyOwner {
        _revealed = revealed;
        baseURI = _baseURI;
    }

    // SALE STATE FUNCTIONS
    function togglePublicMintStatus() external onlyOwner {
        saleState = SaleState.PublicSale;
    }

    function toggleWlMintStatus() external onlyOwner {
        saleState = SaleState.WlSale;
    }

    function getSaleState() public view returns (SaleState) {
        return saleState;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (_revealed) {
            return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        } else {
            return string(abi.encodePacked(baseURI));
        }
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    // ROOT SETTERS
    function setWLSaleRoot(bytes32 _wlRoot) external onlyOwner {
        wlRoot = _wlRoot;
    }

    // LIMIT SETTERS
    function setMintLimit(uint256 _mintLimit) external onlyOwner {
        MINT_LIMIT = _mintLimit;
    }

    // PRICE FUNCTIONS
    function setPublicPrice(uint256 _price) external onlyOwner {
        PUBLIC_PRICE = _price;
    }

    function setWlPrice(uint256 _price) external onlyOwner {
        WL_PRICE = _price;
    }

    function getWlMintPrice() public view returns (uint256) {
        return WL_PRICE;
    }

    function getPublicPrice() public view returns (uint256) {
        return PUBLIC_PRICE;
    }

    function _startTokenId() override internal view virtual returns (uint256) {
        return 1;
    }

    function mintForTeam(uint256 numberOfTokens) external onlyOwner {
        _safeMint(msg.sender, numberOfTokens);
    }

    // withdraw
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        uint256 acc_a = (balance * 1200) / 10000;
        uint256 acc_b = (balance * 4500) / 10000;
        payable(DEV_ADDRESS).transfer(acc_a);
        payable(PROJECT_ADDRESS).transfer(acc_b);
        payable(TEAM_ADDRESS).transfer(address(this).balance);
    }
}