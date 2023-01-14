import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ILendingModule} from '../interfaces/ILendingModule.sol';
import {ILendingStorageManager} from '../interfaces/ILendingStorageManager.sol';
import {ICompoundToken, IComptroller} from '../interfaces/ICToken.sol';
import {ExponentialNoError} from '../libs/ExponentialNoError.sol';
import {IRewardsController} from '../interfaces/IRewardsController.sol';
import {Address} from '../../../@openzeppelin/contracts/utils/Address.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {
  SynthereumPoolMigrationFrom
} from '../../synthereum-pool/common/migration/PoolMigrationFrom.sol';

contract CompoundModule is ILendingModule, ExponentialNoError {
  using SafeERC20 for IERC20;
  using SafeERC20 for ICompoundToken;

  function deposit(
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata,
    uint256 _amount
  )
    external
    override
    returns (
      uint256 totalInterest,
      uint256 tokensOut,
      uint256 tokensTransferred
    )
  {
    // proxy should have received collateral from the pool
    IERC20 collateral = IERC20(_poolData.collateral);
    require(collateral.balanceOf(address(this)) >= _amount, 'Wrong balance');

    // initialise compound interest token
    ICompoundToken cToken = ICompoundToken(_poolData.interestBearingToken);

    // get tokens balance before
    uint256 cTokenBalanceBefore = cToken.balanceOf(address(this));

    uint256 totalPrevDeposit;

    // calculate accrued interest since last operation
    (totalInterest, totalPrevDeposit) = calculateGeneratedInterest(
      msg.sender,
      _poolData,
      0,
      cToken,
      true
    );

    // approve and deposit underlying
    collateral.safeIncreaseAllowance(address(cToken), _amount);
    require(cToken.mint(_amount) == 0, 'Failed mint');

    uint256 cTokenBalanceAfter = cToken.balanceOf(address(this));

    // set return values
    tokensTransferred = cTokenBalanceAfter - cTokenBalanceBefore;

    // transfer cToken to pool
    cToken.transfer(msg.sender, tokensTransferred);

    tokensOut =
      cToken.balanceOfUnderlying(msg.sender) -
      totalPrevDeposit -
      totalInterest;
  }

  function withdraw(
    ILendingStorageManager.PoolStorage calldata _poolData,
    address _pool,
    bytes calldata,
    uint256 _cTokenAmount,
    address _recipient
  )
    external
    override
    returns (
      uint256 totalInterest,
      uint256 tokensOut,
      uint256 tokensTransferred
    )
  {
    // initialise compound interest token
    ICompoundToken cToken = ICompoundToken(_poolData.interestBearingToken);

    IERC20 collateralToken = IERC20(_poolData.collateral);
    uint256 totalPrevDeposit;

    // calculate accrued interest since last operation
    (totalInterest, totalPrevDeposit) = calculateGeneratedInterest(
      _pool,
      _poolData,
      _cTokenAmount,
      cToken,
      false
    );

    // get balances before redeeming
    uint256 collBalanceBefore = collateralToken.balanceOf(address(this));

    // redeem
    require(cToken.redeem(_cTokenAmount) == 0, 'Failed withdraw');

    // get balances after redeeming
    uint256 collBalanceAfter = collateralToken.balanceOf(address(this));

    // set return values
    tokensOut =
      totalPrevDeposit +
      totalInterest -
      cToken.balanceOfUnderlying(_pool);
    tokensTransferred = collBalanceAfter - collBalanceBefore;

    // transfer underlying
    collateralToken.safeTransfer(_recipient, tokensTransferred);
  }

  function totalTransfer(
    address _oldPool,
    address _newPool,
    address _collateral,
    address _interestToken,
    bytes calldata _extraArgs
  )
    external
    override
    returns (uint256 prevTotalCollateral, uint256 actualTotalCollateral)
  {
    uint256 prevTotalcTokens =
      SynthereumPoolMigrationFrom(_oldPool).migrateTotalFunds(_newPool);

    Exp memory exchangeRate =
      Exp({mantissa: ICompoundToken(_interestToken).exchangeRateCurrent()});
    prevTotalCollateral = mul_ScalarTruncate(exchangeRate, prevTotalcTokens);

    actualTotalCollateral = ICompoundToken(_interestToken).balanceOfUnderlying(
      _newPool
    );
  }

  function claimRewards(
    bytes calldata,
    address _collateral,
    address _bearingToken,
    address _recipient
  ) external virtual override {
    revert('Claim rewards not supported');
  }

  function getUpdatedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _extraArgs
  ) external override returns (uint256 totalInterest) {
    // instantiate cToken
    ICompoundToken cToken = ICompoundToken(_poolData.interestBearingToken);

    // calculate collateral
    uint256 totCollateral = cToken.balanceOfUnderlying(_poolAddress);

    totalInterest =
      totCollateral -
      _poolData.collateralDeposited -
      _poolData.unclaimedDaoCommission -
      _poolData.unclaimedDaoJRT;
  }

  function getAccumulatedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _poolData,
    bytes calldata _extraArgs
  ) external view override returns (uint256 totalInterest) {
    ICompoundToken cToken = ICompoundToken(_poolData.interestBearingToken);

    (, uint256 tokenBalance, , uint256 excMantissa) =
      cToken.getAccountSnapshot(_poolAddress);
    Exp memory exchangeRate = Exp({mantissa: excMantissa});

    uint256 totCollateral = mul_ScalarTruncate(exchangeRate, tokenBalance);

    totalInterest =
      totCollateral -
      _poolData.collateralDeposited -
      _poolData.unclaimedDaoCommission -
      _poolData.unclaimedDaoJRT;
  }

  function getInterestBearingToken(
    address _collateral,
    bytes calldata _extraArgs
  ) external view override returns (address token) {
    IComptroller comptroller = IComptroller(abi.decode(_extraArgs, (address)));
    address[] memory markets = comptroller.getAllMarkets();

    for (uint256 i = 0; i < markets.length; i++) {
      try ICompoundToken(markets[i]).underlying() returns (address coll) {
        if (coll == _collateral) {
          token = markets[i];
          break;
        }
      } catch {}
    }
    require(token != address(0), 'Token not found');
  }

  function collateralToInterestToken(
    uint256 _collateralAmount,
    address,
    address _interestToken,
    bytes calldata
  ) external view override returns (uint256 interestTokenAmount) {
    uint256 excMantissa = ICompoundToken(_interestToken).exchangeRateStored();
    Exp memory exchangeRate = Exp({mantissa: excMantissa});

    return div_(_collateralAmount, exchangeRate);
  }

  function interestTokenToCollateral(
    uint256 _interestTokenAmount,
    address,
    address _interestToken,
    bytes calldata _extraArgs
  ) external view override returns (uint256 collateralAmount) {
    uint256 excMantissa = ICompoundToken(_interestToken).exchangeRateStored();
    Exp memory exchangeRate = Exp({mantissa: excMantissa});
    return mul_ScalarTruncate(exchangeRate, _interestTokenAmount);
  }

  function calculateGeneratedInterest(
    address _poolAddress,
    ILendingStorageManager.PoolStorage calldata _pool,
    uint256 _cTokenAmount,
    ICompoundToken _cToken,
    bool _isDeposit
  )
    internal
    returns (uint256 totalInterestGenerated, uint256 totalPrevDeposit)
  {
    // get cToken pool balance and rate
    Exp memory exchangeRate = Exp({mantissa: _cToken.exchangeRateCurrent()});
    uint256 cTokenBalancePool = _cToken.balanceOf(_poolAddress);

    // determine amount of collateral the pool had before this operation
    uint256 poolBalance =
      mul_ScalarTruncate(
        exchangeRate,
        _isDeposit ? cTokenBalancePool : cTokenBalancePool + _cTokenAmount
      );

    totalPrevDeposit =
      _pool.collateralDeposited +
      _pool.unclaimedDaoCommission +
      _pool.unclaimedDaoJRT;

    totalInterestGenerated = poolBalance - totalPrevDeposit;
  }
}