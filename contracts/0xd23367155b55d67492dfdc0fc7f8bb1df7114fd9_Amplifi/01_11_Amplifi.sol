// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAmplifi.sol";
import "./interfaces/IUniswap.sol";
import "./AmplifiNode.sol";
import "./Types.sol";

/**
 * Amplifi
 * Website: https://perpetualyield.io/
 * Telegram: https://t.me/Amplifi_ERC
 * Twitter: https://twitter.com/amplifidefi
 */
contract Amplifi is IERC20, IAmplifi, Ownable {
    string public constant name = "Amplifi";
    string public constant symbol = "AMPLIFI";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 121_373e18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    IERC20 public immutable WETH;
    IERC20 public immutable USDC;

    IUniswapV2Router02 public immutable router;
    address public immutable pair;

    AmplifiNode public amplifiNode;
    address private amplifiNodeAddress;

    uint256 public maxWallet = type(uint256).max;

    mapping(address => bool) public isDisabledExempt;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isMaxExempt;
    mapping(address => bool) public isUniswapPair;

    // Fees are charged on swaps
    Types.FeeRecipients public feeRecipients;
    Types.Fees public fees;
    uint16 public feeTotal = 900;

    // Taxes are charged on transfers and burned
    uint16 public tax = 300;

    // Basis for all fee and tax values
    uint16 public constant bps = 10_000;

    bool public contractSellEnabled = true;
    uint256 public contractSellThreshold = 65e18;
    uint256 public minSwapAmountToTriggerContractSell = 0;

    bool public mintingEnabled = true;
    bool public burningEnabled = true;
    bool public tradingEnabled = false;
    bool public isContractSelling = false;

    modifier contractSelling() {
        isContractSelling = true;
        _;
        isContractSelling = false;
    }

    constructor(
        address _router,
        address _usdc,
        address _gampVault
    ) {
        router = IUniswapV2Router02(_router);
        USDC = IERC20(_usdc);

        pair = IUniswapV2Factory(router.factory()).createPair(address(USDC), address(this));

        WETH = IERC20(router.WETH());

        amplifiNode = new AmplifiNode(this, router, USDC, msg.sender);
        amplifiNodeAddress = address(amplifiNode);

        isDisabledExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        isMaxExempt[msg.sender] = true;
        isDisabledExempt[amplifiNodeAddress] = true;
        isFeeExempt[amplifiNodeAddress] = true;
        isMaxExempt[amplifiNodeAddress] = true;
        isDisabledExempt[address(0)] = true;
        isFeeExempt[address(0)] = true;
        isMaxExempt[address(0)] = true;
        isMaxExempt[address(this)] = true;
        isUniswapPair[pair] = true;

        allowance[address(this)][address(router)] = type(uint256).max;

        feeRecipients = Types.FeeRecipients(
            0xc766B8c9741BC804FCc378FdE75560229CA3AB1E,
            0x682Ce32507D2825A540Ad31dC4C2B18432E0e5Bd,
            0x146f0Af003d2eB9B06a1900F5de9d01708072c3f,
            0x394110aceF86D93b20705d2Df00bE1629ce741De,
            0x8C3F0b1Bd87965bE0dc01A9b7fc3003abec1A3CB,
            0xbE328EAAe2199409a447c4121C7979fFfAaCd4d5,
            _gampVault,
            0x74B605FD7cfC830A862Ee6F2F2e1007608B4b2fF,
            0x5A23C387112e8e213B0755191e7d1cdC26b0C1b2,
            0x6f967da9c0E1764159408988fDcF6c3B7Bf0F9F7,
            0x454cD1e89df17cDB61D868C6D3dBC02bC2c38a17
        );

        fees = Types.Fees(175, 87, 87, 87, 44, 44, 44, 44, 44, 44, 200);

        uint256 toEmissions = 39_000e18;
        uint256 toDeployer = totalSupply - toEmissions;

        balanceOf[msg.sender] = toDeployer;
        emit Transfer(address(0), msg.sender, toDeployer);

        balanceOf[amplifiNodeAddress] = toEmissions;
        emit Transfer(address(0), amplifiNodeAddress, toEmissions);
    }

    function mint(uint256 _amount) external onlyOwner {
        require(mintingEnabled, "Minting is disabled");

        totalSupply += _amount;
        unchecked {
            balanceOf[msg.sender] += _amount;
        }
        emit Transfer(address(0), msg.sender, _amount);
    }

    function burn(address _burnee, uint256 _amount) external onlyOwner returns (bool) {
        require(burningEnabled, "Burning is disabled");
        require(balanceOf[_burnee] >= _amount, "Cannot burn more than an account has");

        totalSupply -= _amount;

        balanceOf[_burnee] -= _amount;
        emit Transfer(_burnee, address(0), _amount);
        return true;
    }

    function burnForAmplifier(address _burnee, uint256 _amount) external returns (bool) {
        require(msg.sender == address(amplifiNode), "Only the Amplifier Node contract can burn");
        require(balanceOf[_burnee] >= _amount, "Cannot burn more than an account has");

        uint256 allowed = allowance[_burnee][msg.sender];
        if (allowed != type(uint256).max) {
            allowance[_burnee][msg.sender] = allowed - _amount;
        }

        totalSupply -= _amount;

        balanceOf[_burnee] -= _amount;
        emit Transfer(_burnee, address(0), _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        allowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transfer(address _recipient, uint256 _amount) external override returns (bool) {
        return _transferFrom(msg.sender, _recipient, _amount);
    }

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external override returns (bool) {
        uint256 allowed = allowance[_sender][msg.sender];
        if (allowed != type(uint256).max) {
            allowance[_sender][msg.sender] = allowed - _amount;
        }

        return _transferFrom(_sender, _recipient, _amount);
    }

    function _transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (bool) {
        if (isContractSelling) {
            return _simpleTransfer(_sender, _recipient, _amount);
        }

        require(tradingEnabled || isDisabledExempt[_sender], "Trading is currently disabled");

        bool sell = isUniswapPair[_recipient] || _recipient == address(router);

        if (!sell && !isMaxExempt[_recipient]) {
            require((balanceOf[_recipient] + _amount) <= maxWallet, "Max wallet has been triggered");
        }

        if (
            sell &&
            _amount >= minSwapAmountToTriggerContractSell &&
            !isUniswapPair[msg.sender] &&
            !isContractSelling &&
            contractSellEnabled &&
            balanceOf[address(this)] >= contractSellThreshold
        ) {
            _contractSell();
        }

        balanceOf[_sender] -= _amount;

        uint256 amountAfter = _amount;
        if (
            ((isUniswapPair[_sender] || _sender == address(router)) ||
                (isUniswapPair[_recipient] || _recipient == address(router)))
                ? !isFeeExempt[_sender] && !isFeeExempt[_recipient]
                : false
        ) {
            amountAfter = _collectFee(_sender, _amount);
        } else if (!isFeeExempt[_sender] && !isFeeExempt[_recipient]) {
            amountAfter = _collectTax(_sender, _amount);
        }

        unchecked {
            balanceOf[_recipient] += amountAfter;
        }
        emit Transfer(_sender, _recipient, amountAfter);

        return true;
    }

    function _simpleTransfer(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private returns (bool) {
        balanceOf[_sender] -= _amount;
        unchecked {
            balanceOf[_recipient] += _amount;
        }
        return true;
    }

    function _contractSell() private contractSelling {
        uint256 ethBefore = address(this).balance;

        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(USDC);
        path[2] = address(WETH);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            balanceOf[address(this)],
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethAfter = address(this).balance - ethBefore;

        if (ethAfter > bps) {
            bool success;
            (success, ) = feeRecipients.operations.call{value: (ethAfter * fees.operations) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.validatorAcquisition.call{value: (ethAfter * fees.validatorAcquisition) / bps}(
                ""
            );
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.PCR.call{value: (ethAfter * fees.PCR) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.yield.call{value: (ethAfter * fees.yield) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.xChainValidatorAcquisition.call{
                value: (ethAfter * fees.xChainValidatorAcquisition) / bps
            }("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.indexFundPools.call{value: (ethAfter * fees.indexFundPools) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.gAMPRewardsPool.call{value: (ethAfter * fees.gAMPRewardsPool) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.OTCSwap.call{value: (ethAfter * fees.OTCSwap) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.rescueFund.call{value: (ethAfter * fees.rescueFund) / bps}("");
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.protocolImprovement.call{value: (ethAfter * fees.protocolImprovement) / bps}(
                ""
            );
            require(success, "Could not send ETH");
            (success, ) = feeRecipients.developers.call{value: (ethAfter * fees.developers) / bps}("");
            require(success, "Could not send ETH");
        }
    }

    function _collectFee(address _sender, uint256 _amount) private returns (uint256) {
        uint256 feeAmount = (_amount * feeTotal) / bps;

        unchecked {
            balanceOf[address(this)] += feeAmount;
        }
        emit Transfer(_sender, address(this), feeAmount);

        return _amount - feeAmount;
    }

    function _collectTax(address _sender, uint256 _amount) private returns (uint256) {
        uint256 taxAmount = (_amount * tax) / bps;

        totalSupply -= taxAmount;

        emit Transfer(_sender, address(0), _amount);

        return _amount - taxAmount;
    }

    function setMaxWallet(uint256 _maxWallet) external onlyOwner {
        maxWallet = _maxWallet;
    }

    function setIsDisabledExempt(address _holder, bool _exempt) external onlyOwner {
        isDisabledExempt[_holder] = _exempt;
    }

    function setIsFeeExempt(address _holder, bool _exempt) external onlyOwner {
        isFeeExempt[_holder] = _exempt;
    }

    function setIsMaxExempt(address _holder, bool _exempt) external onlyOwner {
        isMaxExempt[_holder] = _exempt;
    }

    function setIsUniswapPair(address _pair, bool _isPair) external onlyOwner {
        isUniswapPair[_pair] = _isPair;
    }

    function setContractSelling(
        bool _contractSellEnabled,
        uint256 _contractSellThreshold,
        uint256 _minSwapAmountToTriggerContractSell
    ) external onlyOwner {
        contractSellEnabled = _contractSellEnabled;
        contractSellThreshold = _contractSellThreshold;
        minSwapAmountToTriggerContractSell = _minSwapAmountToTriggerContractSell;
    }

    function setFees(Types.Fees calldata _fees) external onlyOwner {
        fees = _fees;

        feeTotal =
            _fees.operations +
            _fees.validatorAcquisition +
            _fees.PCR +
            _fees.yield +
            _fees.xChainValidatorAcquisition +
            _fees.indexFundPools +
            _fees.gAMPRewardsPool +
            _fees.OTCSwap +
            _fees.rescueFund +
            _fees.protocolImprovement +
            _fees.developers;
    }

    function setFeeRecipients(Types.FeeRecipients calldata _feeRecipients) external onlyOwner {
        feeRecipients = _feeRecipients;
    }

    function setTax(uint16 _tax) external onlyOwner {
        tax = _tax;
    }

    function setTradingEnabled(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
    }

    function setAmplifiNode(AmplifiNode _amplifiNode) external onlyOwner {
        amplifiNode = _amplifiNode;
        amplifiNodeAddress = address(amplifiNode);

        isDisabledExempt[amplifiNodeAddress] = true;
        isFeeExempt[amplifiNodeAddress] = true;
        isMaxExempt[amplifiNodeAddress] = true;
    }

    function permanentlyDisableMinting() external onlyOwner {
        mintingEnabled = false;
    }

    function permanentlyDisableBurning() external onlyOwner {
        burningEnabled = false;
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        require(success, "Could not send ETH");
    }

    function withdrawToken(IERC20 _token, address _recipient) external onlyOwner {
        _token.transfer(_recipient, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}