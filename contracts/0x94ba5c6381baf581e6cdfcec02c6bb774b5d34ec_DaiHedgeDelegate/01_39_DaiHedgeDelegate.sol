// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../abstract/JBOperatable.sol';

import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBFundingCycleDataSource.sol';
import '../interfaces/IJBOperatorStore.sol';
import '../interfaces/IJBPayDelegate.sol';
import '../interfaces/IJBPaymentTerminal.sol';
import '../interfaces/IJBRedemptionDelegate.sol';
import '../interfaces/IJBSingleTokenPaymentTerminalStore.sol';
import '../libraries/JBCurrencies.sol';
import '../libraries/JBOperations.sol';
import '../libraries/JBTokens.sol';
import '../structs/JBDidPayData.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IWETH9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

interface IDaiHedgeDelegate {
  function setHedgeParameters(
    uint256 _projectId,
    bool _applyHedge,
    uint256 _ethShare,
    uint256 _balanceThreshold,
    uint256 _ethThreshold,
    uint256 _usdThreshold,
    HedgeFlags memory _flags
  ) external;
}

struct HedgeFlags {
  bool liveQuote;
  /**
   * @dev Use default Ether payment terminal, otherwise JBDirectory will be queries.
   */
  bool defaultEthTerminal;
  /**
   * @dev Use default DAI payment terminal, otherwise JBDirectory will be queries.
   */
  bool defaultUsdTerminal;
}

struct HedgeSettings {
  uint256 ethThreshold;
  uint256 usdThreshold;
  /**
   * @dev Bit-packed value: uint16: eth share bps, uint16: balance threshold bps (<< 16), bool: live quote (<< 32), bool: default eth terminal (<< 33), bool: default eth terminal (<< 34)
   */
  uint256 settings;
}

/**
 * @title Automated DAI treasury
 *
 * @notice Converts ether sent to it into WETH and swaps it for DAI, then `pay`s the DAI into the platform DAI sink with the beneficiary being the owner of the original target project.
 *
 * @custom:experimetal
 */
contract DaiHedgeDelegate is
  JBOperatable,
  IDaiHedgeDelegate,
  IJBFundingCycleDataSource,
  IJBPayDelegate,
  IJBRedemptionDelegate
{
  //*********************************************************************//
  // ------------------------------ errors ----------------------------- //
  //*********************************************************************//
  error REDEEM_NOT_SUPPORTED();

  //*********************************************************************//
  // -------------------- private stored properties -------------------- //
  //*********************************************************************//

  IJBDirectory private immutable jbxDirectory;

  IERC721 private immutable jbxProjects;

  /**
   * @notice Balance token, in this case DAI, that is held by the delegate on behalf of depositors.
   */
  IERC20Metadata private constant _dai = IERC20Metadata(0x6B175474E89094C44Da98b954EedeAC495271d0F); // DAI mainnet
  // IERC20Metadata private constant _dai = IERC20Metadata(0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60); // DAI goerli

  /**
   * @notice Uniswap v3 router.
   */
  ISwapRouter private constant _swapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // TODO: this should be abstracted into a SwapProvider that can offer interfaces other than just uniswap

  /**
   * @notice Uniswap v3 quoter.
   */
  IQuoter public constant _swapQuoter = IQuoter(0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6);

  /**
   * @notice Hardwired WETH address for use as "cash" in the swaps.
   */
  IWETH9 private constant _weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  uint24 public constant poolFee = 3000;

  IJBSingleTokenPaymentTerminal public defaultEthTerminal;
  IJBSingleTokenPaymentTerminal public defaultUsdTerminal;
  IJBSingleTokenPaymentTerminalStore public terminalStore;
  uint256 public recentPrice;
  uint256 public recentPriceTimestamp;

  /**
   * @dev Maps project ids to hedging configuration.
   */
  mapping(uint256 => HedgeSettings) public projectHedgeSettings;

  uint256 private constant bps = 10_000;
  uint256 private constant SettingsOffsetEthShare = 0;
  uint256 private constant SettingsOffsetBalanceThreshold = 16;
  uint256 private constant SettingsOffsetLiveQuote = 32;
  uint256 private constant SettingsOffsetDefaultEthTerminal = 33;
  uint256 private constant SettingsOffsetDefaultUsdTerminal = 34;
  uint256 private constant SettingsOffsetApplyHedge = 35;

  /**
   * @notice Funding cycle datasource implementation that keeps contributions split between Ether and DAI according to pre-defined params. This contract stores per-project configuration so only a single instance is needed for the platform. Usage of this contract is optional for projects.
   *
   * @param _jbxOperatorStore Juicebox OperatorStore to manage per-project permissions.
   * @param _jbxDirectory Juicebox Directory for terminal lookup.
   * @param _jbxProjects Juicebox Projects ownership NFT.
   * @param _defaultEthTerminal Default Eth terminal.
   * @param _defaultUsdTerminal Default DAI terminal.
   * @param _terminalStore Juicebox TerminalStore to track token balances.
   */
  constructor(
    IJBOperatorStore _jbxOperatorStore,
    IJBDirectory _jbxDirectory,
    IERC721 _jbxProjects,
    IJBSingleTokenPaymentTerminal _defaultEthTerminal,
    IJBSingleTokenPaymentTerminal _defaultUsdTerminal,
    IJBSingleTokenPaymentTerminalStore _terminalStore
  ) {
    operatorStore = _jbxOperatorStore; // JBOperatable

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;

    defaultEthTerminal = _defaultEthTerminal;
    defaultUsdTerminal = _defaultUsdTerminal;
    terminalStore = _terminalStore;
  }

  //*********************************************************************//
  // ------------------------ external functions ----------------------- //
  //*********************************************************************//

  /**
   * @notice Sets project params. This function requires `MANAGE_PAYMENTS` operation privilege.
   *
   * @dev Multiple conditions need to be met for this delegate to attempt swaps between Ether and DAI. Eth/DAI ratio must be away from desired (_ethShare) by at least (_balanceThreshold). Incoming contribution amount must be larger than either _ethThreshold or _usdThreshold depending on denomination.
   *
   * @dev Rather than setting _ethShare to 10_000 (100%), disable hedging or remove the datasource delegate from the funding cycle config to save gas. Similarly setting _ethShare to 0 is more cheaply accomplished by removing the Eth terminal from the project to require contributions in DAI only.
   *
   * @param _projectId Project id to modify settings for.
   * @param _applyHedge Enable hedging.
   * @param _ethShare Target Ether share of the total. Expressed in basis points, setting it to 6000 will make the targer 60% Ether, 40% DAI.
   * @param _balanceThreshold Distance from targer threshold at which to take action.
   * @param _ethThreshold Ether contribution threshold, below this number trandes won't be attempted.
   * @param _usdThreshold Dai contribution threshold, below this number trandes won't be attempted.
   * @param _flags Sets flags requiring live quotes, and allowing use of default token terminals instead of performing look ups to save gas.
   */
  function setHedgeParameters(
    uint256 _projectId,
    bool _applyHedge,
    uint256 _ethShare,
    uint256 _balanceThreshold,
    uint256 _ethThreshold,
    uint256 _usdThreshold,
    HedgeFlags memory _flags
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(_projectId),
      _projectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(_projectId)))
    )
  {
    uint256 settings = uint16(_ethShare);
    settings |= uint256(uint16(_balanceThreshold)) << SettingsOffsetBalanceThreshold;
    settings = setBoolean(settings, SettingsOffsetLiveQuote, _flags.liveQuote);
    settings = setBoolean(settings, SettingsOffsetDefaultEthTerminal, _flags.defaultEthTerminal);
    settings = setBoolean(settings, SettingsOffsetDefaultUsdTerminal, _flags.defaultUsdTerminal);
    settings = setBoolean(settings, SettingsOffsetApplyHedge, _applyHedge);

    projectHedgeSettings[_projectId] = HedgeSettings(_ethThreshold, _usdThreshold, settings);
  }

  /**
   * @notice IJBPayDelegate implementation
   *
   * @notice Will swap ether to DAI or the reverse subject to project-defined constraints. See setHedgeParameters() for requirements.
   */
  function didPay(JBDidPayData calldata _data) public payable override {
    HedgeSettings memory settings = projectHedgeSettings[_data.projectId];

    if (!getBoolean(settings.settings, SettingsOffsetApplyHedge)) {
      return; // TODO: may retain funds, needs tests
    }

    if (_data.amount.token == JBTokens.ETH) {
      // eth -> dai

      IJBSingleTokenPaymentTerminal ethTerminal = getProjectTerminal(
        JBCurrencies.ETH,
        getBoolean(settings.settings, SettingsOffsetDefaultEthTerminal),
        _data.projectId
      );

      if (uint16(settings.settings) == 10_000) {
        // 100% eth
        ethTerminal.addToBalanceOf{value: msg.value}(
          _data.projectId,
          msg.value,
          JBTokens.ETH,
          _data.memo,
          _data.metadata
        );

        return;
      }

      if (uint16(settings.settings) == 0) {
        // 0% eth

        IJBSingleTokenPaymentTerminal daiTerminal = getProjectTerminal(
          JBCurrencies.USD,
          getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
          _data.projectId
        );

        _weth.deposit{value: _data.forwardedAmount.value}();
        _weth.approve(address(_swapRouter), _data.forwardedAmount.value);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
          tokenIn: address(_weth),
          tokenOut: address(_dai),
          fee: poolFee,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _data.forwardedAmount.value,
          amountOutMinimum: 0, // TODO: consider setting amount
          sqrtPriceLimitX96: 0
        });

        uint256 amountOut = _swapRouter.exactInputSingle(params);
        _weth.approve(address(_swapRouter), 0);

        _dai.approve(address(daiTerminal), amountOut);
        daiTerminal.addToBalanceOf(
          _data.projectId,
          amountOut,
          address(_dai),
          _data.memo,
          _data.metadata
        );
        _dai.approve(address(daiTerminal), 0);

        return;
      }

      // (depositEth - x + currentEth) / (currentUsdEth + x) = ethShare/usdShare
      // x = (depositEth + currentEth - currentUsdEth * ethShare/usdShare) / (ethShare/usdShare + 1)
      // NOTE: in this case this should be the same as msg.value
      if (_data.forwardedAmount.value >= settings.ethThreshold) {
        uint256 projectEthBalance = terminalStore.balanceOf(ethTerminal, _data.projectId);

        (uint256 projectUsdBalance, IJBPaymentTerminal daiTerminal) = getProjectBalance(
          JBCurrencies.USD,
          getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
          _data.projectId
        );

        uint256 projectUsdBalanceEthValue;
        if (
          getBoolean(settings.settings, SettingsOffsetLiveQuote) ||
          recentPriceTimestamp < block.timestamp - 43_200
        ) {
          recentPrice = _swapQuoter.quoteExactOutputSingle(
            address(_dai),
            address(_weth),
            poolFee,
            1000000000000000000,
            0
          );
          recentPriceTimestamp = block.timestamp;
        }
        projectUsdBalanceEthValue = (projectUsdBalance * (10 ** 18)) / recentPrice;
        // value of the project's eth balance after adding current contribution
        uint256 newEthBalance;
        uint256 newEthShare;
        {
          newEthBalance = projectEthBalance + _data.forwardedAmount.value;
          uint256 totalEthBalance = newEthBalance + projectUsdBalanceEthValue;
          newEthShare = (newEthBalance * bps) / totalEthBalance;
        }

        if (
          newEthShare > uint16(settings.settings) &&
          newEthShare - uint16(settings.settings) >
          uint16(settings.settings >> SettingsOffsetBalanceThreshold)
        ) {
          uint256 ratio;
          {
            ratio = ((projectUsdBalanceEthValue * uint16(settings.settings)) /
              (bps - uint16(settings.settings)));
          }
          uint256 swapAmount;
          if (newEthBalance < ratio) {
            swapAmount = _data.forwardedAmount.value;
          } else {
            uint256 numerator = newEthBalance - ratio;
            uint256 denominator = (uint16(settings.settings) * bps) /
              (bps - uint16(settings.settings)) +
              bps;
            swapAmount = (numerator / denominator) * bps;
          }

          {
            _weth.deposit{value: swapAmount}();
            _weth.approve(address(_swapRouter), swapAmount);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
              tokenIn: address(_weth),
              tokenOut: address(_dai),
              fee: poolFee,
              recipient: address(this),
              deadline: block.timestamp,
              amountIn: swapAmount,
              amountOutMinimum: 0, // TODO: consider setting amount
              sqrtPriceLimitX96: 0
            });

            uint256 amountOut = _swapRouter.exactInputSingle(params);
            _weth.approve(address(_swapRouter), 0);

            _dai.approve(address(daiTerminal), amountOut);
            daiTerminal.addToBalanceOf(_data.projectId, amountOut, address(_dai), '', '');
            _dai.approve(address(daiTerminal), 0);
          }
          {
            uint256 remainingEth = _data.forwardedAmount.value - swapAmount;
            ethTerminal.addToBalanceOf{value: remainingEth}(
              _data.projectId,
              remainingEth,
              JBTokens.ETH,
              '',
              ''
            );
          }
        } else {
          ethTerminal.addToBalanceOf{value: msg.value}(
            _data.projectId,
            msg.value,
            JBTokens.ETH,
            '',
            ''
          );
        }
      } else {
        ethTerminal.addToBalanceOf{value: msg.value}(
          _data.projectId,
          msg.value,
          JBTokens.ETH,
          '',
          ''
        );
      }
    } else if (_data.amount.token == address(_dai)) {
      // dai -> eth

      // (currentEth + x) / (currentUsdEth + depositUsdEth - x) = ethShare/usdShare
      // x = (ethShare/usdShare * (currentUsdEth + depositUsdEth) - currentEth) / (1 + ethShare/usdShare)
      IJBSingleTokenPaymentTerminal daiTerminal = getProjectTerminal(
        JBCurrencies.USD,
        getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
        _data.projectId
      );

      if (uint16(settings.settings) == 10_000) {
        // 100% eth

        IJBSingleTokenPaymentTerminal ethTerminal = getProjectTerminal(
          JBCurrencies.ETH,
          getBoolean(settings.settings, SettingsOffsetDefaultEthTerminal),
          _data.projectId
        );

        _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
        _dai.approve(address(_swapRouter), _data.forwardedAmount.value);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
          tokenIn: address(_dai),
          tokenOut: address(_weth),
          fee: poolFee,
          recipient: address(this),
          deadline: block.timestamp,
          amountIn: _data.forwardedAmount.value,
          amountOutMinimum: 0, // TODO: consider setting amount
          sqrtPriceLimitX96: 0
        });

        uint256 amountOut = _swapRouter.exactInputSingle(params);
        _dai.approve(address(_swapRouter), 0);
        _weth.withdraw(amountOut);

        ethTerminal.addToBalanceOf{value: amountOut}(
          _data.projectId,
          amountOut,
          JBTokens.ETH,
          _data.memo,
          _data.metadata
        );

        return;
      }

      if (uint16(settings.settings) == 0) {
        // 0% eth
        _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
        _dai.approve(address(daiTerminal), _data.forwardedAmount.value);
        daiTerminal.addToBalanceOf(
          _data.projectId,
          _data.forwardedAmount.value,
          address(_dai),
          _data.memo,
          _data.metadata
        );
        _dai.approve(address(daiTerminal), 0);

        return;
      }

      if (_data.forwardedAmount.value >= settings.usdThreshold) {
        (uint256 projectEthBalance, IJBPaymentTerminal ethTerminal) = getProjectBalance(
          JBCurrencies.ETH,
          getBoolean(settings.settings, SettingsOffsetDefaultEthTerminal),
          _data.projectId
        );
        (uint256 projectUsdBalance, ) = getProjectBalance(
          JBCurrencies.USD,
          getBoolean(settings.settings, SettingsOffsetDefaultUsdTerminal),
          _data.projectId
        );

        if (
          getBoolean(settings.settings, SettingsOffsetLiveQuote) ||
          recentPriceTimestamp < block.timestamp - 43200
        ) {
          recentPrice = _swapQuoter.quoteExactOutputSingle(
            address(_dai),
            address(_weth),
            poolFee,
            1000000000000000000,
            0
          );
          recentPriceTimestamp = block.timestamp;
        }
        // value of the project's dai balance in terms of eth after adding current contribution
        uint256 projectUsdBalanceEthValue = ((projectUsdBalance + _data.forwardedAmount.value) *
          10 ** 18) / recentPrice;
        uint256 totalEthBalance = projectEthBalance + projectUsdBalanceEthValue;
        uint256 newEthShare = (projectEthBalance * bps) / totalEthBalance;

        if (
          newEthShare < uint16(settings.settings) &&
          uint16(settings.settings) - newEthShare >
          uint16(settings.settings >> SettingsOffsetBalanceThreshold)
        ) {
          uint256 ratio = (bps * uint16(settings.settings)) / (bps - uint16(settings.settings));
          uint256 swapAmount;

          if ((projectEthBalance * bps) > ratio * projectUsdBalanceEthValue) {
            swapAmount = _data.forwardedAmount.value;
          } else {
            uint256 numerator = ratio * projectUsdBalanceEthValue - (projectEthBalance * bps);
            uint256 denominator = bps + ratio;

            swapAmount = numerator / denominator;
            swapAmount = (swapAmount * recentPrice) / 10 ** 18;
          }

          uint256 amountOut;
          {
            _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
            _dai.approve(address(_swapRouter), swapAmount);

            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
              tokenIn: address(_dai),
              tokenOut: address(_weth),
              fee: poolFee,
              recipient: address(this),
              deadline: block.timestamp,
              amountIn: swapAmount,
              amountOutMinimum: 0, // TODO: consider setting amount
              sqrtPriceLimitX96: 0
            });

            amountOut = _swapRouter.exactInputSingle(params);

            _dai.approve(address(_swapRouter), 0);

            _weth.withdraw(amountOut);
          }
          ethTerminal.addToBalanceOf{value: amountOut}(
            _data.projectId,
            amountOut,
            JBTokens.ETH,
            '',
            ''
          );

          uint256 remainder = _data.forwardedAmount.value - swapAmount;

          _dai.approve(address(daiTerminal), remainder);
          daiTerminal.addToBalanceOf(_data.projectId, remainder, address(_dai), '', '');
          _dai.approve(address(daiTerminal), 0);
        } else {
          _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
          _dai.approve(address(daiTerminal), _data.forwardedAmount.value);
          daiTerminal.addToBalanceOf(
            _data.projectId,
            _data.forwardedAmount.value,
            address(_dai),
            _data.memo,
            _data.metadata
          );
          _dai.approve(address(daiTerminal), 0);
        }
      } else {
        _dai.transferFrom(msg.sender, address(this), _data.forwardedAmount.value);
        _dai.approve(address(daiTerminal), _data.forwardedAmount.value);
        daiTerminal.addToBalanceOf(
          _data.projectId,
          _data.forwardedAmount.value,
          address(_dai),
          _data.memo,
          _data.metadata
        );
        _dai.approve(address(daiTerminal), 0);
      }
    }
  }

  /**
   * @notice IJBRedemptionDelegate implementation
   *
   * @notice NOT SUPPORTED, set fundingCycleMetadata.useDataSourceForRedeem to false when deploying.
   */
  function didRedeem(JBDidRedeemData calldata) public payable override {
    revert REDEEM_NOT_SUPPORTED();
  }

  /**
   * @notice IJBFundingCycleDataSource implementation
   *
   * @dev This function will pass through the weight and amount parameters from the incoming data argument but will add self as the delegate address.
   */
  function payParams(
    JBPayParamsData calldata _data
  )
    public
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegateAllocations
    )
  {
    weight = _data.weight;
    memo = _data.memo;
    delegateAllocations = new JBPayDelegateAllocation[](1);
    delegateAllocations[0] = JBPayDelegateAllocation({
      delegate: IJBPayDelegate(address(this)),
      amount: _data.amount.value
    });
  }

  /**
   * @notice IJBFundingCycleDataSource implementation
   *
   * @notice NOT SUPPORTED, set fundingCycleMetadata.useDataSourceForRedeem to false when deploying.
   */
  function redeemParams(
    JBRedeemParamsData calldata _data
  )
    public
    pure
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegateAllocations
    )
  {
    revert REDEEM_NOT_SUPPORTED();
  }

  /**
   * @notice IERC165 implementation
   */
  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return
      interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      interfaceId == type(IJBPayDelegate).interfaceId ||
      interfaceId == type(IJBRedemptionDelegate).interfaceId;
  }

  /**
   * @dev WETH withdraw() payment is sent here before execution proceeds in the original function.
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  //*********************************************************************//
  // ------------------------ internal functions ----------------------- //
  //*********************************************************************//
  function getProjectBalance(
    uint256 _currency,
    bool _useDefaultTerminal,
    uint256 _projectId
  ) internal view returns (uint256 balance, IJBSingleTokenPaymentTerminal terminal) {
    if (_currency == JBCurrencies.ETH) {
      terminal = IJBSingleTokenPaymentTerminal(defaultEthTerminal);
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH))
        );
      }

      balance = terminalStore.balanceOf(terminal, _projectId);
    } else if (_currency == JBCurrencies.USD) {
      terminal = defaultUsdTerminal;
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, address(_dai)))
        );
      }
      balance = terminalStore.balanceOf(terminal, _projectId);
    }
  }

  function getProjectTerminal(
    uint256 _currency,
    bool _useDefaultTerminal,
    uint256 _projectId
  ) internal view returns (IJBSingleTokenPaymentTerminal terminal) {
    if (_currency == JBCurrencies.ETH) {
      terminal = IJBSingleTokenPaymentTerminal(defaultEthTerminal);
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH))
        );
      }
    } else if (_currency == JBCurrencies.USD) {
      terminal = defaultUsdTerminal;
      if (!_useDefaultTerminal) {
        terminal = IJBSingleTokenPaymentTerminal(
          address(jbxDirectory.primaryTerminalOf(_projectId, address(_dai)))
        );
      }
    }
  }

  //*********************************************************************//
  // ------------------------------ utils ------------------------------ //
  //*********************************************************************//

  function getBoolean(uint256 _source, uint256 _index) internal pure returns (bool) {
    uint256 flag = (_source >> _index) & uint256(1);
    return (flag == 1 ? true : false);
  }

  function setBoolean(
    uint256 _source,
    uint256 _index,
    bool _value
  ) internal pure returns (uint256 update) {
    if (_value) {
      update = _source | (uint256(1) << _index);
    } else {
      update = _source & ~(uint256(1) << _index);
    }
  }
}