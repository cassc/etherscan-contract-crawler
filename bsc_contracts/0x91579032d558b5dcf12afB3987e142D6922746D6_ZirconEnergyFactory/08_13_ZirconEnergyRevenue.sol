pragma solidity =0.5.16;
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2ERC20.sol';
//import "./libraries/SafeMath.sol";
import "../interfaces/IZirconPair.sol";
import "../interfaces/IZirconPylon.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
//import "hardhat/console.sol";
import "./interfaces/IZirconEnergyFactory.sol";
import '../libraries/Math.sol';

contract ZirconEnergyRevenue is ReentrancyGuard  {
    using SafeMath for uint112;
    using SafeMath for uint256;

    uint public reserve;
    address public energyFactory;
    uint public feeValue1;
    uint public feeValue0;
    struct Zircon {
        address pairAddress;
        address floatToken;
        address anchorToken;
        address energy0;
        address energy1;
        address pylon0;
        address pylon1;
    }
    Zircon public zircon;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        //    require(success && (data.length == 0 || abi.decode(data, (bool))), 'Zircon Pylon: TRANSFER_FAILED');

        // call failed
        if (!success) {
            // decode returndata
            // we need assembly cause there's no 'decodeWithSelector'
            string memory error;
            assembly {
            // mload(returndata) -> length of bytes
            // mload(returndata + 0x20) -> start of body
            //    first 4 bytes are TimeError.selector
                error := mload(add(data, 0x24))
            }

            // return time using logs
            require(success, error);
        }
    }
    // **** MODIFIERS *****
    uint public initialized = 0;

    modifier _initialize() {
        require(initialized == 1, 'Zircon: FORBIDDEN');
        _;
    }
    modifier _onlyPair() {
        require(zircon.pairAddress == msg.sender, "ZE: Not Pair");
        _;
    }

    constructor() public {
        energyFactory = msg.sender;
    }

    function initialize(address _pair, address _tokenA, address _tokenB, address _energy0, address _energy1, address _pylon0, address _pylon1) external {
        require(initialized == 0, "ZER: Not Factory");
        require(energyFactory == msg.sender, "ZER: Not Factory");
        zircon = Zircon(
            _pair,
            _tokenA,
            _tokenB,
            _energy0,
            _energy1,
            _pylon0,
            _pylon1
        );

        initialized = 1;

    }


    function setFeeValue(uint _feeValue0, uint _feeValue1) external {
        require(energyFactory == msg.sender, "ZER: Not Factory");
        feeValue1 = _feeValue1;
        feeValue0 = _feeValue0;
    }

    function calculate(uint percentage) external _onlyPair nonReentrant _initialize {
        uint balance = IUniswapV2ERC20(zircon.pairAddress).balanceOf(address(this));
        require(balance > reserve, "ZER: Reverted");

        //Percentage is feeValue/TPV, percentage of pool reserves that are actually fee
        //It's reduced by mint fee already
        uint totalSupply = IUniswapV2ERC20(zircon.pairAddress).totalSupply();
        //These are the PTBs, balance of pool tokens held by each pylon vault
        uint pylonBalance0 = IUniswapV2ERC20(zircon.pairAddress).balanceOf(zircon.pylon0);
        uint pylonBalance1 = IUniswapV2ERC20(zircon.pairAddress).balanceOf(zircon.pylon1);
        {
            (uint112 _reservePair0, uint112 _reservePair1,) = IZirconPair(zircon.pairAddress).getReserves();

            //Increments the contract variable that stores total fees acquired by pair. Multiplies by each Pylon's share

            feeValue0 += percentage.mul(_reservePair1).mul(2).mul(pylonBalance0)/totalSupply.mul(1e18);
            feeValue1 += percentage.mul(_reservePair0).mul(2).mul(pylonBalance1)/totalSupply.mul(1e18);
        }

        {
            uint feePercentageForRev = IZirconEnergyFactory(energyFactory).feePercentageRev();
            uint amount = balance.sub(reserve);
            uint pylon0Liq = (amount.mul(pylonBalance0)/totalSupply).mul(100 - feePercentageForRev)/(100);
            uint pylon1Liq = (amount.mul(pylonBalance1)/totalSupply).mul(100 - feePercentageForRev)/(100);

            _safeTransfer(zircon.pairAddress, zircon.energy0, pylon0Liq);
            _safeTransfer(zircon.pairAddress, zircon.energy1, pylon1Liq);
            reserve = balance.sub(pylon0Liq.add(pylon1Liq));
        }
    }

    function changePylonAddresses(address _pylonAddressA, address _pylonAddressB) external {
        require(msg.sender == energyFactory, 'Zircon: FORBIDDEN'); // sufficient check
        zircon.pylon0 = _pylonAddressA;
        zircon.pylon1 = _pylonAddressB;
    }

    function migrateLiquidity(address newEnergy) external{
        require(msg.sender == energyFactory, 'ZP: FORBIDDEN'); // sufficient check

        uint balance = IZirconPair(zircon.pairAddress).balanceOf(address(this));
        uint anchorBalance = IZirconPair(zircon.anchorToken).balanceOf(address(this));
        uint floatBalance = IZirconPair(zircon.floatToken).balanceOf(address(this));

        _safeTransfer(zircon.pairAddress, newEnergy, balance);
        _safeTransfer(zircon.anchorToken, newEnergy, anchorBalance);
        _safeTransfer(zircon.floatToken, newEnergy, floatBalance);
    }

    // Balances From Pair
    function getBalanceFromPair() external _initialize returns (uint balance) {
        require(msg.sender == zircon.pylon0 || msg.sender == zircon.pylon1, "ZE: Not Pylon");
        if(msg.sender == zircon.pylon0) {
            balance = feeValue0;
            feeValue0 = 0;

        } else if(msg.sender == zircon.pylon1) {
            balance = feeValue1;
            feeValue1 = 0;
        }
    }

    function getFees(address _token, uint _amount, address _to) external {
        require(msg.sender == energyFactory, "ZER: Not properly called");
        require(_amount != 0, "Operations: Cannot recover zero balance");

        if(_token == zircon.pairAddress) {
            require(_amount <= reserve, "ZER: Reverted");
            reserve = reserve.sub(_amount);
        }

        _safeTransfer(_token, _to, _amount);
    }
}