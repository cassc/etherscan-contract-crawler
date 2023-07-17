// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '../interfaces/IJBDirectory.sol';
import '../libraries/JBTokens.sol';

/**
 * @title MixedPaymentSplitter
 *
 * @notice Allows payments to be distributed to addresses or JBX projects with appropriately configured terminals.
 *
 * @dev based on OpenZeppelin finance/PaymentSplitter.sol v4.7.0
 */
contract MixedPaymentSplitter is Ownable {
  //*********************************************************************//
  // --------------------------- custom events ------------------------- //
  //*********************************************************************//

  event PayeeAdded(address account, uint256 shares);
  event ProjectAdded(uint256 project, uint256 shares);
  event PaymentReleased(address account, uint256 amount);
  event ProjectPaymentReleased(uint256 projectId, uint256 amount);
  event TokenPaymentReleased(IERC20 indexed token, address account, uint256 amount);
  event TokenProjectPaymentReleased(IERC20 indexed token, uint256 projectId, uint256 amount);
  event PaymentReceived(address from, uint256 amount);

  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//

  error INVALID_LENGTH();
  error INVALID_DIRECTORY();
  error MISSING_PROJECT_TERMINAL();
  error INVALID_PAYEE();
  error INVALID_SHARE();
  error PAYMENT_FAILURE();
  error NO_SHARE();
  error NOTHING_DUE();
  error INVALID_SHARE_TOTAL();

  //*********************************************************************//
  // --------------------- public stored properties -------------------- //
  //*********************************************************************//

  /**
   * @dev Total number of shares available.
   */
  uint256 public constant SHARE_WHOLE = 1_000_000;

  /**
   * @dev Total number of shares already assigned to payees.
   */
  uint256 public assignedShares;

  /**
   * @dev Map of shares belonging to addresses, wether EOA or contracts. The map key is encoded such that bottom 160 bits are an address and top 96 bits are a JBX project id.
   */
  mapping(uint256 => uint256) private shares;

  /**
   * @dev Total amount of Ether paid out.
   */
  uint256 public totalReleased;

  /**
   * @dev Map of released Ether payments. The key is encoded such that bottom 160 bits are an address and top 96 bits are a JBX project id.
   */
  mapping(uint256 => uint256) public released;

  /**
   * @dev Total amount of token balances paid out.
   */
  mapping(IERC20 => uint256) public _erc20TotalReleased;

  /**
   * @dev Map of released token payments. The key is encoded such that bottom 160 bits are an address and top 96 bits are a JBX project id.
   */
  mapping(IERC20 => mapping(uint256 => uint256)) public _erc20Released;

  IJBDirectory jbxDirectory;
  string public name;

  //*********************************************************************//
  // -------------------------- constructor ---------------------------- //
  //*********************************************************************//

  /**
   * @dev It's possible to deploy this contract with partial subscription and then call addPayee to bring it to full 100%.
   *
   * @param _name Name for this split configuration.
   * @param _payees Payable addresses to send payment portion to.
   * @param _projects Juicebox project ids to send payment portion to.
   * @param _shares Share assignment in the same order as payees and projects parameters. Share total is 1_000_000.
   * @param _jbxDirectory Juicebox directory contract
   * @param _owner Admin of the contract.
   */
  constructor(
    string memory _name,
    address[] memory _payees,
    uint256[] memory _projects,
    uint256[] memory _shares,
    IJBDirectory _jbxDirectory,
    address _owner
  ) {
    if (_payees.length == 0 && _projects.length == 0) {
      revert INVALID_LENGTH();
    }

    if (_shares.length == 0) {
      revert INVALID_LENGTH();
    }

    if (_payees.length + _projects.length != _shares.length) {
      revert INVALID_LENGTH();
    }

    if (_projects.length != 0 && address(_jbxDirectory) == address(0)) {
      revert INVALID_DIRECTORY();
    }

    jbxDirectory = _jbxDirectory;
    name = _name;

    for (uint256 i; i != _payees.length; ) {
      _addPayee(_payees[i], _shares[i]);
      ++i;
    }

    for (uint256 i; i != _projects.length; ) {
      _addProject(_projects[i], _shares[_payees.length + i]);
      ++i;
    }

    _transferOwnership(_owner);
  }

  //*********************************************************************//
  // ------------------------- external views -------------------------- //
  //*********************************************************************//

  receive() external payable virtual {
    emit PaymentReceived(msg.sender, msg.value);
  }

  /**
   * @notice Returns pending Ether payment for a given address.
   */
  function pending(address _account) public view returns (uint256) {
    uint256 totalReceived = address(this).balance + totalReleased;
    return
      _pendingPayment(
        uint256(uint160(_account)),
        totalReceived,
        released[uint256(uint160(_account))]
      );
  }

  /**
   * @notice Returns pending Ether payment for a given JBX project.
   */
  function pending(uint256 _projectId) public view returns (uint256) {
    uint256 totalReceived = address(this).balance + totalReleased;
    return _pendingPayment(_projectId << 160, totalReceived, released[_projectId << 160]);
  }

  /**
   * @notice Returns pending payment for a given address in a given token.
   */
  function pending(IERC20 _token, address _account) public view returns (uint256) {
    uint256 totalReceived = _token.balanceOf(address(this)) + _erc20TotalReleased[_token];
    return
      _pendingPayment(
        uint256(uint160(_account)),
        totalReceived,
        _erc20Released[_token][uint256(uint160(_account))]
      );
  }

  /**
   * @notice Returns pending payment for a given JBX project in a given token
   */
  function pending(IERC20 _token, uint256 _projectId) public view returns (uint256) {
    uint256 totalReceived = _token.balanceOf(address(this)) + _erc20TotalReleased[_token];
    return
      _pendingPayment(_projectId << 160, totalReceived, _erc20Released[_token][_projectId << 160]);
  }

  //*********************************************************************//
  // ---------------------- external transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice A trustless function to distribute a pending Ether payment to a given address. Will revert for various reasons like address not having a share or having no pending payment.
   */
  function distribute(address payable _account) external virtual {
    if (shares[uint256(uint160(address(_account)))] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_account);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      totalReleased += payment;
      released[uint256(uint160(address(_account)))] += payment;
    }

    Address.sendValue(_account, payment);
    emit PaymentReleased(_account, payment);
  }

  /**
   * @notice A trustless function to distribute a pending Ether payment to a JBX project. Will revert for various reasons like project not having a share or having no pending payment or a registered Ether terminal.
   */
  function distribute(uint256 _projectId) public virtual {
    uint256 key = _projectId << 160;
    if (shares[key] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_projectId);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      totalReleased += payment;
      released[key] += payment;
    }

    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH);
    if (address(terminal) == address(0)) {
      revert PAYMENT_FAILURE();
    }

    terminal.addToBalanceOf{value: payment}(
      _projectId,
      payment,
      JBTokens.ETH,
      string(abi.encodePacked(name, ' split payment')),
      ''
    );
    emit ProjectPaymentReleased(_projectId, payment);
  }

  /**
   * @notice A trustless function to distribute a pending token payment to a given address. Will revert for various reasons like address not having a share or having no pending payment.
   */
  function distribute(IERC20 _token, address _account) public virtual {
    if (shares[uint256(uint160(_account))] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_token, _account);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      _erc20TotalReleased[_token] += payment;
      _erc20Released[_token][uint256(uint160(_account))] += payment;
    }

    bool sent = IERC20(_token).transfer(_account, payment);
    if (!sent) {
      revert PAYMENT_FAILURE();
    }
    emit TokenPaymentReleased(_token, _account, payment);
  }

  /**
   * @notice A trustless function to distribute a pending token payment to a JBX project. Will revert for various reasons like project not having a share or having no pending payment or a registered token terminal.
   */
  function distribute(IERC20 _token, uint256 _projectId) public virtual {
    uint256 key = _projectId << 160;
    if (shares[key] == 0) {
      revert NO_SHARE();
    }

    uint256 payment = pending(_token, _projectId);
    if (payment == 0) {
      revert NOTHING_DUE();
    }

    unchecked {
      _erc20TotalReleased[_token] += payment;
      _erc20Released[_token][key] += payment;
    }

    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_projectId, address(_token));
    if (address(terminal) == address(0)) {
      revert PAYMENT_FAILURE();
    }

    _token.approve(address(terminal), payment);
    terminal.addToBalanceOf(
      _projectId,
      payment,
      JBTokens.ETH,
      string(abi.encodePacked(name, ' split payment')),
      ''
    );
    emit TokenProjectPaymentReleased(_token, _projectId, payment);
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  function addPayee(address _account, uint256 _shares) external onlyOwner {
    _addPayee(_account, _shares);
  }

  function addPayee(uint256 _projectId, uint256 _shares) external onlyOwner {
    _addProject(_projectId, _shares);
  }

  function withdraw() external onlyOwner {
    // TODO
  }

  //*********************************************************************//
  // ---------------------- private transactions ----------------------- //
  //*********************************************************************//

  function _pendingPayment(
    uint256 _key,
    uint256 _totalReceived,
    uint256 _alreadyReleased
  ) private view returns (uint256) {
    return ((_totalReceived * shares[_key]) / SHARE_WHOLE) - _alreadyReleased;
  }

  function _addPayee(address _account, uint256 _shares) private {
    if (_account == address(0)) {
      revert INVALID_PAYEE();
    }

    if (_shares == 0) {
      revert INVALID_SHARE();
    }

    uint256 k = uint256(uint160(_account));

    shares[k] = _shares;
    assignedShares += _shares;

    if (assignedShares > SHARE_WHOLE) {
      revert INVALID_SHARE_TOTAL();
    }

    emit PayeeAdded(_account, _shares);
  }

  function _addProject(uint256 _projectId, uint256 _shares) private {
    if (_projectId > type(uint96).max || _projectId == 0) {
      revert INVALID_PAYEE();
    }

    if (address(jbxDirectory.primaryTerminalOf(_projectId, JBTokens.ETH)) == address(0)) {
      revert MISSING_PROJECT_TERMINAL();
    }

    if (_shares == 0) {
      revert INVALID_SHARE();
    }

    uint256 k = _projectId << 160;

    shares[k] += _shares;
    assignedShares += _shares;

    if (assignedShares > SHARE_WHOLE) {
      revert INVALID_SHARE_TOTAL();
    }

    emit ProjectAdded(_projectId, _shares);
  }
}