pragma solidity ^0.8.0;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {SynthiaRenderer} from "./SynthiaRenderer.sol";
import {ISynthiaERC721} from "./ISynthiaERC721.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";

interface IErc721BalanceOf {
    function balanceOf(address owner) external view returns (uint256 balance);
}

interface IERC721OwnerOf {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Synthia is ERC721A, Ownable {
    SynthiaRenderer public renderer;
    uint256 public mintPrice = 0.029 ether;
    uint256 public heroPrice = 0.025 ether;
    uint public maxSupply = 10000;
    bytes32 public guaranteedMintMerkleRoot;
    uint256 public randomness;
    address heroes;
    mapping(address => bool) public wlCollections;
    mapping(address => uint) public gmMints;

    struct Dates {
        uint256 startWl;
        uint256 startGuaranteed;
        uint256 startPub;
    }

    Dates dates;

    error ErrorMessage(string);

    bytes32 public seedHash;
    uint256 public seed;
    address public wallet;
    bool public useCdn;
    string public cdnBase;

    constructor(
        uint256 startGuaranteed,
        uint256 startWl,
        uint256 startPub,
        address _wallet,
        bytes32 _seedHash,
        bytes32 _root,
        address _heroes
    ) ERC721A("Synthia", "SYN") {
        _mintERC2309(msg.sender, 555);
        heroes = _heroes;
        dates.startWl = startWl;
        dates.startGuaranteed = startGuaranteed;
        dates.startPub = startPub;
        seedHash = _seedHash;
        wallet = _wallet;
        guaranteedMintMerkleRoot = _root;
    }

    function addWlCollections(address[] memory collections) public onlyOwner {
        for (uint i = 0; i < collections.length; i++) {
            wlCollections[collections[i]] = true;
        }
    }

    function setRoot(bytes32 _root) public onlyOwner {
        guaranteedMintMerkleRoot = _root;
    }

    function updateUseCdn(bool val) public onlyOwner {
        useCdn = val;
    }

    function updateCdnBase(string memory base) public onlyOwner {
        cdnBase = base;
    }

    function updateWallet(address _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function updateDates(
        uint256 _startWl,
        uint256 _startGuaranteed,
        uint256 _startPub
    ) public onlyOwner {
        dates.startWl = _startWl;
        dates.startGuaranteed = _startGuaranteed;
        dates.startPub = _startPub;
    }

    function setRenderer(address _renderer) public onlyOwner {
        if (address(renderer) != address(0)) {
            revert ErrorMessage("Renderer set");
        }
        renderer = SynthiaRenderer(_renderer);
    }

    modifier wlStarted() {
        if (block.timestamp < dates.startWl) {
            revert ErrorMessage("WL not started");
        }
        _;
    }

    modifier guaranteedStarted() {
        if (block.timestamp < dates.startGuaranteed) {
            revert ErrorMessage("Guaranteed mint not started");
        }
        _;
    }

    modifier publicStarted() {
        if (block.timestamp < dates.startPub) {
            revert ErrorMessage("Public mint not started");
        }
        _;
    }

    modifier maxSupplyCheck(uint amount) {
        uint totalMinted = _totalMinted();
        if (amount > maxMintPerTx) {
            revert ErrorMessage("Amount gt max mint per tx");
        }
        if (totalMinted == maxSupply) {
            revert ErrorMessage("Max supply reached");
        }
        if (totalMinted + amount > maxSupply) {
            revert ErrorMessage("Invalid amount");
        }
        _;
    }

    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function revealSeed(uint256 _seed, bytes32 _nonce) public onlyOwner {
        if (seed != 0) {
            revert ErrorMessage("Seed aleady revealed");
        }

        bytes32 hashCheck = keccak256(abi.encodePacked(_seed, _nonce));
        require(hashCheck == seedHash, "Invalid seed or nonce");

        seed = _seed;
        emit BatchMetadataUpdate(1, type(uint256).max);
    }

    uint public maxMintPerTx = 20;

    function guaranteedMint(
        uint256 amount,
        bytes32[] calldata proof
    ) public payable guaranteedStarted {
        if (gmMints[msg.sender] + amount > maxMintPerTx) {
            revert ErrorMessage("GM Mint only allowed 20 per wallet");
        }
        uint price = mintPrice;
        try IErc721BalanceOf(heroes).balanceOf(msg.sender) returns (
            uint balance
        ) {
            if (balance > 1) {
                price = heroPrice;
            }
        } catch {
            // If an error occurs during the external call, price stays as mintPrice
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (!MerkleProofLib.verify(proof, guaranteedMintMerkleRoot, leaf)) {
            revert ErrorMessage("Invalid proof");
        }
        if (price * amount != msg.value) {
            revert ErrorMessage("Invalid value");
        }
        gmMints[msg.sender] += amount;
        _internalMint(amount);
    }

    function mintWithAddress(
        uint256 amount,
        address wlAddress
    ) public payable wlStarted {
        bool isWl = wlCollections[wlAddress];
        bool isHero = wlAddress == heroes;
        if (!isWl && !isHero) {
            revert ErrorMessage("Invalid WL address");
        }
        if (IErc721BalanceOf(wlAddress).balanceOf(msg.sender) < 1) {
            revert ErrorMessage("Must own NFT from WL collection");
        }
        uint256 price = isHero ? heroPrice : mintPrice;

        if (price * amount != msg.value) {
            revert ErrorMessage("Invalid value");
        }
        _internalMint(amount);
    }

    function mint(uint amount) public payable publicStarted {
        bool isHero = IErc721BalanceOf(heroes).balanceOf(msg.sender) > 0;
        uint256 price = isHero ? heroPrice : mintPrice;
        if (price * amount != msg.value) {
            revert ErrorMessage("Invalid value");
        }
        _internalMint(amount);
    }

    function _internalMint(uint256 amount) internal maxSupplyCheck(amount) {
        (bool sent, ) = wallet.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        _mint(msg.sender, amount);
    }

    function getSeed(uint256 tokenId) public view returns (uint256) {
        return uint256(keccak256(abi.encode(randomness, tokenId)));
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ErrorMessage("Token ID does not exist");
        }
        if (seed == 0) {
            // Return pre-revealed data
            return renderer.getPrerevealMetadataUri();
        }
        if (useCdn) {
            return string.concat(cdnBase, Strings.toString(tokenId));
        } else {
            return renderer.getMetadataDataUri(getSeed(tokenId), tokenId);
        }
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }
}