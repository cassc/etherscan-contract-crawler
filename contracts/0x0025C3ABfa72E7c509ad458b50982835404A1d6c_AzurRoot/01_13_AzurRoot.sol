// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {MultiOwnable} from "./MultiOwnable.sol";
import {IDelegationRegistry} from "./IDelegationRegistry.sol";

import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/DefaultOperatorFilterer.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 id) external;
}

interface IAzurian {
    function burnRootAndMint(uint256[] calldata rootIds) external;
}

contract AzurRoot is DefaultOperatorFilterer, ERC721, ERC2981, MultiOwnable {
    /// @notice The Bored and Dangerous contract
    address public immutable BOOK;

    /// @notice Total number of tokens which have minted
    uint256 public totalSupply = 0;

    /// @notice The prefix to attach to the tokenId to get the metadata uri
    string public baseTokenURI;

    /// @notice Whether the burning is open
    bool public burnOpen;

    /// @notice The delegation registry for burning root authentication
    IDelegationRegistry public constant delegationRegistry = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    /// @notice Emitted when a token is minted
    event Mint(address indexed owner, uint256 indexed tokenId);

    /// @notice Raised when the mint has not reached the required timestamp
    error MintNotOpen();
    /// @notice Raised when two calldata arrays do not have the same length
    error MismatchedArrays();
    /// @notice Raised when `sender` does not pass the proper ether amount to `recipient`
    error FailedToSendEther(address sender, address recipient);
    /// @notice Raised when `msg.sender` does not own the roots they're attempting to burn
    error BurnAuthentication();

    constructor(address _book) ERC721("Azur Root", "ROOT") {
        BOOK = _book;
    }

    /// @notice Admin mint a batch of tokens
    function ownerMint(address[] calldata recipients) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }

        unchecked {
            uint256 _totalSupply = totalSupply;
            for (uint256 i = 0; i < recipients.length; ++i) {
                _mint(recipients[i], _totalSupply + i);
            }
            totalSupply += recipients.length;
        }
    }

    /// @notice Burn a token
    function burn(uint256 id) external {
        address from = _ownerOf[id];
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id], "NOT_AUTHORIZED"
        );
        _burn(id);
    }

    //////////////////
    // BOOK BURNING //
    //////////////////

    /// @notice Burn a book to receive an azur root
    function burnBooks(uint256[] calldata tokenIds) external {
        if (!burnOpen) {
            revert MintNotOpen();
        }

        // Cache the totalSupply to minimize storage reads
        uint256 _totalSupply = totalSupply;
        for (uint256 i = 0; i < tokenIds.length; ++i) {
            // Attempt to transfer token from the msg sender, revert if not owned or approved
            IERC721(BOOK).transferFrom(msg.sender, address(this), tokenIds[i]);
            _mint(msg.sender, _totalSupply + i);
        }
        totalSupply += tokenIds.length;
    }

    /// @notice Burn a root to receive an azurian
    function burnRoots(address azurians, uint256[] calldata rootIds) external {
        for (uint256 i = 0; i < rootIds.length; ++i) {
            address rootOwner = ownerOf(rootIds[i]);
            if (!(msg.sender == rootOwner || delegationRegistry.checkDelegateForToken(msg.sender, rootOwner, address(this), rootIds[i]))) {
                revert BurnAuthentication();
            }
            _burn(rootIds[i]);
        }
        IAzurian(azurians).burnRootAndMint(rootIds);
    }

    /////////////////////////
    // ADMIN FUNCTIONALITY //
    /////////////////////////

    /// @notice Set metadata
    function setBaseTokenURI(string memory _baseTokenURI) external {
        if (msg.sender != metadataOwner) {
            revert AccessControl();
        }
        baseTokenURI = _baseTokenURI;
    }

    /// @notice Set burn open
    function setBurnOpen(bool _burnOpen) external {
        if (msg.sender != mintingOwner) {
            revert AccessControl();
        }
        burnOpen = _burnOpen;
    }

    /// @notice Claim funds
    function claimFunds(address payable recipient) external {
        if (!(msg.sender == mintingOwner || msg.sender == metadataOwner || msg.sender == royaltyOwner)) {
            revert AccessControl();
        }

        (bool sent,) = recipient.call{value: address(this).balance}("");
        if (!sent) {
            revert FailedToSendEther(address(this), recipient);
        }
    }

    // ROYALTY FUNCTIONALITY

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, ERC2981) returns (bool) {
        return interfaceId == 0x2a55205a // ERC165 Interface ID for ERC2981
            || interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// @dev See {ERC2981-_setDefaultRoyalty}.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_deleteDefaultRoyalty}.
    function deleteDefaultRoyalty() external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _deleteDefaultRoyalty();
    }

    /// @dev See {ERC2981-_setTokenRoyalty}.
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    /// @dev See {ERC2981-_resetTokenRoyalty}.
    function resetTokenRoyalty(uint256 tokenId) external {
        if (msg.sender != royaltyOwner) {
            revert AccessControl();
        }
        _resetTokenRoyalty(tokenId);
    }

    // METADATA FUNCTIONALITY

    /// @notice Returns the metadata URI for a given token
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    // OPERATOR FILTER

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}