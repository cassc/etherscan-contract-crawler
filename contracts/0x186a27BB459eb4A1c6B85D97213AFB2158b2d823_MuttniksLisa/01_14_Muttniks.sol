//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import {OperatorFilterer} from 'closedsea/src/OperatorFilterer.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';

error SoldOut();
error SaleNotStarted();
error MintingTooMany();
error NotWhitelisted();
error Underpriced();
error MintedOut();
error MaxMints();
error ArraysDontMatch();
error ZeroAddress();
error NotAuthorized();
error NotSender();
error CombinationAlreadyUsed();
error CombinationNotApproved();
error ArrayNotAscendingOrSteady();
error UnsafeUint16Cast();

/// @title Muttniks User Generative Collection
/// @author 0xSimon

contract MuttniksLisa is ERC721AQueryable, Ownable, OperatorFilterer, ERC2981 {
    using ECDSA for bytes32;
    uint256 public maxSupply = 5000;
    uint256 private constant BITSIZE_OF_TRAIT = 16; //16 bits
    uint256 private constant DATA_ENTRY = (1 << 16) - 1;
    uint256 public maxPublicMints = 10;
    uint256 public whitelistMintPrice;
    uint256 public publicMintPrice;
    address private signer = 0x235AAE9ed08Edfe150fd71592d51b1Af44C57034;
    string private baseURI =
        'https://smuphotobucket.s3.amazonaws.com/mutniks/json/';
    string private uriSuffix = '.json';
    bool private operatorFilteringEnabled;
    /*
    [0..15] trait 1
    [16...31] trait 2
    [32...47] trait 3
    [....]
    ...
    */
    /// @dev tracks to see if a unique combination of traits has been used
    /// @dev traits are ordered ascending off-chain so there can be no duplicate identifiers
    mapping(uint => bool) public isBitpackedComboUsed;

    /// @dev stores the packed data for a token
    mapping(uint => uint) private bitpackedTokenTraitArray;
    event MutnikCreated(uint indexed tokenId, uint[11] traits);

    //Not Mutually Exclusive
    bool public holderClaimOn = true;
    bool public whitelistMintOn;
    bool public publicMintOn;

    constructor() ERC721A('Muttniks Lisa', 'MTNKS') {
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *                     Utilities
        ...............~~~~~~~~~~~~~~~...............
    */

    function packTraitArray(
        uint[11] calldata traitArray
    ) public pure returns (uint) {
        uint packedVal;
        for (uint i; i < traitArray.length; ) {
            uint valToAdd = traitArray[i] << (i * BITSIZE_OF_TRAIT);
            packedVal |= valToAdd;

            unchecked {
                ++i;
            }
        }
        return packedVal;
    }

    /// @param packedVal - the bitpacked value of a uint[11] array
    /// @return traitArray - the unapacked array
    function unpackPackedTraitArrayValue(
        uint packedVal
    ) public pure returns (uint[11] memory traitArray) {
        for (uint i; i < traitArray.length; ) {
            uint unpackedVal = (packedVal >> (i * BITSIZE_OF_TRAIT)) &
                DATA_ENTRY;
            traitArray[i] = unpackedVal;
            unchecked {
                ++i;
            }
        }
    }

    /// @param tokenId the tokenId you wish to query
    ///@return the trait array of a token
    function unpackPackedTokenTraitArray(
        uint tokenId
    ) external view returns (uint[11] memory) {
        uint packedVal = bitpackedTokenTraitArray[tokenId];
        uint[11] memory traitArray = unpackPackedTraitArrayValue(packedVal);
        return traitArray;
    }

    /// @dev helper to see if the trait array is ascending or steady and if the trait identifier is not greater than uint16
    function _traitArrayCheck(uint[11] memory arr) internal pure {
        for (uint i; i < arr.length - 1; ) {
                if (arr[i] > arr[i + 1]) revert ArrayNotAscendingOrSteady();
                if (arr[i] > type(uint16).max) revert UnsafeUint16Cast();
                unchecked {
                ++i;
            }
        }
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *                   Mint Functions
        ...............~~~~~~~~~~~~~~~...............
    */

    function mutnikMint(
        uint[11] calldata traitArray,
        bytes memory signature
    ) external payable {
        uint packedVal = packTraitArray(traitArray);
        _traitArrayCheck(traitArray);
        uint nextTokenId = _nextTokenId();
        if (isBitpackedComboUsed[packedVal]) revert CombinationAlreadyUsed();
        if (nextTokenId + 1 > maxSupply) revert SoldOut();
        if (msg.value < publicMintPrice) revert Underpriced();
        if (!publicMintOn) revert SaleNotStarted();
        if (getNumMintedPublicOrWhitelist(_msgSender()) + 1 > maxPublicMints)
            revert MaxMints();
        bytes32 hash = keccak256(abi.encodePacked(traitArray));
        if (hash.toEthSignedMessageHash().recover(signature) != signer)
            revert CombinationNotApproved();
        isBitpackedComboUsed[packedVal] = true;
        bitpackedTokenTraitArray[nextTokenId] = packedVal;
        incrementNumMintedWhitelistOrPublic(_msgSender(), 1);
        emit MutnikCreated(nextTokenId, traitArray);
        _mint(_msgSender(), 1);
    }

    function mutnikMintWhitelist(
        uint[11] calldata traitArray,
        uint max,
        bytes memory signature
    ) external payable {
        uint packedVal = packTraitArray(traitArray);
        uint nextTokenId = _nextTokenId();
        _traitArrayCheck(traitArray);
        if (isBitpackedComboUsed[packedVal]) revert CombinationAlreadyUsed();
        if (msg.value < whitelistMintPrice) revert Underpriced();
        if (nextTokenId + 1 > maxSupply) revert SoldOut();
        if (!whitelistMintOn) revert SaleNotStarted();
        if (getNumMintedPublicOrWhitelist(_msgSender()) + 1 > max)
            revert MaxMints();
        bytes32 hash = keccak256(
            abi.encodePacked(_msgSender(), max, traitArray, 'WHITELIST')
        );
        if (hash.toEthSignedMessageHash().recover(signature) != signer)
            revert CombinationNotApproved();
        isBitpackedComboUsed[packedVal] = true;
        bitpackedTokenTraitArray[nextTokenId] = packedVal;
        incrementNumMintedWhitelistOrPublic(_msgSender(), 1);
        emit MutnikCreated(nextTokenId, traitArray);
        _mint(_msgSender(), 1);
    }

    function holderClaimMint(
        uint[11] calldata traitArray,
        uint max,
        bytes memory signature
    ) external {
        uint packedVal = packTraitArray(traitArray);
        uint nextTokenId = _nextTokenId();
        _traitArrayCheck(traitArray);
        if (isBitpackedComboUsed[packedVal]) revert CombinationAlreadyUsed();
        if (nextTokenId + 1 > maxSupply) revert SoldOut();
        if (!holderClaimOn) revert SaleNotStarted();
        if (getNumClaimed(_msgSender()) + 1 > max) revert MaxMints();
        bytes32 hash = keccak256(
            abi.encodePacked(_msgSender(), max, traitArray)
        );
        if (hash.toEthSignedMessageHash().recover(signature) != signer)
            revert CombinationNotApproved();
        isBitpackedComboUsed[packedVal] = true;
        bitpackedTokenTraitArray[nextTokenId] = packedVal;
        emit MutnikCreated(nextTokenId, traitArray);
        _mint(_msgSender(), 1);
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *                Getters and Helpers
        ...............~~~~~~~~~~~~~~~...............
    */
    function isTraitArrayUsed(
        uint[11] calldata traitArray
    ) external view returns (bool) {
        uint packedVal = packTraitArray(traitArray);
        return isBitpackedComboUsed[packedVal];
    }

    function getNumMintedPublicOrWhitelist(
        address account
    ) public view returns (uint256) {
        return uint256(_getAux(account));
    }

    //We use a hot sload
    function incrementNumMintedWhitelistOrPublic(
        address account,
        uint amount
    ) private {
        _setAux(account, uint64(_getAux(account) + amount));
    }

    function getNumClaimed(address account) public view returns (uint256) {
        return uint256(_numberMinted(account));
    }

    /*
        ...............~~~~~~~~~~~~~~~...............
    *                     Setters
        ...............~~~~~~~~~~~~~~~...............
    */

    function setWhitelistMintPrice(uint256 price) external onlyOwner {
        whitelistMintPrice = price;
    }

    function setMaxPublicMints(uint maxPublicMints_) external onlyOwner {
        maxPublicMints = maxPublicMints_;
    }

    function setPublicMintPrice(uint256 price) external onlyOwner {
        publicMintPrice = price;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setWhitelistStatus(bool status) external onlyOwner {
        whitelistMintOn = status;
    }

    function setPublicStatus(bool status) external onlyOwner {
        publicMintOn = status;
    }

    function setHolderClaimStatus(bool status) external onlyOwner {
        holderClaimOn = status;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /*
    ...............~~~~~~~~~~~~~~~...............
                     METADATA
    ...............~~~~~~~~~~~~~~~...............
*/
    function tokenURI(
        uint256 tokenId
    ) public view override(IERC721A, ERC721A) returns (string memory) {
        string memory currentBaseURI = baseURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _toString(tokenId),
                        uriSuffix
                    )
                )
                : '';
    }

    function _startTokenId() internal pure override(ERC721A) returns (uint) {
        return 0;
    }

    /*///////////////////////////////////////////////////////////////
                           WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/
    function withdraw() external onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}('');
        require(os);
    }

    //----ClosedSea Functions ----------------
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(IERC721A, ERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(
        address operator
    ) internal pure override returns (bool) {
        // OpenSea Seaport Conduit:
        // https://etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        // https://goerli.etherscan.io/address/0x1E0049783F008A0085193E00003D00cd54003c71
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}