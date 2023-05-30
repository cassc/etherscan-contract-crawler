// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC721A.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ChiefToads Mint Contract
contract ChiefToads is ERC721A, VRFConsumerBaseV2, Ownable {
    using Strings for uint256;
    using ECDSA for bytes32;

    // -- Chainlink
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 s_subscriptionId;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    address vrfCoordinator;

    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash;

    uint32 callbackGasLimit = 100000;

    uint16 requestConfirmations = 3;

    uint32 numWords = 1;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    // Chainlink --

    string public baseURI;
    bool private _revealed;
    string private _unrevealedBaseURI;

    // Stages
    // 0: Before all minting commence
    // 1: Community List Sale
    // 2: End of community list sale, before Whitelist Sale
    // 3: Whitelist Sale
    // 4: Rizard Sale
    // 5: End of whitelist + rizard, before public sale
    // 6: Public sale
    // 7: End of minting

    uint256 public stage;

    // General Mint Settings
    uint256 public constant totalMaxSupply = 10000;

    // Community Mint Settings
    uint256 public communityMintMaxSupply = 5000;
    uint256 public communityMintMaxPerWallet = 2; // Private Sale Address Mint Cap
    uint256 public communityMintPrice = 0.1 ether; // Private Sale Mint Price
    mapping(address => uint256) public communityMintCount;
    address private communitySignerAddress;

    // Whitelist Mint Settings
    uint256 public whitelistMintMaxPerWallet = 2; // Private Sale Address Mint Cap
    uint256 public whitelistMintPrice = 0.08 ether; // Private Sale Mint Price
    mapping(address => uint256) public whitelistMintCount;
    address private whitelistSignerAddress;

    // Chief Rizard Mint Settings
    uint256 public rizardMintMaxPerWallet = 10;
    uint256 public rizardMintPrice = 0.08 ether;
    mapping(address => uint256) public rizardMintCount;
    address private rizardSignerAddress;

    // Public Sale Mint Settings
    uint256 public publicMintPrice = 0.1 ether;
    uint256 public publicMintMaxPerWallet = 2;
    mapping(address => uint256) public publicMintCount;

    // Dev Mint Settings
    // This counter will help to offset the minting of the dev tokens such that their count will not be counted towards the communityMintMaxSupply
    uint256 public devMintCount;

    // Treasury
    address public treasury;

    // Events
    event PrivateMint(address indexed to, uint256 amount);
    event PublicMint(address indexed to, uint256 amount);
    event DevMint(uint256 count);
    event WithdrawETH(uint256 amountWithdrawn);
    event Revealed(uint256 timestamp);
    event PrivateSaleOpened(bool status, uint256 timestamp);
    event PublicSaleOpened(bool status, uint256 timestamp);

    // Modifiers

    /**
     * @dev Prevent Smart Contracts from calling the functions with this modifier
     */
    modifier onlyEOA() {
        require(msg.sender == tx.origin, "ChiefToads: must use EOA");
        _;
    }

    constructor(
        uint64 subscriptionId,
        address _vrfCoordinator,
        bytes32 _keyHash,
        address _owner,
        address _communitySignerAddress,
        address _whitelistSignerAddress,
        address _rizardSignerAddress,
        string memory _unrevealed
    ) ERC721A("ChiefToad", "CT") VRFConsumerBaseV2(_vrfCoordinator) {
        // -- Chainlink
        require(
            subscriptionId != 0,
            "VRFv2Consumer: subscriptionId must not be 0"
        );
        require(
            _vrfCoordinator != address(0),
            "VRFv2Consumer: vrfCoordinator cannot be 0"
        );
        require(_keyHash != bytes32(0), "VRFv2Consumer: keyHash cannot be 0");
        vrfCoordinator = _vrfCoordinator;
        keyHash = _keyHash;

        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_subscriptionId = subscriptionId;
        // Chainlink --
        _currentIndex = 1;

        setUnrevealedBasedURI(_unrevealed);
        setTreasury(_owner);
        setCommunitySignerAddress(_communitySignerAddress);
        setWhitelistSignerAddress(_whitelistSignerAddress);
        setRizardSignerAddress(_rizardSignerAddress);

        transferOwnership(_owner);
    }

    // -- Chainlink
    function shuffle() external onlyOwner {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
    }

    /**
     * @dev Basically get the first Word of the random value.
     */
    function getRandom() public view returns (uint256) {
        require(
            s_randomWords.length > 0,
            "VRFv2Consumer: No random words available"
        );
        return s_randomWords[0];
    }

    // Chainlink --

    // -------------------- MINT FUNCTIONS --------------------------
    /**
     * @notice Community List Mint
     * @dev 5th July 21:00 to 6th July 03:00
     * 1. 5000 QTY (FCFS)
     * 2. Price = 0.1 ETH
     * 3. Max Mint per wallet = 2
     * @param _mintAmount Amount that is minted
     */
    function communityMint(
        uint256 _mintAmount,
        bytes memory nonce,
        bytes memory signature
    ) external payable onlyEOA {
        // Check if communityMint is open
        require(stage == 1, "ChiefToads: Community Mint is not open");
        // Check if user is whitelisted
        require(
            communitySigned(msg.sender, nonce, signature),
            "ChiefToads: Invalid Signature!"
        );

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * communityMintPrice,
            "ChiefToads: Insufficient ETH!"
        );

        // Check if mints does not exceed communityMintMaxSupply
        require(
            totalSupply() + _mintAmount <=
                communityMintMaxSupply + devMintCount,
            "ChiefToads: Max Supply for Community Mint Reached!"
        );

        // Check if mints does not exceed max wallet allowance for public sale
        require(
            communityMintCount[msg.sender] + _mintAmount <=
                communityMintMaxPerWallet,
            "ChiefToads: Wallet has already minted Max Amount for Community Mint!"
        );

        communityMintCount[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
        emit PrivateMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Whitelist Mint
     * @dev 6th July 21:00 to 7th July 09:00
     * 1. 888 WL ~ 1776 QTY
     * 2. Price = 0.08 ETH
     * 3. Max Mint per wallet = 2
     * @param _mintAmount Amount that is minted
     */
    function whitelistMint(
        uint256 _mintAmount,
        bytes memory nonce,
        bytes memory signature
    ) external payable onlyEOA {
        // Check if user is whitelisted
        require(
            whitelistSigned(msg.sender, nonce, signature),
            "ChiefToads: Invalid Signature!"
        );

        // Check if whitelist sale is open
        require(
            stage == 3 || stage == 4,
            "ChiefToads: Whitelist Mint is not open"
        );

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * whitelistMintPrice,
            "ChiefToads: Insufficient ETH!"
        );

        // Check if mints does not exceed MAX_SUPPLY
        require(
            totalSupply() + _mintAmount <= totalMaxSupply,
            "ChiefToads: Exceeded Max Supply for Chief Toads!"
        );

        // Check if mints does not exceed max wallet allowance for public sale
        require(
            whitelistMintCount[msg.sender] + _mintAmount <=
                whitelistMintMaxPerWallet,
            "ChiefToads: Wallet has already minted Max Amount for Whitelist Mint 2!"
        );

        whitelistMintCount[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
        emit PrivateMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Chief Rizard Mint
     * @dev 6th July 23:00 to 7th 09:00
     * 1. 2336 QTY
     * 2. Price = 0.08 ETH
     * 3. Max Mint per wallet = 10
     * @param _mintAmount Amount that is minted
     */
    function rizardMint(
        uint256 _mintAmount,
        bytes memory nonce,
        bytes memory signature
    ) external payable onlyEOA {
        // Check if user is whitelisted
        require(
            rizardSigned(msg.sender, nonce, signature),
            "ChiefToads: Invalid Signature!"
        );

        // Check if rizard sale is open
        require(stage == 4, "ChiefToads: Rizard Mint is not open");

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * rizardMintPrice,
            "ChiefToads: Insufficient ETH!"
        );

        // Check if mints does not exceed MAX_SUPPLY
        require(
            totalSupply() + _mintAmount <= totalMaxSupply,
            "ChiefToads: Exceeded Max Supply for Chief Toads!"
        );

        // Check if mints does not exceed max wallet allowance for public sale
        require(
            rizardMintCount[msg.sender] + _mintAmount <= rizardMintMaxPerWallet,
            "ChiefToads: Wallet has already minted Max Amount for Rizard Mint!"
        );

        rizardMintCount[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
        emit PrivateMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Public Mint
     * @param _mintAmount Amount that is minted
     */
    function publicMint(uint256 _mintAmount) external payable onlyEOA {
        // Check if public sale is open
        require(stage == 6, "ChiefToads: Public Sale Closed!");

        // Check if enough ETH is sent
        require(
            msg.value == _mintAmount * publicMintPrice,
            "ChiefToads: Insufficient ETH!"
        );

        // Check if mints does not exceed total max supply
        require(
            totalSupply() + _mintAmount <= totalMaxSupply,
            "ChiefToads: Max Supply for Public Mint Reached!"
        );
        require(
            publicMintCount[msg.sender] + _mintAmount <= publicMintMaxPerWallet,
            "ChiefToads: Wallet has already minted Max Amount for Public Mint!"
        );

        publicMintCount[msg.sender] += _mintAmount;

        _safeMint(msg.sender, _mintAmount);
        emit PublicMint(msg.sender, _mintAmount);
    }

    /**
     * @notice Dev Mint
     * @param _mintAmount Amount that is minted
     */
    function devMint(uint256 _mintAmount) external onlyOwner {
        require(
            totalSupply() + _mintAmount <= totalMaxSupply,
            "ChiefToads: Max Supply Reached!"
        );
        devMintCount += _mintAmount;
        _safeMint(owner(), _mintAmount);
    }

    /**
     * @notice Airdrop
     * @param _addresses List of addresses
     */
    function airdrop(address[] memory _addresses) external onlyOwner {
        require(
            totalSupply() + _addresses.length <= totalMaxSupply,
            "ChiefToads: Max Supply Reached!"
        );

        for (uint256 i; i < _addresses.length; i++) {
            _safeMint(_addresses[i], 1);
        }
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
        return whitelistSignerAddress == hash.recover(signature);
    }

    /**
     * @dev Checks if the the signature is signed by a valid signer for communitylist
     * @param sender Address of minter
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     */
    function communitySigned(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return communitySignerAddress == hash.recover(signature);
    }

    /**
     * @dev Checks if the the signature is signed by a valid signer for rizardlist
     * @param sender Address of minter
     * @param nonce Random bytes32 nonce
     * @param signature Signature generated off-chain
     */
    function rizardSigned(
        address sender,
        bytes memory nonce,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(sender, nonce));
        return rizardSignerAddress == hash.recover(signature);
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

        if (_revealed == false) {
            return _unrevealedBaseURI;
        }

        uint256 shift = getRandom();

        return
            bytes(baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        (((tokenId + shift) % totalMaxSupply) + 1).toString()
                    )
                )
                : "";
    }

    // ------------------------- OWNER FUNCTIONS ----------------------------

    /**
     * @dev Set stage of minting
     */
    function setStage(uint256 _newStage) public onlyOwner {
        stage = _newStage;
    }

    /**
     * @dev Set signer address for community mint
     */
    function setCommunitySignerAddress(address signer) public onlyOwner {
        communitySignerAddress = signer;
    }

    /**
     * @dev Set signer address for whitelist mint
     */
    function setWhitelistSignerAddress(address signer) public onlyOwner {
        whitelistSignerAddress = signer;
    }

    /**
     * @dev Set signer address for Rizard Mint
     */
    function setRizardSignerAddress(address signer) public onlyOwner {
        rizardSignerAddress = signer;
    }

    /**
     * @dev Set Community Sale maximum amount of mints
     */
    function setCommunityMaxSupply(uint256 amount) public onlyOwner {
        communityMintMaxSupply = amount;
    }

    function setCommunityMaxMintPerWallet(uint256 amount) public onlyOwner {
        communityMintMaxPerWallet = amount;
    }

    function setWhitelistMaxMintPerWallet(uint256 amount) public onlyOwner {
        whitelistMintMaxPerWallet = amount;
    }

    function setRizardMaxMintPerWallet(uint256 amount) public onlyOwner {
        rizardMintMaxPerWallet = amount;
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
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    /**
     * @notice Set Revealed state of NFT metadata
     */
    function reveal(bool revealed) public onlyOwner {
        _revealed = revealed;
    }

    /**
     * @notice Withdraw all ETH from this account to the owner
     */
    function withdrawFund() external onlyOwner {
        (bool success, ) = payable(treasury).call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed");
    }

    /**
     * @notice Sets the treasury address
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setUnrevealedBasedURI(string memory __unrevealedBaseURI)
        public
        onlyOwner
    {
        _unrevealedBaseURI = __unrevealedBaseURI;
    }
}