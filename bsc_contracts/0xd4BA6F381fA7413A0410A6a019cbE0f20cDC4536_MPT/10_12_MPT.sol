// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./OperationWithSigner.sol";
import "./PancakeSwap.sol";

contract MPT is ERC20Burnable, OperationWithSigner {
    using ECDSA for bytes32;

    uint8 constant _DECIMALS = 9;
    uint256 constant _GWEI = 10**_DECIMALS;
    uint256 constant _TOTAL_SUPPLY = 10000000 * _GWEI;
    uint256 constant _LP_ALLOCATION = 20000 * _GWEI;
    uint256 constant _INCOME_ALLOCATION = 9980000 * _GWEI;

    uint256 private _lpIncomeGiven = 0;
    uint256 private _nodeIncomeGiven = 0;
    uint256 private _platformIncomeGiven = 0;
    uint256 private _totalWithdrawals = 0;

    uint256 private _lpIncomePercent = 4;
    uint256 private _platformIncomePercent = 5;
    uint256 private _nodeIncomePercent = 3;

    uint256 private _burnPercent = 3;

    uint256 private _totalBurned = 0;
    /*fee related */

    mapping(address => bool) private _feeWhitelist;
    address public pancakePairAddress;
    address public pancakeRouterAddress;
    bool private _feeEnabled;

    mapping(string => bool) _usedIds;
    IERC20 public USDT;
    event TransferWithFee(
        address sender,
        address recipient,
        uint256 amount,
        uint256 lpFee,
        uint256 platformFee,
        uint256 nodeFee,
        uint256 burned
    );

    /*withdrawal related */
    event Withdrawal(address wallet, string withdrawalId, uint256 amount);

    //tracking of total withdrawals per address so we can have
    //a sanity check on total income to ensure that user cannot
    //withdraw more than their income.
    mapping(address => uint256) private _incomeWithdrawals;

    constructor(address foundationAddress, address usdtAddress)
        ERC20("Meta Mine Token", "MPT")
    {
        USDT = IERC20(usdtAddress);
        _mint(foundationAddress, _LP_ALLOCATION);
        _mint(address(this), _INCOME_ALLOCATION);
        _feeWhitelist[address(this)] = true;
        _feeWhitelist[foundationAddress] = true;
    }

    function decimals() public pure override returns (uint8) {
        return _DECIMALS;
    }

    //fee functions
    function setFeeEnabled(bool value) external onlyOperators {
        _feeEnabled = value;
    }

    function isFeeEnabled() public view returns (bool) {
        return _feeEnabled;
    }

    function setFeeWhitelist(address addr, bool value) external onlyOperators {
        _feeWhitelist[addr] = value;
    }

    function setFeeWhitelists(address[] memory addresses, bool value)
        external
        onlyOperators
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _feeWhitelist[addresses[i]] = value;
        }
    }

    function isFeeWhiteListed(address addr) external view returns (bool) {
        return _feeWhitelist[addr];
    }

    function setPancakePairAddress(address pairAddress) external onlyOperators {
        pancakePairAddress = pairAddress;
    }

    function setPancakeRouterAddress(address routerAddress)
        external
        onlyOperators
    {
        pancakeRouterAddress = routerAddress;
    }

    function setBurnPercent(uint256 burnPercent) external onlyOperators {
        _burnPercent = burnPercent;
    }

    function getBurnPercent() external view returns (uint256) {
        return _burnPercent;
    }

    function getLpIncomeGiven() public view returns (uint256) {
        return _lpIncomeGiven;
    }

    function getNodeIncomeGiven() public view returns (uint256) {
        return _nodeIncomeGiven;
    }

    function getPlatformIncomeGiven() external view returns (uint256) {
        return _platformIncomeGiven;
    }

    function setNodeIncomePercent(uint256 percent) external onlyOperators {
        _nodeIncomePercent = percent;
    }

    function setLpIncomePercent(uint256 percent) external onlyOperators {
        _lpIncomePercent = percent;
    }

    function setPlatformIncomePercent(uint256 percent) external onlyOperators {
        _platformIncomePercent = percent;
    }

    function getNodeIncomePercent() external view returns (uint256) {
        return _nodeIncomePercent;
    }

    function getLpIncomePercent() external view returns (uint256) {
        return _lpIncomePercent ;
    }

    function getPlatformIncomePercent() external view returns (uint256) {
        return _platformIncomePercent;
    }

    function getTotalBurned() external view returns (uint256) {
        return _totalBurned;
    }

    //withdrawal related
    function getIncomeWithdrawals(address user)
        external
        view
        returns (uint256)
    {
        return _incomeWithdrawals[user];
    }

    function hashTransaction(
        address sender,
        string memory withdrawalId,
        uint256 amount,
        uint256 maxWithdraw,
        uint256 timeoutBlock
    ) internal pure returns (bytes32) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(
                    abi.encodePacked(
                        sender,
                        withdrawalId,
                        amount,
                        maxWithdraw,
                        timeoutBlock
                    )
                )
            )
        );
        return hash;
    }

    function withdraw(
        bytes memory signature,
        string memory withdrawalId,
        uint256 amount,
        uint256 maxWithdraw,
        uint256 timeoutBlock
    ) external {
        require(block.number <= timeoutBlock, "REQUEST_EXPIRED");
        require(
            _totalWithdrawals + amount <=
                _INCOME_ALLOCATION +
                    _lpIncomeGiven +
                    _platformIncomeGiven +
                    _nodeIncomeGiven,
            "WITHDRAWAL_EXCEEDED_BALANCE"
        );
        require(
            _incomeWithdrawals[msg.sender] + amount <= maxWithdraw,
            "WITHDRAW_EXCEED_QUOTA"
        );
        require(_usedIds[withdrawalId] == false, "DUPLICATE_REQUEST");
        _usedIds[withdrawalId] = true;
        require(
            hashTransaction(
                msg.sender,
                withdrawalId,
                amount,
                maxWithdraw,
                timeoutBlock
            ).recover(signature) == getSignerAddress(),
            "INVALID_SIGNATURE"
        );
        _totalWithdrawals += amount;
        _incomeWithdrawals[msg.sender] += amount;
        super._transfer(address(this), msg.sender, amount);
        emit Withdrawal(msg.sender, withdrawalId, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (
            !_feeEnabled ||
            from == pancakePairAddress ||
            _feeWhitelist[from] ||
            _feeWhitelist[to]
        ) {
            //without fee
            super._transfer(from, to, amount);
        } else {
            //with fee
            uint256 toBurn = (_burnPercent * amount) / 100;
            uint256 lpIncome = (_lpIncomePercent * amount) / 100;
            uint256 nodeIncome = (_nodeIncomePercent * amount) / 100;
            uint256 platformIncome = (_platformIncomePercent * amount) / 100;
            uint256 actualAmount = amount -
                toBurn -
                lpIncome -
                nodeIncome -
                platformIncome;
            _burn(from, toBurn);
            super._transfer(
                from,
                address(this),
                lpIncome + nodeIncome + platformIncome
            );
            super._transfer(from, to, actualAmount);
            _nodeIncomeGiven += nodeIncome;
            _lpIncomeGiven += lpIncome;
            _platformIncomeGiven += platformIncome;
            emit TransferWithFee(
                from,
                to,
                amount,
                lpIncome,
                platformIncome,
                nodeIncome,
                toBurn
            );
        }
    }

    /* return the price of MEM in USDT*/
    function getMemPrice(uint256 amount) external view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(
            pancakePairAddress
        ).getReserves();
        if (address(this) > address(USDT)) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        return
            IPancakeRouter01(pancakeRouterAddress).quote(
                amount,
                reserve0,
                reserve1
            );
    }

    /* return the price of USDT in MEM*/
    function getUsdtPrice(uint256 amount) external view returns (uint256) {
        (uint256 reserve0, uint256 reserve1, ) = IPancakePair(
            pancakePairAddress
        ).getReserves();
        if (address(this) > address(USDT)) {
            (reserve0, reserve1) = (reserve1, reserve0);
        }
        return
            IPancakeRouter01(pancakeRouterAddress).quote(
                amount,
                reserve1,
                reserve0
            );
    }

    function addLiquidity(uint256 usdtAmount, uint256 memAmount)
        external
        returns (
            uint256 usdt,
            uint256 mem,
            uint256 liquidity
        )
    {
        require(balanceOf(msg.sender) >= memAmount, "INSUFFICIENT_BALANCE");
        USDT.transferFrom(msg.sender, address(this), usdtAmount);
        super._transfer(msg.sender, address(this), memAmount);
        USDT.approve(pancakeRouterAddress, usdtAmount);
        this.approve(pancakeRouterAddress, memAmount);
        (mem, usdt, liquidity) = IPancakeRouter01(pancakeRouterAddress)
            .addLiquidity(
                address(this),
                address(USDT),
                memAmount,
                usdtAmount,
                0,
                0,
                msg.sender,
                block.timestamp
            );
        //return  excess and clear approval
        if (usdt < usdtAmount) {
            USDT.transfer(msg.sender, usdtAmount - usdt);
            USDT.approve(pancakeRouterAddress, 0);
        }
        if (mem < memAmount) {
            super._transfer(address(this), msg.sender, memAmount - mem);
            approve(pancakeRouterAddress, 0);
        }
        return (usdt, mem, liquidity);
    }

    function _burn(address account, uint256 amount) internal override {
        super._burn(account, amount);
        _totalBurned += amount;
    }

    function adminWithdraw(
        address recipient,
        uint256 amount,
        address coin
    ) external onlyOperators {
        IERC20(coin).transfer(recipient, amount);
    }
}