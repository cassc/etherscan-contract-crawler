// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC2981} from '@openzeppelin/contracts/token/common/ERC2981.sol';
import {ONFT721} from 'tapioca-sdk/src/contracts/token/onft/ONFT721.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {DefaultOperatorFilterer} from 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract PearlClubONFT is DefaultOperatorFilterer, ONFT721, ERC2981 {
    uint256 public totalSupply;

    uint256 public immutable MAX_MINT_ID;
    uint96 public constant ROYALTY_FEE = 500; // 5% of every sale

    uint256 private immutable CHAIN_ID;

    /// @notice Owner controlled account which will mint for users on the whitelist
    /// @dev    This was implemented to prevent trait sniping during mint and enforce a random ID
    address public minter;

    string private baseURI;

    /// @notice Mapping of addresses that are eligible to claim
    mapping(address => bool) public hasClaimAvailable;
    /// @notice True if the claim list is finalized, false otherwise
    bool public claimsFinalized;

    /// @notice Time at which the contract was deployed
    uint256 public immutable deployedOn = block.timestamp;

    error PearlClubONFT__CallerNotMinter();
    error PearlClubONFT__CallerNotOwner();
    error PearlClubONFT__ClaimListFinalized();
    error PearlClubONFT__ClaimsListMustBeFinalized();
    error PearlClubONFT__FullyMinted();
    error PearlClubONFT__InvalidMintingChain();
    error PearlClubONFT__NoClaimAvailable();
    error PearlClubONFT__RescueNotActive();

    /// @notice Emitted when the minter is updated
    event MinterSet(address indexed newMinter, address indexed oldMinter);

    /// @param _layerZeroEndpoint Handles message transmission across chains
    /// @param __baseURI          URI endpoint to query metadata
    /// @param _endMintId         The max number of mints on this chain
    /// @param _minGas            Min amount of gas required to transfer, and also store the payload
    /// @param royaltyReceiver    Address of the recipient of royalties
    /// @param _minter            Proxy address allowed to mint for users
    /// @param _chainId           The base chain ID where mints are allowed to happen
    constructor(
        address _layerZeroEndpoint,
        string memory __baseURI,
        uint256 _endMintId,
        uint256 _minGas,
        address royaltyReceiver,
        address _minter,
        uint256 _chainId,
        address _owner
    ) ONFT721('Pearl Club ONFT', 'PCNFT', _minGas, _layerZeroEndpoint) {
        baseURI = __baseURI;
        MAX_MINT_ID = _endMintId;
        CHAIN_ID = _chainId;
        minter = _minter;
        _setDefaultRoyalty(royaltyReceiver, ROYALTY_FEE);

        transferOwnership(_owner);
    }

    /// @notice Mint your ONFT
    function mint(address receiver, uint256 id) external {
        if (_msgSender() != minter) revert PearlClubONFT__CallerNotMinter();
        if (totalSupply == MAX_MINT_ID) revert PearlClubONFT__FullyMinted();
        if (!claimsFinalized) revert PearlClubONFT__ClaimsListMustBeFinalized();
        if (!hasClaimAvailable[receiver])
            revert PearlClubONFT__NoClaimAvailable();

        if (_getChainId() != CHAIN_ID) {
            revert PearlClubONFT__InvalidMintingChain();
        }

        hasClaimAvailable[receiver] = false;

        unchecked {
            ++totalSupply;
        }

        _mint(receiver, id);
    }

    /// @notice Sets the baseURI for the token
    function setBaseURI(string memory __baseURI) external {
        _requireOwner();
        baseURI = __baseURI;
    }

    /// @notice Sets the whitelisted minter for the contract
    function setMinter(address newMinter) external {
        _requireOwner();
        address oldMinter = minter;
        minter = newMinter;
        emit MinterSet(newMinter, oldMinter);
    }

    /// @notice Update the royalty recipient
    function setRoyaltiesRecipient(address newRecipient) external {
        _requireOwner();
        _setDefaultRoyalty(newRecipient, ROYALTY_FEE);
    }

    /// @notice Sets the mapping of eligible
    function setClaimAvailable(
        address[] calldata addresses,
        bool finalize
    ) external {
        _requireOwner();
        if (claimsFinalized) revert PearlClubONFT__ClaimListFinalized();

        for (uint256 i = 0; i < addresses.length; ) {
            hasClaimAvailable[addresses[i]] = true;
            unchecked {
                ++i;
            }
        }

        if (finalize) {
            claimsFinalized = true;
        }
    }

    /// @notice Rescue function to mint ONFTs only after 30 days of deployment
    function rescueMint(address receiver, uint256 id) external {
        if (block.timestamp < deployedOn + 30 days)
            revert PearlClubONFT__RescueNotActive();
        if (_msgSender() != minter) revert PearlClubONFT__CallerNotMinter();
        if (totalSupply == MAX_MINT_ID) revert PearlClubONFT__FullyMinted();
        if (_getChainId() != CHAIN_ID) {
            revert PearlClubONFT__InvalidMintingChain();
        }

        unchecked {
            ++totalSupply;
        }

        _mint(receiver, id);
    }

    /// @dev Helper function to replace onlyOwner modifier
    /// @dev It is more bytecode efficient to have a function if reused multiple times
    function _requireOwner() internal view {
        if (_msgSender() != owner()) {
            revert PearlClubONFT__CallerNotOwner();
        }
    }

    /// @dev Returns the chain ID of the current network
    function _getChainId() internal view virtual returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC2981, ONFT721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Returns the initialized base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    // --------Blacklist Overrides--------//
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}