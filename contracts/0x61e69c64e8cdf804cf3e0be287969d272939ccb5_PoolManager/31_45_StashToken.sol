// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./Interfaces.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable-0.6/utils/ReentrancyGuardUpgradeable.sol";

interface IERC20Metadata {
    function name() external view returns (string memory); 
    function symbol() external view returns (string memory); 
}

contract StashToken is ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public constant MAX_TOTAL_SUPPLY = 1e38;
    address public immutable stash;

    address public operator;
    address public rewardPool;
    address public baseToken;
    bool public isValid;
    bool public isImplementation;

    uint256 internal _totalSupply;

    constructor(address _stash) public {
        stash = _stash;
        isImplementation = true;
    }

    function init(
        address _operator,
        address _rewardPool,
        address _baseToken
    ) external initializer {
        require(!isImplementation, "isImplementation");
        
        __ReentrancyGuard_init();

        operator = _operator;
        rewardPool = _rewardPool;
        baseToken = _baseToken;
        isValid = true;
    }

    function name() external view returns (string memory) {
        return string(abi.encodePacked("Stash Token ", IERC20Metadata(baseToken).name()));
    }

    function symbol() external view returns (string memory) {
        return string(abi.encodePacked("STASH-", IERC20Metadata(baseToken).symbol()));
    }

    function setIsValid(bool _isValid) external {
        require(msg.sender == IDeposit(operator).owner(), "!owner");
        isValid = _isValid;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function mint(uint256 _amount) external nonReentrant {
        require(msg.sender == stash, "!stash");
        require(_totalSupply.add(_amount) < MAX_TOTAL_SUPPLY, "totalSupply exceeded");

        _totalSupply = _totalSupply.add(_amount);
        IERC20(baseToken).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function transfer(address _to, uint256 _amount) public nonReentrant returns (bool) {
        require(msg.sender == rewardPool, "!rewardPool");
        require(_totalSupply >= _amount, "amount>totalSupply");

        _totalSupply = _totalSupply.sub(_amount);
        IERC20(baseToken).safeTransfer(_to, _amount);

        return true;
    }
}