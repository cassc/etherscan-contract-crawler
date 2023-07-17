/**
 *Submitted for verification at Etherscan.io on 2020-11-09
*/

// File: contracts/common/Validating.sol

pragma solidity 0.5.12;


interface Validating {
  modifier notZero(uint number) { require(number > 0, "invalid 0 value"); _; }
  modifier notEmpty(string memory text) { require(bytes(text).length > 0, "invalid empty string"); _; }
  modifier validAddress(address value) { require(value != address(0x0), "invalid address"); _; }
}

// File: contracts/common/HasOwners.sol

pragma solidity 0.5.12;



/// @notice providing an ownership access control mechanism
contract HasOwners is Validating {

  address[] public owners;
  mapping(address => bool) public isOwner;

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  /// @notice initializing the owners list (with at least one owner)
  constructor(address[] memory owners_) public {
    for (uint i = 0; i < owners_.length; i++) addOwner_(owners_[i]);
  }

  /// @notice requires the sender to be one of the contract owners
  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  /// @notice list all accounts with an owner access
  function getOwners() public view returns (address[] memory) { return owners; }

  /// @notice authorize an `account` with owner access
  function addOwner(address owner) external onlyOwner { addOwner_(owner); }

  function addOwner_(address owner) private validAddress(owner) {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }

  /// @notice revoke an `account` owner access (while ensuring at least one owner remains)
  function removeOwner(address owner) external onlyOwner {
    require(isOwner[owner], 'only owners can be removed');
    require(owners.length > 1, 'can not remove last owner');
    isOwner[owner] = false;
    for (uint i = 0; i < owners.length; i++) {
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        owners.pop();
        emit OwnerRemoved(owner);
        break;
      }
    }
  }

}

// File: contracts/common/Versioned.sol

pragma solidity 0.5.12;


contract Versioned {

  string public version;

  constructor(string memory version_) public { version = version_; }

}

// File: contracts/external/SafeMath.sol

pragma solidity 0.5.12;


/**
 * @title Math provides arithmetic functions for uint type pairs.
 * You can safely `plus`, `minus`, `times`, and `divide` uint numbers without fear of integer overflow.
 * You can also find the `min` and `max` of two numbers.
 */
library SafeMath {

  function min(uint x, uint y) internal pure returns (uint) { return x <= y ? x : y; }
  function max(uint x, uint y) internal pure returns (uint) { return x >= y ? x : y; }


  /** @dev adds two numbers, reverts on overflow */
  function plus(uint x, uint y) internal pure returns (uint z) { require((z = x + y) >= x, "bad addition"); }

  /** @dev subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend) */
  function minus(uint x, uint y) internal pure returns (uint z) { require((z = x - y) <= x, "bad subtraction"); }


  /** @dev multiplies two numbers, reverts on overflow */
  function times(uint x, uint y) internal pure returns (uint z) { require(y == 0 || (z = x * y) / y == x, "bad multiplication"); }

  /** @dev divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero */
  function mod(uint x, uint y) internal pure returns (uint z) {
    require(y != 0, "bad modulo; using 0 as divisor");
    z = x % y;
  }

  /** @dev Integer division of two numbers truncating the quotient, reverts on division by zero */
  function div(uint a, uint b) internal pure returns (uint c) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
  }

}

// File: contracts/gluon/AppLogic.sol

pragma solidity 0.5.12;


/**
  * @notice representing an app's in-and-out transfers of assets
  * @dev an account/asset based app should implement its own bookkeeping
  */
interface AppLogic {

  /// @notice when an app proposal has been activated, Gluon will call this method on the previously active app version
  /// @dev each app must implement, providing a future upgrade path, and call retire_() at the very end.
  /// this is the chance for the previously active app version to migrate to the new version
  /// i.e.: migrating data, deprecate prior behavior, releasing resources, etc.
  function upgrade() external;

  /// @dev once an asset has been deposited into the app's safe within Gluon, the app is given the chance to do
  /// it's own per account/asset bookkeeping
  ///
  /// @param account any Ethereum address
  /// @param asset any ERC20 token or ETH (represented by address 0x0)
  /// @param quantity quantity of asset
  function credit(address account, address asset, uint quantity) external;

  /// @dev before an asset can be withdrawn from the app's safe within Gluon, the quantity and asset to withdraw must be
  /// derived from `parameters`. if the app is account/asset based, it should take this opportunity to:
  /// - also derive the owning account from `parameters`
  /// - prove that the owning account indeed has the derived quantity of the derived asset
  /// - do it's own per account/asset bookkeeping
  /// notice that the derived account is not necessarily the same as the provided account; a classic usage example is
  /// an account transfers assets across app (in which case the provided account would be the target app)
  ///
  /// @param account any Ethereum address to which `quantity` of `asset` would be transferred to
  /// @param parameters a bytes-marshalled record containing all data needed for the app-specific logic
  /// @return asset any ERC20 token or ETH (represented by address 0x0)
  /// @return quantity quantity of asset
  function debit(address account, bytes calldata parameters) external returns (address asset, uint quantity);
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

// File: contracts/gluon/GluonWallet.sol

pragma solidity 0.5.12;


interface GluonWallet {
  function depositEther(uint32 id) external payable;
  function depositToken(uint32 id, address token, uint quantity) external;
  function withdraw(uint32 id, bytes calldata parameters) external;
  function transfer(uint32 from, uint32 to, bytes calldata parameters) external;
}

// File: contracts/gluon/LegacyTokensExtension.sol

pragma solidity 0.5.12;








/**
  * @title the Gluon-Plasma Extension contract for supporting deposit and withdraw for legacy tokens
  * - depositing an token into an app
  * - withdrawing an token from an app
  * - transferring an token across apps
  */
contract LegacyTokensExtension is Versioned, GluonWallet, HasOwners {
    using SafeMath for uint;

    address[] public tokens;
    mapping(address => bool) public isTokenAllowed;

    mapping(uint32 => mapping(address => uint)) public balances;
    mapping(address => uint) public tokenBalances;

    GluonView public gluon;

    event TokenAdded(address indexed token);
    event TokenRemoved(address indexed token);

    constructor(address _gluon, address[] memory tokens_, address[] memory owners, string memory version) Versioned(version) HasOwners(owners) public {
        gluon = GluonView(_gluon);
        for (uint i = 0; i < tokens_.length; i++) addToken_(tokens_[i]);
    }

    modifier provisioned(uint32 appId) {
        require(gluon.history(appId).length > 0, "App is not yet provisioned");
        _;
    }

    /**************************************************** GluonWallet ****************************************************/

    /// @notice deposit ETH token on behalf of the sender into an app's safe
    ///
    /// @param appId index of the target app
    function depositEther(uint32 appId) external payable provisioned(appId) {
        require(false, "prohibited operation; must use Gluon to deposit Ether");
    }

    /// @notice deposit ERC20 token token (represented by address 0x0) on behalf of the sender into an app's safe
    /// @dev an account must call token.approve(logic, quantity) beforehand
    ///
    /// @param appId index of the target app
    /// @param token address of ERC20 token contract
    /// @param quantity how much of token
    function depositToken(uint32 appId, address token, uint quantity) external provisioned(appId) {
        require(isTokenAllowed[token], "use gluon contract");
        transferTokensToGluonSecurely(appId, LegacyToken(token), quantity);
        AppLogic(current(appId)).credit(msg.sender, token, quantity);
    }

    function transferTokensToGluonSecurely(uint32 appId, LegacyToken token, uint quantity) private {
        uint balanceBefore = token.balanceOf(address(this));
        token.transferFrom(msg.sender, address(this), quantity);
        uint balanceAfter = token.balanceOf(address(this));
        require(balanceAfter.minus(balanceBefore) == quantity, "bad LegacyToken; transferFrom erroneously reported of successful transfer");
        balances[appId][address(token)] = balances[appId][address(token)].plus(quantity);
        tokenBalances[address(token)] = tokenBalances[address(token)].plus(quantity);
    }

    /// @notice withdraw a quantity of token from an app's safe
    /// @dev quantity & token should be derived by the app
    ///
    /// @param appId index of the target app
    /// @param parameters a bytes-marshalled record containing at the very least quantity & token
    function withdraw(uint32 appId, bytes calldata parameters) external provisioned(appId) {
        (address token, uint quantity) = AppLogic(current(appId)).debit(msg.sender, parameters);
        require(isTokenAllowed[token], "use gluon contract");
        if (quantity > 0) {
            require(balances[appId][token] >= quantity, "not enough funds to transfer");
            balances[appId][token] = balances[appId][token].minus(quantity);
            tokenBalances[token] = tokenBalances[token].minus(quantity);
            transferTokensToAccountSecurely(LegacyToken(token), quantity, msg.sender);
        }
    }

    function transferTokensToAccountSecurely(LegacyToken token, uint quantity, address to) private {
        uint balanceBefore = token.balanceOf(to);
        token.transfer(to, quantity);
        uint balanceAfter = token.balanceOf(to);
        require(balanceAfter.minus(balanceBefore) == quantity, "transfer failed");
    }

    /// @notice withdraw a quantity of token from a source app's safe and transfer it (within Gluon) to a target app's safe
    /// @dev quantity & token should be derived by the source app
    ///
    /// @param from index of the source app
    /// @param to index of the target app
    /// @param parameters a bytes-marshalled record containing at the very least quantity & token
    function transfer(uint32 from, uint32 to, bytes calldata parameters) external provisioned(from) provisioned(to) {
        (address token, uint quantity) = AppLogic(current(from)).debit(msg.sender, parameters);
        require(isTokenAllowed[token], "use gluon contract");
        if (quantity > 0) {
            if (from != to) {
                require(balances[from][token] >= quantity, "not enough balance in logic to transfer");
                balances[from][token] = balances[from][token].minus(quantity);
                balances[to][token] = balances[to][token].plus(quantity);
            }
            AppLogic(current(to)).credit(msg.sender, token, quantity);
        }
    }

    /**************************************************** GluonView  ****************************************************/

    function current(uint32 appId) public view returns (address) {return gluon.current(appId);}

    /// @notice what is the current balance of `token` in the `appId` app's safe?
    function getBalance(uint32 appId, address token) external view returns (uint) {return balances[appId][token];}

    /**************************************************** allowed tokens  ****************************************************/
    /// @notice add a token
    function addToken(address token) external onlyOwner {addToken_(token);}

    function addToken_(address token) private validAddress(token) {
        if (!isTokenAllowed[token]) {
            isTokenAllowed[token] = true;
            tokens.push(token);
            emit TokenAdded(token);
        }
    }

    /// @notice remove a token
    function removeToken(address token) external onlyOwner {
        require(isTokenAllowed[token], "token does not exists");
        require(tokenBalances[token] == 0, "token is in use");
        isTokenAllowed[token] = false;
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                emit TokenRemoved(token);
                break;
            }
        }
    }

    function getTokens() public view returns (address[] memory){return tokens;}
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract LegacyToken {
    uint public _totalSupply;
    function totalSupply() public view returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}