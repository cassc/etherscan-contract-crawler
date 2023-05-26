// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { ERC721A } from "ERC721A/ERC721A.sol";
import { ERC2981 } from "openzeppelin/token/common/ERC2981.sol";
import { OperatorFilterer } from "operator-filter-registry/src/OperatorFilterer.sol";
import { CANONICAL_CORI_SUBSCRIPTION } from "operator-filter-registry/src/lib/Constants.sol";

/**
 * @title Uniforge Collection
 * @author Dapponics
 * @notice UniforgeCollection is an optimized and universal token
 * contract that extends ERC721A with enforced royalty capabilities.
 */
contract UniforgeCollection is Ownable, ERC721A, ERC2981, OperatorFilterer{
    uint256 private immutable _maxSupply;
    uint256 private immutable _mintLimit;
    uint256 private _mintFee;
    uint256 private _saleStart;
    bool private _lockedBaseURI;
    string private _baseTokenURI;
    address private _royaltyReceiver;
    uint96 private _royaltyPercentage;
    bool private _royaltyEnforced;

    event BaseURIUpdated(string baseURI);
    event RoyaltyEnforced(bool indexed enforced);
    event MintFeeUpdated(uint256 indexed mintFee);
    event SaleStartUpdated(uint256 indexed saleStart);
    event RoyaltyUpdated(address indexed royaltyReceiver, uint96 indexed royaltyPercentage);

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    /**
     * @notice Transfers ownership to the contract creator and declares all the variables.
     * @param owner_ The address of the new owner of the contract.
     * @param name_ The name of the new ERC721 token.
     * @param symbol_ The symbol of the new ERC721 token.
     * @param baseURI_ The base Uniform Resource Identifier (URI) of the new ERC721 token.
     * @param mintFee_ The fee for minting a single token while the public sale is open.
     * @param mintLimit_ The maximum number of tokens that can be minted at once.
     * @param maxSupply_ The maximum total number of tokens that can be minted.
     * @param saleStart_ The timestamp representing the start time of the public sale.
     * @param royaltyReceiver_ The address of the new royalty receiver of the contract.
     * @param royaltyPercentage_ The percentage of the royalty for the ERC2981 standard.
     * @param royaltyEnforced_ The boolean that enables or disables the Operator Filter.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 mintFee_,
        uint256 mintLimit_,
        uint256 maxSupply_,
        uint256 saleStart_,
        address royaltyReceiver_,
        uint96 royaltyPercentage_,
        bool royaltyEnforced_
    ) ERC721A (name_, symbol_) OperatorFilterer(
        CANONICAL_CORI_SUBSCRIPTION,
        true
    ){
        transferOwnership(owner_);
        _baseTokenURI = baseURI_;
        _mintFee = mintFee_;
        _mintLimit = mintLimit_;
        _maxSupply = maxSupply_;
        _saleStart = saleStart_;
        _royaltyReceiver = royaltyReceiver_;
        _royaltyPercentage = royaltyPercentage_;
        _royaltyEnforced = royaltyEnforced_;
        _setDefaultRoyalty(royaltyReceiver_, royaltyPercentage_);
    }

    // =============================================================
    //                         MINT FUNCTIONS
    // =============================================================

    /**
     * @notice Mints `quantity` tokens to the caller of the function. 
     * The caller has to send `_mintFee`*`quantity` ether and the sale should be open.
     * The `quantity` has to be greater than 0 and less than or equal to `_mintLimit`.
     * @param quantity The number of tokens to mint.
     */
    function mintNft(uint256 quantity) external payable {
        // Verify that the sale is open.
        if (block.timestamp < _saleStart) revert UniforgeCollection__SaleIsNotOpen();

        // Verify that the mint amount is valid.
        if (quantity > _mintLimit) revert UniforgeCollection__InvalidMintAmount();

        // Verify that the supply will not be exceeded.
        if (_totalMinted() + quantity > _maxSupply) revert UniforgeCollection__MaxSupplyExceeded();

        // Verify that the ether value is correct.
        if (msg.value < _mintFee * quantity) revert UniforgeCollection__NeedMoreETHSent();

        _safeMint(msg.sender, quantity);
    }

    /**
     * @notice Allows the contract owner to mint NFTs without constraints for marketing purposes.
     * @param receiver The address to receive the minted tokens.
     * @param quantity The number of tokens to mint.
     */
    function creatorMint(address receiver, uint256 quantity) external onlyOwner {
        // Verify that the supply will not be exceeded.
        if (_totalMinted() + quantity > _maxSupply) revert UniforgeCollection__MaxSupplyExceeded();

        _safeMint(receiver, quantity);
    }

    // =============================================================
    //                     PUBLIC SALE FUNCTIONS
    // =============================================================

    /**
     * @dev Sets the new starting timestamp of the public sale.
     * @param timestamp The new starting timestamp.
     */
    function setSaleStart(uint256 timestamp) external onlyOwner {
        _saleStart = timestamp;
        emit SaleStartUpdated(timestamp);
    }

    /**
     * @notice Allows the contract owner to set the fee required to mint a single token.
     * @param newMintFee The fee of minting a single token.
     */
    function setMintFee(uint256 newMintFee) external onlyOwner {
        _mintFee = newMintFee;
        emit MintFeeUpdated(newMintFee);
    }

    /**
     * @notice Allows the contract owner to withdraw the ether balance of the contract.
     */
    function withdraw() external onlyOwner {
        (bool _ownerSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!_ownerSuccess) revert UniforgeCollection__TransferFailed();
    }

    // =============================================================
    //                       METADATA FUNCTIONS
    // =============================================================

    /**
     * @notice Allows the contract owner to set the baseURI of the ERC721 token metadata.
     * If `_lockedBaseURI` is true, `_baseTokenURI` is locked and this function reverts.
     * @param newBaseURI The new baseURI string.
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        // Verify that the metadata is not locked.
        if (_lockedBaseURI) revert UniforgeCollection__LockedBaseURI();
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @notice Allows the contract owner to irreversibly lock the state of `_baseTokenURI`.
     * The metadata of this contract freezes forever at the moment this function is called.
     */
    function lockBaseURI() external onlyOwner {
        _lockedBaseURI = true;
    }

    // =============================================================
    //                       ROYALTY FUNCTIONS
    // =============================================================

    /**
     * @notice Allows the contract owner to set the royalty receiver and the royalty percentage.
     * @param receiver The address of the royalty fees receiver.
     * @param feeNumerator The royalty percentage in basis points (e.g. 1% = 100).
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _royaltyReceiver = receiver;
        _royaltyPercentage = feeNumerator;
        _setDefaultRoyalty(receiver, feeNumerator);
        emit RoyaltyUpdated(receiver, feeNumerator);
    }

    /**
     * @notice Enables or disables the royalty enforcement for marketplaces. This toggle empowers
     * creators with revenue strategies while giving them the option to remain fully independent.
     *
     * When `_royaltyEnforced` is set to true, this contract overrides the approval and transfer 
     * operations, allowing NFTs of this contract to trade only in ERC2981 compliant marketplaces.
     *
     * When `_royaltyEnforced` is set to false, this contract bypases the registry allowing NFTs
     * to be traded in every marketplace and making users save gas for every market transaction. 
     * Please note that some marketplaces will disable creator earnings enforcement.
     */
    function toggleRoyaltyEnforcement() external onlyOwner {
        bool enforced = _royaltyEnforced;
        _royaltyEnforced = !enforced;
        emit RoyaltyEnforced(!enforced);
    }

    /**
     * @notice Checks the operator if `_royaltyEnforced` is true.
     */
    function setApprovalForAll(address operator, bool approved) public override {
        if(_royaltyEnforced) _checkFilterOperator(operator);
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Checks the operator if `_royaltyEnforced` is true.
     */
    function approve(address operator, uint256 tokenId) public payable override {
        if(_royaltyEnforced) _checkFilterOperator(operator);
        super.approve(operator, tokenId);
    }

    /**
     * @notice Checks the operator if `_royaltyEnforced` is true and `from` is not the caller.
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable override {
        if(_royaltyEnforced)
            if (from != msg.sender) _checkFilterOperator(msg.sender);
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Checks the operator if `_royaltyEnforced` is true and `from` is not the caller.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override {
        if(_royaltyEnforced)
            if (from != msg.sender) _checkFilterOperator(msg.sender);
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Checks the operator if `_royaltyEnforced` is true and `from` is not the caller.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override {
        if(_royaltyEnforced)
            if (from != msg.sender) _checkFilterOperator(msg.sender);
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =============================================================
    //                         VIEW FUNCTIONS
    // =============================================================

    /**
     * @notice Returns true if this contract supports the provided interface.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    /**
    * @notice Helper function for update the metadata of the contract.
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Returns the baseURI of the ERC721 token metadata.
     */
    function baseURI() external view returns (string memory) {
        return _baseURI();
    }

    /**
     *  @notice Returns true if the baseURI state is locked.
     */
    function lockedBaseURI() external view returns (bool) {
        return _lockedBaseURI;
    }

    /**
     * @notice Returns the maximum total number of tokens that can be minted.
     */
    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    /**
     * @notice Returns the fee for minting a single token.
     */
    function mintFee() external view returns (uint256) {
        return _mintFee;
    }

    /**
     * @notice Returns the maximum number of tokens that can be minted at once.
     */
    function mintLimit() external view returns (uint256) {
        return _mintLimit;
    }

    /**
     * @notice Returns the starting timestamp of the public sale.
     */
    function saleStart() external view returns (uint256) {
        return _saleStart;
    }

    /**
     * @notice Returns the address of the royalty receiver.
     */
    function royaltyReceiver() external view returns (address) {
        return _royaltyReceiver;
    }
    
    /**
     * @notice Returns the royalty percentage of the collection.
     */
    function royaltyPercentage() external view returns (uint96) {
        return _royaltyPercentage;
    }
 
    /**
     * @notice Returns true if the royalty is enforced on-chain.
     */
    function royaltyEnforced() external view returns (bool) {
        return _royaltyEnforced;
    }
}

/**
 * @notice UniforgeCollection custom errors.
 */
error UniforgeCollection__LockedBaseURI();
error UniforgeCollection__TransferFailed();
error UniforgeCollection__MaxSupplyExceeded();
error UniforgeCollection__InvalidMintAmount();
error UniforgeCollection__NeedMoreETHSent();
error UniforgeCollection__SaleIsNotOpen();