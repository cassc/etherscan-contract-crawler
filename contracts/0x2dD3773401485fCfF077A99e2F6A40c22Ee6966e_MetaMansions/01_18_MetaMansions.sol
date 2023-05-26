// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./ERC721A.sol";
import "./SafeMath.sol";

interface IKeys {
    function purchaseTokenForAddress(address receiver) external payable;
}

/*
    Welcome to Meta Mansions, a collection of 8,888 unique digital mansions 
    built on Ethereum as the core residency of the KEYS Metaverse. 

    Meta Mansions is more than an NFT; it’s part of your identity. 

    Utilities include customization of interior spaces, active & passive income streams, 
    a powerful community, and priority access for special events in real life and 
    inside the KEYS Metaverse. 

    World-renown architects, builders, game designers, businesses, brands, 
    musicians, athletes, and web3 enthusiasts connect to create a decentralized future.

    Let’s re-imagine the way we live, work, play, earn, and learn by 
    creating the next wave of real estate and the KEYS Metaverse experience.

    Join our community 
    Discord: https://discord.gg/keystoken
    Instagram: https://www.instagram.com/metamansions.nft
    Twitter: https://www.twitter.com/metamansionsnft 
*/

contract MetaMansions is ERC721A, Ownable {
    using SafeMath for uint256;

    // Merkle Root for Mamba (Tier 1) Whitelist (18 mints)
    bytes32 public mambaRoot;

    // Merkle Root for Whale (Tier 2) Whitelist (8 mints)
    bytes32 public whaleRoot;

    // Merkle Root for Stacker (Tier 3) Whitelist (2 mints)
    bytes32 public stackerRoot;

    // Mamba Whitelist Active
    bool public isMambaActive;

    // Whale Whitelist Active
    bool public isWhaleActive;

    // Stacker Whitelist Active
    bool public isStackerActive;

    // Public Sale Active
    bool public isPublicSaleActive;

    // Reveal 
    bool public revealed;

    // Price
    uint256 public constant price = 0.88 ether;

    // Max Amount
    uint256 public constant maxAmount = 8888;

    // Base URI
    string private baseURI;

    // Tracks redeem count for public sale
    mapping(address => uint256) private saleRedeemedCount;

    // Max per wallet for Mamba Whitelist
    uint256 private constant mambaMaxPerWallet = 18;

    // Max per wallet for Whale Whitelist
    uint256 private constant whaleMaxPerWallet = 8;

    // Max per wallet for Stacker Whitelist
    uint256 private constant stackerMaxPerWallet = 2;

    // Max mints per wallet for public sale
    uint256 private constant publicSaleMaxPerWallet = 88;

    // KEYS Contract
    address private constant KEYS = 0xe0a189C975e4928222978A74517442239a0b86ff;

    // Locked KEYS Contract
    address private constant LOCKED_KEYS = 0x08DC692FE528fFEcF675Ab3f76981553e060Fd8A;

    // 100 KEYS needed for minting
    uint256 public keysNeededForMinting = 97 * 10**9;

    /////////////////////////////////////////////////////////////////
    /////////////////////  CONSTRUCTOR  /////////////////////////////
    /////////////////////////////////////////////////////////////////

    constructor()
    ERC721A("MetaMansions", "MM", 18) {}

    // Receive function in case someone wants to donate some ETH to the contract
    receive() external payable {}

    /////////////////////////////////////////////////////////////////
    /////////////////////  MINT FUNCTIONALITY  //////////////////////
    /////////////////////////////////////////////////////////////////

    function mint(uint32 quantity, bytes32[] calldata proof, uint32 tier) external payable {
        require(tier == 0 || tier == 1 || tier == 2, "11");
        
        // extra eth needed to buy keys if applicable
        uint256 additional = hasKeys(_msgSender()) ? 0 : 0.01 ether;

        // Check if the price is enough
        require(msg.value >= ( price * quantity ) + additional, "9");

        if (tier == 0) {
            mambaValidation(quantity, proof);
        } else if (tier == 1) {
            whaleValidation(quantity, proof);
        } else if (tier == 2) {
            stackerValidation(quantity, proof);
        }
        
        if (!hasKeys(_msgSender())) {
            _purchaseKEYS(_msgSender());
        }

        // Mint tokens to sender
        _mintToken(_msgSender(), quantity);
    }

    function mint(uint256 quantity) external payable {
        require(isPublicSaleActive, "10");

        // extra eth needed to buy keys if applicable
        uint256 additional = hasKeys(_msgSender()) ? 0 : 0.01 ether;

        // Check if the price is enough
        require(msg.value >= ( price * quantity ) + additional, "9");

        // Add quantity minted to redeemed count
        saleRedeemedCount[_msgSender()] += quantity;

        // Check if the sender's redeem count does not exceed max per wallet 
        require(
            publicSaleMaxPerWallet > saleRedeemedCount[_msgSender()],
            "8"
        );

        if (!hasKeys(_msgSender())) {
            _purchaseKEYS(_msgSender());
        }
        
        // Mint tokens to sender
        _mintToken(_msgSender(), quantity);
    }

    function mint(address to, uint256 quantity) external onlyOwner {
        _mintToken(to, quantity);
    }

    function _mintToken(address to, uint256 quantity) internal {
        require(quantity + totalSupply() <= maxAmount, "3");
        require(quantity <= maxBatchSize, "4");
        _safeMint(to, quantity);
    }

    // Gives the tokenURI for a given tokenId
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();

        // If not revealed, show non-revealed image
        if (!revealed) {
            return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI)) : "";
        }
        // else, show revealed image
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json"))
                : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getTotalClaimed(address address_) external view returns (uint256) {
        return saleRedeemedCount[address_];
    }

    /////////////////////////////////////////////////////////////////
    /////////////////////  OWNER ONLY  //////////////////////////////
    /////////////////////////////////////////////////////////////////

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function setMambaRoot(bytes32 root) external onlyOwner {
        mambaRoot = root;
    }

    function setWhaleRoot(bytes32 root) external onlyOwner {
        whaleRoot = root;
    }

    function setStackerRoot(bytes32 root) external onlyOwner {
        stackerRoot = root;
    }

    function toggleReveal() external onlyOwner {
        revealed = !revealed;
    }

    function toggleMambaActive() external onlyOwner {
        isMambaActive = !isMambaActive;
    }

    function toggleWhaleActive() external onlyOwner {
        isWhaleActive = !isWhaleActive;
    }

    function toggleStackerActive() external onlyOwner {
        isStackerActive = !isStackerActive;
    }

    function togglePublicSaleActive() external onlyOwner {
        isPublicSaleActive = !isPublicSaleActive;
    }

    function withdraw() public onlyOwner {
        (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
        require(success, "No withdraw");
    }

    /////////////////////////////////////////////////////////////////
    ////////////////////////  VALIDATIONS  //////////////////////////
    /////////////////////////////////////////////////////////////////

    function mambaValidation(uint32 quantity, bytes32[] calldata proof) internal {
         // Check if the mamba is active
        require(isMambaActive, "0");

        // Check if whitelist using Merkle Proof
        require(
            MerkleProof.verify(
                proof,
                mambaRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "5"
        );

        // Add quantity to total redeemed count of sender
        saleRedeemedCount[_msgSender()] += quantity;

        // Check if Mamba WL already redeemed
        require(saleRedeemedCount[_msgSender()] <= mambaMaxPerWallet, "8");
    }

    function whaleValidation(uint32 quantity, bytes32[] calldata proof) internal {
        // Check if the whale is active
        require(isWhaleActive, "1");

        // Check if whitelist using Merkle Proof
        require(
            MerkleProof.verify(
                proof,
                whaleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "6"
        );

        // Add quantity to total redeemed count of sender
        saleRedeemedCount[_msgSender()] += quantity;

        // Check if Whale WL already minted
        require(saleRedeemedCount[_msgSender()] <= whaleMaxPerWallet, "8");
    }

    function stackerValidation(uint32 quantity, bytes32[] calldata proof) internal {
        // Check if the stacker is active
        require(isStackerActive, "2");


        // Check if whitelist using Merkle Proof
        require(
            MerkleProof.verify(
                proof,
                stackerRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "7"
        );

        // Add quantity to total redeemed count of sender
        saleRedeemedCount[_msgSender()] += quantity;

        // Check if Stacker WL already minted
        require(saleRedeemedCount[_msgSender()] <= stackerMaxPerWallet, "8");
    }

    function hasKeys(address receiver) public view returns (bool) {
        uint256 amountOfKeysOwned = IERC20(KEYS).balanceOf(receiver);
        uint256 amountOfLockedKeysOwned = IERC20(LOCKED_KEYS).balanceOf(receiver);
        uint256 totalKeysOwned = amountOfKeysOwned.add(amountOfLockedKeysOwned);
        return totalKeysOwned >= keysNeededForMinting;
    }

    function _purchaseKEYS(address receiver) internal {
        IKeys(KEYS).purchaseTokenForAddress{value: 0.01 ether }(receiver);
    }
}