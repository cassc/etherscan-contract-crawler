//SPDX-License-Identifier: LICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.7.0;
pragma abicoder v2;
// We import this library to be able to use console.log
// import "hardhat/console.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/PriceOracle.sol";
import "./interfaces/ILimitManager.sol";
import "./interfaces/ILevelManager.sol";
import "./interfaces/IMarketManager.sol";
import "./interfaces/ICashBackManager.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/ERC20Interface.sol";
import "./interfaces/IConverter.sol";
import "./libraries/SafeMath.sol";

import "./OwnerConstants.sol";
import "./SignerRole.sol";

// This is the main building block for smart contracts.
contract OkseCard is OwnerConstants, SignerRole {
    //  bytes4 public constant PAY_MONTHLY_FEE = bytes4(keccak256(bytes('payMonthlyFee')));
    bytes4 public constant PAY_MONTHLY_FEE = 0x529a8d6c;
    //  bytes4 public constant WITHDRAW = bytes4(keccak256(bytes('withdraw')));
    bytes4 public constant WITHDRAW = 0x855511cc;
    //  bytes4 public constant BUYGOODS = bytes4(keccak256(bytes('buyGoods')));
    bytes4 public constant BUYGOODS = 0xa8fd19f2;
    //  bytes4 public constant SET_USER_MAIN_MARKET = bytes4(keccak256(bytes('setUserMainMarket')));
    bytes4 public constant SET_USER_MAIN_MARKET = 0x4a22142e;

    // uint256 public constant CARD_VALIDATION_TIME = 10 minutes; // 30 days in prodcution
    uint256 public constant CARD_VALIDATION_TIME = 1 days; // 30 days in prodcution

    using SafeMath for uint256;
    address public immutable converter;
    address public swapper;

    // Price oracle address, which is used for verification of swapping assets amount
    address public priceOracle;
    address public limitManager;
    address public levelManager;
    address public marketManager;
    address public cashbackManager;

    // Governor can set followings:
    address public governorAddress; // Governance address

    /*** Main Actions ***/
    // user's deposited balance.
    // user  => ( market => balances)
    mapping(address => mapping(address => uint256)) public usersBalances;

    mapping(address => uint256) public userValidTimes;

    //prevent reentrancy attack
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    bool private initialized;

    // uint256 public timeDiff;
    struct SignKeys {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    struct SignData {
        bytes4 method;
        uint256 id;
        address market;
        address userAddr;
        uint256 amount;
        uint256 validTime;
    }
    // emit event

    event UserBalanceChanged(
        address indexed userAddr,
        address indexed market,
        uint256 amount
    );

    event GovernorAddressChanged(
        address indexed previousGovernor,
        address indexed newGovernor
    );
    event MonthlyFeePaid(
        uint256 id,
        address userAddr,
        uint256 userValidTime,
        uint256 usdAmount
    );
    event UserDeposit(address userAddr, address market, uint256 amount);
    event UserWithdraw(
        uint256 id,
        address userAddr,
        address market,
        uint256 amount,
        uint256 remainedBalance
    );
    event SignerBuyGoods(
        uint256 id,
        address signer1,
        address signer2,
        address market,
        address userAddr,
        uint256 usdAmount
    );
    event UserMainMarketChanged(
        uint256 id,
        address userAddr,
        address market,
        address beforeMarket
    );
    event ContractAddressChanged(
        address priceOracle,
        address swapper,
        address limitManager,
        address levelManager,
        address marketManager,
        address cashbackManager
    );
    event WithdrawTokens(address token, address to, uint256 amount);

    // verified
    /**
     * Contract initialization.
     *
     * The `constructor` is executed only once when the contract is created.
     * The `public` modifier makes a function callable from outside the contract.
     */
    constructor(
        address _converter,
        address _initialSigner
    ) SignerRole(_initialSigner) {
        converter = _converter;
        // The totalSupply is assigned to transaction sender, which is the account
        // that is deploying the contract.
    }

    // verified
    receive() external payable {
        // require(msg.sender == WETH, 'Not WETH9');
    }

    // verified
    function initialize(
        address _priceOracle,
        address _limitManager,
        address _levelManager,
        address _marketManager,
        address _cashbackManager,
        address _financialAddress,
        address _masterAddress,
        address _treasuryAddress,
        address _governorAddress,
        address _monthlyFeeAddress,
        address _stakeContractAddress,
        address _swapper
    ) public {
        require(!initialized, "ai");
        // owner = _owner;
        // _addSigner(_owner);
        priceOracle = _priceOracle;
        limitManager = _limitManager;
        levelManager = _levelManager;
        marketManager = _marketManager;
        cashbackManager = _cashbackManager;
        treasuryAddress = _treasuryAddress;
        financialAddress = _financialAddress;
        masterAddress = _masterAddress;
        governorAddress = _governorAddress;
        monthlyFeeAddress = _monthlyFeeAddress;
        stakeContractAddress = _stakeContractAddress;
        swapper = _swapper;
        //private variables initialize.
        _status = _NOT_ENTERED;
        //initialize OwnerConstants arrays

        stakePercent = 15 * (100 + 15);
        buyFeePercent = 250;
        buyTxFee = 0.7 ether;
        withdrawFeePercent = 0;
        monthlyFeeAmount = 6.99 ether;
        okseMonthlyProfit = 1000;
        initialized = true;
    }

    /// modifier functions
    // verified
    modifier onlyGovernor() {
        require(_msgSender() == governorAddress, "og");
        _;
    }
    // // verified
    modifier marketEnabled(address market) {
        require(IMarketManager(marketManager).marketEnable(market), "mdnd");
        _;
    }
    // verified
    modifier noExpired(address userAddr) {
        require(!getUserExpired(userAddr), "user expired");
        _;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    // verified
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "rc");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier validSignOfUser(
        SignData calldata sign_data,
        SignKeys calldata sign_key
    ) {
        require(
            sign_data.userAddr == getecrecover(sign_data, sign_key),
            "ssst"
        );
        _;
    }
    modifier noEmergency() {
        require(!IMarketManager(marketManager).emergencyStop(), "stopped");
        _;
    }

    function getUserOkseBalance(
        address userAddr
    ) external view returns (uint256) {
        return usersBalances[userAddr][IMarketManager(marketManager).OKSE()];
    }

    // verified
    function getUserExpired(address _userAddr) public view returns (bool) {
        // if monthly fee is zero then user never expired
        if (monthlyFeeAmount == 0) {
            return false;
        }
        if (userValidTimes[_userAddr].add(25 days) > block.timestamp) {
            return false;
        }
        return true;
    }

    // set Governance address
    function setGovernor(address newGovernor) public onlyGovernor {
        address oldGovernor = governorAddress;
        governorAddress = newGovernor;
        emit GovernorAddressChanged(oldGovernor, newGovernor);
    }

    // verified
    function updateSigner(
        address _signer,
        bool bAddOrRemove
    ) public onlyGovernor {
        if (bAddOrRemove) {
            _addSigner(_signer);
        } else {
            _removeSigner(_signer);
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function onUpdateUserBalance(
        address userAddr,
        address market,
        uint256 amount,
        uint256 beforeAmount
    ) internal returns (bool) {
        emit UserBalanceChanged(userAddr, market, amount);
        if (market != IMarketManager(marketManager).OKSE()) return true;
        return
            ILevelManager(levelManager).updateUserLevel(userAddr, beforeAmount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // newly verified
    function deposit(
        address market,
        uint256 amount
    ) public marketEnabled(market) nonReentrant noEmergency {
        TransferHelper.safeTransferFrom(
            market,
            msg.sender,
            address(this),
            amount
        );
        _addUserBalance(market, msg.sender, amount);
        emit UserDeposit(msg.sender, market, amount);
    }

    // newly verified
    function depositETH() public payable nonReentrant {
        address WETH = IMarketManager(marketManager).WETH();
        require(IMarketManager(marketManager).marketEnable(WETH), "me");
        IWETH9(WETH).deposit{value: msg.value}();
        _addUserBalance(WETH, msg.sender, msg.value);
        emit UserDeposit(msg.sender, WETH, msg.value);
    }

    // verified
    function _addUserBalance(
        address market,
        address userAddr,
        uint256 amount
    ) internal marketEnabled(market) {
        uint256 beforeAmount = usersBalances[userAddr][market];
        usersBalances[userAddr][market] = usersBalances[userAddr][market].add(
            amount
        );
        onUpdateUserBalance(
            userAddr,
            market,
            usersBalances[userAddr][market],
            beforeAmount
        );
    }

    // newly verified
    function setUserMainMarket(
        uint256 id,
        address market,
        uint256 validTime,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        address userAddr = msg.sender;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(
            isSigner(
                ecrecover(
                    toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                this,
                                SET_USER_MAIN_MARKET,
                                id,
                                userAddr,
                                market,
                                chainId,
                                uint256(0),
                                validTime
                            )
                        )
                    ),
                    v,
                    r,
                    s
                )
            ),
            "summ"
        );
        require(signatureId[id] == false, "pru");
        signatureId[id] = true;
        require(validTime > block.timestamp, "expired");
        address beforeMarket = IMarketManager(marketManager).getUserMainMarket(
            userAddr
        );
        IMarketManager(marketManager).setUserMainMakret(userAddr, market);
        emit UserMainMarketChanged(id, userAddr, market, beforeMarket);
    }

    // verified
    function payMonthlyFee(
        uint256 id,
        SignData calldata _data,
        SignKeys calldata user_key,
        address market
    )
        public
        nonReentrant
        marketEnabled(market)
        noEmergency
        validSignOfUser(_data, user_key)
        onlySigner
    {
        address userAddr = _data.userAddr;
        require(userValidTimes[userAddr] <= block.timestamp, "e");
        require(monthlyFeeAmount <= _data.amount, "over paid");
        require(
            signatureId[id] == false && _data.method == PAY_MONTHLY_FEE,
            "pru"
        );
        signatureId[id] = true;
        // increase valid period

        // extend user's valid time
        uint256 _monthlyFee = getMonthlyFeeAmount(
            market == IMarketManager(marketManager).OKSE()
        );
        uint256 _tempVal = _monthlyFee;
        userValidTimes[userAddr] = block.timestamp.add(CARD_VALIDATION_TIME);

        if (stakeContractAddress != address(0)) {
            _tempVal = (_monthlyFee.mul(10000)).div(stakePercent.add(10000));
        }

        uint256 beforeAmount = usersBalances[userAddr][market];
        calculateAmount(
            market,
            userAddr,
            _tempVal,
            monthlyFeeAddress,
            stakeContractAddress,
            stakePercent
        );
        onUpdateUserBalance(
            userAddr,
            market,
            usersBalances[userAddr][market],
            beforeAmount
        );
        emit MonthlyFeePaid(
            id,
            userAddr,
            userValidTimes[userAddr],
            _monthlyFee
        );
    }

    // newly verified
    function withdraw(
        uint256 id,
        address market,
        uint256 amount,
        uint256 validTime,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        address userAddr = msg.sender;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        require(
            isSigner(
                ecrecover(
                    toEthSignedMessageHash(
                        keccak256(
                            abi.encodePacked(
                                this,
                                WITHDRAW,
                                id,
                                userAddr,
                                market,
                                chainId,
                                amount,
                                validTime
                            )
                        )
                    ),
                    v,
                    r,
                    s
                )
            ),
            "ssst"
        );
        require(signatureId[id] == false, "pru");
        signatureId[id] = true;
        require(validTime > block.timestamp, "expired");
        uint256 beforeAmount = usersBalances[userAddr][market];
        // require(beforeAmount >= amount, "ib");
        usersBalances[userAddr][market] = beforeAmount.sub(amount);
        address WETH = IMarketManager(marketManager).WETH();
        if (market == WETH) {
            IWETH9(WETH).withdraw(amount);
            if (treasuryAddress != address(0)) {
                uint256 feeAmount = (amount.mul(withdrawFeePercent)).div(10000);
                if (feeAmount > 0) {
                    TransferHelper.safeTransferETH(treasuryAddress, feeAmount);
                }
                TransferHelper.safeTransferETH(
                    msg.sender,
                    amount.sub(feeAmount)
                );
            } else {
                TransferHelper.safeTransferETH(msg.sender, amount);
            }
        } else {
            if (treasuryAddress != address(0)) {
                uint256 feeAmount = (amount.mul(withdrawFeePercent)).div(10000);
                if (feeAmount > 0) {
                    TransferHelper.safeTransfer(
                        market,
                        treasuryAddress,
                        feeAmount
                    );
                }
                TransferHelper.safeTransfer(
                    market,
                    msg.sender,
                    amount.sub(feeAmount)
                );
            } else {
                TransferHelper.safeTransfer(market, msg.sender, amount);
            }
        }
        uint256 userBal = usersBalances[userAddr][market];
        onUpdateUserBalance(userAddr, market, userBal, beforeAmount);
        emit UserWithdraw(id, userAddr, market, amount, userBal);
    }

    // decimal of usdAmount is 18
    // newly verified
    function buyGoods(
        SignData calldata _data,
        SignKeys[2] calldata signer_key
    )
        external
        nonReentrant
        marketEnabled(_data.market)
        noExpired(_data.userAddr)
        noEmergency
    {
        address[2] memory signers = [
            getecrecover(_data, signer_key[0]),
            getecrecover(_data, signer_key[1])
        ];
        require(
            isSigner(signers[0]) &&
                isSigner(signers[1]) &&
                (signers[0] != signers[1]),
            "is"
        );
        require(
            signatureId[_data.id] == false && _data.method == BUYGOODS,
            "pru"
        );
        signatureId[_data.id] = true;
        if (_data.market == IMarketManager(marketManager).OKSE()) {
            require(IMarketManager(marketManager).oksePaymentEnable(), "jsy");
        }
        require(
            IMarketManager(marketManager).getUserMainMarket(_data.userAddr) ==
                _data.market,
            "jsy2"
        );
        uint256 spendAmount = _makePayment(
            _data.market,
            _data.userAddr,
            _data.amount
        );
        cashBack(_data.userAddr, spendAmount);
        emit SignerBuyGoods(
            _data.id,
            signers[0],
            signers[1],
            _data.market,
            _data.userAddr,
            _data.amount
        );
    }

    // deduce user assets using usd amount
    // decimal of usdAmount is 18
    // verified
    function _makePayment(
        address market,
        address userAddr,
        uint256 usdAmount
    ) internal returns (uint256 spendAmount) {
        uint256 beforeAmount = usersBalances[userAddr][market];
        spendAmount = calculateAmount(
            market,
            userAddr,
            usdAmount,
            masterAddress,
            treasuryAddress,
            buyFeePercent
        );
        ILimitManager(limitManager).updateUserSpendAmount(userAddr, usdAmount);

        onUpdateUserBalance(
            userAddr,
            market,
            usersBalances[userAddr][market],
            beforeAmount
        );
    }

    // calculate aseet amount from market and required usd amount
    // decimal of usdAmount is 18
    // spendAmount is decimal 18
    function calculateAmount(
        address market,
        address userAddr,
        uint256 usdAmount,
        address targetAddress,
        address feeAddress,
        uint256 feePercent
    ) internal returns (uint256 spendAmount) {
        uint256 _amount;
        address USDC = IMarketManager(marketManager).USDC();
        if (feeAddress != address(0)) {
            _amount = usdAmount.add((usdAmount.mul(feePercent)).div(10000)).add(
                buyTxFee
            );
        } else {
            _amount = usdAmount;
        }
        // change _amount to USDC asset amounts
        uint256 assetAmountIn = IConverter(converter).getAssetAmount(
            market,
            _amount,
            priceOracle
        );
        assetAmountIn = assetAmountIn.add(
            (assetAmountIn.mul(IMarketManager(marketManager).slippage())).div(
                10000
            )
        );
        _amount = IConverter(converter).convertUsdAmountToAssetAmount(
            _amount,
            USDC
        );
        uint256 userBal = usersBalances[userAddr][market];
        if (market != USDC) {
            // we need to change somehting here, because if there are not pair {market, USDC} , then we have to add another path
            // so please check the path is exist and if no, please add market, weth, usdc to path
            address[] memory path = ISwapper(swapper).getOptimumPath(
                market,
                USDC
            );
            uint256[] memory amounts = ISwapper(swapper).getAmountsIn(
                _amount,
                path
            );

            require(amounts[0] < assetAmountIn, "ua");
            usersBalances[userAddr][market] = userBal.sub(amounts[0]);
            TransferHelper.safeTransfer(
                path[0],
                ISwapper(swapper).GetReceiverAddress(path),
                amounts[0]
            );
            // reuse userBal variable to reduce variable number , which prevent "stack too deep error"
            userBal = ERC20Interface(market).balanceOf(
                address(this)
            );
            ISwapper(swapper)._swap(amounts, path, address(this));
            // calculate real deduced balance, which is useful to use uniswapv3, 1inch
            checkUserBalance(userBal, userAddr, market);
        } else {
            // require(_amount <= usersBalances[userAddr][market], "uat");
            require(_amount < assetAmountIn, "au");
            usersBalances[userAddr][market] = userBal.sub(_amount);
        }
        require(targetAddress != address(0), "mis");
        uint256 usdcAmount = IConverter(converter)
            .convertUsdAmountToAssetAmount(usdAmount, USDC);
        require(_amount >= usdcAmount, "sp");
        TransferHelper.safeTransfer(USDC, targetAddress, usdcAmount);
        uint256 fee = _amount.sub(usdcAmount);
        if (feeAddress != address(0))
            TransferHelper.safeTransfer(USDC, feeAddress, fee);
        spendAmount = IConverter(converter).convertAssetAmountToUsdAmount(
            _amount,
            USDC
        );
    }

    function checkUserBalance(
        uint256 beforeBalance,
        address userAddr,
        address market
    ) internal {
        uint256 laterBalance = ERC20Interface(market).balanceOf(address(this));
        if (laterBalance > beforeBalance) {
            uint256 userBal = usersBalances[userAddr][market];
            usersBalances[userAddr][market] = userBal.add(
                laterBalance.sub(beforeBalance)
            );
        }
    }

    function cashBack(address userAddr, uint256 usdAmount) internal {
        if (!ICashBackManager(cashbackManager).cashBackEnable()) return;
        uint256 cashBackPercent = ICashBackManager(cashbackManager)
            .getCashBackPercent(
                ILevelManager(levelManager).getUserLevel(userAddr)
            );
        address OKSE = IMarketManager(marketManager).OKSE();
        uint256 okseAmount = IConverter(converter).getAssetAmount(
            OKSE,
            (usdAmount.mul(cashBackPercent)).div(10000),
            priceOracle
        );
        // require(ERC20Interface(OKSE).balanceOf(address(this)) >= okseAmount , "insufficient OKSE");
        if (usersBalances[financialAddress][OKSE] > okseAmount) {
            usersBalances[financialAddress][OKSE] = usersBalances[
                financialAddress
            ][OKSE].sub(okseAmount);
            //needs extra check that owner deposited how much OKSE for cashBack
            _addUserBalance(OKSE, userAddr, okseAmount);
        }
    }

    // verified
    function getUserAssetAmount(
        address userAddr,
        address market
    ) public view returns (uint256) {
        return usersBalances[userAddr][market];
    }

    // verified
    function encodePackedData(
        SignData calldata _data
    ) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            keccak256(
                abi.encodePacked(
                    this,
                    _data.method,
                    _data.id,
                    _data.userAddr,
                    _data.market,
                    chainId,
                    _data.amount,
                    _data.validTime
                )
            );
    }

    // verified
    function getecrecover(
        SignData calldata _data,
        SignKeys calldata key
    ) public view returns (address) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return
            ecrecover(
                toEthSignedMessageHash(
                    keccak256(
                        abi.encodePacked(
                            this,
                            _data.method,
                            _data.id,
                            _data.userAddr,
                            _data.market,
                            chainId,
                            _data.amount,
                            _data.validTime
                        )
                    )
                ),
                key.v,
                key.r,
                key.s
            );
    }

    // verified
    function setContractAddress(
        bytes calldata signData,
        bytes calldata keys
    ) public validSignOfOwner(signData, keys, "setContractAddress") {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (
            address _priceOracle,
            address _swapper,
            address _limitManager,
            address _levelManager,
            address _marketManager,
            address _cashbackManager
        ) = abi.decode(
                params,
                (address, address, address, address, address, address)
            );
        priceOracle = _priceOracle;
        swapper = _swapper;
        limitManager = _limitManager;
        levelManager = _levelManager;
        marketManager = _marketManager;
        cashbackManager = _cashbackManager;
        emit ContractAddressChanged(
            priceOracle,
            swapper,
            limitManager,
            levelManager,
            marketManager,
            cashbackManager
        );
    }

    // owner function
    function withdrawTokens(
        bytes calldata signData,
        bytes calldata keys
    ) public validSignOfOwner(signData, keys, "withdrawTokens") {
        (, , , bytes memory params) = abi.decode(
            signData,
            (bytes4, uint256, uint256, bytes)
        );
        (address token, address to) = abi.decode(params, (address, address));

        require(!IMarketManager(marketManager).isMarketExist(token), "me");
        uint256 amount;
        if (token == address(0)) {
            amount = address(this).balance;
            TransferHelper.safeTransferETH(to, amount);
        } else {
            amount = ERC20Interface(token).balanceOf(address(this));
            TransferHelper.safeTransfer(token, to, amount);
        }
        emit WithdrawTokens(token, to, amount);
    }
}