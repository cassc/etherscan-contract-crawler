// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "ERC20.sol";
import "IXFETH.sol";
import "IBorrower.sol";

/**
 * @title The xfETH contract
 * @author Xfai
 * @notice The xfETH token is a flash mintable wrapped token that can accumulate fees over time through flash mintable arbitrage
 */
contract XFETH is ERC20, IXFETH {
  /**
   * @notice The owner of the xfETH contract
   */
  address public override owner;

  /**
   * @notice The initial arbitrageur of the xfETH contract.
   * @dev Only used while isPublic is false.
   */
  address private arbitrageur;

  /**
   * @notice The fee applied on flash mints
   */
  uint public override flashMintFee;

  /**
   * @notice Used to prevet reentrancy attacks
   */
  uint private constant _NOT_ENTERED = 1;

  /**
   * @notice Used to prevet reentrancy attacks
   */
  uint private constant _ENTERED = 2;

  /**
   * @notice Used to prevet reentrancy attacks
   */
  uint private _status;

  /**
   * @notice If true, anyone can perform flash minting
   */
  bool private _isPublic;

  modifier nonReentrant() {
    require(_status != _ENTERED, 'xfETH: reentrant call');
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
  }

  modifier nonReentrantRead() {
    require(_status != _ENTERED, 'xfETH: reentrant call');
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, 'xfETH: NOT_OWNER');
    _;
  }

  modifier isPublic() {
    if (_isPublic == false) {
      require(msg.sender == arbitrageur, 'xfETH: NOT_ARBITRAGEUR');
    }
    _;
  }

  /**
   * @notice Some dust eth needs to be permanently locked to prevent potential zero divisions
   */
  constructor(address _owner, uint _flashMintFee) payable ERC20() {
    _mint(address(0), msg.value);
    owner = _owner;
    flashMintFee = _flashMintFee;
    _status = _NOT_ENTERED;
    _name = 'Xfai ETH';
    _symbol = 'XFETH';
  }

  receive() external payable {
    deposit();
  }

  /**
   * @notice Changes the isPublic status of xfETH.
   * @dev setStatus can only be called by the owner of the contract
   * @param _state The new state of the xfETH isPublic modifier
   */
  function setStatus(bool _state) external override nonReentrant onlyOwner {
    _isPublic = _state;
    emit StatusChange(_state);
  }

  /**
   * @notice Changes the arbitrageur of xfETH contract
   * @dev setArbitrageur can only be called by the owner of the contract
   * @param _arbitrageur The new owner of the xfETH contract
   */
  function setArbitrageur(address _arbitrageur) external override nonReentrant onlyOwner {
    arbitrageur = _arbitrageur;
    emit ArbitrageurChange(_arbitrageur);
  }

  /**
   * @notice Changes the owner of xfETH contract
   * @dev setOwner can only be called by the owner of the contract
   * @param _newOwner The new owner of the xfETH contract
   */
  function setOwner(address _newOwner) external override nonReentrant onlyOwner {
    owner = _newOwner;
    emit OwnerChange(_newOwner);
  }

  /**
   * @notice Changes the fee percentage of xfETH for flash minting
   * @dev setFlashMintFee can only be called by the owner of the contract
   * @param _newFee The fee of the xfETH contract
   */
  function setFlashMintFee(uint _newFee) external override nonReentrant onlyOwner {
    flashMintFee = _newFee;
    emit FeeChange(_newFee);
  }

  /**
   * @notice Returns the exchange value of _xfETHAmount in terms of ETH
   * @param _xfETHAmount The amount of xfETH
   * @return _ETH The exchange value of _xfETHAmount in terms of ETH
   */
  function xfETHToETH(uint _xfETHAmount) public view override nonReentrantRead returns (uint _ETH) {
    _ETH = _xfETHToETH(_xfETHAmount);
  }

  /**
   * @notice Returns the exchange value of _ETHAmount in terms of xfETH
   * @param _ETHAmount The amount of ETH
   * @return _xfETH The exchange value of _ETHAmount in terms of xfETH
   */
  function ETHToXfETH(uint _ETHAmount) public view override nonReentrantRead returns (uint _xfETH) {
    _xfETH = (_ETHAmount * totalSupply()) / address(this).balance;
  }

  /**
   * @notice Accepts as input ETH and returns a given amount of xfETH
   * @dev deposit is a payable function
   * @return amountInXfETH The amount of xfETH received through the deposit
   */
  function deposit() public payable override nonReentrant returns (uint amountInXfETH) {
    amountInXfETH = (msg.value * totalSupply()) / (address(this).balance - msg.value);
    _mint(msg.sender, amountInXfETH);
    emit Deposit(msg.sender, amountInXfETH, msg.value);
  }

  /**
   * @notice Accepts as input xfETH and returns a given amount of ETH
   * @return amountInETH The amount of ETH received through the withdraw
   */
  function withdraw(uint _xfETHAmount) public override nonReentrant returns (uint amountInETH) {
    amountInETH = _xfETHToETH(_xfETHAmount);
    _burn(msg.sender, _xfETHAmount);
    payable(msg.sender).transfer(amountInETH);
    emit Withdrawal(msg.sender, amountInETH);
  }

  /**
   * @notice Allows anyone to mint the token as long as the same amount + a fee get burned by the end of the transaction.
   * @param _amount The amount of xfETH to be flash minted
   */
  function flashMint(uint _amount) external override nonReentrant isPublic {
    // get current ETH balance
    uint ETHBalance = address(this).balance;
    uint xfETHTotalSupply = totalSupply();

    // compute fee
    uint fee = (_amount * flashMintFee) / 10000;

    // mint tokens
    _mint(msg.sender, _amount);

    // hand control to borrower
    IBorrower(msg.sender).executeOnFlashMint(_amount);

    // burn tokens + fee
    _burn(msg.sender, _amount + fee); // reverts if `msg.sender` does not have enough tokens to burn

    // double-check that the contract's ETH balance has not decreased
    assert(address(this).balance >= ETHBalance);

    // double-check that the contract's xfETH supply has decreased
    assert(totalSupply() < xfETHTotalSupply);

    emit FlashMint(msg.sender, _amount);
  }

  function _xfETHToETH(uint _xfETHAmount) private view returns (uint amountInETH) {
    uint balance = address(this).balance;
    amountInETH = (_xfETHAmount * balance) / totalSupply();
  }
}