// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.4;

/// @title RIP

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "erc721a/contracts/ERC721A.sol";
import "./Payable.sol";

contract RIP is ERC721A, Payable {
    string public baseURI;

    uint256 private constant maxSale = 1800;

    enum ContractState {
        OFF,
        PRESALE,
        PUBLIC
    }
    ContractState public contractState = ContractState.OFF;

    // Public
    uint256 public constant PUBLIC_GETS = 2;

    // Presale
    uint256 public constant PRESALE_GETS = 2;
    bytes32 public merkleRoot = "";

    constructor() ERC721A("RIP", "RIP") Payable(1000) {}

    //
    // Modifiers
    //

    /**
     * Ensure current state is correct for this method.
     */
    modifier isContractState(ContractState contractState_) {
        require(contractState == contractState_, "RIP: Invalid state");
        _;
    }

    /**
     * Ensure amount of tokens to mint is within the limit.
     */
    modifier withinMintLimit(uint256 quantity) {
        require((_totalMinted() + quantity) <= maxSale, "RIP: Exceeds available tokens");
        _;
    }

    //
    // Mint
    //

    /**
     * Public mint.
     */
    function mintPublic() external isContractState(ContractState.PUBLIC) withinMintLimit(PUBLIC_GETS) {
        _safeMint(msg.sender, PUBLIC_GETS);
    }

    /**
     * Mint tokens during the presale.
     * @notice This function is only available to those on the list.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function mintPresale(bytes32[] calldata proof)
        external
        isContractState(ContractState.PRESALE)
        withinMintLimit(PRESALE_GETS)
    {
        require(_numberMinted(msg.sender) == 0, "RIP: Already minted");
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        require(verify(merkleRoot, leaf, proof), "RIP: Not a valid proof");
        _safeMint(msg.sender, PRESALE_GETS);
    }

    /**
     * Team reserved mint.
     * @param to Address to mint to.
     * @param quantity Amount of tokens to mint.
     */
    function mintTeam(address to, uint256 quantity) external onlyOwner {
        _safeMint(to, quantity);
    }

    //
    // Admin
    //

    /**
     * Set contract state.
     * @param contractState_ The new state of the contract.
     */
    function setContractState(ContractState contractState_) external onlyOwner {
        contractState = contractState_;
    }

    /**
     * Update URI.
     * @param _uri The new base URI.
     * @dev Once this method is used each token with have unique metadata.
     */
    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * Set the presale Merkle root.
     * @dev The Merkle root is calculated from addresses.
     * @param merkleRoot_ The new merkle root.
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    //
    // Views
    //

    /**
     * Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId The token id.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token does not exist.");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : "";
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Verify the Merkle proof is valid.
     * @param root The Merkle root. Use the value stored in the contract.
     * @param leaf The leaf. An address.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * @dev Return sale details.
     * saleClaims[0]: maxSale
     * saleClaims[1]: totalSupply
     * saleClaims[2]: contractState
     */
    function saleDetails() public view virtual returns (uint256[3] memory) {
        return [maxSale, totalSupply(), uint256(contractState)];
    }
}