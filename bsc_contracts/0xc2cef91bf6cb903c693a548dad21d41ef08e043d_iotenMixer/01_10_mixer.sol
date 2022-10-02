// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract iotenMixer is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    address public operator;
    address public feeTaker;
    address public tokenAddress;

    uint256 public fee;

    mapping(uint256 => address) public depositAddress;
    mapping(uint256 => uint256) public depositAmount;
    mapping(bytes32 => uint256) public depositNoteHash;

    mapping(bytes32 => bool) public withdrawn;

    uint256 public counter;

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setFeeTaker(address _feeTaker) external onlyOwner {
        feeTaker = _feeTaker;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _operator, address _tokenAddress, address _feeTaker, uint256 _fee) initializer public  {
        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        operator = _operator;
        tokenAddress = _tokenAddress;
        feeTaker = _feeTaker;
        fee = _fee;
    }   

    function getNotehash(string calldata _note) external pure returns(bytes32) {
        return(keccak256(abi.encodePacked(_note)));
    }

    function deposit(uint256 _amount, bytes32 _noteHash) external whenNotPaused nonReentrant {
        require(depositNoteHash[_noteHash] == 0, "try another note");
        counter = counter + 1;
        depositAddress[counter] = _msgSender();
        depositAmount[counter] = _amount;
        depositNoteHash[_noteHash] = counter;
        IERC20Upgradeable(tokenAddress).safeTransferFrom(_msgSender(), address(this), _amount);
    }

    function withdraw(uint256 _amount, address userAddress, bytes32 _withdrawn) external whenNotPaused nonReentrant {
        require(_msgSender() == operator, "Caller not operator");
        require(withdrawn[_withdrawn] == false, "Already withdrawn");
        withdrawn[_withdrawn] = true;
        IERC20Upgradeable(tokenAddress).safeTransfer(userAddress, _amount - fee);
        IERC20Upgradeable(tokenAddress).safeTransfer(feeTaker, fee);
    }

}