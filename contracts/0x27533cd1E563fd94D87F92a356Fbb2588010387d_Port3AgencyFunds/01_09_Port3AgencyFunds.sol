// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "IERC20.sol";
import "SafeERC20.sol";

import "Context.sol";
import "ReentrancyGuard.sol";
import "Initializable.sol";
import "IPort3Airdrop.sol";

// Airdrop as LuckyMoney
contract Port3AgencyFunds is Context, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public owner;
    address public feeReceiver;
    uint256 public defaultGasFee;
    IPort3Airdrop public port3AirdropAddr;

    mapping (address => bool) public isOperator;
    mapping (string => uint256) public userGasBalance;
    mapping (string => mapping(address => uint256)) public userTokenBalance;

    event Deposit(
        address indexed _sender,
        string _space_id,
        address _tokenAddr,
        uint256 _tokenAmount,
        uint256 _gasFee
    );
    event Withdraw(
        address indexed _user,
        string _space_id,
        address _tokenAddr,
        uint256 _tokenAmount,
        uint256 _gasFee
    );
    event Airdrop(
        string _space_id,
        address[] _user,
        address _tokenAddr,
        uint256[] _tokenAmount
    );
    
    constructor() public {}

    /* solium-disable-next-line */
    receive () external payable {
    }

    modifier onlyAdmin() {
        require(msg.sender == owner, "only admin is allowed");
        _;
    }
    modifier onlyOperator() {
        require(isOperator[msg.sender], "only operator is allowed");
        _;
    }

    function initialize(address _owner, address _feeReceiver, address _port3AirdropAddr, uint256 _gasFee) external initializer {
        owner = _owner;
        feeReceiver = _feeReceiver;
        defaultGasFee = _gasFee;
        port3AirdropAddr = IPort3Airdrop(_port3AirdropAddr);
        
        isOperator[owner] = true;
    }

    // ========= Normal disperse =========
    function deposit(string memory _space_id, address _tokenAddr, uint256 _tokenAmount, uint256 _gasFee) external payable {
        if (_tokenAddr == address(0)) {
            require((_tokenAmount + _gasFee) == msg.value, "The amount is wrong");
        } else {
            IERC20 token = IERC20(_tokenAddr);

            require(_gasFee == msg.value, "Insufficient gas");
            require(token.balanceOf(msg.sender) >= _tokenAmount, "Insufficient token balance");
            
            uint256 _balance = token.balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), _tokenAmount);

            _tokenAmount = token.balanceOf(address(this)).sub(_balance);
            // require(_balance >= _tokenAmount, "Deflationary tokens are not currently supported");
        }

        payable(feeReceiver).transfer(_gasFee);
        userGasBalance[_space_id] = userGasBalance[_space_id].add(_gasFee);
        userTokenBalance[_space_id][_tokenAddr] = userTokenBalance[_space_id][_tokenAddr].add(_tokenAmount);

        emit Deposit(msg.sender, _space_id, _tokenAddr, _tokenAmount, _gasFee);
    }

    function airdrop(string memory _space_id, address _tokenAddr, address[] memory recipients, uint256[] memory values) external onlyOperator {
        require(recipients.length == values.length, "Parameter is wrong");

        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total = total.add(values[i]);
        }
        uint256 gasUse = recipients.length.mul(defaultGasFee);
        require(userGasBalance[_space_id] >= gasUse, "Insufficient gas");
        userGasBalance[_space_id] = userGasBalance[_space_id].sub(gasUse);

        uint256 fee = port3AirdropAddr.feeOf(total);
        uint256 balance = userTokenBalance[_space_id][_tokenAddr];
        require(balance >= total + fee, "Insufficient balance");
        userTokenBalance[_space_id][_tokenAddr] = balance.sub(total).sub(fee);

        if (_tokenAddr == address(0)) {
            port3AirdropAddr.disperseEther{value: fee + total}(recipients, values);
        } else {
            IERC20(_tokenAddr).approve(address(port3AirdropAddr), total + fee);
            port3AirdropAddr.disperseToken(_tokenAddr, recipients, values);
        }

        emit Airdrop(_space_id, recipients, _tokenAddr, values);
    }

    function withdraw(string memory _space_id, address _recipient, address _tokenAddr, uint256 _tokenAmount, uint256 _gasFee) external onlyOperator {
        uint256 balance = userTokenBalance[_space_id][_tokenAddr];
        uint256 gasBalance = userGasBalance[_space_id];

        require(gasBalance >= _gasFee, "Insufficient gas");
        require(balance >= _tokenAmount, "Insufficient balance");

        userGasBalance[_space_id] = gasBalance.sub(_gasFee);
        userTokenBalance[_space_id][_tokenAddr] = balance.sub(_tokenAmount);

        if (_tokenAmount > 0) {
            if (_tokenAddr == address(0)) {
                payable(_recipient).transfer(_tokenAmount);
            } else {
                IERC20(_tokenAddr).safeTransfer(_recipient, _tokenAmount);
            }
        }

        emit Withdraw(_recipient, _space_id, _tokenAddr, _tokenAmount, _gasFee);
    }

    function getDepositAmount(uint256 _amount) public view returns (uint256 amount) {
        amount = _amount.add(port3AirdropAddr.feeOf(_amount));
        return amount;
    }

    // ========= Admin functions =========
    function setOwner(address _owner) external onlyAdmin {
        require(_owner != address(0), "Owner can't be zero address");
        owner = _owner;
    }

    function setFeeReceiver(address _receiver) external onlyAdmin {
        require(_receiver != address(0), "fee receiver can't be zero address");
        feeReceiver = _receiver;
    }

    function setPort3AirdropAddr(address _port3AirdropAddr) external onlyAdmin {
        require(_port3AirdropAddr != address(0), "Port3 airdrop can't be zero address");
        port3AirdropAddr = IPort3Airdrop(_port3AirdropAddr);
    }

    function setOperator(address _operator, bool _status) external onlyAdmin {
        require(_operator != address(0), "operator can't be zero address");
        isOperator[_operator] = _status;
    }

    function setDefaultGasFee(uint256 _defaultGasFee) external onlyAdmin {
        defaultGasFee = _defaultGasFee;
    }

    function GetInitializeData(address _owner, address _feeReceiver, address _port3AirdropAddr, uint256 _gasFee) public pure returns(bytes memory){
        return abi.encodeWithSignature("initialize(address,address,address,uint256)", _owner,_feeReceiver,_port3AirdropAddr,_gasFee);
    }
}