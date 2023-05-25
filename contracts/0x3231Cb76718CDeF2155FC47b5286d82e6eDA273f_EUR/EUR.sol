/**
 *Submitted for verification at Etherscan.io on 2019-11-11
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: openzeppelin-solidity/contracts/ownership/Claimable.sol

pragma solidity ^0.4.24;



/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.4.24;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: openzeppelin-solidity/contracts/ownership/CanReclaimToken.sol

pragma solidity ^0.4.24;





/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoEther.sol

pragma solidity ^0.4.24;



/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <[email protected]π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

// File: openzeppelin-solidity/contracts/ownership/HasNoTokens.sol

pragma solidity ^0.4.24;



/**
 * @title Contracts that should not own Tokens
 * @author Remco Bloemen <[email protected]π.com>
 * @dev This blocks incoming ERC223 tokens to prevent accidental loss of tokens.
 * Should tokens (any ERC20Basic compatible) end up in the contract, it allows the
 * owner to reclaim the tokens.
 */
contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC223 compatible tokens
  * @param _from address The address that is transferring the tokens
  * @param _value uint256 the amount of the specified token
  * @param _data Bytes The data passed from the caller.
  */
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

// File: openzeppelin-solidity/contracts/ownership/HasNoContracts.sol

pragma solidity ^0.4.24;



/**
 * @title Contracts that should not own Contracts
 * @author Remco Bloemen <[email protected]π.com>
 * @dev Should contracts (anything Ownable) end up being owned by this contract, it allows the owner
 * of this contract to reclaim ownership of the contracts.
 */
contract HasNoContracts is Ownable {

  /**
   * @dev Reclaim ownership of Ownable contracts
   * @param _contractAddr The address of the Ownable to be reclaimed.
   */
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

// File: openzeppelin-solidity/contracts/ownership/NoOwner.sol

pragma solidity ^0.4.24;





/**
 * @title Base contract for contracts that should not own things.
 * @author Remco Bloemen <[email protected]π.com>
 * @dev Solves a class of errors where a contract accidentally becomes owner of Ether, Tokens or
 * Owned contracts. See respective base contracts for details.
 */
contract NoOwner is HasNoEther, HasNoTokens, HasNoContracts {
}

// File: openzeppelin-solidity/contracts/lifecycle/Destructible.sol

pragma solidity ^0.4.24;



/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

// File: contracts/IERC20.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: contracts/TokenStorageLib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;


/** @title TokenStorageLib
 * @dev Implementation of an[external storage for tokens.
 */
library TokenStorageLib {

    using SafeMath for uint;

    struct TokenStorage {
        mapping (address => uint) balances;
        mapping (address => mapping (address => uint)) allowed;
        uint totalSupply;
    }

    /**
     * @dev Increases balance of an address.
     * @param self Token storage to operate on.
     * @param to Address to increase.
     * @param amount Number of units to add.
     */
    function addBalance(TokenStorage storage self, address to, uint amount)
        external
    {
        self.totalSupply = self.totalSupply.add(amount);
        self.balances[to] = self.balances[to].add(amount);
    }

    /**
     * @dev Decreases balance of an address.
     * @param self Token storage to operate on.
     * @param from Address to decrease.
     * @param amount Number of units to subtract.
     */
    function subBalance(TokenStorage storage self, address from, uint amount)
        external
    {
        self.totalSupply = self.totalSupply.sub(amount);
        self.balances[from] = self.balances[from].sub(amount);
    }

    /**
     * @dev Sets the allowance for a spender.
     * @param self Token storage to operate on.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @param amount Qunatity of allowance.
     */
    function setAllowed(TokenStorage storage self, address owner, address spender, uint amount)
        external
    {
        self.allowed[owner][spender] = amount;
    }

    /**
     * @dev Returns the supply of tokens.
     * @param self Token storage to operate on.
     * @return Total supply.
     */
    function getSupply(TokenStorage storage self)
        external
        view
        returns (uint)
    {
        return self.totalSupply;
    }

    /**
     * @dev Returns the balance of an address.
     * @param self Token storage to operate on.
     * @param who Address to lookup.
     * @return Number of units.
     */
    function getBalance(TokenStorage storage self, address who)
        external
        view
        returns (uint)
    {
        return self.balances[who];
    }

    /**
     * @dev Returns the allowance for a spender.
     * @param self Token storage to operate on.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @return Number of units.
     */
    function getAllowed(TokenStorage storage self, address owner, address spender)
        external
        view
        returns (uint)
    {
        return self.allowed[owner][spender];
    }

}

// File: contracts/TokenStorage.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;





/**
 * @title TokenStorage
 * @dev External storage for tokens.
 * The storage is implemented in a separate contract to maintain state
 * between token upgrades.
 */
contract TokenStorage is Claimable, CanReclaimToken, NoOwner {

    using TokenStorageLib for TokenStorageLib.TokenStorage;

    TokenStorageLib.TokenStorage internal tokenStorage;

    /**
     * @dev Increases balance of an address.
     * @param to Address to increase.
     * @param amount Number of units to add.
     */
    function addBalance(address to, uint amount) external onlyOwner {
        tokenStorage.addBalance(to, amount);
    }

    /**
     * @dev Decreases balance of an address.
     * @param from Address to decrease.
     * @param amount Number of units to subtract.
     */
    function subBalance(address from, uint amount) external onlyOwner {
        tokenStorage.subBalance(from, amount);
    }

    /**
     * @dev Sets the allowance for a spender.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @param amount Qunatity of allowance.
     */
    function setAllowed(address owner, address spender, uint amount) external onlyOwner {
        tokenStorage.setAllowed(owner, spender, amount);
    }

    /**
     * @dev Returns the supply of tokens.
     * @return Total supply.
     */
    function getSupply() external view returns (uint) {
        return tokenStorage.getSupply();
    }

    /**
     * @dev Returns the balance of an address.
     * @param who Address to lookup.
     * @return Number of units.
     */
    function getBalance(address who) external view returns (uint) {
        return tokenStorage.getBalance(who);
    }

    /**
     * @dev Returns the allowance for a spender.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender Address of the spender.
     * @return Number of units.
     */
    function getAllowed(address owner, address spender)
        external
        view
        returns (uint)
    {
        return tokenStorage.getAllowed(owner, spender);
    }

}

// File: contracts/ERC20Lib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;



/**
 * @title ERC20Lib
 * @dev Standard ERC20 token functionality.
 * https://github.com/ethereum/EIPs/issues/20
 */
library ERC20Lib {

    using SafeMath for uint;

    /**
     * @dev Transfers tokens [ERC20].
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transfer(TokenStorage db, address caller, address to, uint amount)
        external
        returns (bool success)
    {
        db.subBalance(caller, amount);
        db.addBalance(to, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from a specific address [ERC20].
     * The address owner has to approve the spender beforehand.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to debet the tokens from.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transferFrom(
        TokenStorage db,
        address caller,
        address from,
        address to,
        uint amount
    )
        external
        returns (bool success)
    {
        uint allowance = db.getAllowed(from, caller);
        db.subBalance(from, amount);
        db.addBalance(to, amount);
        db.setAllowed(from, caller, allowance.sub(amount));
        return true;
    }

    /**
     * @dev Approves a spender [ERC20].
     * Note that using the approve/transferFrom presents a possible
     * security vulnerability described in:
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.quou09mcbpzw
     * Use transferAndCall to mitigate.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param spender The address of the future spender.
     * @param amount The allowance of the spender.
     */
    function approve(TokenStorage db, address caller, address spender, uint amount)
        public
        returns (bool success)
    {
        db.setAllowed(caller, spender, amount);
        return true;
    }

    /**
     * @dev Returns the number tokens associated with an address.
     * @param db Token storage to operate on.
     * @param who Address to lookup.
     * @return Balance of address.
     */
    function balanceOf(TokenStorage db, address who)
        external
        view
        returns (uint balance)
    {
        return db.getBalance(who);
    }

    /**
     * @dev Returns the allowance for a spender
     * @param db Token storage to operate on.
     * @param owner The address of the owner of the tokens.
     * @param spender The address of the spender.
     * @return Number of tokens the spender is allowed to spend.
     */
    function allowance(TokenStorage db, address owner, address spender)
        external
        view
        returns (uint remaining)
    {
        return db.getAllowed(owner, spender);
    }

}

// File: contracts/MintableTokenLib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

library MintableTokenLib {

    using SafeMath for uint;

    /**
     * @dev Mints new tokens.
     * @param db Token storage to operate on.
     * @param to The address that will recieve the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(
        TokenStorage db,
        address to,
        uint amount
    )
        external
        returns (bool)
    {
        db.addBalance(to, amount);
        return true;
    }

    /**
     * @dev Burns tokens.
     * @param db Token storage to operate on.
     * @param from The address holding tokens.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        TokenStorage db,
        address from,
        uint amount
    )
        public
        returns (bool)
    {
        db.subBalance(from, amount);
        return true;
    }

    /**
     * @dev Burns tokens from a specific address.
     * To burn the tokens the caller needs to provide a signature
     * proving that the caller is authorized by the token owner to do so.
     * @param db Token storage to operate on.
     * @param from The address holding tokens.
     * @param amount The amount of tokens to burn.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     */
    function burn(
        TokenStorage db,
        address from,
        uint amount,
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (bool)
    {
        require(
            ecrecover(h, v, r, s) == from,
            "signature/hash does not match"
        );
        return burn(db, from, amount);
    }

}

// File: contracts/IValidator.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;

/**
 * @title IValidator
 * @dev Contracts implementing this interface validate token transfers.
 */
interface IValidator {

    /**
     * @dev Emitted when a validator makes a decision.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     * @param valid True if transfer approved, false if rejected.
     */
    event Decision(address indexed from, address indexed to, uint amount, bool valid);

    /**
     * @dev Validates token transfer.
     * If the sender is on the blacklist the transfer is denied.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     */
    function validate(address from, address to, uint amount) external returns (bool valid);

}

// File: contracts/SmartTokenLib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;




/**
 * @title SmartTokenLib
 * @dev This library provides functionality which is required from a regulatory perspective.
 */
library SmartTokenLib {

    using ERC20Lib for TokenStorage;
    using MintableTokenLib for TokenStorage;

    struct SmartStorage {
        IValidator validator;
    }

    /**
     * @dev Emitted when the contract owner recovers tokens.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     */
    event Recovered(address indexed from, address indexed to, uint amount);

    /**
     * @dev Emitted when updating the validator.
     * @param old Address of the old validator.
     * @param current Address of the new validator.
     */
    event Validator(address indexed old, address indexed current);

    /**
     * @dev Sets a new validator.
     * @param self Smart storage to operate on.
     * @param validator Address of validator.
     */
    function setValidator(SmartStorage storage self, address validator)
        external
    {
        emit Validator(self.validator, validator);
        self.validator = IValidator(validator);
    }


    /**
     * @dev Approves or rejects a transfer request.
     * The request is forwarded to a validator which implements
     * the actual business logic.
     * @param self Smart storage to operate on.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens.
     */
    function validate(SmartStorage storage self, address from, address to, uint amount)
        external
        returns (bool valid)
    {
        return self.validator.validate(from, to, amount);
    }

    /**
     * @dev Recovers tokens from an address and reissues them to another address.
     * In case a user loses its private key the tokens can be recovered by burning
     * the tokens from that address and reissuing to a new address.
     * To recover tokens the contract owner needs to provide a signature
     * proving that the token owner has authorized the owner to do so.
     * @param from Address to burn tokens from.
     * @param to Address to mint tokens to.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     * @return Amount recovered.
     */
    function recover(
        TokenStorage token,
        address from,
        address to,
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint)
    {
        require(
            ecrecover(h, v, r, s) == from,
            "signature/hash does not recover from address"
        );
        uint amount = token.balanceOf(from);
        token.burn(from, amount);
        token.mint(to, amount);
        emit Recovered(from, to, amount);
        return amount;
    }

    /**
     * @dev Gets the current validator.
     * @param self Smart storage to operate on.
     * @return Address of validator.
     */
    function getValidator(SmartStorage storage self)
        external
        view
        returns (address)
    {
        return address(self.validator);
    }

}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/AddressUtils.sol

pragma solidity ^0.4.24;


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}

// File: contracts/IERC677Recipient.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;

/**
 * @title IERC677Recipient
 * @dev Contracts implementing this interface can participate in [ERC677].
 */
interface IERC677Recipient {

    /**
     * @dev Receives notification from [ERC677] transferAndCall.
     * @param from Sender address.
     * @param amount Number of tokens.
     * @param data Additional data.
     */
    function onTokenTransfer(address from, uint256 amount, bytes data) external returns (bool);

}

// File: contracts/ERC677Lib.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;





/**
 * @title ERC677
 * @dev ERC677 token functionality.
 * https://github.com/ethereum/EIPs/issues/677
 */
library ERC677Lib {

    using ERC20Lib for TokenStorage;
    using AddressUtils for address;

    /**
     * @dev Transfers tokens and subsequently calls a method on the recipient [ERC677].
     * If the recipient is a non-contract address this method behaves just like transfer.
     * @notice db.transfer either returns true or reverts.
     * @param db Token storage to operate on.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     * @param data Additional data passed to the recipient's tokenFallback method.
     */
    function transferAndCall(
        TokenStorage db,
        address caller,
        address to,
        uint256 amount,
        bytes data
    )
        external
        returns (bool)
    {
        require(
            db.transfer(caller, to, amount), 
            "unable to transfer"
        );
        if (to.isContract()) {
            IERC677Recipient recipient = IERC677Recipient(to);
            require(
                recipient.onTokenTransfer(caller, amount, data),
                "token handler returns false"
            );
        }
        return true;
    }

}

// File: contracts/StandardController.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;








/**
 * @title StandardController
 * @dev This is the base contract which delegates token methods [ERC20 and ERC677]
 * to their respective library implementations.
 * The controller is primarily intended to be interacted with via a token frontend.
 */
contract StandardController is Pausable, Destructible, Claimable {

    using ERC20Lib for TokenStorage;
    using ERC677Lib for TokenStorage;

    TokenStorage internal token;
    address internal frontend;

    string public name;
    string public symbol;
    uint public decimals = 18;

    /**
     * @dev Emitted when updating the frontend.
     * @param old Address of the old frontend.
     * @param current Address of the new frontend.
     */
    event Frontend(address indexed old, address indexed current);

    /**
     * @dev Emitted when updating the storage.
     * @param old Address of the old storage.
     * @param current Address of the new storage.
     */
    event Storage(address indexed old, address indexed current);

    /**
     * @dev Modifier which prevents the function from being called by unauthorized parties.
     * The caller must either be the sender or the function must be
     * called via the frontend, otherwise the call is reverted.
     * @param caller The address of the passed-in caller. Used to preserve the original caller.
     */
    modifier guarded(address caller) {
        require(
            msg.sender == caller || msg.sender == frontend,
            "either caller must be sender or calling via frontend"
        );
        _;
    }

    /**
     * @dev Contract constructor.
     * @param storage_ Address of the token storage for the controller.
     * @param initialSupply The amount of tokens to mint upon creation.
     * @param frontend_ Address of the authorized frontend.
     */
    constructor(address storage_, uint initialSupply, address frontend_) public {
        require(
            storage_ == 0x0 || initialSupply == 0,
            "either a token storage must be initialized or no initial supply"
        );
        if (storage_ == 0x0) {
            token = new TokenStorage();
            token.addBalance(msg.sender, initialSupply);
        } else {
            token = TokenStorage(storage_);
        }
        frontend = frontend_;
    }

    /**
     * @dev Prevents tokens to be sent to well known blackholes by throwing on known blackholes.
     * @param to The address of the intended recipient.
     */
    function avoidBlackholes(address to) internal view {
        require(to != 0x0, "must not send to 0x0");
        require(to != address(this), "must not send to controller");
        require(to != address(token), "must not send to token storage");
        require(to != frontend, "must not send to frontend");
    }

    /**
     * @dev Returns the current frontend.
     * @return Address of the frontend.
     */
    function getFrontend() external view returns (address) {
        return frontend;
    }

    /**
     * @dev Returns the current storage.
     * @return Address of the storage.
     */
    function getStorage() external view returns (address) {
        return address(token);
    }

    /**
     * @dev Sets a new frontend.
     * @param frontend_ Address of the new frontend.
     */
    function setFrontend(address frontend_) public onlyOwner {
        emit Frontend(frontend, frontend_);
        frontend = frontend_;
    }

    /**
     * @dev Sets a new storage.
     * @param storage_ Address of the new storage.
     */
    function setStorage(address storage_) external onlyOwner {
        emit Storage(address(token), storage_);
        token = TokenStorage(storage_);
    }

    /**
     * @dev Transfers the ownership of the storage.
     * @param newOwner Address of the new storage owner.
     */
    function transferStorageOwnership(address newOwner) public onlyOwner {
        token.transferOwnership(newOwner);
    }

    /**
     * @dev Claims the ownership of the storage.
     */
    function claimStorageOwnership() public onlyOwner {
        token.claimOwnership();
    }

    /**
     * @dev Transfers tokens [ERC20].
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transfer_withCaller(address caller, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        avoidBlackholes(to);
        return token.transfer(caller, to, amount);
    }

    /**
     * @dev Transfers tokens from a specific address [ERC20].
     * The address owner has to approve the spender beforehand.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to debet the tokens from.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transferFrom_withCaller(address caller, address from, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        avoidBlackholes(to);
        return token.transferFrom(caller, from, to, amount);
    }

    /**
     * @dev Approves a spender [ERC20].
     * Note that using the approve/transferFrom presents a possible
     * security vulnerability described in:
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.quou09mcbpzw
     * Use transferAndCall to mitigate.
     * @param caller Address of the caller passed through the frontend.
     * @param spender The address of the future spender.
     * @param amount The allowance of the spender.
     */
    function approve_withCaller(address caller, address spender, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        return token.approve(caller, spender, amount);
    }

    /**
     * @dev Transfers tokens and subsequently calls a method on the recipient [ERC677].
     * If the recipient is a non-contract address this method behaves just like transfer.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     * @param data Additional data passed to the recipient's tokenFallback method.
     */
    function transferAndCall_withCaller(
        address caller,
        address to,
        uint256 amount,
        bytes data
    )
        public
        guarded(caller)
        whenNotPaused
        returns (bool ok)
    {
        avoidBlackholes(to);
        return token.transferAndCall(caller, to, amount, data);
    }

    /**
     * @dev Returns the total supply.
     * @return Number of tokens.
     */
    function totalSupply() external view returns (uint) {
        return token.getSupply();
    }

    /**
     * @dev Returns the number tokens associated with an address.
     * @param who Address to lookup.
     * @return Balance of address.
     */
    function balanceOf(address who) external view returns (uint) {
        return token.getBalance(who);
    }

    /**
     * @dev Returns the allowance for a spender
     * @param owner The address of the owner of the tokens.
     * @param spender The address of the spender.
     * @return Number of tokens the spender is allowed to spend.
     */
    function allowance(address owner, address spender) external view returns (uint) {
        return token.allowance(owner, spender);
    }

}

// File: openzeppelin-solidity/contracts/access/rbac/Roles.sol

pragma solidity ^0.4.24;


/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

// File: contracts/SystemRole.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;


/**
 * @title SystemRole
 * @dev SystemRole accounts have been approved to perform operational actions (e.g. mint and burn).
 * @notice addSystemAccount and removeSystemAccount are unprotected by default, i.e. anyone can call them.
 * @notice Contracts inheriting SystemRole *should* authorize the caller by overriding them.
 */
contract SystemRole {

    using Roles for Roles.Role;
    Roles.Role private systemAccounts;

    /**
     * @dev Emitted when system account is added.
     * @param account is a new system account.
     */
    event SystemAccountAdded(address indexed account);

    /**
     * @dev Emitted when system account is removed.
     * @param account is the old system account.
     */
    event SystemAccountRemoved(address indexed account);

    /**
     * @dev Modifier which prevents non-system accounts from calling protected functions.
     */
    modifier onlySystemAccounts() {
        require(isSystemAccount(msg.sender));
        _;
    }

    /**
     * @dev Modifier which prevents non-system accounts from being passed to the guard.
     * @param account The account to check.
     */
    modifier onlySystemAccount(address account) {
        require(
            isSystemAccount(account),
            "must be a system account"
        );
        _;
    }

    /**
     * @dev System Role constructor.
     * @notice The contract is an abstract contract as a result of the internal modifier.
     */
    constructor() internal {}

    /**
     * @dev Checks whether an address is a system account.
     * @param account the address to check.
     * @return true if system account.
     */
    function isSystemAccount(address account) public view returns (bool) {
        return systemAccounts.has(account);
    }

    /**
     * @dev Assigns the system role to an account.
     * @notice This method is unprotected and should be authorized in the child contract.
     */
    function addSystemAccount(address account) public {
        systemAccounts.add(account);
        emit SystemAccountAdded(account);
    }

    /**
     * @dev Removes the system role from an account.
     * @notice This method is unprotected and should be authorized in the child contract.
     */
    function removeSystemAccount(address account) public {
        systemAccounts.remove(account);
        emit SystemAccountRemoved(account);
    }

}

// File: contracts/MintableController.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;




/**
* @title MintableController
* @dev This contracts implements functionality allowing for minting and burning of tokens.
*/
contract MintableController is SystemRole, StandardController {

    using MintableTokenLib for TokenStorage;

    /**
     * @dev Contract constructor.
     * @param storage_ Address of the token storage for the controller.
     * @param initialSupply The amount of tokens to mint upon creation.
     * @param frontend_ Address of the authorized frontend.
     */
    constructor(address storage_, uint initialSupply, address frontend_)
        public
        StandardController(storage_, initialSupply, frontend_)
    { }

    /**
     * @dev Assigns the system role to an account.
     */
    function addSystemAccount(address account) public onlyOwner {
        super.addSystemAccount(account);
    }

    /**
     * @dev Removes the system role from an account.
     */
    function removeSystemAccount(address account) public onlyOwner {
        super.removeSystemAccount(account);
    }

    /**
     * @dev Mints new tokens.
     * @param caller Address of the caller passed through the frontend.
     * @param to Address to credit the tokens.
     * @param amount Number of tokens to mint.
     */
    function mintTo_withCaller(address caller, address to, uint amount)
        public
        guarded(caller)
        onlySystemAccount(caller)
        returns (bool)
    {
        avoidBlackholes(to);
        return token.mint(to, amount);
    }

    /**
     * @dev Burns tokens from token owner.
     * This removfes the burned tokens from circulation.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address of the token owner.
     * @param amount Number of tokens to burn.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     */
    function burnFrom_withCaller(address caller, address from, uint amount, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        public
        guarded(caller)
        onlySystemAccount(caller)
        returns (bool)
    {
        return token.burn(from, amount, h, v, r, s);
    }

}

// File: contracts/SmartController.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;




/**
 * @title SmartController
 * @dev This contract adds "smart" functionality which is required from a regulatory perspective.
 */
contract SmartController is MintableController {

    using SmartTokenLib for SmartTokenLib.SmartStorage;

    SmartTokenLib.SmartStorage internal smartToken;

    bytes3 public ticker;
    uint constant public INITIAL_SUPPLY = 0;

    /**
     * @dev Contract constructor.
     * @param storage_ Address of the token storage for the controller.
     * @param validator Address of validator.
     * @param ticker_ 3 letter currency ticker.
     * @param frontend_ Address of the authorized frontend.
     */
    constructor(address storage_, address validator, bytes3 ticker_, address frontend_)
        public
        MintableController(storage_, INITIAL_SUPPLY, frontend_)
    {
        require(validator != 0x0, "validator cannot be the null address");
        smartToken.setValidator(validator);
        ticker = ticker_;
    }

    /**
     * @dev Sets a new validator.
     * @param validator Address of validator.
     */
    function setValidator(address validator) external onlySystemAccounts {
        smartToken.setValidator(validator);
    }

    /**
     * @dev Recovers tokens from an address and reissues them to another address.
     * In case a user loses its private key the tokens can be recovered by burning
     * the tokens from that address and reissuing to a new address.
     * To recover tokens the contract owner needs to provide a signature
     * proving that the token owner has authorized the owner to do so.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to burn tokens from.
     * @param to Address to mint tokens to.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     * @return Amount recovered.
     */
    function recover_withCaller(address caller, address from, address to, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        external
        guarded(caller)
        onlySystemAccount(caller)
        returns (uint)
    {
        avoidBlackholes(to);
        return SmartTokenLib.recover(token, from, to, h, v, r, s);
    }

    /**
     * @dev Transfers tokens [ERC20].
     * The caller, to address and amount are validated before executing method.
     * Prior to transfering tokens the validator needs to approve.
     * @notice Overrides method in a parent.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transfer_withCaller(address caller, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(caller, to, amount), "transfer request not valid");
        return super.transfer_withCaller(caller, to, amount);
    }

    /**
     * @dev Transfers tokens from a specific address [ERC20].
     * The address owner has to approve the spender beforehand.
     * The from address, to address and amount are validated before executing method.
     * @notice Overrides method in a parent.
     * Prior to transfering tokens the validator needs to approve.
     * @param caller Address of the caller passed through the frontend.
     * @param from Address to debet the tokens from.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transferFrom_withCaller(address caller, address from, address to, uint amount)
        public
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(from, to, amount), "transferFrom request not valid");
        return super.transferFrom_withCaller(caller, from, to, amount);
    }

    /**
     * @dev Transfers tokens and subsequently calls a method on the recipient [ERC677].
     * If the recipient is a non-contract address this method behaves just like transfer.
     * The caller, to address and amount are validated before executing method.
     * @notice Overrides method in a parent.
     * @param caller Address of the caller passed through the frontend.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     * @param data Additional data passed to the recipient's tokenFallback method.
     */
    function transferAndCall_withCaller(
        address caller,
        address to,
        uint256 amount,
        bytes data
    )
        public
        guarded(caller)
        whenNotPaused
        returns (bool)
    {
        require(smartToken.validate(caller, to, amount), "transferAndCall request not valid");
        return super.transferAndCall_withCaller(caller, to, amount, data);
    }

    /**
     * @dev Gets the current validator.
     * @return Address of validator.
     */
    function getValidator() external view returns (address) {
        return smartToken.getValidator();
    }

}

// File: contracts/TokenFrontend.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;







/**
 * @title TokenFrontend
 * @dev This contract implements a token forwarder.
 * The token frontend is [ERC20 and ERC677] compliant and forwards
 * standard methods to a controller. The primary function is to allow
 * for a statically deployed contract for users to interact with while
 * simultaneously allow the controllers to be upgraded when bugs are
 * discovered or new functionality needs to be added.
 */
contract TokenFrontend is Destructible, Claimable, CanReclaimToken, NoOwner, IERC20 {

    SmartController internal controller;

    string public name;
    string public symbol;
    bytes3 public ticker;

    /**
     * @dev Emitted when tokens are transferred.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens transferred.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @dev Emitted when tokens are transferred.
     * @param from Sender address.
     * @param to Recipient address.
     * @param amount Number of tokens transferred.
     * @param data Additional data passed to the recipient's tokenFallback method.
     */
    event Transfer(address indexed from, address indexed to, uint amount, bytes data);

    /**
     * @dev Emitted when spender is granted an allowance.
     * @param owner Address of the owner of the tokens to spend.
     * @param spender The address of the future spender.
     * @param amount The allowance of the spender.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

    /**
     * @dev Emitted when updating the controller.
     * @param ticker Three letter ticker representing the currency.
     * @param old Address of the old controller.
     * @param current Address of the new controller.
     */
    event Controller(bytes3 indexed ticker, address indexed old, address indexed current);

    /**
     * @dev Contract constructor.
     * @notice The contract is an abstract contract as a result of the internal modifier.
     * @param name_ Token name.
     * @param symbol_ Token symbol.
     * @param ticker_ 3 letter currency ticker.
     */
    constructor(string name_, string symbol_, bytes3 ticker_) internal {
        name = name_;
        symbol = symbol_;
        ticker = ticker_;
    }

    /**
     * @dev Sets a new controller.
     * @param address_ Address of the controller.
     */
    function setController(address address_) external onlyOwner {
        require(address_ != 0x0, "controller address cannot be the null address");
        emit Controller(ticker, controller, address_);
        controller = SmartController(address_);
        require(controller.getFrontend() == address(this), "controller frontend does not point back");
        require(controller.ticker() == ticker, "ticker does not match controller ticket");
    }

    /**
     * @dev Transfers tokens [ERC20].
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transfer(address to, uint amount) external returns (bool ok) {
        ok = controller.transfer_withCaller(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
    }

    /**
     * @dev Transfers tokens from a specific address [ERC20].
     * The address owner has to approve the spender beforehand.
     * @param from Address to debet the tokens from.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool ok) {
        ok = controller.transferFrom_withCaller(msg.sender, from, to, amount);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Approves a spender [ERC20].
     * Note that using the approve/transferFrom presents a possible
     * security vulnerability described in:
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit#heading=h.quou09mcbpzw
     * Use transferAndCall to mitigate.
     * @param spender The address of the future spender.
     * @param amount The allowance of the spender.
     */
    function approve(address spender, uint amount) external returns (bool ok) {
        ok = controller.approve_withCaller(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
    }

    /**
     * @dev Transfers tokens and subsequently calls a method on the recipient [ERC677].
     * If the recipient is a non-contract address this method behaves just like transfer.
     * @param to Recipient address.
     * @param amount Number of tokens to transfer.
     * @param data Additional data passed to the recipient's tokenFallback method.
     */
    function transferAndCall(address to, uint256 amount, bytes data)
        external
        returns (bool ok)
    {
        ok = controller.transferAndCall_withCaller(msg.sender, to, amount, data);
        emit Transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount, data);
    }

    /**
     * @dev Mints new tokens.
     * @param to Address to credit the tokens.
     * @param amount Number of tokens to mint.
     */
    function mintTo(address to, uint amount)
        external
        returns (bool ok)
    {
        ok = controller.mintTo_withCaller(msg.sender, to, amount);
        emit Transfer(0x0, to, amount);
    }

    /**
     * @dev Burns tokens from token owner.
     * This removfes the burned tokens from circulation.
     * @param from Address of the token owner.
     * @param amount Number of tokens to burn.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     */
    function burnFrom(address from, uint amount, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        external
        returns (bool ok)
    {
        ok = controller.burnFrom_withCaller(msg.sender, from, amount, h, v, r, s);
        emit Transfer(from, 0x0, amount);
    }

    /**
     * @dev Recovers tokens from an address and reissues them to another address.
     * In case a user loses its private key the tokens can be recovered by burning
     * the tokens from that address and reissuing to a new address.
     * To recover tokens the contract owner needs to provide a signature
     * proving that the token owner has authorized the owner to do so.
     * @param from Address to burn tokens from.
     * @param to Address to mint tokens to.
     * @param h Hash which the token owner signed.
     * @param v Signature component.
     * @param r Signature component.
     * @param s Sigature component.
     * @return Amount recovered.
     */
    function recover(address from, address to, bytes32 h, uint8 v, bytes32 r, bytes32 s)
        external
        returns (uint amount)
    {
        amount = controller.recover_withCaller(msg.sender, from, to, h ,v, r, s);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev Gets the current controller.
     * @return Address of the controller.
     */
    function getController() external view returns (address) {
        return address(controller);
    }

    /**
     * @dev Returns the total supply.
     * @return Number of tokens.
     */
    function totalSupply() external view returns (uint) {
        return controller.totalSupply();
    }

    /**
     * @dev Returns the number tokens associated with an address.
     * @param who Address to lookup.
     * @return Balance of address.
     */
    function balanceOf(address who) external view returns (uint) {
        return controller.balanceOf(who);
    }

    /**
     * @dev Returns the allowance for a spender
     * @param owner The address of the owner of the tokens.
     * @param spender The address of the spender.
     * @return Number of tokens the spender is allowed to spend.
     */
    function allowance(address owner, address spender) external view returns (uint) {
        return controller.allowance(owner, spender);
    }

    /**
     * @dev Returns the number of decimals in one token.
     * @return Number of decimals.
     */
    function decimals() external view returns (uint) {
        return controller.decimals();
    }

}

// File: contracts/EUR.sol

/**
 * Copyright 2019 Monerium ehf.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

pragma solidity 0.4.24;


contract EUR is TokenFrontend {

    constructor()
        public
        TokenFrontend("Monerium EUR emoney", "EURe", "EUR")
    { }

}