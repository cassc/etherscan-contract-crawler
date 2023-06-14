//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title A partial interface taken from the IDelegationRegistry by delegate.cash (CC0-1.0 Creative Commons license).
 */
interface IDelegationRegistry {
    function checkDelegateForContract(address delegate, address vault, address contract_) external returns (bool);
}

contract Danks is ERC721AQueryable, ERC2981, DefaultOperatorFilterer, Ownable {
    // Address constants.
    address private constant _DANKS_TEAM_ADDRESS = 0x0Fc518De2FFc1305BDd5d8beee0137EB924e69A2;
    address private constant _DANKS_DEPLOYER_ADDRESS = 0x118c5485b6b76cbc20e722C381B4F671f4c2e1ea;
    address private constant _WL_SNAPSHOT_CONTRACT_ADDRESS = 0xf7D134224A66C6A4DDeb7dEe714A280b99044805;
    address private constant _DELEGATION_REGISTRY_ADDRESS = 0x00000000000076A84feF008CDAbe6409d2FE638B;

    // Minting constants.
    uint256 public constant MAX_SUPPLY = 16999;
    uint256 public constant MAX_PUBLIC_MINT_AMOUNT = 25;

    // Core variables.
    string public baseUri;
    uint256 public price;
    bool public isMintEventActive;
    uint256 public mintEventStartTime;
    string public provenance;

    bytes32 public wlMerkleRoot;
    mapping(address => bool) public wlUsed;

    // Events.
    event PublicMint(address indexed owner, uint256 amount);
    event WlMint(address indexed owner, address indexed vault, uint256 amount);

    // Constructor.
    constructor(
        string memory _baseUri,
        bytes32 _wlMerkleRoot,
        uint256 _mintEventStartTime
    ) ERC721A("DANKS", "$DANKS") {
        setMintEventActive(false);
        setPrice(0.0069 ether);
        setBaseUri(_baseUri);
        setWlMerkleRoot(_wlMerkleRoot);
        setMintEventStartTime(_mintEventStartTime);
        setDefaultRoyalty(_DANKS_TEAM_ADDRESS, 500);
    }

    // OVERRIDES

    // Start token ID.
    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }

    // Base URI.

    function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
        return baseUri;
    }

    // OpenSea royalties.

    function setApprovalForAll(address operator, bool approved) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool){
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // PUBLIC FUNCTIONS.

    /**
     * @notice Public mint.
     * @param mintAmount the number of tokens to claim
     */
    function publicMint(uint256 mintAmount) public payable {
        require(msg.sender == tx.origin, "Contract minting is not allowed");
        require(isMintEventActive, "Mint event is not active");
        require(block.timestamp >= mintEventStartTime, "Mint event has not started yet");
        require(mintAmount <= MAX_PUBLIC_MINT_AMOUNT, "Mint would exceed max amount per mint");
        require((_totalMinted() + mintAmount) <= MAX_SUPPLY, "Mint would exceed max supply");
        require(msg.value >= (mintAmount * price), "ETH value sent is not correct");

        _safeMint(msg.sender, mintAmount, "");

        emit PublicMint(msg.sender, mintAmount);
    }

    /**
     * @notice WL mint.
     * @param vault if using delegate.cash (for contract or entire vault) - the address that held the tokens in the snapshot,
                    if not using delegation - 0x000..000 or msg.sender.
     * @param mintAmount the number of tokens to claim
     * @param merkleProof the Merkle proof for this claimer
     */
    function wlMint(address vault, uint mintAmount, bytes32[] calldata merkleProof) public payable {
        require(isMintEventActive, "Mint event is not active");
        require(block.timestamp >= mintEventStartTime, "Mint event has not started yet");
        require((_totalMinted() + mintAmount) <= MAX_SUPPLY, "Mint would exceed max supply");

        address claimer = msg.sender;
        if (vault != address(0) && vault != msg.sender) {
            require(
                IDelegationRegistry(_DELEGATION_REGISTRY_ADDRESS).checkDelegateForContract(msg.sender, vault, _WL_SNAPSHOT_CONTRACT_ADDRESS),
                "Claimer is not allowed to act on behalf of the vault"
            );
            claimer = vault;
        }

        bytes32 merkleLeaf = keccak256(abi.encodePacked(claimer, mintAmount));
        require(MerkleProof.verify(merkleProof, wlMerkleRoot, merkleLeaf), "Invalid WL merkle proof");

        require(!wlUsed[claimer], "WL mint allocation is already used");

        wlUsed[claimer] = true;
        _safeMint(msg.sender, mintAmount, "");

        emit WlMint(msg.sender, vault, mintAmount);
    }

    // OWNER FUNCTIONS.

    // Withdraw.
    function withdraw() public onlyOwner {
        uint256 balanceBps = address(this).balance / 10000;
        payable(_DANKS_TEAM_ADDRESS).transfer(balanceBps * 7000);
        payable(_DANKS_DEPLOYER_ADDRESS).transfer(balanceBps * 3000);
    }

    // Set price.
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    // Set base URI.
    function setBaseUri(string memory _uri) public onlyOwner {
        baseUri = _uri;
    }

    // Set mint event status.
    function setMintEventActive(bool _isActive) public onlyOwner {
        isMintEventActive = _isActive;
    }

    // Sent mint event start time.
    function setMintEventStartTime(uint256 _time) public onlyOwner {
        mintEventStartTime = _time;
    }

    // Set WL merkle tree root.
    function setWlMerkleRoot(bytes32 _wlMerkleRoot) public onlyOwner {
        wlMerkleRoot = _wlMerkleRoot;
    }

    // Set provenance.
    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    // Set royalties info.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }
}