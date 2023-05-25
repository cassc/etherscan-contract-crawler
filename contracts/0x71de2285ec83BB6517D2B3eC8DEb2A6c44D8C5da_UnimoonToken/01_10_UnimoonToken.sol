//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/ITreasury.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./pancake-swap/libraries/TransferHelper.sol";

contract UnimoonToken is ERC20, Ownable {
    uint8 public constant DENOMINATOR = 100;

    address public immutable FACTORY;
    address public immutable PAIR;

    address public treasury;
    uint256 public threshold;
    uint8 public sellFee = 5;
    uint8 public buyFee = 5;

    AntiBotInfo public antibot;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => uint256) private _totalPurchased;

    struct AntiBotInfo {
        bool perTxnEnabled;
        bool perWalletEnabled;
        uint16 maxPercPerTxn;
        uint16 maxPercPerWallet;
        uint16 denominator;
    }

    event FeeClaimed(uint256 totalFee);

    constructor(
        address _factory,
        address _firstHolder,
        uint256 _initialSupply,
        uint256 _threshold,
        address _usdc,
        AntiBotInfo memory _antibot
    ) ERC20("Unimoon", "Umoon") {
        require(
            _factory != address(0) &&
                _firstHolder != address(0) &&
                _usdc != address(0),
            "UnimoonToken: address 0x0..."
        );
        require(_initialSupply > 0, "UnimoonToken: amount 0");
        require(
            _antibot.maxPercPerTxn <= _antibot.denominator &&
                _antibot.maxPercPerWallet <= _antibot.denominator,
            "UnimoonToken: wrong antibot values"
        );
        FACTORY = _factory;
        threshold = _threshold;
        antibot = _antibot;

        PAIR = IFactory(_factory).createPair(address(this), _usdc);
        isExcludedFromFee[_firstHolder] = true;
        _mint(_firstHolder, _initialSupply);
    }

    /** @dev Function to change treasury contract address
     * @notice available for owner only
     * @param _treasury new treasury contract address
     */
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "UnimoonToken: wrong input");
        if (treasury != address(0)) isExcludedFromFee[treasury] = false;
        isExcludedFromFee[_treasury] = true;
        treasury = _treasury;
    }

    /** @dev Function to change liquidity threshold
     * @notice available for owner only
     * @param _threshold new liquidity threshold
     */
    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    /** @dev Function to change swap fees
     * @notice available for owner only
     * @param _sell new sell fee precent
     * @param _buy new buy fee precent
     */
    function setSwapFees(uint8 _sell, uint8 _buy) external onlyOwner {
        require(
            _sell < DENOMINATOR && _buy < DENOMINATOR,
            "UnimoonToken: wrong fee percents"
        );
        sellFee = _sell;
        buyFee = _buy;
    }

    /** @dev Function to include/exclude an account from/to swap fees
     * @notice available for owner only
     * @param account account is necessary to include/exclude
     */
    function changeExcludedFromFee(address account) external onlyOwner {
        require(account != treasury, "UnimoonToken: wrong input");
        isExcludedFromFee[account] = !isExcludedFromFee[account];
    }

    /** @dev Function to change antibot limit percents
     * @notice available for owner only
     * @param perTxnPercent new percent value
     * @param perWalletPercent new percent value
     */
    function changeAntibotConfiguration(
        uint16 perTxnPercent,
        uint16 perWalletPercent
    ) external onlyOwner {
        require(
            perTxnPercent <= antibot.denominator &&
                perWalletPercent <= antibot.denominator,
            "UnimoonToken: wrong values"
        );
        antibot.maxPercPerTxn = perTxnPercent;
        antibot.maxPercPerWallet = perWalletPercent;
    }

    /** @dev Function to change antibot limit status
     * @notice available for owner only
     * @param perTxn new status value
     * @param perWallet new status value
     */
    function changeAntibotStatus(bool perTxn, bool perWallet)
        external
        onlyOwner
    {
        antibot.perTxnEnabled = perTxn;
        antibot.perWalletEnabled = perWallet;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        bool isSell = _pairCheck(to);
        bool isBuy = _pairCheck(from);

        if (isBuy) {
            if (antibot.perTxnEnabled && antibot.maxPercPerTxn > 0)
                require(
                    amount <=
                        (antibot.maxPercPerTxn * totalSupply()) /
                            (antibot.denominator),
                    "UnimoonToken: antibot: too large purchase"
                );
            if (antibot.perWalletEnabled && antibot.maxPercPerWallet > 0)
                require(
                    _totalPurchased[to] + amount <=
                        (antibot.maxPercPerWallet * totalSupply()) /
                            antibot.denominator,
                    "UnimoonToken: antibot: limit has been reached"
                );
            _totalPurchased[to] += amount;
        }

        uint256 fees;
        if (
            ((isSell && !isExcludedFromFee[from]) ||
                (isBuy && !isExcludedFromFee[to])) && treasury != address(0)
        ) {
            if (isSell) fees = (amount * sellFee) / DENOMINATOR;
            else fees = (amount * buyFee) / DENOMINATOR;
        }
        if (fees > 0) {
            super._transfer(from, treasury, fees);
            emit FeeClaimed(fees);
        }
        (uint256 reserve0, uint256 reserve1, ) = IPair(PAIR).getReserves();
        if (
            from != PAIR &&
            balanceOf(treasury) >= threshold &&
            treasury != address(0) &&
            from != treasury &&
            reserve0 != 0 &&
            reserve1 != 0
        ) ITreasury(treasury).swapUnimoonToUSDC();
        super._transfer(from, to, amount - fees);
    }

    function _pairCheck(address _token) internal view returns (bool) {
        address token0;
        address token1;

        if (isContract(_token)) {
            try IPair(_token).token0() returns (address _token0) {
                token0 = _token0;
            } catch {
                return false;
            }

            try IPair(_token).token1() returns (address _token1) {
                token1 = _token1;
            } catch {
                return false;
            }

            address goodPair = IFactory(FACTORY).getPair(token0, token1);
            if (goodPair != _token) {
                return false;
            }

            if (token0 == address(this) || token1 == address(this)) return true;
            else return false;
        } else return false;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}