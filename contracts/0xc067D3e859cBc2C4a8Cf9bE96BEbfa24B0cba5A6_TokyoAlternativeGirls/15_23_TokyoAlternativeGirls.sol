// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "erc721-multi-sales/contracts/merkletree/ERC721MultiSaleByMerkle.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";

contract TokyoAlternativeGirls is
    ERC721AntiScam,
    ERC721MultiSaleByMerkle,
    AccessControl
{
    bytes32 public ADMIN = "ADMIN";

    string public baseURI = "";
    string public baseExtension = ".json";

    constructor(address ownerAddress, uint256 ownerMintAmount)
        ERC721A("Tokyo Alternative Girls", "TAG")
    {
        grantRole(ADMIN, msg.sender);
        withdrawAddress = payable(ownerAddress);
        _safeMint(ownerAddress, ownerMintAmount);
    }

    // ==================================================================
    // TAG original
    // ==================================================================
    function totalBurned() external view returns (uint256) {
        return _totalBurned();
    }

    function adminMint(address to, uint256 amount) external onlyRole(ADMIN) {
        _safeMint(to, amount);
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
    // override ERC721MultiSaleByMerkle
    // ==================================================================
    function claim(
        uint256 amount,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable enoughEth(amount) {
        _claim(amount, allowedAmount, merkleProof);
        _safeMint(msg.sender, amount);
    }

    function exchange(
        uint256[] calldata burnTokenIds,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable enoughEth(burnTokenIds.length) {
        _exchange(burnTokenIds, allowedAmount, merkleProof);

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
    // override ERC721MultiSale
    // ==================================================================
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN) {
        _unpause();
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
            interfaceId == type(IERC721AntiScam).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}