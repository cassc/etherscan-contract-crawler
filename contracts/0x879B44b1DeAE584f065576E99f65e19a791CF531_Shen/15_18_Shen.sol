// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721MT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Shen is DefaultOperatorFilterer, ERC721MT, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 5555;

    uint256 public constant MAX_WL_SUPPLY = 3000;
    uint256 public constant MAX_WL_MINT = 5;

    uint256 public constant MAX_FM_SUPPLY = 300;

    uint256 public WL_MINT_START = 1672772400;
    uint256 public FREE_MINT_START = WL_MINT_START + 1 hours;
    uint256 public PUBLIC_MINT_START = FREE_MINT_START + 3 hours;

    address public constant TEAM_WALLET = address(0x53226df5BE0dA81e9D495B6168db190C12De87Fa);

    string private _baseTokenURI = "https://shennft.mypinata.cloud/ipfs/QmaRvTd2ZDquUM9SYMJePoPRYiUF1TwwpNGwAx9RBt2JYU/";

    uint256 public constant WL_PRICE = 0.02 ether;
    uint256 public constant PUBLIC_PRICE = 0.04 ether;

    bytes32 public merkleRoot = 0x671f6320b86bec49823aa5c391d54ec36c7e10b99849975926bf19d6ac2d642f;

    bool public isWlSaleActive = false;
    bool public isFreeMintActive = false;
    bool public isPublicSaleActive = false;
    bool public freeMintActive = true;

    uint256 public fmCount = 0;

    uint256 public wlMintedCount = 0;
    uint256 public freeMintedCount = 0;

    mapping(address => bool) public isWL;
    mapping(address => uint256) public wlMints;
    mapping(address => uint256) public freeMintCount; 

    constructor() ERC721MT("Shen", "SHEN") {}

    function mint(uint256 numberOfTokens) external payable {
        require(msg.sender == tx.origin, "LilShen: Contracts can't mint");
        require(isPublicSaleActive || block.timestamp >= PUBLIC_MINT_START, "LilShen: Mint is not active");
        if (freeMintActive) {
            require(totalSupply() - freeMintedCount < MAX_SUPPLY - fmCount, "LilShen: Sold Out");
            require((fmCount == freeMintedCount && totalSupply() + numberOfTokens <= MAX_SUPPLY) || (fmCount != freeMintedCount && totalSupply() - freeMintedCount + numberOfTokens < MAX_SUPPLY - fmCount), "LilShen: Exceed the max supply");
        } else {
            require(totalSupply() < MAX_SUPPLY, "LilShen: Sold Out");
            require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "LilShen: Exceed the max supply");
        }
        require(msg.value == getPrice(numberOfTokens), "LilShen: Wrong eth value");
        mintTokens(numberOfTokens);
    }

    function wlMint(uint256 numberOfTokens, bytes32[] calldata _merkleProof) external payable {
        require(msg.sender == tx.origin, "LilShen: Contracts can't mint");
        require(isWlSaleActive || block.timestamp >= WL_MINT_START, "LilShen: WL Mint is not active");

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "LilShen: User not whilisted");

        require(numberOfTokens + wlMints[msg.sender] <= MAX_WL_MINT, "LilShen: Would exceed WL purchase limit");

        require(wlMintedCount < MAX_WL_SUPPLY, "LilShen: WL SoldOut");
        require(totalSupply() - freeMintedCount < MAX_SUPPLY - fmCount, "LilShen: Sold Out");
        require((fmCount == freeMintedCount && totalSupply() + numberOfTokens <= MAX_SUPPLY) || (fmCount != freeMintedCount && totalSupply() - freeMintedCount + numberOfTokens < MAX_SUPPLY - fmCount), "LilShen: Exceed the max supply");
        require(msg.value == getWlPrice(numberOfTokens), "LilShen: Wrong eth value");
        wlMints[msg.sender] += numberOfTokens;
        wlMintedCount += numberOfTokens;
        mintTokens(numberOfTokens);
    }

    function freeMint(uint256 numberOfTokens) external {
        require(msg.sender == tx.origin, "LilShen: Contracts can't mint");
        require(isFreeMintActive || block.timestamp >= FREE_MINT_START , "LilShen: Free Mint is not active");
        require(totalSupply() < MAX_SUPPLY, "LilShen: Sold Out");
        require(totalSupply() + numberOfTokens <= MAX_SUPPLY, "LilShen: Exceed the max supply");
        require(numberOfTokens <= freeMintCount[msg.sender], "LilShen: Too much free mint requested");
        freeMintCount[msg.sender] -= numberOfTokens;
        freeMintedCount += numberOfTokens;
        mintTokens(numberOfTokens);
    }

    function reserveTokens(uint256 quantity) public onlyOwner {
        require(totalSupply() + quantity <= MAX_SUPPLY, "LilShen: Exceed the max supply");
        mintTokens(quantity);
    }

    function getPrice(uint256 quantity) public view returns (uint256) {
        return PUBLIC_PRICE * quantity;
    }

    function getWlPrice(uint256 quantity) public view returns (uint256) {
        return WL_PRICE * quantity;
    }

    function walletOfOwner(address address_) public view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        for (uint256 i = 1; i <= (totalSupply()); i++) {
            if (_exists(i)) {
                if (address_ == ownerOf(i)) {
                    _tokens[_index] = i;
                    _index++;
                }
            }
        }
        return _tokens;
    }

    /* === Owner === */

    function changeState(bool _isWlSaleActive, bool _isFreeMintActive, bool _isPublicSaleActive) external onlyOwner {
        isWlSaleActive = _isWlSaleActive;
        isFreeMintActive = _isFreeMintActive;
        isPublicSaleActive = _isPublicSaleActive;
    }

    function toggleFreeMint() external onlyOwner {
        freeMintActive = !freeMintActive;
    }

    function addFreeMintBatch(address[] calldata users) external onlyOwner {
        for(uint256 i = 0 ; i < users.length ; i++) {
            freeMintCount[users[i]] = 1;
        }
        fmCount += users.length;
    }

    function addMultipleFreeMint(address user, uint32 qty) external onlyOwner {
        freeMintCount[user] = qty;
        fmCount += qty;
    }

    function changeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function addWlBatch(address[] calldata users) external onlyOwner {
        for(uint256 i = 0 ; i < users.length ; i++) {
            isWL[users[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        require(payable(TEAM_WALLET).send(address(this).balance));
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _baseTokenURI = URI;
    }

    /* === Core === */

    function mintTokens(uint256 quantity) private {
        _mint(msg.sender, quantity);
    }

    /* === Required Override === */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721MT) returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
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

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}