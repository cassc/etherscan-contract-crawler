// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/ISFTToken.sol";


contract Deposit is Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public filToken;
    ISFTToken public sftToken;
    address public minter; // mint SFT address
    address public taker; // take FIL address
    uint public remainTokens;
    mapping(address => uint) public totalFILDeposited;
    mapping(address => uint) public totalSFTMinted;

    event DepositFIL(address indexed user, uint amount, uint timestamp);
    event MintSFT(address indexed minter, address[] userList, uint[] amountList, uint timestamp);
    event TakeTokens(address indexed taker, address recipient, uint amount, uint timestamp);
    event SetMinter(address oldMinter, address newMinter);
    event SetTaker(address oldTaker, address newTaker);
    

    function initialize(IERC20 _filToken, ISFTToken _sftToken, address _minter, address _taker) external initializer {
        require(address(_filToken) != address(0), "fil token address cannot be zero");
        require(address(_sftToken) != address(0), "SFT token address cannot be zero");
        __Context_init_unchained();
        __Ownable_init_unchained();
        filToken = _filToken;
        sftToken = _sftToken;
        _setMinter(_minter);
        _setTaker(_taker);
    }


    function setMinter(address newMinter) external onlyOwner {
        _setMinter(newMinter);
    }

    function _setMinter(address _minter) private {
        emit SetMinter(minter, _minter);
        minter = _minter;
    }

    function setTaker(address newTaker) external onlyOwner {
        _setTaker(newTaker);
    }

    function _setTaker(address _taker) private {
        emit SetTaker(taker, _taker);
        taker = _taker;
    }
    
    // 质押
    function deposit(uint amount) external {
        require(filToken.balanceOf(address(msg.sender)) >= amount, "fil balance not enough");
        filToken.safeTransferFrom(address(msg.sender), address(this), amount);
        remainTokens += amount;
        totalFILDeposited[address(msg.sender)] += amount;
        emit DepositFIL(address(msg.sender), amount, block.timestamp);
    }

    // 取走质押的fil，拿去做节点
    function takeTokens(address recipient) external {
        require(address(msg.sender) == taker, "only taker can call");
        require(filToken.balanceOf(address(this)) >= remainTokens, "incorrect balance");
        filToken.safeTransfer(recipient, remainTokens);
        emit TakeTokens(address(msg.sender), recipient, remainTokens, block.timestamp);
        delete remainTokens;
    }

    // 节点封装完成
    function mintSFT(address[] calldata userList, uint[] calldata amountList) external {
        require(address(msg.sender) == minter, "only minter can call");
        require(userList.length > 0 && userList.length == amountList.length, "incorrct params");
        for(uint i = 0; i < userList.length; i++) {
            totalSFTMinted[userList[i]] += amountList[i];
            require(totalSFTMinted[userList[i]] <= totalFILDeposited[userList[i]], "minted SFT amount exceed Deposited FIL amount");
            sftToken.mint(userList[i], amountList[i]);
        }
        emit MintSFT(address(msg.sender), userList, amountList, block.timestamp);
    }
}