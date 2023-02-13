// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "hardhat/console.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "operator-filter-registry/src/upgradeable/DefaultOperatorFiltererUpgradeable.sol";

import "./lib/OnlyDevMultiSigUpgradeable.sol";

error SetDevMultiSigToZeroAddress();
error InvalidQueryRange();
error NotTokenOwner();

contract LoveOrdinals is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    OnlyDevMultiSigUpgradeable,
    ERC721AUpgradeable,
    DefaultOperatorFiltererUpgradeable,
    ERC2981Upgradeable
{
    using ECDSAUpgradeable for bytes32;
    using StringsUpgradeable for uint256;

    event NFTMinted(address _owner, uint256 amount, uint256 startTokenId);
    event SaleStatusChange(uint256 indexed saleId, bool enabled);

    string private baseURI;

    address internal _devMultiSigWallet;

    uint256 public MAX_SUPPLY; // total supply
    uint256 public DEV_RESERVE; // total dev will reserve

    uint256 constant PUBLIC_SALE_ID = 0; // public sale

    struct PuclicSaleConfigCreate {
        uint8 maxPerTransaction;
        uint64 unitPrice;
    }

    struct SaleConfig {
        bool enabled;
        uint8 maxPerWallet;
        uint8 maxPerTransaction;
        uint64 unitPrice;
        address signerAddress;
        uint256 maxPerRound;
    }
    mapping(uint256 => SaleConfig) private _saleConfig;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        address devMultiSigWallet_,
        uint96 royalty_,
        PuclicSaleConfigCreate calldata publicSaleConfig
    ) public initializerERC721A initializer {
        MAX_SUPPLY = 333; // total supply
        DEV_RESERVE = 333; // total supply

        __OnlyDevMultiSig_init(devMultiSigWallet_);
        __ERC721A_init(_name, _symbol);
        __ERC2981_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __DefaultOperatorFilterer_init();

        _devMultiSigWallet = devMultiSigWallet_;
        setBaseURI(_initBaseURI);
        _setDefaultRoyalty(devMultiSigWallet_, royalty_);

        setPublicSaleConfig(
            publicSaleConfig.maxPerTransaction,
            publicSaleConfig.unitPrice
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721AUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721AUpgradeable.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNewSupply(uint256 _newMaxSupply) public onlyOwner {
        MAX_SUPPLY = _newMaxSupply;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "NOT_EXISTS");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function explicitOwnershipOf(uint256 tokenId)
        public
        view
        returns (TokenOwnership memory)
    {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _nextTokenId()) {
            return ownership;
        }
        ownership = _ownershipAt(tokenId);
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds)
        external
        view
        returns (TokenOwnership[] memory)
    {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](
                tokenIdsLength
            );
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
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
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (
                uint256 i = start;
                i != stop && tokenIdsIdx != tokenIdsMaxLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (
                uint256 i = _startTokenId();
                tokenIdsIdx != tokenIdsLength;
                ++i
            ) {
                ownership = _ownershipAt(i);
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }

    /* 
        BACK OFFICE
    */
    function setDevMultiSigAddress(address payable _address)
        external
        onlyDevMultiSig
    {
        if (_address == address(0)) revert SetDevMultiSigToZeroAddress();
        _devMultiSigWallet = _address;
        updateDevMultiSigWallet(_address);
    }

    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints)
        external
        onlyDevMultiSig
    {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    function withdrawTokensToDev(IERC20Upgradeable token)
        public
        onlyDevMultiSig
    {
        uint256 funds = token.balanceOf(address(this));
        require(funds > 0, "No token left");
        token.transfer(address(_devMultiSigWallet), funds);
    }

    function withdrawETHBalanceToDev() public onlyDevMultiSig {
        require(address(this).balance > 0, "No ETH left");

        (bool success, ) = address(_devMultiSigWallet).call{
            value: address(this).balance
        }("");

        require(success, "Transfer failed.");
    }

    function burnMany(uint256[] memory tokenIds) public nonReentrant {
        uint256 n = tokenIds.length;
        for (uint256 i = 0; i < n; ++i) {
            address to = ownerOf(tokenIds[i]);
            if (to != _msgSenderERC721A()) {
                revert NotTokenOwner();
            }

            _burn(tokenIds[i], true);
        }
    }

    /* 
        MINT
    */
    modifier canMint(
        uint256 saleId,
        address to,
        uint256 amount
    ) {
        _guardMint(to, amount);
        unchecked {
            SaleConfig memory saleConfig = _saleConfig[saleId];
            require(saleConfig.enabled, "Sale not enabled");
            require(
                amount <= saleConfig.maxPerTransaction,
                "Exceeds max per transaction"
            );
            require(
                msg.value >= (amount * saleConfig.unitPrice),
                "ETH amount is not sufficient"
            );
            if (saleId > 0) {
                require(
                    saleConfig.maxPerRound - amount >= 0,
                    "Exceeds max per round"
                );
            }
        }
        _;
    }

    function _guardMint(address, uint256 quantity) internal view virtual {
        unchecked {
            require(
                tx.origin == _msgSenderERC721A(),
                "Can't mint from contract"
            );
            require(
                totalSupply() + quantity <= MAX_SUPPLY,
                "Exceeds max supply"
            );
        }
    }

    function devMint(uint256 amount) external onlyOwner {
        require(amount <= DEV_RESERVE, "The quantity exceeds the reserve.");
        uint256 startTokenId = _nextTokenId();
        _guardMint(_msgSenderERC721A(), amount);
        _safeMint(_devMultiSigWallet, amount);

        DEV_RESERVE -= amount;

        emit NFTMinted(_devMultiSigWallet, amount, startTokenId);
    }

    function devMintTo(uint256 amount, address to) external onlyOwner {
        require(amount <= DEV_RESERVE, "The quantity exceeds the reserve.");
        uint256 startTokenId = _nextTokenId();
        _guardMint(_msgSenderERC721A(), amount);
        _safeMint(to, amount);

        DEV_RESERVE -= amount;

        emit NFTMinted(to, amount, startTokenId);
    }

    function publicMint(uint256 amount)
        external
        payable
        canMint(PUBLIC_SALE_ID, _msgSenderERC721A(), amount)
    {
        uint256 startTokenId = _nextTokenId();
        _safeMint(_msgSenderERC721A(), amount);

        emit NFTMinted(_msgSenderERC721A(), amount, startTokenId);
    }

    function getPublicSaleConfig() external view returns (SaleConfig memory) {
        return _saleConfig[PUBLIC_SALE_ID];
    }

    function setPublicSaleConfig(uint256 maxPerTransaction, uint256 unitPrice)
        public
        onlyOwner
    {
        _saleConfig[PUBLIC_SALE_ID].maxPerTransaction = uint8(
            maxPerTransaction
        );
        _saleConfig[PUBLIC_SALE_ID].unitPrice = uint64(unitPrice);
    }

    function setPublicSaleStatus(bool enabled) external onlyOwner {
        if (_saleConfig[PUBLIC_SALE_ID].enabled != enabled) {
            _saleConfig[PUBLIC_SALE_ID].enabled = enabled;
            emit SaleStatusChange(PUBLIC_SALE_ID, enabled);
        }
    }
}