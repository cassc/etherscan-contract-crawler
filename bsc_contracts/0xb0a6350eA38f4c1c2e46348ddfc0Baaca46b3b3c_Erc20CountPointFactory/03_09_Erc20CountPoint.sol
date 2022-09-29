pragma solidity ^0.8.17;

import '../../DealPoint.sol';

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/// @dev allows to create a transaction detail for the transfer of ERC20 tokens
contract Erc20CountPoint is DealPoint {
    IERC20 public token;
    uint256 public needCount;
    address public from;
    address public to;
    uint256 public feePercent;
    uint256 public feeDecimals;

    constructor(
        address _router,
        address _token,
        uint256 _needCount,
        address _from,
        address _to,
        address _feeAddress,
        uint256 _feePercent,
        uint256 _feeDecimals
    ) DealPoint(_router, _feeAddress) {
        router = _router;
        token = IERC20(_token);
        needCount = _needCount;
        from = _from;
        to = _to;
        feePercent = _feePercent;
        feeDecimals = _feeDecimals;
    }

    function isComplete() external view override returns (bool) {
        return token.balanceOf(address(this)) >= needCount;
    }

    function withdraw() external payable {
        address owner = isSwapped ? to : from;
        require(msg.sender == owner || msg.sender == router);
        uint256 balance = token.balanceOf(address(this));
        uint256 fee = (balance * feePercent) / feeDecimals;
        if (!isSwapped) fee = 0;
        uint256 toTransfer = balance - fee;
        token.transfer(feeAddress, fee);
        token.transfer(owner, toTransfer);
    }
}