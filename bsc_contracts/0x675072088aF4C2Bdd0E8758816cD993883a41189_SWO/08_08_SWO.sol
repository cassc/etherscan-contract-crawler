// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import './BEP20.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SWO is BEP20("Swo", "SWO"), ReentrancyGuard {
    uint256 public constant INITIAL_SUPPLY = 100000000 * (10**18);
    uint16 public transferTaxRate = 2e2; 
    uint16 public burnRate = 50;

    uint16 public constant MAXIMUM_TRANSFER_TAX_RATE = 1e3;
    address public constant BUYBACK_TWO = 0xCaef3c2788c43608Bfa9e9751645f4BE88a6cB2f;
    address public constant BUYBACK_ONE = 0x0b6Ecf1a453df8886caff34065FF56eD81157E9A;

    uint16 public maxTransferAmountRate = 50;
    mapping(address => bool) private _excludedFromAntiWhale;
    mapping(address => bool) private _excludedFromTax;

    mapping(address => bool) public whiteList;
    mapping(address => bool) public blackList;


    event TransferTaxRateUpdated(address indexed owner, uint16 prevRate, uint16 newRate);
    event TransferredOwner(address indexed preOwner, address indexed newOwner);
    event BurnRateUpdated(address indexed owner, uint16 prevRate, uint16 newRate);
    event MaxTransferAmountRateUpdated(address indexed owner, uint16 prevRate, uint16 newRate);


    modifier onlyWhiteList() {
        //solhint-disable-next-line reason-string
        require(whiteList[msg.sender], "SWO: Only whitelisted address can call this function");
        _;
    }

    modifier antiWhale(
        address sender,
        address recipient,
        uint256 amount
    ) {
        if (maxTransferAmount() > 0) {
            if (_excludedFromAntiWhale[sender] == false && _excludedFromAntiWhale[recipient] == false) {
                //solhint-disable-next-line reason-string
                require(amount <= maxTransferAmount(), "SWO: Exceeded Maximum Transfer Amount");
            }
        }
        _;
    }

    modifier transferTaxFees() {
        uint16 _transaferTaxRate = transferTaxRate;
        transferTaxRate = 0;
        _;
        transferTaxRate = _transaferTaxRate;
    }


    constructor() {
        emit TransferredOwner(address(0), msg.sender);

        _excludedFromAntiWhale[BUYBACK_TWO] = true;
        _excludedFromAntiWhale[msg.sender] = true;
        _excludedFromAntiWhale[address(0)] = true;
        _excludedFromAntiWhale[address(this)] = true;

        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function maxTransferAmount() public view returns (uint256) {
        return totalSupply() * maxTransferAmountRate / 1e4;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override antiWhale(sender, recipient, amount) nonReentrant {
        require((!blackList[sender] || whiteList[sender]), "SWO: Sender is blacklisted");

        if (recipient == BUYBACK_ONE || recipient == BUYBACK_TWO || transferTaxRate == 0 || _excludedFromTax[sender]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 taxAmount = amount * transferTaxRate / 1e4;
            uint256 buybackAmount = taxAmount * burnRate / 100;
            uint256 buyBack = taxAmount - buybackAmount;
            require(taxAmount == buybackAmount + buyBack, "SWO:: Burn value invalid");

            uint256 sendAmount = amount - taxAmount;
            require(amount == sendAmount + taxAmount, "SWO: Tax value invalid");

            super._transfer(sender, BUYBACK_TWO, buybackAmount);
            super._transfer(sender, BUYBACK_ONE, buyBack);
            super._transfer(sender, recipient, sendAmount);
            amount = sendAmount;
        }
    }

    receive() external payable {
        //solhint-disable-previous-line no-empty-blocks
    }


    function setBlacklist(address _addressToBlacklist, bool status) external onlyOwner {
        blackList[_addressToBlacklist] = status;
    }

    function setWhitelist(address _addressToWhitelist, bool status) external onlyOwner {
        whiteList[_addressToWhitelist] = status;
    }

    function updateTransferTaxRate(uint16 _transferTaxRate) public onlyOwner {
        //solhint-disable-next-line reason-string
        require(_transferTaxRate <= MAXIMUM_TRANSFER_TAX_RATE, "SWO: Exeeded maximum transfer tax rate");
        transferTaxRate = _transferTaxRate;
        emit TransferTaxRateUpdated(msg.sender, transferTaxRate, _transferTaxRate);
    }

    function updateBurnRate(uint16 _burnRate) public onlyOwner {
        require(_burnRate <= 100, "SWO: Exeeded maximum burn rate");
        burnRate = _burnRate;
        emit BurnRateUpdated(msg.sender, burnRate, _burnRate);
    }

    function updateMaxTransferAmountRate(uint16 _maxTransferAmountRate) public onlyOwner {
        //solhint-disable-next-line reason-string
        require(_maxTransferAmountRate <= 10000, "SWO: Exeeded maximum transfer amount rate");
        maxTransferAmountRate = _maxTransferAmountRate;
        emit MaxTransferAmountRateUpdated(msg.sender, maxTransferAmountRate, _maxTransferAmountRate);
    }

    function setExcludedFromAntiWhale(address _account, bool _excluded) public onlyOwner {
        _excludedFromAntiWhale[_account] = _excluded;
    }

    function setExcludedFromTax(address _account, bool _excluded) public onlyOwner {
        _excludedFromTax[_account] = _excluded;
    }

    function recoverLostToken() public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    function recoverLostBEP20Token(address _token, uint256 amount) public onlyOwner {
        require(_token != address(this), "SWO: Cannot recover BEP20 token");
        BEP20(_token).transfer(msg.sender, amount);
    }
}