// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract DIVERGENTv2 is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    string public baseURI;
    uint256 public maxSupply;
    uint256 public maxPerTransaction;
    bool public isMintLive;
    uint256 public mintPrice;

    uint8 private freeMintProb;
    bytes32 private merkleTreeRoot;

    CountersUpgradeable.Counter private _seed;

    mapping(address => bool) public whitelistClaimed;
    
    function initialize() initializerERC721A initializer public {
        __ERC721A_init('DIVERGENT', 'DIVERGENT');
        __Ownable_init();

        maxSupply = 5555;
        maxPerTransaction = 10;
        isMintLive = true;
        mintPrice = 0.008 ether;
        freeMintProb = 7;
    }

    function mint(uint256 quantity, bytes32[] memory _proof) external payable nonReentrant {
        require(isMintLive, "Mint not live");
        require(quantity > 0, "You must mint at least one");
        require(totalSupply() + quantity <= maxSupply, "Exceeds total supply");
        require(quantity <= maxPerTransaction, "Exceeds max per transaction");

        uint256 pricedQty = quantity;

        if( whitelistClaimed[_msgSender()] == false && MerkleProofUpgradeable.verify(_proof, merkleTreeRoot, keccak256(abi.encodePacked(_msgSender())) ) ) {
            whitelistClaimed[_msgSender()] = true;
            pricedQty = quantity - 1;
        }

        require(msg.value >= mintPrice * pricedQty, "Not enough ETH");

        uint256 refund = isFreeMint() ? pricedQty * mintPrice : 0;

        payable(_msgSender()).transfer(refund);

        _mint(_msgSender(), quantity);
    }

    function adminMint(address receiver, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Exceeds total supply");
        _mint(receiver, quantity);
    }

    function isFreeMint() internal view returns (bool) {
        return (uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            _msgSender()
        ))) & 0xFFFF) % 10 < freeMintProb;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setMintLive(bool _isMintLive) external onlyOwner {
        isMintLive = _isMintLive;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    function setMaxPerTransaction(uint256 _maxPerTransaction) external onlyOwner {
        maxPerTransaction = _maxPerTransaction;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setFreeMintProb(uint8 _freeMintProb) external onlyOwner {
        freeMintProb = _freeMintProb;
    }

    function setMerkleTreeRoot(bytes32 _merkleTreeRoot) external onlyOwner {
        merkleTreeRoot = _merkleTreeRoot;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}