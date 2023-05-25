// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {IERC721A, ERC721A} from 'erc721a/contracts/extensions/ERC721ABurnable.sol';

import {OwnableOperators} from '../utils/OwnableOperators.sol';

import {EtherealStatesMinter} from './EtherealStatesMinter.sol';
import {EtherealStatesVRF} from './EtherealStatesVRF.sol';
import {EtherealStatesDNA} from './EtherealStatesDNA.sol';

/// @title EtherealStatesMeta
/// @author Artist: GenuineHumanArt (https://twitter.com/GenuineHumanArt)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
/// @notice EtherealStates Meta logic
contract EtherealStatesMeta is
    EtherealStatesMinter,
    EtherealStatesVRF,
    OwnableOperators
{
    error NotRevealed();
    error NonexistentToken();
    error WrongContext();
    error TooLate();

    /// @notice emitted whenever the DNA changes.
    event TokenDNAChanged(
        address operator,
        uint256 indexed tokenId,
        bytes32 oldDNA,
        bytes32 newDNA
    );

    /// @notice emitted whenever the random seed is set
    event RandomSeedSet(uint256 randomSeed);

    /// @notice ChainLink Random Seed
    uint256 public randomSeed;

    /// @notice DNA Generator contract
    address public dnaGenerator;

    /// @notice Metadata manager
    address public metadataManager;

    /// @notice this allows to save the DNA in the contract instead of having to generate
    ///         it every time we call tokenDNA()
    mapping(uint256 => bytes32) public revealedDNA;

    string public contractURI;

    /////////////////////////////////////////////////////////
    // Modifiers                                           //
    /////////////////////////////////////////////////////////

    // stops minting after reveal
    modifier onlyBeforeReveal() {
        if (requestId != 0) {
            revert TooLate();
        }
        _;
    }

    // allows some stuff only after reveal
    modifier onlyAfterReveal() {
        if (randomSeed == 0) {
            revert TooEarly();
        }
        _;
    }

    constructor(
        string memory contractURI_,
        address mintPasses,
        address newSigner,
        address dnaGenerator_,
        address metadataManager_,
        VRFConfig memory vrfConfig_
    )
        EtherealStatesMinter(mintPasses, newSigner)
        EtherealStatesVRF(vrfConfig_)
    {
        contractURI = contractURI_;
        dnaGenerator = dnaGenerator_;
        metadataManager = metadataManager_;
    }

    /////////////////////////////////////////////////////////
    // Getters                                             //
    /////////////////////////////////////////////////////////

    function tokenURI(uint256 tokenId)
        public
        view
        override(IERC721A, ERC721A)
        returns (string memory)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        return EtherealStatesMinter(metadataManager).tokenURI(tokenId);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    /// @notice Get the DNA for a givent tokenId
    /// @param tokenId the token id to get the DNA for
    /// @return dna the DNA
    function tokenDNA(uint256 tokenId)
        public
        view
        onlyAfterReveal
        returns (bytes32 dna)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        dna = revealedDNA[tokenId];

        if (dna == 0x0) {
            dna = _tokenDNA(tokenId);
        }
    }

    function tokensDNA(uint256 startId, uint256 howMany)
        public
        view
        returns (bytes32[] memory dnas)
    {
        bytes32 dna;
        dnas = new bytes32[](howMany);
        for (uint256 i; i < howMany; i++) {
            dna = revealedDNA[startId + i];
            if (dna == 0x0) {
                dna = _tokenDNA(startId + i);
            }
            dnas[i] = dna;
        }
    }

    /////////////////////////////////////////////////////////
    // Setters                                             //
    /////////////////////////////////////////////////////////

    /// @notice Allows to save the DNA of a tokenId so it doesn't need to be recomputed
    ///         after that
    /// @param tokenId the token id to reveal
    /// @return dna the DNA
    function revealDNA(uint256 tokenId)
        external
        onlyAfterReveal
        returns (bytes32 dna)
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        dna = revealedDNA[tokenId];

        // only reveal if not already revealed
        if (dna == 0x0) {
            dna = _tokenDNA(tokenId);
            revealedDNA[tokenId] = dna;
            emit TokenDNAChanged(msg.sender, tokenId, 0x0, dna);
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Operator                                      //
    /////////////////////////////////////////////////////////

    /// @notice Allows an Operator to update a token DNA
    /// @param tokenId the token id to update the DNA of
    /// @param newDNA the new DNA
    function updateTokenDNA(uint256 tokenId, bytes32 newDNA)
        external
        onlyOperator
    {
        if (!_exists(tokenId)) {
            revert NonexistentToken();
        }

        // the caller must be approved by the owner
        if (!isApprovedForAll(ownerOf(tokenId), msg.sender)) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        bytes32 dna = revealedDNA[tokenId];
        if (dna == 0x0) {
            revert NotRevealed();
        }

        revealedDNA[tokenId] = newDNA;
        emit TokenDNAChanged(msg.sender, tokenId, dna, newDNA);
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    /// @notice Allows owner to update metadataManager
    /// @param newManager the new address of the metadata manager
    function setMetadataManager(address newManager) external onlyOwner {
        metadataManager = newManager;
    }

    /// @notice Allows owner to update dna generator
    /// @param newGenerator the new address of the dna generator
    function setDNAGenerator(address newGenerator) external onlyOwner {
        dnaGenerator = newGenerator;
    }

    /// @notice Allows to start the reveal process once everything is minted or time's up
    /// @dev this can only be used beforeReveal, so once the seed is set, this can't be called again
    ///      if the call, for any reason, fails,
    function startReveal() external onlyOwner {
        // only call if requestId is 0
        if (requestId != 0) {
            revert WrongContext();
        }
        currentTier = 0;
        _requestRandomWords();
    }

    /// @notice Allows to reset the requestId, if, for some reason, the ChainLink call does not work
    /// @dev this can only be used beforeReveal, so once the seed is set, this can't be called again
    function resetRequestId() external onlyOwner {
        if (requestId == 0 || randomSeed != 0) {
            revert WrongContext();
        }
        requestId = 0;
    }

    /// @notice Allows owner to update the VRFConfig if something is not right
    /// @dev this can only be used beforeReveal, so once the seed is set, this can't be called again
    function setVRFConfig(VRFConfig memory vrfConfig_)
        external
        onlyOwner
        onlyBeforeReveal
    {
        vrfConfig = vrfConfig_;
    }

    /////////////////////////////////////////////////////////
    // Internals                                           //
    /////////////////////////////////////////////////////////

    // called when ChainLink answers with the random number
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory words
    ) internal override {
        randomSeed = words[0];
        emit RandomSeedSet(randomSeed);
    }

    function _tokenDNA(uint256 tokenId) internal view returns (bytes32) {
        return
            EtherealStatesDNA(dnaGenerator).generate(
                uint256(keccak256(abi.encode(randomSeed, tokenId))),
                hasHoldersTrait(tokenId)
            );
    }

    function _mintStates(
        address to,
        uint256 quantity,
        uint256 free,
        bool addHoldersTrait
    ) internal override onlyBeforeReveal {
        super._mintStates(to, quantity, free, addHoldersTrait);
    }
}