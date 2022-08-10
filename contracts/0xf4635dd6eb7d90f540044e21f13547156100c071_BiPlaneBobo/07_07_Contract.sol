// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@erc721a/contracts/ERC721A.sol";

/*
    ██████╗░░░██╗██╗███████╗░░░░░░░█████╗░░█████╗░███╗░░░███╗██╗░█████╗░░██████╗
    ╚════██╗░██╔╝██║╚════██║░░░░░░██╔══██╗██╔══██╗████╗░████║██║██╔══██╗██╔════╝
    ░░███╔═╝██╔╝░██║░░░░██╔╝█████╗██║░░╚═╝██║░░██║██╔████╔██║██║██║░░╚═╝╚█████╗░
    ██╔══╝░░███████║░░░██╔╝░╚════╝██║░░██╗██║░░██║██║╚██╔╝██║██║██║░░██╗░╚═══██╗
    ███████╗╚════██║░░██╔╝░░░░░░░░╚█████╔╝╚█████╔╝██║░╚═╝░██║██║╚█████╔╝██████╔╝
    ╚══════╝░░░░░╚═╝░░╚═╝░░░░░░░░░░╚════╝░░╚════╝░╚═╝░░░░░╚═╝╚═╝░╚════╝░╚═════╝░
*/

contract BiPlaneBobo is ERC721A, Ownable {
    using ECDSA for bytes32;
    // @dev Using errors instead of requires with strings saves gas at deploy time and during reverts
    error SaleNotActive();
    error MaxSupplyReached();
    error NotMintListed();
    error MintingTooMany();
    error NotPublicMintListed();
    error MintListSpotUsed();
    error PublicListSpotUsed();
    error PublicSpotUsed();
    error AlreadyMintedPublic();
    error ContractMintingNotAllowed();

    bool public teamMinted = false;
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public constant MAX_BOBOLIST_SUPPLY = 2500; // Includes 250 team mints
    uint256 public constant TEAM_SUPPLY = 250;
    string public baseUri;
    address public mintListSigningAddr;
    address public teamMintAddr;
    mapping(address => bool) public mintlistMinted;
    mapping(address => bool) public gatedPublicMinted;
    mapping(address => bool) public publicMinted;
    uint256 public mintlistMintedAmt = 0;
    uint256 public gatedPublicMintedAmt = 0;
    uint256 public publicMintedAmt = 0;

    // @dev OFF and COMPLETE are both sale-off states. Distinction is required/used for ease of website sale progression context.
    enum SaleState {
        OFF,
        MINTLIST,
        GATED_PUBLIC,
        PUBLIC,
        COMPLETE
    }
    SaleState public saleState = SaleState.OFF;

    constructor(string memory baseURI, address mintListSigner)
        ERC721A("BiPlane BoBo", "BPBoBo")
    {
        baseUri = baseURI;
        mintListSigningAddr = mintListSigner;
    }

    // Owner functionality ------------------------------------------------------------------------
    /**
     * @notice Sets the base uri of the collection.
     * @param newuri The uri to set.
     */
    function setBaseURI(string memory newuri) external onlyOwner {
        baseUri = newuri;
    }

    /**
     * @notice Sets address that signs mintlist and gated public signatures.
     * @param addr The address to set.
     */
    function setMintListSigningAddress(address addr) external onlyOwner {
        mintListSigningAddr = addr;
    }

    /**
     * @notice Sets the address that is allowed to mint the team mint.
     * @param addr The address to set.
     */
    function setTeamMintAddr(address addr) external onlyOwner {
        teamMintAddr = addr;
    }

    /**
     * @notice Sets mint list sale active. Only one sale state can be active at a time.
     */
    function setMintListSaleActive() external onlyOwner {
        saleState = SaleState.MINTLIST;
    }

    /**
     * @notice Sets gated public sale active. Only one sale state can be active at a time.
     */
    function setGatedPublicSaleActive() external onlyOwner {
        saleState = SaleState.GATED_PUBLIC;
    }

    /**
     * @notice Sets public sale active. Only one sale state can be active at a time.
     */
    function setPublicSaleActive() external onlyOwner {
        saleState = SaleState.PUBLIC;
    }

    /**
     * @notice Turns off sale. Only one sale state can be active at a time.
     */
    function setSaleInactive() external onlyOwner {
        saleState = SaleState.OFF;
    }

    /**
     * @notice Turns off sale. Only one sale state can be active at a time.
     */
    function setSaleComplete() external onlyOwner {
        saleState = SaleState.COMPLETE;
    }

    /**
     * @notice Mints the team allocation of TEAM_SUPPLY.
     * @notice This can only be called once due to teamMinted being set to true in order to prevent multiple team mints.
     */
    function teamMint() external {
        if (_totalMinted() + TEAM_SUPPLY > MAX_SUPPLY)
            revert MaxSupplyReached();
        if (msg.sender != teamMintAddr) revert NotMintListed();
        if (teamMinted) revert MintListSpotUsed();
        teamMinted = true;
        _safeMint(teamMintAddr, TEAM_SUPPLY);
    }

    // Mint functionality ------------------------------------------------------------------------
    /**
     * @notice Validates a signature of an address padded to 32 bytes with a byte suffix of 0x01
     * @param mlSignature The signature to validate
     */
    function mlSignatureValid(bytes calldata mlSignature)
        internal
        view
        returns (bool)
    {
        return
            mintListSigningAddr ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n33",
                    bytes32(uint256(uint160(msg.sender))),
                    int8(1)
                )
            ).recover(mlSignature);
    }

    /**
     * @notice Validates a signature of an address padded to 32 bytes with a byte suffix of 0x02
     * @param mlSignature The signature to validate
     */
    function publicSignatureValid(bytes calldata mlSignature)
        internal
        view
        returns (bool)
    {
        return
            mintListSigningAddr ==
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n33",
                    bytes32(uint256(uint160(msg.sender))),
                    int8(2)
                )
            ).recover(mlSignature);
    }

    /**
     * @notice Function to mint NFTs for users on the mintlist.
     * @param amount The amount of NFTs to mint
     * @param mlSignature The signature to use (signed by our 247 mintListSigningAddress) to validate the user is on the mintlist
     */
    function mlMint(uint256 amount, bytes calldata mlSignature) public {
        if (saleState != SaleState.MINTLIST) revert SaleNotActive();
        if (amount > 2) revert MintingTooMany();
        if (!mlSignatureValid(mlSignature)) revert NotMintListed();
        if (mintlistMinted[msg.sender]) revert MintListSpotUsed();
        if (_totalMinted() + amount > MAX_BOBOLIST_SUPPLY)
            revert MaxSupplyReached();
        mintlistMinted[msg.sender] = true;
        _safeMint(msg.sender, amount);
        mintlistMintedAmt += amount;
    }

    /**
     * @notice Function to mint NFTs for users with access to gated public mint.
     * @param amount The amount of NFTs to mint
     * @param publicSignature The signature to use (signed by our 247 mintListSigningAddress) to validate the user is on the gated public list
     */
    function gatedPublicMint(uint256 amount, bytes calldata publicSignature)
        public
    {
        if (saleState != SaleState.GATED_PUBLIC) revert SaleNotActive();
        if (amount > 2) revert MintingTooMany();
        if (!publicSignatureValid(publicSignature))
            revert NotPublicMintListed();
        if (gatedPublicMinted[msg.sender]) revert PublicListSpotUsed();
        if (_totalMinted() + amount > MAX_SUPPLY) revert MaxSupplyReached();
        gatedPublicMinted[msg.sender] = true;
        _safeMint(msg.sender, amount);
        gatedPublicMintedAmt += amount;
    }

    /**
     * @notice Function to mint NFTs during our public mint.
     * @param amount The amount of NFTs to mint
     */
    function publicMint(uint256 amount) public {
        if (saleState != SaleState.PUBLIC) revert SaleNotActive();
        // Avoid contract minting for public mint
        if (tx.origin != msg.sender) revert ContractMintingNotAllowed();
        if (amount > 2) revert MintingTooMany();
        if (publicMinted[msg.sender]) revert PublicSpotUsed();
        if (_totalMinted() + amount > MAX_SUPPLY) revert MaxSupplyReached();
        publicMinted[msg.sender] = true;
        _safeMint(msg.sender, amount);
        publicMintedAmt += amount;
    }

    /**
     * @dev See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    /**
     * @dev See {ERC721A-_startTokenId}.
     * @notice Sets starting tokenId.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }
}