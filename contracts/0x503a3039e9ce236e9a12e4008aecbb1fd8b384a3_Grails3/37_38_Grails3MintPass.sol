// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Math} from "openzeppelin-contracts/utils/math/Math.sol";
import {DefaultOperatorFilterer} from
    "operator-filter-registry/DefaultOperatorFilterer.sol";
import {IMoonbirds} from "moonbirds/IMoonbirds.sol";

import {ERC721A} from "ethier/contracts/erc721/ERC721ACommon.sol";
import {BaseTokenURI} from "ethier/contracts/erc721/BaseTokenURI.sol";
import {NextShufflerMemory} from
    "ethier/contracts/random/NextShufflerMemory.sol";

import {ERC721ATransferRestricted} from
    "grails/season-03/ERC721ATransferRestricted.sol";
import {IERC721Supply} from "grails/season-03/IERC721Supply.sol";

/**
 * @title Grails III Mint Pass
 */
contract Grails3MintPass is
    ERC721ATransferRestricted,
    BaseTokenURI,
    DefaultOperatorFilterer
{
    using NextShufflerMemory for NextShufflerMemory.State;

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown for unauthorized method calls that are reserved for the
     * Grails III contract.
     * @dev I.e. during mint pass redemption.
     */
    error OnlyGrailsContract();

    /**
     * @notice Thrown if a function can only be executed once.
     */
    error FunctionAlreadyExecuted(bytes4 selector);

    /**
     * @notice Thrown if the number of supplied grail moonbirds is incorrect.
     */
    error IncorrectNumberOfGrailMoonbirds();

    // =========================================================================
    //                           CONSTANTS
    // =========================================================================

    /**
     * @notice Number of passes minted to the PROOF treasury wallet.
     */
    uint256 internal constant _NUM_TREASURY_MINTS = 5;

    /**
     * @notice Number of passes airdropped to random grail Moonbirds.
     */
    uint256 internal constant _NUM_GRAIL_MOONBIRDS_AIRDROPS = 10;

    /**
     * @notice Number of Moonbirds with the Grail trait.
     */
    uint256 internal constant _NUM_GRAIL_MOONBIRDS = 176;

    /**
     * @notice Number of passes airdropped to random Moonbirds.
     */
    uint256 internal constant _NUM_MOONBIRDS_AIRDROPS = 10;

    /**
     * @notice The PROOF collective token contract.
     */
    IERC721Supply internal immutable _proof;

    /**
     * @notice The Moonbirds token contract.
     */
    IMoonbirds internal immutable _moonbirds;

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The Grails III contract address.
     */
    address public grails;

    /**
     * @notice Number of tokens that have already been airdroppped to PROOF
     * collective token holders.
     */
    uint16 internal _numProofCollectiveAirdropped;

    /**
     * @notice Keeps track of function executions.
     */
    mapping(bytes4 => bool) internal _functionAlreadyExecuted;

    /**
     * @notice Keeps track of the grail moonbirds that already got an airdrop.
     * @dev They will be excluded from the general moonbird airdrop.
     */
    mapping(uint256 => bool) internal _isGrailMoonbirdAirdropWinner;

    // =========================================================================
    //                           Constructor
    // =========================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseTokenURI_,
        address payable royaltyReceiver_,
        IERC721Supply proof_,
        IMoonbirds moonbirds_
    )
        ERC721ATransferRestricted(name_, symbol_, royaltyReceiver_, 500)
        BaseTokenURI(baseTokenURI_)
    {
        _proof = proof_;
        _moonbirds = moonbirds_;
    }

    // =========================================================================
    //                           Minting
    // =========================================================================

    /**
     * @notice Performs a number of airdrops to PROOF collective token holders.
     * @dev Repeated calls beyond the number of intended airdrops have no
     * effect.
     */
    function airdropToProofCollective(uint256 num) external onlyOwner {
        uint256 tokenId = _numProofCollectiveAirdropped;
        uint256 endTokenId = Math.min(tokenId + num, _proof.totalSupply());
        _numProofCollectiveAirdropped = uint16(endTokenId);

        while (tokenId < endTokenId) {
            _mint(_proof.ownerOf(tokenId), 1);

            unchecked {
                ++tokenId;
            }
        }
    }

    /**
     * @notice Mints a predefined number of tokens to the PROOF treasury.
     * @dev Can only be done once. Reverts otherwise.
     */
    function mintTreasury(address to)
        external
        onlyOwner
        onlyOnce(Grails3MintPass.mintTreasury.selector)
    {
        _mint(to, _NUM_TREASURY_MINTS);
    }

    /**
     * @notice Randomised airdrop to a list of Grail Moonbirds.
     * @dev Unnested birds are skipped.
     * @dev Can only be called once. Reverts otherwise.
     * @dev Assuming 176 eligible Moonbirds, the function executes in <1M gas
     * (worst case).
     */
    function airdropToRandomGrailMoonbirds(uint256[] calldata grailMoonbirdIds)
        external
        onlyOwner
        onlyOnce(Grails3MintPass.airdropToRandomGrailMoonbirds.selector)
    {
        if (grailMoonbirdIds.length != _NUM_GRAIL_MOONBIRDS) {
            revert IncorrectNumberOfGrailMoonbirds();
        }
        _airdropToRandomGrailMoonbirds(grailMoonbirdIds);
    }

    /**
     * @notice Randomised airdrop to a list of Grail Moonbirds.
     * @dev Unnested birds are skipped.
     * @dev This was split off from `airdropToRandomGrailMoonbirds` for testing
     * purposes.
     */
    function _airdropToRandomGrailMoonbirds(
        uint256[] calldata eligibleMoonbirds
    ) internal {
        NextShufflerMemory.State memory shuffler = NextShufflerMemory.allocate(
            eligibleMoonbirds.length, bytes32(block.difficulty)
        );

        uint256 numAirdropped = 0;
        uint256 i = 0;
        unchecked {
            while (
                i < eligibleMoonbirds.length
                    && numAirdropped < _NUM_GRAIL_MOONBIRDS_AIRDROPS
            ) {
                uint256 birbId = eligibleMoonbirds[shuffler.next()];
                if (_airdropIfNested(birbId)) {
                    ++numAirdropped;
                    _isGrailMoonbirdAirdropWinner[birbId] = true;
                }
                ++i;
            }
        }
    }

    /**
     * @notice Randomised airdrop to Moonbirds.
     * @dev Unnested birds are skipped.
     * @dev Can only be called once. Reverts otherwise.
     */
    function airdropToRandomMoonbirds()
        external
        onlyOwner
        onlyOnce(Grails3MintPass.airdropToRandomMoonbirds.selector)
    {
        uint256 numMoonbirds = IERC721Supply(address(_moonbirds)).totalSupply();
        NextShufflerMemory.State memory shuffler =
            NextShufflerMemory.allocate(numMoonbirds, bytes32(block.difficulty));

        uint256 numAirdropped = 0;
        uint256 i = 0;
        unchecked {
            while (i < numMoonbirds && numAirdropped < _NUM_MOONBIRDS_AIRDROPS)
            {
                uint256 birbId = shuffler.next();

                if (_isGrailMoonbirdAirdropWinner[birbId]) {
                    // Since this function cannot be run twice and a bird ID
                    // cannot be encountered again in the shuffling, we can get
                    // some gas refunded here.
                    delete _isGrailMoonbirdAirdropWinner[birbId];
                    continue;
                }

                if (_airdropIfNested(birbId)) {
                    ++numAirdropped;
                }
                ++i;
            }
        }
    }

    /**
     * @notice Airdrops a mint pass to the holder of a given moonbird if it is
     * nested.
     * @return Flag to indicate if an airdrop has been performed.
     */
    function _airdropIfNested(uint256 birdId) internal returns (bool) {
        (bool nesting,,) = _moonbirds.nestingPeriod(birdId);
        if (!nesting) {
            return false;
        }
        _mint(_moonbirds.ownerOf(birdId), 1);
        return true;
    }

    // =========================================================================
    //                           Burning
    // =========================================================================

    /**
     * @notice Interface to burn leftover passes that have not been redeemed.
     * @dev We did not put an explicit lock on this method (preventing us from
     * burning passes at any time) because we are disincentiviced to do so (by
     * missing revenue). Since the mint passes are ephemeral to begin with, we
     * opted to not add the additional complexity for this collection.
     * @dev This function is able to bypass the transfer restriction.
     */
    function burnRemaining(uint256[] calldata tokenIds)
        external
        onlyOwner
        bypassTransferRestriction
    {
        for (uint256 idx = 0; idx < tokenIds.length; ++idx) {
            _burn(tokenIds[idx]);
        }
    }

    /**
     * @notice Redeems a pass with given tokenId for a Grail.
     * @dev Only callable by the Grails III contract. Burns the pass.
     */
    function redeem(uint256 tokenId) external onlyGrailsContract {
        _burn(tokenId);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Sets the Grails III contract address.
     */
    function setGrailsContract(address grails_) external onlyOwner {
        grails = grails_;
    }

    /**
     * @notice Modifier to make a method exclusively callable by the Grails II
     * contract.
     */
    modifier onlyGrailsContract() {
        if (msg.sender != grails) {
            revert OnlyGrailsContract();
        }
        _;
    }

    // =========================================================================
    //                           Metadata
    // =========================================================================

    /**
     * @notice The URI for pass metadata.
     * @dev Returns the same tokenURI for all passes.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        tokenExists(tokenId)
        returns (string memory)
    {
        return _baseURI();
    }

    // =========================================================================
    //                           Operator filtering
    // =========================================================================

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override
        onlyAllowedOperator(from)
    {
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

    // =========================================================================
    //                           Internals
    // =========================================================================

    function _baseURI()
        internal
        view
        virtual
        override(ERC721A, BaseTokenURI)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }

    /**
     * @notice Ensures that the modified function can only be executed once.
     * @param selector The selector of the wrapped function.
     */
    modifier onlyOnce(bytes4 selector) {
        if (_functionAlreadyExecuted[selector]) {
            revert FunctionAlreadyExecuted(selector);
        }
        _functionAlreadyExecuted[selector] = true;
        _;
    }
}