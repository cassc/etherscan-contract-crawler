// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721-multi-sales/contracts/multi-wallet/merkletree/ERC721MultiSaleByMerkleMultiWallet.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import {DefaultOperatorFilterer} from "./libs/DefaultOperatorFilterer.sol";

contract UjuFreeMint202211 is
    DefaultOperatorFilterer,
    ERC721AntiScam,
    ERC721MultiSaleByMerkleMultiWallet,
    AccessControl
{
    bytes32 public ADMIN = "ADMIN";

    string public baseURI = "";
    string public baseExtension = ".json";

    constructor(address ownerAddress, uint256 ownerMintAmount)
        ERC721A(
            "One day,Ujuuna killed in explosion, and his reincarnation is decided at generative.",
            "UJU"
        )
    {
        grantRole(ADMIN, msg.sender);
        withdrawAddress = payable(ownerAddress);
        _safeMint(ownerAddress, ownerMintAmount);
    }

    // ==================================================================
    // original
    // ==================================================================
    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function adminMint(address[] calldata to, uint256[] calldata amount)
        external
        onlyRole(ADMIN)
    {
        require(to.length == amount.length);
        for (uint256 i = 0; i < to.length; i++) {
            _safeMint(to[i], amount[i]);
        }
    }

    // ==================================================================
    // overrive ERC721A for operator-filter-registry
    // ==================================================================
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

    // ==================================================================
    // override ERC721
    // ==================================================================
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(abi.encodePacked(ERC721A.tokenURI(tokenId), baseExtension));
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // ==================================================================
    // override ERC721MultiSaleByMerkleMultWallet
    // ==================================================================
    function claim(
        uint256 userId,
        uint256 amount,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable enoughEth(amount) {
        _claim(userId, amount, allowedAmount, merkleProof);
        _safeMint(msg.sender, amount);
    }

    function exchange(
        uint256 userId,
        uint256[] calldata burnTokenIds,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable enoughEth(burnTokenIds.length) {
        _exchange(userId, burnTokenIds, allowedAmount, merkleProof);

        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            uint256 tokenId = burnTokenIds[i];
            require(msg.sender == ownerOf(tokenId), "only holder.");
            _burn(tokenId);
        }

        _safeMint(msg.sender, burnTokenIds.length);
    }

    function setCurrentSale(Sale calldata sale, bytes32 merkleRoot)
        external
        onlyRole(ADMIN)
    {
        _setCurrentSale(sale);
        _merkleRoot = merkleRoot;
    }

    // ==================================================================
    // override BasicSale
    // ==================================================================
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    function withdraw() external onlyRole(ADMIN) {
        _withdraw();
    }

    function setWithdrawAddress(address payable value)
        external
        onlyRole(ADMIN)
    {
        withdrawAddress = value;
    }

    function setMaxSupply(uint256 value) external onlyRole(ADMIN) {
        maxSupply = value;
    }

    function _totalSupply() internal view override returns (uint256) {
        return totalSupply();
    }

    // ==================================================================
    // override ERC721RestrictApprove
    // ==================================================================
    function addLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer)
        external
        onlyRole(ADMIN)
    {
        _removeLocalContractAllowList(transferer);
    }

    function setCAL(address calAddress) external onlyRole(ADMIN) {
        _setCAL(calAddress);
    }

    function setCALLevel(uint256 level) external onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setEnableRestrict(bool value) external onlyRole(ADMIN) {
        enableRestrict = value;
    }

    // ==================================================================
    // override ERC721Loclable
    // ==================================================================
    function setContractLock(LockStatus lockStatus) external onlyRole(ADMIN) {
        _setContractLock(lockStatus);
    }

    function setWalletLock(address to, LockStatus lockStatus) external {
        require(msg.sender == to, "only yourself.");
        _setWalletLock(to, lockStatus);
    }

    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus)
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(msg.sender == ownerOf(tokenIds[i]), "not owner.");
        }
        _setTokenLock(tokenIds, lockStatus);
    }

    function setEnableLock(bool value) external onlyRole(ADMIN) {
        enableLock = value;
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }

    // ==================================================================
    // interface
    // ==================================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721AntiScam)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}