// SPDX-License-Identifier: MIT
// Creator: lohko.io

pragma solidity >=0.8.17;

import {ERC721AQueryable, ERC721A, IERC721Metadata, IERC165} from "ERC721AQueryable.sol";
import {ERC2981} from "ERC2981.sol";
import {IERC721} from "IERC721.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";
import {MerkleProof} from "MerkleProof.sol";

error SaleNotStarted();
error QuantityOffLimits();
error MaxSupplyReached();
error ContractsNotAllowed();
error AlreadyClaimed();
error NotYourPunk();
error NonExistentTokenURI();

contract LilDeadpunks is Ownable, ERC721AQueryable, ERC2981, ReentrancyGuard {
    using Strings for uint256;

    uint256 public constant maxSupply = 10000;
    uint256 public maxTokensPerTx = 10;

    bool public punkClaimStart;

    bool public holderFreeClaimStart;
    bool public publicFreeClaimStart;

    string private _baseTokenURI;

    mapping(uint256 => bool) claimedNoMad;
    mapping(address => uint256[]) claimedPunkIds;

    IERC721 public deadPunks;

    constructor(
        string memory _baseURI,
        address _deadPunks
    ) ERC721A("Lil Deadpunks", "LDPNKS") {
        _baseTokenURI = _baseURI;
        deadPunks = IERC721(_deadPunks);
    }

    // ============ Minting functions ============

    function claimNoMad(uint256[] calldata punkIds) external {
        // Validation
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (!punkClaimStart) revert SaleNotStarted();
        uint256 _amount = punkIds.length;
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();

        for (uint256 i; i < _amount; ) {
            if (claimedNoMad[punkIds[i]]) revert AlreadyClaimed();
            if (deadPunks.ownerOf(punkIds[i]) != msg.sender) revert NotYourPunk();
            claimedNoMad[punkIds[i]] = true;
            claimedPunkIds[msg.sender].push(punkIds[i]);
            unchecked {
                ++i;
            }
        }

        _mint(msg.sender, _amount);
    }

    function publicMint(uint256 _amount) external {
        // Validation
        if (tx.origin != msg.sender) revert ContractsNotAllowed();
        if (_totalMinted() + _amount > maxSupply) revert MaxSupplyReached();
        if (_amount == 0 || _amount > maxTokensPerTx) revert QuantityOffLimits();

        if (deadPunks.balanceOf(msg.sender) > 0) {
            if (!holderFreeClaimStart) revert SaleNotStarted();

        } else {
            if (!publicFreeClaimStart) revert SaleNotStarted();
        }

        _mint(msg.sender, _amount);
    }


    // ============ Frontend helpers ============

    function isClaimed(uint256 _tokenId) public view returns(bool) {
        return claimedNoMad[_tokenId];
    }

    function getClaimedPunks(address _user) public view returns(uint256[] memory) {
        return claimedPunkIds[_user];
    }

    // ============ Admin functions ============

    function togglePunkClaiming() external onlyOwner {
        punkClaimStart = !punkClaimStart;
    }

    function toggleHolderFreeClaiming() external onlyOwner {
        holderFreeClaimStart = !holderFreeClaimStart;
    }

    function togglePublicFreeClaiming() external onlyOwner {
        publicFreeClaimStart = !publicFreeClaimStart;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }

    // ============ Get info ============

    function mintedByAddr(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    function burnedByAddr(address owner) external view returns (uint256) {
        return _numberBurned(owner);
    }

    function totalBurned() external view virtual returns (uint256) {
        return _totalMinted() - totalSupply();
    }

    function totalMinted() external view virtual returns (uint256) {
        return _totalMinted();
    }

    // ============ Overrides ============

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 0;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A, IERC721Metadata)
        returns (string memory)
    {
        if (!_exists(tokenId)) revert NonExistentTokenURI();
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981, IERC165) returns (bool) {
        return 
            ERC721A.supportsInterface(interfaceId) || 
            ERC2981.supportsInterface(interfaceId);
    }
}