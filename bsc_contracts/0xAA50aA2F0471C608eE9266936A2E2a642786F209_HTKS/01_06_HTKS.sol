// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// import "hardhat/console.sol";

interface IHTKSConfig {
    function isExcludedFromFee(address account) external view returns (bool);

    function isExcludedToFee(address account) external view returns (bool);

    function tx_buy_fee() external view returns (uint256);

    function tx_sell_fee() external view returns (uint256);

    function binder(address _user) external view returns (bool);

    function owner() external view returns (address);

    function node() external view returns (address);

    function eco() external view returns (address);

    function isLp(address _lp) external view returns (bool);

    function canTrade(address _user) external view returns (bool);

    function getSettlementRate()
        external
        pure
        returns (
            uint256 nodeRate,
            uint256 ecoRate,
            uint256 burnRate
        );
}

contract HTKS is ERC20 {
    using Address for address;

    mapping(address => address) public parent;

    IHTKSConfig HTKSConfig;

    event BindReferer(address self, address referer);

    mapping(address => address[]) public children;

    constructor() ERC20("HTKS Token", "HTKS") {
        ERC20._mint(msg.sender, 3999 * 1e18);
        _bindReferer(address(this), msg.sender);
    }

    function init(IHTKSConfig _HTKSConfig) external {
        require(address(HTKSConfig) == address(0));
        HTKSConfig = _HTKSConfig;
    }

    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transferStandard(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _spendAllowance(sender, _msgSender(), amount);
        _transferStandard(sender, recipient, amount);
        return true;
    }

    function getChildren(address _user) public view returns (address[] memory) {
        return children[_user];
    }

    function getParent(address _user) public view returns (address) {
        return parent[_user];
    }

    function skim(address token, address to) public {
        require(msg.sender == HTKSConfig.owner(), "not have permission");
        uint256 value = ERC20(token).balanceOf(address(this));
        _safeTransfer(token, to, value);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "!safeTransfer"
        );
    }

    //
    function bindReferer(address referer) public {
        _bindReferer(referer, msg.sender);
    }

    function _bindReferer(address from, address to) internal {
        if (from != address(0) && to != address(0)) {
            bool canRerferer = parent[to] == address(0) &&
                from != to &&
                parent[from] != to &&
                to != address(this);
            if (canRerferer) {
                parent[to] = from;
                children[from].push(to);
                emit BindReferer(to, from);
            }
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        require(
            HTKSConfig.canTrade(sender) && HTKSConfig.canTrade(recipient),
            "account can not trade!"
        );
        require(sender != address(0), "ERC20: transfer from the burn address");
        require(tAmount > 0, "Transfer amount must be greater than burn");
        // _bindReferer(sender,recipient);

        bool takeFee = false;

        if (
            HTKSConfig.isExcludedFromFee(sender) ||
            HTKSConfig.isExcludedToFee(recipient)
        ) {
            takeFee = false;
        }
        if (takeFee && !sender.isContract() && !recipient.isContract()) {
            takeFee = false;
        }
        (uint256 feeAmount, uint256 leftAmount) = _calcActualAmount(
            tAmount,
            takeFee,
            HTKSConfig.isLp(recipient)
        );
        if (feeAmount > 0) {
            // 滑点分发 比例
            (uint256 nodeRate, uint256 ecoRate, ) = HTKSConfig
                .getSettlementRate();
            uint256 nodeAmount = (nodeRate * feeAmount) / 10000;
            uint256 ecoAmount = (ecoRate * feeAmount) / 10000;
            uint256 burnAmount = feeAmount - nodeAmount - ecoAmount;
            // 节点
            _transfer(sender, HTKSConfig.node(), nodeAmount);
            // 生态
            _transfer(sender, HTKSConfig.eco(), ecoAmount);
            // 销毁
            _burn(sender, burnAmount);
        }
        // console.log("======1111",sender,leftAmount);
        _transfer(sender, recipient, leftAmount);
    }

    function _calcActualAmount(
        uint256 tAmount,
        bool _txFee,
        bool isSell
    ) private view returns (uint256 feeAmount, uint256 leftAmount) {
        if (!_txFee) {
            return (0, tAmount);
        }
        uint256 txFee = HTKSConfig.tx_buy_fee();
        if (isSell) {
            txFee = HTKSConfig.tx_sell_fee();
        }
        feeAmount = (tAmount * txFee) / 10000;
        leftAmount = tAmount - feeAmount;
    }
}