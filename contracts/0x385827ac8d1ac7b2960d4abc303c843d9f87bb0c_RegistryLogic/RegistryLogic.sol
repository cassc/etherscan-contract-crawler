/**
 *Submitted for verification at Etherscan.io on 2019-11-14
*/

/**
 *Submitted for verification at Etherscan.io on 2019-11-13
*/

// File: contracts/common/Validating.sol

pragma solidity 0.5.12;


interface Validating {
  modifier notZero(uint number) { require(number > 0, "invalid 0 value"); _; }
  modifier notEmpty(string memory text) { require(bytes(text).length > 0, "invalid empty string"); _; }
  modifier validAddress(address value) { require(value != address(0x0), "invalid address"); _; }
}

// File: contracts/gluon/AppGovernance.sol

pragma solidity 0.5.12;


interface AppGovernance {
  function approve(uint32 id) external;
  function disapprove(uint32 id) external;
  function activate(uint32 id) external;
}

// File: contracts/gluon/AppLogic.sol

pragma solidity 0.5.12;


interface AppLogic {
  function upgrade() external;
  function credit(address account, address asset, uint quantity) external;
  function debit(address account, bytes calldata parameters) external returns (address asset, uint quantity);
}

// File: contracts/gluon/AppState.sol

pragma solidity 0.5.12;


contract AppState {

  enum State { OFF, ON, RETIRED }
  State public state = State.ON;
  event Off();
  event Retired();

  modifier whenOn() { require(state == State.ON, "must be on"); _; }
  modifier whenOff() { require(state == State.OFF, "must be off"); _; }
  modifier whenRetired() { require(state == State.RETIRED, "must be retired"); _; }

  function retire_() internal whenOn {
    state = State.RETIRED;
    emit Retired();
  }

  function switchOff_() internal whenOn {
    state = State.OFF;
    emit Off();
  }

  function isOn() external view returns (bool) { return state == State.ON; }
}

// File: contracts/gluon/GluonView.sol

pragma solidity 0.5.12;


interface GluonView {
  function app(uint32 id) external view returns (address current, address proposal, uint activationBlock);
  function current(uint32 id) external view returns (address);
  function history(uint32 id) external view returns (address[] memory);
  function getBalance(uint32 id, address asset) external view returns (uint);
  function isAnyLogic(uint32 id, address logic) external view returns (bool);
  function isAppOwner(uint32 id, address appOwner) external view returns (bool);
  function proposals(address logic) external view returns (bool);
  function totalAppsCount() external view returns(uint32);
}

// File: contracts/gluon/GluonCentric.sol

pragma solidity 0.5.12;



contract GluonCentric {
  uint32 internal constant REGISTRY_INDEX = 0;
  uint32 internal constant STAKE_INDEX = 1;

  uint32 public id;
  address public gluon;

  constructor(uint32 id_, address gluon_) public {
    id = id_;
    gluon = gluon_;
  }

  modifier onlyCurrentLogic { require(currentLogic() == msg.sender, "invalid sender; must be current logic contract"); _; }
  modifier onlyGluon { require(gluon == msg.sender, "invalid sender; must be gluon contract"); _; }
  modifier onlyOwner { require(GluonView(gluon).isAppOwner(id, msg.sender), "invalid sender; must be app owner"); _; }

  function currentLogic() public view returns (address) { return GluonView(gluon).current(id); }
}

// File: contracts/apps/registry/RegistryData.sol

pragma solidity 0.5.12;



contract RegistryData is GluonCentric {

  mapping(address => address) public accounts;

  constructor(address gluon) GluonCentric(REGISTRY_INDEX, gluon) public { }

  function addKey(address apiKey, address account) external onlyCurrentLogic {
    accounts[apiKey] = account;
  }

}

// File: contracts/gluon/Upgrading.sol

pragma solidity 0.5.12;




contract Upgrading {
  address public upgradeOperator;

  modifier onlyOwner { require(false, "modifier onlyOwner must be implemented"); _; }
  modifier onlyUpgradeOperator { require(upgradeOperator == msg.sender, "invalid sender; must be upgrade operator"); _; }
  function setUpgradeOperator(address upgradeOperator_) external onlyOwner { upgradeOperator = upgradeOperator_; }
  function upgrade_(AppGovernance appGovernance, uint32 id) internal {
    appGovernance.activate(id);
    delete upgradeOperator;
  }
}

// File: contracts/apps/registry/RegistryLogic.sol

pragma solidity 0.5.12;









contract RegistryLogic is Upgrading, Validating, AppLogic, AppState, GluonCentric {

  RegistryData public data;
  OldRegistry public old;

  event Registered(address apiKey, address indexed account);

  constructor(address gluon, address old_, address data_) GluonCentric(REGISTRY_INDEX, gluon) public {
    data = RegistryData(data_);
    old = OldRegistry(old_);
  }

  modifier isAbsent(address apiKey) { require(translate(apiKey) == address (0x0), "api key already in use"); _; }

  function register(address apiKey) external whenOn validAddress(apiKey) isAbsent(apiKey) {
    data.addKey(apiKey, msg.sender);
    emit Registered(apiKey, msg.sender);
  }

  function translate(address apiKey) public view returns (address) {
    address account = data.accounts(apiKey);
    if (account == address(0x0)) account = old.translate(apiKey);
    return account;
  }

  /**************************************************** AppLogic ****************************************************/

  function upgrade() external onlyUpgradeOperator {
    retire_();
    upgrade_(AppGovernance(gluon), id);
  }

  function credit(address, address, uint) external { revert("not supported"); }

  function debit(address, bytes calldata) external returns (address, uint) { revert("not supported"); }

  function switchOff() external onlyOwner {
    uint32 totalAppsCount = GluonView(gluon).totalAppsCount();
    for (uint32 i = 2; i < totalAppsCount; i++) {
      AppState appState = AppState(GluonView(gluon).current(i));
      require(!appState.isOn(), "One of the apps is still ON");
    }
    switchOff_();
  }
}


contract OldRegistry {
  function translate(address) public view returns (address);
}