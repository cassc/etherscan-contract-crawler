/*
    Copyright (c) 2019 Mt Pelerin Group Ltd

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License version 3
    as published by the Free Software Foundation with the addition of the
    following permission added to Section 15 as permitted in Section 7(a):
    FOR ANY PART OF THE COVERED WORK IN WHICH THE COPYRIGHT IS OWNED BY
    MT PELERIN GROUP LTD. MT PELERIN GROUP LTD DISCLAIMS THE WARRANTY OF NON INFRINGEMENT
    OF THIRD PARTY RIGHTS

    This program is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.
    You should have received a copy of the GNU Affero General Public License
    along with this program; if not, see http://www.gnu.org/licenses or write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA, 02110-1301 USA, or download the license from the following URL:
    https://www.gnu.org/licenses/agpl-3.0.fr.html

    The interactive user interfaces in modified source and object code versions
    of this program must display Appropriate Legal Notices, as required under
    Section 5 of the GNU Affero General Public License.

    You can be released from the requirements of the license by purchasing
    a commercial license. Buying such a license is mandatory as soon as you
    develop commercial activities involving Mt Pelerin Group Ltd software without
    disclosing the source code of your own applications.
    These activities include: offering paid services based/using this product to customers,
    using this product in any application, distributing this product with a closed
    source product.

    For more information, please contact Mt Pelerin Group Ltd at this
    address: [email protected]
*/

pragma solidity 0.6.2;

import "@openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../../access/Roles.sol";
import "../../interfaces/IERC20Detailed.sol";
import "../../interfaces/IAdministrable.sol";
import "../../interfaces/IGovernable.sol";
import "../../interfaces/IPriceable.sol";
import "../../interfaces/IProcessor.sol";
import "../../interfaces/IPriceOracle.sol";

/**
 * @title BridgeERC20
 * @dev BridgeERC20 contract
 *
 * Error messages
 * PR01: Processor is not set
 * AD01: Caller is not administrator
 * AL01: Spender is not allowed for this amount
 * PO03: Price Oracle not set
 * KI01: Caller of setRealm has to be owner or administrator of initial token address for realm
**/


contract BridgeERC20 is Initializable, OwnableUpgradeSafe, IAdministrable, IGovernable, IPriceable, IERC20Detailed {
  using Roles for Roles.Role;
  using SafeMath for uint256;

  event ProcessorChanged(address indexed newProcessor);

  IProcessor internal _processor;
  Roles.Role internal _administrators;
  Roles.Role internal _realmAdministrators;
  address[] internal _trustedIntermediaries;
  address internal _realm;
  IPriceOracle internal _priceOracle;

  /** 
  * @dev Initialization function that replaces constructor in the case of upgradable contracts
  **/
  function initialize(address owner, IProcessor newProcessor) public virtual initializer {
    __Ownable_init();
    transferOwnership(owner);
    _processor = newProcessor;
    _realm = address(this);
    emit ProcessorChanged(address(newProcessor));
    emit RealmChanged(address(this));
  }

  modifier hasProcessor() {
    require(address(_processor) != address(0), "PR01");
    _;
  }

  modifier onlyAdministrator() {
    require(owner() == _msgSender() || isAdministrator(_msgSender()), "AD01");
    _;
  }

  /* Administrable */
  function isAdministrator(address _administrator) public override view returns (bool) {
    return _administrators.has(_administrator);
  }

  function addAdministrator(address _administrator) public override onlyOwner {
    _administrators.add(_administrator);
    emit AdministratorAdded(_administrator);
  }

  function removeAdministrator(address _administrator) public override onlyOwner {
    _administrators.remove(_administrator);
    emit AdministratorRemoved(_administrator);
  }

  /* Governable */
  function realm() public override view returns (address) {
    return _realm;
  }

  function setRealm(address newRealm) public override onlyAdministrator {
    BridgeERC20 king = BridgeERC20(newRealm);
    require(king.owner() == _msgSender() || king.isRealmAdministrator(_msgSender()), "KI01");
    _realm = newRealm;
    emit RealmChanged(newRealm);
  }

  function trustedIntermediaries() public override view returns (address[] memory) {
    return _trustedIntermediaries;
  }

  function setTrustedIntermediaries(address[] calldata newTrustedIntermediaries) external override onlyAdministrator {
    _trustedIntermediaries = newTrustedIntermediaries;
    emit TrustedIntermediariesChanged(newTrustedIntermediaries);
  }

  function isRealmAdministrator(address _administrator) public override view returns (bool) {
    return _realmAdministrators.has(_administrator);
  }

  function addRealmAdministrator(address _administrator) public override onlyAdministrator {
    _realmAdministrators.add(_administrator);
    emit RealmAdministratorAdded(_administrator);
  }

  function removeRealmAdministrator(address _administrator) public override onlyAdministrator {
    _realmAdministrators.remove(_administrator);
    emit RealmAdministratorRemoved(_administrator);
  }

  /* Priceable */
  function priceOracle() public override view returns (IPriceOracle) {
    return _priceOracle;
  }

  function setPriceOracle(IPriceOracle newPriceOracle) public override onlyAdministrator {
    _priceOracle = newPriceOracle;
    emit PriceOracleChanged(address(newPriceOracle));
  }

  function convertTo(
    uint256 _amount, string calldata _currency, uint8 maxDecimals
  ) 
    external override hasProcessor view returns(uint256) 
  {
    require(address(_priceOracle) != address(0), "PO03");
    uint256 amountToConvert = _amount;
    uint256 xrate;
    uint8 xrateDecimals;
    uint8 tokenDecimals = _processor.decimals();
    (xrate, xrateDecimals) = _priceOracle.getPrice(_processor.symbol(), _currency);
    if (xrateDecimals > maxDecimals) {
      xrate = xrate.div(10**uint256(xrateDecimals - maxDecimals));
      xrateDecimals = maxDecimals;
    }
    if (tokenDecimals > maxDecimals) {
      amountToConvert = amountToConvert.div(10**uint256(tokenDecimals - maxDecimals));
      tokenDecimals = maxDecimals;
    }
    /* Multiply amount in token decimals by xrate in xrate decimals */
    return amountToConvert.mul(xrate).mul(10**uint256((2*maxDecimals)-xrateDecimals-tokenDecimals));
  }

  /**
  * @dev Set the token processor
  **/
  function setProcessor(IProcessor newProcessor) public onlyAdministrator {
    _processor = newProcessor;
    emit ProcessorChanged(address(newProcessor));
  }

  /**
  * @return the token processor
  **/
  function processor() public view returns (IProcessor) {
    return _processor;
  }

  /**
  * @return the name of the token.
  */
  function name() public override view hasProcessor returns (string memory) {
    return _processor.name();
  }

  /**
  * @return the symbol of the token.
  */
  function symbol() public override view hasProcessor returns (string memory) {
    return _processor.symbol();
  }

  /**
  * @return the number of decimals of the token.
  */
  function decimals() public override view hasProcessor returns (uint8) {
    return _processor.decimals();
  }

  /**
  * @return total number of tokens in existence
  */
  function totalSupply() public override view hasProcessor returns (uint256) {
    return _processor.totalSupply();
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  * @return true if transfer is successful, false otherwise
  */
  function transfer(address _to, uint256 _value) public override hasProcessor 
    returns (bool) 
  {
    bool success;
    address updatedTo;
    uint256 updatedAmount;
    (success, updatedTo, updatedAmount) = _transferFrom(
      _msgSender(), 
      _to, 
      _value
    );
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public override view hasProcessor 
    returns (uint256) 
  {
    return _processor.balanceOf(_owner);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * @return true if transfer is successful, false otherwise
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    override
    hasProcessor
    returns (bool)
  {
    require(_value <= _processor.allowance(_from, _msgSender()), "AL01"); 
    bool success;
    address updatedTo;
    uint256 updatedAmount;
    (success, updatedTo, updatedAmount) = _transferFrom(
      _from, 
      _to, 
      _value
    );
    _processor.decreaseApproval(_from, _msgSender(), updatedAmount);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @return true if approval is successful, false otherwise
   */
  function approve(address _spender, uint256 _value) public override hasProcessor returns (bool)
  {
    _approve(_msgSender(), _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    override
    view
    hasProcessor
    returns (uint256)
  {
    return _processor.allowance(_owner, _spender);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    hasProcessor
  {
    _increaseApproval(_msgSender(), _spender, _addedValue);
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    hasProcessor
  {
    _decreaseApproval(_msgSender(), _spender, _subtractedValue);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * @return _success True if the transfer is successful, false otherwise
   * @return _updatedTo The real address the tokens were sent to
   * @return _updatedAmount The real amount of tokens sent
   */
  function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool _success, address _updatedTo, uint256 _updatedAmount) {
    (_success, _updatedTo, _updatedAmount) = _processor.transferFrom(
      _from, 
      _to, 
      _value
    );
    emit Transfer(_from, _updatedTo, _updatedAmount);
    return (_success, _updatedTo, _updatedAmount);
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of _msgSender().
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _owner The owner address of the funds to spend
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function _approve(address _owner, address _spender, uint256 _value) internal {
    _processor.approve(_owner, _spender, _value);
    emit Approval(_owner, _spender, _value);
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * @param _owner The address which has the funds
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function _increaseApproval(address _owner, address _spender, uint _addedValue) internal {
    _processor.increaseApproval(_owner, _spender, _addedValue);
    uint256 allowed = _processor.allowance(_owner, _spender);
    emit Approval(_owner, _spender, allowed);
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * @param _owner The address which has the funds
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function _decreaseApproval(address _owner, address _spender, uint _subtractedValue) internal {
    _processor.decreaseApproval(_owner, _spender, _subtractedValue);
    uint256 allowed = _processor.allowance(_owner, _spender);
    emit Approval(_owner, _spender, allowed);
  }

  /* Reserved slots for future use: https://docs.openzeppelin.com/sdk/2.5/writing-contracts.html#modifying-your-contracts */
  uint256[50] private ______gap;
}