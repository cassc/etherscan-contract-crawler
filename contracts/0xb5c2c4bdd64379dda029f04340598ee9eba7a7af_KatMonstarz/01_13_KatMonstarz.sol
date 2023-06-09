// SPDX-License-Identifier: MIT

// /ᐠ｡▿｡ᐟ\*ᵖᵘʳʳ*
// KatMonstarz
// author: sadat.eth

pragma solidity ^0.8.4;

import "./ERC721A.sol"; // importing some amazing standard contracts
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract KatMonstarz is ERC721A, ReentrancyGuard, Ownable {
    using Strings for uint256;

    // Kat sale config
    uint256 public maxKats = 4444;
    uint256 public katlistPrice = 0.018 ether;
    uint256 public publicPrice = 0.026 ether;
    uint256 public maxPerWallet = 15;
    uint256 private reservedKats = 222;
    uint256 private availableKats = maxKats - reservedKats;
    uint256 private vipKats;
    
    // Kats metadata
    string private jetBox;
    string private monstarzLab;
    string private openseaInfo;

    // Kats revealing secret word
    bool public meow;

    // Kat burning rewards
    address private katRewards;

    // Kat funds distribution
    address private kittens;
    address private royaltyAddress;
    uint96 private royaltyBasisPoints;
    bytes4 private constant IERC2981 = 0x2a55205a;

    // Kat owners information
    bytes32 private katlist;
    mapping(address => bool) public claimed;
    mapping(address => uint256) public minted;

    // Kat dev stuff
    enum Switch { STOP, MINT, BURN }
    Switch public phase;
    bool public SOS;
    constructor() ERC721A("KatMonstarz", "KM") { }


    // Mint function for mint pass holders, katlist and public

    function mint(uint256 qty, uint256 freeMints, bytes32[] calldata purr) external payable ok() {
        require(phase == Switch.MINT, "mint not started");
        uint256 mints = qty;
        uint256 eth = publicPrice;
        uint256 kats = availableKats - vipKats;
        if (_katlist(_kat(msg.sender, freeMints), purr)) {
            if (!claimed[msg.sender]) {
                kats = availableKats;
                mints = mints + freeMints;
                claimed[msg.sender] = true;
            }
            eth = katlistPrice;
        }
        require(mints + totalSupply() <= kats, "sold out");
        require(minted[msg.sender] + qty <= maxPerWallet, "max minted");
        require(msg.value >= eth * qty, "send eth!");
       _safeMint(msg.sender, mints);
       minted[msg.sender] += qty;
    }

    // Custom KatMonstarz functions to manage and configure

    function burn(uint256[] memory tokenIds) external payable ok() {
        require(phase == Switch.BURN, "burning not started");
        IKatMonstarzReward rewardContract = IKatMonstarzReward(katRewards);
        for (uint256 i; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(_isApprovedOrOwner(msg.sender, tokenId), "you can't burn this");
            _burn(tokenId);
            rewardContract.getReward(msg.sender);
        }
    }

    function reserve(address _to, uint256 qty) external onlyOwner ok() {
        require(qty <= reservedKats, "no more kats");
        _safeMint(_to, qty);
        reservedKats -= qty;
    }

    function start() public onlyOwner {
        phase = Switch.MINT;
    }

    function stop() public onlyOwner {
        phase = Switch.MINT;
    }

    function end() public onlyOwner ok() {
        uint256 supply = totalSupply();
        maxKats = supply;
    }

    function reveal(string memory _URI) public onlyOwner ok() {
        monstarzLab = _URI;
        meow = true;
    }
    
    function burning() public onlyOwner {
        phase = Switch.BURN;
    }

    function freeze() public onlyOwner {
        SOS = !SOS;
    }

    function setKatlist(bytes32 _root) public onlyOwner {
        katlist = _root;
    }

    function setVipkats(uint256 _vipKats) public onlyOwner {
        vipKats = _vipKats;
    }

    function setPayments(address _kittensWallet, address _royaltyAddress, uint96 _royaltyBasisPoints) external onlyOwner {
        kittens = _kittensWallet;
        royaltyAddress = _royaltyAddress;
        royaltyBasisPoints = _royaltyBasisPoints;
    }

    function setReward(address _rewardAddr) external onlyOwner {
        katRewards = _rewardAddr;
    }

    function setCollectionPage(string memory _jetBoxURI, string memory _OsURI) external onlyOwner {
        jetBox = _jetBoxURI;
        openseaInfo = _OsURI;
    }

    function setMonstarzLab(string memory _URI) public onlyOwner {
        monstarzLab = _URI;
    }

    function setSaleConfig(uint256 _katlistPrice, uint256 _publicPrice, uint256 _newMaxMints) public onlyOwner {
        katlistPrice = _katlistPrice;
        publicPrice = _publicPrice;
        maxPerWallet = _newMaxMints;
    }

    function withdraw() public onlyOwner nonReentrant ok() {
        (bool os, ) = payable(kittens).call{value: address(this).balance}("");
        require(os);
    }

    // Standard contract functions for marketplaces and dapps

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        require(_exists(_tokenId), "Cannot query non-existent token");
        return (royaltyAddress, (_salePrice * royaltyBasisPoints) / 10000);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A) returns (bool) {
        if (interfaceId == IERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (meow == false) {
            return jetBox;
        }
        return string(abi.encodePacked(monstarzLab, tokenId.toString(), ".json"));
    }
    
    function contractURI() public view returns (string memory) {
        return openseaInfo;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        while (ownedTokenIndex < ownerTokenCount && currentTokenId < maxKats) {
        address currentTokenOwner = ownerOf(currentTokenId);
        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;
            ownedTokenIndex++;
        }
        currentTokenId++;
        }
        return ownedTokenIds;
    }

    // Custom internal functions for contract

    modifier ok() {
        require(SOS == false, "SOS call devs");
        _;
    } 

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _kat(address account, uint256 freeMints) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, freeMints));
    }

    function _katlist(bytes32 kat_, bytes32[] memory purr) internal view returns (bool) {
        return MerkleProof.verify(purr, katlist, kat_);
    }

}

interface IKatMonstarzReward {
    function getReward(address _address) external;
}