// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol';
import '@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IIdentityVerifier.sol';
import './utils/Adminable.sol';

/**
 * @title NFT Smart Contract made by Artiffine
 * @author https://artiffine.com/
 */
contract NFTContractERC1155_Verifier is ERC1155Supply, ERC1155URIStorage, Adminable {
    struct MintInfo {
        uint256 price;
        bool open;
    }

    IIdentityVerifier public verifier;
    uint256[] public openMintIds;
    mapping(uint256 => MintInfo) public idToMintInfo;

    string private _contractURI;

    event Purchased(address indexed user, uint256 indexed id, uint256 indexed amount, bytes data);
    event MintOpened(uint256 indexed id, uint256 indexed price);
    event MintClosed(uint256 indexed id);

    error MintIsOpened(uint256 tokenId);
    error MintIsClosed(uint256 tokenId);
    error NumberOfTokensIsZero();
    error EtherValueSentNotExact();
    error VerificationFailed();
    error VerifierNotSet();
    error ArgumentIsAddressZero();
    error ContractBalanceIsZero();
    error TransferFailed();

    /**
     * @param _placeholderUri URI to placeholder metadata, settable only once.
     * @param _contractUri URI to the contract-metadata, can be set up later.
     */
    constructor(string memory _placeholderUri, string memory _contractUri) ERC1155(_placeholderUri) {
        _contractURI = _contractUri;
    }

    /**
     * @dev See {ERC1155Supply}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /* External Function */

    /**
     * @notice Mint any number of specified token id.
     *
     * @dev Only available if minting is open for specified token id.
     *
     * @param _id Token id.
     * @param _numberOfTokens Number of NFT tokens.
     * @param _to Address that will recieve minted NFT.
     * @param _data Additional data needed to verify.
     */
    function mint(uint256 _id, uint256 _numberOfTokens, address _to, bytes memory _data) external payable {
        MintInfo storage mintInfo = idToMintInfo[_id];
        if (!mintInfo.open) revert MintIsClosed(_id);
        if (_numberOfTokens == 0) revert NumberOfTokensIsZero();
        if (msg.value != _numberOfTokens * mintInfo.price) revert EtherValueSentNotExact();
        bool isVerified = verifier.verify(_to, _id, _numberOfTokens, _data);
        if (!isVerified) revert VerificationFailed();
        _mint(_to, _id, _numberOfTokens, _data);
        emit Purchased(_to, _id, _numberOfTokens, _data);
    }

    /**
     * @dev See {ERC1155URIStorage}.
     */
    function uri(uint256 tokenId) public view virtual override(ERC1155, ERC1155URIStorage) returns (string memory) {
        return super.uri(tokenId);
    }

    /**
     * @notice Returns URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /* External Admin Function */

    /**
     * @notice Opens minting of specified token id, callable only by the admin/owner.
     *
     * @param _price Price in ether per NFT, can be zero.
     */
    function openMint(uint256 _id, uint256 _price) external onlyAdmin {
        MintInfo storage mintInfo = idToMintInfo[_id];
        if (mintInfo.open) revert MintIsOpened(_id);
        if (address(verifier) == address(0)) revert VerifierNotSet();
        mintInfo.price = _price;
        mintInfo.open = true;
        openMintIds.push(_id);
        emit MintOpened(_id, _price);
    }

    /**
     * @notice Closes minting of specified token id, callable only by the admin/owner.
     *
     * @param _id Token id.
     */
    function closeMint(uint256 _id) external onlyAdmin {
        MintInfo storage mintInfo = idToMintInfo[_id];
        if (!mintInfo.open) revert MintIsClosed(_id);
        _removeFromOpenMints(_id);
        mintInfo.open = false;
        emit MintClosed(_id);
    }

    /**
     * @dev Removes given number from openMints array.
     *
     * @param _id Number to remove.
     */
    function _removeFromOpenMints(uint256 _id) private {
        uint256 length = openMintIds.length;
        uint256 index;
        for (uint256 i = 0; i < length; i++) {
            if (openMintIds[i] == _id) {
                index = i;
                break;
            }
        }
        openMintIds[index] = openMintIds[length - 1];
        openMintIds.pop();
    }

    /**
     * @notice Sets address of verifier contract, callable only by the owner.
     *
     * @param _identityVerifier Address of IIdentityVerifier contract.
     */
    function setIdentityVerifier(address _identityVerifier) external onlyAdmin {
        if (_identityVerifier == address(0)) revert ArgumentIsAddressZero();
        verifier = IIdentityVerifier(_identityVerifier);
    }

    /**
     * @notice Sets URI of contract-level metadata.
     *
     * @param _URI URI of contract-level metadata.
     */
    function setContractURI(string memory _URI) external onlyAdmin {
        _contractURI = _URI;
    }

    /**
     * @notice Sets URI metadata for a given token id.
     *
     * @param _id Token id.
     * @param _URI URI of token metadata.
     */
    function setTokenURI(uint256 _id, string memory _URI) external onlyAdmin {
        _setURI(_id, _URI);
    }

    /**
     * @notice Free mints tokens to specified address, callable only by the owner.
     *
     * @param _id Token id.
     * @param _numberOfTokens Number of NFT tokens.
     * @param _to Address that will recieve minted NFT.
     */
    function freeMint(uint256 _id, uint256 _numberOfTokens, address _to) external onlyAdmin {
        if (_numberOfTokens == 0) revert NumberOfTokensIsZero();
        _mint(_to, _id, _numberOfTokens, '');
    }

    /* External Owner Function */

    /**
     * @notice Transfers all native currency to the owner, callable only by the owner.
     */
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance == 0) revert ContractBalanceIsZero();
        (bool success, ) = msg.sender.call{value: balance}('');
        if (!success) revert TransferFailed();
    }

    /**
     * @notice Recovers ERC20 token back to the owner, callable only by the owner.
     *
     * @param _token IERC20 token address to recover.
     */
    function recoverToken(IERC20 _token) external onlyOwner {
        if (address(_token) == address(0)) revert ArgumentIsAddressZero();
        uint256 balance = _token.balanceOf(address(this));
        if (balance == 0) revert ContractBalanceIsZero();
        _token.transfer(owner(), balance);
    }
}