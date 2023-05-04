// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/DexRouter.sol";

import "./libraries/ABDKMathQuad.sol";
import "./ProjectManager.sol";
import "./ArtikProjectManager.sol";
import "./ArtikStakeManager.sol";
import "./ArtikProjectManagerV2.sol";
import "./ArtikStakeManagerV2.sol";
import "./ArtikStakeManagerV1.sol";
import "./ArtikProjectManagerV1.sol";

import "./StakeManagerV1.sol";
import "./ProjectManagerV1.sol";

contract TreasuryV1 is Initializable {
    using SafeMath for uint256;

    // Pancakeswap 0x10ED43C718714eb63d5aA57B78B54704E256024E (testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3)
    address constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // WBNB 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (testnet: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd)
    address constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    // BUSD 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56 (testnet: 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7)
    address constant STABLE_COIN = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    uint256 private constant BUY_BACK_FEE = 25; //(2% of total fee)
    uint256 private accumulatedEthForAirdrop;

    DexRouter private dexRouter;

    address private artikToken;
    address payable private admin;

    address[] public shareholders;
    uint256 private shareholderCount;
    mapping(address => uint256) private shareholderIndexes;

    mapping(address => mapping(uint256 => bool)) private userClaimedProject;
    uint256 public totalAmountAirdropped;
    mapping(address => uint256) public amountClaimed;

    uint256 public airdropBalance;
    uint256 public totalHoldersBalance;
    uint256 public airdropDate;

    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        private userHasClaimedProject;

    mapping(uint256 => uint256) private airdropSnapshot;
    uint256 private stableCoinBalance;

    ProjectManager private projectManager; // to remove
    address private projectManagerAddress;

    mapping(address => uint256) public holderSellingDays;
    uint256 private holdingDays;

    ArtikProjectManager private artikProjectManager;
    ArtikStakeManager private artikStakeManager;
    mapping(uint256 => uint256) public airdropDates;

    ArtikProjectManagerV2 private artikProjectManagerV2;
    ArtikStakeManagerV2 private artikStakeManagerV2;
    ArtikStakeManagerV1 private artikStakeManagerV1;
    ArtikProjectManagerV1 private artikProjectManagerV1;

    StakeManagerV1 private stakeManagerV1;
    ProjectManagerV1 private projectManagerV1;

    modifier onlyAdmin() {
        require(
            msg.sender == admin ||
                msg.sender == artikToken ||
                msg.sender == projectManagerAddress
        );
        _;
    }

    function initialize(address _tokenAddress) public initializer {
        dexRouter = DexRouter(ROUTER);
        artikToken = _tokenAddress;
        admin = payable(msg.sender);
        shareholderCount = 0;
        totalAmountAirdropped = 0;
        accumulatedEthForAirdrop = 0;
        totalHoldersBalance = 0;
        airdropBalance = 0;
        stableCoinBalance = 0;
    }

    function configureManagers(
        address _projectManagerAddr,
        address _stakeManagerAddr
    ) external onlyAdmin {
        require(_projectManagerAddr != address(0x0));
        require(_stakeManagerAddr != address(0x0));
        projectManagerAddress = _projectManagerAddr;
        projectManagerV1 = ProjectManagerV1(_projectManagerAddr);
        stakeManagerV1 = StakeManagerV1(_stakeManagerAddr);
    }

    function getAirdropDate(
        uint256 _roundNumber
    ) external view returns (uint256) {
        require(_roundNumber > 0);
        return airdropDates[_roundNumber];
    }

    function setAirdropDate(uint256 _days) public onlyAdmin {
        require(_days > 0);
        airdropDates[projectManagerV1.roundNumber()] =
            block.timestamp +
            (1 days * _days);
    }

    // Initialize airdrop
    // 1) approveAirdrop
    // 2) buyBack
    // 3) buyAirdropTokens
    // 4) initializeNextRound
    function approveAirdrop() external onlyAdmin {
        uint256 stableBalance = IERC20(STABLE_COIN).balanceOf(address(this));
        require(stableBalance > 0);

        IERC20(STABLE_COIN).approve(ROUTER, stableBalance);
        (uint256 amountWethMin, ) = getAmountOutMin(
            stableBalance,
            STABLE_COIN,
            WETH
        );
        IERC20(WETH).approve(ROUTER, amountWethMin);
    }

    function buyBack() external onlyAdmin {
        uint256 stableBalance = IERC20(STABLE_COIN).balanceOf(address(this));
        require(stableBalance > 0);

        swapTokensForETH(mulDiv(stableBalance, BUY_BACK_FEE, 100), STABLE_COIN);
        swapETHForTokens(address(this).balance, artikToken);
        IERC20(artikToken).transfer(
            address(0x0),
            IERC20(artikToken).balanceOf(address(this))
        );
    }

    function buyAirdropTokens(
        uint256 _amount,
        address _token1,
        address _token2
    ) external onlyAdmin {
        require(_amount > 0);
        require(_token1 != address(0x0));
        require(_token2 != address(0x0));
        require(
            IERC20(_token1).balanceOf(address(this)) >= _amount,
            "balance less than _amount"
        );

        address[] memory path = new address[](2);
        path[0] = _token1;
        path[1] = _token2;

        dexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function initializeNextRound(uint256 _days) external onlyAdmin {
        require(_days > 0);

        projectManagerV1.nextRound();
        setAirdropDate(_days);
        airdropBalance = IERC20(projectManagerV1.getBestProject().tokenAddress)
            .balanceOf(address(this));
    }

    // End Airdrop

    function claimAirdrop() public {
        uint256 airdrop = calculateAirdropAmount(msg.sender);

        IERC20(projectManagerV1.getBestProject().tokenAddress).transfer(
            msg.sender,
            airdrop
        );

        projectManagerV1.setVoter(msg.sender, false);
        userHasClaimedProject[msg.sender][projectManagerV1.roundNumber()][
            projectManagerV1.getBestProject().id
        ] = true;
    }

    function calculateTVL(uint256 _roundNumber) public view returns (uint256) {
        uint256 currentBalance = 0;
        address[] memory stakeholders = stakeManagerV1.getShareHolders();
        for (uint256 i = 0; i < stakeholders.length; i++) {
            currentBalance = currentBalance.add(
                stakeManagerV1.getStakedBalance(stakeholders[i], _roundNumber)
            );
        }
        return currentBalance;
    }

    function calculateAirdropAmount(
        address _shareholder
    ) public view returns (uint256) {
        uint256 _previousRoundNumber = projectManagerV1.roundNumber() - 1;
        uint256 _currentRoundNumber = projectManagerV1.roundNumber();
        uint256 tvl = calculateTVL(_previousRoundNumber);

        require(
            projectManagerV1.isShareholderVoter(_shareholder),
            "not a voter"
        );
        require(
            _shareholder != address(0x0),
            "shareholder cannot be address of 0"
        );

        require(tvl > 0, "tvl less than 0");
        require(
            userHasClaimedProject[_shareholder][_currentRoundNumber][
                projectManagerV1.getBestProject().id
            ] != true,
            "shareholder has already claimed this airdrop"
        );

        return
            calculateAirdrop(
                _shareholder,
                tvl,
                airdropBalance,
                projectManagerV1.getBestProject().tokenAddress,
                _previousRoundNumber
            );
    }

    function calculateHolderPercentage(
        address _shareholder,
        uint256 _tvl,
        uint256 _roundNumber
    ) private view returns (uint256) {
        // 100 : x = tvl : holderBalance
        uint256 holderBalance = stakeManagerV1.getStakedBalance(
            _shareholder,
            _roundNumber
        );
        return mulDiv(holderBalance, 1000000, _tvl);
    }

    function calculateExpectedAirdrop(
        address _shareholder
    ) external view returns (uint256) {
        require(
            _shareholder != address(0x0),
            "shareholder address cannot be 0"
        );

        uint256 currentRoundNumber = projectManagerV1.roundNumber();
        uint256 holderBalance = stakeManagerV1.getStakedBalance(
            _shareholder,
            currentRoundNumber
        );
        require(
            holderBalance > 0,
            "shareholder balance must be greater than 0"
        );

        uint256 treasuryForAirdrop = mulDiv(
            IERC20(STABLE_COIN).balanceOf(address(this)),
            75,
            100
        );

        return
            calculateAirdrop(
                _shareholder,
                calculateTVL(currentRoundNumber),
                treasuryForAirdrop,
                STABLE_COIN,
                currentRoundNumber
            );
    }

    function calculateAirdrop(
        address _shareholder,
        uint256 _tvl,
        uint256 _airdropBalance,
        address _tokenToAirdrop,
        uint256 _roundNumber
    ) private view returns (uint256) {
        require(
            _shareholder != address(0x0),
            "shareholder address cannot be 0"
        );
        require(_tvl > 0, "tvl must be greater than 0");
        require(_airdropBalance > 0, "airdrop balance must be greater than 0");
        require(_tokenToAirdrop != address(0x0), "token address cannot be 0");
        require(_roundNumber > 0, "round number must be greater than 0");

        uint256 holderPercentage = calculateHolderPercentage(
            _shareholder,
            _tvl,
            _roundNumber
        );

        uint256 airdropBasedOnHoldingAmount = mulDiv(
            _airdropBalance,
            holderPercentage,
            1000000
        );

        uint256 stakingPercentageTime = stakeManagerV1
            .calculateStakingPercentageTime(_shareholder, _roundNumber);

        return
            mulDiv(airdropBasedOnHoldingAmount, stakingPercentageTime, 1000000);
    }

    function swapETHForTokens(uint256 _amount, address _token) private {
        require(_amount > 0, "amount less than 0");
        require(_token != address(0x0), "address is not valid");
        require(address(this).balance >= _amount, "balance less than _amount");

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _amount
        }(0, path, address(this), block.timestamp);
    }

    function swapTokensForETH(uint256 _amount, address _token) private {
        require(_amount > 0);
        require(_token != address(0x0));
        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "balance less than _amount"
        );

        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function getAmountOutMin(
        uint256 _amount,
        address _tokenIn,
        address _tokenOut
    ) private view returns (uint256, address[] memory) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256[] memory amountOutMins = dexRouter.getAmountsOut(_amount, path);
        return (amountOutMins[1], path);
    }

    function swapTokens() external onlyAdmin {
        IERC20(WETH).approve(ROUTER, address(this).balance);
        swapETHForTokens(address(this).balance, STABLE_COIN);
    }

    function withdraw(address _token) external onlyAdmin {
        require(_token != address(0x0));
        uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
        require(remainingBalance > 0);
        IERC20(_token).transfer(admin, remainingBalance);
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.fromUInt(x),
                        ABDKMathQuad.fromUInt(y)
                    ),
                    ABDKMathQuad.fromUInt(z)
                )
            );
    }

    receive() external payable {}
}