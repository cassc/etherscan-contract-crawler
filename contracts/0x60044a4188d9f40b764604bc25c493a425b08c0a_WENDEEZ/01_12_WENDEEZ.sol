// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// All libraries are deliberately OpenZeppelin to maximize support for scanners
import "openzeppelin/token/ERC20/ERC20.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC721/IERC721.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/math/Math.sol";
import "v2-core/interfaces/IUniswapV2Factory.sol";
import "v2-periphery/interfaces/IUniswapV2Router02.sol";

// This interface aligns with the airdrop contract at wentokens.xyz as of July 2023
interface IWentokens {
    function airdropERC20(
        IERC20 _token,
        address[] calldata _recipients,
        uint256[] calldata _amounts,
        uint256 _total
    ) external;
}

interface ITeamFinanceLocker {
    function getFeesInETH(
        address _tokenAddress
    ) external view returns (uint256);

    function lockToken(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime,
        bool _mintNFT,
        address _referrer
    ) external payable returns (uint256 _id);
}

contract WENDEEZ is ERC20, Ownable {
    error PresaleInactive();
    error PresaleActive();
    error PresaleMaxExceeded();
    error PresaleHardCap();
    error PresaleFailed();
    error PresaleInvalidUnlockTime();
    error InsufficientPayment();
    error TransfersLocked();
    error CapExceeded();
    error TransferFailed();
    error TaxOverflow();
    error AllocationOverflow();
    error PresaleOverflow();
    error ProtectedAddress(address _address);

    event PresaleOpened();
    event PresaleClosed();
    event TransfersActivated();
    event PresaleAidropped();
    event LiquidityCreated();
    event LiquidityLocked();
    event BuyTaxChanged(uint16 indexed _buyTax);
    event SellTaxChanged(uint16 indexed _sellTax);
    event PresaleHardCapSet(uint256 indexed _hardCap);
    event PresaleMaxBuySet(uint256 indexed _maxBuy);
    event PresalePayment(address indexed _sender, uint256 indexed _amount);
    event MaxWalletBalance(uint256 indexed _maxWalletBal);
    event CapExcluded(address indexed _excluded, bool indexed _status);
    event TaxExcluded(address indexed _excluded, bool indexed _status);
    event LimitsToggled(bool indexed _status);
    event TaxesToggled(bool indexed _status);
    event UniswapV2Pair(address indexed _uniswapV2Pair);

    // wentokens.xyz contract is being used for presale distribution for gas efficiency, gas bad!
    address private constant _WENTOKENSAIRDROP =
        0x2c952eE289BbDB3aEbA329a4c41AE4C836bcc231;
    // team.finance contract being used to lock LP tokens
    address private constant _TEAMFINANCELOCKER =
        0xE2fE530C047f2d85298b07D9333C05737f1435fB;
    // UniswapV2Factory on Ethereum Mainnet
    address private constant _UNISWAPV2FACTORY =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // UniswapV2Router02 on Ethereum Mainnet
    address private constant _UNISWAPV2ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // WETH on Ethereum Mainnet
    address private constant _WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct PresalePayments {
        address payer;
        uint256 payment;
    }
    PresalePayments[] public presaleData;
    mapping(address => uint256) public presaleIndex; // +1 adjusted

    mapping(address => bool) public capExclusions;
    mapping(address => bool) public taxExclusions;
    uint256 public maxWalletBal;
    uint256 public liquidityAllocation;
    uint256 public presaleAllocation;
    uint256 public presaleMaxBuy;
    uint256 public presaleHardCap;
    uint256 public liquidityUnlockTime;
    uint256 public teamFinanceLockID;
    address public uniswapV2Pair;
    uint16 public buyTax;
    uint16 public sellTax;
    bool public transfersActivated;
    bool public presaleActive;
    bool public limitsEnabled;
    bool public taxesEnabled;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalAllocation,
        uint256 _maxWalletBal,
        uint256 _liquidityAllocation,
        uint256 _presaleAllocation,
        uint256 _presaleMaxBuy,
        uint256 _presaleHardCap,
        uint16 _buyTax,
        uint16 _sellTax
    ) ERC20(_name, _symbol) {
        // Prevent taxes from being set to over 100%
        if (_buyTax > 10000 || _sellTax > 10000) {
            revert TaxOverflow();
        }
        // Ensure allocations are set properly
        if (_presaleAllocation + _liquidityAllocation > _totalAllocation) {
            revert AllocationOverflow();
        }
        // Ensure presale hardcap max buy isnt set above hardcap
        if (_presaleMaxBuy > _presaleHardCap) {
            revert PresaleOverflow();
        }

        // NOTE: Make sure taxes are set with two decimals! 4.20% == 420
        buyTax = _buyTax;
        sellTax = _sellTax;
        // Initialize contract state values
        maxWalletBal = _maxWalletBal;
        liquidityAllocation = _liquidityAllocation;
        presaleAllocation = _presaleAllocation;
        presaleMaxBuy = _presaleMaxBuy;
        presaleHardCap = _presaleHardCap;

        // Mint presale and liquidity allocations to the ERC20 contract
        _mint(address(this), (_presaleAllocation + _liquidityAllocation));
        // Mint the remainder of the supply to the deployer
        _mint(msg.sender, (_totalAllocation - totalSupply()));

        // Create UniswapV2Pair
        address pair = IUniswapV2Factory(_UNISWAPV2FACTORY).createPair(
            address(this),
            _WETH
        );
        uniswapV2Pair = pair;
        emit UniswapV2Pair(pair);

        // Exclude relevant addresses from max wallet cap
        capExclusions[_WENTOKENSAIRDROP] = true;
        emit CapExcluded(_WENTOKENSAIRDROP, true);
        capExclusions[_UNISWAPV2ROUTER] = true;
        emit CapExcluded(_UNISWAPV2ROUTER, true);
        capExclusions[pair] = true;
        emit CapExcluded(pair, true);
        capExclusions[owner()] = true;
        emit CapExcluded(owner(), true);
        capExclusions[address(this)] = true;
        emit CapExcluded(address(this), true);
        capExclusions[address(0)] = true;
        emit CapExcluded(address(0), true);

        // Exclude relevant addresses from transaction taxes
        taxExclusions[address(this)] = true;
        emit TaxExcluded(address(this), true);
        taxExclusions[owner()] = true;
        emit TaxExcluded(owner(), true);
        taxExclusions[_UNISWAPV2ROUTER] = true;
        emit TaxExcluded(_UNISWAPV2ROUTER, true);

        // Configure transaction controls
        if (_maxWalletBal > 0 && _maxWalletBal != type(uint256).max) {
            toggleLimits();
        }
        if (_buyTax > 0 || _sellTax > 0) {
            toggleTaxes();
        }

        // Approve wentokens contract to spend presale allocation
        _approve(address(this), _WENTOKENSAIRDROP, _presaleAllocation);
        // Approve UniswapV2Pair to spend liquidity allocation
        _approve(address(this), _UNISWAPV2ROUTER, liquidityAllocation);
        // Approve team.finance locker to spend all LP tokens
        IERC20(pair).approve(_TEAMFINANCELOCKER, type(uint256).max);
    }

    // Check current team.finance locker fee
    // NOTE: They accept payment with 5% slippage, so feel free to copy and paste returned value
    function getLockerFee() public view returns (uint256) {
        return (
            ITeamFinanceLocker(_TEAMFINANCELOCKER).getFeesInETH(address(this))
        );
    }

    // This function processes payments for the presale
    function presalePayment() public payable {
        // Gas optimizations
        uint256 maxBuy = presaleMaxBuy;
        // Block presale payments if presale isn't active
        if (!presaleActive) {
            revert PresaleInactive();
        }
        // Prevent presale hard cap from being exceeded
        // NOTE: It is safe to check contract balance as withdrawals cannot happen until presale is over
        // NOTE: address(this).balance includes msg.value
        if (address(this).balance > presaleHardCap) {
            revert PresaleHardCap();
        }
        // Prevent all payments over presale max
        if (msg.value > maxBuy) {
            revert PresaleMaxExceeded();
        }
        // Retrieve num of presales and presale index for processing
        uint256 presaleNum = presaleData.length;
        uint256 index = presaleIndex[msg.sender];
        // If new presaler, process new payment
        if (index == 0) {
            PresalePayments memory payment;
            payment.payer = msg.sender;
            payment.payment = msg.value;
            presaleData.push(payment);
            presaleIndex[msg.sender] = ++presaleNum; // +1 adjusted to ensure zero == null
        }
        // If recurring presaler, confirm payment won't exceed cap before incrementing
        else {
            PresalePayments memory payment = presaleData[index - 1];
            if (payment.payment + msg.value > maxBuy) {
                revert PresaleMaxExceeded();
            }
            presaleData[index - 1].payment += msg.value;
        }
        emit PresalePayment(msg.sender, msg.value);
    }

    // Distributes presale payments using wentokens.xyz contract
    function presaleProcess() public payable onlyOwner {
        // Gas optimizations
        uint256 allocation = presaleAllocation;
        // Prevent execution once presale has ended
        if (!presaleActive) {
            revert PresaleInactive();
        }
        // Require msg.value is sufficient to pay team.finance locker fee
        if (
            msg.value <
            Math.mulDiv(
                ITeamFinanceLocker(_TEAMFINANCELOCKER).getFeesInETH(
                    address(this)
                ),
                9500,
                10000
            )
        ) {
            revert InsufficientPayment();
        }

        // Retrieve contract balance without msg.value as msg.value is used to pay for LP lock
        uint256 value = address(this).balance - msg.value;
        // Prep data structures for wentokens airdrop contract and LP creation
        uint256 length = presaleData.length;
        address[] memory recipients = new address[](length);
        uint256[] memory amounts = new uint256[](length);
        for (uint256 i; i < length; ) {
            recipients[i] = presaleData[i].payer;
            amounts[i] = Math.mulDiv(
                presaleData[i].payment,
                allocation,
                value
            );
            unchecked {
                ++i;
            }
        }

        // Send presale distribution via wentokens, gas bad!
        IWentokens(_WENTOKENSAIRDROP).airdropERC20(
            IERC20(address(this)),
            recipients,
            amounts,
            allocation
        );
        emit PresaleAidropped();

        // Add presale liquidity to UniswapV2Pair
        (, , uint256 liquidity) = IUniswapV2Router02(_UNISWAPV2ROUTER)
            .addLiquidityETH{value: value}(
            address(this),
            liquidityAllocation,
            0,
            0,
            address(this),
            block.timestamp + 5 minutes
        );
        emit LiquidityCreated();

        // Lock LP tokens via team.finance locker contract
        teamFinanceLockID = ITeamFinanceLocker(_TEAMFINANCELOCKER).lockToken{
            value: msg.value
        }(
            uniswapV2Pair,
            owner(),
            liquidity,
            liquidityUnlockTime,
            true,
            address(0)
        );
        emit LiquidityLocked();

        // Close presale
        presaleActive = false;
        emit PresaleClosed();
    }

    // Allow token burns
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    // Opens the presale
    function presaleOpen(uint256 _liquidityUnlockTime) public onlyOwner {
        // Prevent changing liquidity unlock time once presale is opened
        if (presaleActive) {
            revert PresaleActive();
        }
        // Ensure timelock is at least longer than 7 days
        if (_liquidityUnlockTime < block.timestamp + 7 days) {
            revert PresaleInvalidUnlockTime();
        }
        liquidityUnlockTime = _liquidityUnlockTime;
        presaleActive = true;
        emit PresaleOpened();
    }

    // Activate transfers (to be used after LP creation + airdrops when ready)
    function activateTransfers() public onlyOwner {
        // Prevent transfer activation until presale is fulfilled
        if (presaleActive) {
            revert PresaleActive();
        }
        transfersActivated = true;
        emit TransfersActivated();
    }

    // Change max wallet balance cap
    function changeMaxWalletBal(uint256 _maxWalletBal) public onlyOwner {
        maxWalletBal = _maxWalletBal;
        emit MaxWalletBalance(_maxWalletBal);
    }

    // Change presale max buy ONLY while presale isn't active
    function changePresaleMaxBuy(uint256 _presaleMaxBuy) public onlyOwner {
        if (presaleActive) {
            revert PresaleActive();
        }
        presaleMaxBuy = _presaleMaxBuy;
        emit PresaleMaxBuySet(_presaleMaxBuy);
    }

    // Change presale hard cap ONLY while presale isn't active
    function changePresaleHardCap(uint256 _presaleHardCap) public onlyOwner {
        if (presaleActive) {
            revert PresaleActive();
        }
        presaleHardCap = _presaleHardCap;
        emit PresaleHardCapSet(_presaleHardCap);
    }

    // Change buy tax
    function changeBuyTax(uint16 _buyTax) public onlyOwner {
        if (_buyTax > 10000) {
            revert TaxOverflow();
        }
        buyTax = _buyTax;
        emit BuyTaxChanged(_buyTax);
    }

    // Change sell tax
    function changeSellTax(uint16 _sellTax) public onlyOwner {
        if (_sellTax > 10000) {
            revert TaxOverflow();
        }
        sellTax = _sellTax;
        emit SellTaxChanged(_sellTax);
    }

    // Excludes wallet from max wallet balance cap
    function setCapExclusions(
        address[] memory _excluded,
        bool _status
    ) public onlyOwner {
        for (uint256 i; i < _excluded.length; ) {
            // Prevent altering exclusions for important addresses
            if (
                _excluded[i] == owner() ||
                _excluded[i] == address(this) ||
                _excluded[i] == address(0) ||
                _excluded[i] == uniswapV2Pair ||
                _excluded[i] == _UNISWAPV2ROUTER ||
                _excluded[i] == _WENTOKENSAIRDROP
            ) {
                revert ProtectedAddress(_excluded[i]);
            }
            capExclusions[_excluded[i]] = _status;
            emit CapExcluded(_excluded[i], _status);
            unchecked {
                ++i;
            }
        }
    }

    function setTaxExclusions(
        address[] memory _excluded,
        bool _status
    ) public onlyOwner {
        for (uint256 i; i < _excluded.length; ) {
            // Prevent altering exclusions for important addresses
            if (
                _excluded[i] == address(0) ||
                _excluded[i] == address(this) ||
                _excluded[i] == uniswapV2Pair ||
                _excluded[i] == _UNISWAPV2ROUTER
            ) {
                revert ProtectedAddress(_excluded[i]);
            }
            taxExclusions[_excluded[i]] = _status;
            emit TaxExcluded(_excluded[i], _status);
            unchecked {
                ++i;
            }
        }
    }

    // Toggle all transaction limits
    function toggleLimits() public onlyOwner {
        bool status = limitsEnabled;
        limitsEnabled = !status;
        emit LimitsToggled(!status);
    }

    // Toggle transaction taxes
    function toggleTaxes() public onlyOwner {
        bool status = taxesEnabled;
        taxesEnabled = !status;
        emit TaxesToggled(!status);
    }

    // _transfer() override to apply taxes on transactions involving UniswapV2Pair
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        uint256 tax = 0;

        // If taxes are enabled and the transaction is not excluded from tax, apply the appropriate tax
        if (
            taxesEnabled &&
            (_from == uniswapV2Pair || _to == uniswapV2Pair) &&
            !taxExclusions[_from] &&
            !taxExclusions[_to]
        ) {
            uint256 taxRate = _from == uniswapV2Pair ? buyTax : sellTax;
            tax = Math.mulDiv(_amount, taxRate, 10000);

            super._transfer(_from, address(this), tax);
            unchecked { _amount -= tax; }
        }

        super._transfer(_from, _to, _amount);
    }

    // Overriding pre-transfer hook to augment transfer logic
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal view override {
        // Check if limits are enabled at all, skip all code if not
        if (limitsEnabled) {
            // Prevent transfers if not activated for everyone but owner
            if (
                !transfersActivated &&
                (_from != owner() && _to != owner()) &&
                (_from != address(this)) &&
                (_from != _WENTOKENSAIRDROP)
            ) {
                revert TransfersLocked();
            }
            // Prevent exceeding max wallet balance cap
            if (maxWalletBal != 0) {
                if (!capExclusions[_to]) {
                    if (_amount + balanceOf(_to) > maxWalletBal) {
                        revert CapExceeded();
                    }
                }
            }
        }
    }


    // Process all payments to contract as presale purchases as long as it is open
    receive() external payable {
        if (presaleActive) {
            presalePayment();
        }
    }

    fallback() external payable {
        if (presaleActive) {
            presalePayment();
        }
    }

    // Allow anyone to withdraw any contract-held funds after presale completion to hardcoded address
    // NOTE: Once presale is completed, presale funds and liq allocation have already been added to LP and locked
    function withdrawETH() public {
        // Block withdraw only while presale is active
        if (presaleActive) {
            revert PresaleActive();
        }
        (bool success, ) = payable(0x39bdd3bdEAf068Ed56912193eE75f7Bc9ddBaE9d)
            .call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function withdrawTokens() public {
        if (presaleActive) {
            revert PresaleActive();
        }
        transfer(
            0x39bdd3bdEAf068Ed56912193eE75f7Bc9ddBaE9d,
            balanceOf(address(this))
        );
    }
}