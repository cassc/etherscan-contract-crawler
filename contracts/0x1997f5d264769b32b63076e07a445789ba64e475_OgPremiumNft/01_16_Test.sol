// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract OgPremiumNft is ERC721A, ReentrancyGuard, ERC2981, AccessControl {

    AggregatorV3Interface internal immutable priceFeed;

    string public baseURI = "ipfs://QmYcjmfkmSc48HyTCKC49K5P27YDnMYHobcRSyhpBEawcM/";
    bytes32 public constant AIRDROP_BASEURI_MANAGE_ROLE = keccak256("AIRDROP_BASEURI_MANAGE_ROLE");
    address public constant royaltyReceiverAddress = 0xbA343482689222efD1a6b3A564D7d4B77Fc830de;
    address public constant chainlinkPriceFeedContractAddress = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant adminAddress = 0xD22234d60dA88E53ecaB34F2d9bAaB33B9d1EA9F;
    address public constant gasPayerAddress = 0x039A775A0474B939486DB0F8fBad641f22966843;
    /* 
        Active Tier
            Code - Name
            0 - Closed
            1 - Tier 1
            2 - Tier 2
            3 - Public
    */
    uint256 public activeTier = 0;
    bytes32 public merkleRoot;

    uint256 public nftPriceUsd = 190;
    uint256 public constant maxSupply = 5000;
    uint96 public constant royaltyFeeNumerator = 500; // equivalent to 5 percent

    constructor(bytes32 _merkleRoot) ERC721A("Road Hounds OG Premium", "RHOGP") {
        // Set Merkle Root
        merkleRoot = _merkleRoot;
        
        // Set Royalty
        _setDefaultRoyalty(royaltyReceiverAddress, royaltyFeeNumerator);

        // intialise price feed 
        priceFeed = AggregatorV3Interface(
            chainlinkPriceFeedContractAddress
        );

        // Transfer Ownership
        _grantRole(DEFAULT_ADMIN_ROLE, adminAddress);

        // Role assigned for triggering Airdop & setBaseURI function
        _grantRole(AIRDROP_BASEURI_MANAGE_ROLE, gasPayerAddress);
    }

    event MintEvent(
        address indexed reciever,
        uint256 quantity,
        uint256 latest_token_id
    );
    event BaseURI(
        string baseURI
    );
    event MerkleRootUpdateEvent(
        bytes32 merkleRoot
    );
    event ActiveTierUpdateEvent(
        uint256 activeTier
    );
    event NftPriceUpdateEvent(
        uint256 nftPriceUsd
    );
    event RoyaltyReceiverUpdateEvent(
        address royalty_receiver
    );

    function setBaseURI(string calldata _baseUri) external onlyRole(AIRDROP_BASEURI_MANAGE_ROLE) {
        baseURI = _baseUri;
        emit BaseURI(_baseUri);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateActiveTier(uint256 _activeTier) external onlyRole(DEFAULT_ADMIN_ROLE) {
        activeTier = _activeTier;
        emit ActiveTierUpdateEvent(_activeTier);
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdateEvent(_merkleRoot);
    }
    function setNftPriceUsd(uint256 _nftPriceUsd) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftPriceUsd = _nftPriceUsd;
        emit NftPriceUpdateEvent(_nftPriceUsd);
    }
    
    function updateDefaultRoyalty(address royalty_receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(royalty_receiver, royaltyFeeNumerator);
        emit RoyaltyReceiverUpdateEvent(royalty_receiver);
    }

    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            uint80 roundID,
            int price,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        require(price > 0, "PriceFeedError: Price is below zero.");
        require(roundID != 0, "PriceFeedError: Invalid roundID.");
        require(timeStamp != 0, "PriceFeedError: Invalid timeStamp.");

        return price;
    }

    function verifyPayment(uint256 eth_amount, uint256 quantity) public view returns (bool) {
        uint256 eth_usd_price = uint256(getLatestPrice());

        uint256 required_eth_amount_per_nft = (nftPriceUsd * 10**(18+8)) / eth_usd_price;

        return eth_amount >= required_eth_amount_per_nft * quantity;
    }

    /// @notice Allows addresses in whitelist to participate
    /// @param proof the merkle proof that the given user with the provided tier is in the merke tree
    /// @param quantity the quantity of NFTs to mint
    /// @param tier in which the user address is listed
    function allowlistMint(
        bytes32[] memory proof,
        uint256 quantity,
        uint256 tier
    ) external payable nonReentrant {

        require(isWhitelisted(_msgSender(), merkleRoot, proof, tier), "NON_WHITELIST: Not whitelisted");
        require(activeTier == 1 || activeTier == 2, "PRESALE_INACTIVE: Presale not active!");
        require(tier == activeTier, "PRESALE_TIER_NOT_STARTED: Presale active, but not for your Tier!");
        
        require(totalSupply() + quantity <= maxSupply, "SOLD_OUT: All NFTs sold out!");

        // Check msg.sender USD value is greater than equal to nftPriceUsd
        require(verifyPayment(msg.value, quantity), "LOW_BALANCE: Not enough funds supplied!");

        _safeMint(_msgSender(), quantity);
        emit MintEvent(_msgSender(), quantity, totalSupply());
    } 


    function isWhitelisted(
        address account,
        bytes32 _merkleRoot,
        bytes32[] memory proof,
        uint256 tier
    ) public pure returns (bool) {
        return MerkleProof.verify(
                    proof,
                    _merkleRoot,
                    keccak256(abi.encodePacked(account, tier))
                );
    }

    function mint(uint quantity) external payable nonReentrant {
        require(activeTier == 3, "PUBLIC_SALE_INACTIVE: Public sale not active!");
        
        require(totalSupply() + quantity <= maxSupply, "SOLD_OUT: Max supply reached!");

        // Check msg.sender USD value is greater than equal to nftPriceUsd
        require(verifyPayment(msg.value, quantity), "LOW_BALANCE: Not enough funds supplied!");

        _safeMint(_msgSender(), quantity);
        emit MintEvent(_msgSender(), quantity, totalSupply());
    }


    function airdrop(address[] calldata recipients, uint256[] calldata quantity) external onlyRole(AIRDROP_BASEURI_MANAGE_ROLE) nonReentrant {
        require(recipients.length == quantity.length, "UNEQUAL_ARRAY: length of recipients and quantity not equal!");

        uint256 cumulativeQuantity = 0;
        for( uint256 i = 0; i < recipients.length; ++i ){
            cumulativeQuantity += quantity[i];
        }
        require(totalSupply() + cumulativeQuantity <= maxSupply, "SOLD_OUT: Max supply reached!");

        for( uint256 i = 0; i < recipients.length; ++i ){
            _safeMint(recipients[i], quantity[i]);
            emit MintEvent(recipients[i], quantity[i], totalSupply());
        }
    }

    function withdraw(address withdrawal_address) external onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(withdrawal_address), balance);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) ||  ERC2981.supportsInterface(interfaceId) ||  AccessControl.supportsInterface(interfaceId);
    }
}