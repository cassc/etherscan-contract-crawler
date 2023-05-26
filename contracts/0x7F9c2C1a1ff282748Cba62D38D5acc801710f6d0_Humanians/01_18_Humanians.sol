// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title The Humanians
/// @author MilkyTaste @ Ao Collaboration Ltd.
/// https://thehumanians.com

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721AEnumerable.sol";
import "./Payable.sol";

contract Humanians is ERC721AEnumerable, Payable {
    using Strings for uint256;

    uint256 private maxSalePlusOne = 10000;
    uint256 private maxPresalePlusOne = 9001;
    uint256 private constant RESERVE_MINT_CAP_PLUS_ONE = 501;
    uint256 private reserveMinted = 0;
    uint256 private txLimitPlusOne = 3;
    uint256 public tokenPrice = 0.07 ether;

    // Presale
    uint256 public presaleAllowancePlusOne = 3;
    bytes32 public merkleRoot = "";

    enum ContractState {
        OFF,
        PRESALE,
        PUBLIC,
        PAUSED
    }
    ContractState public contractState = ContractState.OFF;

    string public placeholderURI;
    string public baseURI;

    constructor() ERC721AEnumerable("The Humanians", "HUMAN") {}

    //
    // Modifiers
    //

    /**
     * Do not allow calls from other contracts.
     */
    modifier noBots() {
        require(msg.sender == tx.origin, "Humanians: No bots");
        _;
    }

    /**
     * Ensure current state is correct for this method.
     */
    modifier isContractState(ContractState contractState_) {
        require(contractState == contractState_, "Humanians: Invalid state");
        _;
    }

    /**
     * Ensure amount of tokens to mint is within the limit.
     */
    modifier withinMintLimit(uint256 quantity) {
        if (contractState == ContractState.PRESALE) {
            require((_totalMinted() + quantity) < maxPresalePlusOne, "Humanians: Exceeds available tokens");
        } else {
            require((_totalMinted() + quantity) < maxSalePlusOne, "Humanians: Exceeds available tokens");
        }
        _;
    }

    /**
     * Ensure correct amount of Ether present in transaction.
     */
    modifier correctValue(uint256 expectedValue) {
        require(expectedValue == msg.value, "Humanians: Ether value sent is not correct");
        _;
    }

    //
    // Mint
    //

    /**
     * Public mint.
     * @param quantity Amount of tokens to mint.
     */
    function mintPublic(uint256 quantity)
        external
        payable
        noBots
        isContractState(ContractState.PUBLIC)
        withinMintLimit(quantity)
        correctValue(tokenPrice * quantity)
    {
        require(quantity < txLimitPlusOne, "Humanians: Exceeds transaction limit");
        _safeMint(msg.sender, quantity);
    }

    /**
     * Mint tokens during the presale.
     * @notice This function is only available to those on the allowlist.
     * @param quantity The number of tokens to mint.
     * @param proof The Merkle proof used to validate the leaf is in the root.
     */
    function mintPresale(uint256 quantity, bytes32[] calldata proof)
        external
        payable
        noBots
        isContractState(ContractState.PRESALE)
        withinMintLimit(quantity)
        correctValue(tokenPrice * quantity)
    {
        require(_numberMinted(msg.sender) + quantity < presaleAllowancePlusOne, "Humanians: Exceeds allowance");
        bytes32 leaf = keccak256(abi.encode(msg.sender));
        require(verify(merkleRoot, leaf, proof), "Humanians: Not a valid proof");
        _safeMint(msg.sender, quantity);
    }

    /**
     * Team reserved mint.
     * @param to Address to mint to.
     * @param quantity Amount of tokens to mint.
     */
    function mintReserved(address to, uint256 quantity) external onlyOwner withinMintLimit(quantity) {
        require(reserveMinted + quantity < RESERVE_MINT_CAP_PLUS_ONE, "Humanians: Exceeds allowance");
        reserveMinted += quantity;
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
     * Update token price.
     * @param tokenPrice_ The new token price
     */
    function setTokenPrice(uint256 tokenPrice_) external onlyOwner {
        tokenPrice = tokenPrice_;
    }

    /**
     * Update maximum number of tokens for sale.
     * @param maxSale The maximum number of tokens available for sale.
     */
    function setMaxSale(uint256 maxSale) external onlyOwner {
        uint256 maxSalePlusOne_ = maxSale + 1;
        require(maxSalePlusOne_ < maxSalePlusOne, "Humanians: Can only reduce supply");
        maxSalePlusOne = maxSalePlusOne_;
    }

    /**
     * Update maximum number of tokens for presale.
     * @param maxPresale The maximum number of tokens available for presale.
     */
    function setMaxPresale(uint256 maxPresale) external onlyOwner {
        uint256 maxPresalePlusOne_ = maxPresale + 1;
        require(maxPresalePlusOne_ < maxPresalePlusOne, "Humanians: Can only reduce supply");
        maxPresalePlusOne = maxPresalePlusOne_;
    }

    /**
     * Update maximum number of tokens per transaction in public sale.
     * @param txLimit The new transaction limit.
     */
    function setTxLimit(uint256 txLimit) external onlyOwner {
        uint256 txLimitPlusOne_ = txLimit + 1;
        txLimitPlusOne = txLimitPlusOne_;
    }

    /**
     * Update presale allowance.
     * @param presaleAllowance The new presale allowance.
     */
    function setPresaleAllowance(uint256 presaleAllowance) external onlyOwner {
        presaleAllowancePlusOne = presaleAllowance + 1;
    }

    /**
     * Set the presale Merkle root.
     * @dev The Merkle root is calculated from [address, allowance] pairs.
     * @param merkleRoot_ The new merkle roo
     */
    function setMerkleRoot(bytes32 merkleRoot_) external onlyOwner {
        merkleRoot = merkleRoot_;
    }

    /**
     * Sets base URI.
     * @param baseURI_ The base URI
     */
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * Sets placeholder URI.
     * @param placeholderURI_ The placeholder URI
     */
    function setPlaceholderURI(string memory placeholderURI_) external onlyOwner {
        placeholderURI = placeholderURI_;
    }

    //
    // Views
    //

    /**
     * The block.timestamp when this token was transferred to the current owner.
     * @param tokenId The token id to query
     */
    function holdingSince(uint256 tokenId) public view returns (uint256) {
        return _ownershipOf(tokenId).startTimestamp;
    }

    /**
     * Return sale info.
     * @param addr The address to return sales data for.
     * saleInfo[0]: contractState
     * saleInfo[1]: maxSale (total available tokens)
     * saleInfo[2]: totalMinted
     * saleInfo[3]: tokenPrice
     * saleInfo[4]: numberMinted (by given address)
     * saleInfo[5]: presaleAllowance
     * saleInfo[6]: maxPresale (total available tokens during presale)
     */
    function saleInfo(address addr) public view virtual returns (uint256[7] memory) {
        return [
            uint256(contractState),
            maxSalePlusOne - 1,
            _totalMinted(),
            tokenPrice,
            _numberMinted(addr),
            presaleAllowancePlusOne - 1,
            maxPresalePlusOne - 1
        ];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(uint16(tokenId)), "Humanians: URI query for nonexistent token");

        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : placeholderURI;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
     * Verify the Merkle proof is valid.
     * @param root The Merkle root. Use the value stored in the contract
     * @param leaf The leaf. A [address, availableAmt] pair
     * @param proof The Merkle proof used to validate the leaf is in the root
     */
    function verify(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    /**
     * Change the starting tokenId to 1.
     */
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }
}