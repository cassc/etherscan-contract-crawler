// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IStakingContract.sol";

contract StakeToken is ERC20, Ownable {
  using SafeMath for uint256;

  mapping (address => bool) private _isMinter;
  bool private _isInitialized;
  IStakingContract private _stakingContract;

  modifier onlyMinter {
    require(_isMinter[msg.sender]);
    _;
  }

  /**
  * @param name: ERC20 name of the token
  * @param symbol: ERC20 symbol (ticker) of the token
  */
  constructor(
    string memory name,
    string memory symbol
  )
  ERC20(name, symbol)
  {
    _setupDecimals(8);
  }

  /**
  * Sets up minters and initializes the link to the staking contract
  *
  * @param minterAddresses: list of addresses to receive minter roles
  * @param stakingContract: address of the staking contract, needs to support IStakingContract
  */
  function init(
    address[] calldata minterAddresses,
    address stakingContract
  )
  external
  onlyOwner
  {
    require(stakingContract != address(0), "Staking contract cannot be zero address");
    require(!_isInitialized, "Minters are already set");
    require(minterAddresses.length > 0, "Trying to initialize with no minters");
    for (uint8 i=0; i<minterAddresses.length; i++) {
      require(minterAddresses[i]  != address(0), "StakeToken: Trying to init with a zero address minter");
      _isMinter[minterAddresses[i]] = true;
    }
    _stakingContract = IStakingContract(stakingContract);
    _isInitialized = true;
  }

  /**
  * Minting wrapper for the privileged role
  */
  function mint(address account, uint256 amount) public onlyMinter {
    require(account != address(0), "StakeToken: Trying to mint to zero address");
    require(amount > 0, "StakeToken: Trying to mint zero tokens");
    _mint(account, amount);
  }

  /**
  * Total supply that includes "virtual" tokens which will be minted by staking, to date
  */
  function totalSupplyVirtual() public view returns (uint256) {
    return totalSupply().add(_stakingContract.totalUnmintedInterest());
  }
}