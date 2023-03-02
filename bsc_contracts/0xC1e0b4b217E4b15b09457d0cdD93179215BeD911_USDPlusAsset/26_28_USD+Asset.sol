// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.5;

import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '../libraries/DSMath.sol';
import './Asset.sol';

/**
 * @title USD+ Asset
 * @notice Contract presenting an asset in a pool
 * @dev The `USDPlusAdmin` can extract rebasing reward from the contract by calling `skim`
 * Note that there no tip bucket should be stored in this contract, otherwise it will be `skimm`ed. i.e. `lpDividendRatio + retentionRatio = 1 ether`
 */
contract USDPlusAsset is Asset, ReentrancyGuard, AccessControlEnumerable {
    using SafeERC20 for IERC20;

    bytes32 public constant ROLE_USDPlusAdmin = keccak256('USD+Admin');

    /// @notice An event thats emitted when Skim
    event Skim(uint256 amount, address to);

    error NotEnoughCash(uint256 tokenBalance, uint256 cash);

    constructor(
        address underlyingToken_,
        string memory name_,
        string memory symbol_
    ) Asset(underlyingToken_, name_, symbol_) {}

    function addUSDPlusAdmin(address _admin) external onlyOwner {
        _grantRole(ROLE_USDPlusAdmin, _admin);
    }

    function removeUSDPlusAdmin(address _admin) external onlyOwner {
        _revokeRole(ROLE_USDPlusAdmin, _admin);
    }

    function skim(address _to) external nonReentrant returns (uint256 amount) {
        require(hasRole(ROLE_USDPlusAdmin, msg.sender), 'not authorized');

        IPool(pool).mintFee(underlyingToken); // mint fee to LP before skim such that haircut is not skimmed
        amount = _quoteSkimAmount();
        IERC20(underlyingToken).safeTransfer(_to, amount); // `safeTransfer` is not needed for USD+

        emit Skim(amount, _to);
    }

    function _quoteSkimAmount() internal view returns (uint256 amount) {
        uint256 tokenBalance = IERC20(underlyingToken).balanceOf(address(this));
        uint256 cash_ = DSMath.fromWad(cash, underlyingTokenDecimals);

        if (tokenBalance < cash_) revert NotEnoughCash(tokenBalance, cash_);
        amount = tokenBalance - cash_;
    }
}

interface IPool {
    function mintFee(address token) external;
}