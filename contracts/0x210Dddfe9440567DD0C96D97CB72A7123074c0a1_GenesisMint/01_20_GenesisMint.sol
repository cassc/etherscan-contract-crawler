// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./GenesisStorage.sol";

/// @title Centaurify Collection AAA - GenesisMint.sol
/// @author @dadogg80 - Viken Blockchain Solutions.

/// @notice This is the Centaurify Genesis Mint smart contract used for the Collection AAA.
/// @notice This smart contract is built on the ERC721A smart contract from ChiruLabs for cheaper batch minting and better fee optimisation.
/// @dev Link to ERC721a docs - { https://chiru-labs.github.io/ERC721A/#/ }.
/// @dev Supports ERC2981 Royalty Standard.
/// @dev Supports OpenSea's - Royalty Standard { https://docs.opensea.io/docs/contract-level-metadata }.

contract GenesisMint is GenesisStorage {

    // @notice Constructor arguments to be passed at the deployment of this contract
    // @param __contractURI Read { https://docs.opensea.io/docs/contract-level-metadata } for more information.
    // @param _operator The _operator is the relayer address that will initiate the { setPhase*MintValues } method.
    // @param _royalty The _royalty address is a smart contract used to split the royalty amount between preset addresses..
    constructor(string memory __contractURI, address _operator, address payable _royalty)
        ERC721A("Centaurify_Collection_AAA", "CENT_AAA")
    {
        _contractURI = __contractURI;
        royalty = _royalty;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSenderERC721A());
        _setupRole(ADMIN_ROLE, _msgSenderERC721A());
        _setupRole(OPERATOR_ROLE, _operator);

        _setDefaultRoyalty(royalty, 750);
        _mintERC2309(_msgSenderERC721A(), 500);
    }

    /// @dev Receive function will revert if triggered.
    receive() external payable {
        if (msg.value > 0) revert Code_3(_ReceivefunctionError);
    }

    /// @notice Allow first phase whitelisted accounts to mint.
    /// @dev Require phaseOneIsOpen
    /// @param amount The amount of nft's to mint.
    /// @param leaf The leaf node of the three.
    /// @param proof The proof from the merkletree.
    function whitelistPhase1Mint(uint amount, bytes32 leaf, bytes32[] memory proof) 
        external 
        payable 
        phaseOneIsOpen 
        costs(amount) 
    {
        if (block.timestamp > endTimestamp) revert MintPhaseEnded(endTimestamp);
        if (!whitelistPhase1Used[_msgSenderERC721A()]) {
            if (keccak256(abi.encodePacked(_msgSenderERC721A())) != leaf)
                revert Code_3(_MerkleLeafMatchError );

            if (!verify(merkleRoot, leaf, proof))
                revert Code_3(_MerkleLeafValidationError );

            whitelistPhase1Used[_msgSenderERC721A()] = true;
            whitelistPhase1Remaining[_msgSenderERC721A()] = maxItemsPerTx;
        }

        if (amount <= 0) revert NoZeroValues();
        if (whitelistPhase1Remaining[_msgSenderERC721A()] < amount)
            revert Code_3(_RemainingAllocationError);

        whitelistPhase1Remaining[_msgSenderERC721A()] -= amount;
        _mintWithoutValidation(_msgSenderERC721A(), amount, false);
    }

    /// @notice Allow second whitelisted accounts to mint.
    /// @dev Require phaseTwoIsOpen.
    /// @param amount The amount of nft's to mint.
    /// @param leaf the leaf node of the three.
    /// @param proof the proof from the merkletree.
    function whitelistPhase2Mint(uint amount, bytes32 leaf, bytes32[] memory proof) 
        external 
        payable 
        phaseTwoIsOpen 
        costs(amount) 
    {
        if (block.timestamp > endTimestamp) revert MintPhaseEnded(endTimestamp);
        if (!whitelistPhase2Used[_msgSenderERC721A()]) {
            if (keccak256(abi.encodePacked(_msgSenderERC721A())) != leaf)
                revert Code_3(_MerkleLeafMatchError );

            if (!verify(merkleRoot, leaf, proof))
                revert Code_3(_MerkleLeafValidationError );

            whitelistPhase2Used[_msgSenderERC721A()] = true;
            whitelistPhase2Remaining[_msgSenderERC721A()] = maxItemsPerTx;
        }

        if (amount <= 0) revert NoZeroValues();
        if (whitelistPhase2Remaining[_msgSenderERC721A()] < amount)
            revert Code_3(_RemainingAllocationError);

        whitelistPhase2Remaining[_msgSenderERC721A()] -= amount;
        _mintWithoutValidation(_msgSenderERC721A(), amount, false);
    }

    /// @notice Allow third phase whitelisted accounts to mint.
    /// @dev Require phaseThreeIsOpen.
    /// @param amount The amount of nft's to mint.
    /// @param leaf the leaf node of the three.
    /// @param proof the proof from the merkletree.
    function whitelistPhase3Mint(uint amount, bytes32 leaf, bytes32[] memory proof) 
        external 
        payable 
        phaseThreeIsOpen 
        costs(amount) 
    {
        if (block.timestamp > endTimestamp) revert MintPhaseEnded(endTimestamp);
        if (!whitelistPhase3Used[_msgSenderERC721A()]) {
            if (keccak256(abi.encodePacked(_msgSenderERC721A())) != leaf)
                revert Code_3(_MerkleLeafMatchError);

            if (!verify(merkleRoot, leaf, proof))
                revert Code_3(_MerkleLeafValidationError );

            whitelistPhase3Used[_msgSenderERC721A()] = true;
            whitelistPhase3Remaining[_msgSenderERC721A()] = maxItemsPerTx;
        }

        if (amount <= 0) revert NoZeroValues();
        if (whitelistPhase3Remaining[_msgSenderERC721A()] < amount)
            revert Code_3(_RemainingAllocationError);

        whitelistPhase3Remaining[_msgSenderERC721A()] -= amount;
        _mintWithoutValidation(_msgSenderERC721A(), amount, false);
    }

    /// @notice Allows the public to mint if public minting is open.
    /// @dev Require publicMintingIsOpen.
    /// @param amount The amount of nft's to mint.
    function publicMint(uint amount) external payable publicMintingIsOpen costs(amount) {
        if (block.timestamp > endTimestamp) revert MintPhaseEnded(endTimestamp);
        if (!publicMintUsed[_msgSenderERC721A()]) {
            publicMintUsed[_msgSenderERC721A()] = true;
            publicMintRemaining[_msgSenderERC721A()] = maxItemsPerTx;
        }
        if (amount <= 0) revert NoZeroValues();
        if (publicMintRemaining[_msgSenderERC721A()] < amount)
            revert Code_3(_RemainingAllocationError);

        publicMintRemaining[_msgSenderERC721A()] -= amount;
        _mintWithoutValidation(_msgSenderERC721A(), amount, false);
    }

    /// @notice Method dedicated for the FrontEnd to query the remaining mints of an account.
    /// @dev Method returns the max phase mint if user has not minted before, and the remaining mints if user has minted before.
    /// @dev Attention! This method does NOT verify if the `user` is whitelisted. It only checks if the `user` has minted or not. The normal Merkle tree procedure is still required. 
    /// @param user The user address to query the remaining mints of.
    function getRemainingMints(address user) external view returns (uint remaining) {
        Status _status = status;

        if (_status == Status(0)) {
            if (!whitelistPhase1Used[user]) return PHASE1_MAX_MINT;
            return whitelistPhase1Remaining[user];
        }

        else if (_status == Status(1)) {
            if (!whitelistPhase2Used[user]) return PHASE2_MAX_MINT;
            return whitelistPhase2Remaining[user];
        }

        else if (_status == Status(2)) {
            if (!whitelistPhase3Used[user]) return PHASE3_MAX_MINT;
            return whitelistPhase3Remaining[user];
        }
        
        else if (_status == Status(3)) {
            if (!publicMintUsed[user]) return PUBLIC_MAX_MINT;
            return publicMintRemaining[user];
        }
    }

    /// @notice Burns a token.
    /// @dev Completes an approval check in derived { _burn } method.
    /// @param _tokenId The token Id to burn.
    function burn(uint _tokenId) external {
        if (!_exists(_tokenId)) revert Code_3("Didn't exist");
        super._burn(_tokenId, true);
    }

    /// @dev Method returns the URI with a given token ID's metadata.
    /// @dev Returns the uri for the token ID given, with additional suffix if set.
    /// @param _tokenId The token id to retrieve the metadata of.
    function tokenURI(uint _tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        return bytes(_baseTokenURI).length != 0 ? string(abi.encodePacked(_baseTokenURI, _toString(_tokenId), _uriSuffix)) : "";
    }

    /// @dev Method is used by OpenSea's - Royalty Standard { https://docs.opensea.io/docs/contract-level-metadata }
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Allows the owner to call on { _mintWithoutValidation() } method.
    /// @dev Restricted with onlyRole(ADMIN_ROLE) modifier.
    /// @param to Address to receive the minted nft's.
    /// @param amount The amount of tokens to mint.
    function ownerMint(address to, uint amount) external onlyRole(ADMIN_ROLE) {
        _mintWithoutValidation(to, amount, true);
    }

    /* ------------------------------------------------------------  INTERNAL FUNCTIONS  ----------------------------------------------------------- */

    /// @notice Private method used to mint the NFT's.
    /// @param to The address that will receive the tokens.
    /// @param amount The amount of tokens to mint.
    /// @param skipMaxItems Pass true to skip maxItemsPerTx.
    function _mintWithoutValidation(address to, uint amount, bool skipMaxItems) private {
        uint _totalSupply = totalSupply();
        if (_totalSupply + amount > MAX_ITEMS) revert Code_3(_MaxItemsError);

        require(
            skipMaxItems || amount <= maxItemsPerTx,
            "Surpasses maxItemsPerTx"
        );

        _mint(to, amount);
        uint _nextToken = _nextTokenId();
        emit Minted(to, amount, _nextToken - 1, status);
    }

    /// @notice Verify the address against the merkletree.
    /// @param root The root node to validate.
    /// @param leaf The leaf node to validate.
    /// @param proof The proof to validate.
    function verify(bytes32 root, bytes32 leaf, bytes32[] memory proof) 
        public
        pure 
        returns (bool) 
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}