// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";

import {UpdatableOperatorFilterer} from "./UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "./RevokableDefaultOperatorFilterer.sol";

contract B4DBULL is ERC721A, ERC2981, RevokableDefaultOperatorFilterer, Ownable, ReentrancyGuard, PaymentSplitter {    

    using Strings for uint;

    uint256 public supply = 666; // Supply total

    string public uri; // URI
    bool public isUriLocked = false; // Booléen permettant de locker l'URI afin d'éviter qu'elle soit modifiée par la suite
    bool public isRevealed = false;  // Booléen permettant de passer de l'URI native commune à une URI spécifique par token (post reveal)

    // DynamicNFT
    uint256 public dynamicTokenId;

    // Steps
    enum Step { Pause, PhaseOne, PhaseTwo, PhaseThree, PhaseFour, SoldOut }
    Step public currentStep;

    // Events
    event stepUpdated(Step currentStep);
    event newMint(address indexed owner, uint256 startId, uint256 number);

    // Structures + mappings
    struct mintGroup {
        string name;
        uint256 price;
        uint256 maxPerWallet;
        bytes32 merkleTreeRoot;
        bool exists;
    }

    struct mintTracker {
        uint[7] groupTracker;
    }

    mapping(address => mintTracker) mintTrackers;
    mapping(uint256 => mintGroup) public mintGroups;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    constructor(string memory defaultUri, address[] memory teamMembers, uint[] memory teamShares) ERC721A("B4D BULL", "B4D")
    PaymentSplitter(teamMembers, teamShares)
    {
        uri = defaultUri;
        _setDefaultRoyalty(_msgSender(), 750); // Royalties par défaut fixées à 7.5%

        dynamicTokenId = 0;

        mintGroups[0] = mintGroup({ name: "PhaseOneYoungBull", price: 0.019 ether, maxPerWallet: 1, merkleTreeRoot: bytes32(0x62cb0af8199dd1c757bda80ed6f2041886f480fcda31c10bc1a5214f7c7dd3dc), exists: true });
        mintGroups[1] = mintGroup({ name: "PhaseOneBull", price: 0.016 ether, maxPerWallet: 1, merkleTreeRoot: bytes32(0xe49e59ec59f0814db223376378b686b7c609cc7a572e0150c3842993b7c354df), exists: true });
        mintGroups[2] = mintGroup({ name: "PhaseOneOldBull", price: 0.014 ether, maxPerWallet: 2, merkleTreeRoot: bytes32(0xffdfcd83207f952764f8aa33dad74aaeafb9176bf3110c18937719b50ad74a06), exists: true });
        mintGroups[3] = mintGroup({ name: "Public", price: 0.025 ether, maxPerWallet: 3, merkleTreeRoot: bytes32(0x0), exists: true });
        mintGroups[4] = mintGroup({ name: "PhaseThreeBull", price: 0.022 ether, maxPerWallet: 3, merkleTreeRoot: bytes32(0xb55c3e3c47aff881310504da35633c02dedf285e27fec663b70a666079617900), exists: true });
        mintGroups[5] = mintGroup({ name: "PhaseTwoOldBull", price: 0.019 ether, maxPerWallet: 3, merkleTreeRoot: bytes32(0xd2d8bb4234e4063e481b537cd7ea31c0ab009d1894e8fc1464ea7829313d18de), exists: true });
        mintGroups[6] = mintGroup({ name: "FreeMint", price: 0 ether, maxPerWallet: 1, merkleTreeRoot: bytes32(0x465a7b33c5171b235a401f260b9ee53cf66d087076f645ff6e8ffe8d5840ef56), exists: true });

    }

    // [R-Public | U-Owner] Mint groups & trackers
    function updatemintGroup(uint256 group, string memory name, uint256 price, uint256 maxPerWallet, bytes32 merkleTreeRoot, bool exists) external onlyOwner {
        require(mintGroups[group].exists, "Invalid group");
        mintGroups[group] = mintGroup(name, price, maxPerWallet, merkleTreeRoot, exists);
    }

    function updatemintGroupPrice(uint256 group, uint256 price) external onlyOwner {
        require(mintGroups[group].exists, "Invalid group");
        mintGroups[group].price = price;
    }

    function updatemintGroupMerkleTreeRoot(uint256 group, bytes32 merkleTreeRoot) external onlyOwner {
        require(mintGroups[group].exists, "Invalid group");
        mintGroups[group].merkleTreeRoot = merkleTreeRoot;
    }

    function getMintGroup(uint256 group) public view returns (mintGroup memory) {
        require(mintGroups[group].exists, "Invalid group");
        return mintGroups[group];
    }

    function getMintTracker(uint group, address wallet) public view returns (uint) {
        require(group < 7, "Invalid group");
        return mintTrackers[wallet].groupTracker[group];
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Merkle Tree checking fx
    function isOnList(address account, bytes32[] calldata proof, uint group) public view returns (bool) {
        require(group < 7, "Invalid group");

        if (group != 3) { // Groupe soumis à WL
            return _verify(_leaf(account), proof, mintGroups[group].merkleTreeRoot);
        } else { // Groupe public, pas de WL
            return true;
        }
    }

    function _leaf(address account) internal pure returns (bytes32) { return keccak256(abi.encodePacked(account)); }
    function _verify(bytes32 leaf, bytes32[] memory proof, bytes32 root) internal pure returns (bool) { return MerkleProof.verify(proof, root, leaf); }

    // Mint
    function mint(bytes32[] calldata proof, uint256 group, uint256 amount) public payable nonReentrant {
        require(currentStep >= Step.PhaseOne && currentStep <= Step.PhaseFour, "Please wait for the mint phase");
        require(totalSupply() + amount <= supply, "Max supply reached");

        // Forcing des groupes disponibles suivant la phase
        if (currentStep == Step.PhaseOne) {
            require(group == 0 || group == 1 || group == 2 || group == 6, "Invalid mint group for this phase");
        } else if (currentStep == Step.PhaseTwo) {
            require(group >= 5 && group <= 6, "Invalid mint group for this phase");
        } else if (currentStep == Step.PhaseThree) {
            require(group >= 4 && group <= 6, "Invalid mint group for this phase");
        } else if (currentStep == Step.PhaseFour) {
            require(group >= 3 && group <= 6, "Invalid mint group for this phase");
        }

        require(isOnList(msg.sender, proof, group), "Not whitelisted for this mint group"); // WL check
        require(msg.value >= mintGroups[group].price * amount, "Not enough ETH");
        require(mintTrackers[msg.sender].groupTracker[group] + amount <= mintGroups[group].maxPerWallet, "Amount exceed the limit or max mint reached for this mint group"); // Tracker check
        mintTrackers[msg.sender].groupTracker[group] += amount; // Tracker update
        _safeMint(msg.sender, amount);
        emit newMint(msg.sender, totalSupply() - amount, amount);
    }

    // [Owner] Fonction qui met à jour l'étape actuelle
    function updateStep(Step step) external onlyOwner {
        currentStep = step;
        emit stepUpdated(currentStep);
    }

    // [Owner] Permet de passer en mode reveal (une seule fois)
    function reveal() external onlyOwner {
        require(!isRevealed, "Already revealed");
        isRevealed = true;
    }

    // [Owner] Permet de verrouiller l'URI (une seule fois)
    function lockURI() external onlyOwner {
        require(!isUriLocked, "URI already locked");
        isUriLocked = true;
    }

    // [Owner] Permet de modifier l'URI tant qu'elle n'est pas verrouillée
    function updateURI(string memory newUri) external onlyOwner {
        require(!isUriLocked, "URI locked");
        uri = newUri;
    }

    // [Owner] Permet de modifier l'ID du token évolutif tant que l'URI n'est pas verrouillé 
    function updateDynamicTokenId(uint256 newId) external onlyOwner {
        require(!isUriLocked, "URI locked");
        dynamicTokenId = newId;
    }

    // Retourne l'URI, soit dans sa version de base en mode "unrevealed", soit dans sa version définitive avec un code spécifique pour le token dynamique
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(_exists(tokenId), "Inexistent token");

        if (!isRevealed) { return uri; }

        if (tokenId == dynamicTokenId) {
            uint256 lastTransfer = _ownershipOf(tokenId).startTimestamp; // Specific ERC721A
            uint256 diff = block.timestamp - lastTransfer;
            string memory evPhase;

            if (diff > 120 days) {
                evPhase = "5";
            } else if (diff > 60 days) {
                evPhase = "4";
            } else if (diff > 30 days) {
                evPhase = "3";
            } else if (diff > 15 days) {
                evPhase = "2";
            } else { evPhase = "1"; }

            return string(abi.encodePacked(uri, tokenId.toString(), "_", evPhase, ".json"));
        } else {
            return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
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
    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public payable
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
     // Fonction modifiée pour implémenter l'ERC721A
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}