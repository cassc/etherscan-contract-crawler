// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "./IGrailsRevenues.sol";
import "./GrailsRevenues.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
@author divergence
 */
contract Grails is ERC721Common {
    using Address for address payable;
    using ERC165Checker for address;
    using ERC721Redeemer for ERC721Redeemer.SingleClaims;
    using Monotonic for Monotonic.Increaser;
    using Strings for uint256;

    /**
    @notice Address of the PROOF collective token against which claims for this
    token can be redeemed.
     */
    IERC721 public immutable PROOF;

    /**
    @notice Contract responsible for management of revenues from both primary
    and secondary sales.
     */
    IGrailsRevenues internal revenues;

    constructor(IERC721 proof)
        ERC721Common("PROOF Collective Grails", "GRAIL")
    {
        PROOF = proof;
        revenues = new GrailsRevenues(msg.sender);
    }

    /**
    @notice Price of a single Grail.
     */
    uint256 public constant PRICE = 0.05 ether;

    /**
    @dev BitMap of already-claimed tokens.
     */
    ERC721Redeemer.SingleClaims internal claims;

    /**
    @notice Total number of tokens minted.
     */
    Monotonic.Increaser public totalSupply;

    /**
    @notice Flag indicating that non-owner can st
     */
    bool public publicMintingOpen = false;

    /**
    @notice Toggle whether non-owner addresses can start minting.
     */
    function setPublicMinting(bool publicMinting) external onlyOwner {
        publicMintingOpen = publicMinting;
    }

    /**
    @dev Emitted when a PROOF token is used to mint a Grail.
     */
    event PROOFTokenRedeemed(uint256 tokenId);

    /**
    @notice Allows PROOF tokens to be redeemed for Grails.
    @param proofTokenIds Tokens for which the caller MUST be either the owner or
    approved under ERC721 specifications.
    @param grailIds MUST be of the same length as `proofTokenIds`; the minter's
    Grail selections, 0-indexed.
     */
    function mint(uint256[] calldata proofTokenIds, uint8[] calldata grailIds)
        external
        payable
    {
        require(publicMintingOpen, "Public minting closed");
        require(
            proofTokenIds.length == grailIds.length,
            "Incorrect number of tokens"
        );
        require(msg.value == proofTokenIds.length * PRICE, "Incorrect payment");

        claims.redeem(msg.sender, PROOF, proofTokenIds);
        payable(address(revenues)).sendValue(msg.value);
        _mint(msg.sender, grailIds);

        for (uint256 i = 0; i < proofTokenIds.length; i++) {
            emit PROOFTokenRedeemed(proofTokenIds[i]);
        }
    }

    uint256 internal constant NUM_GRAILS = 20;

    /**
    @dev Each artist, as well as the development team, are allowed to choose two
    Grails to mint free of charge.
     */
    uint256 public freeGrailsRemaining = (NUM_GRAILS + 1) * 2;

    /**
    @dev Each artist receives one of their own Grail, and PROOF receives one of
    each.
     */
    uint256 public constant GENESIS_MINTS = 2 * NUM_GRAILS;

    /**
    @notice Flag indicating if the genesis mints have been claimed.
     */
    bool public genesisMinted = false;

    /**
    @notice Allows the contract owner to mint the genesis pieces of each Grail.
     */
    function mintGenesis(address to) external onlyOwner {
        require(!genesisMinted, "Already minted");
        genesisMinted = true;

        uint8[] memory grailIds = new uint8[](GENESIS_MINTS);
        for (uint8 i = 0; i < NUM_GRAILS; i++) {
            uint256 idx = 2 * i;
            grailIds[idx] = i;
            grailIds[idx + 1] = i;
        }

        _mint(to, grailIds);
    }

    /**
    @notice Allows the contract owner to mint the gratis allocation for later
    distribution.
     */
    function mintFree(address to, uint8[] calldata grailIds)
        external
        onlyOwner
    {
        require(grailIds.length <= freeGrailsRemaining, "Quota exceeded");
        freeGrailsRemaining -= grailIds.length;
        _mint(to, grailIds);
    }

    /**
    @notice Flag indicating that no more minting is allowed, even for PROOF
    token redemptions.
     */
    bool public mintingLocked = false;

    /**
    @notice Permanently lock minting for everyone.
     */
    function lockMinting() external onlyOwner {
        mintingLocked = true;
    }

    /**
    @dev The Grail chosen for the respective token.
     */
    uint8[] internal tokenGrails;

    /**
    @notice How many times each Grail has been minted.
     */
    uint16[NUM_GRAILS] public grailMintCounts;

    /**
    @dev Emitted when the specific Grail is minted.
     */
    event GrailMinted(uint8 indexed grailId);

    /**
    @dev Common internal minting logic.
     */
    function _mint(address to, uint8[] memory grailIds) internal {
        require(!mintingLocked, "Minting locked");

        uint256 firstTokenId = totalSupply.current();
        for (uint256 i = 0; i < grailIds.length; i++) {
            uint8 grail = grailIds[i];
            require(grail < NUM_GRAILS, "Invalid Grail ID");
            tokenGrails.push(grail);

            grailMintCounts[grail]++;
            emit GrailMinted(grail);

            _safeMint(to, firstTokenId + i);
        }

        totalSupply.add(grailIds.length);

        // Contract invariant in place for testing, therefore assert.
        assert(totalSupply.current() == tokenGrails.length);
    }

    /**
    @notice Returns whether the PROOF token has already been used to claim a
    Grail.
     */
    function proofClaimed(uint256 tokenId) external view returns (bool) {
        require(tokenId < 1000, "Token doesn't exist");
        return claims.claimed(tokenId);
    }

    /**
    @notice Sets the contract responsible for revenue management.
    @dev Requires that the address supports the IGrailsRevenues interface.
     */
    function setRevenuesContract(IGrailsRevenues _revenues) external onlyOwner {
        require(
            address(_revenues).supportsInterface(
                type(IGrailsRevenues).interfaceId
            ),
            "Not IGrailsRevenues"
        );
        revenues = _revenues;
    }

    /**
    @notice Implementation of ERC2981 royalty standard.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        require(tokenId < totalSupply.current(), "Token doesn't exist");
        uint8 grailId = tokenGrails[tokenId];

        uint256 basisPoints = revenues.royaltyBasisPoints(grailId);
        return (revenues.receiver(grailId), (salePrice * basisPoints) / 1e4);
    }

    /**
    @notice Prefix for all URIs returned by tokenURI().
     */
    string public baseTokenURI;

    /**
    @notice Update the tokenURI() prefix.
     */
    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    /**
    @notice Returns the token's metadata URI.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        uint256 grailId = uint256(tokenGrails[tokenId]);
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    "/",
                    grailId.toString(),
                    "/",
                    tokenId.toString()
                )
            );
    }
}