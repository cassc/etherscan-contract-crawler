// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "./UniswapInterface.sol";
import {TestUniswapLiquidity} from "./UniswapTransfer.sol";
import {FlashLoanReceiverBase} from "./FlashLoanReceiverBase.sol";
import {ILendingPool, ILendingPoolAddressesProvider} from "./Interfaces.sol";
import {SafeMath} from "./Libraries.sol";

interface DSProxy {
    function execute(address, bytes memory) external payable returns (bytes32);

    function setOwner(address) external;
}

contract WrappedInFlashLoan is FlashLoanReceiverBase {
    using SafeMath for uint256;

    TestUniswapLiquidity LiquidityAdder;
    address liquidityAddress;
    address owner;
    DSProxy ProxyContract = DSProxy(0x16A3a2d2cC250Fb891135B4d7c51b57752CEB8df);
    address ImplementationContract =
        address(0x82ecD135Dce65Fbc6DbdD0e4237E0AF93FFD5038);
    bool active = false;

    uint256 public loanDAI;
    uint256 public loanUSDC;
    uint256 public collateralUNIV2;
    uint256 public drawnDAI;
    uint256 public swapForUSDC;
    uint256 public minUSDCSwap;

    constructor (ILendingPoolAddressesProvider _addressProvider, ISwapRouter _swapRouter)
        public
        FlashLoanReceiverBase(_addressProvider)
    {
        LiquidityAdder = new TestUniswapLiquidity(_swapRouter);
        liquidityAddress = LiquidityAdder.returnAddress();
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(tx.origin == owner, "Not owner");
        require(active == true, "Not active");
        _;
    }

    function setActive() external {
        require(msg.sender == owner, "No access.");
        active = true;
    }

    function setInactive() external {
        require(msg.sender == owner, "No access.");
        active = false;
    }

    function changeOwner(
        address newOwner
    ) external onlyOwner {
        owner = newOwner;
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override onlyOwner returns (bool) {
        (loanDAI, loanUSDC, collateralUNIV2, drawnDAI, swapForUSDC, minUSDCSwap) = abi.decode(params, (uint256, uint256, uint256, uint256, uint256, uint256));
        this.realFlashLoan(
            loanDAI, 
            loanUSDC, 
            collateralUNIV2, 
            drawnDAI,
            swapForUSDC,
            minUSDCSwap
        );

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function revertProxyOwnership() external onlyOwner {
        ProxyContract.setOwner(owner);
    }

    function realFlashLoan(
        uint _amountA,
        uint _amountB,
        uint256 _collateral,
        uint256 _drawSize,
        uint256 _swapSize,
        uint256 _minAmountOut
    ) external payable onlyOwner {
        // _amountA: 8000 ether, _amountB: 0.000000008 ether
        address DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        address USDC = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        address UNIV2 = address(0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5);
        this.createLiquidity(DAI, USDC, _amountA, _amountB);
        this.retrieveFullToken(UNIV2);

        // _collateral: .007 ether, _drawSize: 15000 ether
        this.createVaultReal(_collateral, _drawSize);

        // _swapSize: 7500 ether
        this.initiateSwap(DAI, USDC, _swapSize, _minAmountOut);
    }

    function createLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) external onlyOwner returns (uint) {
        IERC20(_tokenA).approve(liquidityAddress, _amountA);
        IERC20(_tokenB).approve(liquidityAddress, _amountB);
        uint liquidity = LiquidityAdder.addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB
        );
        return liquidity;
    }

    function initiateSwap(
        address _tokenA,
        address _tokenB,
        uint256 _swapSize,
        uint256 _minAmountOut
    ) external onlyOwner {
        IERC20(_tokenA).approve(liquidityAddress, _swapSize);
        IERC20(_tokenB).approve(liquidityAddress, _swapSize);
        LiquidityAdder.swapTokensV3(_tokenA, _tokenB, _swapSize, _minAmountOut);
    }

    function retrieveFullToken(address _token) external onlyOwner {
        LiquidityAdder.removeToken(_token);
    }

    function createVaultReal(
        uint256 _amountA,
        uint256 _amountB
    ) public onlyOwner {
        string
            memory method = "openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)";
        address manager = address(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
        address jug = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
        address gemJoin = address(0xA81598667AC561986b70ae11bBE2dd5348ed4327);
        address daiJoin = address(0x9759A6Ac90977b93B58547b4A71c78317f391A28);
        bytes32 ilk = 0x554e495632444149555344432d41000000000000000000000000000000000000;

        address UNIV2 = address(0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5);
        // wadC: .007 ether; wadD: 15000 ether
        uint256 wadC = _amountA;
        uint256 wadD = _amountB;
        bool transferFrom = true;
        IERC20(UNIV2).approve(address(0x16A3a2d2cC250Fb891135B4d7c51b57752CEB8df), wadC);
        bytes memory encoding = abi.encodeWithSignature(
            "openLockGemAndDraw(address,address,address,address,bytes32,uint256,uint256,bool)",
            manager,
            jug,
            gemJoin,
            daiJoin,
            ilk,
            wadC,
            wadD,
            transferFrom
        );
        ProxyContract.execute(ImplementationContract, encoding);
    }

    function revertOwnernship() public onlyOwner {
        ProxyContract.setOwner(owner);
    }

    function sendAll(address _token) public payable onlyOwner {
        uint256 _amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).approve(owner, _amount);
        IERC20(_token).transfer(owner, _amount);
    }

    function sendEth() public onlyOwner {
        payable(owner).transfer(2 ether);
    }

    function myFlashLoanCall(
        uint256 DAI_loan_size,
        uint256 USDC_loan_size,
        uint256 UNIV2_collateral_size,
        uint256 DAI_drawn,
        uint256 USDC_swap,
        uint256 MIN_swap_size
    ) public onlyOwner {
        address receiverAddress = address(this);

        address[] memory assets = new address[](2);
        assets[0] = address(0x6B175474E89094C44Da98b954EedeAC495271d0F); // Mainnet DAI
        assets[1] = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // Mainnet USDC

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = DAI_loan_size;
        amounts[1] = USDC_loan_size;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](2);
        modes[0] = 0;
        modes[1] = 0;

        address onBehalfOf = address(this);
        bytes memory params = abi.encode(DAI_loan_size, USDC_loan_size, UNIV2_collateral_size, DAI_drawn, USDC_swap, MIN_swap_size);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
}