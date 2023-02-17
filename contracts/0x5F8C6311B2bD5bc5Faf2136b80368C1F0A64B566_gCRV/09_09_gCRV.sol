// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUCrvWithdrawAs {
    enum Option {
        Claim,
        ClaimAsETH,
        ClaimAsCRV,
        ClaimAsCVX,
        ClaimAndStake
    }

    function withdrawAs(address _to, uint256 _shares, Option option) external;

    function withdrawAs(address _to, uint256 _shares, Option option, uint256 minAmountOut) external;

    function withdraw(address _to, uint256 _shares) external;
}

contract gCRV is Initializable, ERC20Upgradeable, OwnableUpgradeable {
    // address public constant uCrvAddress = 0x83507cc8C8B67Ed48BADD1F59F684D5d02884C81;
    IERC20 public uCrv;
    uint256 public lastInflatedTimestamp;
    address public inflationRecipient;
    // inflation rate per second
    uint256 public inflationRate;
    uint256 public inflatedAmount;

    bool public migrated;

    IStkCvxCrvZaps public immutable stkCvxCrvZaps;

    constructor(IStkCvxCrvZaps _stkCvxCrvZaps) {
        stkCvxCrvZaps = _stkCvxCrvZaps;
    }

    function initialize(IERC20 _uCrv, address _inflationRecipient) public initializer {
        __ERC20_init("gCRV", "gCRV");
        __Ownable_init();
        uCrv = _uCrv;
        inflationRecipient = _inflationRecipient;
        inflationRate = 1585489599;
        lastInflatedTimestamp = block.timestamp;
    }

    modifier accrue() {
        uint256 diff = block.timestamp - lastInflatedTimestamp;
        lastInflatedTimestamp = block.timestamp;
        uint256 supply = totalSupply();
        if(diff != 0 && supply != 0) {
            inflatedAmount += supply * diff * inflationRate / 1e18;
        }
        _;
    }

    function totalSupply() public view override returns(uint256) {
        return super.totalSupply() + inflatedAmount;
    }

    function inflate() external accrue {
        _mint(inflationRecipient, inflatedAmount);
        inflatedAmount = 0;
    }

    // Wraps an `amountIn` of uCRV to a bigger amount of gCRV
    //
    // Inflation is implemented on contract level, so that when
    // a user wraps uCRV, they get more gCRV, since it is cheaper
    // due to accrued inflation.
    //
    // An alternative approach on user level would mean that a user
    // gets gCRV in the amount equal to the amount of uCRV wrapped,
    // but on exit gets less. That however would require fixing the
    // time a user wraps their tokens.
    function wrap(uint256 amountIn) external accrue {
        address account = msg.sender;
        uint256 amountOut = toGCRV(amountIn);

        // Increase the account's balance by amountOut
        _mint(account, amountOut);

        // Transfer uCRV from the sender to this contract's address.
        // The transfer must be approved by the sender in advance
        uCrv.transferFrom(account, address(this), amountIn);
    }

    // Unwraps an `amountIn` of gCRV to a smaller amount of uCRV
    // based on the `inflationRate` and the time passed since the
    // contract inception
    function unwrap(uint256 amountIn, bool cvx) external accrue {
        address account = msg.sender;
        uint256 amountOut = toUCRV(amountIn);

        // Reduce the account's balance by amountOut
        _burn(account, amountIn);
        if(cvx) {
            IUCrvWithdrawAs(address(uCrv)).withdraw(account, amountOut);
        } else {
            // Return the user the uCRV amount due
            uCrv.transfer(account, amountOut);
        }
    }

    // Inflation value is set per second. It should be expressed as a decimal
    // (not percentage) multiplied by 10**18, so 1% would equal
    // 0.01 * 10**18 = 1E16 or 10 000 000 000 000 000
    function setInflation(uint256 _inflationRate) external onlyOwner {
        require(_inflationRate > 0, "gCRV: inflation rate cannot be zero");
        inflationRate = _inflationRate;
    }

    function changeInfationRecipient(address _recipient) external onlyOwner {
        inflationRecipient = _recipient;
    }

    // Gets gCRV amount and returns equivalent uCRV amount
    function toUCRV(uint256 gCrvAmount) public view returns (uint256 uCrvAmount) {
        // Get the wrap ratio based on the balances pre unwrap
        uint256 gCrvTotal = totalSupply();
        uint256 uCrvBalance =  ucrvBalanceInternal();
        // Sanity check: make sure we do not delete by zero
        if (gCrvTotal == 0) {
            uCrvAmount = gCrvAmount;
        } else {
            // Note here we expect uCrvBalance / gCrvTotal <= 1,
            // Therefore, we expect uCrvAmount <= gCrvAmount
            uCrvAmount = gCrvAmount * uCrvBalance / gCrvTotal;
        }
    }

    // Gets uCRV amount and returns equivalent gCRV amount
    function toGCRV(uint256 uCrvAmount) public view returns (uint256 gCrvAmount) {
        uint256 gCrvTotal = totalSupply();
        uint256 uCrvBalance = ucrvBalanceInternal();
        // Make sure we do not delete by zero
        if (uCrvBalance == 0 || gCrvTotal == 0) {
            gCrvAmount = uCrvAmount;
        } else {
            // Note here we expect gCrvTotal / uCrvBalance >= 1,
            // Therefore, we expect amountOut >= amountIn
            gCrvAmount = uCrvAmount * gCrvTotal / uCrvBalance;
        }
    }

    function ucrvBalanceInternal() internal view returns(uint256) {
        return uCrv.balanceOf(address(this));
    }

    function migrate() external {
        require(!migrated, "gCRV: already migrated");
        uint256 amount = uCrv.balanceOf(address(this));
        uCrv.approve(address(stkCvxCrvZaps), amount);
        stkCvxCrvZaps.depositFromUCrv(amount, 0, address(this));
        uCrv = stkCvxCrvZaps.vault();
        migrated = true;
    }
}


interface IStkCvxCrvZaps {
    function depositFromUCrv(
        uint256 _amount,
        uint256 _minAmountOut,
        address _to
    ) external;

    function vault() external view returns (IERC20);
}