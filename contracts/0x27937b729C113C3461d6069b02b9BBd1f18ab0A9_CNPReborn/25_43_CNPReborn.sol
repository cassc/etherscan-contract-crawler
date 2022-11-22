// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./gimmick/ICNPRebornGimmick.sol";
import "./tokenUri/ITokenUriSupplier.sol";
import "./ICNPReborn.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "erc721-multi-sales/contracts/multi-wallet/merkletree/ERC721MultiSaleByMerkleMultiWallet.sol";
import "./libs/DefaultOperatorFilterer.sol";

contract CNPReborn is
    ICNPReborn,
    DefaultOperatorFilterer,
    ERC721AntiScam,
    ERC2981,
    AccessControl,
    ERC721MultiSaleByMerkleMultiWallet
{
    // ==================================================================
    // Constants
    // ==================================================================
    bytes32 public constant ADMIN = "ADMIN";

    // ==================================================================
    // Variables
    // ==================================================================
    // == For Creator fee ==
    uint96 public royaltyFee = 1000;

    // == For time lock ==
    // tokenId -> unlock time
    mapping(uint256 => uint256) unlockTokenTimestamp;
    // wallet -> unlock time
    mapping(address => uint256) unlockWalletTimestamp;
    uint256 public unlockLeadTime = 3 hours;

    // == For Grow ==
    // tokenId -> period
    mapping(uint256 => uint256) private _growthPeriodToChild;
    mapping(uint256 => uint256) private _growthPeriodToAdult;

    // tokenId -> date
    mapping(uint256 => uint256) public birthDay;

    uint256 public standardPeriodToChild = 42 days;
    uint256 public standardPeriodToAdult = 76 days;
    // 100% => 1000
    uint256 public maxVariation = 50;

    // == For cooldown time
    // tokenId -> day
    mapping(uint256 => uint256) private lastTransferOrGimmickDay;
    uint256 public cooldownTime = 14 days;

    ICNPRebornGimmick private _gimmick;
    ITokenUriSupplier private _tokenUriSupplier;

    constructor(address ownerAddress, uint256 ownerMintAmount)
        ERC721Psi("CNP Reborn", "CNPReborn")
    {
        grantRole(ADMIN, msg.sender);

        withdrawAddress = payable(ownerAddress);
        _setDefaultRoyalty(withdrawAddress, royaltyFee);

        // bacause of Psi start with 0
        _safeMint(msg.sender, 1);
        _burn(0);

        _birthWithSleeping(ownerAddress, ownerMintAmount);
    }

    // ==================================================================
    // original
    // ==================================================================
    function _setBirthDay(uint256 tokenId) private {
        birthDay[tokenId] = block.timestamp;
    }

    function _getVariation(uint256 tokenId) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(block.number - 1), tokenId)
                )
            ) % maxVariation;
    }

    function _decideGrowthPeriod(uint256 tokenId) private {
        _growthPeriodToChild[tokenId] =
            standardPeriodToChild +
            ((standardPeriodToChild * _getVariation(tokenId)) / 1000);
        _growthPeriodToAdult[tokenId] =
            standardPeriodToAdult +
            ((standardPeriodToAdult * _getVariation(tokenId)) / 1000);
    }

    function _birthWithSleeping(address to, uint256 amount) private {
        uint256 startTokenId = _nextTokenId();

        _safeMint(to, amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = startTokenId + i;
            birthDay[tokenId] = 0;
            _decideGrowthPeriod(tokenId);
        }
    }

    function _birth(address to, uint256 amount) private {
        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _nextTokenId() + i;
            _setBirthDay(tokenId);
            _decideGrowthPeriod(tokenId);
        }
        _safeMint(to, amount);
    }

    function adminMint(
        address[] calldata to,
        uint256[] calldata amount,
        bool withSleep
    ) external onlyRole(ADMIN) {
        require(to.length == amount.length);
        for (uint256 i = 0; i < to.length; i++) {
            if (withSleep) {
                _birthWithSleeping(to[i], amount[i]);
            } else {
                _birth(to[i], amount[i]);
            }
        }
    }

    function _burn(address from, uint256[] memory burnTokenIds) internal {
        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            uint256 tokenId = burnTokenIds[i];
            require(from == ownerOf(tokenId), "only holder.");
            _burn(tokenId);
        }
    }

    function isAdult(uint256 tokenId) public view returns (bool) {
        if (birthDay[tokenId] == 0) {
            return false;
        }

        return
            birthDay[tokenId] + _growthPeriodToAdult[tokenId] <=
            block.timestamp;
    }

    function isChild(uint256 tokenId) public view returns (bool) {
        if (birthDay[tokenId] == 0) {
            return false;
        }

        return
            birthDay[tokenId] + _growthPeriodToChild[tokenId] <=
            block.timestamp;
    }

    function inCoolDownTime(uint256 tokenId) public view returns (bool) {
        return
            isAdult(tokenId) &&
            (lastTransferOrGimmickDay[tokenId] + cooldownTime >
                block.timestamp);
    }

    function totalBurned() external view returns (uint256) {
        return _burned();
    }

    function nextTokenId() external view returns (uint256) {
        return _nextTokenId();
    }

    function setStandardPeriodToChild(uint256 period) external onlyRole(ADMIN) {
        standardPeriodToChild = period;
    }

    function setStandardPeriodToAdult(uint256 period) external onlyRole(ADMIN) {
        standardPeriodToAdult = period;
    }

    function setCoolDownTime(uint256 period) external onlyRole(ADMIN) {
        cooldownTime = period;
    }

    function setMaxVariation(uint256 value) external onlyRole(ADMIN) {
        maxVariation = value;
    }

    function playGimmick(uint256 tokenId) external {
        require(msg.sender == address(_gimmick), "only call from gimmick.");
        lastTransferOrGimmickDay[tokenId] = block.timestamp;
    }

    // == For gimmick of Reborn
    function reborn(
        ICNPRebornGimmick.Parents[] calldata parents,
        uint256[] calldata couponIds
    ) external payable {
        _gimmick.reborn{value: msg.value}(msg.sender, parents, couponIds);

        for (uint256 i = 0; i < parents.length; i++) {
            _burn(parents[i].parent1);
            _burn(parents[i].parent2);
            _birth(msg.sender, 2);
        }
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        lastTransferOrGimmickDay[startTokenId] = block.timestamp;

        if (birthDay[startTokenId] == 0) {
            birthDay[startTokenId] = block.timestamp;
        }
        _afterTokenTransfersForAddressData(from, to, startTokenId, quantity);
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }

    // ==================================================================
    // Queriable
    // ==================================================================
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view virtual returns (uint256[] memory) {
        unchecked {
            require(start < stop, "start must be greater than stop.");
            uint256 tokenIdsIdx;
            uint256 stopLimit = _nextTokenId();
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, stopLimit)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }

            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }

            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }

            for (
                uint256 i = start;
                i != stop && tokenIdsIdx != tokenIdsMaxLength;
                ++i
            ) {
                if (_exists(i)) {
                    if (ownerOf(i) == owner) {
                        tokenIds[tokenIdsIdx++] = i;
                    }
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    // ==================================================================
    // overrive ERC721Psi for operator-filter-registry
    // ==================================================================
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
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
        require(_exists(tokenId), "not exists.");
        return _tokenUriSupplier.tokenURI(tokenId);
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

    function getLocalContractAllowList()
        external
        view
        returns (address[] memory)
    {
        return _getLocalContractAllowList();
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

        if (
            walletLock[to] == LockStatus.Lock && lockStatus != LockStatus.Lock
        ) {
            unlockWalletTimestamp[to] = block.timestamp;
        }

        _setWalletLock(to, lockStatus);
    }

    function setTokenLock(uint256[] calldata tokenIds, LockStatus lockStatus)
        external
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(msg.sender == ownerOf(tokenIds[i]), "not owner.");
        }

        LockStatus currentWalletLock = walletLock[msg.sender];

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (
                (currentWalletLock == LockStatus.Lock &&
                    tokenLock[tokenIds[i]] != LockStatus.UnLock &&
                    lockStatus == LockStatus.UnLock) ||
                (currentWalletLock != LockStatus.Lock &&
                    tokenLock[tokenIds[i]] == LockStatus.Lock &&
                    lockStatus == LockStatus.UnLock)
            ) {
                unlockTokenTimestamp[tokenIds[i]] = block.timestamp;
            }
        }
        _setTokenLock(tokenIds, lockStatus);
    }

    function setEnableLock(bool value) external onlyRole(ADMIN) {
        enableLock = value;
    }

    function isLocked(uint256 tokenId)
        public
        view
        override(IERC721Lockable, ERC721Lockable)
        returns (bool)
    {
        return
            ERC721Lockable.isLocked(tokenId) ||
            (unlockTokenTimestamp[tokenId] + unlockLeadTime >
                block.timestamp) ||
            (unlockWalletTimestamp[ownerOf(tokenId)] + unlockLeadTime >
                block.timestamp);
    }

    function setUnlockLeadTime(uint256 value) external onlyRole(ADMIN) {
        unlockLeadTime = value;
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

    // ==================================================================
    // interface
    // ==================================================================
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721AntiScam, ERC2981)
        returns (bool)
    {
        return
            ERC721Psi.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId) ||
            ERC721AntiScam.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    // ==================================================================
    // override ERC721MultiSaleByMerkleMultWallet For gimmick
    // ==================================================================
    // == For sale ==
    function claim(
        uint256 userId,
        uint256 amount,
        uint256 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable enoughEth(amount) {
        _claim(userId, amount, allowedAmount, merkleProof);
        _birth(msg.sender, amount);
    }

    function exchange(
        uint256, /*userId*/
        uint256[] calldata, /*burnTokenIds*/
        uint256, /*allowedAmount*/
        bytes32[] calldata /*merkleProof*/
    ) external payable override {
        revert();
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
        _setDefaultRoyalty(withdrawAddress, royaltyFee);
    }

    function setMaxSupply(uint256 value) external onlyRole(ADMIN) {
        maxSupply = value;
    }

    function _totalSupply() internal view override returns (uint256) {
        return totalSupply();
    }

    // ==================================================================
    // For IERC2981 NFT Royalty Standard
    // ==================================================================
    function setRoyaltyFee(uint96 value) external onlyRole(ADMIN) {
        royaltyFee = value;
        _setDefaultRoyalty(withdrawAddress, royaltyFee);
    }

    // ==================================================================
    // Operation outer contract
    // ==================================================================
    function setGimmick(address value) external onlyRole(ADMIN) {
        _gimmick = ICNPRebornGimmick(value);
    }

    function setTokenUriSupplier(address value) external onlyRole(ADMIN) {
        _tokenUriSupplier = ITokenUriSupplier(value);
    }

    // ==================================================================
    // ERC721PsiAddressData
    // ==================================================================
    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721Psi: balance query for the zero address"
        );
        return uint256(_addressData[owner].balance);
    }

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfersForAddressData(
        address from,
        address to,
        uint256, /*startTokenId*/
        uint256 quantity
    ) internal virtual {
        require(quantity < 2**64);
        uint64 _quantity = uint64(quantity);

        if (from != address(0)) {
            _addressData[from].balance -= _quantity;
        } else {
            // Mint
            _addressData[to].numberMinted += _quantity;
        }

        if (to != address(0)) {
            _addressData[to].balance += _quantity;
        } else {
            // Burn
            _addressData[from].numberBurned += _quantity;
        }
    }
}