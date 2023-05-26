//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PettoKado is ERC721A, Ownable {
    // ====== Variables ======
    enum SalePhase {
        OG,
        Whitelist,
        Public
    }
    SalePhase public phase;
    string private baseURI;
    string private token;
    string private withdrawalAddress;
    uint256 private MAX_SUPPLY = 3333;
    uint256 public mintQuantity = 2;
    uint256 public mintPrice = 0.018 ether;
    mapping(address => bool) public allowList;
    bool public startMint = false;
    bool public reveal = false;

    constructor() ERC721A("Petto NFT", "PETTO") {}

    // ====== Basic Setup ======
    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setReveal() external onlyOwner {
        reveal = true;
    }

    // ====== Mint Settings ======
    function setPhase(SalePhase _phase) external onlyOwner {
        phase = _phase;
    }

    function setMintPrice(uint256 _price) external onlyOwner {
        mintPrice = _price;
    }

    function setMintQuantity(uint256 _quantity) external onlyOwner {
        mintQuantity = _quantity;
    }

    function setToStartMint(bool _status) external onlyOwner {
        startMint = _status;
    }

    function setToken(string memory _token) external onlyOwner {
        token = _token;
    }

    function setWithdrawalAddress(string memory _address) external onlyOwner {
        withdrawalAddress = _address;
    }

    // ====== Minting ======
    function ownerMint(uint256 _quantity) external payable onlyOwner {
        // *** Checking conditions ***
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Reach maximum supply."
        );

        // *** _safeMint's second argument now takes in a quality but not tokenID ***
        _safeMint(msg.sender, _quantity);
    }

    // ====== Minting ======
    function isMintStart() public view returns (bool) {
        if (!startMint) return false;
        return true;
    }

    function checkToken(string memory _token) public view returns (bool) {
        return keccak256(bytes(_token)) == keccak256(bytes(token));
    }

    function checkPrice(
        uint256 _value,
        uint256 _quantity
    ) public view returns (bool) {
        uint256 requiredPrice = mintPrice * _quantity;
        if (_value >= requiredPrice) {
            return true;
        }

        return false;
    }

    function mint(uint256 _quantity, string memory _token) external payable {
        // *** Checking conditions ***
        // Check Minting State
        bool isMintPhaseStart = isMintStart();
        require(isMintPhaseStart, "Minting is not active yet.");
        // Check Maximum Supply
        require(
            totalSupply() + _quantity <= MAX_SUPPLY,
            "Reach maximum supply."
        );
        // Check Number of mint
        require(
            _numberMinted(msg.sender) + _quantity <= mintQuantity,
            "Reach maximum minting limit."
        );
        // Check Price
        bool isPriceEnough = checkPrice(msg.value, _quantity);
        require(isPriceEnough, "Not enough ETH to mint.");
        // Check Token
        bool isTokenPass = checkToken(_token);
        require(isTokenPass, "Token is invalid.");

        // *** _safeMint's second argument now takes in a quality but not tokenID ***
        _safeMint(msg.sender, _quantity);
    }

    // ====== Token URI ======
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "Token ID is not exist.");
        if (!reveal) {
            return string(abi.encodePacked(baseURI, "hatching.json"));
        }
        return
            string(
                abi.encodePacked(
                    baseURI,
                    Strings.toString(_tokenId + 1),
                    ".json"
                )
            );
    }

    // ====== Withdraw ======
    function withdraw(address payable to) public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No balance to withdraw");
        to.transfer(balance);
    }
}