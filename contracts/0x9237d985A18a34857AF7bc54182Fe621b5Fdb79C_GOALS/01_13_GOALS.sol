// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import './ERC721A.sol';

/**
 * @title GOALS contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract GOALS is Ownable, ERC721A {
    uint256 public constant maxSupply = 3500;

    uint32 public freemintStartTime = 0;
    uint32 public premintStartTime = 0;
    uint32 public mintStartTime = 0;

    constructor() ERC721A("GOALS", "GOALS") {}

    uint256 public premintPrice = 0.1 ether;
    uint256 public mintPrice = 0.125 ether;
    uint256 public maxLimitForPreMint = 5;
    uint256 public maxLimitForMint = 10;    
    uint256 public maxAmountPerTx = 5;
    uint256 public totalFreeMinted;

    mapping (address => uint256) public freeMinted;
    mapping (address => uint256) public preMinted;

    address private admin = 0x0C484fc3e5412440E2bA69DF95e69b3C4D0CF0D0;

    string public constant CONTRACT_NAME = "Goals Contract";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant FREEMINT_TYPEHASH = keccak256("Freemint(address user,uint256 amount)");
    bytes32 public constant PREMINT_TYPEHASH = keccak256("Premint(address user,uint256 amount)");

    address private wallet1 = 0x120BcA4E677F0415fC6Ccc592484b4259d069f16;
    address private wallet2 = 0x0450285a6d39B7F5d70e1224aB6d78132A3420CB;
    address private wallet3 = 0x7F6Ef05ab28282e79Da43AbBCd834C9eFa79d618;
    address private wallet4 = 0x5cFc7754228890cf35534e7B8E981E5CD5758e9F;
    address private wallet5 = 0xBfD0f9b82FE6AE50444469e9D7a1e5f1140D7cf8;

    function setFreemintStartTime(uint32 newTime) public onlyOwner {
        freemintStartTime = newTime;
    }

    function setPremintStartTime(uint32 newTime) public onlyOwner {
        premintStartTime = newTime;
    }

    function setMintStartTime(uint32 newTime) public onlyOwner {
        mintStartTime = newTime;
    }

    function setPremintPrice(uint256 newPrice) external onlyOwner {
        premintPrice = newPrice;
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setMaxLimitForPreMint(uint256 newLimit) external onlyOwner {
        maxLimitForPreMint = newLimit;
    }

    function setMaxLimitForMint(uint256 newLimit) external onlyOwner {
        maxLimitForMint = newLimit;
    }

    /**
     * metadata URI
     */
    string private _baseURIExtended = "";

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    /**
     * withdraw
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(wallet1), balance * 20 / 100);
        Address.sendValue(payable(wallet2), balance * 15 / 100);
        Address.sendValue(payable(wallet3), balance * 5 / 100);
        Address.sendValue(payable(wallet4), balance * 10 / 100);
        Address.sendValue(payable(wallet5), address(this).balance);
    }

    /**
     * reserve
     */
    function reserve(uint256 amount, address account) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "Exceeds total supply");
        
        _safeMint(account, amount);
    }

    /**
     * Free mint
     */
    function freemint(uint amount, uint8 v, bytes32 r, bytes32 s) external {
        require(msg.sender == tx.origin, "User wallet required");
        require(freemintStartTime != 0 && freemintStartTime <= block.timestamp, "freemint not started");        
        require(premintStartTime == 0 || block.timestamp < premintStartTime, "premint started already.");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(FREEMINT_TYPEHASH, msg.sender, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        uint256 mintableAmount = amount;
        
        uint256 availableSupply = maxSupply - totalSupply();
        mintableAmount = Math.min(mintableAmount, availableSupply);

        freeMinted[msg.sender] = freeMinted[msg.sender] + mintableAmount;
        _safeMint(msg.sender, mintableAmount);
    }

    function premint(uint amount, uint8 v, bytes32 r, bytes32 s) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(premintStartTime != 0 && premintStartTime <= block.timestamp, "presales not started");        
        require(mintStartTime == 0 || block.timestamp < mintStartTime, "sales started already.");
        require(totalSupply() < maxSupply, "Exceeds max supply");
        require(amount <= maxAmountPerTx, "Exceeds max amount per mint");

        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(CONTRACT_NAME)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PREMINT_TYPEHASH, msg.sender, amount));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        uint256 mintableAmount = Math.min(amount, maxLimitForPreMint - preMinted[msg.sender]);
        
        uint256 availableSupply = maxSupply - totalSupply();
        mintableAmount = Math.min(mintableAmount, availableSupply);

        uint256 totalMintCost = mintableAmount * premintPrice;
        require(msg.value >= totalMintCost, "Not enough ETH sent; check price!"); 

        preMinted[msg.sender] = preMinted[msg.sender] + mintableAmount;
        _safeMint(msg.sender, mintableAmount);

        // Refund unused fund
        uint256 changes = msg.value - totalMintCost;
        if (changes != 0) {
            Address.sendValue(payable(msg.sender), changes);
        }
    }

    function mint(uint amount) external payable {
        require(msg.sender == tx.origin, "User wallet required");
        require(mintStartTime != 0 && mintStartTime <= block.timestamp, "sales not started");
        require(totalSupply() < maxSupply, "Exceeds max supply");
        require(amount <= maxAmountPerTx, "Exceeds max amount per mint");

        uint256 mintableAmount = Math.min(amount, maxLimitForMint - (balanceOf(msg.sender) - freeMinted[msg.sender] - preMinted[msg.sender]));

        // check to ensure amount is not exceeded MAX_SUPPLY
        uint256 availableSupply = maxSupply - totalSupply();
        mintableAmount = Math.min(mintableAmount, availableSupply);

        uint256 totalMintCost = mintableAmount * mintPrice;
        require(msg.value >= totalMintCost, "Not enough ETH sent; check price!"); 

        _safeMint(msg.sender, mintableAmount);

        // Refund unused fund
        uint256 changes = msg.value - totalMintCost;
        if (changes != 0) {
            Address.sendValue(payable(msg.sender), changes);
        }
    }

    function publicMinted(address account) external view returns (uint) {
        return balanceOf(account) - freeMinted[account] - preMinted[account];
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}