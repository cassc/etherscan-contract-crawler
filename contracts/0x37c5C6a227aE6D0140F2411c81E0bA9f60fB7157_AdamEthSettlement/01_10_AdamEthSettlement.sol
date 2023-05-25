// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract AdamEthSettlement is AccessControl, ReentrancyGuard {

    using SafeERC20 for IERC20;
    event Settled(address indexed buyer, uint256 settlePrice, address indexed seller, uint256 sellerPrice, address creater, uint256 royalty, address adamWallet, uint256 indexed pid, uint256 deadline);   
    event ERC20Withdrawed(address indexed recipient, uint256 value, address assetAddress, address indexed sender);
    event OperatorChanged(address indexed oldOperator, address indexed newOperator, address indexed sender);
    event AdamWalletChanged(address indexed oldWallet, address indexed newWallet, address indexed sender);

    // paymentId(pid) -> true/false
    mapping(uint256 => bool) public exclusives;
    address public operator;
    address payable public adamWallet;

    constructor(address _owner, address _operator, address payable _adamWallet) {
        require(_owner != address(0), "owner is the zero address");
        require(_operator != address(0), "operator is the zero address");
        require(_adamWallet != address(0), "adamWallet is the zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        operator = _operator;
        adamWallet = _adamWallet;
    }

    function settle(address payable _seller, uint256 _sellerPrice, address payable _creater, uint256 _royalty, uint256 deadline, uint256 pid, uint8 v, bytes32 r, bytes32 s) nonReentrant() payable external {
        // reproduce the data of the signature
        bytes32 data = keccak256(abi.encodePacked(
            address(msg.sender),
            bytes32(msg.value),
            _seller,
            bytes32(_sellerPrice),
            _creater,
            bytes32(_royalty),
            adamWallet,
            bytes32(pid),
            bytes32(deadline)
        ));

        // check the signature 
        require(ecrecover(data, v, r, s) == operator, "invalid signature");

        // check the deadline
        require(deadline >= block.timestamp, 'expired');

        // avoid multi-payment
        require(!exclusives[pid], "had settled"); 

        // check the msg.value
        require(msg.value >= _sellerPrice + _royalty, "the price is invalid");

        // flag the settled payment 
        exclusives[pid] = true; 

        // send _sellerPrice to seller 
        if(_sellerPrice != 0){
            (bool sent, ) = _seller.call{value: _sellerPrice}("");
            require(sent, "failed to send ETH to seller");
        }

        // send _royalty to creater 
        if(_royalty != 0){
            (bool sent, ) = _creater.call{value: _royalty}("");
            require(sent, "failed to send ETH to creater");
        }

        // send fee to adam wallet
        uint256 feeBalance = msg.value - _sellerPrice - _royalty;
        if(feeBalance != 0){
            (bool sent, ) = adamWallet.call{value: feeBalance}("");
            require(sent, "failed to send ETH to adam wallet");            
        }

        emit Settled(msg.sender, msg.value, _seller, _sellerPrice,  _creater, _royalty, adamWallet, pid, deadline);
    }

    // withdraw ERC20 locked up in the contract
    function withdrawERC20(address _assetAddress, address _recipient, uint256 _value) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(_value <= IERC20(_assetAddress).balanceOf(address(this)), "the ERC20 token balance is insufficient");
        IERC20(_assetAddress).safeTransfer(_recipient, _value);
        emit ERC20Withdrawed(_recipient, _value, _assetAddress, msg.sender);
    }

    function changeOperator(address _newOperator) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(_newOperator != address(0), "new operator is the zero address");
        address old = operator; 
        operator = _newOperator;
        emit OperatorChanged(old, _newOperator, msg.sender);
    }

    function changeAdamWallet(address payable _newWallet) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(_newWallet != address(0), "new wallet is the zero address");
        address old = adamWallet; 
        adamWallet = _newWallet;
        emit AdamWalletChanged(old, _newWallet, msg.sender);
    }
}