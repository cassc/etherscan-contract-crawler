pragma solidity >=0.6.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; 
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Allowlist.sol";
import "./PaymentSplitter.sol"; 

contract HappySloths is ERC721A, Ownable, ReentrancyGuard, Allowlist, PaymentSplitter {

    string public        baseURI;
    uint public          price             = 0 ether;
    uint public          maxPerTx          = 2;
    uint public          maxPerWallet      = 2;
    uint public          maxSupply         = 3333;
    uint public          reservedSupply    = 100;
    bool public          mintEnabled       = false;
    bool public          teamClaimed       = false;

    address[] private _payees = [
        0x3183226D0616E15d98C171cc6C9Af22E8cb08Ccf,
        0x793c5393c12E7c361375771e12e9FdE5B55Fb25E
    ];

    uint256[] private _shares = [
        60,
        40
    ];

    constructor(bytes32 _merkleRoot) 
    ERC721A("Happy Sloths", "HAPPYS")
    PaymentSplitter(_payees, _shares) {
        merkleRoot = _merkleRoot;
        _safeMint(_payees[0], 1);
    }

    function mint(uint256 amt) external payable
    {
        require(mintEnabled, "Minting is not live yet");
        require( amt < maxPerTx + 1, "Max per TX reached.");
        require(_numberMinted(_msgSender()) < maxPerWallet, "Don't be greedy");
        require(totalSupply() + amt < maxSupply + 1, "Max supply reached");

        _safeMint(msg.sender, amt);
    }

    function mintToAL(address _to, bytes32[] calldata _merkleProof) public {
        require(onlyAllowlistMode == true, "Allowlist minting is closed");
        require(isAllowlisted(_to, _merkleProof), "Address is not in Allowlist!");
        require(_numberMinted(_msgSender()) < maxPerWallet, "Don't be greedy");        

        _safeMint(_to, 1);
    }

    function enableMint()  external onlyOwner {
        onlyAllowlistMode = false;
        mintEnabled = true;
    }

    function toggleMinting() external onlyOwner {
        mintEnabled = !mintEnabled;
    }

    function teamClaim() external {
        require(teamClaimed == false);

        _safeMint(_payees[0], 49);
        _safeMint(_payees[1], 50);

        teamClaimed = true;
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setPrice(uint256 price_) external onlyOwner {
        price = price_;
    }

    function setMaxPerTx(uint256 maxPerTx_) external onlyOwner {
        maxPerTx = maxPerTx_;
    }

    function setmaxSupply(uint256 maxSupply_) external onlyOwner {
        maxSupply = maxSupply_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() external nonReentrant {
        release(payable(_payees[0]));
        release(payable(_payees[1]));
    }
}