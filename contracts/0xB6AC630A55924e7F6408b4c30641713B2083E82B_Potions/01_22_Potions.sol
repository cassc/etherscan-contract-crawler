//SPDX-License-Identifier: Unlicense
// Creator: owenyuwono.eth
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "hardhat/console.sol";

contract Potions is ERC1155, ERC1155Supply, PaymentSplitter, Ownable, AccessControl, Pausable, ReentrancyGuard {
    using Strings for uint256;

    // Contract
    string public name = "POTIONS";
    string public symbol = "POTIONS";
    string public tokenURI;

    // Limits
    uint public maxSupply = 2661;
    uint public airdropCount = 1981;
    uint public minted = 0;
    uint public maxPerTx = 0;

    bool public isOpen;
    
    uint nonce;

    // Payment & Pricing
    uint256 public price = 0.12 ether;
    address[] public PAYEES = [
        0x2961dA73F6e08EeE37EC3F488e9008004F90BbDC,
        0x9B0C5c21BA4D452934Ad4c1cb314fbcfCA132c7A
    ];
    uint256[] private SHARES = [5, 95];

    constructor (string memory tokenUri) ERC1155(tokenUri) PaymentSplitter(PAYEES, SHARES) {
        _transferOwnership(0x9B0C5c21BA4D452934Ad4c1cb314fbcfCA132c7A);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        tokenURI = tokenUri;
    }

    error MaxRarity();
    error InsufficientPotions();
    error InvalidPotionId();
    error InsufficientFunds();
    error InvalidAmount();
    error ExceedMaxSupply();
    error NotOpenYet();
    error ExceedMaxPerTx();

    modifier isValid(uint256 id) {
        if(id > 2) revert InvalidPotionId();
        _;
    }

    modifier canMint(uint amount) {
        if(amount < 1) revert InvalidAmount();
        _;
    }

    modifier whenOpen() {
        if(!isOpen) revert NotOpenYet();
        _;
    }

    function mint(uint amount) external payable canMint(amount) whenOpen {
        if(msg.value != amount * price) revert InsufficientFunds();
        if(minted + amount > maxSupply - airdropCount) revert ExceedMaxSupply();
        if(maxPerTx != 0 && amount > maxPerTx) revert ExceedMaxPerTx();

        uint256[] memory ids;
        uint256[] memory amts;
        (ids, amts) = generateId(amount);

        minted += amount;
        _mintBatch(msg.sender, ids, amts, "");
    }

    function generateId(uint amount) internal returns (uint256[] memory, uint256[] memory) {
        uint256[] memory amts = new uint256[](3);
        uint256[] memory ids = new uint256[](3);
        ids[0] = 0;
        ids[1] = 1;
        ids[2] = 2;
        for(uint i = 0; i < amount; i++) {
            uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 10000;
            nonce++;
            if(randomnumber < 42) amts[2]++;
            else if(randomnumber < 2500) amts[1]++;
            else if(randomnumber < 10000) amts[0]++;
        }
        return (ids, amts);
    }
    

    function upgrade(uint256 id, uint amount) external isValid(id) {
        if(id == 2) revert MaxRarity();
        if(balanceOf(msg.sender, id) < amount * 10) revert InsufficientPotions();
        _burn(msg.sender, id, amount * 10);
        _mint(msg.sender, id + 1, amount, "");
    }

    function burn(address owner, uint256 id, uint amount) external isValid(id) {
        _burn(owner, id, amount);
    }

    // Admin
    function airdrop(address[] calldata wallet, uint256[][] calldata id, uint256[][] calldata amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for(uint i = 0; i < wallet.length; i++) {
            _mintBatch(wallet[i], id[i], amount[i], "");
        }
    }

    function setTokenUri(string calldata v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenURI = v;
    }

    function setMaxSupply(uint v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxSupply = v;
    }
    function setMaxPerTx(uint v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxPerTx = v;
    }
    function setAirdropCount(uint v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        airdropCount = v;
    }
    function setOpen(bool v) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isOpen = v;
    }

    // Payment
    function claim() external {
        release(payable(msg.sender));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Essentials
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        if(id > 2) revert InvalidPotionId();
        if(bytes(tokenURI).length == 0) return "";

        return string(abi.encodePacked(tokenURI, "/", id.toString(), ".json"));
    }

    function totalSupply() public view returns (uint) {
        return totalSupply(0) + totalSupply(1) + totalSupply(2);
    }
}