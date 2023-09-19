// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./IGarbageBags.sol";

contract GarbageCans is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    using ECDSA for bytes32;

    uint16 public constant MAX_SUPPLY = 6500;
    bool public paused;
    string public uriSuffix = '.json';
    string public baseTokenURI;
    address private _allowedCaller;
    address public signer;
    IGarbageBags public garbageBags; 
    mapping(uint256 => uint256) private mintToBurnId;

    // Custom error
    error ContractPausedError();
    error OnlyAllowedCallerError();
    error MaxSupplyReachedError();
    error NotTokenOwnerError();
    error InvalidSignerError();

    constructor(
        string memory _baseTokenURI,
        address _garbageBags,
        address _signer
    ) ERC721A("Garbage Cans", "GARBAGEC") {
        baseTokenURI = _baseTokenURI;
        paused = true;
        garbageBags = IGarbageBags(_garbageBags);
        signer = _signer;
        _setDefaultRoyalty(_msgSender(), 650);
    }

    // Modifier

    modifier onlyAllowedCaller() {
        if (_msgSender() != _allowedCaller) revert OnlyAllowedCallerError();
        _;
    }

    /**
     *@notice This is an internal function that returns base URI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Mint tokenIds
     * @param tokenIds uint[]
     * @param sig bytes
     */
    function mint(uint256[] calldata tokenIds, bytes calldata sig) external {
        if (paused) revert ContractPausedError();
        if (_totalMinted() + tokenIds.length > MAX_SUPPLY) {
            revert MaxSupplyReachedError();
        }
        uint256 nonce = _getAux(_msgSender());
        address sigRecover = keccak256(
            abi.encodePacked(_msgSender(), sumOf(tokenIds), nonce)
        ).toEthSignedMessageHash().recover(sig);

        if (sigRecover != signer) revert InvalidSignerError();
        uint256 nextId = _nextTokenId();
        for (uint256 i; i < tokenIds.length; ) {
            if (garbageBags.ownerOf(tokenIds[i]) != _msgSender())
                revert NotTokenOwnerError();
            mintToBurnId[nextId + i] = tokenIds[i];
            unchecked {
                ++i;
            }
        }
        _setAux(_msgSender(), uint64(nonce) + 1);
        garbageBags.burnBatch(tokenIds);
        _mint(_msgSender(), tokenIds.length);
    }

    /**
     * @notice Sets the pause status
     * @param _status bool
     */
    function setPause(bool _status) external onlyOwner {
        paused = _status;
    }

    /**
     * @notice Sets the uri suffix
     * @param _uriSuffix string
     */
    function setUriSuffix(string calldata _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    /**
     * @notice Update the base token URI
     * @param _newBaseURI string
     */
    function setBaseURI(string calldata _newBaseURI) external onlyOwner {
        baseTokenURI = _newBaseURI;
    }

    /**
     * @notice Update caller to burn token
     * @param _caller address
     */
    function setAllowedCaller(address _caller) external onlyOwner {
        _allowedCaller = _caller;
    }

    /**
     * @dev To change signer wallet address
     * @param _signer new signer wallet address
     */
    function setSignerWallet(address _signer) external onlyOwner {
        signer = _signer;
    }

    /**
     * @notice Update royalty information
     * @param receiver address
     * @param numerator uint96
     */
    function setDefaultRoyalty(
        address payable receiver,
        uint96 numerator
    ) external onlyOwner {
        _setDefaultRoyalty(receiver, numerator);
    }

    /**
     * @notice burn token ids in batch
     * @param tokenIds uint[]
     */
    function burnBatch(uint256[] calldata tokenIds) external onlyAllowedCaller {
        for (uint256 i; i < tokenIds.length; ) {
            _burn(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function sumOf(uint256[] calldata ids) private pure returns (uint256) {
        uint256 sum;
        for (uint256 i; i < ids.length; ) {
            sum = sum + ids[i];
            unchecked {
                ++i;
            }
        }
        return sum;
    }

    // Override following ERC721a's method to auto restrict marketplace contract

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override onlyAllowedOperatorApproval(operator) {
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

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, tokenId, quantity);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721A, ERC2981) returns (bool) {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns the URI for `tokenId` token
     * @param tokenId uint
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory base = _baseURI();
        return string(abi.encodePacked(base, _toString(tokenId), uriSuffix));
    }

    /**
     * @dev Returns the burn id exchange of minted id
     * @param tokenId uint
     */
    function getBurnId(uint256 tokenId) external view returns (uint256) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return mintToBurnId[tokenId];
    }

    /**
     * @dev Returns the nonce of user
     * @param user address
     */
    function nonces(address user) external view returns (uint256) {
        return _getAux(user);
    }
}