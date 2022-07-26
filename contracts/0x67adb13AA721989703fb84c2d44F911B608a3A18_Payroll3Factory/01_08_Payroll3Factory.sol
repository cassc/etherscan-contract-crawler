// SPDX-License-Identifier: MIT

/*
 * @title Payroll3 Factory v0.1
 * @author Marcus J. Carey, @marcusjcarey
 * @notice Payroll3 Factory allows accounts to mint Payroll3 smart wallets
 */

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Payroll3.sol';

contract Payroll3Factory {
    event PayrollDeployed(address indexed _from, address _payroll);
    event AdminAdded(address indexed _from, address _address);
    event BalanceWithdrawal(address indexed _from, uint256 _balance);
    event PaymentReceived(address indexed _from, uint256 _amount);

    mapping(address => mapping(uint256 => bool)) public promoClaims;
    mapping(address => bool) public admins;
    mapping(address => address[]) private payrolls;

    uint256 public cost;
    uint256 public payrollsDeployed;
    uint256 promoCode;
    uint256 promoCost;

    address public owner;
    address public payee;

    bool public paused;
    bool public activePromo;

    constructor(uint256 _cost) {
        admins[msg.sender] = true;
        payee = msg.sender;
        owner = msg.sender;
        cost = _cost;
        promoCode = 0;
        promoCost = 0;
        activePromo = false;
        paused = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender]);
        _;
    }

    modifier pauseCheck() {
        require(!paused, 'Contract paused!');
        _;
    }

    function checkValue(uint256 _value) private {
        require(msg.value >= _value, 'Insufficient value.');
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
        emit AdminAdded(msg.sender, _address);
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function setPaused(bool _bool) external onlyAdmin {
        paused = _bool;
    }

    function balance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function deploy(
        string memory _name,
        string memory _primaryToken,
        uint256 _releasableDate,
        address[] memory _payees,
        uint256[] memory _shares,
        address[] memory _tokens,
        bool _stream
    ) internal {
        Payroll3 payroll = new Payroll3(
            _name,
            msg.sender,
            _primaryToken,
            _releasableDate,
            _payees,
            _shares,
            _tokens,
            _stream
        );

        payrolls[msg.sender].push(payroll.contractAddress());
        payrollsDeployed++;
        emit PayrollDeployed(msg.sender, payroll.contractAddress());
    }

    function mint(
        string memory _name,
        string memory _primaryToken,
        uint256 _releasableDate,
        address[] memory _payees,
        uint256[] memory _shares,
        address[] memory _tokens,
        bool _stream
    ) public payable pauseCheck {
        if (admins[msg.sender]) {} else if (
            activePromo && !promoClaims[msg.sender][promoCode]
        ) {
            checkValue(promoCost);
            promoClaims[msg.sender][promoCode] = true;
        } else {
            checkValue(cost);
        }

        deploy(
            _name,
            _primaryToken,
            _releasableDate,
            _payees,
            _shares,
            _tokens,
            _stream
        );
    }

    function getDeployedPayrolls(address _address)
        public
        view
        returns (address[] memory)
    {
        return payrolls[_address];
    }

    function updateCost(uint256 _cost) external onlyAdmin {
        cost = _cost;
    }

    function updateOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function updatePayee(address _payee) external onlyOwner {
        payee = _payee;
    }

    function updatePromo(
        bool _activePromo,
        uint256 _promoCode,
        uint256 _promoCost
    ) public onlyAdmin {
        activePromo = _activePromo;
        promoCode = _promoCode;
        promoCost = _promoCost;
    }

    function withdraw() external onlyAdmin {
        uint256 amount = address(this).balance;
        payable(payee).transfer(amount);
        emit BalanceWithdrawal(msg.sender, amount);
    }

    function withdrawToken(address _address) external onlyAdmin {
        IERC20 token = IERC20(_address);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(payee, amount);
    }

    fallback() external payable {}

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }
}