// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IERCBurn.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IUniFactory.sol";
import "./interfaces/IUniswapV2Pair.sol";

import "./interfaces/IUniswapV3Factory.sol";
import "./interfaces/IUniswapV3Pool.sol";

import "./Farm.sol";

contract FarmGenerator is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    IFactory public factory;
    IUniFactory public uniswapFactory;
    IUniswapV3Factory public uniswapFactoryV3;

    address payable devaddr;
 
    struct FeeStruct {
        IERCBurn gasToken;
        bool useGasToken; // set to false to waive the gas fee
        uint256 gasFee; // the total amount of gas tokens to be burnt (if used)
        uint256 ethFee; // Small eth fee to prevent spam on the platform
        uint256 tokenFee; // Divided by 1000, fee on farm rewards
        uint256 referralFee;
    }

    FeeStruct public gFees;

    struct FarmParameters {
        uint256 fee;
        uint256 amountMinusFee;
        uint256 bonusBlocks;
        uint256 totalBonusReward;
        uint256 numBlocks;
        uint256 endBlock;
        uint256 requiredAmount;
        uint256 amountFee;
        uint256 referralFee;
    }

    constructor(IFactory _factory, IUniFactory _uniswapFactory, IUniswapV3Factory _uniswapFactoryV3) {
        factory = _factory;
        devaddr = payable(msg.sender);
        // gFees.useGasToken = false;
        // gFees.gasFee = 1 * (10**18);
        // gFees.ethFee = 2e17;
        gFees.tokenFee = 50; // 5%
        uniswapFactory = _uniswapFactory;
        uniswapFactoryV3 = _uniswapFactoryV3;
        gFees.referralFee = 10; // 1%
    }

    /**
     * @notice Below are self descriptive gas fee and general settings functions
     */
    function setGasToken(IERCBurn _gasToken) public onlyOwner {
        gFees.gasToken = _gasToken;
    }

    function setGasFee(uint256 _amount) public onlyOwner {
        gFees.gasFee = _amount;
    }

    function setEthFee(uint256 _amount) public onlyOwner {
        gFees.ethFee = _amount;
    }

    function setTokenFee(uint256 _amount) public onlyOwner {
        gFees.tokenFee = _amount;
    }

    function setRequireGasToken(bool _useGasToken) public onlyOwner {
        gFees.useGasToken = _useGasToken;
    }

    function setDev(address payable _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    /**
     * @notice Determine the endBlock based on inputs. Used on the front end to show the exact settings the Farm contract will be deployed with
     */
    function determineEndBlock(
        uint256 _amount,
        uint256 _blockReward,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonus,
        bool _referral
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        FarmParameters memory params;
        params.fee = _amount.mul(gFees.tokenFee).div(1000);
        params.amountMinusFee = _amount.sub(params.fee);
        params.bonusBlocks = _bonusEndBlock.sub(_startBlock);
        params.totalBonusReward = params.bonusBlocks.mul(_bonus).mul(
            _blockReward
        );
        params.numBlocks = params
            .amountMinusFee
            .sub(params.totalBonusReward)
            .div(_blockReward);
        params.endBlock = params.numBlocks.add(params.bonusBlocks).add(
            _startBlock
        );

        uint256 nonBonusBlocks = params.endBlock.sub(_bonusEndBlock);
        uint256 effectiveBlocks = params.bonusBlocks.mul(_bonus).add(
            nonBonusBlocks
        );
        uint256 requiredAmount = _blockReward.mul(effectiveBlocks);
        if (_referral) {
            return (
                params.endBlock,
                requiredAmount,
                requiredAmount.mul(gFees.tokenFee.sub(gFees.referralFee)).div(
                    1000
                )
            );
        } else {
            return (
                params.endBlock,
                requiredAmount,
                requiredAmount.mul(gFees.tokenFee).div(1000)
            );
        }
    }

    /**
     * @notice Determine the blockReward based on inputs specifying an end date. Used on the front end to show the exact settings the Farm contract will be deployed with
     */
    function determineBlockReward(
        uint256 _amount,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonus,
        uint256 _endBlock
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 fee = _amount.mul(gFees.tokenFee).div(1000);
        uint256 amountMinusFee = _amount.sub(fee);
        uint256 bonusBlocks = _bonusEndBlock.sub(_startBlock);
        uint256 nonBonusBlocks = _endBlock.sub(_bonusEndBlock);
        uint256 effectiveBlocks = bonusBlocks.mul(_bonus).add(nonBonusBlocks);
        uint256 blockReward = amountMinusFee.div(effectiveBlocks);
        uint256 requiredAmount = blockReward.mul(effectiveBlocks);
        return (
            blockReward,
            requiredAmount,
            requiredAmount.mul(gFees.tokenFee).div(1000)
        );
    }

    /**
     * @notice Creates a new Farm contract and registers it in the FarmFactory.sol. All farming rewards are locked in the Farm Contract
     */
    function createFarmV2(
        IERC20 _rewardToken,
        uint256 _amount,
        IERC20 _lpToken,
        uint256 _blockReward,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonus,
        bool _referral
    ) public returns (address) {
        require(_startBlock > block.number, "START"); // ideally at least 24 hours more to give farmers time
        require(_bonus > 0, "BONUS");
        require(address(_rewardToken) != address(0), "TOKEN");
        require(_blockReward > 1000, "BR"); // minimum 1000 divisibility per block reward

        // ensure this pair is on uniswap by querying the factory

        IUniswapV2Pair lpair = IUniswapV2Pair(address(_lpToken));
        address factoryPairAddress = uniswapFactory.getPair(
            lpair.token0(),
            lpair.token1()
        );
        require(
            factoryPairAddress == address(_lpToken),
            "This pair is not on uniswap"
        );

        FarmParameters memory params;
        (
            params.endBlock,
            params.requiredAmount,
            params.amountFee
        ) = determineEndBlock(
            _amount,
            _blockReward,
            _startBlock,
            _bonusEndBlock,
            _bonus,
            _referral
        );
        _rewardToken.transferFrom(
            address(msg.sender),
            devaddr,
            params.amountFee
        );
        
        Farm newFarm = new Farm(address(factory), address(this));
        require(
            _rewardToken.transferFrom(
                msg.sender,
                address(newFarm),
                params.requiredAmount
            ),
            "Token transfer failed."
        );
        newFarm.init(
            _rewardToken,
            params.requiredAmount,
            _lpToken,
            _blockReward,
            _startBlock,
            params.endBlock,
            _bonusEndBlock,
            _bonus
        );

        factory.registerFarm(address(newFarm));
        return (address(newFarm));
    }

    function createFarmV3(
        IERC20 _rewardToken,
        uint256 _amount,
        IERC20 _lpToken,
        uint256 _blockReward,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonus,
        bool _referral
    ) public returns (address) {
        require(_startBlock > block.number, "START"); // ideally at least 24 hours more to give farmers time
        require(_bonus > 0, "BONUS");
        require(address(_rewardToken) != address(0), "TOKEN");
        require(_blockReward > 1000, "BR"); // minimum 1000 divisibility per block reward

        // ensure this pair is on uniswap by querying the factory
        IUniswapV3Pool lpool = IUniswapV3Pool(address(_lpToken));
        address factoryPoolAddress = uniswapFactoryV3.getPool(
            lpool.token0(),
            lpool.token1(),
            lpool.fee()
        );
        require(
            factoryPoolAddress == address(_lpToken),
            "This pair is not on uniswap"
        );

        FarmParameters memory params;
        (
            params.endBlock,
            params.requiredAmount,
            params.amountFee
        ) = determineEndBlock(
            _amount,
            _blockReward,
            _startBlock,
            _bonusEndBlock,
            _bonus,
            _referral
        );
        _rewardToken.transferFrom(
            address(msg.sender),
            devaddr,
            params.amountFee
        );
        
        Farm newFarm = new Farm(address(factory), address(this));
        require(
            _rewardToken.transferFrom(
                msg.sender,
                address(newFarm),
                params.requiredAmount
            ),
            "Token transfer failed."
        );
        newFarm.init(
            _rewardToken,
            params.requiredAmount,
            _lpToken,
            _blockReward,
            _startBlock,
            params.endBlock,
            _bonusEndBlock,
            _bonus
        );

        factory.registerFarmV3(address(newFarm));
        return (address(newFarm));
    }
}