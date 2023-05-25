// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import "./defualt-contract/TokenUriSupplier.sol";
import "contract-allow-list/contracts/ERC721AntiScam/ERC721AntiScam.sol";
import "erc721-multi-sales/contracts/single-wallet/merkletree/ERC721MultiSaleByMerkle.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract CryptoNinjaChildren is
    AccessControl,
    Ownable,
    RevokableDefaultOperatorFilterer,
    ERC721MultiSaleByMerkle,
    ERC2981,
    TokenUriSupplier,
    ERC721AntiScam
{
    using Strings for uint256;
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

    // ==================================================================
    // Constractor
    // ==================================================================
    constructor() ERC721Psi("CryptoNinja Children", "CNC") {
        grantRole(ADMIN, msg.sender);
    }

    // ==================================================================
    // Queriable
    // ==================================================================
    function tokensOfOwnerIn(
        address _owner,
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

            uint256 tokenIdsMaxLength = balanceOf(_owner);
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
                    if (ownerOf(i) == _owner) {
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

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    // ==================================================================
    // override ERC721
    // ==================================================================
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721Psi, TokenUriSupplier)
        returns (string memory)
    {
        return TokenUriSupplier.tokenURI(tokenId);
    }

    function _defaultTokenUri(uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    tokenId.toString(),
                    isLocked(tokenId) ? "_lock" : "",
                    baseExtension
                )
            );
    }

    function setBaseURI(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseURI = _value;
    }

    function setBaseExtension(string memory _value)
        external
        override
        onlyRole(ADMIN)
    {
        baseExtension = _value;
    }

    function setExternalSupplier(address _value)
        external
        override
        onlyRole(ADMIN)
    {
        externalSupplier = ITokenUriSupplier(_value);
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
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

    function _isTokenLockToUnlock(uint256 tokenId, LockStatus newLockStatus)
        private
        view
        returns (bool)
    {
        if (newLockStatus == LockStatus.UnLock) {
            LockStatus currentWalletLock = walletLock[msg.sender];
            bool isWalletLock_TokenLockOrUnset = (currentWalletLock ==
                LockStatus.Lock &&
                tokenLock[tokenId] != LockStatus.UnLock);
            bool isWalletUnlockOrUnset_TokenLock = (currentWalletLock !=
                LockStatus.Lock &&
                tokenLock[tokenId] == LockStatus.Lock);

            return
                isWalletLock_TokenLockOrUnset ||
                isWalletUnlockOrUnset_TokenLock;
        } else if (newLockStatus == LockStatus.UnSet) {
            LockStatus currentWalletLock = walletLock[msg.sender];
            bool isNotWalletLock = currentWalletLock != LockStatus.Lock;
            bool isTokenLock = tokenLock[tokenId] == LockStatus.Lock;

            return isNotWalletLock && isTokenLock;
        } else {
            return false;
        }
    }

    function setTokenLock(uint256[] calldata tokenIds, LockStatus newLockStatus)
        external
    {
        require(tokenIds.length > 0, "tokenIds must be greater than 0.");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(msg.sender == ownerOf(tokenIds[i]), "not owner.");
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_isTokenLockToUnlock(tokenIds[i], newLockStatus)) {
                unlockTokenTimestamp[tokenIds[i]] = block.timestamp;
            }
        }
        _setTokenLock(tokenIds, newLockStatus);
    }

    function setEnableLock(bool value) external onlyRole(ADMIN) {
        enableLock = value;
    }

    function _isTokenTimeLock(uint256 tokenId) private view returns (bool) {
        return unlockTokenTimestamp[tokenId] + unlockLeadTime > block.timestamp;
    }

    function _isWalletTimeLock(uint256 tokenId) private view returns (bool) {
        return
            unlockWalletTimestamp[ownerOf(tokenId)] + unlockLeadTime >
            block.timestamp;
    }

    function isLocked(uint256 tokenId)
        public
        view
        override(IERC721Lockable, ERC721Lockable)
        returns (bool)
    {
        return
            ERC721Lockable.isLocked(tokenId) ||
            _isTokenTimeLock(tokenId) ||
            _isWalletTimeLock(tokenId);
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
    // override ERC721MultiSaleByMerkle
    // ==================================================================
    function adminMint(address[] calldata to, uint256[] calldata amount)
        external
        onlyRole(ADMIN)
    {
        require(to.length == amount.length);
        for (uint256 i = 0; i < to.length; i++) {
            require(
                amount[i] + _totalSupply() <= maxSupply,
                "claim is over the max supply."
            );
            _safeMint(to[i], amount[i]);
        }
    }

    // == For sale ==
    function claim(
        uint248 amount,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable override enoughEth(amount) {
        _claim(amount, allowedAmount, merkleProof);
        _safeMint(msg.sender, amount);
    }

    function exchange(
        uint256[] calldata burnTokenIds,
        uint248 allowedAmount,
        bytes32[] calldata merkleProof
    ) external payable override enoughEth(burnTokenIds.length) {
        _exchange(burnTokenIds, allowedAmount, merkleProof);

        for (uint256 i = 0; i < burnTokenIds.length; i++) {
            _burn(burnTokenIds[i]);
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

    function withdraw() external payable onlyRole(ADMIN) {
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
    // Override Ownerble for fail safe
    // ==================================================================
    function renounceOwnership() public view override onlyOwner {
        revert("Can not renounceOwnership. In the absence of the Owner, the system will not be operational.");
    }

    // ==================================================================
    // For IERC2981 NFT Royalty Standard
    // ==================================================================
    function setRoyaltyFee(uint96 value) external onlyRole(ADMIN) {
        royaltyFee = value;
        _setDefaultRoyalty(withdrawAddress, royaltyFee);
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
    function balanceOf(address _owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            _owner != address(0),
            "ERC721Psi: balance query for the zero address"
        );
        return uint256(_addressData[_owner].balance);
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

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        _afterTokenTransfersForAddressData(from, to, startTokenId, quantity);
        super._afterTokenTransfers(from, to, startTokenId, quantity);
    }
}