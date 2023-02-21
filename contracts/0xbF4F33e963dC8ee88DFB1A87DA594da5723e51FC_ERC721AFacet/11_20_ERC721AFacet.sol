// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../LibDiamond.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./BaseFacet.sol";
import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "../operatorFilterer/DefaultOperatorFiltererUpgradeable.sol";

contract ERC721AFacet is BaseFacet, ERC721AUpgradeable, IERC2981, DefaultOperatorFiltererUpgradeable {
    using Strings for uint256;
    using ECDSA for bytes32;

    modifier isTokenOwnerOrOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender || owner() == msg.sender, "Budda Bears: Only token owner");
        _;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Humans and Bears only");
        _;
    }

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    modifier supplyAvailable(uint256 quantity) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint256 teamMintsLeft = _as.maxMintsTeam - _as.totalMintedTeam;
        require(_totalMinted() + quantity <= _as.maxSupply - teamMintsLeft, "No more mints");
        _;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        if (_as.isReveal) {
            return string(abi.encodePacked(_as.baseTokenURI, "/", tokenId.toString(), ".json"));
        } else {
            return _as.unrevealURI;
        }
    }

    // Not in used (see @DiamondCutAndLoupeFacet)
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setFilterOperator(address subscriptionOrRegistrantToCopy, bool subscribe) external onlyOwner {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isRegistered(address(this))) {
                if (subscribe) {
                    operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        operatorFilterRegistry.register(address(this));
                    }
                }
            }
        }
    }

    // Take note of the initializer modifiers.
    // - `initializerERC721A` for `ERC721AUpgradeable`.
    function initialize() external initializerERC721A {
        require(msg.sender == owner(), "Budda Bears: Not contract owner");
        __ERC721A_init("Budda Bears", "BUDDA");

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.stakingTransfer = 1;
        _as.stakingOpen = false;
    }

    // =========== ERC721A =========== //

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // ==================== Management ====================

    function setMethodsExposureFacetAddress(address _methodsExposureFacetAddress) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.methodsExposureFacetAddress = _methodsExposureFacetAddress;
    }

    function setBaseTokenURI(string memory _baseTokenURI) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.baseTokenURI = _baseTokenURI;
    }

    function setRoyaltiesRecipient(address _royaltiesRecipient) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesRecipient = _royaltiesRecipient;
    }

    function setRoyaltiesBasisPoints(uint256 _royaltiesBasisPoints) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.royaltiesBasisPoints = _royaltiesBasisPoints;
    }

    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.mintPrice = _mintPrice;
    }

    function setMaxMintsPerWallet(uint32 _maxMintsPerWallet) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.maxMintsPerWallet = _maxMintsPerWallet;
    }

    function setReveal(bool _isReveal) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.isReveal = _isReveal;
    }

    function setPublicMintOpen(bool _publicMintOpen) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.publicMintOpen = _publicMintOpen;
    }

    function setAllowlistMintOpen(bool _allowlistMintOpen) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.allowlistMintOpen = _allowlistMintOpen;
    }

    // ==================== Views ====================

    function maxSupply() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxSupply;
    }

    function baseTokenURI() external view returns (string memory) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.baseTokenURI;
    }

    function mintPrice() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.mintPrice;
    }

    function maxMintsPerWallet() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxMintsPerWallet;
    }

    function maxMintsTeam() external view returns (uint32) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.maxMintsTeam;
    }

    function isReveal() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.isReveal;
    }

    function royaltiesRecipient() external view returns (address) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesRecipient;
    }

    function royaltiesBasisPoints() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.royaltiesBasisPoints;
    }

    function publicMintOpen() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.publicMintOpen;
    }

    function allowlistMintOpen() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.allowlistMintOpen;
    }

    function numberMinted(address who) external view returns (uint256) {
        return _numberMinted(who);
    }

    function totalMintedTeam() external view returns (uint256) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.totalMintedTeam;
    }

    // =========== EIP2981 ===========

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return (_as.royaltiesRecipient, (_salePrice * _as.royaltiesBasisPoints) / LibDiamond.PERCENTAGE_DENOMINATOR);
    }

    // =========== ERC721 ===========

    /*
        @dev
        Allowlist marketplaces to enable gas-less listings.
    */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        if (operator == 0x1E0049783F008A0085193E00003D00cd54003c71) {
            // Seaport's conduit contract
            try
                LibDiamond.OPENSEA_SEAPORT_CONDUIT_CONTROLLER.getChannelStatus(
                    operator,
                    LibDiamond.appStorage().seaportAddress
                )
            returns (bool isOpen) {
                if (isOpen) {
                    return true;
                }
            } catch {}
        }
        // LooksRare
        if (
            operator == LibDiamond.LOOKSRARE_ERC721_TRANSFER_MANAGER ||
            // X2Y2
            operator == LibDiamond.X2Y2_ERC721_DELEGATE
        ) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // =========== Mints =========== //

    function mint(bytes calldata signature, uint256 quantity) external payable callerIsUser supplyAvailable(quantity) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.publicMintOpen, "Mint not open");
        require(_numberMinted(msg.sender) + quantity <= _as.maxMintsPerWallet, "Too many mints");

        require(
            keccak256(abi.encodePacked(msg.sender, quantity)).toEthSignedMessageHash().recover(signature) ==
                _as.signingAddress,
            "Invalid signature"
        );

        _safeMint(msg.sender, quantity);
    }

    function allowlistMint(bytes calldata signature, uint256 quantity) external payable supplyAvailable(quantity) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.allowlistMintOpen, "Mint not open");

        // can only mint once during allowlist phase
        require(_numberMinted(msg.sender) == 0, "Too many mints");

        require(
            keccak256(abi.encodePacked(msg.sender, quantity)).toEthSignedMessageHash().recover(signature) ==
                _as.signingAddress,
            "Invalid signature"
        );

        _safeMint(msg.sender, quantity);
    }

    function mintTeam(address to, uint256 quantity) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();

        require(_as.totalMintedTeam + quantity <= _as.maxMintsTeam, "Too many mints");
        require(_totalMinted() + quantity <= _as.maxSupply, "No more mints");

        _as.totalMintedTeam += quantity;
        _safeMint(to, quantity);
    }

    // =========== Staking =========== //

    event Staked(uint256 indexed tokenId);
    event Unstaked(uint256 indexed tokenId);

    function stakingOpen() external view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as.stakingOpen;
    }

    function stakingStatus(uint32[] calldata tokenIds) external view returns (LibDiamond.Staking[] memory statusses) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        statusses = new LibDiamond.Staking[](tokenIds.length);
        uint32 tokenId;
        uint256 start;
        uint256 current;
        bool staking = false;
        for (uint32 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            start = _as.stakingStarted[tokenId];
            current = 0;
            if (start == 0) {
                staking = false;
            } else {
                staking = true;
                current += block.timestamp - start;
            }

            uint256 total = current + _as.stakingTotal[tokenId];
            statusses[i] = LibDiamond.Staking(staking, current, total);
        }
    }

    /**
    @notice Transfer a token between addresses while the Budda Bear is staking,
    thus not resetting the staking period.
     */
    function safeTransferWhileStaking(
        address from,
        address to,
        uint256 tokenId
    ) external callerIsUser isTokenOwnerOrOwner(tokenId) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.stakingTransfer = 2;
        safeTransferFrom(from, to, tokenId);
        _as.stakingTransfer = 1;
    }

    // Toggles the `stakingOpen` flag.
    function setStakingOpen(bool open) external onlyOwner {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        _as.stakingOpen = open;
    }

    function toggleStaking(uint256 tokenId) internal {
        address tokenOwner = ownerOf(tokenId);
        require(
            msg.sender == tokenOwner || msg.sender == owner() || hasRole(LibDiamond.STAKE_ADMIN, msg.sender),
            "Budda Bears: Only token owner"
        );

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        uint256 start = _as.stakingStarted[tokenId];
        if (start == 0) {
            require(_as.stakingOpen, "Budda Bears: staking closed");
            _as.stakingStarted[tokenId] = block.timestamp;
            emit Staked(tokenId);
        } else {
            _as.stakingTotal[tokenId] += block.timestamp - start;
            _as.stakingStarted[tokenId] = 0;
            emit Unstaked(tokenId);
        }
    }

    // Changes the Budda Bears' staking status
    function toggleStaking(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            toggleStaking(tokenIds[i]);
        }
    }

    //  Ban a Budda Bear from the staking.
    function banFromStaking(uint256 tokenId) external {
        require(
            msg.sender == owner() || hasRole(LibDiamond.STAKE_ADMIN, msg.sender),
            "Budda Bears: Only token owner"
        );

        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        require(_as.stakingStarted[tokenId] != 0, "Budda Bears: not staked");
        _as.stakingTotal[tokenId] += block.timestamp - _as.stakingStarted[tokenId];
        _as.stakingStarted[tokenId] = 0;
        emit Unstaked(tokenId);
    }

    // Block transfers while staking.
    function _beforeTokenTransfers(
        address,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        if (!_as.stakingOpen) return;

        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            require(_as.stakingStarted[tokenId] == 0 || _as.stakingTransfer == 2, "Budda Bears: staking");
        }
    }

    // =========== AccessControl =========== //

    function _checkRole(bytes32 role, address account) internal view {
        require(hasRole(role, account), "AccessControl: account does not have role");
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
        return _as._roles[role].members[account];
    }

    function grantRole(bytes32 role, address account) external onlyOwner {
        if (!hasRole(role, account)) {
            LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
            _as._roles[role].members[account] = true;
        }
    }

    function revokeRole(bytes32 role, address account) external onlyOwner {
        if (hasRole(role, account)) {
            LibDiamond.AppStorage storage _as = LibDiamond.appStorage();
            _as._roles[role].members[account] = false;
        }
    }
}