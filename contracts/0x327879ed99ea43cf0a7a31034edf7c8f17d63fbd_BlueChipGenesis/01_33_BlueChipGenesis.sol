// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./contract-allow-list/ERC721AntiScam.sol";
import "./interface/ITokenURI.sol";

error MaxSupplyOver();

contract BlueChipGenesis is AccessControl, Pausable, ERC721AntiScam, DefaultOperatorFilterer, ERC2981 {
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant MINTER = keccak256("MINTER");
    uint256 constant MAX_SUPPLY = 26000;
    uint256 public baseTime;

    using Strings for uint256;

    string public baseURI = "https://bluechip-genesis.s3.ap-northeast-1.amazonaws.com/metadata/";
    string public baseExtension = ".json";
    ITokenURI public tokenuri;

    address constant TREASURY_ADDRESS = 0x4f4823F3639DdCC2B14093a28802E214C7C28D03;
    address public royaltyReceiver = 0x4f4823F3639DdCC2B14093a28802E214C7C28D03;

    constructor() ERC721Psi("BLUECHIP-GENESIS-", "BCG") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, 0x407211BeF7cbca2C8897C580EC16c80F2ad5c966);
        _grantRole(ADMIN, 0x11F51b553ed8175Bf26faD5Eec20BEbAB31c0893);
        _grantRole(MINTER, msg.sender);

        _safeMint(TREASURY_ADDRESS, 782);

        _pause();

        _setDefaultRoyalty(royaltyReceiver, 1000); // 10%

        baseTime = block.timestamp;
    }

    /**
     * ミント関数
     */
    /// @dev MINTERによるミント関数
    function mint(address _to, uint256 _amount) external onlyRole(MINTER) {
        /**
         * @notice ミント用コントラクトでコントラクトからのミントをrevertしているので
         *         _safeMint()ではなく_mint()を使用しています
         */
        if (_amount + totalSupply() > MAX_SUPPLY) revert MaxSupplyOver();
        _mint(_to, _amount);
    }

    /// @dev エアドロミント関数
    function adminMint(address[] calldata _airdropAddresses, uint256[] calldata _UserMintAmount)
        external
        onlyRole(ADMIN)
    {
        require(_airdropAddresses.length == _UserMintAmount.length, "array length unmatch");

        uint256 _totalAmmount;

        for (uint256 i = 0; i < _UserMintAmount.length; i++) {
            require(_UserMintAmount[i] > 0, "amount 0 address exists!");

            // adminがボケた引数を入れないことが大前提
            unchecked {
                _totalAmmount += _UserMintAmount[i];
            }

            if (_totalAmmount + totalSupply() > MAX_SUPPLY) revert MaxSupplyOver();

            _safeMint(_airdropAddresses[i], _UserMintAmount[i]);
        }
    }

    /**
     * ADMIN用 setter関数
     */
    /// @dev メタデータフォルダーのsetter（..../まで）
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }

    /// @dev メタデータファイル拡張子のsetter（デフォルトは.json）
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }

    /// @dev オンチェーンメタデータ用のコントラクトsetter関数
    function setOnChainTokenURI(address _tokenUriContract) external onlyRole(ADMIN) {
        tokenuri = ITokenURI(_tokenUriContract);
    }

    /// @dev transferを禁止するsetter関数（ミントも止まります）
    function pause() external onlyRole(ADMIN) {
        _pause();
    }

    /// @dev transferを禁止を解除するsetter関数
    function unpause() external onlyRole(ADMIN) {
        _unpause();
    }

    /// @dev sAFA抑止機能のON/OFF（基本はONですが、念のため）
    function setEnableRestrict(bool value) external onlyRole(ADMIN) {
        enableRestrict = value;
    }

    /// @dev ロック機構のON/OFF（基本はONですが、念のため）
    function setEnableLock(bool value) external onlyRole(ADMIN) {
        enableLock = value;
    }

    /**
     * OVERRIDES ERC721Lockable functions
     */
    /**
     * @notice setTokenLock()とsetWalletLock()は持ち主に加え、ADMINも操作できるようにしました
     *         setContractLock()はownerでなく、ADMINが使えるようにしました
     */
    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus) external override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(msg.sender == ownerOf(tokenIds[i]) || hasRole(ADMIN, msg.sender), "not owner or admin.");
        }
        _setTokenLock(tokenIds, lockStatus);
    }

    function setWalletLock(address to, LockStatus lockStatus) external override {
        require(to == msg.sender || hasRole(ADMIN, msg.sender), "not yourself or admin.");
        _setWalletLock(to, lockStatus);
    }

    function setContractLock(LockStatus lockStatus) external override onlyRole(ADMIN) {
        _setContractLock(lockStatus);
    }

    /**
     * OVERRIDES ERC721RestrictApprove functions
     */
    function addLocalContractAllowList(address transferer) external override onlyRole(ADMIN) {
        _addLocalContractAllowList(transferer);
    }

    function removeLocalContractAllowList(address transferer) external override onlyRole(ADMIN) {
        _removeLocalContractAllowList(transferer);
    }

    function getLocalContractAllowList() external view override returns (address[] memory) {
        return _getLocalContractAllowList();
    }

    function setCALLevel(uint256 level) external override onlyRole(ADMIN) {
        CALLevel = level;
    }

    function setCAL(address calAddress) external override onlyRole(ADMIN) {
        _setCAL(calAddress);
    }

    /**
     * OVERRIDES OperatorFilter functions
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Psi)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721Psi)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721Psi)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * ERC2981のSetter関数
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyRole(ADMIN) {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyRole(ADMIN) {
        _deleteDefaultRoyalty();
    }

    /**
     * その他の関数
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721AntiScam, ERC2981)
        returns (bool)
    {
        return (
            AccessControl.supportsInterface(interfaceId) || ERC721AntiScam.supportsInterface(interfaceId)
                || ERC2981.supportsInterface(interfaceId) || super.supportsInterface(interfaceId)
        );
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "URI query for nonexistent token");

        if (address(tokenuri) != address(0)) {
            return tokenuri.tokenURI(_tokenId);
        }

        return string(abi.encodePacked(ERC721Psi.tokenURI(_tokenId), baseExtension));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /// @notice pause()でtransfer禁止
    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity)
        internal
        override
        whenNotPaused
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}