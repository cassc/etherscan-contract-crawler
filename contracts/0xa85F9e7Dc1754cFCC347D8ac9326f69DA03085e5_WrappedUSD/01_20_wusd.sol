pragma solidity ^0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC20/IERC20.sol';
import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.8/contracts/token/ERC20/utils/SafeERC20.sol';

import './PreciseMath.sol';
import './AddressArrayUtils.sol';

contract WrappedUSD is ERC20, AccessControl, ERC20FlashMint {
    using SafeERC20 for IERC20;
    using PreciseMath for uint256;
    using AddressArrayUtils for address[];

    error NoLimit(uint limit);
    error NotValid(address coin);

    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");

    event Mint(address indexed to, address indexed coin, uint256 value);
    event Burn(address indexed from, address indexed coin, uint256 value);

    address[] coins;
    mapping(address => bool) public validCoins;
    mapping(address => uint256) public limits;
    mapping(address => uint256) public mintFees;
    mapping(address => uint256) public burnFees;

    constructor() ERC20("Wrapped USD", "WUSD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(GOVERNANCE_ROLE, msg.sender);
    }

    function getCoins() external view returns(address[] memory) {
        return coins;
    }

    // TODO: support decimal conversions
    function mint(address _coin, uint256 _amount) external {
        if(!validCoins[_coin]) {
            revert NotValid(_coin);
        }
        uint256 mintAmount = _amount.preciseMul(1e18 - mintFees[_coin]);
        if(mintAmount > limits[_coin]) {
            revert NoLimit(limits[_coin]);
        }

        IERC20(_coin).safeTransferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, mintAmount);
        limits[_coin] -= mintAmount;

        emit Mint(msg.sender, _coin, mintAmount);
    }

    // TODO: support decimal conversions
    function burn(address _coin, uint256 _amount) external {
        if(!validCoins[_coin]) {
            revert NotValid(_coin);
        }
        uint256 sendAmount = _amount.preciseMul(1e18 - burnFees[_coin]);
        _burn(msg.sender, _amount);
        IERC20(_coin).safeTransfer(msg.sender, sendAmount);
        limits[_coin] += _amount;

        emit Burn(msg.sender, _coin, _amount);
    }

    function addCoin(address _coin) external onlyRole(GOVERNANCE_ROLE) {
        coins.push(_coin);
        validCoins[_coin] = true;
    }

    function removeCoin(address _coin) external onlyRole(GOVERNANCE_ROLE) {
        coins.remove(_coin);
        delete validCoins[_coin];
    }

    function addLimit(address _coin, uint256 _amount) external onlyRole(GOVERNANCE_ROLE) {
        limits[_coin] += _amount;
    }

    function reduceLimit(address _coin, uint256 _amount) external onlyRole(GOVERNANCE_ROLE) {
        limits[_coin] -= _amount;
    }

    function setMintFee(address _coin, uint256 _fee) external onlyRole(GOVERNANCE_ROLE) {
        mintFees[_coin] = _fee;
    }

    function setBurnFee(address _coin, uint256 _fee) external onlyRole(GOVERNANCE_ROLE) {
        burnFees[_coin] = _fee;
    }
}