// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IDEXRouter.sol";
import "./Rescueable.sol";

interface IFeeHandler {
    function getFeeInfo(address sender, address recipient, uint256 amount) external returns (uint256);

    function onFeeReceived(address sender, address recipient, uint256 amount, uint256 fee) external;
}

contract BomberzillaFeeHandler is IFeeHandler, Rescueable {
    IERC20 public token;
    IDEXRouter public router;
    address public feeRecipient;

    address public admin;

    mapping(address => bool) taxless;

    bool public swapEnabled = true;
    uint256 public swapThreshold = 1000 ether;
    mapping(address => bool) public pairs;

    // Fee have 2 decimals, so 100 is equal to 1%, 525 is 5.25% and so on
    uint256 public p2pFee;
    uint256 public buyFee;
    uint256 public sellFee;

    bool inSwap;

    event FeeUpdated(uint256 buyFee, uint256 sellFee, uint256 p2pFee);
    event FeeRecipientUpdated(address indexed oldFeeRecipient, address indexed newFeeRecipient);
    event SetPair(address indexed pair, bool enabled);

    event RouterUpdated(address indexed router);
    event SwapUpdated(bool indexed enabled);
    event SwapThresholdUpdated(uint256 indexed threshold);

    event Swapped(uint256 tokenAmount, uint256 ethAmount);

    constructor(
        IERC20 _token,
        IDEXRouter _router,
        address _feeRecipient,
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _p2pFee
    ) {
        token = _token;
        router = _router;
        buyFee = _buyFee;
        sellFee = _sellFee;
        p2pFee = _p2pFee;
        feeRecipient = _feeRecipient;
        taxless[address(this)] = true;

        emit FeeUpdated(_buyFee, _sellFee, _p2pFee);
        emit FeeRecipientUpdated(address(0), _feeRecipient);
        transferOwnership(_feeRecipient);
    }

    modifier onlyAuthorized() {
        require(msg.sender == address(token), "only token");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == admin, "only owner or admin");
        _;
    }

    modifier lockSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    function getFeeInfo(address sender, address recipient, uint256) external view override returns (uint256) {
        if (taxless[sender] || taxless[recipient] || inSwap) return 0;

        // buy
        if (pairs[sender]) {
            return buyFee;
        }

        // sell
        if (pairs[recipient]) {
            return sellFee;
        }

        // p2p
        return p2pFee;
    }

    function onFeeReceived(address from, address, uint256, uint256) external override onlyAuthorized {
        if (swapEnabled && from != address(router)) {
            _swapTokensForETH();
        }
    }

    function _setPair(address _pair, bool _enable) internal {
        pairs[_pair] = _enable;
        emit SetPair(_pair, _enable);
    }

    function setPair(address _pair, bool _enable) external onlyOwnerOrAdmin {
        _setPair(_pair, _enable);
    }

    function setPairs(address[] memory _pairs, bool[] memory _enable) external onlyOwnerOrAdmin {
        require(_pairs.length == _enable.length, "invalid length");
        for (uint256 i = 0; i < _pairs.length; i++) {
            _setPair(_pairs[i], _enable[i]);
        }
    }

    function setFee(uint256 _buyFee, uint256 _sellFee, uint256 _p2pFee) external onlyOwnerOrAdmin {
        buyFee = _buyFee;
        sellFee = _sellFee;
        p2pFee = _p2pFee;
        emit FeeUpdated(_buyFee, _sellFee, _p2pFee);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwnerOrAdmin {
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    function includeInTax(address[] memory accounts) external onlyOwnerOrAdmin {
        for (uint i = 0; i < accounts.length; i++) {
            delete taxless[accounts[i]];
        }
    }

    function excludeFromTax(address[] memory accounts) external onlyOwnerOrAdmin {
        for (uint i = 0; i < accounts.length; i++) {
            taxless[accounts[i]] = true;
        }
    }

    // ======================= Fee Swap ============================//

    function _swapTokensForETH() private lockSwap {
        uint256 amount = token.balanceOf(address(this));
        if (amount > swapThreshold) {
            address[] memory sellPath = new address[](2);
            sellPath[0] = address(token);
            sellPath[1] = router.WETH();
            token.approve(address(router), amount);

            uint256 balanceBefore = feeRecipient.balance;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0,
                sellPath,
                feeRecipient,
                block.timestamp
            );
            emit Swapped(amount, feeRecipient.balance - balanceBefore);
        }
    }

    function setRouter(IDEXRouter _router) external onlyOwnerOrAdmin {
        router = _router;
        emit RouterUpdated(address(_router));
    }

    function setSwapEnabled(bool _enabled) external onlyOwnerOrAdmin {
        swapEnabled = _enabled;
        emit SwapUpdated(_enabled);
    }

    function setSwapThreshold(uint256 _threshold) external onlyOwnerOrAdmin {
        swapThreshold = _threshold;
        emit SwapThresholdUpdated(_threshold);
    }
}