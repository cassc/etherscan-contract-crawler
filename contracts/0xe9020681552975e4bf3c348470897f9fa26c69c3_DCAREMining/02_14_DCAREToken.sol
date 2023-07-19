// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../common/token/ITokenRecipient.sol";
import "../common/interfaces/ICommittee.sol";

contract DCAREToken is ERC20, AccessControl, Ownable {
  using SafeMath for uint256;

  address public INITIAL_FC_VOTING_CONTRACT_ADDRESS;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  uint256 public constant MAXIMUM_SUPPLY = 3500000;

  uint256[7] public INITIAL_SUPPLY = [105000, 50000, 35000, 25000, 10000, 10000, 10000];

  address[] public admins;
  address[] public minters;

  constructor(address fcVotingContractAddress) ERC20("DCARE Token", "DCARE") {
    INITIAL_FC_VOTING_CONTRACT_ADDRESS = fcVotingContractAddress;

    _setupDecimals(6);

    _setupRole(DEFAULT_ADMIN_ROLE, INITIAL_FC_VOTING_CONTRACT_ADDRESS);
    admins.push(INITIAL_FC_VOTING_CONTRACT_ADDRESS);

    _mintInitialSupply();
  }

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an Admin");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a Minter");
    _;
  }

  function grantAdminRole(address _adminAddress) public onlyAdmin {
    _setupRole(DEFAULT_ADMIN_ROLE, _adminAddress);

    admins.push(_adminAddress);
  }

  function revokeAdminRole(address _adminAddress) public onlyAdmin {
    revokeRole(DEFAULT_ADMIN_ROLE, _adminAddress);

    for (uint256 i = 0; i < admins.length; i++) {
      if (i >= admins.length) {
        break;
      }

      if (admins[i] == _adminAddress) {
        if (i != admins.length - 1) {
          admins[i] = admins[admins.length - 1];
        }
        admins.pop();
      }
    }
  }

  function grantMinterRole(address _minterAddress) public onlyAdmin {
    _setupRole(MINTER_ROLE, _minterAddress);

    minters.push(_minterAddress);
  }

  function revokeMinterRole(address _minterAddress) public onlyAdmin {
    revokeRole(MINTER_ROLE, _minterAddress);

    for (uint256 i = 0; i < minters.length; i++) {
      if (i >= minters.length) {
        break;
      }

      if (minters[i] == _minterAddress) {
        if (i != minters.length - 1) {
          minters[i] = minters[minters.length - 1];
        }
        minters.pop();
      }
    }
  }

  function mint(address _receiver, uint256 _amount) public onlyMinter {
    require(
      totalSupply().add(_amount) <= MAXIMUM_SUPPLY.mul(10 ** decimals()),
      "The limit of the maximum allowable emission of tokens has been exceeded"
    );

    _mint(_receiver, _amount);
  }

  function _mintInitialSupply() private {
    ICommittee committeeContract = ICommittee(INITIAL_FC_VOTING_CONTRACT_ADDRESS);

    address committee;
    for (uint8 i = 0; i < 7; i++) {
      committee = committeeContract.committee(i);
      _mint(committee, INITIAL_SUPPLY[i].mul(10 ** decimals()));
    }
  }

  /**
    * @dev Transfer the specified amount of tokens to the specified address.
    *      Invokes the `tokenFallback` function if the recipient is a contract.
    *      The token transfer fails if the recipient is a contract
    *      but does not implement the `tokenFallback` function
    *      or the fallback function to receive funds.
    *
    * @param _to    Receiver address.
    * @param _value Amount of tokens that will be transferred.
    * @param _data  Transaction metadata.
    */
  function transfer(address _to, uint256 _value, bytes memory _data) public returns (bool success) {
    _transfer(_msgSender(), _to, _value);
    if (Address.isContract(_to)) {
      ITokenRecipient receiver = ITokenRecipient(_to);
      bool result = receiver.tokenFallback(_msgSender(), _value, _data);
      if (!result) {
        revert("The recipient contract has no fallback function to receive tokens properly");
      }
    }

    return true;
  }

  /**
    * @dev Transfer the specified amount of tokens to the specified address.
    *      This function works the same with the previous one
    *      but doesn't contain `_data` param.
    *      Added due to backwards compatibility reasons.
    *
    * @param _to    Receiver address.
    * @param _value Amount of tokens that will be transferred.
    */
  function transfer(address _to, uint256 _value) public override returns (bool success) {
    _transfer(_msgSender(), _to, _value);
    if (Address.isContract(_to)) {
      ITokenRecipient receiver = ITokenRecipient(_to);
      bool result = receiver.tokenFallback(
        _msgSender(), _value, hex"00");
      if (!result) {
        revert("The recipient contract has no fallback function to receive tokens properly");
      }
    }

    return true;
  }

  function adminsNumber() public view returns (uint256) {
    return admins.length;
  }

  function mintersNumber() public view returns (uint256) {
    return minters.length;
  }

}