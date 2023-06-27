import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWWWWWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMWWNNNNXXX0KKKKKKKKKKKKKKKKXXNWWMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMWNXKK00KKKKKKKKKKKKKKKKKKKKKKKKKKKXNWMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMWNNNXKK000000KKKKKKKK0KKKK00KKKKKKKKKK00KXNWMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMWNXKKKKKKKK0000KKKKKK0000KK0000KKKKKKKKKKKKKKKKXNWMMMMMMMMMMMMMMMMMM
//MMMMMMMMMWNKK0OO0K00KKKKKKK00KKKK000KKK0000KKKKKKKKKKKKKKKKKKXNNWMMMMMMMMMMMMMMM
//MMMMMMMMNK00Oxdd0K0KKKK00KKKKKKKK00KKKKKKKKKKKKKKKKKK0KKKKKKKKKKKXWMMMMMMMMMMMMM
//MMMMMMMNK0Oxoolx0K000KK00KKKK00KKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKK0KXWMMMMMMMMMMM
//MMMMMMWX0kolollxKK000KKKKK0KKK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKkodOKNWMMMMMMMMM
//MMMMMMNKkolooolx0KKKK0KK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKo';k00KNMMMMMMMM
//MMMMMWXOxlllllld0KKK00K00KKKKKKKKKKKKKKKKK0KKKKK00KKKKKKKKKKKKKKd',x0000XWMMMMMM
//MMMMMN0xocccccclOK00OO00KKK000KKKKK00KKKKKKKKKKK0KKKKKKKKKKKK0KKx,,okxxxx0WMMMMM
//MMMMMNOxocccccclkKOolldOK000K000KKKKKKK0000KKKK000KK0KKKKKKK00KXk;'lkxxxxkXMMMMM
//MMMMMXkxdcccccccxKOoccoOKKK00KKK0KKKKKKKKKK00KKKK0KK00KKKKKKKKKKOl:oxxxxxkXMMMMM
//MMMMMKxxdcccccccd00dcclOK0KKKKKKKKKKKKKKKKKK0KKKKKK00KKKKKKKKKKK0xxxdxxxxxKWMMMM
//MMMMMKxxdcccccccd0KxlclkK00KKKKKKKKKKKKKKKKKKKKKKKKKKKKKK00KKKKK0kxxxxxxxx0WMMMM
//MMMMMKxdoccccccco0KklclkKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKKXKkxxxxxxxdONMMMM
//MMMMMKkxdlccccc:lOKOoclx0KKKKKKKKKKKKKKKKKXKKKKKKKKKKKKKKKKKKKKKKkxxxxxxxxONMMMM
//MMMMMKxxxlccccc:lkX0dclx0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0kxkkxxxxxkNMMMM
//MMMMMXxdxl:ccccccxKKxlcd0KKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKKKKK0K0kxkkkxxxxkNMMMM
//MMMMMXxddoc:cccccx0Kklcd0KKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKxclxxddxxkXMMMM
//MMMMMNkdxoccc:cc:d0KOocoOK0KKKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKXKo';dkddxxkXMMMM
//MMMMMNOdxdcccccc:o0X0dclOK0KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0o';dkxxxdkNMMMM
//MMMMMWOdxdlccccc:lOKKOxk0KKKKKKKKKKK0KKKKKK00KKKKKKKKKK0KKKKKKKK0o';oxxxxxONMMMM
//MMMMMW0xxdlcccccclkK000KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK0KKKKKKKKKo',oxxkxxONMMMM
//MMMMMMXxxxoccccccckKKKKKKKKKKKKKKKKKKKKK00KKKKKKKKKKKKKKKKKKKKKXKdcldxxxxxONMMMM
//MMMMMMNOxxocccccccxKKKKKKK00KKKKKKKKKKK00KKKKKKKKKKKKKKKKK0KKKK0kxkkxxkxxx0WMMMM
//MMMMMMN0xxdlcccccco0KKKKKKKKKKKKKKKK0KKKKKKKKKKKKKKKKKKKKKKKK0Okxxxxxxkxxx0WMMMM
//MMMMMMWKkkxxxdddddodkOOOOOOOOOOO000OOOOOOOOOOOOOOkkkkkkxxkkOkkkkkkddxxddod0WMMMM
//MMMMMMMXkxkkkkkkkkkxxxddxxxxdxxkkkxxxxxxxxxxxxxxxxxdxxxdxxkkkOOkxxxxxxxddxKMMMMM
//MMMMMMMNkxkkkkkkkOkkkkxxkxxxkxxkkkxdodkkkkkkkkOOOOOOkOOO000000OxxkxxxkxxxOXMMMMM
//MMMMMMMW0xkkkkkkkkOkkkkkxkkOOkkOO0000000000000000000OO00K000KK0xxkkkxkkkkONMMMMM
//MMMMMMMMKkkOOOkxxddddddk00KKKK0KKKKK0K00K0000000000K0KKKK00KKKOookkkkkkkxONMMMMM
//MMMMMMMMXkxkxolc:::::cd0KKKKKKKKK00000KKK0000000000K000K00KKKKx,,dkxkkkkx0WMMMMM
//MMMMMMMMNOxdc::::::::d0Oxxxk0000K000KK00K000O000000K000KKKKKKKd',dxxxxkkxKWMMMMM
//MMMMMMMMW0xo:::::::::dOdcccoOK0000KK00KKK000000000KK00KKKKKKKKd';oddxxkkkKMMMMMM
//MMMMMMMMMKko:;:::::::oOxclclkK00000000KKKKK00K0000KK00K000KKKKo';dxxxxxxkXMMMMMM
//MMMMMMMMMXkdc;;;;;::;cOklcccx00000000K00000000K00000OO00000KK0d,:dxdodxxONMMMMMM
//MMMMMMMMMNkoc;;;;;;;;:xOocccd0000KKKK0000KK000K00KK0000K00K00KOdxxxxdxddOWMMMMMM
//MMMMMMMMMWOdl;;;,,,;;;oOdcccoO0K0KK00KK000KKKKK000KK00K000KK00Oxdddddxdd0WMMMMMM
//MMMMMMMMMMKdl:;;;,,,,,lOdcccoO0000KKK00000000000000000K0O0K000kxxddddddxKMMMMMMM
//MMMMMMMMMMXxoc;,;;;,,,ckklcclkOOOOOOOOO00000000000000000O00000kdddoooooxXMMMMMMM
//MMMMMMMMMMNkol;,,,,,,,:xOocclxOOOOOOO000000000000000KKK0000000koodoollokNMMMMMMM
//MMMMMMMMMMW0dd:;;;,,;;;oOxcccdO0OOO000000OO0000K0000KKKKKKK000kdoddooooOWMMMMMMM
//MMMMMMMMMMMKdoc;;;,;;;;lOklccdO00000000000O00KKK00KKKKKKKKKK00OdooddoooOWMMMMMMM
//MMMMMMMMMMMXxol;;;;;;;;ckOoccoO00KKK0000000KKKKKK0KKKKKKKKKKKKOdddddxdxXMMMMMMMM
//MMMMMMMMMMMWOdo:,;;;;;;;dOdccoO00KKK000KK0000KKK00KK000KKKKKKKOxddxkkxONMMMMMMMM
//MMMMMMMMMMMWKddl;;;;;;;;o0klcoO00K00000000000KKKKKKK00KKKKKK0K0kxxxkkx0WMMMMMMMM
//MMMMMMMMMMMMXxxdc;:::;;;l00oclk00000000000000000KKKK00KK000K00OxdodxxxKMMMMMMMMM
//MMMMMMMMMMMMNOxxl::::;;,:k0dclx0000000000000000000KK0000000000kddddddkXMMMMMMMMM
//MMMMMMMMMMMMWKxko:::::;,;x0xlcd00O0000000000000000K000000000KKOxxxxxxONMMMMMMMMM
//MMMMMMMMMMMMMXxxxc::::;;;dK0xok0K0000000000000000KK0000KKKK0Okkddxxxx0WMMMMMMMMM
//MMMMMMMMMMMMMXxdxl::::;,,o0K00KK0KK00000K000KKKK00K00K00KKKOc'lxxxxxkKMMMMMMMMMM
//MMMMMMMMMMMMMNOxxl::::::;cOKKKKKK00000000000000K00KKKKKKK0Kx;'lxdxxxONMMMMMMMMMM
//MMMMMMMMMMMMMMXkxd:;:;;:::xKKKKKKKKKKK0000K000KKKKKKKKKK00Kd',oxxddx0WMMMMMMMMMM
//MMMMMMMMMMMMMMNkddl:;;::;;dKKKKKKKKKKKK0000000KKKKKKKKKKKK0l':dxdddxKMMMMMMMMMMM
//MMMMMMMMMMMMMMW0dddoc::::;o0KKKK0KKKKKKKKKK00KKKKK0KKK00KKOl,lxxxxdkXMMMMMMMMMMM
//MMMMMMMMMMMMMMMXkkkkxdl:;;cOKKKK0KKKKKKKKKKKK000KK00KKKKKK00xxxxxxxOWMMMMMMMMMMM
//MMMMMMMMMMMMMMMNOxkkkxxdc::xKKKKKKKKKKKKKKKK0000KK00000KK0K0kdxxddkXMMMMMMMMMMMM
//MMMMMMMMMMMMMMMW0xxkkxxxdoodOKKKKKKKKKKKKKK000K00KK000K0KK0OxodxxkXMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMXxdxxxxxddddxO0K0K000KK000KKKK00000000000OkxkxxxKWMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMW0xxxxxxkxxddxk0K0000KKKKKKKK00K00000OkkkkkkkdxKWMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMWKOkxxxkxxxxxxkO0KKKKKKKKKKKKKK000Okxxxkkkxo:dNMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMNX0OkkxxxxxxxxkOOOOOOOOOOOOkOkkxxxdxkkk0x',OMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMWWKocllox0O0000000O0000000OxodddkO0KNWXodNMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMWd...,OMMMMMMMMMMMMMMMMWNo''.cKWWMMMMWWMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMXc..oNMMMMMMMMMMMMMMMMMMK:.'xWMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMM0;;0MMMMMMMMMMMMMMMMMMMWk,lXMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMMMMMMMMMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
//MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM

contract Fridge is Context, Ownable {
    /*
        The Fridge takes in WETH and reinforces DC. This first version can buy
        DC and add DC-WETH LP for price stability.
    */

    IUniswapV2Pair dcPair;
    IUniswapV2Router02 uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address WETH;
    address DC;
    struct PriceReading { 
        uint128 dcWeth;
        uint128 block;
    }
    PriceReading reading1 = PriceReading(800000, 0);
    PriceReading reading2 = PriceReading(800000, 1); 
    address dev1;
    address dev2;
    uint32 lastWithdrawal;
    using SafeMath for uint256;
    using SafeMath for uint128;
    using SafeMath for uint32;

    constructor (address DogCatcher, address pair) {
        DC = DogCatcher;
        dcPair = IUniswapV2Pair(pair);
        WETH = uniRouter.WETH();
        lastWithdrawal = uint32(block.timestamp);
        IERC20(WETH).approve(address(uniRouter), type(uint256).max);
        IERC20(DC).approve(address(uniRouter), type(uint256).max);
    }

    function setDevs(address new_dev1, address new_dev2) public onlyOwner() {
        // Operators who call the snack & preserve functions.
        dev1 = new_dev1;
        dev2 = new_dev2;
    }

    function updatePrice() external {
        // The DC/WETH exchange rate is recorded in two alternating buckets,
        // so the effective mint price is always taken from a prior block.
        (uint reserve0, uint reserve1,) = dcPair.getReserves();
        (uint256 wethReserves, uint256 dcReserves) = WETH < DC ? (reserve0, reserve1) : (reserve1, reserve0);
        uint128 new_dcWeth = uint128(dcReserves.mul(10**9) / wethReserves);
        if (reading1.block < reading2.block && reading2.block < block.number) {
            reading1.dcWeth = new_dcWeth; 
            reading1.block = uint128(block.number);
        } else if (reading1.block > reading2.block && reading1.block < block.number) {
            reading2.dcWeth = new_dcWeth; 
            reading2.block = uint128(block.number);
        }
    }

    function valuate(uint256 ethAmount) public view returns (uint256 dcAmount) {
        // Calculate an amount of DC to mint given ETH.
        PriceReading memory toRead = reading1.block < reading2.block ? reading1 : reading2;
        dcAmount = ethAmount.mul(toRead.dcWeth) / 10**9;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'Zero input');
        require(reserveIn > 0 && reserveOut > 0, 'Zero liquidity');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function snack(uint256 amountIn, uint256 amountOutMin, uint deadline) public {
        require(block.timestamp < deadline, "Expired.");
        require(_msgSender() == dev1 || _msgSender() == dev2, "Permission denied!");
        uint amountOutput;
        {
        (uint reserve0, uint reserve1,) = dcPair.getReserves();
        (uint reserveInput, uint reserveOutput) = WETH < DC ? (reserve0, reserve1) : (reserve1, reserve0);
        IERC20(WETH).transfer(address(dcPair), amountIn);
        amountOutput = getAmountOut(amountIn, reserveInput, reserveOutput);
        require(amountOutput>= amountOutMin, 'Slipped.');
        }
        (uint amount0Out, uint amount1Out) = WETH < DC ? (uint(0), amountOutput) : (amountOutput, uint(0));
        dcPair.swap(amount0Out, amount1Out, address(this), new bytes(0));

    }

    function preserve(uint256 amountWETHDesired, uint256 amountDCDesired, uint256 amountWETHMin, uint256 amountDCMin,  uint256 deadline) public { 
        // Add WETH+DC LP.
        require(_msgSender() == dev1 || _msgSender() == dev2, "Permission denied!");
        uniRouter.addLiquidity(WETH, DC, amountWETHDesired, amountDCDesired, amountWETHMin, amountDCMin, address(this), deadline);
    }

    function raid() public {
        // Contract creators can each withdraw 1% of liquidity every 30 days.
        // This is a dev fee that helps cover ongoing gas fees for calls to
        // snack() and preserve().
        require(lastWithdrawal < (block.timestamp - 30 days), "Don't be greedy!");
        uint256 ruggableLPBalance = dcPair.balanceOf(address(this)).div(50);
        IERC20(address(dcPair)).transfer(dev1, ruggableLPBalance.div(2));
        IERC20(address(dcPair)).transfer(dev2, ruggableLPBalance.div(2));
        lastWithdrawal = uint32(block.timestamp);
    }

    //Fail-safe functions for releasing tokens we don't care about, not meant to be used.
    function release(address token) public {
        require (token != WETH);
        require (token != DC);
        require (token != address(dcPair));
        IERC20(token).transfer(owner(), 
            IERC20(token).balanceOf(address(this)));
    }

}