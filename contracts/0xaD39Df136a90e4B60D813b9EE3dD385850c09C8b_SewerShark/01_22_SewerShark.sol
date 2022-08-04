// SPDX-License-Identifier: UNLICENSED
// Creator: owenyuwono.eth
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "erc721a/contracts/ERC721A.sol";
import "./lib/MerkleTree.sol";
import "hardhat/console.sol";

contract SewerShark is ERC721A, PaymentSplitter, Ownable, AccessControl, Pausable, ReentrancyGuard, MerkleTree {
    using Strings for uint256;
    // Supply
    uint public maxTotalSupply = 6969;
    mapping(address => uint) public claimed;

    // Metadata
    string public _tokenUri;

    // Toggle
    bool public isOpen;

    // Payments
    address[] public _payees = [
        0x2961dA73F6e08EeE37EC3F488e9008004F90BbDC,
        0xF98C718B0BF6A331265CC504bfc12Ac749DcBdC6
    ];
    uint256[] private _shares = [10, 90];

    constructor (string memory tokenUri_) ERC721A("SewerShark", "SS") PaymentSplitter(_payees, _shares) {
        _transferOwnership(0xF98C718B0BF6A331265CC504bfc12Ac749DcBdC6);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _tokenUri = tokenUri_;
    }

    error InsufficientFund(uint256 price, uint256 value);
    error ExceededMaxSupply(uint maxSupply);
    error AmountTooLittle();
    error NotOpenYet();
    error Unauthorized();

    // Mint
    function getPrice(bool isAllowed, uint amount) public view returns (uint256) {
        uint minted = claimed[msg.sender];
        uint free = isAllowed ? 2: 1;
        
        uint r = amount;
        uint256 p = 0;

        if(minted < free) {
            uint t0 = free - minted;
            minted += r <= t0? r: t0;
            r -= r <= t0? r: t0;
        }
        if(minted < 10 + free && r > 0) {
            uint t1 = r > 10 + free - minted? 10 + free - minted: r;
            p += t1 * 0.01 ether;
            minted += t1;
            r -= t1;
        }
        if(r > 0) {
            p += r * 0.02 ether;
            minted += r;
            r = 0;
        }
        require(r == 0, "invalid calculation");
        return p;
    }

    function mint(uint amount, bytes32[] calldata proof) external payable whenNotPaused nonReentrant {
        uint256 supply = totalSupply();
        uint256 price = getPrice(isAllowed(proof, msg.sender), amount);
        if(msg.value != price) revert InsufficientFund(price, msg.value);
        if(amount <= 0) revert AmountTooLittle();
        if(supply + amount > maxTotalSupply) revert ExceededMaxSupply(maxTotalSupply);
        if(!isOpen) revert NotOpenYet();

        claimed[msg.sender] += amount;
        _safeMint(msg.sender, amount);
    }

    // Admin
    function airdrop(address wallet, uint256 amount) external {
        uint256 supply = totalSupply();
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && msg.sender != owner()) revert Unauthorized();
        if(amount <= 0) revert AmountTooLittle();
        if(supply + amount > maxTotalSupply) revert ExceededMaxSupply(maxTotalSupply);

        _safeMint(wallet, amount);
    }

    // Minting fee
    function setOpen(bool value) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isOpen = value;
    }

    // Max Settings
    function setMaxSupply(uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxTotalSupply = amount;
    }

    // Payment
    function claim() external {
        release(payable(msg.sender));
    }

    // Allowlist
    function setMerkleRoot(bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setMerkleRoot(root);
    }

    // Metadata
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setTokenURI(string calldata uri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenUri = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        if (bytes(_tokenUri).length == 0) return "";

        return string(abi.encodePacked(_tokenUri, "/", tokenId.toString(), ".json"));
    }

    function supportsInterface(bytes4 interfaceId)
        public view virtual override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}