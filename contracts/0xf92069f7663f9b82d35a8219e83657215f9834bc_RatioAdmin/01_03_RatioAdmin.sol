// SPDX-License-Identifier: GPL-3.0 License

pragma solidity >=0.8.0;

import "./interfaces/IRatioAdmin.sol";

import "./interfaces/IERC20.sol";


contract RatioAdmin is IRatioAdmin {

    address public immutable OWNER;

    mapping(address => uint) internal ratio;
    mapping(address => bool) internal isExists;
    address[] public tokens;

    constructor(address _owner) {
        OWNER = _owner;
    }

    modifier onlyOwner() {
        require(OWNER == msg.sender, "NOT_OWNER");
        _;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function getRatio(address token) public view override returns (uint) {
        uint8 tokenDecimals = IERC20(token).decimals();
        uint8 _decimals = decimals();

        if (_decimals >= tokenDecimals) {
            return ratio[token] * 10 ** (_decimals - tokenDecimals);

        } else {
            return ratio[token] / 10 ** (tokenDecimals - _decimals);
        }
    }

    function updateRatio(address token, uint _ratio) external override onlyOwner {
        if (!isExists[token]) {
            tokens.push(token);
            isExists[token] = true;
        }
        ratio[token] = _ratio;
        emit UpdateRatio(msg.sender, token, _ratio);
    }

    function destruct() external onlyOwner {
        selfdestruct(payable(OWNER));
    }
}