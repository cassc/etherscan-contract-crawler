// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../interfaces/IController.sol";
import "../interfaces/IWhitelist.sol";
import "../utils/TransferHelper.sol";

contract EFVault is Initializable, ERC20Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;
    using SafeMath for uint256;

    ERC20Upgradeable public asset;

    string public constant version = "4.0";

    address public depositApprover;

    address public controller;

    uint256 private assetDecimal;

    uint256 public maxWithdraw;

    uint256 public maxDeposit;

    address public whiteList;

    bool public paused;

    event Deposit(address indexed asset, address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed asset,
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares,
        uint256 fee
    );

    event SetMaxDeposit(uint256 maxDeposit);

    event SetMaxWithdraw(uint256 maxWithdraw);

    event SetController(address controller);

    event SetDepositApprover(address depositApprover);

    event SetWhitelist(address whiteList);

    modifier unPaused() {
        require(!paused, "PAUSED");
        _;
    }

    modifier onlyAllowed() {
        require(tx.origin == msg.sender || IWhitelist(whiteList).listed(msg.sender), "NON_LISTED_CA");
        _;
    }

    function initialize(
        ERC20Upgradeable _asset,
        string memory _name,
        string memory _symbol,
        uint256 _assetDecimal,
        address _whiteList
    ) public initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();
        __ReentrancyGuard_init();
        asset = _asset;
        assetDecimal = _assetDecimal;
        maxDeposit = type(uint256).max;
        maxWithdraw = type(uint256).max;

        whiteList = _whiteList;
    }

    function deposit(uint256 assets, address receiver)
        public
        virtual
        nonReentrant
        unPaused
        onlyAllowed
        returns (uint256 shares)
    {
        require(assets != 0, "ZERO_ASSETS");
        require(assets <= maxDeposit, "EXCEED_ONE_TIME_MAX_DEPOSIT");

        require(getBalance(address(this)) >= assets, "INSUFFICIENT_TRANSFER");

        // Need to transfer before minting or ERC777s could reenter.
        TransferHelper.safeTransfer(address(asset), address(controller), assets);

        // Total Assets amount until now
        uint256 totalDeposit = IController(controller).totalAssets(false);
        // Calls Deposit function on controller
        uint256 newDeposit = IController(controller).deposit(assets);

        require(newDeposit > 0, "INVALID_DEPOSIT_SHARES");

        // Calculate share amount to be mint
        shares = totalSupply() == 0 || totalDeposit == 0 ? assets : (totalSupply() * newDeposit) / totalDeposit;

        // Mint ENF token to receiver
        _mint(receiver, shares);

        emit Deposit(address(asset), msg.sender, receiver, assets, shares);
    }

    function getBalance(address account) internal view returns (uint256) {
        // Asset is zero address when it is ether
        if (address(asset) == address(0)) return address(account).balance;
        else return IERC20Upgradeable(asset).balanceOf(account);
    }

    function withdraw(uint256 assets, address receiver)
        public
        virtual
        nonReentrant
        unPaused
        onlyAllowed
        returns (uint256 shares)
    {
        require(assets != 0, "ZERO_ASSETS");
        require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");

        // Calculate share amount to be burnt
        shares = (totalSupply() * assets) / IController(controller).totalAssets(false);

        require(balanceOf(msg.sender) >= shares, "EXCEED_TOTAL_DEPOSIT");

        // Withdraw asset
        _withdraw(assets, shares, receiver);
    }

    function redeem(uint256 shares, address receiver)
        public
        virtual
        nonReentrant
        unPaused
        onlyAllowed
        returns (uint256 assets)
    {
        require(shares > 0, "ZERO_SHARES");
        require(shares <= balanceOf(msg.sender), "EXCEED_TOTAL_BALANCE");

        assets = (shares * assetsPerShare()) / 1e24;

        require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");

        // Withdraw asset
        _withdraw(assets, shares, receiver);
    }

    function _withdraw(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal {
        // Calls Withdraw function on controller
        (uint256 withdrawn, uint256 fee) = IController(controller).withdraw(assets, receiver);
        require(withdrawn > 0, "INVALID_WITHDRAWN_SHARES");

        // Burn shares amount
        _burn(msg.sender, shares);

        emit Withdraw(address(asset), msg.sender, receiver, assets, shares, fee);
    }

    function assetsPerShare() internal view returns (uint256) {
        return (IController(controller).totalAssets(false) * assetDecimal * 1e18) / totalSupply();
    }

    function totalAssets() public view virtual returns (uint256) {
        return IController(controller).totalAssets(true);
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    ///////////////////////////////////////////////////////////////
    //                 SET CONFIGURE LOGIC                       //
    ///////////////////////////////////////////////////////////////

    function setMaxDeposit(uint256 _maxDeposit) public onlyOwner {
        require(_maxDeposit > 0, "INVALID_MAX_DEPOSIT");
        maxDeposit = _maxDeposit;

        emit SetMaxDeposit(maxDeposit);
    }

    function setMaxWithdraw(uint256 _maxWithdraw) public onlyOwner {
        require(_maxWithdraw > 0, "INVALID_MAX_WITHDRAW");
        maxWithdraw = _maxWithdraw;

        emit SetMaxWithdraw(maxWithdraw);
    }

    function setController(address _controller) public onlyOwner {
        require(_controller != address(0), "INVALID_ZERO_ADDRESS");
        controller = _controller;

        emit SetController(controller);
    }

    function setDepositApprover(address _approver) public onlyOwner {
        require(_approver != address(0), "INVALID_ZERO_ADDRESS");
        depositApprover = _approver;

        emit SetDepositApprover(depositApprover);
    }

    function setWhitelist(address _whitelist) public onlyOwner {
        require(_whitelist != address(0), "INVALID_ZERO_ADDRESS");
        whiteList = _whitelist;

        emit SetWhitelist(whiteList);
    }

    ////////////////////////////////////////////////////////////////////
    //                      PAUSE/RESUME                              //
    ////////////////////////////////////////////////////////////////////

    function pause() public onlyOwner {
        require(!paused, "CURRENTLY_PAUSED");
        paused = true;
    }

    function resume() public onlyOwner {
        require(paused, "CURRENTLY_RUNNING");
        paused = false;
    }
}