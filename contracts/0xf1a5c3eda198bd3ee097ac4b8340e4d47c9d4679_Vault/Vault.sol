/**
 *Submitted for verification at Etherscan.io on 2019-08-21
*/

// File: contracts/interfaces/IERC20Token.sol

pragma solidity ^0.4.23;

/*
    ERC20 Standard Token interface
*/
contract IERC20Token {
    // these functions aren't abstract since the compiler emits automatically generated getter functions as external
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

// File: contracts/interfaces/IContractRegistry.sol

pragma solidity ^0.4.23;

/*
    Contract Registry interface
*/
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);
}

// File: contracts/interfaces/IVault.sol

pragma solidity ^0.4.23;



contract IVault {

    function registry() public view returns (IContractRegistry);

    function auctions(address _borrower) public view returns (address) { _borrower; }
    function vaultExists(address _vault) public view returns (bool) { _vault; }
    function totalBorrowed(address _vault) public view returns (uint256) { _vault; }
    function rawBalanceOf(address _vault) public view returns (uint256) { _vault; }
    function rawDebt(address _vault) public view returns (uint256) { _vault; }
    function rawTotalBalance() public view returns (uint256);
    function rawTotalDebt() public view returns (uint256);
    function collateralBorrowedRatio() public view returns (uint256);
    function amountMinted() public view returns (uint256);

    function debtScalePrevious() public view returns (uint256);
    function debtScaleTimestamp() public view returns (uint256);
    function debtScaleRate() public view returns (int256);
    function balScalePrevious() public view returns (uint256);
    function balScaleTimestamp() public view returns (uint256);
    function balScaleRate() public view returns (int256);
    
    function liquidationRatio() public view returns (uint32);
    function maxBorrowLTV() public view returns (uint32);

    function borrowingEnabled() public view returns (bool);
    function biddingTime() public view returns (uint);

    function setType(bool _type) public;
    function create(address _vault) public;
    function setCollateralBorrowedRatio(uint _newRatio) public;
    function setAmountMinted(uint _amountMinted) public;
    function setLiquidationRatio(uint32 _liquidationRatio) public;
    function setMaxBorrowLTV(uint32 _maxBorrowLTV) public;
    function setDebtScalingRate(int256 _debtScalingRate) public;
    function setBalanceScalingRate(int256 _balanceScalingRate) public;
    function setBiddingTime(uint _biddingTime) public;
    function setRawTotalDebt(uint _rawTotalDebt) public;
    function setRawTotalBalance(uint _rawTotalBalance) public;
    function setRawBalanceOf(address _borrower, uint _rawBalance) public;
    function setRawDebt(address _borrower, uint _rawDebt) public;
    function setTotalBorrowed(address _borrower, uint _totalBorrowed) public;
    function debtScalingFactor() public view returns (uint256);
    function balanceScalingFactor() public view returns (uint256);
    function debtRawToActual(uint256 _raw) public view returns (uint256);
    function debtActualToRaw(uint256 _actual) public view returns (uint256);
    function balanceRawToActual(uint256 _raw) public view returns (uint256);
    function balanceActualToRaw(uint256 _actual) public view returns (uint256);
    function getVaults(address _vault, uint256 _balanceOf) public view returns(address[]);
    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public;
    function oracleValue() public view returns(uint256);
    function emitBorrow(address _borrower, uint256 _amount) public;
    function emitRepay(address _borrower, uint256 _amount) public;
    function emitDeposit(address _borrower, uint256 _amount) public;
    function emitWithdraw(address _borrower, address _to, uint256 _amount) public;
    function emitLiquidate(address _borrower) public;
    function emitAuctionStarted(address _borrower) public;
    function emitAuctionEnded(address _borrower, address _highestBidder, uint256 _highestBid) public;
    function setAuctionAddress(address _borrower, address _auction) public;
}

// File: contracts/interfaces/IPegSettings.sol

pragma solidity ^0.4.23;


contract IPegSettings {

    function authorized(address _address) public view returns (bool) { _address; }
    
    function authorize(address _address, bool _auth) public;
    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public;

}

// File: contracts/interfaces/IPegOracle.sol

pragma solidity ^0.4.23;

contract IPegOracle {
    function getValue() public view returns (uint256);
}

// File: contracts/library/SafeMath.sol

pragma solidity ^0.4.23;

library SafeMath {
    function plus(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        assert(c >= _a);
        return c;
    }

    function plus(int256 _a, int256 _b) internal pure returns (int256) {
        int256 c = _a + _b;
        assert((_b >= 0 && c >= _a) || (_b < 0 && c < _a));
        return c;
    }

    function minus(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_a >= _b);
        return _a - _b;
    }

    function minus(int256 _a, int256 _b) internal pure returns (int256) {
        int256 c = _a - _b;
        assert((_b >= 0 && c <= _a) || (_b < 0 && c > _a));
        return c;
    }

    function times(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }
        uint256 c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function times(int256 _a, int256 _b) internal pure returns (int256) {
        if (_a == 0) {
            return 0;
        }
        int256 c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function toInt256(uint256 _a) internal pure returns (int256) {
        assert(_a <= 2 ** 255);
        return int256(_a);
    }

    function toUint256(int256 _a) internal pure returns (uint256) {
        assert(_a >= 0);
        return uint256(_a);
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function div(int256 _a, int256 _b) internal pure returns (int256) {
        return _a / _b;
    }
}

// File: contracts/interfaces/IOwned.sol

pragma solidity ^0.4.23;

/*
    Owned contract interface
*/
contract IOwned {
    // this function isn't abstract since the compiler emits automatically generated getter functions as external
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
    function setOwner(address _newOwner) public;
}

// File: contracts/interfaces/ISmartToken.sol

pragma solidity ^0.4.23;



/*
    Smart Token interface
*/
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

// File: contracts/interfaces/IPegLogic.sol

pragma solidity ^0.4.23;




contract IPegLogic {

    function adjustCollateralBorrowingRate() public;
    function isInsolvent(IVault _vault, address _borrower) public view returns (bool);
    function actualDebt(IVault _vault, address _address) public view returns(uint256);
    function excessCollateral(IVault _vault, address _borrower) public view returns (int256);
    function availableCredit(IVault _vault, address _borrower) public view returns (int256);
    function getCollateralToken(IVault _vault) public view returns(IERC20Token);
    function getDebtToken(IVault _vault) public view returns(ISmartToken);

}

// File: contracts/interfaces/IAuctionActions.sol

pragma solidity ^0.4.23;


contract IAuctionActions {

    function startAuction(IVault _vault, address _borrower) public;
    function endAuction(IVault _vault, address _borrower) public;

}

// File: contracts/ContractIds.sol

pragma solidity ^0.4.23;

contract ContractIds {
    bytes32 public constant STABLE_TOKEN = "StableToken";
    bytes32 public constant COLLATERAL_TOKEN = "CollateralToken";

    bytes32 public constant PEGUSD_TOKEN = "PEGUSD";

    bytes32 public constant VAULT_A = "VaultA";
    bytes32 public constant VAULT_B = "VaultB";

    bytes32 public constant PEG_LOGIC = "PegLogic";
    bytes32 public constant PEG_LOGIC_ACTIONS = "LogicActions";
    bytes32 public constant AUCTION_ACTIONS = "AuctionActions";

    bytes32 public constant PEG_SETTINGS = "PegSettings";
    bytes32 public constant ORACLE = "Oracle";
    bytes32 public constant FEE_RECIPIENT = "StabilityFeeRecipient";
}

// File: contracts/Helpers.sol

pragma solidity ^0.4.23;










contract Helpers is ContractIds {

    IContractRegistry public registry;

    constructor(IContractRegistry _registry) public {
        registry = _registry;
    }

    modifier authOnly() {
        require(settings().authorized(msg.sender));
        _;
    }

    modifier validate(IVault _vault, address _borrower) {
        require(address(_vault) == registry.addressOf(ContractIds.VAULT_A) || address(_vault) == registry.addressOf(ContractIds.VAULT_B));
        _vault.create(_borrower);
        _;
    }

    function stableToken() internal returns(ISmartToken) {
        return ISmartToken(registry.addressOf(ContractIds.STABLE_TOKEN));
    }

    function collateralToken() internal returns(ISmartToken) {
        return ISmartToken(registry.addressOf(ContractIds.COLLATERAL_TOKEN));
    }

    function PEGUSD() internal returns(IERC20Token) {
        return IERC20Token(registry.addressOf(ContractIds.PEGUSD_TOKEN));
    }

    function vaultA() internal returns(IVault) {
        return IVault(registry.addressOf(ContractIds.VAULT_A));
    }

    function vaultB() internal returns(IVault) {
        return IVault(registry.addressOf(ContractIds.VAULT_B));
    }

    function oracle() internal returns(IPegOracle) {
        return IPegOracle(registry.addressOf(ContractIds.ORACLE));
    }

    function settings() internal returns(IPegSettings) {
        return IPegSettings(registry.addressOf(ContractIds.PEG_SETTINGS));
    }

    function pegLogic() internal returns(IPegLogic) {
        return IPegLogic(registry.addressOf(ContractIds.PEG_LOGIC));
    }

    function auctionActions() internal returns(IAuctionActions) {
        return IAuctionActions(registry.addressOf(ContractIds.AUCTION_ACTIONS));
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public authOnly {
        _token.transfer(_to, _amount);
    }

}

// File: contracts/interfaces/ILogicActions.sol

pragma solidity ^0.4.23;


contract ILogicActions {

    function deposit(IVault _vault, uint256 _amount) public;
    function withdraw(IVault _vault, address _to, uint256 _amount) public;
    function borrow(IVault _vault, uint256 _amount) public;
    function repay(IVault _vault, address _borrower, uint256 _amount) public;
    function repayAuction(IVault _vault, address _borrower, uint256 _amount) public;
    function repayAll(IVault _vault, address _borrower) public;

}

// File: contracts/Auction.sol

pragma solidity ^0.4.23;








contract Auction is ContractIds {
    address public borrower;
    IVault public vault;
    IContractRegistry public registry;
    uint public auctionEndTime;
    uint public auctionStartTime;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public lowestBidRelay;
    uint256 public amountToPay;
    bool ended;

    event HighestBidIncreased(address indexed _bidder, uint256 _amount, uint256 _amountRelay);

    constructor(IContractRegistry _registry, IVault _vault, address _borrower) public {
        registry = _registry;
        borrower = _borrower;
        vault = _vault;
    }

    modifier authOnly() {
        require(IPegSettings(registry.addressOf(ContractIds.PEG_SETTINGS)).authorized(msg.sender), "Unauthorized");
        _;
    }

    function validateBid(uint256 _amount, uint256 _amountRelay) internal {
        if(auctionEndTime > 0)
            require(now <= auctionEndTime, "Auction has already ended");
        else {
            auctionStartTime = now;
            auctionEndTime = now + vault.biddingTime();
        }
        require(_amount == 0 || _amountRelay == 0, "Can't refund collateral and mint relay tokens");
        if(highestBidder != address(0))
            require(_amount > highestBid || _amountRelay < lowestBidRelay, "There already is a higher bid");
        require(vault.balanceActualToRaw(_amount) <= vault.rawBalanceOf(address(this)), "Can't refund more than 100%");
    }

    function bid(uint256 _amount, uint256 _amountRelay) public {
        validateBid(_amount, _amountRelay);
        if(_amountRelay > 0)
            auctionEndTime = auctionStartTime + 172800; // extends to 48 hours auction
        IPegLogic pegLogic = IPegLogic(registry.addressOf(ContractIds.PEG_LOGIC));
        if(amountToPay == 0) amountToPay = pegLogic.actualDebt(vault, address(this));
        IERC20Token token = pegLogic.getDebtToken(vault);
        token.transferFrom(msg.sender, address(this), amountToPay);
        if (highestBidder != address(0)) {
            require(token.transfer(highestBidder, amountToPay), "Error transferring token to last highest bidder.");
        } else {
            ILogicActions logicActions = ILogicActions(registry.addressOf(ContractIds.PEG_LOGIC_ACTIONS));
            if (address(vault) == registry.addressOf(ContractIds.VAULT_B))
                token.approve(address(logicActions), amountToPay);
            logicActions.repayAuction(vault, borrower, amountToPay);
        }
        highestBidder = msg.sender;
        highestBid = _amount;
        lowestBidRelay = _amountRelay;
        emit HighestBidIncreased(msg.sender, _amount, _amountRelay);
    }

    function auctionEnd() public authOnly {
        require(auctionEndTime > 0, "Bidding has not started yet");
        require(now >= auctionEndTime, "Auction end time is in the future");
        require(!ended, "Auction already ended");
        ended = true;
    }

    function hasEnded() public view returns (bool) {
        return auctionEndTime > 0 && now >= auctionEndTime;
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public authOnly {
        _token.transfer(_to, _amount);
    }
}

// File: contracts/Vault.sol

pragma solidity ^0.4.23;









contract Vault is Helpers {
    using SafeMath for uint256;
    using SafeMath for int256;

    IContractRegistry public registry;

    address[] public vaults;
    mapping (address => address) public auctions;
    mapping (address => bool) public vaultExists;
    mapping (address => uint256) public totalBorrowed;
    mapping (address => uint256) public rawBalanceOf;
    mapping (address => uint256) public rawDebt;
    uint256 public rawTotalBalance;
    uint256 public rawTotalDebt;
    uint256 public collateralBorrowedRatio;
    uint256 public amountMinted;

    uint256 public debtScalePrevious = 1e18;
    uint256 public debtScaleTimestamp = now;
    int256 public debtScaleRate;

    uint256 public balScalePrevious = 1e18;
    uint256 public balScaleTimestamp = now;
    int256 public balScaleRate;

    uint32 public liquidationRatio = 850000;
    uint32 public maxBorrowLTV = 500000;

    bool public borrowingEnabled = true;

    uint public biddingTime = 10800; // 3 hours

    event AmountMinted(uint256 _old, uint256 _new);
    event Create(address indexed _borrower);
    event DebtScalingRateUpdate(int _old, int _new);
    event BalanceScalingRateUpdate(int _old, int _new);
    event CollateralBorrowedRatio(uint _old, uint _new);
    event LiquidationRatioUpdate(int _old, int _new);
    event MaxBorrowUpdate(uint32 _old, uint32 _new);
    event Deposit(address indexed _borrower, uint256 _amount);
    event Liquidate(address indexed _borrower);
    event Borrow(address indexed _borrower, uint256 _amount);
    event Repay(address indexed _borrower, uint256 _amount);
    event Withdraw(address indexed _borrower, address indexed _to, uint256 _amount);
    event AuctionStarted(address indexed _borrower);
    event AuctionEnded(address indexed _borrower, address indexed _highestBidder, uint256 _highestBid);
   
    constructor(IContractRegistry _registry) public Helpers(_registry) {
        registry = _registry;
    }

    function setBorrowingEnabled(bool _enabled) public authOnly {
        borrowingEnabled = _enabled;
    }

    function create(address _borrower) public authOnly {
        if(vaultExists[_borrower] == false) {
            vaults.push(_borrower);
            vaultExists[_borrower] = true;
            emit Create(_borrower);
        }
    }

    function setCollateralBorrowedRatio(uint _newRatio) public authOnly {
        emit CollateralBorrowedRatio(collateralBorrowedRatio, _newRatio);
        collateralBorrowedRatio = _newRatio;
    }

    function setAmountMinted(uint _amountMinted) public authOnly {
        emit AmountMinted(amountMinted, _amountMinted);
        amountMinted = _amountMinted;
    }

    function setLiquidationRatio(uint32 _liquidationRatio) public authOnly {
        emit LiquidationRatioUpdate(liquidationRatio, _liquidationRatio);
        liquidationRatio = _liquidationRatio;
    }

    function setMaxBorrowLTV(uint32 _maxBorrowLTV) public authOnly {
        emit MaxBorrowUpdate(maxBorrowLTV, _maxBorrowLTV);
        maxBorrowLTV = _maxBorrowLTV;
    }

    function setDebtScalingRate(int256 _debtScalingRate) public authOnly {
        emit DebtScalingRateUpdate(debtScaleRate, _debtScalingRate);
        debtScalePrevious = debtScalingFactor();
        debtScaleTimestamp = now;
        debtScaleRate = _debtScalingRate;
    }

    function setBalanceScalingRate(int256 _balanceScalingRate) public authOnly {
        emit BalanceScalingRateUpdate(balScaleRate, _balanceScalingRate);
        balScalePrevious = balanceScalingFactor();
        balScaleTimestamp = now;
        balScaleRate = _balanceScalingRate;
    }

    function setBiddingTime(uint _biddingTime) public authOnly {
        biddingTime = _biddingTime;
    }

    function setRawTotalBalance(uint _rawTotalBalance) public authOnly {
        rawTotalBalance = _rawTotalBalance;
    }

    function setRawTotalDebt(uint _rawTotalDebt) public authOnly {
        rawTotalDebt = _rawTotalDebt;
    }

    function setRawBalanceOf(address _borrower, uint _rawBalance) public authOnly {
        rawBalanceOf[_borrower] = _rawBalance;
    }

    function setRawDebt(address _borrower, uint _rawDebt) public authOnly {
        rawDebt[_borrower] = _rawDebt;
    }

    function setTotalBorrowed(address _borrower, uint _totalBorrowed) public authOnly {
        totalBorrowed[_borrower] = _totalBorrowed;
    }

    function debtScalingFactor() public view returns (uint) {
        return uint(int(debtScalePrevious).plus(debtScaleRate.times(int(now.minus(debtScaleTimestamp)))));
    }

    function balanceScalingFactor() public view returns (uint) {
        return uint(int(balScalePrevious).plus(balScaleRate.times(int(now.minus(balScaleTimestamp)))));
    }

    function debtRawToActual(uint256 _raw) public view returns(uint256) {
        return _raw.times(1e18) / debtScalingFactor();
    }

    function debtActualToRaw(uint256 _actual) public view returns(uint256) {
        return _actual.times(debtScalingFactor()) / 1e18;
    }

    function balanceRawToActual(uint256 _raw) public view returns(uint256) {
        return _raw.times(1e18) / balanceScalingFactor();
    }

    function balanceActualToRaw(uint256 _actual) public view returns(uint256) {
        return _actual.times(balanceScalingFactor()) / 1e18;
    }

    function getVaults() public view returns (address[]) {
        return vaults;
    }

    function transferERC20Token(IERC20Token _token, address _to, uint256 _amount) public authOnly {
        _token.transfer(_to, _amount);
    }

    function oracleValue() public view returns(uint) {
        if (address(this) == address(vaultA())) {
            return oracle().getValue();
        } else {
            return 1e12 / oracle().getValue();
        }
    }

    function emitRepay(address _borrower, uint256 _amount) public authOnly {
        emit Repay(_borrower, _amount);
    }

    function emitDeposit(address _borrower, uint256 _amount) public authOnly {
        emit Deposit(_borrower, _amount);
    }

    function emitWithdraw(address _borrower, address _to, uint256 _amount) public authOnly {
        emit Withdraw(_borrower, _to, _amount);
    }

    function emitBorrow(address _borrower, uint256 _amount) public authOnly {
        emit Borrow(_borrower, _amount);
    }

    function emitLiquidate(address _borrower) public authOnly {
        emit Liquidate(_borrower);
    }

    function emitAuctionStarted(address _borrower) public authOnly {
        emit AuctionStarted(_borrower);
    }

    function emitAuctionEnded(address _borrower, address _highestBidder, uint256 _highestBid) public authOnly {
        emit AuctionEnded(_borrower, _highestBidder, _highestBid);
    }
    
    function setAuctionAddress(address _borrower, address _auction) public authOnly {
        auctions[_borrower] = _auction;
    }

}