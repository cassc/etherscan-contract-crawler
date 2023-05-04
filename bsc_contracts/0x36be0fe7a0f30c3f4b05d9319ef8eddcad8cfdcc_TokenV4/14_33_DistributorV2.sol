// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/DexRouter.sol";

import "./libraries/ABDKMathQuad.sol";

import "./ProjectManager.sol";

contract DistributorV2 is Initializable {
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

    ProjectManager private projectManager;
    address private projectManagerAddress;

    mapping(address => uint256) public holderSellingDays;
    uint256 private holdingDays;

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

    function configureProjectManager(address _address) external onlyAdmin {
        require(_address != address(0x0));
        projectManagerAddress = _address;
        projectManager = ProjectManager(_address);
    }

    function setAirdropDate(uint256 _days) public onlyAdmin {
        require(_days > 0);
        airdropDate = block.timestamp + (1 days * _days);
    }

    // Initialize airdrop
    // 1) approveAirdrop
    // 2) buyBack
    // 3) buyAirdropTokens
    // 4) initializeNextRound
    function approveAirdrop() external onlyAdmin {
        airdropSnapshot[projectManager.roundNumber()] = calculateTVL();

        stableCoinBalance = IERC20(STABLE_COIN).balanceOf(address(this));
        require(stableCoinBalance > 0);

        IERC20(STABLE_COIN).approve(ROUTER, stableCoinBalance);
        (uint256 amountWethMin, ) = getAmountOutMin(
            stableCoinBalance,
            STABLE_COIN,
            WETH
        );
        IERC20(WETH).approve(ROUTER, amountWethMin);
    }

    function buyBack() external onlyAdmin {
        swapTokensForETH(
            mulDiv(stableCoinBalance, BUY_BACK_FEE, 100),
            STABLE_COIN
        );
        swapETHForTokens(address(this).balance, artikToken);
        IERC20(artikToken).transfer(
            address(0x0),
            IERC20(artikToken).balanceOf(address(this))
        );
    }

    function buyAirdropTokens(uint256 _amount) external onlyAdmin {
        require(_amount > 0);
        swapTokensForETH(_amount, STABLE_COIN);
        swapETHForTokens(
            address(this).balance,
            projectManager.getBestProject().tokenAddress
        );
    }

    function initializeNextRound(uint256 _days) external onlyAdmin {
        require(_days > 0);

        projectManager.nextRound();
        airdropSnapshot[projectManager.roundNumber()] = 0;
        setAirdropDate(_days);
        airdropBalance = IERC20(projectManager.getBestProject().tokenAddress)
            .balanceOf(address(this));
    }

    // End Airdrop

    function claimAirdrop() public {
        uint256 airdrop = calculateAirdropAmount(msg.sender);
        IERC20(projectManager.getBestProject().tokenAddress).transfer(
            msg.sender,
            airdrop
        );

        projectManager.setVoter(msg.sender, false);
        userHasClaimedProject[msg.sender][projectManager.roundNumber()][
            projectManager.getBestProject().id
        ] = true;

        (uint256 amountWethMin, ) = getAmountOutMin(
            airdrop,
            projectManager.getBestProject().tokenAddress,
            WETH
        );
        (uint256 amountStableMin, ) = getAmountOutMin(
            amountWethMin,
            WETH,
            STABLE_COIN
        );

        amountClaimed[msg.sender] = amountClaimed[msg.sender].add(
            amountStableMin
        );
        totalAmountAirdropped = totalAmountAirdropped.add(amountStableMin);
    }

    function calculateTVL() public view returns (uint256) {
        uint256 currentBalance = 0;
        for (uint256 i = 0; i < shareholders.length; i++) {
            if (projectManager.isShareholderVoter(shareholders[i])) {
                currentBalance = currentBalance.add(
                    IERC20(artikToken).balanceOf(shareholders[i])
                );
            }
        }
        return currentBalance;
    }

    function calculateAirdropAmount(
        address _shareholder
    ) public view returns (uint256) {
        require(shareholderIndexes[_shareholder] > 0, "not a shareholder");
        require(projectManager.isShareholderVoter(_shareholder), "not a voter");
        require(
            _shareholder != address(0x0),
            "shareholder cannot be address of 0"
        );
        require(
            airdropSnapshot[projectManager.roundNumber() - 1] > 0,
            "total holders balance less than 0"
        );

        require(
            userHasClaimedProject[_shareholder][projectManager.roundNumber()][
                projectManager.getBestProject().id
            ] != true,
            "shareholder has already claimed this airdrop"
        );

        uint256 holderPercentage = calculateHolderPercentage(
            _shareholder,
            airdropSnapshot[projectManager.roundNumber() - 1]
        );

        uint256 airdropBasedOnHoldingAmount = mulDiv(
            airdropBalance.div(2),
            holderPercentage,
            1000000
        );

        uint256 holderPercentageBasedOnDays = calculateHolderPercentageBasedOnDays(
                _shareholder
            );

        uint256 airdropBasedOnHoldingDays = mulDiv(
            airdropBalance.div(2),
            holderPercentageBasedOnDays,
            1000000
        );

        return
            airdropBasedOnHoldingAmount.add(airdropBasedOnHoldingDays).div(
                1000000
            );
    }

    function calculateHolderPercentage(
        address _shareholder,
        uint256 _totalHoldersBalance
    ) private view returns (uint256) {
        // 100 : x = totalHoldersBalance : holderBalance
        uint256 holderBalance = IERC20(artikToken).balanceOf(_shareholder);
        uint256 holderPercentage = mulDiv(
            holderBalance,
            1000000,
            _totalHoldersBalance
        );
        return holderPercentage;
    }

    function increaseHoldingDays() external onlyAdmin {
        holdingDays = holdingDays.add(1);
    }

    function removeHoldingDay(address _shareholder) external onlyAdmin {
        require(_shareholder != address(0x0));

        if (holderSellingDays[_shareholder] > 0) {
            holderSellingDays[_shareholder] = holderSellingDays[_shareholder]
                .sub(1);
        }
    }

    function calculateHolderPercentageBasedOnDays(
        address _shareholder
    ) private view returns (uint256) {
        // 100 : x = : total holders days : holder days
        uint256 holderDays = holdingDays.sub(holderSellingDays[_shareholder]);
        uint256 holderPercentage = mulDiv(holderDays, 1000000, holdingDays);
        return holderPercentage;
    }

    function calculateExpectedAirdrop(
        address _shareholder
    ) external view returns (uint256) {
        require(
            _shareholder != address(0x0),
            "shareholder address cannot be 0"
        );
        require(shareholderIndexes[_shareholder] > 0, "not a shareholder");

        uint256 holderBalance = IERC20(artikToken).balanceOf(_shareholder);
        require(
            holderBalance > 0,
            "shareholder balance must be greater than 0"
        );

        uint256 holders_balance = 0;
        if (airdropSnapshot[projectManager.roundNumber()] > 0) {
            holders_balance = airdropSnapshot[projectManager.roundNumber()];
        } else {
            holders_balance = calculateTVL();
        }

        uint256 holderPercentage = calculateHolderPercentage(
            _shareholder,
            holders_balance
        );

        uint256 treasuryForAirdrop = mulDiv(
            IERC20(STABLE_COIN).balanceOf(address(this)),
            75,
            100
        );

        uint256 airdropBasedOnHoldingAmount = mulDiv(
            (treasuryForAirdrop.div(2)),
            holderPercentage,
            1000000
        );

        uint256 holderPercentageBasedOnDays = calculateHolderPercentageBasedOnDays(
                _shareholder
            );

        uint256 airdropBasedOnHoldingDays = mulDiv(
            (treasuryForAirdrop.div(2)),
            holderPercentageBasedOnDays,
            1000000
        );

        return
            airdropBasedOnHoldingAmount.add(airdropBasedOnHoldingDays).div(
                1000000
            );
    }

    function getShareholderIndex(
        address _shareholder
    ) external view returns (uint256) {
        require(_shareholder != address(0x0));
        return shareholderIndexes[_shareholder];
    }

    function addShareHolder(address _shareholder) external onlyAdmin {
        require(_shareholder != address(0x0));

        if (shareholderIndexes[_shareholder] <= 0) {
            shareholders.push(_shareholder);
            shareholderCount = shareholderCount.add(1);
            shareholderIndexes[_shareholder] = shareholderCount;
        }
    }

    function removeShareHolder(address _shareholder) external onlyAdmin {
        require(_shareholder != address(0x0));

        if (shareholderIndexes[_shareholder] > 0) {
            shareholders[shareholderIndexes[_shareholder] - 1] = shareholders[
                shareholders.length - 1
            ];
            shareholders.pop();
            shareholderCount = shareholderCount.sub(1);
            shareholderIndexes[_shareholder] = 0;
        }
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

    function withdrawRemainingAirdrop(address _token) external onlyAdmin {
        require(_token != address(0x0));
        uint256 remainingBalance = IERC20(_token).balanceOf(address(this));
        totalAmountAirdropped = totalAmountAirdropped.add(remainingBalance);
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