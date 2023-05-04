// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./Distributor.sol";
import "./DistributorV2.sol";
import "./ArtikDistributorV1.sol";
import "./DistributorContract.sol";
import "./ArtikDistributor.sol";
import "./DistributorV1.sol";
import "./ArtikDistributorV2.sol";

import "./interfaces/DexRouter.sol";
import "./libraries/ABDKMathQuad.sol";
import "./ArtikTreasury.sol";
import "./ArtikTreasuryV2.sol";
import "./ArtikTreasuryV1.sol";

import "./TreasuryV1.sol";
import "./TreasuryV0.sol";
import "./TreasuryManagerV0.sol";

contract TokenV4 is IERC20, Initializable {
    using SafeMath for uint256;

    // Pancakeswap 0x10ED43C718714eb63d5aA57B78B54704E256024E (testnet: 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3)
    address private constant ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // WBNB 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c (testnet: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd)
    address private constant WETH = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    uint256 private constant TEAM_FEE = 20;
    uint256 private constant TAX_FEE = 10;
    uint256 private constant ANTI_WHALE_AMOUNT = 5000000000000000000000000;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    mapping(address => bool) private excludedFromTax;
    address private _owner;

    // To remove
    Distributor private distributor;
    address payable public distributorAddress;
    DexRouter private dexRouter;
    uint256 public dateFeesAccumulation;
    DistributorContract private distributorContract;
    ArtikDistributor private artikDistributor;
    ArtikDistributorV1 private artikDistributorV1;
    DistributorV1 private distributorV1;
    ArtikDistributorV2 private artikDistributorV2;
    DistributorV2 private distributorV2;
    // End to remove

    ArtikTreasury private treasury;
    ArtikTreasuryV2 private artikTreasury;
    ArtikTreasuryV1 private artikTreasuryV1;
    TreasuryV1 private treasuryV1;
    TreasuryV0 private treasuryV0;
    TreasuryManagerV0 private treasuryManagerV0;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function initialize(uint256 _supply) public initializer {
        _name = "Artik";
        _symbol = "ARTK";

        _transferOwnership(msg.sender);

        _totalSupply += _supply * (10 ** decimals());
        _balances[_owner] += _supply * (10 ** decimals());

        excludedFromTax[_owner] = true;
        excludedFromTax[ROUTER] = true;

        dexRouter = DexRouter(ROUTER);
        _approve(address(this), ROUTER, totalSupply());
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function configureDistributor(address payable _address) external onlyOwner {
        distributorAddress = _address;
        excludedFromTax[_address] = true;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address the_owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[the_owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address the_owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(
            the_owner != address(0),
            "ERC20: approve from the zero address"
        );
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[the_owner][spender] = amount;
        emit Approval(the_owner, spender, amount);
    }

    function processTransfers(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        if (
            excludedFromTax[msg.sender] ||
            excludedFromTax[_sender] ||
            excludedFromTax[_recipient] ||
            _recipient == distributorAddress
        ) {
            _transfer(_sender, _recipient, _amount);
        } else {
            uint256 taxFee = mulDiv(_amount, 8, 100);

            // Transfer amount-fees to recipient
            _transfer(_sender, _recipient, _amount.sub(taxFee));

            // Transfer fee to token wallet
            _transfer(_sender, address(this), taxFee);
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function accumulateFees() external onlyOwner {
        uint256 tokenBalance = balanceOf(address(this));
        uint256 teamFee = mulDiv(tokenBalance, TEAM_FEE, 100);

        // Transfer fee to team wallet
        swapTokens(teamFee, _owner);

        // Transfer airdrop and buy-back fee to distributor
        swapTokens(tokenBalance.sub(teamFee), distributorAddress);
    }

    function transfer(
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        if (msg.sender == distributorAddress && _recipient == address(0x0)) {
            _burn(msg.sender, _amount);
        } else {
            processTransfers(msg.sender, _recipient, _amount);
        }

        return true;
    }

    function transferFrom(
        address the_owner,
        address _recipient,
        uint256 _amount
    ) public override returns (bool) {
        processTransfers(the_owner, _recipient, _amount);

        uint256 currentAllowance = allowance(the_owner, msg.sender);
        require(
            currentAllowance >= _amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(the_owner, msg.sender, currentAllowance.sub(_amount));
        }

        return true;
    }

    function swapTokens(uint256 _amount, address _to) private {
        require(_amount > 0, "amount less than 0");
        require(_to != address(0), "address equal to 0");

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        uint256 amountWethMin = dexRouter.getAmountsOut(_amount, path)[1];

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            amountWethMin,
            path,
            _to,
            block.timestamp
        );
    }

    function excludeFromFee(address _user, bool _exclude) external onlyOwner {
        require(_user != address(0));
        excludedFromTax[_user] = _exclude;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        return
            ABDKMathQuad.toUInt(
                ABDKMathQuad.div(
                    ABDKMathQuad.mul(
                        ABDKMathQuad.fromUInt(x),
                        ABDKMathQuad.fromUInt(y)
                    ),
                    ABDKMathQuad.fromUInt(z)
                )
            );
    }
}