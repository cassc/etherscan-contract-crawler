// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721A.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/** 
    ____  ___    ____  ___    __    __    ___   _  __
   / __ \/   |  / __ \/   |  / /   / /   /   | | |/ /
  / /_/ / /| | / /_/ / /| | / /   / /   / /| | |   / 
 / ____/ ___ |/ _, _/ ___ |/ /___/ /___/ ___ |/   |  
/_/   /_/  |_/_/ |_/_/  |_/_____/_____/_/  |_/_/|_|  

*/
/// @title ParallaxGenesis Mint Contract
/// @author GEN3 Studios
contract ParallaxGenesis is ERC721A, Ownable, Pausable {
    using Strings for uint256;
    using ECDSA for bytes32;

    string private baseURI;
    bool private _revealed;
    string private _unrevealedBaseURI;
    address private treasury;

    // General Mint Settings
    uint256 public maxSupply = 777;
    uint256 public nftPrice = 0.35 ether;
    uint256 public maxNftPerWallet = 1;

    // Sale toggles 
    bool public presaleActive = false; 
    bool public publicSaleActive = false; 

    // Off-chain whitelist Variables
    address private signerAddress;

    mapping(address => uint256) public nftMintCount;

    // Events
    event PrivateMint(address indexed to, uint256 amount);
    event PublicMint(address indexed to, uint256 amount);
    event DevMint(uint256 amount);
    event WithdrawETH(uint256 amountWithdrawn);
    event Revealed(uint256 timestamp);

   
    // -------------------- MODIFIERS --------------------------

    /**
     * @dev Prevent Smart Contracts from calling the functions with this modifier
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "PARALLAX: ONLY EOA");
        _;
    }   

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _initBaseURI,
        address _newOwner,
        address _signerAddress,
        address _treasury
    ) ERC721A(name_, symbol_) {
        _currentIndex = 1; // required for ERC721A since it starts from 0
        setNotRevealedURI(_initBaseURI);
        transferOwnership(_newOwner);
        signerAddress = _signerAddress;
        treasury = _treasury;
    }

    // -------------------- MINT FUNCTIONS --------------------------

    /// @notice Allows owner of smart contract to mint for free
    /// @param _mintAmount Amount to mint for Dev
    function devMint(uint256 _mintAmount) public onlyEOA onlyOwner {
        require(
            totalSupply() + _mintAmount <= maxSupply,
            "PARALLAX: EXCEEDED MAX SUPPLY"
        );

        _mint(msg.sender, _mintAmount, "", true);
        emit DevMint(_mintAmount);
    }
    /**
     * @notice Private Mint for users who are whitelisted
     * @param signature Signature retrieved from backend for Parallax whitelist
     * @param nonce Random nonce retrieved from backend for Parallax whitelist
     */
    function privateMint(
        bytes memory nonce,
        bytes memory signature
    ) external payable onlyEOA whenNotPaused {
        // Check if user is whitelisted
        require(
            whitelistSigned(msg.sender, nonce, signature),
            "PARALLAX: INVALID SIGNATURE"
        );

        // Check if public sale is open
        require(presaleActive, "PARALLAX: PRIVATE SALE CLOSED");

        // Check if enough ETH is sent
        require(
            msg.value >= nftPrice,
            "PARALLAX: INSUFFICIENT ETH"
        );

        // Check if mints exceed maxSupply
        require(
            totalSupply() + 1 <= maxSupply,
            "PARALLAX: EXCEEDED MAX SUPPLY"
        );

        // Check that mints does not exceed max wallet allowance for parallax
        require(
            nftMintCount[msg.sender] + 1 <=
                maxNftPerWallet,
            "PARALLAX: MAXIMUM AMOUNT MINTED"
        );

        nftMintCount[msg.sender] += 1;

        _mint(msg.sender, 1, "", true);
        emit PrivateMint(msg.sender, 1);
    }

    /**
     * @notice Public Mint
     */
    function publicMint() external payable onlyEOA whenNotPaused{
        // Check if public sale is open
        require(publicSaleActive, "PARALLAX: Public Sale Closed!");

        // Check if enough ETH is sent
        require(
            msg.value >= nftPrice,
            "PARALLAX: Insufficient ETH!"
        );

        // Check if mints does not exceed maxSupply
        require(
            totalSupply() + 1 <= maxSupply,
            "PARALLAX: Max Supply for Public Mint Reached!"
        );

        // Check that mints does not exceed max wallet allowance for public sale
        require(
            nftMintCount[msg.sender] + 1 <= maxNftPerWallet,
            "PARALLAX: Wallet has already minted Max Amount for Public Sale"
        );

        nftMintCount[msg.sender] += 1;

        _mint(msg.sender, 1, "", true);
        emit PublicMint(msg.sender, 1);
    }

    // -------------------- WHITELIST FUNCTION ----------------------

    /**
     * @dev Checks if the the signature is signed by a valid signer for whitelist
     * @param sender Address of minter
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     */
    function whitelistSigned(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return signerAddress == hash.recover(signature);
    }

    // ---------------------- VIEW FUNCTIONS ------------------------
    /**
     * @dev See {IERC721Metadata-tokenURI}.
     * @dev gets baseURI from contract state variable
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (!_revealed) {
            return _unrevealedBaseURI;
        }

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // ------------------------- OWNER FUNCTIONS ----------------------------
    /**
     * @notice Set presale state
     * @param _presaleState New presale state
    */
    function setPresaleState(bool _presaleState) external onlyOwner {
        presaleActive = _presaleState;
    }

    /**
     * @notice Set public sale state
     * @param _publicSaleState New public sale state 
    */
    function setPublicSaleState(bool _publicSaleState) external onlyOwner {
        publicSaleActive = _publicSaleState;
    }

    /**
     * @notice Set max supply of collection
     * @param _maxSupply New max supply of the collection 
     * @dev Can be used to "cap" the collection
    */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply <= 777, "PARALLAX: ONLY REDUCE ALLOWED");
        maxSupply = _maxSupply;
    }

    /**
     * @notice Set new mint price of collection
     * @param _newPrice New price nft minting
     * @dev Only use for contingencies
    */
    function setPrice(uint256 _newPrice) external onlyOwner {
        nftPrice = _newPrice;
    }

    /**
     * @notice Pauses all minting except devMint
    */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses all minting except devMint
    */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Set Private Sale maximum amount of mints
     */
    function setSignerAddress(address _signerAddress) external onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @dev Set the unrevealed URI
     * @param newUnrevealedURI unrevealed URI for metadata
     */
    function setNotRevealedURI(string memory newUnrevealedURI)
        public
        onlyOwner
    {
        _unrevealedBaseURI = newUnrevealedURI;
    }

    /**
     * @dev Set Revealed Metadata URI
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Set Revealed state of NFT metadata
     */
    function reveal(bool revealed) external onlyOwner {
        _revealed = revealed;
        emit Revealed(block.timestamp);
    }

    /**
    * @notice Set treasury address for withdrawal
    */
    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    /**
     * @notice Withdraws ETH from smart contract to treasury
     */
    function withdrawToTreasury() external onlyOwner {
        (bool success, ) = treasury.call{ value: address(this).balance }(""); // returns boolean and data
        require(success, "PARALLAX: WITHDRAWAL FAILED");
        emit WithdrawETH(address(this).balance);
  }
}