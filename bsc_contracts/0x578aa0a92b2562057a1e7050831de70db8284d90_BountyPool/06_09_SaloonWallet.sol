//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SaloonWallet {
    using SafeERC20 for IERC20;

    uint256 public constant BOUNTY_COMMISSION = 10;
    uint256 public constant DENOMINATOR = 100;

    address public immutable manager;

    // premium fees to collect
    uint256 public premiumFees;
    uint256 public saloonTotalBalance;
    uint256 public cummulativeCommission;
    uint256 public cummulativeHackerPayouts;

    // hunter balance per token
    // hunter address => token address => amount
    mapping(address => mapping(address => uint256)) public hunterTokenBalance;

    // saloon balance per token
    // token address => amount
    mapping(address => uint256) public saloonTokenBalance;

    constructor(address _manager) {
        manager = _manager;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "Only manager allowed");
        _;
    }

    // bountyPaid
    function bountyPaid(
        address _token,
        uint256 _decimals,
        address _hunter,
        uint256 _amount
    ) external onlyManager {
        // handle decimals
        uint256 decimals = 18 - _decimals == 0 ? 18 : 18 - _decimals;
        // calculate commision
        uint256 saloonCommission = (_amount *
            10**decimals *
            (BOUNTY_COMMISSION)) / (DENOMINATOR);

        uint256 amount = _amount * (10**decimals);

        uint256 hunterPayout = (amount) - saloonCommission;
        // update variables and mappings
        hunterTokenBalance[_hunter][_token] += hunterPayout;
        cummulativeHackerPayouts += hunterPayout;
        saloonTokenBalance[_token] += saloonCommission;
        saloonTotalBalance += saloonCommission;
        cummulativeCommission += saloonCommission;
    }

    function premiumFeesCollected(address _token, uint256 _amount)
        external
        onlyManager
    {
        saloonTokenBalance[_token] += _amount;
        premiumFees += _amount;
        saloonTotalBalance += _amount;
    }

    //
    // WITHDRAW FUNDS TO ANY ADDRESS saloon admin
    function withdrawSaloonFunds(
        address _token,
        address _to,
        uint256 _amount,
        uint256 _decimals
    ) external onlyManager returns (bool) {
        require(_amount <= saloonTokenBalance[_token], "not enough balance");

        //  handle decimals to change state variables
        uint256 decimals = 18 - _decimals == 0 ? 18 : 18 - _decimals;
        uint256 amount = _amount * (10**decimals);
        // decrease saloon funds variable
        saloonTokenBalance[_token] -= amount;
        saloonTotalBalance -= amount;

        IERC20(_token).safeTransfer(_to, amount);

        return true;
    }

    ///////////////////////   VIEW FUNCTIONS  ////////////////////////

    // VIEW saloon CURRENT TOTAL BALANCE
    function viewSaloonBalance() external view returns (uint256) {
        return saloonTotalBalance;
    }

    // VIEW COMMISSIONS PLUS PREMIUM
    function viewTotalEarnedSaloon() external view returns (uint256) {
        uint256 premiums = viewTotalPremiums();
        uint256 commissions = viewTotalSaloonCommission();

        return premiums + commissions;
    }

    // VIEW TOTAL PAYOUTS MADE - commission - fees
    function viewTotalHackerPayouts() external view returns (uint256) {
        return cummulativeHackerPayouts;
    }

    // view hacker payouts by hunter
    function viewHunterTotalTokenPayouts(address _token, address _hunter)
        external
        view
        returns (uint256)
    {
        return hunterTokenBalance[_hunter][_token];
    }

    // VIEW TOTAL COMMISSION
    function viewTotalSaloonCommission() public view returns (uint256) {
        return cummulativeCommission;
    }

    // VIEW TOTAL IN PREMIUMS
    function viewTotalPremiums() public view returns (uint256) {
        return premiumFees;
    }

    ///////////////////////    VIEW FUNCTIONS END  ////////////////////////
}