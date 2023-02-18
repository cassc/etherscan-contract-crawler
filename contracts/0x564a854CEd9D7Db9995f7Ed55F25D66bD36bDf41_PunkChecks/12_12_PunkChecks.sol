// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {DefaultOperatorFilterer} from "operator-filter-registry/DefaultOperatorFilterer.sol";

import {ICryptoPunks} from "./ICryptoPunks.sol";
import {IDelegationRegistry} from "./IDelegationRegistry.sol";

error TokenDoesNotExist();
error MaxSupplyReached();
error WrongEtherAmount();
error InvalidVersion();
error NoEthBalance();
error NoCoinBalance();
error MintNotOpen();
error MintNotOpenForVersion();

/// @author flatmap.eth
/// @author snjolfur.eth
contract PunkChecks is DefaultOperatorFilterer, ERC721, Owned {
    uint256 public price = 0.0069 ether;

    address constant PUNKS_V1_ADDRESS = address(0x6Ba6f2207e343923BA692e5Cae646Fb0F566DB8D);
    address constant PUNKS_V2_ADDRESS = address(0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB);
    address constant PUNKS_V1_WRAPPER_ADDRESS = address(0x282BDD42f4eb70e7A9D9F40c8fEA0825B7f68C5D);
    address constant PUNKS_V2_WRAPPER_ADDRESS = address(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6);

    address constant DELEGATE_CASH_ADDRESS = address(0x00000000000076A84feF008CDAbe6409d2FE638B);

    address public renderingContractAddress;
    address public vaultAddress;

    string contractUri = "https://punkchecks.xyz/api/contractURI";

    mapping(uint256 => uint256) public typeByPunkId;
    uint256 private mintType;

    /// Mint types for PunkChecks, i.e. which CryptoPunks holders are allowed to mint
    uint256 private constant OPEN = 0;
    uint256 private constant V1_HOLDERS = 1;
    uint256 private constant V2_HOLDERS = 2;
    uint256 private constant HOLDERS_OF_BOTH = 3;
    uint256 private constant HOLDERS = 4;
    uint256 private constant CLOSED = 5;

    constructor(address _renderingContractAddress, address _vaultAddress, address _owner)
        ERC721("PunkChecks", "PCS")
        Owned(_owner)
    {
        renderingContractAddress = _renderingContractAddress;
        vaultAddress = _vaultAddress;
        mintType = 5;
    }

    /**
     * @notice Mint a PunkCheck
     * @param punkId The ID of the CryptoPunk to mint PunkChecks for
     * @param vaultV1 The address where the CryptoPunks v1 is held if using a delegate wallet
     * @param vaultV2 The address where the CryptoPunks v2 is held if using a delegate wallet
     * @param v The version of PunkChecks to mint, 1 if holding only a v1 Punk, 2 if holding only a v2 Punk, 3 if holding both, 4 if holding none
     */
    function mint(uint256 punkId, address vaultV1, address vaultV2, uint256 v) external payable {
        if (mintType == CLOSED) revert MintNotOpen();
        if (msg.value != price) revert WrongEtherAmount();
        if (v < 1 || v > 4) revert InvalidVersion();
        if (mintType == V1_HOLDERS && v != 1 && v != 3) revert MintNotOpenForVersion();
        if (mintType == V2_HOLDERS && v != 2 && v != 3) revert MintNotOpenForVersion();
        if (mintType == HOLDERS_OF_BOTH && v != 3) revert MintNotOpenForVersion();
        if (mintType == HOLDERS && v == 4) revert MintNotOpenForVersion();

        if (v == 1 || v == 3) {
            _verifyOwnership(punkId, vaultV1, PUNKS_V1_ADDRESS, PUNKS_V1_WRAPPER_ADDRESS);
        }

        if (v == 2 || v == 3) {
            _verifyOwnership(punkId, vaultV2, PUNKS_V2_ADDRESS, PUNKS_V2_WRAPPER_ADDRESS);
        }

        _mint(msg.sender, punkId);
        typeByPunkId[punkId] = v;
    }

    /**
     * @dev Verify that msg.sender is either the owner or a delegatee of the specified CryptoPunk
     * @param punkId The ID of the CryptoPunk to verify ownership of
     * @param vault The address where the CryptoPunk is held if using a delegate wallet
     * @param punksAddress The address of the CryptoPunks contract
     * @param wrapperAddress The address of the CryptoPunks wrapper contract
     */
    function _verifyOwnership(uint256 punkId, address vault, address punksAddress, address wrapperAddress)
        internal
        view
    {
        address requester = msg.sender;
        address owner = ICryptoPunks(punksAddress).punkIndexToAddress(punkId);
        address contractAddress = punksAddress;

        if (owner == wrapperAddress) {
            owner = ERC721(wrapperAddress).ownerOf(punkId);
            contractAddress = wrapperAddress;
        }

        if (vault != address(0)) {
            bool isDelegateValid = IDelegationRegistry(DELEGATE_CASH_ADDRESS).checkDelegateForToken(
                msg.sender, vault, contractAddress, punkId
            );
            require(isDelegateValid, "Punk not delegated");

            requester = vault;
        }

        require(owner == requester, "Punk not owned");
    }

    /**
     * @notice Get a json string with the metadata for a PunkCheck
     * @dev This is delegated to the PunkChecksRenderer contract
     * @param tokenId The ID of the PunkCheck to get the metadata for
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf[tokenId] != address(0), "NOT_MINTED");

        if (renderingContractAddress == address(0)) {
            return "";
        }

        IPunkChecksRenderer renderer = IPunkChecksRenderer(renderingContractAddress);
        return renderer.tokenURI(tokenId, typeByPunkId[tokenId]);
    }

    // Contract URI so OpenSea picks up the collection automatically
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /**
     * @notice Withdraw any ether held by the contract to vault address
     */
    function withdrawEther() external onlyOwner {
        if (address(this).balance == 0) revert NoEthBalance();
        SafeTransferLib.safeTransferETH(vaultAddress, address(this).balance);
    }

    /**
     * @notice Withdraw an ERC721 held by the contract to vault address
     * @param nftAddress The address of the ERC721 contract
     * @param tokenId The ID of the token to withdraw
     */
    function withdraw721(address nftAddress, uint256 tokenId) external onlyOwner {
        ERC721 nft = ERC721(nftAddress);
        if (nft.ownerOf(tokenId) != address(this)) revert NoCoinBalance();
        nft.safeTransferFrom(address(this), vaultAddress, tokenId);
    }

    /**
     * @notice Withdraw an ERC1155 held by the contract to vault address
     * @param nftAddress The address of the ERC1155 contract
     * @param tokenId The ID of the token to withdraw
     */
    function withdraw1155(address nftAddress, uint256 tokenId) external onlyOwner {
        ERC1155 nft = ERC1155(nftAddress);
        uint256 balance = nft.balanceOf(address(this), tokenId);
        if (balance == 0) revert NoCoinBalance();
        nft.safeTransferFrom(address(this), vaultAddress, tokenId, balance, "");
    }

    /**
     * @notice Withdraw an ERC20 held by the contract to vault address
     * @param tokenAddress The address of the ERC20 contract
     */
    function withdrawCoins(address tokenAddress) external onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) revert NoCoinBalance();
        SafeTransferLib.safeTransferFrom(token, address(this), vaultAddress, balance);
    }

    /**
     * @notice Change who is allowed to mint
     */
    function setEnabledMintType(uint256 enabledMintType) public onlyOwner {
        mintType = enabledMintType;
    }

    /**
     * @notice Change the mint price
     */
    function setPrice(uint256 _price) public onlyOwner {
        price = _price;
    }

    /// Operator Filter overrides

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

    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    function setVaultAddress(address _vaultAddress) public onlyOwner {
        vaultAddress = _vaultAddress;
    }

    function setContractURI(string memory _contractUri) public onlyOwner {
        contractUri = _contractUri;
    }
}

abstract contract IPunkChecksRenderer {
    function tokenURI(uint256 punkId, uint256 t) public view virtual returns (string memory);
}