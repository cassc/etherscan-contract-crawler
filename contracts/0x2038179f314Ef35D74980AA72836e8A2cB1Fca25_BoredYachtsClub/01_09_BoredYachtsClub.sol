// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @custom:security-contact [email protected]
contract BoredYachtsClub is ERC721A, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    string public baseURI = "ipfs://QmP6ZjG2o3LfRNHgnU4xk5gwC5cM2YomtH5hf1D86N48Vq/metadata/";

    /* 
        Active Tier
            Code - Name
            0 - Closed
            1 - Tier 1
            2 - Tier 2
            3 - Tier 3
            4 - Public
    */
    uint256 public activeTier = 0;
    bytes32 public merkleRoot;

    // public Access
    uint256 public maxPublicMintPerWallet = 2;
    uint256 public publicPrice = 0.1 ether;
    uint256 public presalePrice = 0.1 ether;

    uint256 public maxSupply = 1000;

    constructor(bytes32 _merkleRoot) ERC721A("Bored Yachts Club", "BYC") {
        merkleRoot = _merkleRoot;
    }

    event MintEvent(
        address indexed reciever,
        uint256 quantity,
        uint256 latest_token_id
    );
    event BaseURI(
        string baseURI
    );

    function setBaseURI(string calldata _baseUri) external onlyOwner {
        baseURI = _baseUri;
        emit BaseURI(_baseUri);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateActiveTier(uint256 _activeTier) external onlyOwner {
        activeTier = _activeTier;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    function setPublicSalePrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }
    function setPresalePrice(uint256 _presalePrice) external onlyOwner {
        presalePrice = _presalePrice;
    }
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
    function setMaxPublicMintPerWallet(uint256 _maxPublicMintPerWallet) external onlyOwner {
        maxPublicMintPerWallet = _maxPublicMintPerWallet;
    }

    /// @notice Allows addresses in whitelist to participate
    /// @param proof the merkle proof that the given user with the provided allocation is in the merke tree
    /// @param quantity the quantity of NFTs to mint
    /// @param allocation of NFT mentioned in whitelist for individual address
    /// @param tier in which the user address is listed
    function presaleMint(
        bytes32[] memory proof,
        uint256 quantity,
        uint256 allocation,
        uint256 tier
    ) external payable nonReentrant {

        require(isWhitelisted(_msgSender(), merkleRoot, proof, allocation, tier), "NON_WHITELIST: Not whitelisted");
        require(activeTier == 1 || activeTier == 2 || activeTier == 3, "PRESALE_INACTIVE: Presale not active!");
        require(tier == activeTier, "PRESALE_TIER_NOT_STARTED: Presale active, but not for your Tier!");
        require(_numberMinted(_msgSender()) + quantity <= allocation, "WALLET_LIMIT_REACHED: Wallet limit reached!");
        require(totalSupply() + quantity <= maxSupply, "SOLD_OUT: All NFTs sold out!");
        require(msg.value >= presalePrice * quantity, "LOW_BALANCE: Not enough funds supplied!");

        _safeMint(_msgSender(), quantity);
        emit MintEvent(_msgSender(), quantity, totalSupply());
    } 


    function isWhitelisted(
        address account,
        bytes32 _merkleRoot,
        bytes32[] memory proof,
        uint256 allocation,
        uint256 tier
    ) public pure returns (bool) {
        return MerkleProof.verify(
                    proof,
                    _merkleRoot,
                    keccak256(abi.encodePacked(account, allocation, tier))
                );
    }

    function mint(uint quantity) external payable nonReentrant {
        require(activeTier == 4, "PUBLIC_SALE_INACTIVE: Public sale not active!");
        require(_numberMinted(_msgSender()) + quantity <= maxPublicMintPerWallet, "WALLET_LIMIT_REACHED: Wallet limit reached!");
        require(totalSupply() + quantity <= maxSupply, "SOLD_OUT: Max supply reached!");
        require(msg.value >= publicPrice * quantity, "LOW_BALANCE: Not enough funds supplied!");

        _safeMint(_msgSender(), quantity);
    }

    function crossmint(address recipient, uint256 quantity) external payable nonReentrant {
        require(activeTier == 4, "PUBLIC_SALE_INACTIVE: Public sale not active!");
        require(_numberMinted(_msgSender()) + quantity <= maxPublicMintPerWallet, "WALLET_LIMIT_REACHED: Wallet limit reached!");
        require(totalSupply() + quantity <= maxSupply, "SOLD_OUT: Max supply reached!");
        require(msg.value >= publicPrice * quantity, "LOW_BALANCE: Not enough funds supplied!");

        _safeMint(recipient, quantity);
    }

    function airdrop(address[] calldata recipients, uint256[] calldata quantity) external onlyOwner {
        require(recipients.length == quantity.length, "UNEQUAL_ARRAY: length of recipients and quantity not equal!");

        uint256 cumulativeQuantity = 0;
        for( uint256 i = 0; i < recipients.length; ++i ){
            cumulativeQuantity += quantity[i];
        }
        require(totalSupply() + cumulativeQuantity <= maxSupply, "SOLD_OUT: Max supply reached!");

        for( uint256 i = 0; i < recipients.length; ++i ){
            _safeMint(recipients[i], quantity[i]);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(_msgSender()), balance);
    }
}