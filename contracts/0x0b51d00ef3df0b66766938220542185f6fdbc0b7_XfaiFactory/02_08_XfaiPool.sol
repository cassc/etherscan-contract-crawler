// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import "ERC20.sol";

import "IXfaiPool.sol";
import "IERC20.sol";
import "IXfaiFactory.sol";

/**
 * @title Xfai's Pool contract
 * @author Xfai
 * @notice XfaiPool is a contract that gets created by the xfaiFactory. Every hosted token has a unique pool that holds the state (i.e. pool token reserve, xfETH reserve, etc.) for the given token.
 */
contract XfaiPool is IXfaiPool, ERC20 {
  /**
   * @notice The pool reserve
   */
  uint private reserve;

  /**
   * @notice Pool weight
   * @dev weight is used to compute the exchange value of a token. It represents the balance of xfETH within the pool contract
   */
  uint private weight;

  uint private seeded = 1;

  IXfaiFactory private factory;

  /**
   * @notice The ERC20 token address of the pool's underlying token
   * @dev Not to be confused with the liquidity token address
   */
  address public override poolToken;

  modifier linked() {
    address core = getXfaiCore();
    require(msg.sender == core, 'XfaiPool: NOT_CORE');
    _;
  }

  /**
   * @notice Construct the XfaiPool
   * @dev The parameters of the pool are omitted in the construct and are instead specified via the initialize function
   */
  constructor() ERC20() {}

  /**
   * @notice Called once by the factory at time of deployment
   * @param _token The ERC20 token address of the pool
   * @param _xfaiFactory The xfai Factory of the pool
   */
  function initialize(address _token, address _xfaiFactory) external override {
    require(seeded == 1, 'XfaiPool: DEX_SEEDED');
    poolToken = _token;
    factory = IXfaiFactory(_xfaiFactory);
    _name = 'Xfai Liquidity Token';
    _symbol = 'XFAI-LP';
    seeded = 2;
  }

  /**
   * @notice Get the current Xfai Core contract address
   * @dev Only the Xfai Core contract can modify the state of the pool
   */
  function getXfaiCore() public view override returns (address) {
    return factory.getXfaiCore();
  }

  /**
   * @notice Get the current reserve and weight of the pool
   */
  function getStates() external view override returns (uint, uint) {
    return (reserve, weight);
  }

  /**
   * @notice Updates the reserve and weight.
   * @dev This function is linked. Only the latest Xfai Core contract can call it
   * @param _newReserve The latest token balance of the pool
   * @param _newWeight The latest xfETH balance of the pool
   */
  function update(uint _newReserve, uint _newWeight) external override linked {
    reserve = _newReserve;
    weight = _newWeight;
    emit Sync(_newReserve, _newWeight);
  }

  /**
   * @notice transfer the pool's poolToken or xfETH
   * @dev This function is linked. Only the latest Xfai Core contract can call it.
   * @param _token The ERC20 token address
   * @param _to The recipient of the tokens
   * @param _value The amount of tokens
   */
  function linkedTransfer(address _token, address _to, uint256 _value) external override linked {
    require(_token.code.length > 0, 'XfaiPool: TRANSFER_FAILED');
    (bool success, bytes memory data) = _token.call(
      abi.encodeWithSelector(IERC20.transfer.selector, _to, _value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'XfaiPool: TRANSFER_FAILED');
  }

  /**
   * @notice This function mints new ERC20 liquidity tokens
   * @dev This function is linked. Only the latest Xfai Core contract can call it
   * @param _to The recipient of the tokens
   * @param _amount The amount of tokens
   */
  function mint(address _to, uint _amount) public override linked {
    _mint(_to, _amount);
  }

  /**
   * @notice This function burns existing ERC20 liquidity tokens
   * @dev This function is linked. Only the latest Xfai Core contract can call it
   * @param _to The recipient whose tokens get burned
   * @param _amount The amount of tokens burned
   */
  function burn(address _to, uint _amount) public override linked {
    _burn(_to, _amount);
  }
}