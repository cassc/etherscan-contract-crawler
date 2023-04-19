// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./IntermediateStorage.sol";

/// @title Centaurify Advanced Collection - AdvancedCollection.sol
/// @author @dadogg80 - Viken Blockchain Solutions.

/// @notice This is the Centaurify Intermediate Collection smart contract used for the Artist Collections.
/// @dev Supports ERC2981 Royalty Standard.
/// @dev Supports OpenSea's - Royalty Standard { https://docs.opensea.io/docs/contract-level-metadata }.

/** 
 * @notice Intermediate Collection Features:
 *          - Premint whitelists w/MerkleProof validation.  
 *          - Public mint phase.  
 */


contract IntermediateCollection is IntermediateStorage, DefaultOperatorFilterer {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    /// @notice Constructor arguments to be passed at the deployment of this contract
    /// @param _superAdmin The _superAdmin is the account with the DEFAULT_ADMIN_ROLE.
    /// @param _artist The _artist account will show up as the OWNER account on OpenSea.
    /// @param _totalSupply The totalsupply.
    /// @param _name The _name is the "Collection Name".
    /// @param _symbol The _symbol is the "Ticker" for this collection.
    constructor(address _superAdmin, address _artist, uint256 _totalSupply, string memory _name,  string memory _symbol)
        ERC721(_name, _symbol)
    {
        transferOwnership(_artist);
        _setupRole(DEFAULT_ADMIN_ROLE, _superAdmin);
        _setupRole(ADMIN_ROLE, _superAdmin);
        MAX_ITEMS = _totalSupply;
        //ownerMint(_CentaurifyPrimintedNFTs, _centSupply);
    }

    /// @notice Allow first phase whitelisted accounts to mint.
    /// @dev Require phaseOneIsOpen
    /// @param amount The amount of nft's to mint.
    /// @param leaf The leaf node of the three.
    /// @param proof The proof from the merkletree.
    function whitelistPhase1Mint(uint256 amount, bytes32 leaf, bytes32[] memory proof) 
        external 
        payable 
        phaseOneIsOpen
        costs(amount) 
    {
        if (!whitelistPhase1Used[_msgSender()]) {
            if (keccak256(abi.encodePacked(_msgSender())) != leaf)
                revert Code_3("Wrong leaf");

            if (!verify(merkleRoot, leaf, proof))
                revert Code_3("Not Verified");

            whitelistPhase1Used[_msgSender()] = true;
            whitelistPhase1Remaining[_msgSender()] = maxItemsPerTx;
        }

        if (amount <= 0) revert NoZeroValues();
        if (whitelistPhase1Remaining[_msgSender()] < amount)
            revert Code_3("Wrong Allcoation");

        whitelistPhase1Remaining[_msgSender()] -= amount;
        _mintWithoutValidation(_msgSender(), amount, false);
    }

    /// @notice Allows the public to mint if public minting is open.
    /// @dev Require publicMintingIsOpen.
    /// @param amount The amount of nft's to mint.
    function publicMint(uint256 amount) external payable publicMintingIsOpen costs(amount) {
        if (!publicMintUsed[_msgSender()]) {
            publicMintUsed[_msgSender()] = true;
            publicMintRemaining[_msgSender()] = maxItemsPerTx;
        }
        if (amount <= 0) revert NoZeroValues();
        if (publicMintRemaining[_msgSender()] < amount)
            revert Code_3("Wrong Allcoation");

        publicMintRemaining[_msgSender()] -= amount;
        _mintWithoutValidation(_msgSender(), amount, false);
    }

    /// @dev Method returns the URI with a given token ID's metadata.
    /// @dev Returns the uri for the token ID given, with additional suffix if set.
    /// @param _tokenId The token id to retrieve the metadata of.
    function tokenURI(uint256 _tokenId) public view override(ERC721) returns (string memory) {
        return bytes(_baseTokenURI).length != 0 ? string(abi.encodePacked(_baseTokenURI, Strings.toString(_tokenId))) : "";
    }

    /// @dev Method is used by OpenSea's - Royalty Standard { https://docs.opensea.io/docs/contract-level-metadata }
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Allows the owner to call on { _mintWithoutValidation() } method.
    /// @dev Restricted with onlyRole(ADMIN_ROLE) modifier.
    /// @param to Address to receive the minted nft's.
    /// @param amount The amount of tokens to mint.
    function ownerMint(address to, uint256 amount) public onlyRole(ADMIN_ROLE) {
        _mintWithoutValidation(to, amount, true);
    }

    /* ------------------------------------------------------------  INTERNAL FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Private method used to mint the NFT's.
    /// @param to The address that will receive the tokens.
    /// @param amount The amount of tokens to mint.
    /// @param skipMaxItems Pass true to skip maxItemsPerTx.
    function _mintWithoutValidation(address to, uint256 amount, bool skipMaxItems) private {
        if (totalSupply() + amount > MAX_ITEMS) revert Code_3(_MaxItemsError);

        require(
            skipMaxItems || amount <= maxItemsPerTx,
            "Surpasses maxItemsPerTx"
        );
        for (uint256 i = 0; i < amount; i++){
            _tokenIdTracker.increment();
            _safeMint(to,  _tokenIdTracker.current());
        }

        emit Minted(to, _tokenIdTracker.current());
    }

    /// @notice Verify the address against the merkletree.
    /// @param root The root node to validate.
    /// @param leaf The leaf node to validate.
    /// @param proof The proof to validate.
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) 
        internal
        pure 
        returns (bool) 
    {
        return MerkleProof.verify(proof, root, leaf);
    }


    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

}