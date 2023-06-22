// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import {ERC721A} from "../lib/erc721a/contracts/ERC721A.sol";
import {ERC2981} from "../lib/openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {Owned} from "../lib/solmate/src/auth/Owned.sol";
import {ReentrancyGuard} from "../lib/solmate/src/utils/ReentrancyGuard.sol";
import {MerkleProofLib} from "../lib/solmate/src/utils/MerkleProofLib.sol";
import {OperatorFilterer} from "../lib/closedsea/src/OperatorFilterer.sol";

// @title Optimized Minting Contract with TransferLocks, OS operator filter &
// follows the ERC2981 Standard. 
// @author 0xsku, twitter: @iamsku_
contract ONE_ETH_FP_Phase3 is ERC721A, ERC2981, Owned, ReentrancyGuard, OperatorFilterer {

    // =============================================================
    //                            STORAGE
    // =============================================================

    // Max Supply to be minted at 0.1/pass.
    uint256 public maxSupply = 1000;
    uint256 public mintPrice = 0.1 ether;

    // State to depict if sale is active or not.
    bool public saleActive;

    // State to depict if transfers/listings between EOAS/CONTRACTS is active or not.
    bool public transfersLocked;
    bool public listingsLocked;

    // State to depict if Openseas filter is active or not.
    bool public operatorFilteringEnabled;

    bytes32 public merkleRoot;
    string public baseURI;

    // Checks to see if the collection is sold out. Modifier since we will be using this multiple times.
    modifier StockCount(uint256 _amount) {
        if (totalSupply() + _amount >= maxSupply) revert SoldOut();
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================
    
    constructor(bytes32 _merkleRoot, string memory _newURI, uint96 _royaltyFee) ERC721A("1ETHFP_PH3", "1ETHFP") Owned(msg.sender) {
        
        // Sets royalties on-chain using the ERC2981 standard.
        _setDefaultRoyalty(msg.sender, _royaltyFee);

        // Subscribes to Openseas default operator filter.
        _registerForOperatorFiltering();

        // Enables the Opensea filter modifier to ensure it is checked before transfers.
        operatorFilteringEnabled = true;

        // Lock Transfers from any type of address.
        transfersLocked = true;
        
        // Locks Listings
        listingsLocked = true;

        // Sets the BASEURI for all tokens.
        baseURI = _newURI;

        // Sets the merkleRoot.
        merkleRoot = _merkleRoot;
    }

    // =============================================================
    //                          MINTING
    // =============================================================

    /**
     * @notice Allows users to mint any amount of passes as long as mint price is respected &
     * provides a valid proof.
     * @dev We use _mint() instead of _safeMint() since we are manually adding security checks with ReentrancyGuard &
     * ensuring tx.origin is from a EOA.
     */
    function mintPass(uint256 _amount, bytes32[] calldata _proof) external payable StockCount(_amount) nonReentrant {
        if (!saleActive) revert SaleNotActive();
        if (tx.origin != msg.sender) revert NotEOA();
        if (_amount <= 0) revert InvalidMintAmount();
        if (msg.value != _amount * mintPrice) revert IncorrectMintPrice();
        if (!MerkleProofLib.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();

        _mint(msg.sender, _amount);
    }

    /**
     * @notice Allows the owner of the contract to mint any amount of passes for free as long as
     * supply is respected.
     */
    function teamMint(uint256 _amount, address _recipient) external onlyOwner StockCount(_amount) {
        _mint(_recipient, _amount);
    }

    // =============================================================
    //                          ADMIN
    // =============================================================

    /**
     * @notice Allows the owner of the contract to burn a pass incase of stolen passes
     * or any situation deemed fit to burn a pass.
     */
    function burnPass(uint256[] calldata _tokenIds) external onlyOwner {
        for (uint256 i; i < _tokenIds.length;) {
            uint256 tokenId = _tokenIds[i];
            _burn(tokenId);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows the owner of the contract to change URI if needed.
     */
    function setBaseURI(string calldata _URI) external onlyOwner {
        baseURI = _URI;
    }

    /**
     * @notice Allows the owner of the contract to toggle between locks for token transfers.
     */
    function toggleTransfers() external onlyOwner {
        transfersLocked = !transfersLocked;
    }

    /**
     * @notice Allows the owner of the contract to toggle between locks for listings.
     */
    function toggleListings() external onlyOwner {
        listingsLocked = !listingsLocked;
    }

    /**
     * @notice Allows the owner of the contract to change the mint price.
     */
    function changeMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    /**
     * @notice Allows the owner of the contract to change the merkle root if the Whitelist should change.
     */
    function changeMerkleRoot(bytes32 _newRoot) external onlyOwner {
        merkleRoot = _newRoot;
    }

    /**
     * @notice Allows the owner of the contract to toggle the sale on or off.
     */
    function setSaleState() external onlyOwner {
        saleActive = !saleActive;
    }

    /**
     * @notice Allows the owner of the contract to change the royalty fee or recipient.
     */
    function setRoyalties(address _receiver, uint96 _royaltyFee) external onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFee);
    }

    /**
     * @notice Allows the owner of the contract to re-register to Openseas Filter.
     */
    function repeatOperatorRegistration() external onlyOwner {
        _registerForOperatorFiltering();
    }

    /**
     * @notice Allows the owner of the contract to turn Openseas Filter on or off.
     */
    function setOperatorFilteringEnabled(bool _value) public onlyOwner {
        operatorFilteringEnabled = _value;
    }

    /**
     * @notice Allows the owner of the contract to withdraw all funds from the contract.
     */
    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert WithdrawFailed();
    }

    // =============================================================
    //                          OVERRIDES
    // =============================================================

    /**
     * @notice Runs a check before every token transfer to see if transfers are locked.
     * Owner transfers, mints and burns are always enabled despite the lock being enabled.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        if (from == owner || from == address(0) || to == address(0)) {
            super._beforeTokenTransfers(from, to, startTokenId, quantity);   
        }
        else {
            if (transfersLocked) revert TransfersLocked();

            super._beforeTokenTransfers(from, to, startTokenId, quantity);
        }
    }

    /**
     * @notice Returns the current state of Openseas operator filter.
     */
    function _operatorFilteringEnabled() internal view virtual override returns (bool) {
        return operatorFilteringEnabled;
    }

    /**
     * @notice Returns the current ipfs uri.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice Allows the tokenID to start at 1 instead of 0.
     */
    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /**
     * @dev Addition of the onlyAllowedOperatorApproval modifier.
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        if (listingsLocked) revert ListingsLocked();
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override onlyAllowedOperatorApproval(operator) {
        if (listingsLocked) revert ListingsLocked();
        super.approve(operator, tokenId);
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Addition of ERC2981 interface.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    // =============================================================
    //                          ERRORS
    // =============================================================

    error SaleNotActive();
    error NotEOA();
    error SoldOut();
    error ListingsLocked();
    error TransfersLocked();
    error IncorrectMintPrice();
    error InvalidProof();
    error InvalidMintAmount();
    error WithdrawFailed();
}