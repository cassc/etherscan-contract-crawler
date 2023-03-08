// SPDX-License-Identifier: AGPL-3.0-or-later

/// MultiplyProxyActions.sol

// Copyright (C) 2023 Oazo Apps Limited

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import { IERC20 } from "../interfaces/IERC20.sol";
import "../utils/SafeMath.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/mcd/IJoin.sol";
import "../interfaces/mcd/IManager.sol";
import "../interfaces/mcd/IVat.sol";
import "../interfaces/mcd/IJug.sol";
import "../interfaces/mcd/IDaiJoin.sol";
import "../interfaces/exchange/IExchange.sol";
import "../interfaces/misc/IProxy.sol";
import "../interfaces/misc/IChainLogView.sol";
import "./ExchangeData.sol";

import "../flash-mint/interface/IERC3156FlashBorrower.sol";
import "../flash-mint/interface/IERC3156FlashLender.sol";

pragma solidity 0.8.13;
pragma abicoder v2;

struct CdpData {
  address gemJoin;
  address payable fundsReceiver;
  uint256 cdpId;
  bytes32 ilk;
  uint256 requiredDebt;
  uint256 borrowCollateral;
  uint256 withdrawCollateral;
  uint256 withdrawDai;
  uint256 depositDai;
  uint256 depositCollateral;
  bool skipFL;
  string methodName;
}

struct AddressRegistry {
  address jug;
  address manager;
  address multiplyProxyActions;
  address lender;
  address exchange;
}

// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
// WARNING: These functions meant to be used as a a library for a DSProxy. Some are unsafe if you call them directly.
// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contract MultiplyProxyActions is IERC3156FlashBorrower {
  using SafeMath for uint256;

  uint256 constant RAY = 10**27;

  address public immutable SELF;
  address public immutable CHAIN_LOG_VIEW;
  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public constant DAIJOIN = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
  address public constant CDP_MANAGER = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
  address public constant JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
  address public constant EXCHANGE = 0xb5eB8cB6cED6b6f8E13bcD502fb489Db4a726C7B;
  address public constant ONE_INCH_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
  address public constant ONE_INCH_V5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;

  bool public callable = true;

  constructor(address _chainLogView) {
    SELF = address(this);
    CHAIN_LOG_VIEW = _chainLogView;
  }

  modifier logMethodName(
    string memory name,
    CdpData memory data,
    address destination
  ) {
    if (bytes(data.methodName).length == 0) {
      data.methodName = name;
    }
    _;
    data.methodName = "";
  }
  modifier isCallable() {
    require(MultiplyProxyActions(payable(SELF)).callable(), "mpa/not-callable");
    _;
  }

  modifier onlyDelegate() {
    require(address(this) != SELF, "mpa/only-delegate");
    _;
  }

  function validateAndCorrectInputData(
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry,
    ExchangeData calldata exchangeData
  ) public view {
    require(cdpData.skipFL == false, "mpa/skipFL-not-supported");
    require(addressRegistry.jug == JUG, "mpa/jug-invalid");
    require(addressRegistry.manager == CDP_MANAGER, "mpa/manager-invalid");
    require(addressRegistry.multiplyProxyActions == SELF, "mpa/self-invalid");
    require(
      addressRegistry.lender == IChainLogView(CHAIN_LOG_VIEW).getServiceAddress("MCD_FLASH"),
      "mpa/FL-invalid"
    );
    require(addressRegistry.exchange == EXCHANGE, "mpa/exchange-invalid");
    require(
      exchangeData.exchangeAddress == ONE_INCH_V4 || exchangeData.exchangeAddress == ONE_INCH_V5,
      "mpa/exchange-not-one-inch"
    );
    address cdpOwner = IProxy(IManager(CDP_MANAGER).owns(cdpData.cdpId)).owner();
    bytes32 ilk = IJoin(cdpData.gemJoin).ilk();
    address gem = address(IJoin(cdpData.gemJoin).gem());
    cdpData.ilk = ilk;
    require(
      (exchangeData.fromTokenAddress == gem && exchangeData.toTokenAddress == DAI) ||
        (exchangeData.fromTokenAddress == DAI && exchangeData.toTokenAddress == gem),
      "mpa/wrong-gem"
    );
    require(cdpData.fundsReceiver == cdpOwner, "mpa/fundsReceiver-not-owner");
    require(
      cdpData.gemJoin == IChainLogView(CHAIN_LOG_VIEW).getIlkJoinAddressByHash(cdpData.ilk),
      "mpa/wrong-gemJoin"
    );
  }

  function takeAFlashLoan(
    AddressRegistry calldata addressRegistry,
    CdpData memory cdpData,
    bytes memory paramsData
  ) internal {
    IManager(addressRegistry.manager).cdpAllow(
      cdpData.cdpId,
      addressRegistry.multiplyProxyActions,
      1
    );
    IERC3156FlashLender(addressRegistry.lender).flashLoan(
      IERC3156FlashBorrower(addressRegistry.multiplyProxyActions),
      DAI,
      cdpData.requiredDebt,
      paramsData
    );

    IManager(addressRegistry.manager).cdpAllow(
      cdpData.cdpId,
      addressRegistry.multiplyProxyActions,
      0
    );
  }

  function toInt256(uint256 x) internal pure returns (int256 y) {
    y = int256(x);
    require(y >= 0, "int256-overflow");
  }

  function convertTo18(address gemJoin, uint256 amt) internal view returns (uint256 wad) {
    // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to frob function
    // Adapters will automatically handle the difference of precision
    wad = amt.mul(10**(18 - IJoin(gemJoin).dec()));
  }

  function _getDrawDart(
    address vat,
    address jug,
    address urn,
    bytes32 ilk,
    uint256 wad
  ) internal returns (int256 dart) {
    // Updates stability fee rate
    uint256 rate = IJug(jug).drip(ilk);

    // Gets DAI balance of the urn in the vat
    uint256 dai = IVat(vat).dai(urn);

    // If there was already enough DAI in the vat balance, just exits it without adding more debt
    if (dai < wad.mul(RAY)) {
      // Calculates the needed dart so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
      dart = toInt256(wad.mul(RAY).sub(dai) / rate);
      // This is neeeded due lack of precision. It might need to sum an extra dart wei (for the given DAI wad amount)
      dart = uint256(dart).mul(rate) < wad.mul(RAY) ? dart + 1 : dart;
    }
  }

  function openMultiplyVault(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    payable
    logMethodName("openMultiplyVault", cdpData, addressRegistry.multiplyProxyActions)
    isCallable
    onlyDelegate
  {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();
    cdpData.cdpId = IManager(addressRegistry.manager).open(cdpData.ilk, address(this));
    increaseMultipleDepositCollateral(exchangeData, cdpData, addressRegistry);
  }

  function increaseMultipleDepositCollateral(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    payable
    logMethodName(
      "increaseMultipleDepositCollateral",
      cdpData,
      addressRegistry.multiplyProxyActions
    )
    isCallable
    onlyDelegate
  {
    validateAndCorrectInputData(cdpData, addressRegistry, exchangeData);
    IGem gem = IJoin(cdpData.gemJoin).gem();

    if (address(gem) == WETH) {
      gem.deposit{ value: msg.value }();
      gem.transfer(addressRegistry.multiplyProxyActions, msg.value);
    } else {
      gem.transferFrom(msg.sender, addressRegistry.multiplyProxyActions, cdpData.depositCollateral);
    }
    increaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function toRad(uint256 wad) internal pure returns (uint256 rad) {
    rad = wad.mul(10**27);
  }

  function drawDaiDebt(
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry,
    uint256 amount
  ) internal {
    address urn = IManager(addressRegistry.manager).urns(cdpData.cdpId);
    address vat = IManager(addressRegistry.manager).vat();
    IManager(addressRegistry.manager).frob(
      cdpData.cdpId,
      0,
      _getDrawDart(vat, addressRegistry.jug, urn, cdpData.ilk, amount)
    );
    IManager(addressRegistry.manager).move(cdpData.cdpId, address(this), toRad(amount));
    if (IVat(vat).can(address(this), address(DAIJOIN)) == 0) {
      IVat(vat).hope(DAIJOIN);
    }

    IJoin(DAIJOIN).exit(address(this), amount);
  }

  function increaseMultiple(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName("increaseMultiple", cdpData, addressRegistry.multiplyProxyActions)
    isCallable
    onlyDelegate
  {
    validateAndCorrectInputData(cdpData, addressRegistry, exchangeData);
    increaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function increaseMultipleInternal(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  ) internal {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();

    bytes memory paramsData = abi.encode(1, exchangeData, cdpData, addressRegistry);

    takeAFlashLoan(addressRegistry, cdpData, paramsData);
  }

  function decreaseMultiple(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName("decreaseMultiple", cdpData, addressRegistry.multiplyProxyActions)
    isCallable
    onlyDelegate
  {
    validateAndCorrectInputData(cdpData, addressRegistry, exchangeData);
    decreaseMultipleInternal(exchangeData, cdpData, addressRegistry);
  }

  function decreaseMultipleInternal(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  ) internal {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();

    bytes memory paramsData = abi.encode(0, exchangeData, cdpData, addressRegistry);

    takeAFlashLoan(addressRegistry, cdpData, paramsData);
  }

  function closeVaultExitGeneric(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry,
    uint8 mode
  ) private {
    cdpData.ilk = IJoin(cdpData.gemJoin).ilk();

    address urn = IManager(addressRegistry.manager).urns(cdpData.cdpId);
    address vat = IManager(addressRegistry.manager).vat();

    uint256 wadD = _getWipeAllWad(vat, urn, urn, cdpData.ilk);
    cdpData.requiredDebt = wadD;

    bytes memory paramsData = abi.encode(mode, exchangeData, cdpData, addressRegistry);

    takeAFlashLoan(addressRegistry, cdpData, paramsData);
  }

  function closeVaultExitCollateral(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName("closeVaultExitCollateral", cdpData, addressRegistry.multiplyProxyActions)
    isCallable
    onlyDelegate
  {
    validateAndCorrectInputData(cdpData, addressRegistry, exchangeData);
    closeVaultExitGeneric(exchangeData, cdpData, addressRegistry, 2);
  }

  function closeVaultExitDai(
    ExchangeData calldata exchangeData,
    CdpData memory cdpData,
    AddressRegistry calldata addressRegistry
  )
    public
    logMethodName("closeVaultExitDai", cdpData, addressRegistry.multiplyProxyActions)
    isCallable
    onlyDelegate
  {
    validateAndCorrectInputData(cdpData, addressRegistry, exchangeData);
    closeVaultExitGeneric(exchangeData, cdpData, addressRegistry, 3);
  }

  function joinDrawDebt(
    CdpData memory cdpData,
    uint256 borrowedDai,
    address manager,
    address jug
  ) private {
    IGem gem = IJoin(cdpData.gemJoin).gem();

    uint256 balance = IERC20(address(gem)).balanceOf(address(this));
    gem.approve(address(cdpData.gemJoin), balance);

    address urn = IManager(manager).urns(cdpData.cdpId);
    address vat = IManager(manager).vat();

    IJoin(cdpData.gemJoin).join(urn, balance);

    IManager(manager).frob(
      cdpData.cdpId,
      toInt256(convertTo18(cdpData.gemJoin, balance)),
      _getDrawDart(vat, jug, urn, cdpData.ilk, borrowedDai)
    );
    IManager(manager).move(cdpData.cdpId, address(this), borrowedDai.mul(RAY));

    IVat(vat).hope(DAIJOIN);

    IJoin(DAIJOIN).exit(address(this), borrowedDai);
  }

  function getInk(address manager, CdpData memory cdpData) internal view returns (uint256) {
    address urn = IManager(manager).urns(cdpData.cdpId);
    address vat = IManager(manager).vat();

    (uint256 ink, ) = IVat(vat).urns(cdpData.ilk, urn);
    return ink;
  }

  function _getWipeDart(
    address vat,
    uint256 dai,
    address urn,
    bytes32 ilk
  ) internal view returns (int256 dart) {
    // Gets actual rate from the vat
    (, uint256 rate, , , ) = IVat(vat).ilks(ilk);
    // Gets actual art value of the urn
    (, uint256 art) = IVat(vat).urns(ilk, urn);

    // Uses the whole dai balance in the vat to reduce the debt
    dart = toInt256(dai / rate);
    // Checks the calculated dart is not higher than urn.art (total debt), otherwise uses its value
    dart = uint256(dart) <= art ? -dart : -toInt256(art);
  }

  function _getWipeAllWad(
    address vat,
    address usr,
    address urn,
    bytes32 ilk
  ) internal view returns (uint256 wad) {
    // Gets actual rate from the vat
    (, uint256 rate, , , ) = IVat(vat).ilks(ilk);
    // Gets actual art value of the urn
    (, uint256 art) = IVat(vat).urns(ilk, urn);
    // Gets actual dai amount in the urn
    uint256 dai = IVat(vat).dai(usr);

    uint256 rad = art.mul(rate).sub(dai);
    wad = rad / RAY;

    // If the rad precision has some dust, it will need to request for 1 extra wad wei
    wad = wad.mul(RAY) < rad ? wad + 1 : wad;
  }

  function wipeAndFreeGem(
    address manager,
    address gemJoin,
    uint256 cdp,
    uint256 borrowedDai,
    uint256 collateralDraw
  ) internal {
    address vat = IManager(manager).vat();
    address urn = IManager(manager).urns(cdp);
    bytes32 ilk = IManager(manager).ilks(cdp);

    IERC20(DAI).approve(DAIJOIN, borrowedDai);
    IDaiJoin(DAIJOIN).join(urn, borrowedDai);

    uint256 wadC = convertTo18(gemJoin, collateralDraw);

    IManager(manager).frob(cdp, -toInt256(wadC), _getWipeDart(vat, IVat(vat).dai(urn), urn, ilk));

    IManager(manager).flux(cdp, address(this), wadC);
    IJoin(gemJoin).exit(address(this), collateralDraw);
  }

  function _withdrawGem(address gemJoin, address payable destination, uint256 amount) private {
    IGem gem = IJoin(gemJoin).gem();

    if (address(gem) == WETH) {
      gem.withdraw(amount);
      destination.transfer(amount);
    } else {
      IERC20(address(gem)).transfer(destination, amount);
    }
  }

  function _increaseMP(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 premium
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);
    uint256 borrowedDai = cdpData.requiredDebt.add(premium);
    require(
      IERC20(DAI).approve(address(exchange), exchangeData.fromTokenAmount.add(cdpData.depositDai)),
      "mpa/could-not-approve-exchange-dai"
    );
    require(address(this) == SELF, "mpa/this-not-self");
    callable = false;
    exchange.swapDaiForToken(
      exchangeData.toTokenAddress,
      exchangeData.fromTokenAmount.add(cdpData.depositDai),
      exchangeData.minToTokenAmount,
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );
    callable = true;
    //here we add collateral we got from exchange, if skipFL then borrowedDai = 0
    joinDrawDebt(cdpData, borrowedDai, addressRegistry.manager, addressRegistry.jug);
    //if some DAI are left after exchange return them to the user
    uint256 daiLeft = IERC20(DAI).balanceOf(address(this)).sub(borrowedDai);
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      0,
      daiLeft
    );

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
  }

  function _decreaseMP(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 premium
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);

    uint256 debtToBeWiped = cdpData.requiredDebt.sub(cdpData.withdrawDai);

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      debtToBeWiped,
      cdpData.borrowCollateral.add(cdpData.withdrawCollateral)
    );

    require(
      IERC20(exchangeData.fromTokenAddress).approve(
        address(exchange),
        exchangeData.fromTokenAmount
      ),
      "mpa/could-not-approve-exchange-token"
    );
    require(address(this) == SELF, "mpa/this-not-self");
    callable = false;
    exchange.swapTokenForDai(
      exchangeData.fromTokenAddress,
      exchangeData.fromTokenAmount,
      cdpData.requiredDebt.add(premium),
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );
    callable = true;
    uint256 collateralLeft = IERC20(exchangeData.fromTokenAddress).balanceOf(address(this));

    uint256 daiLeft = IERC20(DAI).balanceOf(address(this)).sub(cdpData.requiredDebt.add(premium));

    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      collateralLeft,
      daiLeft
    );

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
    if (collateralLeft > 0) {
      _withdrawGem(cdpData.gemJoin, cdpData.fundsReceiver, collateralLeft);
    }
  }

  function _closeWithdrawCollateral(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 borrowedDaiAmount,
    uint256 ink
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);
    address gemAddress = address(IJoin(cdpData.gemJoin).gem());

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      cdpData.requiredDebt,
      ink
    );

    require(
      IERC20(exchangeData.fromTokenAddress).approve(address(exchange), ink),
      "mpa/could-not-approve-exchange-token"
    );
    require(address(this) == SELF, "mpa/this-not-self");
    callable = false;
    exchange.swapTokenForDai(
      exchangeData.fromTokenAddress,
      exchangeData.fromTokenAmount,
      exchangeData.minToTokenAmount,
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );
    callable = true;
    uint256 daiLeft = IERC20(DAI).balanceOf(address(this)).sub(borrowedDaiAmount);
    uint256 collateralLeft = IERC20(gemAddress).balanceOf(address(this));

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
    if (collateralLeft > 0) {
      _withdrawGem(cdpData.gemJoin, cdpData.fundsReceiver, collateralLeft);
    }
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      collateralLeft,
      daiLeft
    );
  }

  function _closeWithdrawDai(
    ExchangeData memory exchangeData,
    CdpData memory cdpData,
    AddressRegistry memory addressRegistry,
    uint256 borrowedDaiAmount,
    uint256 ink
  ) private {
    IExchange exchange = IExchange(addressRegistry.exchange);
    address gemAddress = address(IJoin(cdpData.gemJoin).gem());

    wipeAndFreeGem(
      addressRegistry.manager,
      cdpData.gemJoin,
      cdpData.cdpId,
      cdpData.requiredDebt,
      ink
    );

    require(
      IERC20(exchangeData.fromTokenAddress).approve(
        address(exchange),
        IERC20(gemAddress).balanceOf(address(this))
      ),
      "mpa/could-not-approve-exchange-token"
    );
    require(address(this) == SELF, "mpa/this-not-self");
    callable = false;
    exchange.swapTokenForDai(
      exchangeData.fromTokenAddress,
      ink,
      exchangeData.minToTokenAmount,
      exchangeData.exchangeAddress,
      exchangeData._exchangeCalldata
    );
    callable = true;
    uint256 daiLeft = IERC20(DAI).balanceOf(address(this)).sub(borrowedDaiAmount);

    if (daiLeft > 0) {
      IERC20(DAI).transfer(cdpData.fundsReceiver, daiLeft);
    }
    uint256 collateralLeft = IERC20(gemAddress).balanceOf(address(this));
    /*
    if (collateralLeft > 0) {
      _withdrawGem(cdpData.gemJoin, cdpData.fundsReceiver, collateralLeft);
    }*/
    emit MultipleActionCalled(
      cdpData.methodName,
      cdpData.cdpId,
      exchangeData.minToTokenAmount,
      exchangeData.toTokenAmount,
      collateralLeft,
      daiLeft
    );
  }

  function onFlashLoan(
    address,
    address token,
    uint256 amount,
    uint256 fee,
    bytes calldata params
  ) public override isCallable returns (bytes32) {
    (
      uint8 mode,
      ExchangeData memory exchangeData,
      CdpData memory cdpData,
      AddressRegistry memory addressRegistry
    ) = abi.decode(params, (uint8, ExchangeData, CdpData, AddressRegistry));

    require(
      msg.sender == IChainLogView(CHAIN_LOG_VIEW).getServiceAddress("MCD_FLASH"),
      "mpa/untrusted-lender"
    );

    uint256 borrowedDaiAmount = amount.add(fee);
    emit FLData(IERC20(DAI).balanceOf(address(this)).sub(cdpData.depositDai), borrowedDaiAmount);

    require(
      cdpData.requiredDebt.add(cdpData.depositDai) <= IERC20(DAI).balanceOf(address(this)),
      "mpa/receive-requested-amount-mismatch"
    );

    if (mode == 0) {
      _decreaseMP(exchangeData, cdpData, addressRegistry, fee);
    }
    if (mode == 1) {
      _increaseMP(exchangeData, cdpData, addressRegistry, fee);
    }
    if (mode == 2) {
      _closeWithdrawCollateral(
        exchangeData,
        cdpData,
        addressRegistry,
        borrowedDaiAmount,
        cdpData.borrowCollateral
      );
    }
    if (mode == 3) {
      _closeWithdrawDai(
        exchangeData,
        cdpData,
        addressRegistry,
        borrowedDaiAmount,
        cdpData.borrowCollateral
      );
    }

    IERC20(token).approve(addressRegistry.lender, borrowedDaiAmount);

    return keccak256("ERC3156FlashBorrower.onFlashLoan");
  }

  event FLData(uint256 borrowed, uint256 due);
  event MultipleActionCalled(
    string methodName,
    uint256 indexed cdpId,
    uint256 swapMinAmount,
    uint256 swapOptimistAmount,
    uint256 collateralLeft,
    uint256 daiLeft
  );

  fallback() external payable {}
}