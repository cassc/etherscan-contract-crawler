// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IFactory.sol";
import "../Liquidity.sol";

contract THERUGGAME is ERC20, Ownable {
    uint256 private _feesOnContract;
    uint256 public points;
    uint256 public wethReward;
    address public factory;

    mapping(address => uint256) private _credit;
    mapping(address => uint256) private _xDividendPerToken;

    error EliminatedToken();
    error InvalidBribeToken();
    error NotEnoughBalance();
    error NotEnoughRewards();
    error TransferLimitExceeded();

    event Bribe(
        address indexed tokenUsedForBribe,
        address indexed tokenBribed,
        uint256 amount
    );

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        address _factory
    ) ERC20(_name, _symbol) {
        _mint(msg.sender, _supply);
        factory = _factory;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        address pair = Liquidity.getPair(address(this), Liquidity.WETH);

        if (to != pair && to != address(this) && to != factory) {
            uint256 validTokenTransfer = (totalSupply() / 100) - balanceOf(to);
            if (amount > validTokenTransfer) revert TransferLimitExceeded();
        }

        _withdrawToCredit(from);
        _withdrawToCredit(to);

        if (
            (pair == to && from != address(this) && from != factory) ||
            (pair == from && to != address(this) && to != factory)
        ) {
            uint256 totalTax = burnTax() + cultTax() + rewardTax() + trgTax();
            uint256 feeAmount = (amount * totalTax) / 10000;
            super._transfer(from, address(this), feeAmount);

            _feesOnContract += feeAmount;

            if (from != pair) {
                uint256 swappedCult = _buyAndBurnToken(
                    cult(),
                    (_feesOnContract * cultTax()) / totalTax
                );
                uint256 swappedTrg = _buyAndBurnToken(
                    trg(),
                    (_feesOnContract * trgTax()) / totalTax
                );
                uint256 swappedWeth = Liquidity.swap(
                    address(this),
                    Liquidity.WETH,
                    (_feesOnContract * rewardTax()) / totalTax,
                    slippage(),
                    factory
                );
                uint256 burnAmount = (_feesOnContract * burnTax()) / totalTax;
                super._transfer(
                    address(this),
                    Liquidity.DEAD_ADDRESS,
                    burnAmount
                );

                wethReward += swappedWeth;
                points += swappedCult + swappedTrg + (burnAmount * 100000);
                _feesOnContract = 0;
            } else {
                uint256 validTokenTransfer = (totalSupply() / 100) -
                    balanceOf(to);
                if (amount > validTokenTransfer) revert TransferLimitExceeded();
            }

            return super._transfer(from, to, amount - feeAmount);
        } else return super._transfer(from, to, amount);
    }

    function _buyAndBurnToken(address _tokenOut, uint256 _amountIn)
        private
        returns (uint256)
    {
        if (_amountIn > 0) {
            uint256 swappedAmount = Liquidity.swap(
                address(this),
                _tokenOut,
                _amountIn,
                slippage(),
                address(this)
            );
            transferIERC20(_tokenOut, Liquidity.DEAD_ADDRESS, swappedAmount);

            return swappedAmount;
        }
        return 0;
    }

    function _withdrawToCredit(address _user) private {
        address pair = Liquidity.getPair(address(this), Liquidity.WETH);
        if (
            _user == pair ||
            _user == Liquidity.DEAD_ADDRESS ||
            _user == address(this)
        ) return;

        uint256 recipientBalance = balanceOf(_user);
        if (recipientBalance != 0) {
            uint256 amount = ((dividendPerToken() - _xDividendPerToken[_user]) *
                recipientBalance) / 1e18;
            _credit[_user] += amount;
        }
        _xDividendPerToken[_user] = dividendPerToken();
    }

    function pendingRewards(address _user) public view returns (uint256) {
        address pair = Liquidity.getPair(address(this), Liquidity.WETH);
        if (_user == Liquidity.DEAD_ADDRESS || _user == pair) return 0;

        uint256 userBalance = balanceOf(_user);
        if (userBalance == 0) return 0;

        uint256 amount = ((dividendPerToken() - _xDividendPerToken[_user]) *
            userBalance) / 1e18;
        return amount += _credit[_user];
    }

    function claimReward() external {
        uint256 userReward = pendingRewards(msg.sender);
        if (userReward == 0) revert NotEnoughRewards();

        _credit[msg.sender] = 0;
        _xDividendPerToken[msg.sender] = dividendPerToken();
        transferIERC20(Liquidity.WETH, msg.sender, userReward);
    }

    function bribe(address _token, uint256 _amount) external {
        bool isRugged = IFactory(factory).isValidBribe(address(this));
        if (isRugged) revert EliminatedToken();

        if (
            (_token != cult() && _token != trg()) ||
            trgTax() == 0 ||
            cultTax() == 0
        ) revert InvalidBribeToken();

        if (balanceOfIERC20(_token, msg.sender) < _amount)
            revert NotEnoughBalance();

        uint256 beforeBalance = balanceOfIERC20(_token, address(this));
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        uint256 balanceDifference = balanceOfIERC20(_token, address(this)) -
            beforeBalance;

        uint256 amountToBurn = balanceDifference / 2;
        uint256 amountForHolders = balanceDifference - amountToBurn;

        transferIERC20(_token, Liquidity.DEAD_ADDRESS, amountToBurn);

        if (_token == trg()) transferIERC20(trg(), sTrg(), amountForHolders);
        if (_token == cult()) transferIERC20(cult(), dCult(), amountForHolders);

        points += (_amount * 3) / 2;

        emit Bribe(_token, address(this), _amount);
    }

    function balanceOfIERC20(address _token, address _user)
        private
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_user);
    }

    function transferIERC20(
        address _token,
        address _to,
        uint256 _amount
    ) private returns (bool) {
        return IERC20(_token).transfer(_to, _amount);
    }

    function dividendPerToken() public view returns (uint256) {
        return IFactory(factory).dividendPerToken(address(this));
    }

    function cult() public view returns (address) {
        return IFactory(factory).cult();
    }

    function dCult() public view returns (address) {
        return IFactory(factory).dCult();
    }

    function trg() public view returns (address) {
        return IFactory(factory).trg();
    }

    function sTrg() public view returns (address) {
        return IFactory(factory).sTrg();
    }

    function slippage() public view returns (uint256) {
        return IFactory(factory).slippage();
    }

    function burnTax() public view returns (uint256) {
        return IFactory(factory).burnTax();
    }

    function cultTax() public view returns (uint256) {
        return IFactory(factory).cultTax();
    }

    function rewardTax() public view returns (uint256) {
        return IFactory(factory).rewardTax();
    }

    function trgTax() public view returns (uint256) {
        return IFactory(factory).trgTax();
    }
}