// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./MultiStage.sol";
import "./SignaturePresale.sol";
import "./interfaces/IDropKitPass.sol";

contract DropKitPass is
    IDropKitPass,
    MultiStage,
    SignaturePresale,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ERC2981Upgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using MerkleProofUpgradeable for bytes32[];
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint96 private _defaultFeeRate;
    address private _treasury;
    string private _tokenBaseURI;

    mapping(uint256 => uint256) private _stagesByToken;
    mapping(uint256 => FeeEntry) private _feeRatesByToken;
    mapping(address => FeeEntry) private _lowestFeeRatesByOwner;
    mapping(address => mapping(uint96 => uint256))
        private _feeRatesCountByOwner;
    mapping(address => EnumerableSetUpgradeable.UintSet)
        private _feeRatesSetByOwner;

    // passes per stage
    mapping(uint256 => mapping(uint96 => PricingEntry))
        private _passesForSaleByStage;

    modifier onlyPurchasable(
        uint256 stageId,
        uint64 quantity,
        address to
    ) {
        uint256 maxAmount = _maxAmount[stageId];
        require(_saleActive[stageId], "Sale not active");
        require(quantity > 0, "Quantity is 0");
        require(
            maxAmount > 0 ? _supply[stageId].add(quantity) <= maxAmount : true,
            "Exceeded max supply"
        );
        require(quantity <= _maxPerMint[stageId], "Exceeded max per mint");
        require(
            _mintCount[stageId][to].add(quantity) <= _maxPerWallet[stageId],
            "Exceeded max per wallet"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address treasury_,
        address royalty_,
        uint96 royaltyFee_,
        uint96 defaultFeeRate_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721Enumerable_init();
        __AccessControl_init();
        __Ownable_init();
        __ERC2981_init();

        _treasury = treasury_;
        _defaultFeeRate = defaultFeeRate_;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(royalty_, royaltyFee_);
    }

    function purchasePass(
        uint256 stageId,
        uint96 feeRate,
        uint64 quantity,
        address recipient
    ) external payable onlyPurchasable(stageId, quantity, recipient) {
        require(!_presaleActive[stageId], "Presale active");

        _purchasePass(stageId, feeRate, recipient, quantity);

        emit PassOptionPurchased(stageId, feeRate);
    }

    function presalePurchasePass(
        uint256 stageId,
        uint96 feeRate,
        uint64 quantity,
        uint64 allowed,
        address recipient,
        bytes32[] calldata proof
    ) external payable onlyPurchasable(stageId, quantity, recipient) {
        bytes32 merkleRoot = _merkleRoot[stageId];
        require(_presaleActive[stageId], "Presale not active");
        require(merkleRoot != "", "Presale not set");
        require(
            MerkleProofUpgradeable.verify(
                proof,
                merkleRoot,
                keccak256(abi.encodePacked(recipient, allowed))
            ),
            "Presale invalid"
        );

        _purchasePass(stageId, feeRate, recipient, quantity);

        emit PassOptionPurchased(stageId, feeRate);
    }

    function redeemPass(
        uint256 stageId,
        uint96 feeRate,
        uint64 quantity,
        address recipient,
        uint256 expiration,
        bytes32 data,
        bytes calldata signature
    ) external payable onlyPurchasable(stageId, quantity, recipient) {
        require(_presaleActive[stageId], "Presale not active");

        _verifySignature(stageId, expiration, data, signature);
        _purchasePass(stageId, feeRate, recipient, quantity);

        emit PassOptionRedeemed(stageId, feeRate, data);
    }

    function batchAirdrop(
        uint256 stageId,
        address[] calldata recipients,
        uint96[] calldata feeRates
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            recipients.length == feeRates.length,
            "Invalid number of recipients"
        );

        uint256 length = recipients.length;
        for (uint256 i = 0; i < length; ) {
            require(
                _passesForSaleByStage[stageId][feeRates[i]].isValue,
                "Pass doesn't exist"
            );
            _mintPass(stageId, feeRates[i], recipients[i]);
            unchecked {
                i++;
            }
        }
    }

    function createPassOption(
        uint256 stageId,
        uint96 feeRate,
        uint256 price
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            !_passesForSaleByStage[stageId][feeRate].isValue,
            "Pass already exists"
        );
        _passesForSaleByStage[stageId][feeRate] = PricingEntry({
            price: price,
            isValue: true
        });

        emit PassOptionCreated(stageId, feeRate, price);
    }

    function updatePassOption(
        uint256 stageId,
        uint96 feeRate,
        uint256 newPrice,
        bool active
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _passesForSaleByStage[stageId][feeRate].isValue = active;
        _passesForSaleByStage[stageId][feeRate].price = newPrice;

        emit PassOptionUpdated(stageId, feeRate, newPrice, active);
    }

    function startSale(
        uint256 stageId,
        uint256 newMaxAmount,
        uint256 newMaxPerWallet,
        uint256 newMaxPerMint,
        bool presale
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_saleActive[stageId], "Sale already active");
        _startSale(
            stageId,
            newMaxAmount,
            newMaxPerWallet,
            newMaxPerMint,
            presale
        );

        emit SaleStarted(
            stageId,
            newMaxAmount,
            newMaxPerWallet,
            newMaxPerMint,
            presale
        );
    }

    function stopSale(uint256 stageId) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_saleActive[stageId], "Sale not active");
        _stopSale(stageId);

        emit SaleStopped(stageId);
    }

    function setMerkleRoot(uint256 stageId, bytes32 newRoot)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setMerkleRoot(stageId, newRoot);
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(this).balance > 0, "0 balance");

        uint256 balance = address(this).balance;
        AddressUpgradeable.sendValue(payable(_treasury), balance);
    }

    function setSigner(address signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setSigner(signer);
    }

    function setTreasury(address newTreasury)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _treasury = newTreasury;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function setStageRoyalty(
        uint256 stageId,
        address receiver,
        uint96 feeNumerator,
        bool active
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setStageRoyalty(stageId, receiver, feeNumerator, active);
    }

    function setDefaultFeeRate(uint96 feeRate)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _defaultFeeRate = feeRate;
    }

    function setBaseURI(string memory newBaseURI)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokenBaseURI = newBaseURI;
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function isRedeemed(uint256 stageId, bytes32 data)
        public
        view
        returns (bool)
    {
        return _isVerified(stageId, data);
    }

    function getPrice(uint256 stageId, uint96 feeRate)
        public
        view
        returns (uint256)
    {
        PricingEntry memory pass = _passesForSaleByStage[stageId][feeRate];
        require(pass.isValue, "Pass doesn't exist");
        return pass.price;
    }

    function getStage(uint256 tokenId) public view returns (uint256) {
        return _stagesByToken[tokenId];
    }

    function getFeeRate(uint256 tokenId) public view returns (uint96) {
        require(_feeRatesByToken[tokenId].isValue, "Invalid tokenId");
        return _feeRatesByToken[tokenId].value;
    }

    function getFeeRateOf(address owner) external view returns (uint96) {
        FeeEntry memory ownerRate = _lowestFeeRatesByOwner[owner];
        if (ownerRate.isValue) {
            return ownerRate.value;
        }

        return _defaultFeeRate;
    }

    function getDefaultFeeRate() external view returns (uint96) {
        return _defaultFeeRate;
    }

    function _purchasePass(
        uint256 stageId,
        uint96 feeRate,
        address to,
        uint64 quantity
    ) internal {
        require(
            _passesForSaleByStage[stageId][feeRate].isValue,
            "Pass doesn't exist"
        );
        require(
            _passesForSaleByStage[stageId][feeRate].price.mul(quantity) <=
                msg.value,
            "Value incorrect"
        );
        for (uint256 i = 0; i < quantity; ) {
            _mintPass(stageId, feeRate, to);
            unchecked {
                i++;
            }
        }
    }

    function _mintPass(
        uint256 stageId,
        uint96 feeRate,
        address to
    ) internal {
        uint256 mintIndex = totalSupply().add(1);
        _feeRatesByToken[mintIndex] = _feeValue(feeRate, true);
        _stagesByToken[mintIndex] = stageId;
        unchecked {
            _supply[stageId]++;
            _mintCount[stageId][to]++;
        }
        RoyaltyEntry memory royalty = _royalty[stageId];
        if (royalty.isValue) {
            _setTokenRoyalty(mintIndex, royalty.receiver, royalty.feeNumerator);
        }
        _safeMint(to, mintIndex);
    }

    function _feeValue(uint96 feeRate, bool isValue)
        internal
        pure
        returns (FeeEntry memory)
    {
        return FeeEntry(feeRate, isValue);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _tokenBaseURI;
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        uint96 feeRate = getFeeRate(tokenId);
        FeeEntry memory newOwnerRate = _lowestFeeRatesByOwner[to];

        // if the owner is a new recipient
        if (!newOwnerRate.isValue) {
            _lowestFeeRatesByOwner[to] = _feeValue(feeRate, true);
        }

        // if the recipient is already a holder, and new fee is lower
        if (newOwnerRate.isValue && feeRate < newOwnerRate.value) {
            _lowestFeeRatesByOwner[to].value = feeRate;
        }

        // add new fees to the new owner set
        _feeRatesSetByOwner[to].add(feeRate);

        // update holder count
        unchecked {
            _feeRatesCountByOwner[to][feeRate]++;
            _feeRatesCountByOwner[from][feeRate]--;
        }

        // if the sender no longer holds the fee
        if (_feeRatesCountByOwner[from][feeRate] == 0) {
            // remove fees from set
            _feeRatesSetByOwner[from].remove(feeRate);

            // check if there's other fees held by owner
            uint256 feesCount = _feeRatesSetByOwner[from].length();
            if (feesCount > 0) {
                // find the lowest fee available
                uint96 lowestFee = type(uint96).max;
                for (uint256 i = 0; i < feesCount; ) {
                    unchecked {
                        lowestFee = uint96(
                            MathUpgradeable.min(
                                _feeRatesSetByOwner[from].at(i),
                                lowestFee
                            )
                        );
                        i++;
                    }
                }
                // assign lowest fee by owner
                _lowestFeeRatesByOwner[from].value = lowestFee;
            } else {
                // holder no longer carries any passes
                _lowestFeeRatesByOwner[from] = _feeValue(0, false);
            }
        }

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC2981Upgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}