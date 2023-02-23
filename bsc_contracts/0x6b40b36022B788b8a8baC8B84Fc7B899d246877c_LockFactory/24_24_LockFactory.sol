// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

// IMPORTS
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./DeployFee.sol";

contract LockFactory is AccessControlEnumerable, DeployFee {
    using SafeERC20 for IERC20;
    using Address for address;

    // STRUCTS
    struct LockModules {
        address dm;
        address shm;
        address spm;
    }

    struct InstancesAddress {
        address lockInstance;
        address depositManagerInstance;
        address scheduleManagerInstance;
        address splitManagerInstance;
        address selectedPaymentToken;
    }

    // IS THE FEE PAID
    mapping(address => bool) public feePaid;

    // ROLES
    bytes32 public constant FACTORY_MANAGER = keccak256("FACTORY_MANAGER");
    bytes32 internal constant UPGRADE_MANAGER_ROLE = keccak256("UPGRADE_MANAGER_ROLE");
    bytes32 public constant WHITE_LIST = keccak256("WHITE_LIST");
    bytes32 public constant TX_FEE_WHITELISTED_ROLE = keccak256("polkalokr.features.txFeeFeature._txFeeBeneficiaryRole");

    bytes private constant ZERO_BYTES = new bytes(0);

    // MINTR CONTRACT ADDRESS
    address mintrContract;

    event Deploy(address indexed owner, address lockProxy);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(FACTORY_MANAGER, _msgSender());
    }

    // EXTERNAL GET FUNCTIONS

    /* return array of all addressess  who have particular role */
    function getAllRoleMember(bytes32 role)
        public
        view
        returns (address[] memory)
    {
        uint256 membercount = super.getRoleMemberCount(role);
        address[] memory roleAddress = new address[](membercount);
        for (uint256 i; i < membercount; ) {
            address rolemember = super.getRoleMember(role, i);
            roleAddress[i] = rolemember;
            unchecked {
                ++i;
            }
        }
        return roleAddress;
    }

    /// @notice This functions will return all the payment tokens
    /// @return paymentTokens all the tokens that the lock factory will accept
    function getPaymentTokens()
        external
        view
        returns (IERC20Metadata[] memory paymentTokens)
    {
        paymentTokens = deployFeeTokens;
    }

    /// @notice This functions will return the actual native token price feed
    /// @return actualCryptoPriceFeed chainlink crypto price feed i.e. ETH-USD, BNB-USD
    function getCryptoPriceFeed()
        external
        view
        returns (AggregatorV3Interface actualCryptoPriceFeed)
    {
        actualCryptoPriceFeed = cryptoPriceFeed;
    }

    /// @notice This functions will return the amount of tokens to pay the fee
    /// @param paymentToken This will be the token to pay the fee
    /// @param lockedAmount This will be the amount of tokens to lock
    /// @return paymentTokenFixedAmount Amount of tokens if you are going to pay the fixed amount
    /// @return lockTokenPercentageAmount Amount of locked tokens if you will pay the percentage amount
    function getRequiredTokensToPayFee(
        IERC20Metadata paymentToken,
        uint256 lockedAmount
    )
        external
        view
        returns (
            uint256 paymentTokenFixedAmount,
            uint256 lockTokenPercentageAmount
        )
    {
        (
            paymentTokenFixedAmount,
            lockTokenPercentageAmount
        ) = calculateRequiredTokens(paymentToken, lockedAmount);
    }

    /// @notice This functions will return the amount of native tokens to pay the fee
    /// @return fixedAmountRequired Amount of native tokens if you are going to pay the fixed amount
    function getRequiredMsgValueToPayFee()
        external
        view
        returns (uint256 fixedAmountRequired)
    {
        fixedAmountRequired = calculateRequiredCrypto();
    }

    /// EXTERNAL SET FUNCTIONS

    function setupDeployFee(bytes calldata deployFeeOptions)
        external
        onlyRole(FACTORY_MANAGER)
    {
        (
            uint256 _deployFeeAmount,
            uint256 _deployFeePercentage,
            address _deployFeeBeneficiary,
            address[] memory _deployFeeTokens,
            address[] memory _tokenPriceFeeds,
            address _cryptoPriceFeed,
            bytes32 _deployFeePaymentOption
        ) = abi.decode(
                deployFeeOptions,
                (
                    uint256,
                    uint256,
                    address,
                    address[],
                    address[],
                    address,
                    bytes32
                )
            );
        setupDeployFeeInternal(
            _deployFeeAmount,
            _deployFeePercentage,
            _deployFeeBeneficiary,
            _deployFeeTokens,
            _tokenPriceFeeds,
            _cryptoPriceFeed,
            _deployFeePaymentOption
        );
    }

    function setMintrFactory(address _mintrContract)
        external
        onlyRole(FACTORY_MANAGER)
    {
        require(_mintrContract != address(0), "Can't set address 0");
        mintrContract = _mintrContract;
    }

    function setDiscountTokens(
        address[] memory _discountTokens,
        uint256[] memory _discountAmounts
    ) external onlyRole(FACTORY_MANAGER) {
        require(_discountAmounts.length == _discountTokens.length, "Tokens and Amounts dont have same length");
        for(uint256 i; i < _discountAmounts.length; ) {
            setDiscountTokenInternal(_discountTokens[i], _discountAmounts[i]);
            unchecked {
                i++;
            }
        }
    }

    /// UPPDATE FUNCTIONS

    function updateTokenFees(
        address _updatedToken,
        uint256 _newFixedFee,
        uint256 _newPercentageFee
    ) external onlyRole(FACTORY_MANAGER) {
        require(_updatedToken != address(0), "Can't Update Address(0)");
        require(
            _newFixedFee > 0 && _newPercentageFee > 0,
            "Can't set 0 fee, use WhiteList instead"
        );
        updateTokenFeesInternal(_updatedToken, _newFixedFee, _newPercentageFee);
    }

    function updateFeesAndPaymentTokens(
        address[] memory _deployFeeTokens,
        address[] memory _tokenPriceFeeds,
        uint256[] memory _ids
    ) external onlyRole(FACTORY_MANAGER) {
        updateFeedsAndTokens(_deployFeeTokens, _tokenPriceFeeds, _ids);
    }

    function updateDeployFeeBeneficiary(address newDeployFeeBeneficiary) external onlyRole(FACTORY_MANAGER) {
        updateDeployFeeBeneficiaryInternal(newDeployFeeBeneficiary);
    }

    function addFeedsAndPaymentTokens(
        address[] memory _deployFeeTokens,
        address[] memory _tokenPriceFeeds
    ) external onlyRole(FACTORY_MANAGER) {
        addNewFeedsAndTokens(_deployFeeTokens, _tokenPriceFeeds);
    }

    function changeActiveDeployFeeAmounts(
        uint256 newFixedAmount,
        uint256 newPercentageAmount
    ) external onlyRole(FACTORY_MANAGER) {
        changeActiveDeployFeesInternal(newFixedAmount, newPercentageAmount);
    }

    function changeActivePaymentOption(bytes32 paymentOption)
        external
        onlyRole(FACTORY_MANAGER)
    {
        changeActivePaymentOptionInternal(paymentOption);
    }

    /// REMOVE FUNCTIONS

    function removeDiscountTokens(
        address[] memory _discountTokens
    ) external onlyRole(FACTORY_MANAGER) {
        for(uint8 i; i < _discountTokens.length; ) {
            removeDiscountTokenInternal(_discountTokens[i]);
            unchecked {
                i++;
            }
        }
    }

    function removeFeedAndPaymentToken(uint256 _id)
        external
        onlyRole(FACTORY_MANAGER)
    {
        removeFeedAndToken(_id);
    }

    /// WHITE LIST FUNCTIONS

    function addToWhiteList(address[] memory whiteListAddresses)
        external
        onlyRole(FACTORY_MANAGER)
    {
        for (uint256 i; i < whiteListAddresses.length; ) {
            if (!hasRole(WHITE_LIST, whiteListAddresses[i])) {
                _grantRole(WHITE_LIST, whiteListAddresses[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    function removeFromWhiteList(address[] memory removedAddresses)
        external
        onlyRole(FACTORY_MANAGER)
    {
        for (uint256 i; i < removedAddresses.length; ) {
            if (hasRole(WHITE_LIST, removedAddresses[i])) {
                _revokeRole(WHITE_LIST, removedAddresses[i]);
            }
            unchecked {
                ++i;
            }
        }
    }

    /// DEPLOY LOCK FUNCTIONS

    function deployLock(
        bytes calldata lockInstancesAndPaymentToken,
        bytes calldata lockAndInitialBeneficiariesData,
        bytes calldata depositManagerData,
        bytes calldata scheduleManagerData,
        bytes calldata splitManagerData
    ) external payable {
        InstancesAddress memory instances = decodeInstancesAddress(
            lockInstancesAndPaymentToken
        );

        //If it's not whitelisted, charge the deploy fee
        if (!checkTokenOnWhiteList(lockAndInitialBeneficiariesData)) {
            verifyFeePayment(
                instances.selectedPaymentToken,
                lockAndInitialBeneficiariesData
            );
        }

        address lockProxy = address(
            new ERC1967Proxy(instances.lockInstance, ZERO_BYTES)
        );

        LockModules memory modules = deployModuleProxies(
            lockProxy,
            instances.depositManagerInstance,
            depositManagerData,
            instances.scheduleManagerInstance,
            scheduleManagerData,
            instances.splitManagerInstance,
            splitManagerData
        );
        initializeLock(lockProxy, modules, lockAndInitialBeneficiariesData);

        manageRoles(lockProxy, modules);

        emit Deploy(_msgSender(), lockProxy);
    }

    function deployModuleProxies(
        address lockProxy,
        address depositManagerInstance,
        bytes memory depositManagerData,
        address scheduleManagerInstance,
        bytes memory scheduleManagerData,
        address splitManagerInstance,
        bytes memory splitManagerData
    ) internal returns (LockModules memory modules) {
        modules.dm = address(
            new ERC1967Proxy(
                depositManagerInstance,
                prepareModuleInitializerData(
                    address(lockProxy),
                    depositManagerData
                )
            )
        );
        modules.shm = address(
            new ERC1967Proxy(
                scheduleManagerInstance,
                prepareModuleInitializerData(
                    address(lockProxy),
                    scheduleManagerData
                )
            )
        );
        modules.spm = address(
            new ERC1967Proxy(
                splitManagerInstance,
                prepareModuleInitializerData(
                    address(lockProxy),
                    splitManagerData
                )
            )
        );
    }

    function initializeLock(
        address lockProxy,
        LockModules memory modules,
        bytes memory lockAndInitialBeneficiariesData
    ) internal {
        (bytes memory lockData, bytes memory initialBeneficiariesData) = abi
            .decode(lockAndInitialBeneficiariesData, (bytes, bytes));
        lockProxy.functionCall(
            prepareTokensAndLockInit(
                address(lockProxy),
                modules,
                lockData,
                initialBeneficiariesData
            ),
            "Unknown lock initalization error"
        );
    }

    function prepareTokensAndLockInit(
        address lockProxy,
        LockModules memory modules,
        bytes memory lockData,
        bytes memory initialBeneficiariesData
    ) internal returns (bytes memory) {
        (
            ,
            ,
            ,
            address token,
            address governance,
            bool canAdd,
            bool canRemove,
            bool canTransfer,
            uint256 lockedAmount
        ) = abi.decode(
                lockData,
                (
                    address,
                    address,
                    address,
                    address,
                    address,
                    bool,
                    bool,
                    bool,
                    uint256
                )
            );
        prepareTokens(token, lockProxy, lockedAmount);
        return
            abi.encodeWithSignature(
                "initialize(bytes,bytes)",
                abi.encode(
                    modules.shm,
                    modules.dm,
                    modules.spm,
                    token,
                    governance,
                    canAdd,
                    canRemove,
                    canTransfer,
                    lockedAmount
                ),
                initialBeneficiariesData
            );
    }

    function prepareTokens(
        address token,
        address lockProxy,
        uint256 amount
    ) internal {
        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        require(
            IERC20(token).balanceOf(address(this)) == amount,
            "ERROR: Can't Lock Tokens With TX Fee"
        );
        if (mintrContract != address(0)) {
            (bool success, bytes memory data) = mintrContract.call{gas: 10000}(
                abi.encodeWithSignature("createdByMinted(address)", token)
            );
            require(success, "ERROR: FAILED TO CALL MINTR");
            bool createdByMinted = abi.decode(data, (bool));
            if (createdByMinted) {
                whitelistLokr(lockProxy, token);
            }
        }
        IERC20(token).approve(lockProxy, amount);
    }

    function prepareModuleInitializerData(
        address lockProxy,
        bytes memory initData
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSignature(
                "initialize(address,bytes)",
                lockProxy,
                initData
            );
    }

    function decodeInstancesAddress(bytes memory data)
        internal
        pure
        returns (InstancesAddress memory instances)
    {
        (
            instances.lockInstance,
            instances.depositManagerInstance,
            instances.scheduleManagerInstance,
            instances.splitManagerInstance,
            instances.selectedPaymentToken
        ) = abi.decode(data, (address, address, address, address, address));
    }

    function manageRoles(address lockProxy, LockModules memory modules)
        internal
    {
        AccessControl(lockProxy).grantRole(UPGRADE_MANAGER_ROLE, _msgSender());
        AccessControl(modules.dm).grantRole(UPGRADE_MANAGER_ROLE, _msgSender());
        AccessControl(modules.shm).grantRole(
            UPGRADE_MANAGER_ROLE,
            _msgSender()
        );
        AccessControl(modules.spm).grantRole(
            UPGRADE_MANAGER_ROLE,
            _msgSender()
        );

        AccessControl(lockProxy).renounceRole(
            UPGRADE_MANAGER_ROLE,
            address(this)
        );
        AccessControl(modules.dm).renounceRole(
            UPGRADE_MANAGER_ROLE,
            address(this)
        );
        AccessControl(modules.shm).renounceRole(
            UPGRADE_MANAGER_ROLE,
            address(this)
        );
        AccessControl(modules.spm).renounceRole(
            UPGRADE_MANAGER_ROLE,
            address(this)
        );

        AccessControl(lockProxy).grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        AccessControl(modules.dm).grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        AccessControl(modules.shm).grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        AccessControl(modules.spm).grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        AccessControl(lockProxy).renounceRole(
            DEFAULT_ADMIN_ROLE,
            address(this)
        );
        AccessControl(modules.dm).renounceRole(
            DEFAULT_ADMIN_ROLE,
            address(this)
        );
        AccessControl(modules.shm).renounceRole(
            DEFAULT_ADMIN_ROLE,
            address(this)
        );
        AccessControl(modules.spm).renounceRole(
            DEFAULT_ADMIN_ROLE,
            address(this)
        );
    }

    function whitelistLokr(address lockProxy, address token) internal {
        AccessControl(token).grantRole(TX_FEE_WHITELISTED_ROLE, lockProxy);
    }

    function verifyFeePayment(address paymentToken, bytes memory data)
        internal
    {
        require(
            deployFeePaymentOption != "",
            "ERROR: THERE'S NO PAYMENT OPTION ENABLED"
        );
        (bytes memory lockData, ) = abi.decode(data, (bytes, bytes));
        (, , , address token, , , , , uint256 lockedAmount) = abi.decode(
            lockData,
            (
                address,
                address,
                address,
                address,
                address,
                bool,
                bool,
                bool,
                uint256
            )
        );
        if (
            deployFeePaymentOption == PERCENTAGE_UPFRONT_PAYMENT_OPTION ||
            (deployFeePaymentOption == COMBINED_PAYMENT_OPTION &&
                feePaid[token]) ||
            (deployFeePaymentOption == COMBINED_PAYMENT_OPTION &&
                !feePaid[token] &&
                hasRole(WHITE_LIST, _msgSender()))
        ) {
            chargeWithLockedToken(IERC20Metadata(token), lockedAmount);
        } else if (
            (!hasRole(WHITE_LIST, _msgSender()) &&
                deployFeePaymentOption == COMBINED_PAYMENT_OPTION) ||
            (deployFeePaymentOption == FIXED_PAYMENT_OPTION && !feePaid[token])
        ) {
            chargeDeployFee(paymentToken);
            feePaid[token] = true;
            TokenFees[token].PercentageAmountFee = deployFeePercentageAmount;
        }
    }

    function checkTokenOnWhiteList(bytes memory lockAndInitialBeneficiariesData)
        internal
        view
        returns (bool)
    {
        (bytes memory lockData, ) = abi.decode(
            lockAndInitialBeneficiariesData,
            (bytes, bytes)
        );
        (, , , address token, , , , , ) = abi.decode(
            lockData,
            (
                address,
                address,
                address,
                address,
                address,
                bool,
                bool,
                bool,
                uint256
            )
        );
        return hasRole(WHITE_LIST, token);
    }
}