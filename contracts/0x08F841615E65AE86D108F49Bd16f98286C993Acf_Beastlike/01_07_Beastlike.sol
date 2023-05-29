// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// for remix:
// import "https://github.com/chiru-labs/ERC721A/blob/v4.2.3/contracts/ERC721A.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract Beastlike is ERC721A, Ownable, ReentrancyGuard {

    /**
     * @notice Wallet address of the Wolf Conservation Center (will receive 2% of revenue)
     */
    address public constant WOLF_CONSERVATION_CENTER_WALLET = 0xd4De84d58C1A665812B9Ae678eC5F58972fcDd93;

    /**
     * @notice Wallet address of the Perfect World Foundation (will receive 2% of revenue)
     */
    address public constant PERFECT_WORLD_FOUNDATION_WALLET = 0x4B8f45D19B0E5D1cF139993158F8b779654C4F0D;

    /**
     * @notice Wallet address of the Sea Turtle Foundation (will receive 2% of revenue)
     */
    address public constant SEE_TURTLE_FOUNDATION_WALLET = 0x8492AfE3Abf3a0275E8e7514585893cFE3907577;

    /**
     * @notice Wallet address of the advisor (will receive 0.5% of revenue)
     */
    address public constant ADVISOR_WALLET = 0x03FCAd69EBE34219Da0028fc8153f3Fc6b7B3bb0;

    /**
     * @notice If true the public sale is active
     */
    bool public publicSaleActive = false;

    /**
     * @notice Cost per token of the public sale
     */
    uint256 public cost;

    /**
     * @notice Cost per token of the whitelist sale
     */
    uint256 public whitelistCost;

    /**
     * @notice The maximum supply of tokens that can be minted
     */
    uint256 public maxSupply = 30000;

    /**
     * @notice Locks the maxSupply so it can't be changed anymore
     */
    bool public maxSupplyLocked = false;

    /**
     * @notice The maximum amount of mint tokens per Wallet (public sale)
     */
    uint256 public maxMintAmount = 20;

    /**
     * @notice The maximum amount of mint tokens per Wallet (whitelist sale)
     */
    uint256 public maxWhitelistMintAmount = 10;

    /**
     * @dev Construct this from (address, amount) tuple elements for whitelisted mints
     */
    bytes32 public whitelistMerkleRoot = '';

    /**
     * @dev Maps address to amount of minted whitelist tokens, we can't use _numberMinted
     * from ERC721A because the wallet might have already minted 1 free OG NFT
     */
    mapping(address => uint) public whitelistUsed;

    /**
     * @dev Construct this from (address, amount) tuple elements for free mint
     */
    bytes32 public ogMintMerkleRoot = '';

    /**
     * @dev Maps address to a boolean (only 1 free mint per OG spot)
     */
    mapping(address => bool) public ogMintUsed;

    /**
     * @dev Maps address to amount of minted public sale tokens, we can't use _numberMinted
     * from ERC721A because the wallet might already have minted from the WL sale
     */
    mapping(address => uint) public publicSaleUsed;

    /**
     * @dev The baseURI
     */
    string public baseURI;

    /**
     * @dev If set to true the baseURI can't be changed anymore
     */
    bool public baseURILocked;

    /**
     * @dev If set to true, an emergency withdraw function is unlocked
     * @notice This variable will only be set to false if something goes wrong in the regular
     * withdraw function. It can't be controlled by the owner.
     */
    bool public emergencyWithdrawLocked = true;

    // ================================================== //
    // Constructor                                        //
    // ================================================== //

    /**
     * @param name Contract name
     * @param symbol Contract symbol
     * @param _cost Cost for public mint
     * @param _whitelistCost Cost for whitelist mint
     * @param baseURI_ The baseURI for the tokens
     */
    constructor(string memory name, string memory symbol, uint256 _cost, uint256 _whitelistCost, string memory baseURI_) ERC721A(name, symbol) {
        cost = _cost;
        whitelistCost = _whitelistCost;
        baseURI = baseURI_;
    }

    // ================================================== //
    // Internal                                           //
    // ================================================== //

    /**
     * @dev Returns the starting token ID.
     * @return uint256 Start Token ID.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 0;
    }

    /**
     * @dev Return the baseURI to be used by tokenURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Validate a merkleTree
     * @param merkleRoot The merkleRoot that's set in the contract
     * @param merkleProof The merkleProof sent with the transaction
     * @param verifyAddress The address (leaf) to be verified
     */
    function _isValid(bytes32 merkleRoot, bytes32[] calldata merkleProof, address verifyAddress) internal pure returns (bool isValid) {
        bytes32 leaf = keccak256(abi.encodePacked(verifyAddress));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }

    // ================================================== //
    // External                                           //
    // ================================================== //

    /**
     * @dev Mint function for the public sale
     * @param quantity The amount of tokens to be minted
     */
    function mint(uint256 quantity) external payable {
        require(publicSaleActive, "Public sale is not active");
        require(quantity > 0, "Quantity of tokens must be greater than 0"); 
        require(totalSupply() + quantity < (maxSupply + 1), "Quantity of tokens exceeds maxSupply");
        require((msg.value + 1) > cost * quantity, "Not enough ether provided");

        // Make sure that 1 wallet can't mint more than maxMintAmount
        require(publicSaleUsed[msg.sender] + quantity < (maxMintAmount + 1), "Quanity of tokens exceeds maxMintAmount");
        publicSaleUsed[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Mint function for all whitelisted addresses
     * @param quantity The amount of tokens to be minted
     * @param merkleProof The Merkle proof to be validated
     */
    function whitelistMint(uint256 quantity, bytes32[] calldata merkleProof) external payable {
        require(_isValid(whitelistMerkleRoot, merkleProof, msg.sender), "Not on the whitelist"); 

        require(quantity > 0, "Quantity of tokens must be greater than 0"); 
        require(totalSupply() + quantity < (maxSupply + 1), "Quantity of tokens exceeds maxSupply");
        require((msg.value + 1) > whitelistCost * quantity, "Not enough ether provided");

        // Make sure that 1 wallet can't mint more than maxWhitelistMintAmount
        require(whitelistUsed[msg.sender] + quantity < (maxWhitelistMintAmount + 1), "Quanity of tokens exceeds maxMintAmount");
        whitelistUsed[msg.sender] += quantity;

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Mint function for all OG addresses (1 free mint)
     * @param quantity The amount of tokens to be minted
     * @param merkleProof The Merkle proof to be validated
     */
    function OGMint(uint256 quantity, bytes32[] calldata merkleProof) external payable { 
        require(_isValid(ogMintMerkleRoot, merkleProof, msg.sender), "Not on the OG list");
        require(totalSupply() + quantity < (maxSupply + 1), "Quantity of tokens exceeds maxSupply");

        // Calculate costs including ogMint if still available
        uint256 costs = whitelistCost * quantity;
        if (!ogMintUsed[msg.sender]) {
            ogMintUsed[msg.sender] = true;

            // Subtract 1x whitelistCost to account for the free mint
            costs -= whitelistCost;

            // Make sure that 1 wallet can't mint more than maxWhitelistMintAmount + 2
            // The +2 comes from a +1 that we need to use < instead of <= (gas costs)
            // and a +1 that we need to account for the free mint spot
            require(whitelistUsed[msg.sender] + quantity < (maxWhitelistMintAmount + 2), "Quanity of tokens exceeds maxMintAmount");

            // Subtract -1 from quantity for the free mint (10WL spots, 1 free mint)
            whitelistUsed[msg.sender] += quantity - 1;
        } else {
            // Make sure that 1 wallet can't mint more than maxWhitelistMintAmount
            require(whitelistUsed[msg.sender] + quantity < (maxWhitelistMintAmount + 1), "Quanity of tokens exceeds maxMintAmount");
            whitelistUsed[msg.sender] += quantity;
        }

        // Check costs, in case of a quanity of 1 and the free mint it would be 1 > 0
        require((msg.value + 1) > costs, "Not enough ether provided");

        _safeMint(msg.sender, quantity);
    }

    /**
     * @dev Function to airdrop X amount of tokens to all wallets[], can not mint more than maxSupply
     * @param to Array of wallet addesses
     * @param quantity Amount of tokens to be airdropped to each wallet
     */
    function airdrop(address[] calldata to, uint256 quantity) external onlyOwner {
        uint256 totalQuantity = to.length * quantity;
        require(totalSupply() + totalQuantity < maxSupply + 1, "Quantity of tokens exceeds maxSupply");

        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], quantity);
        }
    }

    /**
     * @dev Set the new base URI, only works if the baseURILocked is false
     * @param baseURI_ The new baseURI for the tokens
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        require(!baseURILocked, "The baseURI is locked and can not be changed anymore");
        baseURI = baseURI_;
    }

    /**
     * @notice Lock the baseURI, only do this if the baseURI is correct and you won't
     * have to change it anymore!
     * @dev Lock the baseURI so it can't be changed anymore
     */
    function lockBaseURI() external onlyOwner {
        baseURILocked = true;
    }

    /**
     * @dev Sets the new price for public mint
     * @param _cost The new price for public mint
     */
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    /**
     * @dev Sets the new price for whitelist mint
     * @param _whitelistCost The new price for whitelist mint
     */
    function setWhitelistCost(uint256 _whitelistCost) external onlyOwner {
        whitelistCost = _whitelistCost;
    }

    /**
     * @dev Sets the new Whitelist Merkle Root
     * @param _whitelistMerkleRoot The new Merkle Root for the whitelist
     */
    function setWhitelistMerkleRoot(bytes32  _whitelistMerkleRoot) external onlyOwner {
        whitelistMerkleRoot = _whitelistMerkleRoot; 
    }

    /**
     * @dev Sets the new Free Mint Merkle Root
     * @param _ogMintMerkleRoot The new Merkle Root for the whitelist
     */
    function setOgMintMerkleRoot(bytes32  _ogMintMerkleRoot) external onlyOwner{
        ogMintMerkleRoot = _ogMintMerkleRoot; 
    }

    /**
     * @dev Sets the new maxMintAmount for public sale
     * @param _maxMintAmount The new maxMintAmount for public sale
     */
    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    /**
     * @dev Sets the new maxSupply
     * @param _maxSupply The new maxSupply for the collection
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(!maxSupplyLocked, "Max Supply is locked and can't be changed anymore");
        maxSupply = _maxSupply;
    }

    /**
     * @dev Locks the max Supply so it can't be changed anymore
     */
    function lockMaxSupply() external onlyOwner {
        maxSupplyLocked = true;
    }

    /**
     * @dev Unlock/Lock the public sale
     * @param _publicSaleActive THe new state of publicSaleActive
     */
    function setPublicSaleActive(bool _publicSaleActive) external onlyOwner {
        publicSaleActive = _publicSaleActive;
    }

    /**
     * @dev Locks the max emergency withdraw again, in case it got unlocked
     */
    function lockEmergencyWithdraw() external onlyOwner {
        emergencyWithdrawLocked = true;
    }

    /**
     * @dev Withdraw the funds from the contract, automatically pay a set amount to
     * charities.
     * @param receiver The address that will receive the rest of the balance
     */
    function withdraw(address receiver) external onlyOwner nonReentrant {
        // get contract total balance
        uint256 balance = address(this).balance;

        uint256 wolfAmount = (balance * 2) / 100; // 2%
        uint256 turtleAmount = (balance * 2) / 100; // 2%
        uint256 perfectWorldAmount = (balance * 2) / 100; // 2%
        uint256 advisorAmount = (balance * 5) / 1000; // 0.5%
        uint256 remainingAmount = balance - wolfAmount - turtleAmount - perfectWorldAmount - advisorAmount;

        (bool wolfSuccess,) = payable(WOLF_CONSERVATION_CENTER_WALLET)
            .call{ value: wolfAmount }('');

        (bool turtleSuccess,) = payable(SEE_TURTLE_FOUNDATION_WALLET)
            .call{ value: turtleAmount }('');

        (bool perfectWorldSuccess,) = payable(PERFECT_WORLD_FOUNDATION_WALLET)
            .call{ value: perfectWorldAmount }('');

        (bool advisorSuccess,) = payable(ADVISOR_WALLET)
            .call{ value: advisorAmount }('');

        (bool success,) = payable(receiver).call{ value: remainingAmount }('');

        if (!wolfSuccess || !turtleSuccess || !perfectWorldSuccess || !advisorSuccess || !success) {
            // Unlock the emergency withdraw function if something went wrong
            emergencyWithdrawLocked = false;
        }
    }

    /**
     * @notice Emergency withdraw, can only be used if something went wrong in the regular withdraw function
     * @param receiver The address that will the contract funds
     */
    function emergencyWithdraw(address receiver) external onlyOwner nonReentrant {
        require(!emergencyWithdrawLocked, "Emergency withdraw is locked");
        (bool success,) = payable(receiver).call{ value: address(this).balance }('');
        require(success, "Transfer failed");
    }

}