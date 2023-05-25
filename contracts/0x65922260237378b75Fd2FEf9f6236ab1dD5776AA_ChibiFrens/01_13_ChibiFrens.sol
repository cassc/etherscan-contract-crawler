// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IChibis {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}

contract ChibiFrens is ERC721A, Ownable, ReentrancyGuard {
    using Address for address;
    using MerkleProof for bytes32[];

    IChibis public Gen1Contract;
    IChibis public Gen2Contract;
    IChibis public Gen3Contract;

    // variables
    string public baseTokenURI;
    uint256 public mintPrice = 0.05 ether;
    uint public collectionSize = 10000;
    uint256 public maxItemsPerWallet = 3;
    uint256 public allowlistReserved = 3300;
    uint256 public allowlistMinted = 0;
    uint256 public publicMintReserved = 200;
    uint256 public publicMinted = 0;

    address public gen1Addr = 0x4Ef0Fe82B42B6104BbcEB69E764AbD2050aCfdd4;
    address public gen2Addr = 0xC49a9AB342b6ea66792D4110e9cA0ab36e3a5674;
    address public gen3Addr = 0x5AEb2a703323F69b20F397BCB7B38610EC37237b;
    
    bool public claimPaused = true;
    bool public publicMintPaused = true;
    bool public allowlistMintPaused = true;
    bool public specialClaimPaused = true;

    bytes32 allowlistMerkleRoot;

    mapping(address => uint256) public allowlistMintedAmount;
    mapping(address => uint256) public specialClaimedAmount;

    struct claims {
        uint256[] gen1TokenIds;
        uint256[] gen2TokenIds;
        uint256[] gen3TokenIds;
    }

    uint256[] public specialTokenIds;

    event SpecialClaim(address indexed user, uint256 indexed amount);

    mapping(string => bool) public claimedChibis;

    function _onlySender() private view {
        require(msg.sender == tx.origin);
    }

    modifier onlySender {
        _onlySender();
        _;
    }

    // constructor
    constructor() ERC721A("Chibi Frens", "FREN") {
        Gen1Contract = IChibis(gen1Addr);
        Gen2Contract = IChibis(gen2Addr);
        Gen3Contract = IChibis(gen3Addr);
    }

    function specialClaim(uint256[] calldata _tokenIds) external onlySender nonReentrant {
        require(!specialClaimPaused, "No claim.");
        uint256 startingId = totalSupply();
        uint256 amount = 0;
        uint256 numOfGen1 = _tokenIds.length;
        uint256 alreadyClaimed = specialClaimedAmount[_msgSender()];
        require(Gen2Contract.balanceOf(_msgSender()) - alreadyClaimed >= numOfGen1, "must own same amount of gen 2");
        require(Gen3Contract.balanceOf(_msgSender()) - alreadyClaimed >= numOfGen1, "must own same amount of gen 3");
        for (uint256 i = 0; i < numOfGen1; i++) {
            uint256 id = _tokenIds[i];
            _claimCheck(Gen1Contract, gen1Addr, id);
            amount++;
            specialTokenIds.push(startingId + i);
        }
        specialClaimedAmount[_msgSender()] += amount;
        _mintWithValidation(amount);
        emit SpecialClaim(_msgSender(), amount);
    }

    function claim(uint256[] calldata gen1TokenIds, uint256[] calldata gen2TokenIds, uint256[] calldata gen3TokenIds ) external onlySender nonReentrant {
        require(!claimPaused, "No claim.");
        uint256 amount = 0;

        // for gen 1
        for (uint256 i = 0; i < gen1TokenIds.length; i++) {
            _claimCheck(Gen1Contract, gen1Addr, gen1TokenIds[i]);
            amount++;
        }

        // for gen 2
        for (uint256 i = 0; i < gen2TokenIds.length; i++) {
            _claimCheck(Gen2Contract, gen2Addr, gen2TokenIds[i]);
            amount++;
        }

        // for gen 3
        for (uint256 i = 0; i < gen3TokenIds.length; i++) {
            _claimCheck(Gen3Contract, gen3Addr, gen3TokenIds[i]);
            amount++;
        }

        _mintWithValidation(amount);
    }

    // public mint
    function publicMint() external payable nonReentrant onlySender {
        require(!publicMintPaused, "No public mint.");

        uint256 amount = _getMintAmount(msg.value);

        require(
            amount <= maxItemsPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        require(
            publicMinted + amount <= publicMintReserved,
            "Public Mint sold out"
        );
        publicMinted += amount;

        _mintWithValidation(amount);
    }

    // allowlist mint
    function allowlistMint(bytes32[] memory proof) external payable onlySender nonReentrant {
        require(!allowlistMintPaused, "Allowlist mint is paused");
        require(
            isAddressAllowlisted(proof, _msgSender()),
            "You are not eligible for allowlist mint"
        );

        uint256 amount = _getMintAmount(msg.value);

        require(
            allowlistMintedAmount[_msgSender()] + amount <= maxItemsPerWallet,
            "Minting amount exceeds allowance per wallet"
        );

        require(
            allowlistMinted + amount <= allowlistReserved,
            "Allowlist Mint sold out"
        );
        allowlistMinted += amount;

        allowlistMintedAmount[_msgSender()] += amount;
        _mintWithValidation(amount);
    }

    function isClaimed(address _addr, uint256 _id) view external returns (bool) {
        require(_addr == gen1Addr || _addr == gen2Addr || _addr == gen3Addr, "Wrong address.");
        string memory key = string(abi.encodePacked(_addr, "-", Strings.toString(_id)));
        return claimedChibis[key];
    }

    function isAddressAllowlisted(bytes32[] memory proof, address _address)
        public
        view
        returns (bool)
    {
        return _isAddressInMerkleRoot(allowlistMerkleRoot, proof, _address);
    }

    function getSpecialTokenIds()
        public
        view
        returns (uint256[] memory)
    {
        return specialTokenIds;
    }

    function _claimCheck(IChibis _contract, address _addr, uint256 _id) internal {
        string memory key = string(abi.encodePacked(_addr, "-", Strings.toString(_id)));
        require(_contract.ownerOf(_id) == _msgSender(), "You must own the NFT.");
        require(!claimedChibis[key], "Chibi must be unclaimed.");
        claimedChibis[key] = true;
    }

    function _isAddressInMerkleRoot(
        bytes32 merkleRoot,
        bytes32[] memory proof,
        address _address
    ) internal pure returns (bool) {
        return proof.verify(merkleRoot, keccak256(abi.encodePacked(_address)));
    }

    function _getMintAmount(uint256 value) internal view returns (uint256) {
        uint256 remainder = value % mintPrice;
        require(remainder == 0, "Send a divisible amount of eth");
        uint256 amount = value / mintPrice;
        return amount;
    }

    function _mintWithValidation(uint256 _amount) internal {
        require(_amount > 0, "Amount to mint is 0");
        require((totalSupply() + _amount) <= collectionSize, "sold out");
        _safeMint(_msgSender(), _amount);
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxMintItems(uint256 _maxItemsPerWallet) external onlyOwner {
        maxItemsPerWallet = _maxItemsPerWallet;
    }

    function setCollectionSize(uint256 _collectionSize, uint256 _publicMintReserve, uint256 _allowlistReserve) external onlyOwner {
        collectionSize = _collectionSize;
        publicMintReserved = _publicMintReserve;
        allowlistReserved = _allowlistReserve;
    }

    function setPaused(bool _claimPaused, bool _publicMintPaused, bool _allowlistPaused, bool _specialClaimPaused) external onlyOwner {
        claimPaused = _claimPaused;
        publicMintPaused = _publicMintPaused;
        allowlistMintPaused = _allowlistPaused;
        specialClaimPaused = _specialClaimPaused;
    }

    function setAllowlistMintMerkleRoot(bytes32 _allowlistMerkleRoot)
        external
        onlyOwner
    {
        allowlistMerkleRoot = _allowlistMerkleRoot;
    }

    function setAddresses(address _gen1Addr, address _gen2Addr, address _gen3Addr) external onlyOwner {
        gen1Addr = _gen1Addr;
        Gen1Contract = IChibis(_gen1Addr);
        gen2Addr = _gen2Addr;
        Gen2Contract = IChibis(_gen2Addr);
        gen3Addr = _gen3Addr;
        Gen3Contract = IChibis(_gen3Addr);
    }

    function withdrawAll() external onlyOwner nonReentrant {
        uint amount1 = address(this).balance * 25 / 100;
        uint amount2 = address(this).balance * 27375 / 100000;
        uint amount3 = address(this).balance * 27375 / 100000;
        uint amount4 = address(this).balance * 2025 / 10000;

        sendEth(0xAc0B0CD0268B5A9166De11A94E931E8e0cAD1DbB, amount1);
        sendEth(0xBF790E2bB3c5486961c37070A228a00329df87dA, amount2);
        sendEth(0xbD8daCc5621245DB77Fb01b194f6ee9da6B303D4, amount3);
        sendEth(0x133480292b0C5f3E5Ec685377669D5dF5f0bC4ac, amount4);
    }

    function sendEth(address to, uint amount) internal {
        (bool success,) = to.call{value: amount}("");
        require(success, "Failed to send ether");
    }

    function emergencyWithdrawAll() external onlyOwner nonReentrant {
        uint256 amount = address(this).balance;
        (bool success, ) = address(this.owner()).call{value: amount}("");
        require(success, "Failed to send ether");
    }

    // view
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721A)
        returns (string memory)
    {
        return
        string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }
}