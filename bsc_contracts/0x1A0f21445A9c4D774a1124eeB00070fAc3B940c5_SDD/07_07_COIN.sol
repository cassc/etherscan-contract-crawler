// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/SlippageERC20.sol";
import "../utils/Permissions.sol";
import "../utils/SimpliRoute.sol";

/// @title SEE
/// @notice total supply 21_000_000, transfer tax 1%, buy and sell tax 10%, sell to u, all tax to taxOwner

contract SEE is SlippageERC20 {
    
    address public taxOwner;
    /// @notice min limit except address
    mapping(address => bool) public noMinLimit;
    event SetNoMinLimit(address indexed _address, bool _noMinLimit);

    address public avoidRobot;
    /// @notice avoid robot, purchase after 20 blocks after sell
    mapping(address => uint) public lastSellBlock;


    function name() external pure returns (string memory) {
        return "SEE Coin";
    }

    function symbol() external pure returns (string memory) {
        return "SEE";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    constructor(address _taxOwner) {
        _mint(msg.sender, 21_000_000 * 1e18);

        address _sender = msg.sender;
        slipWhiteList[_sender] = true;
        _setMin(_sender, true);
        
        taxOwner = _taxOwner;
        slipWhiteList[taxOwner] = true;
        _setMin(taxOwner, true);
    }

    function setTaxOwner(address _taxOwner) external onlyCaller(OWNER) {
        slipWhiteList[taxOwner] = false;
        _setMin(taxOwner, false);
        taxOwner = _taxOwner;
        slipWhiteList[taxOwner] = true;
        _setMin(taxOwner, true);
    }

    function setMinLimit(address _sender, bool _val) external onlyCaller(OWNER) {
        _setMin(_sender, _val);
    }

    function setRobot(address _avoidRobot) external onlyCaller(OWNER) {
        avoidRobot = _avoidRobot;
    }

    function _setMin(address _sender, bool _val) internal {
        noMinLimit[_sender] = _val;
        emit SetNoMinLimit(_sender, _val);
    }

    /// @notice must set taxOwner to slippageWhitelist
    function _transferSlippage(address _from, address _to, uint256, uint _fee) internal override {
        _balanceOf[taxOwner] += _fee;
        emit Transfer(_from, taxOwner, _fee);
        ISellHelper(taxOwner).sell(_from, _to, _fee);
    }

    function _transferAfter(address _from, address _to, uint, uint) internal override {
        require(lastSellBlock[_from] < block.number, "avoid robot");
        if ( avoidRobot == _from ) {
            lastSellBlock[_to] = block.number + 20;
        }
        require(noMinLimit[_from] || _balanceOf[_from] >= 1 ether, "min balance 1");
    }
}

contract SDD is SlippageERC20 {
    
    address public taxOwner;
    /// @notice min limit except address
    mapping(address => bool) public noMinLimit;
    event SetNoMinLimit(address indexed _address, bool _noMinLimit);

    function name() external pure returns (string memory) {
        return "SDD Coin";
    }

    function symbol() external pure returns (string memory) {
        return "SDD";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    constructor(address _taxOwner) {
        _mint(msg.sender, 21_000_000 * 1e18);
        address _sender = msg.sender;
        slipWhiteList[_sender] = true;
        _setMin(_sender, true);
        taxOwner = _taxOwner;
        slipWhiteList[taxOwner] = true;
        _setMin(taxOwner, true);
    }

    function setTaxOwner(address _taxOwner) external onlyCaller(OWNER) {
        slipWhiteList[taxOwner] = false;
        _setMin(taxOwner, false);
        taxOwner = _taxOwner;
        slipWhiteList[taxOwner] = true;
        _setMin(taxOwner, true);
    }

    function setMinLimit(address _sender, bool _val) external onlyCaller(OWNER) {
        _setMin(_sender, _val);
    }

    function _setMin(address _sender, bool _val) internal {
        noMinLimit[_sender] = _val;
        emit SetNoMinLimit(_sender, _val);
    }

    /// @notice must set taxOwner to slippageWhitelist
    function _transferSlippage(address _from, address _to, uint256, uint _fee) internal override {
        _balanceOf[taxOwner] += _fee;
        emit Transfer(_from, taxOwner, _fee);
        ISellHelper(taxOwner).sell(_from, _to, _fee);
    }

    function _transferAfter(address _from, address, uint, uint) internal view override {
        require(noMinLimit[_from] || _balanceOf[_from] >= 1 ether, "min balance 1");
    }
}



interface ISellHelper {
    function sell(address _from, address _to, uint _sellAmount) external;
}

/// @title Sell helper
/// @notice sell to u, all tax to taxOwner
contract SellHelper is SimpliRoute, Permissions {
    
    /// @notice tax owner
    address public taxOwner;
    address public immutable usdt;

    /// @notice lp token mapping, sell token => lp token, default usdt
    mapping(address => address) public lpToken;
    event SetLpToken(address indexed _sellToken, address indexed _lpToken);

    constructor(address _usdt, address _taxOwner) {
        usdt = _usdt;
        taxOwner = _taxOwner;
        _setPermission(OWNER, msg.sender, true);
    }
    
    function setTaxOwner(address _taxOwner) external onlyCaller(OWNER) {
        taxOwner = _taxOwner;
    }

    function setLpToken(address[] calldata _sellTokens, address[] calldata _lpTokens) external onlyCaller(OWNER) {
        for(uint i = 0; i < _sellTokens.length; i++) {
            address _sellToken = _sellTokens[i];
            address _lpToken = _lpTokens[i];
            lpToken[_sellToken] = _lpToken;
            emit SetLpToken(_sellToken, _lpToken);
        }
    }
    
    function _sell(address _sellToken, uint256 _sellAmount) internal {
        _sawp(
            _sellToken,
            usdt,
            lpToken[_sellToken],
            _sellAmount,
            9975,
            0,
            taxOwner
        );
    }

    function sell(address, address _to, uint _sellAmount) external {
        address _sender = msg.sender;
        address _lp = lpToken[_sender];
        if ( _lp == _to ) {
            _sell(_sender, _sellAmount);
        } else {
            (bool success, bytes memory data) = _sender.call(abi.encodeWithSelector(0xa9059cbb, taxOwner, _sellAmount));
            require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
        }
    }

    
}