// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IController.sol";
import "../interfaces/IVault.sol";
import "../utils/TransferHelper.sol";
import "../interfaces/IWhitelist.sol";

//TOBE removed
import "truffle/console.sol";

contract INFVault is IVault, ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;
    using Math for uint256;

    ERC20 public asset;

    string public constant version = "3.0";

    address public controller;

    uint256 public maxDeposit;

    uint256 public maxWithdraw;

    address public whitelist;

    bool public paused;

    uint256[] public priceHistory;

    event Deposit(
        address indexed asset,
        address indexed caller,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

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

    event SetWhitelist(address _whitelist);

    receive() external payable {}

    modifier unPaused() {
        require(!paused, "PAUSED");
        _;
    }

    modifier onlyStrategy() {
        require(
            IController(controller).isSubStrategy(_msgSender()),
            "NOT_SUBSTRATEGY"
        );
        _;
    }

    modifier onlyAllowed() {
        require(IWhitelist(whitelist).isWhitelisted(msg.sender), "NON_LISTED");
        _;
    }

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        asset = _asset;
        maxDeposit = type(uint256).max;
        maxWithdraw = type(uint256).max;
    }

    function deposit(
        uint256 assets,
        address receiver
    )
        public
        payable
        virtual
        override
        nonReentrant
        unPaused
        onlyAllowed
        returns (uint256 shares)
    {
        require(assets != 0, "ZERO_ASSETS");
        require(assets <= maxDeposit, "EXCEED_ONE_TIME_MAX_DEPOSIT");

        require(msg.value >= assets, "INSUFFICIENT_TRANSFER");

        // Need to transfer before minting or ERC777s could reenter.
        TransferHelper.safeTransferETH(address(controller), assets);

        // Total Assets amount until now
        uint256 totalDeposit = IController(controller).totalAssets();

        // Calls Deposit function on controller
        uint256 newDeposit = IController(controller).deposit(assets);

        require(newDeposit > 0, "INVALID_DEPOSIT_SHARES");

        // Calculate share amount to be mint
        shares = totalSupply() == 0 || totalDeposit == 0
            ? assets.mulDiv(
                10 ** decimals(),
                10 ** asset.decimals(),
                Math.Rounding.Down
            )
            : newDeposit.mulDiv(
                totalSupply(),
                totalDeposit,
                Math.Rounding.Down
            );

        // Mint INDEX token to receiver
        _mint(receiver, shares);

        emit Deposit(address(asset), msg.sender, receiver, assets, shares);
    }

    function mint(
        uint256 amount,
        address account
    ) external override onlyStrategy {
        _mint(account, amount);
    }

    function withdraw(
        uint256 assets,
        address receiver
    )
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
        shares =
            (totalSupply() * assets) /
            IController(controller).totalAssets();

        require(shares > 0, "INVALID_WITHDRAW_SHARES");
        console.log(
            "shares %s totalSupply() * assets to %s,totalAssets %s",
            shares,
            (totalSupply() * assets),
            IController(controller).totalAssets()
        );
        require(balanceOf(msg.sender) >= shares, "EXCEED_TOTAL_DEPOSIT");

        _withdraw(assets, shares, receiver);
    }

    function redeem(
        uint256 shares,
        address receiver
    )
        public
        virtual
        nonReentrant
        unPaused
        onlyAllowed
        returns (uint256 assets)
    {
        require(shares != 0, "ZERO_SHARES");
        require(shares <= balanceOf(msg.sender), "EXCEED_TOTAL_BALANCE");

        assets =
            (shares * IController(controller).totalAssets()) /
            totalSupply();

        require(assets <= maxWithdraw, "EXCEED_ONE_TIME_MAX_WITHDRAW");

        // Withdraw asset
        _withdraw(assets, shares, receiver);
    }

    function totalAssets() public view virtual returns (uint256) {
        return IController(controller).totalAssets();
    }

    function assetsPerShare() public view returns (uint256) {
        return IController(controller).totalAssets() / totalSupply();
    }

    function convertToShares(
        uint256 assets
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function convertToAssets(
        uint256 shares
    ) public view virtual returns (uint256) {
        uint256 supply = totalSupply();

        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    ///////////////////////////////////////////////////////////////
    //                 SET CONFIGURE LOGIC                       //
    ///////////////////////////////////////////////////////////////

    function setPriceHistory() public onlyOwner {
        uint256 supply = totalSupply();
        if (supply != 0) {
            priceHistory.push((totalAssets() * 10000) / supply);
        }
    }

    function getPriceHistory() public view returns (uint256[] memory) {
        return priceHistory;
    }

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

    function setWhitelist(address _whitelist) public onlyOwner {
        require(_whitelist != address(0), "INVALID_ZERO_ADDRESS");
        whitelist = _whitelist;

        emit SetWhitelist(whitelist);
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

    ////////////////////////////////////////////////////////////////////
    //                      INTERNAL                                  //
    ////////////////////////////////////////////////////////////////////

    function _withdraw(
        uint256 assets,
        uint256 shares,
        address receiver
    ) internal {
        require(shares != 0, "SHARES_TOO_LOW");
        // Calls Withdraw function on controller
        (uint256 withdrawn, uint256 fee) = IController(controller).withdraw(
            assets,
            receiver
        );
        require(withdrawn > 0, "INVALID_WITHDRAWN_SHARES");

        // Burn shares amount
        _burn(msg.sender, shares);

        emit Withdraw(
            address(asset),
            msg.sender,
            receiver,
            assets,
            shares,
            fee
        );
    }
}