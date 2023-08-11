// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract GuaranteeFund is Ownable, Initializable, UUPSUpgradeable {
    string public domain;
    address public factory;
    address[] public tokens;
    mapping(address => uint256) public tokenIndexs;
    mapping(address => uint256) public tokenAmounts;

    event AddFund(string domain,address sender, address token, uint256 amount);
    event Received(address indexed sender, uint256 value);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function initialize(
        string memory _domain,
        address _owner,
        address _factory,
        address _token,
        uint256 _amount
    ) external initializer {
        _transferOwnership(_owner);
        domain = _domain;
        factory = _factory;
        tokens.push(_token);
        tokenIndexs[_token] = 0;
        tokenAmounts[_token] = _amount;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {
        require(
            newImplementation != address(0),
            "GuaranteeFund: new implementation is the zero address"
        );
        require(
            msg.sender == owner() || msg.sender == factory,
            "GuaranteeFund: not owner or factory"
        );
    }

    function addFund(address _token, uint256 _amount) external payable {
        if (_token == address(0)) {
            require(msg.value >= _amount, "GuaranteeFund: not enough value");
        } else {
            IERC20 token = IERC20(_token);
            require(
                token.allowance(msg.sender, address(this)) >= _amount,
                "GuaranteeFund: not enough allowance"
            );
            token.transferFrom(msg.sender, address(this), _amount);
        }
        if (tokenAmounts[_token] == 0) {
            tokens.push(_token);
            tokenIndexs[_token] = tokens.length - 1;
            tokenAmounts[_token] = _amount;
        } else {
            tokenAmounts[_token] += _amount;
        }
        emit AddFund(domain,msg.sender, _token, _amount);
    }
}