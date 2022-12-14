// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/IERCOwnable.sol";
import "./interface/IwrappedToken.sol";
import "./interface/Iregistry.sol";
import "./interface/Isettings.sol";
import "./interface/IbridgeMigrator.sol";
import "./interface/Icontroller.sol";
import "./interface/Ideployer.sol";
import "./interface/IfeeController.sol";
import "./interface/IbridgePool.sol";

contract Bridge is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    struct asset {
        address tokenAddress;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 ownerFeeBalance;
        uint256 networkFeeBalance;
        uint256 collectedFees;
        bool ownedRail;
        address manager;
        address feeRemitance;
        bool isSet;
    }
    struct directForiegnAsset {
        address foriegnAddress;
        address nativeAddress;
        uint256 chainID;
        bool isSet;
    }

    IController public controller;
    Isettings public settings;
    IRegistery public registry;
    IbridgePool public bridgePool;
    bool public paused;

    mapping(address => asset) public nativeAssets;
    mapping(address => bool) public isActiveNativeAsset;
    mapping(address => uint256[]) assetSupportedChainIds;
    mapping(address => mapping(uint256 => bool)) public isAssetSupportedChain;
    mapping(address => uint256) public foriegnAssetChainID;
    mapping(address => asset) public foriegnAssets;
    mapping(uint256 => directForiegnAsset) public directForiegnAssets;
    mapping(address => mapping(uint256 => address)) public wrappedForiegnPair;
    mapping(address => address) public foriegnPair;
    mapping(address => mapping(uint256 => bool)) public hasWrappedForiegnPair;
    mapping(address => mapping(uint256 => bool)) public isDirectSwap;

    uint256 public totalGas;
    uint256 public chainId; // current chain id
    //    uint256 public immutable chainId; // current chain id
    address public deployer;
    address public feeController;
    bool activeMigration;
    uint256 migrationInitiationTime;
    uint256 constant migrationDelay = 2 days;
    address newBridge;
    address migrator;

    uint256 directForiegnCount;
    //    address public immutable migrator;
    uint256 fMigrationAt;
    uint256 fDirectSwapMigrationAt;
    uint256 nMigrationAt;
    uint256 public constant standardDecimals = 18;
    address[] public foriegnAssetsList;
    address[] public nativeAssetsList;

    event MigrationInitiated(address indexed newBridge);
    event RegisterredNativeMigration(address indexed assetAddress);
    event RegisteredForiegnMigration(
        address indexed foriegnAddress,
        uint256 indexed chainID,
        address indexed wrappedAddress
    );
    event MigratedAsset(address indexed assetAddress, bool isNativeAsset);
    event ForiegnAssetAdded(
        address indexed foriegnAddress,
        uint256 indexed chainID,
        address indexed wrappedAddress
    );
    event UpdatedAddresses(
        address indexed settings,
        address indexed feeController,
        address indexed deployer
    );
    event AssetUpdated(
        address indexed assetAddress,
        address indexed manager,
        address indexed feeRemitance,
        uint256 min,
        uint256 max,
        bool native
    );
    event MigrationCompleted(address indexed newBridge);
    event BridgePauseStatusChanged(bool status);
    //    event NativeAssetStatusChanged(address indexed assetAddress , bool status);

    event SendTransaction(
        bytes32 transactionID,
        uint256 chainID,
        address indexed assetAddress,
        uint256 sendAmount,
        address indexed receiver,
        uint256 nounce,
        address indexed sender
    );
    event BurnTransaction(
        bytes32 transactionID,
        uint256 chainID,
        address indexed assetAddress,
        uint256 sendAmount,
        address indexed receiver,
        uint256 nounce,
        address indexed sender
    );
    event RailAdded(
        address indexed assetAddress,
        uint256 minAmount,
        uint256 maxAmount,
        uint256[] supportedChains,
        address[] foriegnAddresses,
        bool directSwap,
        address registrar,
        bool ownedRail,
        address indexed manager,
        address feeRemitance,
        uint256 deployWith
    );

    constructor(
        address _controllers,
        address _settings,
        address _registry,
        address _deployer,
        address _feeController,
        address _bridgePool,
        address _migrator
    ) {
        noneZeroAddress(_controllers);
        noneZeroAddress(_settings);
        noneZeroAddress(_registry);
        noneZeroAddress(_deployer);
        noneZeroAddress(_feeController);
        noneZeroAddress(_bridgePool);
        settings = Isettings(_settings);
        controller = IController(_controllers);
        registry = IRegistery(_registry);
        migrator = _migrator;
        deployer = _deployer;
        feeController = _feeController;
        bridgePool = IbridgePool(_bridgePool);
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;
    }

    function pauseBrigde() external {
        isOwner();
        paused = !paused;
        //    emit BridgePauseStatusChanged(paused);
    }

    function updateAddresses(
        address _settings,
        address _feeController,
        address _deployer
    ) external {
        isOwner();
        noneZeroAddress(_settings);
        noneZeroAddress(_feeController);
        noneZeroAddress(_deployer);
        emit UpdatedAddresses(_settings, _feeController, _deployer);
        settings = Isettings(_settings);
        feeController = _feeController;
        deployer = _deployer;
    }

    function activeNativeAsset(address assetAddress, bool activate) public {
        //    require(nativeAssets[assetAddress].isSet , "I_A");
        require(
            nativeAssets[assetAddress].isSet &&
                (controller.isAdmin(_msgSender()) ||
                    controller.isRegistrar(_msgSender()) ||
                    isAssetManager(assetAddress, true)),
            "U_A"
        );
        //    emit NativeAssetStatusChanged(assetAddress , activate);
        isActiveNativeAsset[assetAddress] = activate;
    }

    function updateAsset(
        address assetAddress,
        address manager,
        address _feeRemitance,
        uint256 min,
        uint256 max
    ) external {
        notPaused();
        noneZeroAddress(manager);
        noneZeroAddress(_feeRemitance);
        require(
            (foriegnAssets[assetAddress].isSet ||
                nativeAssets[assetAddress].isSet) && max > min,
            "I_A"
        );
        bool native;
        if (isAssetManager(assetAddress, true)) {
            native = true;
        } else if (isAssetManager(assetAddress, false)) {
            native = false;
        } else {
            isOwner();
            if (foriegnAssets[assetAddress].isSet) native = false;
            else if (nativeAssets[assetAddress].isSet) native = true;
            else require(false, "U_A");
        }

        if (native) {
            nativeAssets[assetAddress].manager = manager;
            nativeAssets[assetAddress].feeRemitance = _feeRemitance;
            nativeAssets[assetAddress].minAmount = min;
            nativeAssets[assetAddress].maxAmount = max;
        } else {
            foriegnAssets[assetAddress].manager = manager;
            foriegnAssets[assetAddress].feeRemitance = _feeRemitance;
            foriegnAssets[assetAddress].minAmount = min;
            foriegnAssets[assetAddress].maxAmount = max;
        }

        AssetUpdated(assetAddress, manager, _feeRemitance, min, max, native);
    }

    function registerRail(
        address assetAddress,
        uint256 minAmount,
        uint256 maxAmount,
        uint256[] calldata supportedChains,
        address[] calldata foriegnAddresses,
        bool directSwap,
        address feeAccount,
        address manager,
        uint256 deployWith
    ) external {
        notPaused();
        bool ownedRail;
        //   require(maxAmount > minAmount  && supportedChains.length == foriegnAddresses.length, "AL_E");
        if (controller.isAdmin(msg.sender)) {
            if (manager != address(0) && feeAccount != address(0)) {
                ownedRail = true;
            }
        } else {
            ownedRail = true;
            if (settings.onlyOwnableRail()) {
                if (assetAddress == address(0)) {
                    require(
                        settings.approvedToAdd(assetAddress, msg.sender),
                        "U_A"
                    );
                } else {
                    require(
                        _msgSender() == IERCOwnable(assetAddress).owner() ||
                            settings.approvedToAdd(assetAddress, msg.sender),
                        "U_A"
                    );
                }
            }
            IERC20 token = IERC20(settings.brgToken());
            token.safeTransferFrom(
                _msgSender(),
                settings.feeRemitance(),
                supportedChains.length * settings.railRegistrationFee()
            );
        }

        _registerRail(
            assetAddress,
            supportedChains,
            directSwap,
            minAmount,
            maxAmount,
            ownedRail,
            feeAccount,
            manager,
            false
        );
        emit RailAdded(
            assetAddress,
            minAmount,
            maxAmount,
            supportedChains,
            foriegnAddresses,
            directSwap,
            _msgSender(),
            ownedRail,
            manager,
            feeAccount,
            deployWith
        );
    }

    function _registerRail(
        address assetAddress,
        uint256[] memory supportedChains,
        bool directSwap,
        uint256 minAmount,
        uint256 maxAmount,
        bool ownedRail,
        address feeAccount,
        address manager,
        bool migration
    ) internal {
        asset storage newNativeAsset = nativeAssets[assetAddress];
        if (!newNativeAsset.isSet) {
            newNativeAsset.tokenAddress = assetAddress;
            newNativeAsset.minAmount = minAmount;
            newNativeAsset.maxAmount = maxAmount;
            if (ownedRail) {
                if (feeAccount != address(0) && manager != address(0)) {
                    newNativeAsset.ownedRail = true;
                    newNativeAsset.feeRemitance = feeAccount;
                    newNativeAsset.manager = manager;
                }
            }
            newNativeAsset.isSet = true;
            isActiveNativeAsset[assetAddress] = false;
            nativeAssetsList.push(assetAddress);
        }
        if (directSwap && !bridgePool.validPool(assetAddress)) {
            bridgePool.createPool(assetAddress, maxAmount);
        }
        uint256 chainLenght = supportedChains.length;
        for (uint256 index; index < chainLenght; index++) {
            if (settings.isNetworkSupportedChain(supportedChains[index])) {
                if (
                    !isAssetSupportedChain[assetAddress][supportedChains[index]]
                ) {
                    isAssetSupportedChain[assetAddress][
                        supportedChains[index]
                    ] = true;
                    assetSupportedChainIds[assetAddress].push(
                        supportedChains[index]
                    );
                    if (migration) {
                        if (
                            IbridgeMigrator(migrator).isDirectSwap(
                                assetAddress,
                                supportedChains[index]
                            )
                        ) {
                            isDirectSwap[assetAddress][
                                supportedChains[index]
                            ] = true;
                            
                        }
                    } else {
                        if (directSwap) {
                            isDirectSwap[assetAddress][
                                supportedChains[index]
                            ] = true;
                        }
                    }
                }
            }
        }
    }

    function addForiegnAsset(
        address foriegnAddress,
        uint256 chainID,
        uint256[] calldata range,
        string[] calldata assetMeta,
        bool OwnedRail,
        address manager,
        address feeAddress,
        uint256 deployWith,
        bool directSwap,
        address nativeAddress
    ) external {
        require(
            controller.isAdmin(_msgSender()) ||
                controller.isRegistrar(_msgSender()),
            "U_A_r"
        );
        require(
            settings.isNetworkSupportedChain(chainID) &&
                !hasWrappedForiegnPair[foriegnAddress][chainID] &&
                range.length == 2 &&
                assetMeta.length == 2,
            "registered"
        );

        address wrappedAddress;
        if (directSwap) {
            wrappedAddress = nativeAddress;
            isDirectSwap[foriegnAddress][chainID] = true;
            directForiegnAssets[directForiegnCount] = directForiegnAsset(
                foriegnAddress,
                wrappedAddress,
                chainID,
                true
            );
            directForiegnCount++;
        } else {
            wrappedAddress = Ideployer(deployer).deployerWrappedAsset(
                assetMeta[0],
                assetMeta[1],
                deployWith
            );
            foriegnAssets[wrappedAddress] = asset(
                wrappedAddress,
                range[0],
                range[1],
                0,
                0,
                0,
                OwnedRail,
                manager,
                feeAddress,
                true
            );

            foriegnAssetChainID[wrappedAddress] = chainID;
            foriegnPair[wrappedAddress] = foriegnAddress;
            foriegnAssetsList.push(wrappedAddress);
        }

        _registerForiegn(foriegnAddress, chainID, wrappedAddress);
    }

    function _registerForiegn(
        address foriegnAddress,
        uint256 chainID,
        address wrappedAddress
    ) internal {
        wrappedForiegnPair[foriegnAddress][chainID] = wrappedAddress;
        hasWrappedForiegnPair[foriegnAddress][chainID] = true;
        emit ForiegnAssetAdded(foriegnAddress, chainID, wrappedAddress);
    }

    function getAssetDecimals(address assetAddress)
        internal
        view
        returns (uint256 decimals)
    {
        if (assetAddress == address(0)) {
            decimals = standardDecimals;
        } else {
            decimals = IERCOwnable(assetAddress).decimals();
        }
    }

    function standaredize(uint256 amount, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        return amount * (10**(standardDecimals - decimals));
    }

    function convertToAssetDecimals(uint256 amount, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        return amount / (10**(standardDecimals - decimals));
    }

    function send(
        uint256 chainTo,
        address assetAddress,
        uint256 amount,
        address receiver
    ) external payable nonReentrant returns (bytes32 transactionID) {
        notPaused();
        //    require(, "C_E");
        require(
            isActiveNativeAsset[assetAddress] &&
                isAssetSupportedChain[assetAddress][chainTo],
            "AL_E"
        );
        noneZeroAddress(receiver);
        (bool success, uint256 recievedValue) = processedPayment(
            assetAddress,
            chainTo,
            amount
        );
        require(
            success &&
            recievedValue > 0 &&
            recievedValue >= nativeAssets[assetAddress].minAmount &&
            recievedValue <= nativeAssets[assetAddress].maxAmount,
            "I_F"
        );

        recievedValue = deductFees(assetAddress, recievedValue, true);
        if (isDirectSwap[assetAddress][chainTo]) {
            if (assetAddress == address(0)) {
                bridgePool.topUp{value: recievedValue}(
                    assetAddress,
                    recievedValue
                );
            } else {
                IERC20(assetAddress).approve(
                    address(bridgePool),
                    recievedValue
                );
                bridgePool.topUp(assetAddress, recievedValue);
            }
        }

        recievedValue = standaredize(
            recievedValue,
            getAssetDecimals(assetAddress)
        );
        uint256 nounce;
        (transactionID, nounce) = registry.registerTransaction(
            chainTo,
            assetAddress,
            recievedValue,
            receiver,
            0
        );

        emit SendTransaction(
            transactionID,
            chainTo,
            assetAddress,
            recievedValue,
            receiver,
            nounce,
            msg.sender
        );
    }

    function burn(address assetAddress, uint256 amount, address receiver)
        external
        payable
        nonReentrant
        returns (bytes32 transactionID)
    {
        notPaused();
        uint256 chainTo = foriegnAssetChainID[assetAddress];
        require(foriegnAssets[assetAddress].isSet, "I_A");

        noneZeroAddress(receiver);
        (bool success, uint256 recievedValue) = processedPayment(
            assetAddress,
            chainTo,
            amount
        );
        require(
            success &&
                recievedValue >= foriegnAssets[assetAddress].minAmount &&
                recievedValue <= foriegnAssets[assetAddress].maxAmount,
            "I_F"
        );
        recievedValue = deductFees(assetAddress, recievedValue, false);
        IwrappedToken(assetAddress).burn(recievedValue);
        address _foriegnAsset = foriegnPair[assetAddress];
        recievedValue = standaredize(
            recievedValue,
            getAssetDecimals(assetAddress)
        );
        uint256 nounce;
        (transactionID, nounce) = registry.registerTransaction(
            chainTo,
            _foriegnAsset,
            recievedValue,
            receiver,
            1
        );

        emit BurnTransaction(
            transactionID,
            chainTo,
            _foriegnAsset,
            recievedValue,
            receiver,
            nounce,
            msg.sender
        );
    }

    function mint(bytes32 mintID) public nonReentrant {
        notPaused();
        //    require(, "MI_E");
        IRegistery.Transaction memory transaction = registry.mintTransactions(
            mintID
        );
        require(
            registry.isMintTransaction(mintID) &&
                !transaction.isCompleted &&
                registry.transactionValidated(mintID),
            "M"
        );
        uint256 amount = convertToAssetDecimals(
            transaction.amount,
            getAssetDecimals(transaction.assetAddress)
        );
        if (isDirectSwap[transaction.assetAddress][transaction.chainId]) {
            bridgePool.sendOut(
                transaction.assetAddress,
                transaction.receiver,
                amount
            );
        } else {
            IwrappedToken(transaction.assetAddress).mint(
                transaction.receiver,
                amount
            );
        }

        registry.completeMintTransaction(mintID);
    }

    function claim(bytes32 claimID) public nonReentrant {
        notPaused();
        //    require( , "CI_E");
        IRegistery.Transaction memory transaction = registry.claimTransactions(
            claimID
        );
        uint256 amount = convertToAssetDecimals(
            transaction.amount,
            getAssetDecimals(transaction.assetAddress)
        );
        require(
            registry.isClaimTransaction(claimID) &&
                registry.assetChainBalance(
                    transaction.assetAddress,
                    transaction.chainId
                ) >=
                amount &&
                !transaction.isCompleted &&
                registry.transactionValidated(claimID),
            "AL_E"
        );

        payoutUser(
            payable(transaction.receiver),
            transaction.assetAddress,
            amount
        );
        registry.completeClaimTransaction(claimID);
    }

    function payoutUser(
        address payable recipient,
        address _paymentMethod,
        uint256 amount
    ) private {
        noneZeroAddress(recipient);
        if (_paymentMethod == address(0)) {
            recipient.transfer(amount);
        } else {
            IERC20 currentPaymentMethod = IERC20(_paymentMethod);
            require(currentPaymentMethod.transfer(recipient, amount), "I_F");
        }
    }

    // internal fxn used to process incoming payments
    function processedPayment(
        address assetAddress,
        uint256 chainID,
        uint256 amount
    ) internal returns (bool, uint256) {
        uint256 gas = settings.networkGas(chainID);
        if (assetAddress == address(0)) {
            if (msg.value >= amount + gas ) {
                totalGas += gas;
                if (gas > 0)
                    payoutUser(
                        payable(settings.gasBank()),
                        address(0),
                        gas
                    );
                return (true, msg.value - gas);
            } else {
                return (false, 0);
            }
        } else {
            IERC20 token = IERC20(assetAddress);
            if (
                token.allowance(_msgSender(), address(this)) >= amount &&
                (msg.value >= gas)
            ) {
                totalGas += msg.value;
                if (gas > 0)
                    payoutUser(
                        payable(settings.gasBank()),
                        address(0),
                        msg.value
                    );
                uint256 balanceBefore = token.balanceOf(address(this));
                token.safeTransferFrom(_msgSender(), address(this), amount);
                uint256 balanceAfter = token.balanceOf(address(this));
                return (true, balanceAfter - balanceBefore);
            } else {
                return (false, 0);
            }
        }
    }

    // internal fxn for deducting and remitting fees after a sale
    function deductFees(address assetAddress, uint256 amount, bool native)
        private
        returns (uint256)
    {
        asset storage currentasset;
        if (native) currentasset = nativeAssets[assetAddress];
        else currentasset = foriegnAssets[assetAddress];

        require(currentasset.isSet, "I_A");
        if (!settings.baseFeeEnable()) {
            return amount;
        }
        // uint256 fees_to_deduct = settings.networkFee(chainID);

        uint256 feePercentage = IfeeController(feeController).getBridgeFee(
            msg.sender,
            assetAddress
        );

        if (feePercentage == 0) {
            return amount;
        }

        if (feePercentage > settings.maxFeeThreshold()) {
            feePercentage = settings.maxFeeThreshold();
        }

        uint256 baseFee = (amount * feePercentage) / 10000;
        if (currentasset.ownedRail) {
            uint256 ownershare = (baseFee * settings.railOwnerFeeShare()) / 100;
            uint256 networkshare = baseFee - ownershare;
            currentasset.collectedFees += baseFee;
            currentasset.ownerFeeBalance += ownershare;
            currentasset.networkFeeBalance += networkshare;
        } else {
            currentasset.collectedFees += baseFee;
            currentasset.networkFeeBalance += baseFee;
        }

        return amount - baseFee;
    }

    function remitFees(address assetAddress, bool native) public {
        asset storage currentasset;
        uint256 amount;
        if (native) currentasset = nativeAssets[assetAddress];
        else currentasset = foriegnAssets[assetAddress];

        if (currentasset.ownedRail) {
            if (currentasset.ownerFeeBalance > 0) {
                amount = currentasset.ownerFeeBalance;
                currentasset.ownerFeeBalance = 0;
                payoutUser(
                    payable(currentasset.feeRemitance),
                    assetAddress,
                    amount
                );
            }
        }
        if (currentasset.networkFeeBalance > 0) {
            amount = currentasset.networkFeeBalance;
            currentasset.networkFeeBalance = 0;
            payoutUser(payable(settings.feeRemitance()), assetAddress, amount);
        }
    }

    function initiateMigration(address _newbridge) external {
        notPaused();
        isOwner();
        noneZeroAddress(_newbridge);
        require(!activeMigration, "P_M");
        newBridge = _newbridge;
        activeMigration = true;
        paused = true;
        migrationInitiationTime = block.timestamp;
        emit MigrationInitiated(_newbridge);
    }

    function completeMigration() external {
        isOwner();

        require(
            activeMigration && fMigrationAt >= foriegnAssetsList.length,
            "P_M"
        );
        registry.transferOwnership(newBridge);
        activeMigration = false;
        emit MigrationCompleted(newBridge);
    }

    function migrateForiegn(uint256 limit, bool directSwap) external {
        isOwner();
        require(
            activeMigration &&
                block.timestamp - migrationInitiationTime >= migrationDelay,
            "N_Y_T"
        );
        uint256 start;
        uint256 migrationAmount;
        if (directSwap) {
            require(fDirectSwapMigrationAt < directForiegnCount, "completed");
            start = fDirectSwapMigrationAt;

            if (limit + fDirectSwapMigrationAt < directForiegnCount)
                migrationAmount = limit;
            else migrationAmount = directForiegnCount - fDirectSwapMigrationAt;

            for (uint256 i; i < migrationAmount; i++) {
                directForiegnAsset
                    storage directSwapAsset = directForiegnAssets[start + i];
                if (directSwapAsset.isSet) {
                    IbridgeMigrator(newBridge).registerForiegnMigration(
                        directSwapAsset.foriegnAddress,
                        directSwapAsset.chainID,
                        0,
                        0,
                        false,
                        address(0),
                        address(0),
                        0,
                        true,
                        directSwapAsset.nativeAddress
                    );
                    fDirectSwapMigrationAt = fDirectSwapMigrationAt + 1;
                    // emit MigratedAsset(directSwapAsset.foriegnAddress , false);
                }
            }
        } else {
            require(fMigrationAt < foriegnAssetsList.length, "completed");
            start = fMigrationAt;

            if (limit + fMigrationAt < foriegnAssetsList.length)
                migrationAmount = limit;
            else migrationAmount = foriegnAssetsList.length - fMigrationAt;

            for (uint256 i; i < migrationAmount; i++) {
                address assetAddress = foriegnAssetsList[start + i];
                remitFees(assetAddress, false);
                asset memory foriegnAsset = foriegnAssets[assetAddress];

                IwrappedToken(assetAddress).transferOwnership(newBridge);
                IbridgeMigrator(newBridge).registerForiegnMigration(
                    foriegnAsset.tokenAddress,
                    foriegnAssetChainID[foriegnAsset.tokenAddress],
                    foriegnAsset.minAmount,
                    foriegnAsset.maxAmount,
                    foriegnAsset.ownedRail,
                    foriegnAsset.manager,
                    foriegnAsset.feeRemitance,
                    foriegnAsset.collectedFees,
                    false,
                    foriegnPair[foriegnAsset.tokenAddress]
                );

                fMigrationAt = fMigrationAt + 1;
                // emit MigratedAsset(assetAddress , false);
            }
        }
    }

    function migrateNative(uint256 limit) external {
        isOwner();
        require(
            activeMigration &&
                block.timestamp - migrationInitiationTime >= migrationDelay,
            "N_Y_T"
        );
        uint256 migrationAmount;
        uint256 start;
        if (nMigrationAt == 0) start = nMigrationAt;
        else start = nMigrationAt + 1;
        if (limit + nativeAssetsList.length < nMigrationAt)
            migrationAmount = limit;
        else migrationAmount = nativeAssetsList.length - nMigrationAt;

        for (uint256 i; i < migrationAmount; i++) {
            _migrateNative(nativeAssetsList[start + i]);
        }

        // emit MigratedAsset(assetAddress , true);
    }

    function _migrateNative(address assetAddress) internal {
        asset memory nativeAsset = nativeAssets[assetAddress];
        uint256 balance;
        if (assetAddress == address(0)) {
            balance = address(this).balance;
            IbridgeMigrator(newBridge).registerNativeMigration{value: balance}(
                assetAddress,
                [nativeAsset.minAmount, nativeAsset.maxAmount],
                nativeAsset.collectedFees,
                nativeAsset.ownedRail,
                nativeAsset.manager,
                nativeAsset.feeRemitance,
                [
                    nativeAsset.ownerFeeBalance,
                    balance,
                    nativeAsset.networkFeeBalance
                ],
                isActiveNativeAsset[assetAddress],
                assetSupportedChainIds[assetAddress]
            );
        } else {
            balance = IERC20(assetAddress).balanceOf(address(this));
            IERC20(assetAddress).safeApprove(newBridge, balance);
            IbridgeMigrator(newBridge).registerNativeMigration(
                assetAddress,
                [nativeAsset.minAmount, nativeAsset.maxAmount],
                nativeAsset.collectedFees,
                nativeAsset.ownedRail,
                nativeAsset.manager,
                nativeAsset.feeRemitance,
                [
                    nativeAsset.ownerFeeBalance,
                    balance,
                    nativeAsset.networkFeeBalance
                ],
                isActiveNativeAsset[assetAddress],
                assetSupportedChainIds[assetAddress]
            );
        }
        nMigrationAt = nMigrationAt + 1;
    }

    function registerNativeMigration(
        address assetAddress,
        uint256[2] memory limits,
        uint256 collectedFees,
        bool ownedRail,
        address manager,
        address feeRemitance,
        uint256[3] memory balances,
        bool active,
        uint256[] memory supportedChains
    ) external payable {
        require(
            !nativeAssets[assetAddress].isSet && _msgSender() == migrator,
            "U_A"
        );

        (bool success, uint256 amountRecieved) = processedPayment(
            assetAddress,
            0,
            balances[1]
        );
        require(success && amountRecieved >= balances[1], "I_F");
        _registerRail(
            assetAddress,
            supportedChains,
            false,
            limits[0],
            limits[1],
            ownedRail,
            feeRemitance,
            manager,
            true
        );
        nativeAssets[assetAddress].ownerFeeBalance = balances[0];
        nativeAssets[assetAddress].networkFeeBalance = balances[2];
        nativeAssets[assetAddress].collectedFees = collectedFees;

        if (active) {
            isActiveNativeAsset[assetAddress] = true;
        }
        //  emit RegisterredNativeMigration(assetAddress);
    }

    function registerForiegnMigration(
        address wrappedAddress,
        uint256 chainID,
        uint256 minAmount,
        uint256 maxAmount,
        bool ownedRail,
        address manager,
        address feeAddress,
        uint256 _collectedFees,
        bool directSwap,
        address foriegnAddress
    ) external {
        // require(settings.isNetworkSupportedChain(chainID) && !hasWrappedForiegnPair[foriegnAddress][chainID] , "A_R");
        require(
            settings.isNetworkSupportedChain(chainID) &&
                !hasWrappedForiegnPair[foriegnAddress][chainID] &&
                _msgSender() == migrator,
            "U_A"
        );

        if (directSwap) {
            isDirectSwap[wrappedAddress][chainID] = true;
            directForiegnAssets[directForiegnCount] = directForiegnAsset(
                wrappedAddress,
                foriegnAddress,
                chainID,
                true
            );
            directForiegnCount++;
        } else {
            foriegnAssets[wrappedAddress] = asset(
                wrappedAddress,
                minAmount,
                maxAmount,
                0,
                0,
                _collectedFees,
                ownedRail,
                manager,
                feeAddress,
                true
            );
            foriegnAssetChainID[wrappedAddress] = chainID;
            foriegnPair[wrappedAddress] = foriegnAddress;
            foriegnAssetsList.push(wrappedAddress);
        }

        _registerForiegn(foriegnAddress, chainID, wrappedAddress);

        // emit RegisteredForiegnMigration(foriegnAddress , chainID, wrappedAddress);
    }

    function assetLimits(address assetAddress, bool native)
        external
        view
        returns (uint256, uint256)
    {
        if (native)
            return (
                nativeAssets[assetAddress].minAmount,
                nativeAssets[assetAddress].maxAmount
            );
        else
            return (
                foriegnAssets[assetAddress].minAmount,
                foriegnAssets[assetAddress].maxAmount
            );
    }

    function getAssetSupportedChainIds(address assetAddress)
        external
        view
        returns (uint256[] memory)
    {
        return assetSupportedChainIds[assetAddress];
    }

    function getAssetCount() external view returns (uint256, uint256, uint256) {
        return (
            nativeAssetsList.length,
            foriegnAssetsList.length,
            directForiegnCount
        );
    }

    function notPaused() private view returns (bool) {
        require(!paused, "B_P");
        return true;
    }

    function noneZeroAddress(address _address) private pure returns (bool) {
        require(_address != address(0), "A_z");
        return true;
    }

    function onlyAdmin() private view returns (bool) {
        require(
            controller.isAdmin(msg.sender) || msg.sender == controller.owner(),
            "U_A"
        );
        return true;
    }

    function isOwner() internal view returns (bool) {
        require(controller.owner() == _msgSender(), "U_A");
        return true;
    }

    function isAssetManager(address assetAddress, bool native)
        internal
        view
        returns (bool)
    {
        bool isManager;
        if (native) {
            if (
                nativeAssets[assetAddress].manager == _msgSender() &&
                nativeAssets[assetAddress].manager != address(0)
            ) {
                isManager = true;
            }
        } else {
            if (
                foriegnAssets[assetAddress].manager == _msgSender() &&
                foriegnAssets[assetAddress].manager != address(0)
            ) {
                isManager = true;
            }
        }
        return isManager;
    }

    function bridgeData()
        external
        view
        returns (
            address,
            address,
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            migrator,
            newBridge,
            activeMigration,
            migrationInitiationTime,
            migrationDelay,
            fMigrationAt,
            fDirectSwapMigrationAt,
            nMigrationAt,
            feeController
        );
    }
}