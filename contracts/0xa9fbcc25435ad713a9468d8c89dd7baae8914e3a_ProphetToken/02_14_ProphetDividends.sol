// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/DividendPayingToken.sol";

contract ProphetDividends is DividendPayingToken, Ownable {
    error UnauthorizedAccount(address account);
    error InvalidDeployerAccount(address account);

    using SafeMath for uint256;
    using SafeMathInt for int256;

    IERC20 token;

    mapping(address => bool) public excludedFromDividends;

    bool noWarning;
    address private _deployer;
    uint256 public closeTime;

    uint256 public constant claimGracePeriod = 30 days;

    event ExcludeFromDividends(address indexed account);

    event Claim(
        address indexed account,
        uint256 amount,
        bool indexed automatic
    );

    constructor()
        DividendPayingToken("PROPHET_Dividends", "PROPHET_Dividends")
    {
        _deployer = tx.origin;
        token = IERC20(msg.sender);
    }

    modifier onlyDeployer() {
        _checkDeployer();
        _;
    }

    function deployer() public view virtual returns (address) {
        return _deployer;
    }

    function _checkDeployer() internal view virtual {
        if (deployer() != _msgSender()) {
            revert UnauthorizedAccount(_msgSender());
        }
    }

    function renounceAsDeployer() public virtual onlyDeployer {
        _transferDeployer(address(0));
    }

    function transferDeployer(address newDeployer) public virtual onlyDeployer {
        if (newDeployer == address(0)) {
            revert InvalidDeployerAccount(address(0));
        }
        _transferDeployer(newDeployer);
    }

    function _transferDeployer(address newDeployer) internal virtual {
        _deployer = newDeployer;
    }

    function _transfer(
        address,
        address,
        uint256
    ) internal override {
        require(false, "No transfers allowed");
        noWarning = noWarning;
    }

    function withdrawDividend() public override {
        require(
            false,
            "withdrawDividend disabled. Use the 'claim' function on the main token contract."
        );
        noWarning = noWarning;
    }

    function claim(address account) external onlyOwner {
        require(
            closeTime == 0 || block.timestamp < closeTime + claimGracePeriod,
            "closed"
        );
        _withdrawDividendOfUser(payable(account));
    }

    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;

        _setBalance(account, 0);

        emit ExcludeFromDividends(account);
    }

    function getAccount(address _account)
        public
        view
        returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends
        )
    {
        account = _account;
        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);
    }

    function updateBalance(address payable account) external {
        if (excludedFromDividends[account]) {
            return;
        }

        _setBalance(account, token.balanceOf(account));
    }

    //If the dividend contract needs to be updated, we can close
    //this one, and let people claim for a month
    //After that is over, we can take the remaining funds and
    //use for the project
    function close() external onlyDeployer {
        require(closeTime == 0, "cannot take yet");
        closeTime = block.timestamp;
    }

    //Only allows funds to be taken if contract has been closed for a month
    function takeFunds() external onlyDeployer {
        require(
            closeTime >= 0 && block.timestamp >= closeTime + claimGracePeriod,
            "already closed"
        );
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }
}