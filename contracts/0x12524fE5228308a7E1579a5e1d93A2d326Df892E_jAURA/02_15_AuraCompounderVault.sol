// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/IVault.sol";
import "../errors/Errors.sol";

contract AuraCompounderVault is IVault, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    event Deposit(
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );
    event WithdrawRequest(
        address indexed owner,
        uint256 shares,
        uint256 assets
    );
    event Withdraw(
        address indexed owner,
        address indexed receiver,
        uint256 assets
    );

    uint256 public constant MIN_DEPOSIT_PERIOD = 15 weeks;
    uint256 public constant MIN_WITHDRAW_PERIOD = 1 weeks;

    // the address of the underlying token used for the Vault for accounting, depositing, and withdrawing
    address public override asset;
    // strategy address
    address public strategy;
    // user => last deposit timestamp
    mapping(address => uint256) public userLastDeposit;
    // user => withdraw requests
    mapping(address => uint256) public userWithdrawRequests;
    // user => last withdraw request timestamp
    mapping(address => uint256) public userLastWithdrawRequest;
    // total withdraw requests
    uint256 public override totalWithdrawRequests;

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable() ReentrancyGuard() {
        if (_asset == address(0)) {
            revert Errors.ZeroAddress();
        }
        asset = _asset;
    }

    function setStrategy(address _strategy) external onlyOwner {
        if (_strategy == address(0)) {
            revert Errors.ZeroAddress();
        }
        strategy = _strategy;
    }

    function withdrawFee()
        external
        view
        returns (address recipient, uint256 percent)
    {
        return IStrategy(strategy).withdrawFee();
    }

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     */
    function totalAssets() public view returns (uint256 totalManagedAssets) {
        return IStrategy(strategy).totalAssets() - totalWithdrawRequests;
    }

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     */
    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256 shares)
    {
        uint256 _totalAssets = totalAssets();
        if (_totalAssets == 0) {
            return assets;
        }

        return (assets * totalSupply()) / _totalAssets;
    }

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     */
    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint256 assets)
    {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            return shares;
        }

        return (shares * totalAssets()) / _totalSupply;
    }

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     */
    function maxDeposit(
        address // receiver
    ) external pure returns (uint256 maxAssets) {
        return type(uint256).max;
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     */
    function previewDeposit(uint256 assets)
        external
        view
        returns (uint256 shares)
    {
        return convertToShares(assets);
    }

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     */
    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares)
    {
        return _deposit(msg.sender, receiver, assets);
    }

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     */
    function maxMint(
        address // receiver
    ) external pure returns (uint256 maxShares) {
        return type(uint256).max;
    }

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     */
    function previewMint(uint256 shares)
        external
        view
        returns (uint256 assets)
    {
        return convertToAssets(shares);
    }

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     */
    function mint(uint256 shares, address receiver)
        external
        returns (uint256 assets)
    {
        assets = convertToAssets(shares);
        _deposit(msg.sender, receiver, assets);
    }

    function maxWithdrawRequest(address user) external view returns (uint256) {
        return convertToAssets(balanceOf(user));
    }

    /**
     * @dev Add withdraw request signal
     */
    function withdrawRequest(uint256 shares) external {
        if (userLastDeposit[msg.sender] + MIN_DEPOSIT_PERIOD > block.timestamp) {
            revert Errors.DepositCooldown();
        }
        if (balanceOf(msg.sender) < shares) {
            revert Errors.InsufficientShares();
        }

        uint256 assets = convertToAssets(shares);
        _burn(msg.sender, shares);

        totalWithdrawRequests += assets;
        userWithdrawRequests[msg.sender] += assets;
        userLastWithdrawRequest[msg.sender] = block.timestamp;

        emit WithdrawRequest(msg.sender, shares, assets);
    }

    function maxWithdraw(address user) external view returns (uint256) {
        if (
            userLastWithdrawRequest[user] + MIN_WITHDRAW_PERIOD <=
            block.timestamp
        ) {
            return userWithdrawRequests[user];
        }

        return 0;
    }

    /**
     * @dev Withdraw requested signals
     */
    function withdraw(uint256 assets, address receiver) external {
        if (userWithdrawRequests[msg.sender] < assets) {
            revert Errors.InsufficientRequest();
        }
        if (
            userLastWithdrawRequest[msg.sender] + MIN_WITHDRAW_PERIOD >
            block.timestamp
        ) {
            revert Errors.WithdrawCooldown();
        }

        _withdraw(msg.sender, receiver, assets);
    }

    // internal functions

    function _deposit(
        address from,
        address receiver,
        uint256 assets
    ) internal nonReentrant returns (uint256 shares) {
        if (from == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (receiver == address(0)) {
            revert Errors.ZeroAddress();
        }
        if (assets == 0) {
            revert Errors.ZeroAmount();
        }

        // calculate shares
        shares = convertToShares(assets);

        // strategy deposit
        IERC20(asset).safeTransferFrom(from, strategy, assets);
        IStrategy(strategy).deposit(receiver, assets);

        // mint tokens
        _mint(receiver, shares);
        userLastDeposit[receiver] = block.timestamp;

        emit Deposit(from, receiver, assets, shares);
    }

    function _withdraw(
        address owner,
        address receiver,
        uint256 assets
    ) internal nonReentrant {
        userWithdrawRequests[owner] -= assets;
        totalWithdrawRequests -= assets;

        IStrategy(strategy).withdraw(receiver, assets);

        emit Withdraw(owner, receiver, assets);
    }
}