// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IAgent.sol";
import "./interfaces/ICharity.sol";

contract GreenWorld is ERC20, Ownable {
    IFactory public immutable factory;
    IAgent public immutable agent;
    ICharity public charity;
    address public immutable ecosystem;
    address public staking;

    uint256 public liquidityFeeSell;
    uint256 public charityFeeSell;
    uint256 public stakingRewardFeeSell;
    uint256 public ecosystemFeeSell;

    uint256 public liquidityFeeBuy;
    uint256 public charityFeeBuy;
    uint256 public stakingRewardFeeBuy;
    uint256 public ecosystemFeeBuy;

    uint256 private constant PERCENT = 1000;
    uint256 private constant MAX_SUM_FEE_PERCENTS = 200;

    mapping(address => bool) public isExcludedFromFee;

    struct FeesAmount {
        uint256 liquidity;
        uint256 charity;
        uint256 ecosystem;
        uint256 stakingReward;
    }

    constructor(
        address[] memory addresses,
        uint256[] memory amounts,
        uint256[] memory feesSell,
        uint256[] memory feesBuy,
        IFactory _factory,
        IAgent _agent
    ) ERC20("GreenWorld", "GWD") {
        require(addresses.length == amounts.length, "Wrong inputs");
        for (uint256 i = 0; i < amounts.length; i++) {
            isExcludedFromFee[addresses[i]] = true;
            _mint(addresses[i], amounts[i] * 10**decimals());
        }

        liquidityFeeSell = feesSell[0];
        charityFeeSell = feesSell[1];
        stakingRewardFeeSell = feesSell[2];
        ecosystemFeeSell = feesSell[3];

        liquidityFeeBuy = feesBuy[0];
        charityFeeBuy = feesBuy[1];
        stakingRewardFeeBuy = feesBuy[2];
        ecosystemFeeBuy = feesBuy[3];

        factory = _factory;
        agent = _agent;
        ecosystem = addresses[5];
        isExcludedFromFee[address(agent)] = true;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /** @dev Change isExcludedFromFee status
     *  @param _account an address of account to change
     */
    function changeExcludedFromFee(address _account) external onlyOwner {
        isExcludedFromFee[_account] = !isExcludedFromFee[_account];
    }

    /**
     @dev Change liquidity sell and buy fee. Onle for owner
     @param buy new liquidityFeeBuy. Enter as x * 10
     @param sell new liquidityFeeSell. Enter as x * 10 
     */
    function changeLiquidityFee(uint256 buy, uint256 sell) external onlyOwner {
        require(
            buy + charityFeeBuy + ecosystemFeeBuy + stakingRewardFeeBuy <=
                MAX_SUM_FEE_PERCENTS &&
                sell +
                    charityFeeSell +
                    ecosystemFeeSell +
                    stakingRewardFeeSell <=
                MAX_SUM_FEE_PERCENTS,
            "Fees > 20%!"
        );
        liquidityFeeBuy = buy;
        liquidityFeeSell = sell;
    }

    /**
     @dev Change charity sell and buy fee. Onle for owner
     @param buy new charityFeeBuy. Enter as x * 10
     @param sell new charityFeeSell. Enter as x * 10 
     */
    function changeCharityFee(uint256 buy, uint256 sell) external onlyOwner {
        require(
            buy + liquidityFeeBuy + ecosystemFeeBuy + stakingRewardFeeBuy <=
                MAX_SUM_FEE_PERCENTS &&
                sell +
                    liquidityFeeSell +
                    ecosystemFeeSell +
                    stakingRewardFeeSell <=
                MAX_SUM_FEE_PERCENTS,
            "Fees > 20%!"
        );
        charityFeeBuy = buy;
        charityFeeSell = sell;
    }

    /**
     @dev Change ecosystem sell and buy fee. Onle for owner
     @param buy new ecosystemFeeBuy. Enter as x * 10
     @param sell new ecosystemFeeSell. Enter as x * 10 
     */
    function changeEcosystemFee(uint256 buy, uint256 sell) external onlyOwner {
        require(
            buy + charityFeeBuy + liquidityFeeBuy + stakingRewardFeeBuy <=
                MAX_SUM_FEE_PERCENTS &&
                sell +
                    charityFeeSell +
                    liquidityFeeSell +
                    stakingRewardFeeSell <=
                MAX_SUM_FEE_PERCENTS,
            "Fees > 20%!"
        );
        ecosystemFeeBuy = buy;
        ecosystemFeeSell = sell;
    }

    /**
     @dev Change staking reward sell and buy fee. Onle for owner
     @param buy new stakingRewardFeeBuy. Enter as x * 10
     @param sell new stakingRewardFeeSell. Enter as x * 10 
     */
    function changeStakingRewardFee(uint256 buy, uint256 sell)
        external
        onlyOwner
    {
        require(
            buy + charityFeeBuy + ecosystemFeeBuy + liquidityFeeBuy <=
                MAX_SUM_FEE_PERCENTS &&
                sell + charityFeeSell + ecosystemFeeSell + liquidityFeeSell <=
                MAX_SUM_FEE_PERCENTS,
            "Fees > 20%!"
        );
        stakingRewardFeeBuy = buy;
        stakingRewardFeeSell = sell;
    }

    /**
     @dev Sets staking address for sending reward. Only for owner
     @param _staking staking address
     */
    function setStaking(address _staking) external onlyOwner {
        require(
            _staking != address(0) && staking == address(0),
            "Staking address is not 0"
        );
        staking = _staking;
        _mint(_staking, 75000000 * (10**decimals()));
    }

    /**
     @dev Sets charity address for sending fee. Only for owner
     @param _charity charity address
     */
    function setCharity(ICharity _charity) external onlyOwner {
        charity = _charity;
        isExcludedFromFee[address(_charity)] = true;
    }

    /**
     @dev Overrided ERC20 transfer. If msg.sender address = pair => buy.
     If buy and 'to' address is not excluded from fee => takes fee
     */
    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        address _owner = _msgSender();
        bool isPair = _pairCheck(_owner);
        if (isPair && !isExcludedFromFee[to]) {
            FeesAmount memory fees;
            if (liquidityFeeBuy > 0) {
                fees.liquidity = (amount * liquidityFeeBuy) / PERCENT;
                _transfer(_owner, address(agent), fees.liquidity);
                agent.increaseStock(fees.liquidity);
            }
            if (charityFeeBuy > 0 && address(charity) != address(0)) {
                fees.charity = (amount * charityFeeBuy) / PERCENT;
                _transfer(_owner, address(charity), fees.charity);
                charity.addToCharity(fees.charity, to);
            }
            if (ecosystemFeeBuy > 0) {
                fees.ecosystem = (amount * ecosystemFeeBuy) / PERCENT;
                _transfer(_owner, ecosystem, fees.ecosystem);
            }
            if (stakingRewardFeeBuy > 0 && staking != address(0)) {
                fees.stakingReward = (amount * stakingRewardFeeBuy) / PERCENT;
                _transfer(_owner, staking, fees.stakingReward);
            }
            uint256 amountWithFee = amount -
                fees.liquidity -
                fees.charity -
                fees.ecosystem -
                fees.stakingReward;
            _transfer(_owner, to, amountWithFee);
        } else {
            _transfer(_owner, to, amount);
            if (!isPair) {
                charity.swapNow();
                if (
                    (agent.getStock() > agent.getThreshold()) &&
                    (_owner != address(agent))
                ) {
                    agent.autoLiquidity();
                }
            }
        }
        return true;
    }

    /**
     @dev Overrided ERC20 transferFrom. If 'to' address = pair => sell.
     If sell and 'from' address is not excluded from fee => takes fee
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        _spendAllowance(from, _msgSender(), amount);
        bool isPair = _pairCheck(to);
        if (isPair && !isExcludedFromFee[from]) {
            FeesAmount memory fees;
            if (liquidityFeeSell > 0) {
                fees.liquidity = (amount * liquidityFeeSell) / PERCENT;
                _transfer(from, address(agent), fees.liquidity);
                agent.increaseStock(fees.liquidity);
            }
            if (charityFeeSell > 0 && address(charity) != address(0)) {
                fees.charity = (amount * charityFeeSell) / PERCENT;
                _transfer(from, address(charity), fees.charity);
                charity.addToCharity(fees.charity, from);
            }
            if (ecosystemFeeSell > 0) {
                fees.ecosystem = (amount * ecosystemFeeSell) / PERCENT;
                _transfer(from, ecosystem, fees.ecosystem);
            }
            if (stakingRewardFeeSell > 0 && staking != address(0)) {
                fees.stakingReward = (amount * stakingRewardFeeSell) / PERCENT;
                _transfer(from, staking, fees.stakingReward);
            }
            uint256 amountWithFee = amount -
                fees.liquidity -
                fees.charity -
                fees.ecosystem -
                fees.stakingReward;
            _transfer(from, to, amountWithFee);
        } else {
            _transfer(from, to, amount);
            if (!isPair) {
                charity.swapNow();
                if (
                    (agent.getStock() > agent.getThreshold()) &&
                    (from != address(agent))
                ) {
                    agent.autoLiquidity();
                }
            }
        }
        return true;
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

            address goodPair = factory.getPair(token0, token1);
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