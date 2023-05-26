//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IStorefront.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Contract that is expected to be implemented by any storefront implementation
 * @author Ohimire Labs
 */
abstract contract AbstractStorefront is IStorefront, AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    /**
     * @notice Denotes the purchaser type (of 3 categories that modify purchase behaviour)
     */
    enum PurchaserType {
        general,
        artist,
        platform
    }

    /**
     * @notice A mapping from sale ids to whitelisted addresses to amount of pre-sale units purchased
     */
    mapping(uint256 => mapping(address => uint32)) public whitelistedPurchases;

    /**
     * @notice Platform administrative account
     */
    address public platform;

    /**
     * @notice Platform minter
     */
    address public minterAddress;

    /**
     * @notice The number of sales on the storefront
     */
    uint256 public numSales;

    /**
     * @notice Holders of this role can execute operations requiring elevated authorization
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Track sales
     */
    mapping(uint256 => Sale) internal _sales;

    /**
     * @notice Tracks failed transfers of native gas token
     */
    mapping(address => uint256) private _failedTransferCredits;

    /**
     * @notice Reverts if caller is not authority for sale
     * @param tokenContract Token contract of sale
     */
    modifier onlyTokenContractAuthority(address tokenContract) {
        require(msg.sender == tokenContract || hasRole(MINTER_ROLE, msg.sender), "!authorized");
        _;
    }

    /**
     * @notice Checks if primary sale fee info is valid
     * @param feeInfo Primary sale fee info
     */
    modifier isPrimaryFeeInfoValid(PrimaryFeeInfo memory feeInfo) {
        require(_isPrimaryFeeInfoValid(feeInfo), "Fee invo invalid");
        _;
    }

    /**
     * @notice Checks if sale is still valid, given the sale end timestamp
     * @param _saleEndTimestamp Sale end timestamp
     */
    modifier isSaleEndTimestampCurrentlyValid(uint128 _saleEndTimestamp) {
        require(_isSaleEndTimestampCurrentlyValid(_saleEndTimestamp), "ended");
        _;
    }

    /**
     * @notice See {IStorefront-createSale}
     */
    function createSale(
        Sale calldata sale
    )
        external
        override
        onlyTokenContractAuthority(sale.tokenContract)
        isSaleEndTimestampCurrentlyValid(sale.saleEndTimestamp)
        isPrimaryFeeInfoValid(sale.primaryFee)
    {
        require(sale.saleState != SaleState.paused, "initial sale state invalid");
        uint256 saleId = numSales + 1;
        _sales[saleId] = sale;
        numSales = saleId;
        emit SaleCreated(saleId, sale.packId, sale.tokenContract);
    }

    /**
     * @notice See {IStorefront-updateSale}
     */
    function updateSale(
        uint256 saleId,
        uint64 maxPurchaseAmount,
        uint128 saleEndTimestamp,
        uint128 price,
        address erc20Token,
        bytes32 merkleroot,
        PrimaryFeeInfo calldata primaryFee,
        uint256 mintAmountArtist,
        uint256 mintAmountPlatform
    )
        external
        override
        onlyTokenContractAuthority(_sales[saleId].tokenContract)
        isSaleEndTimestampCurrentlyValid(saleEndTimestamp)
        isPrimaryFeeInfoValid(primaryFee)
    {
        // read result into memory
        Sale memory sale = _sales[saleId];
        sale.maxPurchaseAmount = maxPurchaseAmount;
        sale.saleEndTimestamp = saleEndTimestamp;
        sale.price = price;
        sale.erc20Token = erc20Token;
        sale.merkleroot = merkleroot;
        sale.primaryFee = primaryFee;
        sale.mintAmountArtist = mintAmountArtist;
        sale.mintAmountPlatform = mintAmountPlatform;
        // writeback result
        _sales[saleId] = sale;
    }

    /**
     * @notice See {IStorefront-updateSaleState}
     */
    function updateSaleState(
        uint256 saleId,
        SaleState saleState
    ) external override onlyTokenContractAuthority(_sales[saleId].tokenContract) {
        require(_isSaleStateUpdateValid(_sales[saleId].saleState, saleState, saleId), "invalid salestate update");
        _sales[saleId].saleState = saleState;
    }

    /**
     * @notice See {IStorefront-updatePrimaryFee}
     */
    function updatePrimaryFee(
        uint256 saleId,
        PrimaryFeeInfo calldata primaryFee
    ) external override onlyTokenContractAuthority(_sales[saleId].tokenContract) isPrimaryFeeInfoValid(primaryFee) {
        _sales[saleId].primaryFee = primaryFee;
    }

    /**
     * @notice See {IStorefront-updateMerkleroot}
     */
    function updateMerkleroot(
        uint256 saleId,
        bytes32 _newMerkleroot
    ) external override onlyTokenContractAuthority(_sales[saleId].tokenContract) {
        _sales[saleId].merkleroot = _newMerkleroot;
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    /**
     * @notice See {IStorefront-updatePlatformAddress}
     */
    function updatePlatformAddress(address _platform) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @notice See {IStorfront-withdrawAllFailedCredits}
     */
    function withdrawAllFailedCredits(address payable recipient) external override {
        uint256 amount = _failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        _failedTransferCredits[msg.sender] = 0;

        /* solhint-disable avoid-low-level-calls */
        (bool successfulWithdraw, ) = recipient.call{ value: amount, gas: 20000 }("");
        /* solhint-enable avoid-low-level-calls */
        require(successfulWithdraw, "withdraw failed");
    }

    /**
     * @notice See {IStorefront-getSale}
     */
    function getSale(uint256 saleId) external view override returns (Sale memory) {
        return _sales[saleId];
    }

    /**
     * @notice Initialize instance
     * @param _platform Platform address
     * @param _minter Minter address
     */
    function __AbstractStorefront_init__(address _platform, address _minter) internal onlyInitializing {
        // Initialize parent contracts
        AccessControlUpgradeable.__AccessControl_init();

        // Setup a default admin
        _setupRole(DEFAULT_ADMIN_ROLE, _platform);
        platform = _platform;

        // Setup auth role
        _setupRole(MINTER_ROLE, _minter);
        minterAddress = _minter;

        numSales = 0;
    }

    /**
     * @notice Pay primary fees owed to primary fee recipients
     * @param _sale Sale
     * @param _purchaseQuantity How many purchases on the sale are being invoked
     */
    function _payFeesAndArtist(Sale memory _sale, uint32 _purchaseQuantity) internal {
        uint256 totalPurchaseValue = _purchaseQuantity * _sale.price;
        uint256 feesPaid;

        for (uint256 i; i < _sale.primaryFee.feeBPS.length; i++) {
            uint256 fee = (totalPurchaseValue * _sale.primaryFee.feeBPS[i]) / 10000;
            feesPaid = feesPaid + fee;
            _payout(_sale.primaryFee.feeRecipients[i], _sale.erc20Token, fee);
        }
        if (totalPurchaseValue - feesPaid > 0) {
            _payout(_sale.artist, _sale.erc20Token, (totalPurchaseValue - feesPaid));
        }
    }

    /**
     * @notice Simple payment function to pay an amount of currency to a recipient
     * @param _recipient Recipient of payment
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount
     */
    function _payout(address _recipient, address _erc20Token, uint256 _amount) internal {
        if (_erc20Token != address(0)) {
            IERC20(_erc20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = payable(_recipient).call{ value: _amount, gas: 20000 }("");
            /* solhint-enable avoid-low-level-calls */
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                /* solhint-disable reentrancy */
                _failedTransferCredits[_recipient] += _amount;
                /* solhint-enable reentrancy */
            }
        }
    }

    /**
     * @notice Validate payment and process part of it (if in ERC20)
     * @dev Doesn't send erc20 to primary fee recipients immediately, preferring n transfer + 1 transferFrom operations
     *      instead of n transferFrom operations b/c transferFrom is expensive as it checks
     *      approval storage on erc20 contract
     * @param sale Sale
     * @param purchaseQuantity How many purchases on the sale are being invoked
     */
    function _validateAndProcessPurchasePayment(Sale memory sale, uint32 purchaseQuantity) internal virtual {
        // Require valid payment
        if (sale.erc20Token == address(0)) {
            // The txn must come with a full ETH payment
            require(msg.value == purchaseQuantity * sale.price, "$ != expected");
        } else {
            // or we must be able to transfer the full purchase amount to the contract
            IERC20(sale.erc20Token).transferFrom(msg.sender, address(this), purchaseQuantity * sale.price);
        }
    }

    /**
     * @notice Validate purchase time and process quantity of purchase
     * @param sale Sale
     * @param saleId ID of sale
     * @param purchaseQuantity How many purchases on the sale are being invoked
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     */
    function _validatePurchaseTimeAndProcessQuantity(
        Sale memory sale,
        uint256 saleId,
        uint32 purchaseQuantity,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof
    ) internal {
        // User is only guaranteed whitelisted allotment during pre-sale,
        // after sale becomes public all purchases are just routed through open public-sale
        if (_isWhitelistedAndPresale(presaleWhitelistedQuantity, proof, sale)) {
            uint32 whitelistedPurchase = whitelistedPurchases[saleId][msg.sender];
            require(whitelistedPurchase + purchaseQuantity <= presaleWhitelistedQuantity, "> whitelisted amount");
            whitelistedPurchases[saleId][msg.sender] = whitelistedPurchase + purchaseQuantity;
        } else {
            require(_isSaleOngoing(sale), "unavailable");
        }

        // Require that the purchase amount is within the sale's governance parameters
        require(
            sale.maxPurchaseAmount == 0 || purchaseQuantity <= sale.maxPurchaseAmount,
            "cannot buy > maxPurchaseAmount in one tx"
        );
    }

    /**
     * @notice Asserts that it is valid to update a sale's state from prev to new
     * @param prevState Previous sale state
     * @param newState New sale state
     * @param saleId ID of sale being updated
     */
    function _isSaleStateUpdateValid(SaleState prevState, SaleState newState, uint256 saleId) internal returns (bool) {
        if (prevState == SaleState.not_started) {
            emit SaleStarted(saleId);
            return newState == SaleState.started;
        } else if (prevState == SaleState.started) {
            emit SalePaused(saleId);
            return newState == SaleState.paused;
        } else if (prevState == SaleState.paused) {
            emit SaleUnpaused(saleId);
            return newState == SaleState.started;
        } else {
            // should never reach here
            return false;
        }
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @notice See {UUPSUpgradeable-_authorizeUpgrade}
     * @param // New implementation to upgrade to
     */
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /* solhint-enable no-empty-blocks */

    /**
     * @notice Return the purchaser's type
     * @param saleArtist Sale's artist
     * @param purchaser Purchaser who's type is returned
     */
    function _getPurchaserType(address saleArtist, address purchaser) internal view returns (PurchaserType) {
        if (purchaser == saleArtist) {
            return PurchaserType.artist;
        } else if (hasRole(MINTER_ROLE, purchaser)) {
            return PurchaserType.platform;
        } else {
            return PurchaserType.general;
        }
    }

    /**
     * @notice Checks if sale is still valid, given the sale end timestamp
     * @param _saleEndTimestamp Sale end timestamp
     */
    function _isSaleEndTimestampCurrentlyValid(uint128 _saleEndTimestamp) internal view returns (bool) {
        return _saleEndTimestamp > block.timestamp || _saleEndTimestamp == 0;
    }

    /**
     * @notice Validates that sale is still ongoing
     * @param sale Sale
     */
    function _isSaleOngoing(Sale memory sale) internal view returns (bool) {
        return sale.saleState == SaleState.started && _isSaleEndTimestampCurrentlyValid(sale.saleEndTimestamp);
    }

    /**
     * @notice Checks if user whitelisted for presale purchase
     * @param _whitelistedQuantity Purchaser's requested quantity. Validated against merkle tree
     * @param proof Merkle tree proof to use to validate account's inclusion in tree as leaf
     * @param sale The sale
     */
    function _isWhitelistedAndPresale(
        uint32 _whitelistedQuantity,
        bytes32[] calldata proof,
        Sale memory sale
    ) internal view returns (bool) {
        return (sale.saleState == SaleState.not_started &&
            _verify(_leaf(msg.sender, uint256(_whitelistedQuantity)), sale.merkleroot, proof));
    }

    /**
     * @notice Checks if primary sale fee info is valid
     * @param _feeInfo Primary sale fee info
     */
    function _isPrimaryFeeInfoValid(PrimaryFeeInfo memory _feeInfo) internal pure returns (bool) {
        uint totalBPS = 0;
        uint256 feeInfoLength = _feeInfo.feeBPS.length;
        for (uint i = 0; i < feeInfoLength; i++) {
            totalBPS += _feeInfo.feeBPS[i];
        }
        // Total payment distribution must be 100% and the fee recipients and allocation arrays must be equal size
        return totalBPS == 10000 && feeInfoLength == _feeInfo.feeRecipients.length;
    }

    ////////////////////////////////////
    ////// MERKLEROOT FUNCTIONS ////////
    ////////////////////////////////////

    /**
     * @notice Create a merkle tree with address: quantity pairs as the leaves.
     *      The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     * @param account Minting account being verified
     * @param quantity Quantity to mint, being verified
     */
    function _leaf(address account, uint256 quantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, quantity));
    }

    /**
     * @notice Verify a leaf's inclusion in a merkle tree with its root and corresponding proof
     * @param leaf Leaf to verify
     * @param merkleroot Merkle tree's root
     * @param proof Corresponding proof for leaf
     */
    function _verify(bytes32 leaf, bytes32 merkleroot, bytes32[] memory proof) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleroot, leaf);
    }
}