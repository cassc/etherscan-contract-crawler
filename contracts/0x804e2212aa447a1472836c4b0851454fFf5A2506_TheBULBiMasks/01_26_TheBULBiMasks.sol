// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";

contract TheBULBiMasks is ERC721, ERC2981, RevokableDefaultOperatorFilterer, Ownable, ReentrancyGuard, PaymentSplitter {

    using Strings for uint;

    using Counters for Counters.Counter;
    Counters.Counter private _customTokenIdCounter;

    string public uri; // URI
    string public customUri; // URI pour les versions Custom

    bool public uriLocked = false; // Booléen permettant de locker l'URI afin d'éviter qu'elle soit modifiée par la suite
    bool public customUriLocked = false; // Booléen permettant de locker l'URI custom afin d'éviter qu'elle soit modifiée par la suite
    bool public mintPaused = false; // Booléen permettant de changer le statut du mint des BULBiMasks classiques
    bool public customMintPaused = false; // Booléen permettant de changer le statut du mint des BULBiMasks customs

    bytes32 public customWLRoot; // Merkle Tree Root pour les mints custom

    mapping(address => bool) public walletCustomMintStatus; // Booléen permettant de savoir si un wallet WL a déjà mint ou non
    mapping(uint256 => bool) public mintedTokens; // Tracker permettant de savoir si un token a déjà été mint auparavant

    address tcpSmartContractAddress; // Adresse du SC d'origine TCP

    // Events
    event mintPauseUpdated(bool mintPaused);
    event customMintPauseUpdated(bool customMintPaused);
    event newMint(address indexed sender, uint256 tokenId);

    constructor(string memory defaultUri, address[] memory teamMembers, uint[] memory teamShares, address defaultTcpSmartContractAddress) ERC721("TheBULBiMasks", "BULBIMASKS")
    PaymentSplitter(teamMembers, teamShares)
    {
        uri = defaultUri;
        customUri = defaultUri;
        _customTokenIdCounter._value = 555;
        customWLRoot= bytes32(0x0);
        tcpSmartContractAddress = defaultTcpSmartContractAddress;
        _setDefaultRoyalty(_msgSender(), 1000); // Royalties par défaut fixées à 10%    
    } 

    // [Owner] Permet de verrouiller l'URI (une seule fois)
    function lockURI() external onlyOwner {
        require(!uriLocked, "URI already locked");
        uriLocked = true;
    }

    // [Owner] Permet de modifier l'URI (une seule fois)
    function updateURI(string memory newUri) external onlyOwner {
        require(!uriLocked, "URI locked");
        uri = newUri;
    }

    // [Owner] Permet de verrouiller l'URI custom (une seule fois)
    function lockCustomURI() external onlyOwner {
        require(!customUriLocked, "Custom URI already locked");
        customUriLocked = true;
    }

    // [Owner] Permet de modifier l'URI custom (une seule fois)
    function updateCustomURI(string memory newCustomUri) external onlyOwner {
        require(!customUriLocked, "Custom URI locked");
        customUri = newCustomUri;
    }

    // [Owner] Permet d'autoriser ou non le Mint
    function toggleMintPause() external onlyOwner {
        mintPaused = !mintPaused;
        emit mintPauseUpdated(mintPaused);
    }

    // [Owner] Permet d'autoriser ou non le Mint Custom
    function toggleCustomMintPause() external onlyOwner {
        customMintPaused = !customMintPaused;
        emit customMintPauseUpdated(customMintPaused);
    }

    // [Owner] Permet d'update la racine
    function updateCustomWLRoot(bytes32 newRoot) external onlyOwner {
        customWLRoot = newRoot;
    }

    // Merkle Tree checking fx
    // Fonction qui retourne le statut WL d'une adresse
    function isWL(address account, bytes32[] calldata proof) public view returns(bool) {
        return _verify(_leaf(account), proof, customWLRoot);
    }

    function _leaf(address account) internal pure returns (bytes32) { return keccak256(abi.encodePacked(account)); }
    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 root) internal pure returns (bool) { return MerkleProof.verify(proof, root, leaf); }

    // Mint
    function mint(uint256 tokenId) external payable nonReentrant {
        
        require(!_exists(tokenId), "Token already minted."); // Verif token déjà mint
        require(!mintPaused, "Mint is paused."); // Verif mint actif

        if (msg.sender != owner() && msg.sender != IERC721(tcpSmartContractAddress).ownerOf(tokenId)) { // Mint possible par le owner et par le holder du TCP correspondant
            revert("Only the original token owner or contract owner can mint.");
        }

        _safeMint(msg.sender, tokenId);
        mintedTokens[tokenId] = true;  // Tracking
        emit newMint(msg.sender, tokenId);
    }

    // Custom Mint
    function customMint(address to, bytes32[] calldata proof) external payable nonReentrant {

        require(!customMintPaused, "Custom Mint is paused."); // Verif custom mint actif

        uint256 customTokenId = _customTokenIdCounter.current(); // On récupère l'ID du dernier custom mint

        require(!_exists(customTokenId + 1), "Token already minted."); // Verif token déjà mint
        if (msg.sender != owner() && !isWL(msg.sender, proof)) { // Mint possible par le owner et par un wallet WL
            revert("Only WL wallet or contract owner can custom mint.");
        }
        if (msg.sender != owner() && walletCustomMintStatus[msg.sender]) { // Un seul mint par wallet WL, illimité pour le owner
            revert("Only one custom mint per WL wallet.");
        }

        _customTokenIdCounter.increment(); // On incrémente le compteur de mint custom
        walletCustomMintStatus[msg.sender] = true; // Changement du statut (tracking)
        _safeMint(to, customTokenId);
        mintedTokens[customTokenId] = true; // Tracking
        emit newMint(msg.sender, customTokenId);
    }

    // Retourne l'URI d'un token (custom ou non)
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "Inexistent token");

        if (tokenId < 555) {
            return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
        } else {
            return string(abi.encodePacked(customUri, tokenId.toString(), ".json"));
        }

    }

    // [Owner] Fonction de sécurité pour withdraw les fonds présents sur le SC
    function withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }




    // ROYALTIES, ERC-2981 + Operator Filter OpenSea

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

   /**
     * @dev See {IERC721-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC721-approve}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the ERC721 token contract.
     */
    function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

}