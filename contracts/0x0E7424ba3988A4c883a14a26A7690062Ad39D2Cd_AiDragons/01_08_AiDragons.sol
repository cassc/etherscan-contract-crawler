//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AiDragons is ERC721A, Ownable {
    using SafeMath for uint256;

    bool public isMintActive = false;

    uint256 public price         = 0.1 ether;
    uint256 public maxSupply     = 1111;
    uint256 public maxMintsPerTx = 20;
    uint256 public maxMintsTotal = 20;

    string internal _baseTokenURI;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 private _royaltyAmount = 1000; // 10%

    // Team Addresses
    address public a1 = 0x4f1ABBABF5ad8D10D9F70f948389220Cd2f4E1df;
    address public a2 = 0x2fCe8DEAb97C3eC61f6707C174670EfbE243eBFd;
    address public a3 = 0xce08cF4505306A3848814bfb639bD6FE421d3034;
    address public a4 = 0xca34072FE89563cc1af5a0DacAaDbEDC250950a5;
    address public a5 = 0x6b1451Cd703F82ebb4c8898C8CFC8c4173689992;
    address public a6 = 0x0f375cAAD3b434C3CD509f8b1f539c169Ec9583e;
    address public a7 = 0x58a4e27004b940d4Db4716Bdb72005785afb7D5c;
    address public a8 = 0x9De89422AA486f9Cb30aA308DE9642B5BDe9AD1E;
    address public a9 = 0x26A427500e5cb29DAA3eA1ef781021a00eAfa626;

    // Project Wallet
    address public aMulti = 0x2bb93997e9981452D0D8f19b332c2500344358fA;

    struct Whitelist {
        bool isActive;
        uint256 price;
        uint256 maxMints;
        bytes32 merkleRoot;
    }

    Whitelist[] internal _whitelists;

    mapping(uint256 => mapping(address => uint256)) internal _whitelistsMints;

    constructor(string memory baseTokenURI) ERC721A("AiDragons", "AIDRAGON") {
        _baseTokenURI = baseTokenURI;
    }


    //----------------------------------------
    // Mint / Ownership (public)
    //----------------------------------------

    function tokensOf(address _owner) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(_owner));
        uint256 ctr = 0;
        for (uint256 i = 0; i < totalSupply(); i++) {
            if (ownerOf(i) == _owner) {
                tokens[ctr] = i;
                ctr++;
            }
        }
        return tokens;
    }

    function numberMintedOf(address _owner) public view returns (uint256) {
        return _numberMinted(_owner);
    }

    function mint(uint256 qty) external payable {
        require(isMintActive, "Mint isn't active");
        require(_numberMinted(msg.sender) + qty <= maxMintsTotal, "Exceeds mint limit");
        require(qty <= maxMintsPerTx && qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= maxSupply, "Exceeds total supply");
        require(msg.value == price * qty, "Invalid value");

        _safeMint(msg.sender, qty);
    }

    function mintWhitelist(uint256 whitelistIndex, uint256 qty, bytes32[] calldata merkleProof) external payable {
        Whitelist memory wl = _whitelists[whitelistIndex];

        require(wl.isActive, "Whitelist isn't active");
        require(_numberMinted(msg.sender) + qty <= maxMintsTotal, "Exceeds mint limit");
        require(qty <= maxMintsPerTx && qty > 0, "Qty of mints not allowed");
        require(qty + totalSupply() <= maxSupply, "Exceeds total supply");
        require(msg.value == wl.price * qty, "Invalid value");
        require(_whitelistsMints[whitelistIndex][msg.sender] + qty <= wl.maxMints, "Exceeds whitelist mint limit");

        require(MerkleProof.verify(
                merkleProof,
                wl.merkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ), "Criteria not on the whitelist");

        _safeMint(msg.sender, qty);
        _whitelistsMints[whitelistIndex][msg.sender] += qty;
    }


    //----------------------------------------
    // Whitelist (public)
    //----------------------------------------

    function whitelists() public view returns (Whitelist[] memory) {
        return _whitelists;
    }

    function whitelistMintsOf(uint256 whitelistIndex, address minterAddress) public view returns (uint256) {
        return _whitelistsMints[whitelistIndex][minterAddress];
    }

    function whitelistValidateMerkleProof(uint256 whitelistIndex, address minterAddress, bytes32[] calldata merkleProof) public view returns (bool) {
        Whitelist memory wl = _whitelists[whitelistIndex];

        return MerkleProof.verify(
            merkleProof,
            wl.merkleRoot,
            keccak256(abi.encodePacked(minterAddress))
        );
    }


    //----------------------------------------
    // Royalty (public)
    //----------------------------------------

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (aMulti, ((_salePrice * _royaltyAmount) / 10000));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }


    //----------------------------------------
    // Misc (owner)
    //----------------------------------------

    function getBaseTokenURI() public view onlyOwner returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function setMaxSupply(uint256 newSupply) external onlyOwner {
        maxSupply = newSupply;
    }

    function toggleMintActive() external onlyOwner {
        isMintActive = !isMintActive;
    }

    function setMaxMintsPerTx(uint256 newMax) external onlyOwner {
        maxMintsPerTx = newMax;
    }

    function setMaxMintsTotal(uint256 newMax) external onlyOwner {
        maxMintsTotal = newMax;
    }

    // Mint
    function giveaway(address[] calldata adds, uint256 qty) external onlyOwner {
        uint256 minted = totalSupply();

        require((adds.length * qty) + minted <= maxSupply, "Value exceeds total supply");

        for (uint256 i = 0; i < adds.length; i++) {
            _safeMint(adds[i], qty);
        }
    }

    // Whitelist
    function whitelistCreate(bool isActive, uint256 whitelistPrice, uint256 whitelistMaxMints, bytes32 merkleRoot) external onlyOwner {
        Whitelist storage whitelist = _whitelists.push();

        whitelist.isActive = isActive;
        whitelist.price = whitelistPrice;
        whitelist.maxMints = whitelistMaxMints;
        whitelist.merkleRoot = merkleRoot;
    }

    function whitelistToggleActive(uint256 whitelistIndex) external onlyOwner {
        _whitelists[whitelistIndex].isActive = !_whitelists[whitelistIndex].isActive;
    }

    function whitelistSetPrice(uint256 whitelistIndex, uint256 newPrice) external onlyOwner {
        _whitelists[whitelistIndex].price = newPrice;
    }

    function whitelistSetMaxMints(uint256 whitelistIndex, uint256 maxMints) external onlyOwner {
        _whitelists[whitelistIndex].maxMints = maxMints;
    }

    function whitelistSetMerkleRoot(uint256 whitelistIndex, bytes32 merkleRoot) external onlyOwner {
        _whitelists[whitelistIndex].merkleRoot = merkleRoot;
    }

    // Withdraw
    function withdrawTeam() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        _widthdraw(a1, balance.mul(5).div(100));
        _widthdraw(a2, balance.mul(4).div(100));
        _widthdraw(a3, balance.mul(5).div(100));
        _widthdraw(a4, balance.mul(4).div(100));
        _widthdraw(a5, balance.mul(4).div(100));
        _widthdraw(a6, balance.mul(2).div(100));
        _widthdraw(a7, balance.mul(2).div(100));
        _widthdraw(a8, balance.mul(2).div(100));
        _widthdraw(a9, balance.mul(2).div(100));
        _widthdraw(aMulti, address(this).balance);
    }

    function emergencyWithdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);

        payable(aMulti).transfer(balance);
    }


    //----------------------------------------
    // Internal
    //----------------------------------------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

}