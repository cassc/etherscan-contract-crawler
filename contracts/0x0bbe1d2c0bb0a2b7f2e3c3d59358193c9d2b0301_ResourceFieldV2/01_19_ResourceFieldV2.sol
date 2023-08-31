// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

////////////////////////////////////////////////////////////////////////////////////////
//                                                                                    //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ██████████████▌          ╟██           ████████████████          j██████████████  //
//  ██████████████▌          ╟███           ███████████████          j██████████████  //
//  ██████████████▌          ╟███▌           ██████████████          j██████████████  //
//  ██████████████▌          ╟████▌           █████████████          j██████████████  //
//  ██████████████▌          ╟█████▌          ╙████████████          j██████████████  //
//  ██████████████▌          ╟██████▄          ╙███████████          j██████████████  //
//  ██████████████▌          ╟███████           ╙██████████          j██████████████  //
//  ██████████████▌          ╟████████           ╟█████████          j██████████████  //
//  ██████████████▌          ╟█████████           █████████          j██████████████  //
//  ██████████████▌          ╟██████████           ████████          j██████████████  //
//  ██████████████▌          ╟██████████▌           ███████          j██████████████  //
//  ██████████████▌          ╟███████████▌           ██████          j██████████████  //
//  ██████████████▌          ╟████████████▄          ╙█████        ,████████████████  //
//  ██████████████▌          ╟█████████████           ╙████      ▄██████████████████  //
//  ██████████████▌          ╟██████████████           ╙███    ▄████████████████████  //
//  ██████████████▌          ╟███████████████           ╟██ ,███████████████████████  //
//  ██████████████▌                      ,████           ███████████████████████████  //
//  ██████████████▌                    ▄██████▌           ██████████████████████████  //
//  ██████████████▌                  ▄█████████▌           █████████████████████████  //
//  ██████████████▌               ,█████████████▄           ████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//  ████████████████████████████████████████████████████████████████████████████████  //
//                                                                                    //
////////////////////////////////////////////////////////////////////////////////////////

import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../resources/IResources.sol";
import "./IResourceFieldV2.sol";

contract ResourceFieldV2 is AdminControl, IResourceFieldV2, IERC721, IERC721Metadata {
    using ECDSA for bytes32;
    using Strings for uint256;

    string constant public override name = "LVCIDIA// Resource Field";
    string constant public override symbol = "LRF";

    uint256 private constant MAX_UINT96 = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    // Resource contract address
    address public immutable RESOURCE_ADDRESS;
    
    // Whether or not contract is enabled
    bool private _enabled;

    // Validation signing address
    address private _signingAddress;

    // Message nonces
    mapping(bytes32 => bool) private _usedNonces;

    // Mapping for staked token info
    mapping(address => mapping (uint256 => address)) private _stakeOwner;
    // Owner address to balance
    mapping(address => uint256) private _stakeBalances;
    // Mapping for metadata override
    mapping(address => string) private _tokenURIOverride;

    constructor(address resourceAddress, address signingAddress) {
        RESOURCE_ADDRESS = resourceAddress;
        _signingAddress = signingAddress;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return
            interfaceId == type(IResourceFieldV2).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            AdminControl.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IResourceField-updateSigner}.
     */
    function updateSigner(address signingAddress) external override onlyOwner {
        _signingAddress = signingAddress;
    }

    /**
     * @dev See {IResourceField-enable}.
     */
    function enable() external override onlyOwner {
        _enabled = true;
    }

    /**
     * @dev See {IResourceField-disable}.
     */
    function disable() external override adminRequired {
        _enabled = false;
    }

    /**
     * @dev See {IResourceField-disable}.
     */
    function setTokenURIOverride(address contractAddress, string memory uriOverride) external override adminRequired {
        _tokenURIOverride[contractAddress] = uriOverride;
    }

    /**
     * @dev See {IResourceField-stakeMultiple}.
     */
    function stakeMultiple(address[] calldata tokenAddresses, uint256[] calldata tokenIds, bytes calldata data) external override {
        require(tokenAddresses.length == tokenIds.length, "Invalid input");
        require(_enabled, "Disabled");
        uint256 length = tokenAddresses.length;
        for (uint i = 0; i < length;) {
            require(tokenIds[i] <= MAX_UINT96, "Invalid tokenId");
            IERC721(tokenAddresses[i]).safeTransferFrom(msg.sender, address(this), tokenIds[i], data);
            emit Transfer(address(0), msg.sender, _encodeToken(tokenAddresses[i], tokenIds[i]));
            unchecked { i++; }
        }
        _stakeBalances[msg.sender] += length;
    }

    /**
     * @dev See {IResourceField-unstake}.
     */
    function unstake(address[] calldata tokenAddresses, uint256[] calldata tokenIds) external override {
        require(tokenAddresses.length == tokenIds.length, "Invalid input");
        uint256 length = tokenAddresses.length;
        for (uint i = 0; i < length;) {
            address tokenAddress = tokenAddresses[i];
            uint256 tokenId = tokenIds[i];
            address ownerAddress = _stakeOwner[tokenAddress][tokenId];
            require(ownerAddress == msg.sender, "Cannot unstake token you do not own");
            _stakeOwner[tokenAddress][tokenId] = address(0);
            IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
            emit Unstake(ownerAddress, tokenAddress, tokenId);
            emit Transfer(msg.sender, address(0), _encodeToken(tokenAddress, tokenId));
            unchecked { i++; }
        }
        _stakeBalances[msg.sender] -= length;
    }

    /**
     * @dev See {IResourceField-recover}.
     */
    function recover(address tokenAddress, uint256 tokenId, address recipient) external override onlyOwner {
        require(_stakeOwner[tokenAddress][tokenId] == address(0), "Cannot recover staked token");
        IERC721(tokenAddress).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @dev See {IResourceField-claimResources}.
     */
    function claimResources(uint256[] calldata tokenIds, uint256[] calldata amounts, bytes32 message, bytes calldata signature, bytes32 nonce) external override {
        require(_enabled, "Disabled");
        // Check signature data
        _validateClaimSignature(tokenIds, amounts, message, signature, nonce);
        IResources(RESOURCE_ADDRESS).safeBatchTransferFrom(address(this), msg.sender, tokenIds, amounts, "");
        emit ClaimResource(nonce, msg.sender, tokenIds, amounts);
    }

    /**
     * @dev See {IResourceField-burnResources}.
     */
    function burnResources(uint256[] calldata tokenIds, uint256[] calldata amounts) external override onlyOwner {
        IResources(RESOURCE_ADDRESS).burn(address(this), tokenIds, amounts);
    }

    /**
     * Validate claim signature
     */
    function _validateClaimSignature(uint256[] calldata tokenIds, uint256[] calldata amounts, bytes32 message, bytes calldata signature, bytes32 nonce) internal virtual {
        // Verify nonce usage/re-use
        require(!_usedNonces[nonce], "Cannot replay transaction");
        // Verify valid message based on input variables
        uint256 length = 52+64*tokenIds.length;
        bytes32 expectedMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", length.toString(), msg.sender, nonce, tokenIds, amounts));
        require(message == expectedMessage, "Malformed message");
        // Verify signature was performed by the expected signing address
        address signer = message.recover(signature);
        require(signer == _signingAddress, "Invalid signature");

        _usedNonces[nonce] = true;
    }

    /**
     * @dev See {IResourceField-nonceUsed}.
     */
    function nonceUsed(bytes32 nonce) external view override returns (bool) {
        return _usedNonces[nonce];
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        require(_enabled, "Disabled");
        // Check that this is a token that can be staked
        require(tokenId <= MAX_UINT96, "Invalid tokenId");
        _stakeOwner[msg.sender][tokenId] = from;
        emit Stake(from, msg.sender, tokenId, data);
        emit Transfer(address(0), from, _encodeToken(msg.sender, tokenId));
        _stakeBalances[from] += 1;
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) view public override returns (bytes4) {
        require(msg.sender == RESOURCE_ADDRESS, "Only LVCIDIA// RESOURCES accepted");
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) view public override returns (bytes4) {
        require(msg.sender == RESOURCE_ADDRESS, "Only LVCIDIA// RESOURCES accepted");
        return this.onERC1155BatchReceived.selector;
    }

    function _encodeToken(address tokenAddress, uint256 tokenId) private pure returns (uint256) {
        return uint256(uint160(tokenAddress)) << 96 | uint96(tokenId); 
    }

    function _decodeToken(uint256 token) private pure returns (address tokenAddress, uint256 tokenId) {
        tokenAddress = address(uint160(token >> 96));
        tokenId = uint96(token);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256
    ) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address, uint256) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256) external pure override returns (address) {
        return address(0);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) external pure override {
        _transferRevert();
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address, address) external pure override returns (bool) {
        return false;
    }

    function _transferRevert() private pure {
        revert("Cannot perform transfers on a non-transferable token");
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 token) external view override returns (address) {
        (address tokenAddress, uint256 tokenId) = _decodeToken(token);
        address owner = _stakeOwner[tokenAddress][tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 token) external view override returns (string memory) {
        (address tokenAddress, uint256 tokenId) = _decodeToken(token);
        require(_stakeOwner[tokenAddress][tokenId] != address(0), "ERC721: invalid token ID");
        string memory uriOverride = _tokenURIOverride[tokenAddress];
        if (bytes(uriOverride).length > 0) {
            return string(abi.encodePacked(uriOverride, '/', tokenId.toString(), '.json'));
        }
        return IERC721Metadata(tokenAddress).tokenURI(tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _stakeBalances[owner];
    }

}