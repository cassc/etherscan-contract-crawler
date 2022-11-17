pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./gov/OLEToken.sol";

contract WordCupCompetition {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    uint256 public totalExchangedCompetitionAmount;
    uint256 public totalExchangedOleAmount;
    uint256 public exchangedAddressAmount;
    address public admin;
    IERC20 public competitionToken;
    IERC20 public oleToken;
    uint32 public exchangeRate;

    mapping(address => uint256) public prizes;
    mapping(address => ExchangeVar) public exchangeVars;

    struct ExchangeVar {
        uint256 oleAmount;
        uint256 competitionAmount;
    }

    event ExchangeRecord(address account, uint256 oleAmount, uint256 competitionAmount);
    event WithdrawRecord(address account, uint256 amount);

    constructor(address _admin, IERC20 _competitionToken, IERC20 _oleToken, uint32 _exchangeRate) {
        admin = _admin;
        competitionToken = _competitionToken;
        oleToken = _oleToken;
        exchangeRate = _exchangeRate;
    }

    function exchange(uint256 amount) external {
        address account = msg.sender;
        oleToken.safeTransferFrom(account, address(this), amount);
        uint256 exchangeAmount = amount.mul(10000).div(exchangeRate);
        require(exchangeAmount <= competitionToken.balanceOf(address(this)), "limit exceed");
        totalExchangedCompetitionAmount = totalExchangedCompetitionAmount.add(exchangeAmount);
        totalExchangedOleAmount = totalExchangedOleAmount.add(amount);
        ExchangeVar memory exchangeVar = exchangeVars[account];
        if (exchangeVar.oleAmount == 0) {
            exchangedAddressAmount = exchangedAddressAmount.add(1);
        }
        exchangeVars[account] = ExchangeVar(exchangeVar.oleAmount.add(amount), exchangeVar.competitionAmount.add(exchangeAmount));
        competitionToken.safeTransfer(account, exchangeAmount);
        emit ExchangeRecord(account, amount, exchangeAmount);
    }

    function setAirdropBatch(address[] memory accounts, uint256[] memory amounts, uint256 totalAmount, uint32 _exchangeRate) external onlyAdmin{
        require(totalAmount <= competitionToken.balanceOf(address(this)), "limit exceed");
        require(accounts.length == amounts.length, "Length must be same");
        exchangeRate = _exchangeRate;
        for (uint i = 0; i < accounts.length; i++) {
            competitionToken.safeTransfer(accounts[i], amounts[i]);
        }
    }

    function setPrizeBatch(address[] memory accounts, uint256[] memory amounts, uint256 totalAmount) external onlyAdmin{
        require(totalAmount <= oleToken.balanceOf(address(this)), "limit exceed");
        require(accounts.length == amounts.length, "Length must be same");
        for (uint i = 0; i < accounts.length; i++) {
            prizes[accounts[i]] = amounts[i];
        }
    }

    function withdrawPrize() external {
        address account = msg.sender;
        uint256 amount = prizes[account];
        require( amount > 0, 'no prize');
        uint256 oleBalance = oleToken.balanceOf(address(this));
        require(amount <= oleBalance, "limit exceed");
        delete prizes[account];
        oleToken.safeTransfer(account, amount);
        emit WithdrawRecord(account, amount);
    }

    function withdraw(address to) external onlyAdmin{
        uint256 amount = oleToken.balanceOf(address(this));
        require(amount > 0, "no amount available");
        oleToken.safeTransfer(to, amount);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "caller must be admin");
        _;
    }

}