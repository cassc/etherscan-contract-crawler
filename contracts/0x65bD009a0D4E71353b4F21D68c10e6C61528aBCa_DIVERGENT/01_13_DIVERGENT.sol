// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";

contract DIVERGENT is ERC721AUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    string public baseURI;
    uint256 public maxSupply;
    bool public isMintLive;
    uint256 public mintPrice;

    uint8 private freeMintProb;

    bytes32 private merkleTreeRoot;

    CountersUpgradeable.Counter private _seed;

    mapping(address => uint256) public mintsWallet;
    mapping(address => bool) public whitelistClaimed;
    
    function initialize() initializerERC721A initializer public {
        __ERC721A_init('DIVERGENT', 'DIVERGENT');
        __Ownable_init();

        maxSupply = 5555;
        isMintLive = false;
        mintPrice = 0.02 ether;
        freeMintProb = 7;
    }

    function mint(uint256 quantity, bytes32[] memory _proof) external payable nonReentrant {
        require(isMintLive, "Mint not live");
        require(quantity > 0, "You must mint at least one");
        require(totalSupply() + quantity <= maxSupply, "Exceeds total supply");

        uint256 pricedQty = quantity;

        if( whitelistClaimed[msg.sender] == false && MerkleProofUpgradeable.verify(_proof, merkleTreeRoot, keccak256(abi.encodePacked(msg.sender)) ) ) {
            whitelistClaimed[msg.sender] = true;
            pricedQty = quantity - 1;
        }

        require(msg.value >= mintPrice * pricedQty, "Not enough ETH");

        uint256 refund = isFreeMint() ? pricedQty * mintPrice : 0;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        mintsWallet[msg.sender] = mintsWallet[msg.sender] + quantity;

        _mint(msg.sender, quantity);
    }

    function adminMint(address receiver, uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "Exceeds total supply");
        _mint(receiver, quantity);
    }

    function isFreeMint() private returns (bool) {
        uint256 seed = generateRandom();
        return (uint8(seed % 10) < freeMintProb);
    }

    function generateRandom() private returns (uint256) {
        _seed.increment();
        return uint256( keccak256(
            abi.encodePacked(
                block.difficulty,
                tx.origin,
                blockhash(block.number - 1),
                block.timestamp,
                block.coinbase,
                block.gaslimit,
                msg.sender,
                _seed.current()
            )
        ));
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