// SPDX-License-Identifier: MIT
// Creator: twitter.com/runo_dev

/*
,--.   ,--. ,-----.  ,-----. ,--.  ,--.,--------.,--. ,--.,------. ,--------.,--.   ,------.,-------. 
|   `.'   |'  .-.  ''  .-.  '|  ,'.|  |'--.  .--'|  | |  ||  .--. ''--.  .--'|  |   |  .---'`--.   /  
|  |'.'|  ||  | |  ||  | |  ||  |' '  |   |  |   |  | |  ||  '--'.'   |  |   |  |   |  `--,   /   /   
|  |   |  |'  '-'  ''  '-'  '|  | `   |   |  |   '  '-'  '|  |\  \    |  |   |  '--.|  `---. /   `--. 
`--'   `--' `-----'  `-----' `--'  `--'   `--'    `-----' `--' '--'   `--'   `-----'`------'`-------' 
*/

// Moonturtlez - ERC-721A based NFT contract

pragma solidity ^0.8.4;

import "../lib/ERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Moonturtlez is ERC721A, Ownable, ReentrancyGuard {
    address private constant _creator1 = 0x1Be2797e7c6717A86dF9D72E5e307911410B55Cc;
    address private constant _creator2 = 0xE2BFf72848B50e2385E63c23681695e990eC42cb;
    address private constant _creator3 = 0x4E309329764DFb001d52c08FAe14e46a745Df506;

    using MerkleProof for bytes32[];

    string private _baseTokenURI;
    bool private _saleStatus = false;
    uint256 private _salePrice = 0.024 ether;
    
	bytes32 private _claimMerkleRoot;

    mapping(address => bool) private _mintedClaim;

    uint256 private MAX_MINTS_PER_TX = 20;
    uint256 private MINT_PER_FREE_TX = 1;
	
    uint256 public MAX_SUPPLY = 8888;
    uint256 public FREE_SUPPLY = 888;
	

    constructor() ERC721A("Moonturtlez", "MOONTURTLE") {}

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier verify(
        address account,
        bytes32[] calldata merkleProof,
        bytes32 merkleRoot
    ) {
        require(
            merkleProof.verify(
                merkleRoot,
                keccak256(abi.encodePacked(account))
            ),
            "Address not listed"
        );
        _;
    }

    function setBaseURI(string calldata newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function setClaimMerkleRoot(bytes32 root) external onlyOwner {
        _claimMerkleRoot = root;
    }

    function setMaxMintPerTx(uint256 maxMint) external onlyOwner {
        MAX_MINTS_PER_TX = maxMint;
    }

    function setSalePrice(uint256 price) external onlyOwner {
        _salePrice = price;
    }
    
    function setFreeSupply(uint256 newSupply) external onlyOwner {
        if (newSupply >= FREE_SUPPLY) {
            revert("New supply exceed previous free supply");
        }
        FREE_SUPPLY = newSupply;
    }

    function toggleSaleStatus() external onlyOwner {
        _saleStatus = !_saleStatus;
    }

    function withdrawAll() external onlyOwner {
        uint256 amountToCreator2 = (address(this).balance * 100) / 1000; // 10%
        uint256 amountToCreator3 = (address(this).balance * 50) / 1000; // 5%

        withdraw(_creator2, amountToCreator2);
        withdraw(_creator3, amountToCreator3);

        uint256 amountToCreator1 = address(this).balance; // ~85%
        withdraw(_creator1, amountToCreator1);
    }

    function withdraw(address account, uint256 amount) internal {
        (bool os, ) = payable(account).call{value: amount}("");
        require(os, "Failed to send ether");
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function claimMint(bytes32[] calldata merkleProof)
        external
        nonReentrant
        callerIsUser
        verify(msg.sender, merkleProof, _claimMerkleRoot)
    {
        if (!isSaleActive()) revert("Sale not started");
        if (hasMintedClaim(msg.sender)) revert("Amount exceeds claim limit");
        if (totalSupply() + MINT_PER_FREE_TX > (MAX_SUPPLY - FREE_SUPPLY)) revert("Amount exceeds supply");
        _mintedClaim[msg.sender] = true;
        _safeMint(msg.sender, MINT_PER_FREE_TX);
    }

    function saleMint(uint256 quantity)
        external
        payable
        nonReentrant
        callerIsUser
    {
        if (!isSaleActive()) revert("Sale not started");
        if (quantity > MAX_MINTS_PER_TX)
            revert("Amount exceeds transaction limit");
        if (totalSupply() + quantity > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");
        if (getSalePrice() * quantity > msg.value)
            revert("Insufficient payment");

        _safeMint(msg.sender, quantity);
    }

    function walletOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 0;
        uint256 ownedTokenIndex = 0;
        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= totalSupply()
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);
            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;
                ownedTokenIndex++;
            }
            currentTokenId++;
        }
        return ownedTokenIds;
    }

    function mintToAddress(address to, uint256 quantity) external onlyOwner {
        if (totalSupply() + quantity > (MAX_SUPPLY - FREE_SUPPLY))
            revert("Amount exceeds supply");

        _safeMint(to, quantity);
    }

    function getClaimMerkleRoot() external view returns (bytes32) {
        return _claimMerkleRoot;
    }

    function isSaleActive() public view returns (bool) {
        return _saleStatus;
    }

    function getSalePrice() public view returns (uint256) {
        return _salePrice;
    }

    function hasMintedClaim(address account) public view returns (bool) {
        return _mintedClaim[account];
    }
}