//SPDX-License-Identifier: Unlicense
pragma solidity =0.5.16;

//import "hardhat/console.sol";
import "./interfaces/IZirconEnergy.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol';
import '../libraries/Math.sol';
import "./interfaces/IZirconEnergyFactory.sol";
import "../interfaces/IZirconPair.sol";
import "../interfaces/IZirconPylon.sol";

contract ZirconEnergy is IZirconEnergy {

  /*
   * Zircon Energy is the protocol-wide accumulator of revenue.
   * Each Pylon ahas an energy that works as a "bank account" and works as an insurance portion balance
  */

  using SafeMath for uint112;
  using SafeMath for uint256;

  struct Pylon {
    address pylonAddress;
    address pairAddress;
    address floatToken;
    address anchorToken;
  }
  Pylon pylon;

  address energyFactory;
  uint anchorReserve; //Used to track balances and sync up in case of donations
  bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
  // **** MODIFIERS *****
  uint public initialized = 0;
  event RegisterFee(uint newReserve, uint fee, uint rev);
  event MuUpdate(uint fee);
  event Slashing(uint omega, uint ptToSend, uint anchorToSend);

  modifier _initialize() {
    require(initialized == 1, 'Zircon: FORBIDDEN');
    _;
  }
  constructor() public {
    energyFactory = msg.sender;
  }

  function getFee() internal view returns (uint112 minFee, uint112 maxFee) {
    (minFee, maxFee) = IZirconEnergyFactory(energyFactory).getMinMaxFee();
  }

  function initialize(address _pylon, address _pair, address _token0, address _token1) external {
    require(initialized == 0, "ZER: AI");
    require(msg.sender == energyFactory, 'Zircon: FORBIDDEN'); // sufficient check

    pylon = Pylon(
      _pylon,
      _pair,
      _token0,
      _token1
    );
    initialized = 1;
  }

  // ****** HELPER FUNCTIONS *****
  function _safeTransfer(address token, address to, uint value) private {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'Zircon Pylon: TRANSFER_FAILED');
  }

  modifier _onlyPylon() {
    require(pylon.pylonAddress == msg.sender, "ZE: Not Pylon");
    _;
  }

  modifier _onlyPair() {
    require(pylon.pairAddress == msg.sender, "ZE: Not Pylon");
    _;
  }

  function registerFee() external _onlyPylon _initialize {
    uint balance = IUniswapV2ERC20(pylon.anchorToken).balanceOf(address(this));
    require(balance >= anchorReserve, "ZE: Anchor not sent");
    uint register = balance.sub(anchorReserve);

    uint feePercentageForRev = IZirconEnergyFactory(energyFactory).feePercentageEnergy();
    address energyRevAddress = IZirconEnergyFactory(energyFactory).getEnergyRevenue(pylon.floatToken, pylon.anchorToken);
    uint toSend = register.mul(feePercentageForRev)/(100);
    if(toSend != 0) _safeTransfer(pylon.anchorToken, energyRevAddress, toSend);
    anchorReserve = balance.sub(toSend);
    emit RegisterFee(anchorReserve, register, toSend);
  }


  //Returns the fee in basis points (0.01% units, needs to be divided by 10000)
  //Uses two piece-wise parabolas. Between 0.45 and 0.55 the fee is very low (minFee).
  //After the cutoff it uses a steeper parabola defined by a max fee at the extremes (very high, up to 1% by default).
  function getFeeByGamma(uint gammaMulDecimals) _initialize external view returns (uint amount) {
    (uint _minFee, uint _maxFee) = getFee();
    uint _gammaHalf = 5e17;
    uint x = (gammaMulDecimals > _gammaHalf) ? (gammaMulDecimals - _gammaHalf).mul(10) : (_gammaHalf - gammaMulDecimals).mul(10);
    if (gammaMulDecimals <= 45e16 || gammaMulDecimals >= 55e16) {
      amount = _minFee + (_maxFee.mul(x).mul(x))/(25e36); //25 is a reduction factor based on the 0.45-0.55 range we're using.
    } else {
      amount = (_minFee.mul(x).mul(x).mul(36)/(1e36)).add(_minFee); //Ensures minFee is the lowest value.
    }
  }
  function migrateLiquidity(address newEnergy) external{
    require(msg.sender == energyFactory, 'ZP: FORBIDDEN'); // sufficient check

    uint balance = IZirconPair(pylon.pairAddress).balanceOf(address(this));
    uint balanceAnchor = IUniswapV2ERC20(pylon.anchorToken).balanceOf(address(this));
    uint balanceFloat = IUniswapV2ERC20(pylon.floatToken).balanceOf(address(this));

    _safeTransfer(pylon.pairAddress, newEnergy, balance);
    _safeTransfer(pylon.anchorToken, newEnergy, balanceAnchor);
    _safeTransfer(pylon.floatToken, newEnergy, balanceFloat);
  }

  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint fee) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'UV2: IIA');
    require(reserveIn > 0 && reserveOut > 0, 'UV2: IL');
    uint amountInWithFee = amountIn.mul(10000-fee);
    uint numerator = amountInWithFee.mul(reserveOut);
    uint denominator = reserveIn.mul(10000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function _updateMu(uint muUpdatePeriod, uint muChangeFactor, uint muBlockNumber, uint muMulDecimals, uint gammaMulDecimals, uint muOldGamma) external returns (uint mu) {

    // We only go ahead with this if a sufficient amount of time passes
    // This is primarily to reduce noise, we want to capture sweeping changes over fairly long periods
    if((block.number - muBlockNumber) > muUpdatePeriod) { // reasonable to assume it won't subflow

      uint _newGamma = gammaMulDecimals; // y2
      uint _oldGamma = muOldGamma; // y1

      bool deltaGammaIsPositive = _newGamma >= _oldGamma;
      bool gammaIsOver50 = _newGamma >= 5e17;

      // This the part that measures if gamma is going outside (to the extremes) or to the inside (0.5 midpoint)
      // It uses an XOR between current gamma and its delta
      // If delta is positive when above 50%, means it's moving to the outside
      // If delta is negative when below 50%, that also means it's going to the outside

      // In other scenarios it's going to the inside, which is why we use the XOR
      uint deltaMu = Math.absoluteDiff(_newGamma, _oldGamma);
      if(deltaGammaIsPositive != gammaIsOver50) { // != with booleans is an XOR
        // This block assigns the dampened delta gamma to mu and checks that it's between 0 and 1
        // Due to uint math we can't do this in one line
        // Parameter to tweak the speed at which mu seeks to follow gamma
        deltaMu = deltaMu.mul(muChangeFactor * Math.absoluteDiff(_newGamma, 5e17))/1e18;
      }

      if (deltaGammaIsPositive) {
        if (deltaMu + muMulDecimals <= 1e18) {
          // Only updates if the result doesn't go above 1.
          muMulDecimals += deltaMu;
        }
      } else {
        if(deltaMu <= muMulDecimals) {
          muMulDecimals -= deltaMu;
        }
      }

      mu = Math.clamp(muMulDecimals, 1e17, 9e17);

      emit MuUpdate(mu);
      // update variables for next step
    } else {
      mu = muMulDecimals;
    }


  }


  /// @notice Omega is the slashing factor. It's always equal to 1 if pool has gamma above 50%
  /// If it's below 50%, it begins to go below 1 and thus slash any withdrawal.
  /// @dev Note that in practice this system doesn't activate unless the syncReserves are empty.
  /// Also note that a dump of 60% only generates about 10% of slashing.
  // 0.39kb
  function handleOmegaSlashing(uint ptu, uint omegaMulDecimals, bool isFloatReserve0, address _to) _onlyPylon
  external returns (uint retPTU, uint amount){
    // Send slashing should send the extra PTUs to Uniswap.
    // When burn calls the uniswap burn it will also give users the compensation
    retPTU = omegaMulDecimals.mul(ptu)/1e18;
    if (omegaMulDecimals < 1e18) {
      // finds amount to cover
      uint amountToAdd = ptu * (1e18-omegaMulDecimals)/1e18; // already checked

      // finds how much we can cover
      uint energyPTBalance = IUniswapV2ERC20(pylon.pairAddress).balanceOf(address(this));

      if (amountToAdd < energyPTBalance) {
        // Sending PT tokens to Pair because burn one side is going to be called after
        // sends pool tokens directly to pair
        _safeTransfer(pylon.pairAddress, pylon.pairAddress, amountToAdd);
      } else {
        // Sending PT tokens to Pair because burn one side is going to be called after
        // @dev if amountToAdd is too small the remainingPercentage will be 0 so that is ok
        _safeTransfer(pylon.pairAddress, pylon.pairAddress, energyPTBalance);

//        uint percentage = (amountToAdd - energyPTBalance).mul(1e18)/(ptu);

        {
//          uint _fee = fee;
//          uint _ptu = retPTU;
          bool _isFloatReserve0 = isFloatReserve0;
          uint ts = IZirconPair(pylon.pairAddress).totalSupply();
          (uint reserve0, uint reserve1,) = IZirconPair(pylon.pairAddress).getReserves();
//          uint _reserve0 = _isFloatReserve0 ? reserve0 : reserve1;
          uint _reserve1 = _isFloatReserve0 ? reserve1 : reserve0;

          // Simplified, the previous system was necessary because it was two separate functions
          amount = (amountToAdd - energyPTBalance).mul(2 * _reserve1)/ts;

          //          // sends pool tokens directly to pair
          //          // TotalAmount is what the user already received, while percentage is what's missing.
          //          // We divide to arrive to the original amount and diff it with totalAmount to get final number.
          //          // Percentage is calculated "natively" as a full 1e18
          //          // ta/(1-p) - ta = ta*p/(1-p)
          //          amount = totalAmount.mul(percentage)/(1e18 - percentage);
        }

        uint eBalance = IUniswapV2ERC20(pylon.anchorToken).balanceOf(address(this));

        amount = eBalance > amount ? amount : eBalance;
        _safeTransfer(pylon.anchorToken, _to, amount);
        // updating the reserves of energy
        anchorReserve = eBalance-amount;
      }
      emit Slashing(omegaMulDecimals, amountToAdd, amount);
    }
  }


}