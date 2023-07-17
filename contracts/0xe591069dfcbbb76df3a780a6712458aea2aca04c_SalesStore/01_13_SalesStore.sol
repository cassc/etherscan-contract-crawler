// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "solady/src/utils/MerkleProofLib.sol";
import "solady/src/utils/ECDSA.sol";

enum LimitMode {
    MerkleTree,
    List,
    None,
    ECDSA
}

struct SalesInfo {
    LimitMode limitMode;
    bool onSale;
    uint96 cost;
    uint8 maxQtyPerTx;
    bool usePeriodSale;
    uint40 timeStart;
    uint24 duration;
}

interface IERC721SalesItem {
    function sellerMint(address to, uint256 quantity) external;
    function supportsInterface(bytes4) external view returns (bool);
}

contract SalesStore is Initializable, AccessControl {

    ///////////////////////////////////////////////////////////////////////////
    // Variables
    ///////////////////////////////////////////////////////////////////////////

    /// @dev Sales information on sales id.
    mapping(uint256 => SalesInfo) internal _salesInfo;
    /// @dev Merkle root on sales id for merkelTree of LimitMode.
    mapping(uint256 => bytes32) public merkleRoots;
    /// @dev Alloctions on sales id for list of LimitMode.
    mapping(uint256 => mapping(address => uint256)) public allocations;
    /// @dev Minted allocations on address on sales id.
    mapping(uint256 => mapping(address => uint256)) public mintedNumbers;

    /// @dev If true, Whole sales are suspended.
    bool public salesSuspended;
    /// @dev Sales counter.
    uint24 internal _salesCount;
    /// @dev Target NFT
    IERC721SalesItem public salesTarget;

    /// @dev Withdraw address.
    address public withdrawAddress;

    /// @dev ECDSA signer address.
    address public ECDSASigner;
    /// @dev ECDSA salt.
    uint96 public ECDSASalt;

    ///////////////////////////////////////////////////////////////////////////
    // Custom Errors
    ///////////////////////////////////////////////////////////////////////////

    /// @dev A specified parmeter is Zero Address.
    error ZeroAddress();
    /// @dev 
    error RegisterInvalidContract();
    /// @dev
    error IndexOutOfBound();
    /// @dev The sale is not open.
    error NotOnSale();
    /// @dev Mint exceeding maximum quantity per transaction.
    error MintExceedingMaximumQuantity();
    /// @dev Mint without sufficient func.
    error MintWithoutSufficientFund();
    /// @dev Allocation is insufficient.
    error FailVerification();
    /// @dev Allocation is insufficient.
    error InsufficientAllocation();
    /// @dev Call invalid sale function.
    error CallInvalidLimitMode();
    /// @dev Operation is unauthorized.
    error UnauthorizedOperation();
    /// @dev Caller is not EOA User.
    error CallerNotUser();
    /// @dev Start sale with updating other parameters is not allowed.
    error StartSaleWithUpdatingOtherParameters();
    /// @dev Invalid update operation under safeMode.
    error InvalidUpdateUnderSafeMode();
    /// @dev
    error ParameterLengthNotMatch();

    ///////////////////////////////////////////////////////////////////////////
    // Modifier
    ///////////////////////////////////////////////////////////////////////////
    // Revert when operated by not admin user.
    modifier onlyAdmin() {
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        _;
    }

    // Revert when caller is not EOA
    modifier callerIsUser() {
        if (tx.origin != msg.sender) revert CallerNotUser();
        _;
    }

    // Revert When sale is suspended.
    modifier WhenNotSuspended() {
        // Check sales supended
        if (salesSuspended) revert NotOnSale();
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Initializer
    ///////////////////////////////////////////////////////////////////////////
    function initialize(address target, address admin) public virtual initializer {
        // Essential initialization.
        _initializeCore(target, admin);
    }

    function initialize(address target, address admin, address receiver) public virtual initializer {
        // Essential initialization.
        _initializeCore(target, admin);
        // Set withdrawAddress
        withdrawAddress = receiver;
    }

    function initialize(address target, address admin, address receiver, address signer, uint96 salt) public virtual initializer {
        // Essential initialization.
        _initializeCore(target, admin);
        // Set withdrawAddress.
        withdrawAddress = receiver;
        // Set ECDSA configuration.
        ECDSASigner = signer;
        ECDSASalt = salt;
    }

    function _initializeCore(address target, address admin) internal virtual {
        // Set target
        _setSalesTarget(target);
        // Grant Admin for specified address or msg.sender
        if (admin == address(0)) admin = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Internal setter logics
    ///////////////////////////////////////////////////////////////////////////

    function _setSalesTarget(address target) internal {
        // Check target
        if (target == address(0)) revert ZeroAddress();
        IERC721SalesItem targetERC721 = IERC721SalesItem(target);
        // Check interface of ERC721
        if (!targetERC721.supportsInterface(0x80ac58cd)) revert RegisterInvalidContract();
        // Register target
        salesTarget = targetERC721;

    }
    function _addSale(SalesInfo memory sale) internal {
        uint256 newId = _salesCount;
        _salesInfo[newId] = sale;
        ++_salesCount;
    }

    function _updateSale(uint256 id, SalesInfo memory newSale, bool safe) internal {
        if (id + 1 > _salesCount) revert IndexOutOfBound();
        if (safe) {
            SalesInfo memory sale = _salesInfo[id];
            if (sale.limitMode != newSale.limitMode) revert InvalidUpdateUnderSafeMode();
            if (sale.onSale) revert InvalidUpdateUnderSafeMode();
            if (newSale.onSale) revert StartSaleWithUpdatingOtherParameters();
        }
        _salesInfo[id] = newSale;
    }

    ///////////////////////////////////////////////////////////////////////////
    // Public withdraw function
    ///////////////////////////////////////////////////////////////////////////

    function withdraw()
        external
        payable
        onlyAdmin
    {
        if (withdrawAddress == address(0)) revert ZeroAddress();
        (bool os, ) = payable(withdrawAddress).call{
            value: address(this).balance
        }("");
        require(os);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Public getter functions
    ///////////////////////////////////////////////////////////////////////////

    function salesCount() external view returns (uint256) {
        return uint256(_salesCount);
    }

    function nowOnSale(uint256 id) external view returns (bool) {
        // Check `id` in bound.
        if (id + 1 > _salesCount) revert IndexOutOfBound();
        // Load sales information.
        SalesInfo memory sale = _salesInfo[id];

        if (!sale.onSale) {
            if (!sale.usePeriodSale) return false;
            if (block.timestamp < uint256(sale.timeStart)) return false;
            if (uint256(sale.timeStart) + uint256(sale.duration) < block.timestamp) return false;
        }
        return true;
    }

    function nowOnSaleAll() external view returns (bool[] memory ret) {
        uint256 count = _salesCount;
        ret = new bool[] (count);
        for (uint256 i; i < count; ++i) {
            // Load sales information.
            SalesInfo memory sale = _salesInfo[i];

            if (sale.onSale) {
                ret[i] = true;
            } else {
                if (uint256(sale.timeStart) <= block.timestamp) {
                    if (block.timestamp <= uint256(sale.timeStart) + uint256(sale.duration)) {
                        ret[i] = true;
                    }
                }
            }
        }
    }

    function mintedNumbersAll(address addr) external view returns (uint256[] memory ret) {
        uint256 count = _salesCount;
        ret = new uint256[] (count);
        for (uint256 i; i < count; ++i) {
            // Load mintedNumbers information.
            ret[i] = mintedNumbers[i][addr];
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Public Admin Setter Functions
    ///////////////////////////////////////////////////////////////////////////

    function setSalesTarget(address target) 
        external 
        onlyAdmin
    {
        _setSalesTarget(target);
    }

    function setWithdrawAddress(address newReceiver)
        external
        onlyAdmin
    {
        withdrawAddress = newReceiver;
    }

    function setECDSASigner(address newSigner)
        external
        onlyAdmin
    {
        ECDSASigner = newSigner;
    }

    function setECDSASalt(uint96 newSalt)
        external
        onlyAdmin
    {
        ECDSASalt = newSalt;
    }

    function setMerkleRoot(uint256 id, bytes32 root)
        external
        onlyAdmin
    {
        if (id + 1 > _salesCount) revert IndexOutOfBound();
        merkleRoots[id] = root;
    }

    function setAllocations(uint256 id, address[] calldata addrs, uint256[] calldata allocs)
        external
        onlyAdmin
    {
        if (id + 1 > _salesCount) revert IndexOutOfBound();
        uint256 length = addrs.length;
        if (length != allocs.length) revert ParameterLengthNotMatch();
        for (uint256 i; i < length; ++i) {
            allocations[id][addrs[i]] = allocs[i];
        }
    }

    function salesInfo(uint256 id) external view returns (SalesInfo memory) {
        return _salesInfo[id];
    }

    function addSale(SalesInfo memory sale) external onlyAdmin {
        _addSale(sale);
    }
    
    function addSale(LimitMode limitMode, uint256 cost, uint256 maxQtyPerTx) 
        external 
        onlyAdmin 
    {
        SalesInfo memory sale = SalesInfo(
            limitMode, 
            false, 
            uint96(cost), 
            uint8(maxQtyPerTx), 
            false, 
            0, 
            0
        );
        _addSale(sale);
    }
    
    function addSaleBatch(SalesInfo[] calldata sales) external onlyAdmin {
        if (sales.length > 0) {
            for (uint256 i; i < sales.length;++i) {
                _addSale(sales[i]); 
            }
        }
    }
    
    function addSaleBatch(
        LimitMode[] calldata limitModes, 
        uint256[] calldata costs, 
        uint256[] calldata maxQtyPerTxs
    ) 
        external 
        onlyAdmin 
    {
        if (limitModes.length != costs.length) revert ParameterLengthNotMatch();
        if (limitModes.length != maxQtyPerTxs.length) revert ParameterLengthNotMatch();
        if (limitModes.length > 0) {
            for (uint256 i; i < limitModes.length;++i) {
                SalesInfo memory sale = SalesInfo(
                    limitModes[i], 
                    false, 
                    uint96(costs[i]), 
                    uint8(maxQtyPerTxs[i]), 
                    false, 
                    0, 
                    0
                );
                _addSale(sale);
            }
        }
    }

    function updateSale(uint256 id, SalesInfo memory sale)
        external
        onlyAdmin
    {
        _updateSale(id, sale, true);
    }

    function updateCost(uint256 id, uint256 cost)
        external
        onlyAdmin
    {
        SalesInfo memory sale = _salesInfo[id];
        sale.cost = uint96(cost);
        _updateSale(id, sale, false);
    }

    function updateMaxQtyPerTx(uint256 id, uint256 maxQtyPerTx)
        external
        onlyAdmin
    {
        SalesInfo memory sale = _salesInfo[id];
        sale.maxQtyPerTx = uint8(maxQtyPerTx);
        _updateSale(id, sale, false);
    }

    function updateUsePeriodSale(uint256 id, bool value)
        external
        onlyAdmin
    {
        SalesInfo memory sale = _salesInfo[id];
        sale.usePeriodSale = value;
        _updateSale(id, sale, false);
    }

    function updateTimeStart(uint256 id, uint256 timeStart)
        external
        onlyAdmin
    {
        SalesInfo memory sale = _salesInfo[id];
        sale.timeStart = uint40(timeStart);
        _updateSale(id, sale, false);
    }

    function updateDuration(uint256 id, uint256 duration)
        external
        onlyAdmin
    {
        SalesInfo memory sale = _salesInfo[id];
        sale.duration = uint24(duration);
        _updateSale(id, sale, false);
    }

    function setOnSale(uint256 id, bool value)
        external
        onlyAdmin
    {
        SalesInfo memory sale = _salesInfo[id];
        sale.onSale = value;
        _updateSale(id, sale, false);
    }

    function _getDigest(bytes memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
    }

    ///////////////////////////////////////////////////////////////////////////
    // Internal mint logic
    ///////////////////////////////////////////////////////////////////////////

    function _mint(
        uint256 id, 
        uint256 amount, 
        bool isLimitSale,
        uint256 allocation,
        bool onSale, 
        uint96 cost, 
        uint8 maxQtyPerTx, 
        bool usePeriodSale, 
        uint40 timeStart, 
        uint24 duration
    ) internal {
        // Check on sale.
        if (!onSale) {
            if (!usePeriodSale) revert NotOnSale();
            if (block.timestamp < uint256(timeStart)) revert NotOnSale();
            if (uint256(timeStart) + uint256(duration) < block.timestamp) revert NotOnSale();
        }
        // Check remain allocation.
        if (isLimitSale) {
            uint256 currentMinted = mintedNumbers[id][msg.sender];
            if (currentMinted + amount > allocation) revert InsufficientAllocation();
            // Increment minted count
            mintedNumbers[id][msg.sender] = currentMinted + amount;
        }
        // Check quantity.
        if (maxQtyPerTx > 0) {
            if (amount > maxQtyPerTx) revert MintExceedingMaximumQuantity();
        }
        // Check funds.
        if (msg.value < cost * amount) revert MintWithoutSufficientFund();

        // Mint
        salesTarget.sellerMint(msg.sender, amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    // Mint Functions
    ///////////////////////////////////////////////////////////////////////////

    function mintWithProof(uint256 id, uint256 amount, bytes32[] calldata proof, uint256 allocation)
        external
        payable
        callerIsUser
        WhenNotSuspended
    {
        // Check `id` in bound.
        if (id + 1 > _salesCount) revert IndexOutOfBound();
        // Load sales information.
        SalesInfo memory sale = _salesInfo[id];

        // Check sales mode.
        if (sale.limitMode != LimitMode.MerkleTree) revert CallInvalidLimitMode();
        // Check merkle proof.
        if (!MerkleProofLib.verifyCalldata(
            proof, 
            merkleRoots[id], 
            keccak256(abi.encodePacked(msg.sender, allocation))
        )) revert FailVerification();
        // Call internal mint function
        _mint(id, amount, true, allocation, sale.onSale, sale.cost, sale.maxQtyPerTx, sale.usePeriodSale, sale.timeStart, sale.duration);
    }

    function mintWithSignature(uint256 id, uint256 amount, bytes calldata signature, uint256 allocation)
        external
        payable
        callerIsUser
        WhenNotSuspended
    {
        // Check `id` in bound.
        if (id + 1 > _salesCount) revert IndexOutOfBound();
        // Load sales information.
        SalesInfo memory sale = _salesInfo[id];

        // Check sales mode(ECDSA).
        if (sale.limitMode != LimitMode.ECDSA) revert CallInvalidLimitMode();
        // Verify signature.
        address recovered = ECDSA.recover(
            _getDigest(abi.encodePacked(ECDSASalt, id, msg.sender, allocation)), 
            signature
        );
        if (recovered != ECDSASigner) revert FailVerification();
        // Call internal mint function
        _mint(id, amount, true, allocation, sale.onSale, sale.cost, sale.maxQtyPerTx, sale.usePeriodSale, sale.timeStart, sale.duration);
    }

    function mint(uint256 id, uint256 amount)
        external
        payable
        callerIsUser
        WhenNotSuspended
    {
        // Check `id` in bound.
        if (id + 1 > _salesCount) revert IndexOutOfBound();
        // Load sales information.
        SalesInfo memory sale = _salesInfo[id];

        // Check sales mode.
        if (sale.limitMode == LimitMode.MerkleTree) revert CallInvalidLimitMode();
        if (sale.limitMode == LimitMode.ECDSA) revert CallInvalidLimitMode();
        // Check remain allocation.
        if (sale.limitMode == LimitMode.List) {
            _mint(id, amount, true, allocations[id][msg.sender], sale.onSale, sale.cost, sale.maxQtyPerTx, sale.usePeriodSale, sale.timeStart, sale.duration);
        } else {
            _mint(id, amount, false, 0, sale.onSale, sale.cost, sale.maxQtyPerTx, sale.usePeriodSale, sale.timeStart, sale.duration);
        }

    }
}