/**
 *Submitted for verification at Etherscan.io on 2020-03-26
*/

pragma solidity ^0.5.2;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.2;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.2;



/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 * Originally based on code by FirstBlood:
 * https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

// File: contracts/lib/CommonMath.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;



library CommonMath {
    using SafeMath for uint256;

    uint256 public constant SCALE_FACTOR = 10 ** 18;
    uint256 public constant MAX_UINT_256 = 2 ** 256 - 1;

    /**
     * Returns scale factor equal to 10 ** 18
     *
     * @return  10 ** 18
     */
    function scaleFactor()
        internal
        pure
        returns (uint256)
    {
        return SCALE_FACTOR;
    }

    /**
     * Calculates and returns the maximum value for a uint256
     *
     * @return  The maximum value for uint256
     */
    function maxUInt256()
        internal
        pure
        returns (uint256)
    {
        return MAX_UINT_256;
    }

    /**
     * Increases a value by the scale factor to allow for additional precision
     * during mathematical operations
     */
    function scale(
        uint256 a
    )
        internal
        pure
        returns (uint256)
    {
        return a.mul(SCALE_FACTOR);
    }

    /**
     * Divides a value by the scale factor to allow for additional precision
     * during mathematical operations
    */
    function deScale(
        uint256 a
    )
        internal
        pure
        returns (uint256)
    {
        return a.div(SCALE_FACTOR);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0);

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }

    /**
    * @dev Performs division where if there is a modulo, the value is rounded up
    */
    function divCeil(uint256 a, uint256 b)
        internal
        pure
        returns(uint256)
    {
        return a.mod(b) > 0 ? a.div(b).add(1) : a.div(b);
    }

    /**
     * Checks for rounding errors and returns value of potential partial amounts of a principal
     *
     * @param  _principal       Number fractional amount is derived from
     * @param  _numerator       Numerator of fraction
     * @param  _denominator     Denominator of fraction
     * @return uint256          Fractional amount of principal calculated
     */
    function getPartialAmount(
        uint256 _principal,
        uint256 _numerator,
        uint256 _denominator
    )
        internal
        pure
        returns (uint256)
    {
        // Get remainder of partial amount (if 0 not a partial amount)
        uint256 remainder = mulmod(_principal, _numerator, _denominator);

        // Return if not a partial amount
        if (remainder == 0) {
            return _principal.mul(_numerator).div(_denominator);
        }

        // Calculate error percentage
        uint256 errPercentageTimes1000000 = remainder.mul(1000000).div(_numerator.mul(_principal));

        // Require error percentage is less than 0.1%.
        require(
            errPercentageTimes1000000 < 1000,
            "CommonMath.getPartialAmount: Rounding error exceeds bounds"
        );

        return _principal.mul(_numerator).div(_denominator);
    }

    /*
     * Gets the rounded up log10 of passed value
     *
     * @param  _value         Value to calculate ceil(log()) on
     * @return uint256        Output value
     */
    function ceilLog10(
        uint256 _value
    )
        internal
        pure
        returns (uint256)
    {
        // Make sure passed value is greater than 0
        require (
            _value > 0,
            "CommonMath.ceilLog10: Value must be greater than zero."
        );

        // Since log10(1) = 0, if _value = 1 return 0
        if (_value == 1) return 0;

        // Calcualte ceil(log10())
        uint256 x = _value - 1;

        uint256 result = 0;

        if (x >= 10 ** 64) {
            x /= 10 ** 64;
            result += 64;
        }
        if (x >= 10 ** 32) {
            x /= 10 ** 32;
            result += 32;
        }
        if (x >= 10 ** 16) {
            x /= 10 ** 16;
            result += 16;
        }
        if (x >= 10 ** 8) {
            x /= 10 ** 8;
            result += 8;
        }
        if (x >= 10 ** 4) {
            x /= 10 ** 4;
            result += 4;
        }
        if (x >= 100) {
            x /= 100;
            result += 2;
        }
        if (x >= 10) {
            result += 1;
        }

        return result + 1;
    }
}

// File: contracts/core/lib/RebalancingLibrary.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;


/**
 * @title RebalancingLibrary
 * @author Set Protocol
 *
 * The RebalancingLibrary contains functions for facilitating the rebalancing process for
 * Rebalancing Set Tokens. Removes the old calculation functions
 *
 */
library RebalancingLibrary {

    /* ============ Enums ============ */

    enum State { Default, Proposal, Rebalance, Drawdown }

    /* ============ Structs ============ */

    struct AuctionPriceParameters {
        uint256 auctionStartTime;
        uint256 auctionTimeToPivot;
        uint256 auctionStartPrice;
        uint256 auctionPivotPrice;
    }

    struct BiddingParameters {
        uint256 minimumBid;
        uint256 remainingCurrentSets;
        uint256[] combinedCurrentUnits;
        uint256[] combinedNextSetUnits;
        address[] combinedTokenArray;
    }
}

// File: contracts/core/interfaces/ICore.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;


/**
 * @title ICore
 * @author Set Protocol
 *
 * The ICore Contract defines all the functions exposed in the Core through its
 * various extensions and is a light weight way to interact with the contract.
 */
interface ICore {
    /**
     * Return transferProxy address.
     *
     * @return address       transferProxy address
     */
    function transferProxy()
        external
        view
        returns (address);

    /**
     * Return vault address.
     *
     * @return address       vault address
     */
    function vault()
        external
        view
        returns (address);

    /**
     * Return address belonging to given exchangeId.
     *
     * @param  _exchangeId       ExchangeId number
     * @return address           Address belonging to given exchangeId
     */
    function exchangeIds(
        uint8 _exchangeId
    )
        external
        view
        returns (address);

    /*
     * Returns if valid set
     *
     * @return  bool      Returns true if Set created through Core and isn't disabled
     */
    function validSets(address)
        external
        view
        returns (bool);

    /*
     * Returns if valid module
     *
     * @return  bool      Returns true if valid module
     */
    function validModules(address)
        external
        view
        returns (bool);

    /**
     * Return boolean indicating if address is a valid Rebalancing Price Library.
     *
     * @param  _priceLibrary    Price library address
     * @return bool             Boolean indicating if valid Price Library
     */
    function validPriceLibraries(
        address _priceLibrary
    )
        external
        view
        returns (bool);

    /**
     * Exchanges components for Set Tokens
     *
     * @param  _set          Address of set to issue
     * @param  _quantity     Quantity of set to issue
     */
    function issue(
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Issues a specified Set for a specified quantity to the recipient
     * using the caller's components from the wallet and vault.
     *
     * @param  _recipient    Address to issue to
     * @param  _set          Address of the Set to issue
     * @param  _quantity     Number of tokens to issue
     */
    function issueTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Converts user's components into Set Tokens held directly in Vault instead of user's account
     *
     * @param _set          Address of the Set
     * @param _quantity     Number of tokens to redeem
     */
    function issueInVault(
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Function to convert Set Tokens into underlying components
     *
     * @param _set          The address of the Set token
     * @param _quantity     The number of tokens to redeem. Should be multiple of natural unit.
     */
    function redeem(
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Redeem Set token and return components to specified recipient. The components
     * are left in the vault
     *
     * @param _recipient    Recipient of Set being issued
     * @param _set          Address of the Set
     * @param _quantity     Number of tokens to redeem
     */
    function redeemTo(
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Function to convert Set Tokens held in vault into underlying components
     *
     * @param _set          The address of the Set token
     * @param _quantity     The number of tokens to redeem. Should be multiple of natural unit.
     */
    function redeemInVault(
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Composite method to redeem and withdraw with a single transaction
     *
     * Normally, you should expect to be able to withdraw all of the tokens.
     * However, some have central abilities to freeze transfers (e.g. EOS). _toExclude
     * allows you to optionally specify which component tokens to exclude when
     * redeeming. They will remain in the vault under the users' addresses.
     *
     * @param _set          Address of the Set
     * @param _to           Address to withdraw or attribute tokens to
     * @param _quantity     Number of tokens to redeem
     * @param _toExclude    Mask of indexes of tokens to exclude from withdrawing
     */
    function redeemAndWithdrawTo(
        address _set,
        address _to,
        uint256 _quantity,
        uint256 _toExclude
    )
        external;

    /**
     * Deposit multiple tokens to the vault. Quantities should be in the
     * order of the addresses of the tokens being deposited.
     *
     * @param  _tokens           Array of the addresses of the ERC20 tokens
     * @param  _quantities       Array of the number of tokens to deposit
     */
    function batchDeposit(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

    /**
     * Withdraw multiple tokens from the vault. Quantities should be in the
     * order of the addresses of the tokens being withdrawn.
     *
     * @param  _tokens            Array of the addresses of the ERC20 tokens
     * @param  _quantities        Array of the number of tokens to withdraw
     */
    function batchWithdraw(
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

    /**
     * Deposit any quantity of tokens into the vault.
     *
     * @param  _token           The address of the ERC20 token
     * @param  _quantity        The number of tokens to deposit
     */
    function deposit(
        address _token,
        uint256 _quantity
    )
        external;

    /**
     * Withdraw a quantity of tokens from the vault.
     *
     * @param  _token           The address of the ERC20 token
     * @param  _quantity        The number of tokens to withdraw
     */
    function withdraw(
        address _token,
        uint256 _quantity
    )
        external;

    /**
     * Transfer tokens associated with the sender's account in vault to another user's
     * account in vault.
     *
     * @param  _token           Address of token being transferred
     * @param  _to              Address of user receiving tokens
     * @param  _quantity        Amount of tokens being transferred
     */
    function internalTransfer(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;

    /**
     * Deploys a new Set Token and adds it to the valid list of SetTokens
     *
     * @param  _factory              The address of the Factory to create from
     * @param  _components           The address of component tokens
     * @param  _units                The units of each component token
     * @param  _naturalUnit          The minimum unit to be issued or redeemed
     * @param  _name                 The bytes32 encoded name of the new Set
     * @param  _symbol               The bytes32 encoded symbol of the new Set
     * @param  _callData             Byte string containing additional call parameters
     * @return setTokenAddress       The address of the new Set
     */
    function createSet(
        address _factory,
        address[] calldata _components,
        uint256[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);

    /**
     * Exposes internal function that deposits a quantity of tokens to the vault and attributes
     * the tokens respectively, to system modules.
     *
     * @param  _from            Address to transfer tokens from
     * @param  _to              Address to credit for deposit
     * @param  _token           Address of token being deposited
     * @param  _quantity        Amount of tokens to deposit
     */
    function depositModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

    /**
     * Exposes internal function that withdraws a quantity of tokens from the vault and
     * deattributes the tokens respectively, to system modules.
     *
     * @param  _from            Address to decredit for withdraw
     * @param  _to              Address to transfer tokens to
     * @param  _token           Address of token being withdrawn
     * @param  _quantity        Amount of tokens to withdraw
     */
    function withdrawModule(
        address _from,
        address _to,
        address _token,
        uint256 _quantity
    )
        external;

    /**
     * Exposes internal function that deposits multiple tokens to the vault, to system
     * modules. Quantities should be in the order of the addresses of the tokens being
     * deposited.
     *
     * @param  _from              Address to transfer tokens from
     * @param  _to                Address to credit for deposits
     * @param  _tokens            Array of the addresses of the tokens being deposited
     * @param  _quantities        Array of the amounts of tokens to deposit
     */
    function batchDepositModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

    /**
     * Exposes internal function that withdraws multiple tokens from the vault, to system
     * modules. Quantities should be in the order of the addresses of the tokens being withdrawn.
     *
     * @param  _from              Address to decredit for withdrawals
     * @param  _to                Address to transfer tokens to
     * @param  _tokens            Array of the addresses of the tokens being withdrawn
     * @param  _quantities        Array of the amounts of tokens to withdraw
     */
    function batchWithdrawModule(
        address _from,
        address _to,
        address[] calldata _tokens,
        uint256[] calldata _quantities
    )
        external;

    /**
     * Expose internal function that exchanges components for Set tokens,
     * accepting any owner, to system modules
     *
     * @param  _owner        Address to use tokens from
     * @param  _recipient    Address to issue Set to
     * @param  _set          Address of the Set to issue
     * @param  _quantity     Number of tokens to issue
     */
    function issueModule(
        address _owner,
        address _recipient,
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Expose internal function that exchanges Set tokens for components,
     * accepting any owner, to system modules
     *
     * @param  _burnAddress         Address to burn token from
     * @param  _incrementAddress    Address to increment component tokens to
     * @param  _set                 Address of the Set to redeem
     * @param  _quantity            Number of tokens to redeem
     */
    function redeemModule(
        address _burnAddress,
        address _incrementAddress,
        address _set,
        uint256 _quantity
    )
        external;

    /**
     * Expose vault function that increments user's balance in the vault.
     * Available to system modules
     *
     * @param  _tokens          The addresses of the ERC20 tokens
     * @param  _owner           The address of the token owner
     * @param  _quantities      The numbers of tokens to attribute to owner
     */
    function batchIncrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

    /**
     * Expose vault function that decrement user's balance in the vault
     * Only available to system modules.
     *
     * @param  _tokens          The addresses of the ERC20 tokens
     * @param  _owner           The address of the token owner
     * @param  _quantities      The numbers of tokens to attribute to owner
     */
    function batchDecrementTokenOwnerModule(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

    /**
     * Expose vault function that transfer vault balances between users
     * Only available to system modules.
     *
     * @param  _tokens           Addresses of tokens being transferred
     * @param  _from             Address tokens being transferred from
     * @param  _to               Address tokens being transferred to
     * @param  _quantities       Amounts of tokens being transferred
     */
    function batchTransferBalanceModule(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;

    /**
     * Transfers token from one address to another using the transfer proxy.
     * Only available to system modules.
     *
     * @param  _token          The address of the ERC20 token
     * @param  _quantity       The number of tokens to transfer
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     */
    function transferModule(
        address _token,
        uint256 _quantity,
        address _from,
        address _to
    )
        external;

    /**
     * Expose transfer proxy function to transfer tokens from one address to another
     * Only available to system modules.
     *
     * @param  _tokens         The addresses of the ERC20 token
     * @param  _quantities     The numbers of tokens to transfer
     * @param  _from           The address to transfer from
     * @param  _to             The address to transfer to
     */
    function batchTransferModule(
        address[] calldata _tokens,
        uint256[] calldata _quantities,
        address _from,
        address _to
    )
        external;
}

// File: contracts/core/interfaces/IFeeCalculator.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;

/**
 * @title IFeeCalculator
 * @author Set Protocol
 *
 */
interface IFeeCalculator {

    /* ============ External Functions ============ */

    function initialize(
        bytes calldata _feeCalculatorData
    )
        external;

    function getFee()
        external
        view
        returns(uint256);

    function updateAndGetFee()
        external
        returns(uint256);

    function adjustFee(
        bytes calldata _newFeeData
    )
        external;
}

// File: contracts/core/interfaces/ISetToken.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * The ISetToken interface provides a light-weight, structured way to interact with the
 * SetToken contract from another contract.
 */
interface ISetToken {

    /* ============ External Functions ============ */

    /*
     * Get natural unit of Set
     *
     * @return  uint256       Natural unit of Set
     */
    function naturalUnit()
        external
        view
        returns (uint256);

    /*
     * Get addresses of all components in the Set
     *
     * @return  componentAddresses       Array of component tokens
     */
    function getComponents()
        external
        view
        returns (address[] memory);

    /*
     * Get units of all tokens in Set
     *
     * @return  units       Array of component units
     */
    function getUnits()
        external
        view
        returns (uint256[] memory);

    /*
     * Checks to make sure token is component of Set
     *
     * @param  _tokenAddress     Address of token being checked
     * @return  bool             True if token is component of Set
     */
    function tokenIsComponent(
        address _tokenAddress
    )
        external
        view
        returns (bool);

    /*
     * Mint set token for given address.
     * Can only be called by authorized contracts.
     *
     * @param  _issuer      The address of the issuing account
     * @param  _quantity    The number of sets to attribute to issuer
     */
    function mint(
        address _issuer,
        uint256 _quantity
    )
        external;

    /*
     * Burn set token for given address
     * Can only be called by authorized contracts
     *
     * @param  _from        The address of the redeeming account
     * @param  _quantity    The number of sets to burn from redeemer
     */
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

    /**
    * Transfer token for a specified address
    *
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(
        address to,
        uint256 value
    )
        external;
}

// File: contracts/core/interfaces/IRebalancingSetToken.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;
pragma experimental "ABIEncoderV2";


/**
 * @title IRebalancingSetToken
 * @author Set Protocol
 *
 * The IRebalancingSetToken interface provides a light-weight, structured way to interact with the
 * RebalancingSetToken contract from another contract.
 */

interface IRebalancingSetToken {

    /*
     * Get the auction library contract used for the current rebalance
     *
     * @return address    Address of auction library used in the upcoming auction
     */
    function auctionLibrary()
        external
        view
        returns (address);

    /*
     * Get totalSupply of Rebalancing Set
     *
     * @return  totalSupply
     */
    function totalSupply()
        external
        view
        returns (uint256);

    /*
     * Get proposalTimeStamp of Rebalancing Set
     *
     * @return  proposalTimeStamp
     */
    function proposalStartTime()
        external
        view
        returns (uint256);

    /*
     * Get lastRebalanceTimestamp of Rebalancing Set
     *
     * @return  lastRebalanceTimestamp
     */
    function lastRebalanceTimestamp()
        external
        view
        returns (uint256);

    /*
     * Get rebalanceInterval of Rebalancing Set
     *
     * @return  rebalanceInterval
     */
    function rebalanceInterval()
        external
        view
        returns (uint256);

    /*
     * Get rebalanceState of Rebalancing Set
     *
     * @return RebalancingLibrary.State    Current rebalance state of the RebalancingSetToken
     */
    function rebalanceState()
        external
        view
        returns (RebalancingLibrary.State);

    /*
     * Get the starting amount of current SetToken for the current auction
     *
     * @return  rebalanceState
     */
    function startingCurrentSetAmount()
        external
        view
        returns (uint256);

    /**
     * Gets the balance of the specified address.
     *
     * @param owner      The address to query the balance of.
     * @return           A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(
        address owner
    )
        external
        view
        returns (uint256);

    /**
     * Function used to set the terms of the next rebalance and start the proposal period
     *
     * @param _nextSet                      The Set to rebalance into
     * @param _auctionLibrary               The library used to calculate the Dutch Auction price
     * @param _auctionTimeToPivot           The amount of time for the auction to go ffrom start to pivot price
     * @param _auctionStartPrice            The price to start the auction at
     * @param _auctionPivotPrice            The price at which the price curve switches from linear to exponential
     */
    function propose(
        address _nextSet,
        address _auctionLibrary,
        uint256 _auctionTimeToPivot,
        uint256 _auctionStartPrice,
        uint256 _auctionPivotPrice
    )
        external;

    /*
     * Get natural unit of Set
     *
     * @return  uint256       Natural unit of Set
     */
    function naturalUnit()
        external
        view
        returns (uint256);

    /**
     * Returns the address of the current base SetToken with the current allocation
     *
     * @return           A address representing the base SetToken
     */
    function currentSet()
        external
        view
        returns (address);

    /**
     * Returns the address of the next base SetToken with the post auction allocation
     *
     * @return  address    Address representing the base SetToken
     */
    function nextSet()
        external
        view
        returns (address);

    /*
     * Get the unit shares of the rebalancing Set
     *
     * @return  unitShares       Unit Shares of the base Set
     */
    function unitShares()
        external
        view
        returns (uint256);

    /*
     * Burn set token for given address.
     * Can only be called by authorized contracts.
     *
     * @param  _from        The address of the redeeming account
     * @param  _quantity    The number of sets to burn from redeemer
     */
    function burn(
        address _from,
        uint256 _quantity
    )
        external;

    /*
     * Place bid during rebalance auction. Can only be called by Core.
     *
     * @param _quantity                 The amount of currentSet to be rebalanced
     * @return combinedTokenArray       Array of token addresses invovled in rebalancing
     * @return inflowUnitArray          Array of amount of tokens inserted into system in bid
     * @return outflowUnitArray         Array of amount of tokens taken out of system in bid
     */
    function placeBid(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory);

    /*
     * Get combinedTokenArray of Rebalancing Set
     *
     * @return  combinedTokenArray
     */
    function getCombinedTokenArrayLength()
        external
        view
        returns (uint256);

    /*
     * Get combinedTokenArray of Rebalancing Set
     *
     * @return  combinedTokenArray
     */
    function getCombinedTokenArray()
        external
        view
        returns (address[] memory);

    /*
     * Get failedAuctionWithdrawComponents of Rebalancing Set
     *
     * @return  failedAuctionWithdrawComponents
     */
    function getFailedAuctionWithdrawComponents()
        external
        view
        returns (address[] memory);

    /*
     * Get auctionPriceParameters for current auction
     *
     * @return uint256[4]    AuctionPriceParameters for current rebalance auction
     */
    function getAuctionPriceParameters()
        external
        view
        returns (uint256[] memory);

    /*
     * Get biddingParameters for current auction
     *
     * @return uint256[2]    BiddingParameters for current rebalance auction
     */
    function getBiddingParameters()
        external
        view
        returns (uint256[] memory);

    /*
     * Get token inflows and outflows required for bid. Also the amount of Rebalancing
     * Sets that would be generated.
     *
     * @param _quantity               The amount of currentSet to be rebalanced
     * @return inflowUnitArray        Array of amount of tokens inserted into system in bid
     * @return outflowUnitArray       Array of amount of tokens taken out of system in bid
     */
    function getBidPrice(
        uint256 _quantity
    )
        external
        view
        returns (uint256[] memory, uint256[] memory);

}

// File: contracts/core/lib/Rebalance.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;



/**
 * @title Rebalance
 * @author Set Protocol
 *
 * Types and functions for Rebalance-related data.
 */
library Rebalance {

    struct TokenFlow {
        address[] addresses;
        uint256[] inflow;
        uint256[] outflow;
    }

    function composeTokenFlow(
        address[] memory _addresses,
        uint256[] memory _inflow,
        uint256[] memory _outflow
    )
        internal
        pure
        returns(TokenFlow memory)
    {
        return TokenFlow({addresses: _addresses, inflow: _inflow, outflow: _outflow });
    }

    function decomposeTokenFlow(TokenFlow memory _tokenFlow)
        internal
        pure
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {
        return (_tokenFlow.addresses, _tokenFlow.inflow, _tokenFlow.outflow);
    }

    function decomposeTokenFlowToBidPrice(TokenFlow memory _tokenFlow)
        internal
        pure
        returns (uint256[] memory, uint256[] memory)
    {
        return (_tokenFlow.inflow, _tokenFlow.outflow);
    }

    /**
     * Get token flows array of addresses, inflows and outflows
     *
     * @param    _rebalancingSetToken   The rebalancing Set Token instance
     * @param    _quantity              The amount of currentSet to be rebalanced
     * @return   combinedTokenArray     Array of token addresses
     * @return   inflowArray            Array of amount of tokens inserted into system in bid
     * @return   outflowArray           Array of amount of tokens returned from system in bid
     */
    function getTokenFlows(
        IRebalancingSetToken _rebalancingSetToken,
        uint256 _quantity
    )
        internal
        view
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {
        // Get token addresses
        address[] memory combinedTokenArray = _rebalancingSetToken.getCombinedTokenArray();

        // Get inflow and outflow arrays for the given bid quantity
        (
            uint256[] memory inflowArray,
            uint256[] memory outflowArray
        ) = _rebalancingSetToken.getBidPrice(_quantity);

        return (combinedTokenArray, inflowArray, outflowArray);
    }
}

// File: contracts/core/interfaces/ILiquidator.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;




/**
 * @title ILiquidator
 * @author Set Protocol
 *
 */
interface ILiquidator {

    /* ============ External Functions ============ */

    function startRebalance(
        ISetToken _currentSet,
        ISetToken _nextSet,
        uint256 _startingCurrentSetQuantity,
        bytes calldata _liquidatorData
    )
        external;

    function getBidPrice(
        address _set,
        uint256 _quantity
    )
        external
        view
        returns (Rebalance.TokenFlow memory);

    function placeBid(
        uint256 _quantity
    )
        external
        returns (Rebalance.TokenFlow memory);


    function settleRebalance()
        external;

    function endFailedRebalance() external;

    // ----------------------------------------------------------------------
    // Auction Price
    // ----------------------------------------------------------------------

    function auctionPriceParameters(address _set)
        external
        view
        returns (RebalancingLibrary.AuctionPriceParameters memory);

    // ----------------------------------------------------------------------
    // Auction
    // ----------------------------------------------------------------------

    function hasRebalanceFailed(address _set) external view returns (bool);
    function minimumBid(address _set) external view returns (uint256);
    function startingCurrentSets(address _set) external view returns (uint256);
    function remainingCurrentSets(address _set) external view returns (uint256);
    function getCombinedCurrentSetUnits(address _set) external view returns (uint256[] memory);
    function getCombinedNextSetUnits(address _set) external view returns (uint256[] memory);
    function getCombinedTokenArray(address _set) external view returns (address[] memory);
}

// File: contracts/core/interfaces/ISetFactory.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;


/**
 * @title ISetFactory
 * @author Set Protocol
 *
 * The ISetFactory interface provides operability for authorized contracts
 * to interact with SetTokenFactory
 */
interface ISetFactory {

    /* ============ External Functions ============ */

    /**
     * Return core address
     *
     * @return address        core address
     */
    function core()
        external
        returns (address);

    /**
     * Deploys a new Set Token and adds it to the valid list of SetTokens
     *
     * @param  _components           The address of component tokens
     * @param  _units                The units of each component token
     * @param  _naturalUnit          The minimum unit to be issued or redeemed
     * @param  _name                 The bytes32 encoded name of the new Set
     * @param  _symbol               The bytes32 encoded symbol of the new Set
     * @param  _callData             Byte string containing additional call parameters
     * @return setTokenAddress       The address of the new Set
     */
    function createSet(
        address[] calldata _components,
        uint[] calldata _units,
        uint256 _naturalUnit,
        bytes32 _name,
        bytes32 _symbol,
        bytes calldata _callData
    )
        external
        returns (address);
}

// File: contracts/core/interfaces/IWhiteList.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;

/**
 * @title IWhiteList
 * @author Set Protocol
 *
 * The IWhiteList interface exposes the whitelist mapping to check components
 */
interface IWhiteList {

    /* ============ External Functions ============ */

    /**
     * Validates address against white list
     *
     * @param  _address       Address to check
     * @return bool           Whether passed in address is whitelisted
     */
    function whiteList(
        address _address
    )
        external
        view
        returns (bool);

    /**
     * Verifies an array of addresses against the whitelist
     *
     * @param  _addresses    Array of addresses to verify
     * @return bool          Whether all addresses in the list are whitelsited
     */
    function areValidAddresses(
        address[] calldata _addresses
    )
        external
        view
        returns (bool);
}

// File: contracts/core/interfaces/IRebalancingSetFactory.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;




/**
 * @title IRebalancingSetFactory
 * @author Set Protocol
 *
 * The IRebalancingSetFactory interface provides operability for authorized contracts
 * to interact with RebalancingSetTokenFactory
 */
contract IRebalancingSetFactory is
    ISetFactory
{
    /**
     * Getter for minimumRebalanceInterval of RebalancingSetTokenFactory, used
     * to enforce rebalanceInterval when creating a RebalancingSetToken
     *
     * @return uint256    Minimum amount of time between rebalances in seconds
     */
    function minimumRebalanceInterval()
        external
        returns (uint256);

    /**
     * Getter for minimumProposalPeriod of RebalancingSetTokenFactory, used
     * to enforce proposalPeriod when creating a RebalancingSetToken
     *
     * @return uint256    Minimum amount of time users can review proposals in seconds
     */
    function minimumProposalPeriod()
        external
        returns (uint256);

    /**
     * Getter for minimumTimeToPivot of RebalancingSetTokenFactory, used
     * to enforce auctionTimeToPivot when proposing a rebalance
     *
     * @return uint256    Minimum amount of time before auction pivot reached
     */
    function minimumTimeToPivot()
        external
        returns (uint256);

    /**
     * Getter for maximumTimeToPivot of RebalancingSetTokenFactory, used
     * to enforce auctionTimeToPivot when proposing a rebalance
     *
     * @return uint256    Maximum amount of time before auction pivot reached
     */
    function maximumTimeToPivot()
        external
        returns (uint256);

    /**
     * Getter for minimumNaturalUnit of RebalancingSetTokenFactory
     *
     * @return uint256    Minimum natural unit
     */
    function minimumNaturalUnit()
        external
        returns (uint256);

    /**
     * Getter for maximumNaturalUnit of RebalancingSetTokenFactory
     *
     * @return uint256    Maximum Minimum natural unit
     */
    function maximumNaturalUnit()
        external
        returns (uint256);

    /**
     * Getter for rebalanceAuctionModule address on RebalancingSetTokenFactory
     *
     * @return address      Address of rebalanceAuctionModule
     */
    function rebalanceAuctionModule()
        external
        returns (address);
}

// File: contracts/core/interfaces/IVault.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;

/**
 * @title IVault
 * @author Set Protocol
 *
 * The IVault interface provides a light-weight, structured way to interact with the Vault
 * contract from another contract.
 */
interface IVault {

    /*
     * Withdraws user's unassociated tokens to user account. Can only be
     * called by authorized core contracts.
     *
     * @param  _token          The address of the ERC20 token
     * @param  _to             The address to transfer token to
     * @param  _quantity       The number of tokens to transfer
     */
    function withdrawTo(
        address _token,
        address _to,
        uint256 _quantity
    )
        external;

    /*
     * Increment quantity owned of a token for a given address. Can
     * only be called by authorized core contracts.
     *
     * @param  _token           The address of the ERC20 token
     * @param  _owner           The address of the token owner
     * @param  _quantity        The number of tokens to attribute to owner
     */
    function incrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;

    /*
     * Decrement quantity owned of a token for a given address. Can only
     * be called by authorized core contracts.
     *
     * @param  _token           The address of the ERC20 token
     * @param  _owner           The address of the token owner
     * @param  _quantity        The number of tokens to deattribute to owner
     */
    function decrementTokenOwner(
        address _token,
        address _owner,
        uint256 _quantity
    )
        external;

    /**
     * Transfers tokens associated with one account to another account in the vault
     *
     * @param  _token          Address of token being transferred
     * @param  _from           Address token being transferred from
     * @param  _to             Address token being transferred to
     * @param  _quantity       Amount of tokens being transferred
     */

    function transferBalance(
        address _token,
        address _from,
        address _to,
        uint256 _quantity
    )
        external;


    /*
     * Withdraws user's unassociated tokens to user account. Can only be
     * called by authorized core contracts.
     *
     * @param  _tokens          The addresses of the ERC20 tokens
     * @param  _owner           The address of the token owner
     * @param  _quantities      The numbers of tokens to attribute to owner
     */
    function batchWithdrawTo(
        address[] calldata _tokens,
        address _to,
        uint256[] calldata _quantities
    )
        external;

    /*
     * Increment quantites owned of a collection of tokens for a given address. Can
     * only be called by authorized core contracts.
     *
     * @param  _tokens          The addresses of the ERC20 tokens
     * @param  _owner           The address of the token owner
     * @param  _quantities      The numbers of tokens to attribute to owner
     */
    function batchIncrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

    /*
     * Decrements quantites owned of a collection of tokens for a given address. Can
     * only be called by authorized core contracts.
     *
     * @param  _tokens          The addresses of the ERC20 tokens
     * @param  _owner           The address of the token owner
     * @param  _quantities      The numbers of tokens to attribute to owner
     */
    function batchDecrementTokenOwner(
        address[] calldata _tokens,
        address _owner,
        uint256[] calldata _quantities
    )
        external;

   /**
     * Transfers tokens associated with one account to another account in the vault
     *
     * @param  _tokens           Addresses of tokens being transferred
     * @param  _from             Address tokens being transferred from
     * @param  _to               Address tokens being transferred to
     * @param  _quantities       Amounts of tokens being transferred
     */
    function batchTransferBalance(
        address[] calldata _tokens,
        address _from,
        address _to,
        uint256[] calldata _quantities
    )
        external;

    /*
     * Get balance of particular contract for owner.
     *
     * @param  _token    The address of the ERC20 token
     * @param  _owner    The address of the token owner
     */
    function getOwnerBalance(
        address _token,
        address _owner
    )
        external
        view
        returns (uint256);
}

// File: contracts/lib/ScaleValidations.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;



library ScaleValidations {
    using SafeMath for uint256;

    uint256 private constant ONE_HUNDRED_PERCENT = 1e18;
    uint256 private constant ONE_BASIS_POINT = 1e14;

    function validateLessThanEqualOneHundredPercent(uint256 _value) internal view {
        require(_value <= ONE_HUNDRED_PERCENT, "Must be <= 100%");
    }

    function validateMultipleOfBasisPoint(uint256 _value) internal view {
        require(
            _value.mod(ONE_BASIS_POINT) == 0,
            "Must be multiple of 0.01%"
        );
    }
}

// File: contracts/core/tokens/rebalancing-v2/RebalancingSetState.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;











/**
 * @title RebalancingSetState
 * @author Set Protocol
 *
 */
contract RebalancingSetState {

    /* ============ State Variables ============ */

    // ----------------------------------------------------------------------
    // System Related
    // ----------------------------------------------------------------------

    // Set Protocol's Core Contract
    ICore public core;

    // The Factory that created this Set
    IRebalancingSetFactory public factory;

    // Set Protocol's Vault contract
    IVault public vault;

    // The token whitelist that components are checked against during proposals
    IWhiteList public componentWhiteList;

    // WhiteList of liquidator contracts
    IWhiteList public liquidatorWhiteList;

    // Contract holding the state and logic required for rebalance liquidation
    // The Liquidator interacts closely with the Set during rebalances.
    ILiquidator public liquidator;

    // Contract responsible for calculation of rebalance fees
    IFeeCalculator public rebalanceFeeCalculator;

    // The account that is allowed to make proposals
    address public manager;

    // The account that receives any fees
    address public feeRecipient;

    // ----------------------------------------------------------------------
    // Configuration
    // ----------------------------------------------------------------------

    // Time in seconds that must elapsed from last rebalance to propose
    uint256 public rebalanceInterval;

    // Time in seconds after rebalanceStartTime before the Set believes the auction has failed
    uint256 public rebalanceFailPeriod;

    // Fee levied to feeRecipient every mint operation, paid during minting
    // Represents a decimal value scaled by 1e18 (e.g. 100% = 1e18 and 1% = 1e16)
    uint256 public entryFee;

    // ----------------------------------------------------------------------
    // Current State
    // ----------------------------------------------------------------------

    // The Set currently collateralizing the Rebalancing Set
    ISetToken public currentSet;

    // The number of currentSet per naturalUnit of the Rebalancing Set
    uint256 public unitShares;

    // The minimum issuable value of a Set
    uint256 public naturalUnit;

    // The current state of the Set (e.g. Default, Proposal, Rebalance, Drawdown)
    // Proposal is unused
    RebalancingLibrary.State public rebalanceState;

    // The number of rebalances in the Set's history; starts at index 0
    uint256 public rebalanceIndex;

    // The timestamp of the last completed rebalance
    uint256 public lastRebalanceTimestamp;

    // ----------------------------------------------------------------------
    // Live Rebalance State
    // ----------------------------------------------------------------------

    // The proposal's SetToken to rebalance into
    ISetToken public nextSet;

    // The timestamp of the last rebalance was initiated at
    uint256 public rebalanceStartTime;

    // Whether a successful bid has been made during the rebalance.
    // In the case that the rebalance has failed, hasBidded is used
    // to determine whether the Set should be put into Drawdown or Default state.
    bool public hasBidded;

    // In the event a Set is put into the Drawdown state, these components
    // that can be withdrawn by users
    address[] internal failedRebalanceComponents;

    /* ============ Modifier ============ */

    modifier onlyManager() {
        validateManager();
        _;
    }

    /* ============ Events ============ */

    event NewManagerAdded(
        address newManager,
        address oldManager
    );

    event NewLiquidatorAdded(
        address newLiquidator,
        address oldLiquidator
    );

    event NewEntryFee(
        uint256 newEntryFee,
        uint256 oldEntryFee
    );

    event NewFeeRecipient(
        address newFeeRecipient,
        address oldFeeRecipient
    );

    event EntryFeePaid(
        address indexed feeRecipient,
        uint256 feeQuantity
    );

    event RebalanceStarted(
        address oldSet,
        address newSet,
        uint256 rebalanceIndex,
        uint256 currentSetQuantity
    );

    event RebalanceSettled(
        address indexed feeRecipient,
        uint256 feeQuantity,
        uint256 feePercentage,
        uint256 rebalanceIndex,
        uint256 issueQuantity,
        uint256 unitShares
    );

    /* ============ Setter Functions ============ */

    /*
     * Set new manager address.
     */
    function setManager(
        address _newManager
    )
        external
        onlyManager
    {
        emit NewManagerAdded(_newManager, manager);
        manager = _newManager;
    }

    function setEntryFee(
        uint256 _newEntryFee
    )
        external
        onlyManager
    {
        ScaleValidations.validateLessThanEqualOneHundredPercent(_newEntryFee);

        ScaleValidations.validateMultipleOfBasisPoint(_newEntryFee);

        emit NewEntryFee(_newEntryFee, entryFee);
        entryFee = _newEntryFee;
    }

    /*
     * Set new liquidator address. Only whitelisted addresses are valid.
     */
    function setLiquidator(
        ILiquidator _newLiquidator
    )
        external
        onlyManager
    {
        require(
            rebalanceState != RebalancingLibrary.State.Rebalance,
            "Invalid state"
        );

        require(
            liquidatorWhiteList.whiteList(address(_newLiquidator)),
            "Not whitelisted"
        );

        emit NewLiquidatorAdded(address(_newLiquidator), address(liquidator));
        liquidator = _newLiquidator;
    }

    function setFeeRecipient(
        address _newFeeRecipient
    )
        external
        onlyManager
    {
        emit NewFeeRecipient(_newFeeRecipient, feeRecipient);
        feeRecipient = _newFeeRecipient;
    }

    /* ============ Getter Functions ============ */

    /*
     * Retrieves the current expected fee from the fee calculator
     * Value is returned as a scale decimal figure.
     */
    function rebalanceFee()
        external
        view
        returns (uint256)
    {
        return rebalanceFeeCalculator.getFee();
    }

    /*
     * Function for compatability with ISetToken interface. Returns currentSet.
     */
    function getComponents()
        external
        view
        returns (address[] memory)
    {
        address[] memory components = new address[](1);
        components[0] = address(currentSet);
        return components;
    }

    /*
     * Function for compatability with ISetToken interface. Returns unitShares.
     */
    function getUnits()
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory units = new uint256[](1);
        units[0] = unitShares;
        return units;
    }

    /*
     * Returns whether the address is the current set of the RebalancingSetToken.
     * Conforms to the ISetToken Interface.
     */
    function tokenIsComponent(
        address _tokenAddress
    )
        external
        view
        returns (bool)
    {
        return _tokenAddress == address(currentSet);
    }

    /* ============ Validations ============ */
    function validateManager() internal view {
        require(
            msg.sender == manager,
            "Not manager"
        );
    }

    function validateCallerIsCore() internal view {
        require(
            msg.sender == address(core),
            "Not Core"
        );
    }

    function validateCallerIsModule() internal view {
        require(
            core.validModules(msg.sender),
            "Not approved module"
        );
    }

    function validateRebalanceStateIs(RebalancingLibrary.State _requiredState) internal view {
        require(
            rebalanceState == _requiredState,
            "Invalid state"
        );
    }

    function validateRebalanceStateIsNot(RebalancingLibrary.State _requiredState) internal view {
        require(
            rebalanceState != _requiredState,
            "Invalid state"
        );
    }
}

// File: contracts/core/tokens/rebalancing-v3/IncentiveFee.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;







/**
 * @title IncentiveFee
 * @author Set Protocol
 */
contract IncentiveFee is
    ERC20,
    RebalancingSetState
{
    using SafeMath for uint256;
    using CommonMath for uint256;

    /* ============ Events ============ */

    event IncentiveFeePaid(
        address indexed feeRecipient,
        uint256 feeQuantity,
        uint256 feePercentage,
        uint256 newUnitShares
    );

    /* ============ Internal Functions ============ */

    /**
     * Calculates the fee and mints the rebalancing SetToken quantity to the recipient.
     * The minting is done without an increase to the total collateral controlled by the
     * rebalancing SetToken. In effect, the existing holders are paying the fee via inflation.
     *
     * @return feePercentage
     * @return feeQuantity
     */
    function handleFees()
        internal
        returns (uint256, uint256)
    {
        // Represents a decimal value scaled by 1e18 (e.g. 100% = 1e18 and 1% = 1e16)
        uint256 feePercent = rebalanceFeeCalculator.updateAndGetFee();
        uint256 feeQuantity = calculateIncentiveFeeInflation(feePercent);

        if (feeQuantity > 0) {
            ERC20._mint(feeRecipient, feeQuantity);
        }

        return (feePercent, feeQuantity);
    }

    /**
     * Returns the new incentive fee. The calculation for the fee involves implying
     * mint quantity so that the feeRecipient owns the fee percentage of the entire
     * supply of the Set.
     *
     * The formula to solve for fee is:
     * feeQuantity / feeQuantity + totalSupply = fee / scaleFactor
     *
     * The simplified formula utilized below is:
     * feeQuantity = fee * totalSupply / (scaleFactor - fee)
     *
     * @param   _feePercentage          Fee levied to feeRecipient
     * @return  uint256                 New RebalancingSet issue quantity
     */
    function calculateIncentiveFeeInflation(
        uint256 _feePercentage
    )
        internal
        view
        returns(uint256)
    {
        // fee * totalSupply
        uint256 a = _feePercentage.mul(totalSupply());

        // ScaleFactor (10e18) - fee
        uint256 b = CommonMath.scaleFactor().sub(_feePercentage);

        return a.div(b);
    }

    /*
     * The Rebalancing SetToken must be in Default state.
     */
    function validateFeeActualization() internal view {
        validateRebalanceStateIs(RebalancingLibrary.State.Default);
    }

    /*
     * After the minting of new inflation fees, the unit shares must be updated.
     * The formula is as follows:
     * newUnitShares = currentSetAmount * rebalanceSetNaturalUnit / rebalanceSetTotalSupply
     */
    function calculateNewUnitShares() internal view returns(uint256) {
        uint256 currentSetAmount = vault.getOwnerBalance(
            address(currentSet),
            address(this)
        );

        return currentSetAmount.mul(naturalUnit).divCeil(totalSupply());
    }
}

// File: openzeppelin-solidity/contracts/math/Math.sol

pragma solidity ^0.5.2;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Calculates the average of two numbers. Since these are integers,
     * averages of an even and odd number cannot be represented, and will be
     * rounded down.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// File: contracts/core/lib/SetTokenLibrary.sol

/*
    Copyright 2018 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;





library SetTokenLibrary {
    using SafeMath for uint256;

    struct SetDetails {
        uint256 naturalUnit;
        address[] components;
        uint256[] units;
    }

    /**
     * Validates that passed in tokens are all components of the Set
     *
     * @param _set                      Address of the Set
     * @param _tokens                   List of tokens to check
     */
    function validateTokensAreComponents(
        address _set,
        address[] calldata _tokens
    )
        external
        view
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            // Make sure all tokens are members of the Set
            require(
                ISetToken(_set).tokenIsComponent(_tokens[i]),
                "SetTokenLibrary.validateTokensAreComponents: Component must be a member of Set"
            );

        }
    }

    /**
     * Validates that passed in quantity is a multiple of the natural unit of the Set.
     *
     * @param _set                      Address of the Set
     * @param _quantity                 Quantity to validate
     */
    function isMultipleOfSetNaturalUnit(
        address _set,
        uint256 _quantity
    )
        external
        view
    {
        require(
            _quantity.mod(ISetToken(_set).naturalUnit()) == 0,
            "SetTokenLibrary.isMultipleOfSetNaturalUnit: Quantity is not a multiple of nat unit"
        );
    }

    /**
     * Validates that passed in quantity is a multiple of the natural unit of the Set.
     *
     * @param _core                     Address of Core
     * @param _set                      Address of the Set
     */
    function requireValidSet(
        ICore _core,
        address _set
    )
        internal
        view
    {
        require(
            _core.validSets(_set),
            "SetTokenLibrary: Must be an approved SetToken address"
        );
    }

    /**
     * Retrieves the Set's natural unit, components, and units.
     *
     * @param _set                      Address of the Set
     * @return SetDetails               Struct containing the natural unit, components, and units
     */
    function getSetDetails(
        address _set
    )
        internal
        view
        returns (SetDetails memory)
    {
        // Declare interface variables
        ISetToken setToken = ISetToken(_set);

        // Fetch set token properties
        uint256 naturalUnit = setToken.naturalUnit();
        address[] memory components = setToken.getComponents();
        uint256[] memory units = setToken.getUnits();

        return SetDetails({
            naturalUnit: naturalUnit,
            components: components,
            units: units
        });
    }
}

// File: contracts/core/tokens/rebalancing-v2/RebalancingSettlement.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;











/**
 * @title RebalancingSettlement
 * @author Set Protocol
 *
 */
contract RebalancingSettlement is
    ERC20,
    RebalancingSetState
{
    using SafeMath for uint256;

    uint256 public constant SCALE_FACTOR = 10 ** 18;

    /* ============ Internal Functions ============ */

    /*
     * Validates that the settle function can be called.
     */
    function validateRebalancingSettlement()
        internal
        view
    {
        validateRebalanceStateIs(RebalancingLibrary.State.Rebalance);
    }

    /*
     * Issue nextSet to RebalancingSetToken; The issued Set is held in the Vault
     *
     * @param  _issueQuantity   Quantity of next Set to issue
     */
    function issueNextSet(
        uint256 _issueQuantity
    )
        internal
    {
        core.issueInVault(
            address(nextSet),
            _issueQuantity
        );
    }

    /*
     * Updates state post-settlement.
     *
     * @param  _nextUnitShares   The new implied unit shares
     */
    function transitionToDefault(
        uint256 _newUnitShares
    )
        internal
    {
        rebalanceState = RebalancingLibrary.State.Default;
        lastRebalanceTimestamp = block.timestamp;
        currentSet = nextSet;
        unitShares = _newUnitShares;
        rebalanceIndex = rebalanceIndex.add(1);

        nextSet = ISetToken(address(0));
        hasBidded = false;
    }

    /**
     * Calculate the amount of Sets to issue by using the component amounts in the
     * vault.
     */
    function calculateSetIssueQuantity(
        ISetToken _setToken
    )
        internal
        view
        returns (uint256)
    {
        // Collect data necessary to compute issueAmounts
        SetTokenLibrary.SetDetails memory setToken = SetTokenLibrary.getSetDetails(address(_setToken));
        uint256 maxIssueAmount = calculateMaxIssueAmount(setToken);

        // Issue amount of Sets that is closest multiple of nextNaturalUnit to the maxIssueAmount
        uint256 issueAmount = maxIssueAmount.sub(maxIssueAmount.mod(setToken.naturalUnit));

        return issueAmount;
    }

    /**
     * Calculates the fee and mints the rebalancing SetToken quantity to the recipient.
     * The minting is done without an increase to the total collateral controlled by the
     * rebalancing SetToken. In effect, the existing holders are paying the fee via inflation.
     *
     * @return feePercentage
     * @return feeQuantity
     */
    function handleFees()
        internal
        returns (uint256, uint256)
    {
        // Represents a decimal value scaled by 1e18 (e.g. 100% = 1e18 and 1% = 1e16)
        uint256 feePercent = rebalanceFeeCalculator.getFee();
        uint256 feeQuantity = calculateRebalanceFeeInflation(feePercent);

        if (feeQuantity > 0) {
            ERC20._mint(feeRecipient, feeQuantity);
        }

        return (feePercent, feeQuantity);
    }

    /**
     * Returns the new rebalance fee. The calculation for the fee involves implying
     * mint quantity so that the feeRecipient owns the fee percentage of the entire
     * supply of the Set.
     *
     * The formula to solve for fee is:
     * feeQuantity / feeQuantity + totalSupply = fee / scaleFactor
     *
     * The simplified formula utilized below is:
     * feeQuantity = fee * totalSupply / (scaleFactor - fee)
     *
     * @param   _rebalanceFeePercent    Fee levied to feeRecipient every rebalance, paid during settlement
     * @return  uint256                 New RebalancingSet issue quantity
     */
    function calculateRebalanceFeeInflation(
        uint256 _rebalanceFeePercent
    )
        internal
        view
        returns(uint256)
    {
        // fee * totalSupply
        uint256 a = _rebalanceFeePercent.mul(totalSupply());

        // ScaleFactor (10e18) - fee
        uint256 b = SCALE_FACTOR.sub(_rebalanceFeePercent);

        return a.div(b);
    }

    /**
     * Calculates the new unitShares, defined as issueQuantity / naturalUnitsOutstanding
     *
     * @param  _issueQuantity   Amount of nextSets to issue
     *
     * @return  uint256             New unitShares for the rebalancingSetToken
     */
    function calculateNextSetNewUnitShares(
        uint256 _issueQuantity
    )
        internal
        view
        returns (uint256)
    {
        // Calculate the amount of naturalUnits worth of rebalancingSetToken outstanding.
        uint256 naturalUnitsOutstanding = totalSupply().div(naturalUnit);

        // Divide final issueAmount by naturalUnitsOutstanding to get newUnitShares
        return _issueQuantity.div(naturalUnitsOutstanding);
    }

    /* ============ Private Functions ============ */

    /**
     * Get the maximum possible issue amount of nextSet based on number of components owned by rebalancing
     * set token.
     *
     * @param  _setToken    Struct of Set Token details
     */
    function calculateMaxIssueAmount(
        SetTokenLibrary.SetDetails memory _setToken
    )
        private
        view
        returns (uint256)
    {
        uint256 maxIssueAmount = CommonMath.maxUInt256();

        for (uint256 i = 0; i < _setToken.components.length; i++) {
            // Get amount of components in vault owned by rebalancingSetToken
            uint256 componentAmount = vault.getOwnerBalance(
                _setToken.components[i],
                address(this)
            );

            // Calculate amount of Sets that can be issued from those components, if less than amount for other
            // components then set that as maxIssueAmount. We divide before multiplying so that we don't get
            // an amount that isn't a multiple of the naturalUnit
            uint256 componentIssueAmount = componentAmount.div(_setToken.units[i]).mul(_setToken.naturalUnit);
            if (componentIssueAmount < maxIssueAmount) {
                maxIssueAmount = componentIssueAmount;
            }
        }

        return maxIssueAmount;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.2;


/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: zos-lib/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.6.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: contracts/core/tokens/rebalancing-v2/BackwardCompatibility.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;




/**
 * @title BackwardCompatibility
 * @author Set Protocol
 *
 * This module allows full backwards compatability with RebalancingSetTokenV1. It implements
 * all the same getter functions to allow upstream applications to make minimized changes
 * to support the new version.
 *
 * The following interfaces are not included:
 * - propose(address, address, uint256, uint256, uint256): Implementation would have
 *.    been a revert.
 * - biddingParameters: RebalancingSetToken V1 biddingParameters reverts on call
 */
contract BackwardCompatibility is
    RebalancingSetState
{
    /* ============ Empty Variables ============ */

    // Deprecated auctionLibrary. Returns 0x00 to prevent reverts
    address public auctionLibrary;

    // Deprecated proposal period. Returns 0 to prevent reverts
    uint256 public proposalPeriod;

    // Deprecated proposal start time. Returns 0 to prevent reverts
    uint256 public proposalStartTime;

    /* ============ Getters ============ */

    function getAuctionPriceParameters() external view returns (uint256[] memory) {
        RebalancingLibrary.AuctionPriceParameters memory params = liquidator.auctionPriceParameters(
            address(this)
        );

        uint256[] memory auctionPriceParams = new uint256[](4);
        auctionPriceParams[0] = params.auctionStartTime;
        auctionPriceParams[1] = params.auctionTimeToPivot;
        auctionPriceParams[2] = params.auctionStartPrice;
        auctionPriceParams[3] = params.auctionPivotPrice;

        return auctionPriceParams;
    }

    function getCombinedCurrentUnits() external view returns (uint256[] memory) {
        return liquidator.getCombinedCurrentSetUnits(address(this));
    }

    function getCombinedNextSetUnits() external view returns (uint256[] memory) {
        return liquidator.getCombinedNextSetUnits(address(this));
    }

    function getCombinedTokenArray() external view returns (address[] memory) {
        return liquidator.getCombinedTokenArray(address(this));
    }

    function getCombinedTokenArrayLength() external view returns (uint256) {
        return liquidator.getCombinedTokenArray(address(this)).length;
    }

    function startingCurrentSetAmount() external view returns (uint256) {
        return liquidator.startingCurrentSets(address(this));
    }

    function auctionPriceParameters() external view
        returns (RebalancingLibrary.AuctionPriceParameters memory)
    {
        return liquidator.auctionPriceParameters(address(this));
    }

    /*
     * Since structs with arrays cannot be retrieved, we return
     * minimumBid and remainingCurrentSets separately.
     *
     * @return  biddingParams       Array with minimumBid and remainingCurrentSets
     */
    function getBiddingParameters() public view returns (uint256[] memory) {
        uint256[] memory biddingParams = new uint256[](2);
        biddingParams[0] = liquidator.minimumBid(address(this));
        biddingParams[1] = liquidator.remainingCurrentSets(address(this));
        return biddingParams;
    }

    function biddingParameters()
        external
        view
        returns (uint256, uint256)
    {
        uint256[] memory biddingParams = getBiddingParameters();
        return (biddingParams[0], biddingParams[1]);
    }

    function getFailedAuctionWithdrawComponents() external view returns (address[] memory) {
        return failedRebalanceComponents;
    }
}

// File: contracts/lib/AddressArrayUtils.sol

// Pulled in from Cryptofin Solidity package in order to control Solidity compiler version
// https://github.com/cryptofinlabs/cryptofin-solidity/blob/master/contracts/array-utils/AddressArrayUtils.sol

pragma solidity 0.5.7;


library AddressArrayUtils {

    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (0, false);
    }

    /**
    * Returns true if the value is present in the list. Uses indexOf internally.
    * @param A The input array to search
    * @param a The value to find
    * @return Returns isIn for the first occurrence starting from index 0
    */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        bool isIn;
        (, isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /**
     * Returns the array with a appended to A.
     * @param A The first array
     * @param a The value to append
     * @return Returns A appended by a
     */
    function append(address[] memory A, address a) internal pure returns (address[] memory) {
        address[] memory newAddresses = new address[](A.length + 1);
        for (uint256 i = 0; i < A.length; i++) {
            newAddresses[i] = A[i];
        }
        newAddresses[A.length] = a;
        return newAddresses;
    }

    /**
     * Returns the intersection of two arrays. Arrays are treated as collections, so duplicates are kept.
     * @param A The first array
     * @param B The second array
     * @return The intersection of the two arrays
     */
    function intersect(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 newLength = 0;
        for (uint256 i = 0; i < length; i++) {
            if (contains(B, A[i])) {
                includeMap[i] = true;
                newLength++;
            }
        }
        address[] memory newAddresses = new address[](newLength);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

    /**
     * Returns the union of the two arrays. Order is not guaranteed.
     * @param A The first array
     * @param B The second array
     * @return The union of the two arrays
     */
    function union(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        address[] memory leftDifference = difference(A, B);
        address[] memory rightDifference = difference(B, A);
        address[] memory intersection = intersect(A, B);
        return extend(leftDifference, extend(intersection, rightDifference));
    }

    /**
     * Computes the difference of two arrays. Assumes there are no duplicates.
     * @param A The first array
     * @param B The second array
     * @return The difference of the two arrays
     */
    function difference(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 length = A.length;
        bool[] memory includeMap = new bool[](length);
        uint256 count = 0;
        // First count the new length because can't push for in-memory arrays
        for (uint256 i = 0; i < length; i++) {
            address e = A[i];
            if (!contains(B, e)) {
                includeMap[i] = true;
                count++;
            }
        }
        address[] memory newAddresses = new address[](count);
        uint256 j = 0;
        for (uint256 k = 0; k < length; k++) {
            if (includeMap[k]) {
                newAddresses[j] = A[k];
                j++;
            }
        }
        return newAddresses;
    }

    /**
    * Removes specified index from array
    * Resulting ordering is not guaranteed
    * @return Returns the new array and the removed entry
    */
    function pop(address[] memory A, uint256 index)
        internal
        pure
        returns (address[] memory, address)
    {
        uint256 length = A.length;
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * @return Returns the new array
     */
    function remove(address[] memory A, address a)
        internal
        pure
        returns (address[] memory)
    {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert();
        } else {
            (address[] memory _A,) = pop(A, index);
            return _A;
        }
    }

    /**
     * Returns whether or not there's a duplicate. Runs in O(n^2).
     * @param A Array to search
     * @return Returns true if duplicate, false otherwise
     */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        if (A.length == 0) {
            return false;
        }
        for (uint256 i = 0; i < A.length - 1; i++) {
            for (uint256 j = i + 1; j < A.length; j++) {
                if (A[i] == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * Returns whether the two arrays are equal.
     * @param A The first array
     * @param B The second array
     * @return True is the arrays are equal, false if not.
     */
    function isEqual(address[] memory A, address[] memory B) internal pure returns (bool) {
        if (A.length != B.length) {
            return false;
        }
        for (uint256 i = 0; i < A.length; i++) {
            if (A[i] != B[i]) {
                return false;
            }
        }
        return true;
    }
}

// File: contracts/core/tokens/rebalancing-v2/RebalancingFailure.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;









/**
 * @title RebalancingFailure
 * @author Set Protocol
 *
 */
contract RebalancingFailure is
    RebalancingSetState,
    RebalancingSettlement
{
    using SafeMath for uint256;
    using AddressArrayUtils for address[];

    /* ============ Internal Functions ============ */

    /*
     * Validations for failRebalance:
     *  - State is Rebalance
     *  - Either liquidator recognizes failure OR fail period breached on RB Set
     *
     * @param _quantity                 The amount of currentSet to be rebalanced
     */
    function validateFailRebalance()
        internal
        view
    {
        // Token must be in Rebalance State
        validateRebalanceStateIs(RebalancingLibrary.State.Rebalance);

        // Failure triggers must be met
        require(
            liquidatorBreached() || failPeriodBreached(),
            "Triggers not breached"
        );
    }

    /*
     * Determine the new Rebalance State. If there has been a bid, then we put it to
     * Drawdown, where the Set is effectively killed. If no bids, we reissue the currentSet.
     */
    function getNewRebalanceState()
        internal
        view
        returns (RebalancingLibrary.State)
    {
        return hasBidded ? RebalancingLibrary.State.Drawdown : RebalancingLibrary.State.Default;
    }

    /*
     * Update state based on new Rebalance State.
     *
     * @param  _newRebalanceState      The new State to transition to
     */
    function transitionToNewState(
        RebalancingLibrary.State _newRebalanceState
    )
        internal
    {
        reissueSetIfRevertToDefault(_newRebalanceState);

        setWithdrawComponentsIfDrawdown(_newRebalanceState);

        rebalanceState = _newRebalanceState;
        rebalanceIndex = rebalanceIndex.add(1);
        lastRebalanceTimestamp = block.timestamp;

        nextSet = ISetToken(address(0));
        hasBidded = false;
    }

    /* ============ Private Functions ============ */

    /*
     * Returns whether the liquidator believes the rebalance has failed.
     *
     * @return        If liquidator thinks rebalance failed
     */
    function liquidatorBreached()
        private
        view
        returns (bool)
    {
        return liquidator.hasRebalanceFailed(address(this));
    }

    /*
     * Returns whether the the fail time has elapsed, which means that a period
     * of time where the auction should have succeeded has not.
     *
     * @return        If fail period has passed on Rebalancing Set Token
     */
    function failPeriodBreached()
        private
        view
        returns(bool)
    {
        uint256 rebalanceFailTime = rebalanceStartTime.add(rebalanceFailPeriod);

        return block.timestamp >= rebalanceFailTime;
    }

    /*
     * If the determination is Default State, reissue the Set.
     */
    function reissueSetIfRevertToDefault(
        RebalancingLibrary.State _newRebalanceState
    )
        private
    {
        if (_newRebalanceState ==  RebalancingLibrary.State.Default) {
            uint256 issueQuantity = calculateSetIssueQuantity(currentSet);

            // If bid not placed, reissue current Set
            core.issueInVault(
                address(currentSet),
                issueQuantity
            );
        }
    }

    /*
     * If the determination is Drawdown State, set the drawdown components which is the union of
     * the current and next Set components.
     */
    function setWithdrawComponentsIfDrawdown(
        RebalancingLibrary.State _newRebalanceState
    )
        private
    {
        if (_newRebalanceState ==  RebalancingLibrary.State.Drawdown) {
            address[] memory currentSetComponents = currentSet.getComponents();
            address[] memory nextSetComponents = nextSet.getComponents();

            failedRebalanceComponents = currentSetComponents.union(nextSetComponents);
        }
    }
}

// File: contracts/core/tokens/rebalancing-v2/Issuance.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;









/**
 * @title Issuance
 * @author Set Protocol
 *
 * Default implementation of Rebalancing Set Token propose function
 */
contract Issuance is
    ERC20,
    RebalancingSetState
{
    using SafeMath for uint256;
    using CommonMath for uint256;

    /* ============ Internal Functions ============ */

    /*
     * Validate call to mint new Rebalancing Set Token
     *
     *  - Make sure caller is Core
     *  - Make sure state is not Rebalance or Drawdown
     */
    function validateMint()
        internal
        view
    {
        validateCallerIsCore();

        validateRebalanceStateIs(RebalancingLibrary.State.Default);
    }

    /*
     * Validate call to burn Rebalancing Set Token
     *
     *  - Make sure state is not Rebalance or Drawdown
     *  - Make sure sender is module when in drawdown, core otherwise
     */
    function validateBurn()
        internal
        view
    {
        validateRebalanceStateIsNot(RebalancingLibrary.State.Rebalance);

        if (rebalanceState == RebalancingLibrary.State.Drawdown) {
            // In Drawdown Sets can only be burned as part of the withdrawal process
            validateCallerIsModule();
        } else {
            // When in non-Rebalance or Drawdown state, check that function caller is Core
            // so that Sets can be redeemed
            validateCallerIsCore();
        }
    }
    /*
     * Calculates entry fees and mints the feeRecipient a portion of the issue quantity.
     *
     * @param  _quantity              The number of rebalancing SetTokens the issuer mints
     * @return issueQuantityNetOfFees Quantity of rebalancing SetToken to mint issuer net of fees
     */
    function handleEntryFees(
        uint256 _quantity
    )
        internal
        returns(uint256)
    {
        // The entryFee is a scaled decimal figure by 10e18. We multiply the fee by the quantity
        // Then descale by 10e18
        uint256 fee = _quantity.mul(entryFee).deScale();

        if (fee > 0) {
            ERC20._mint(feeRecipient, fee);

            emit EntryFeePaid(feeRecipient, fee);
        }

        // Return the issue quantity less fees
        return _quantity.sub(fee);
    }
}

// File: contracts/core/tokens/rebalancing-v2/RebalancingBid.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;







/**
 * @title RebalancingBid
 * @author Set Protocol
 *
 * Implementation of Rebalancing Set Token V2 bidding-related functionality.
 */
contract RebalancingBid is
    RebalancingSetState
{
    using SafeMath for uint256;

    /* ============ Internal Functions ============ */

    /*
     * Validates conditions to retrieve a Bid Price:
     *  - State is Rebalance
     *  - Quanity is greater than zero
     *
     * @param _quantity                 The amount of currentSet to be rebalanced
     */
    function validateGetBidPrice(
        uint256 _quantity
    )
        internal
        view
    {
        validateRebalanceStateIs(RebalancingLibrary.State.Rebalance);

        require(
            _quantity > 0,
            "Bid not > 0"
        );
    }

    /*
     * Validations for placeBid:
     *  - Module is sender
     *  - getBidPrice validations
     *
     * @param _quantity                 The amount of currentSet to be rebalanced
     */
    function validatePlaceBid(
        uint256 _quantity
    )
        internal
        view
    {
        validateCallerIsModule();

        validateGetBidPrice(_quantity);
    }

    /*
     * If a successful bid has been made, flip the hasBidded boolean.
     */
    function updateHasBiddedIfNecessary()
        internal
    {
        if (!hasBidded) {
            hasBidded = true;
        }
    }

}

// File: contracts/core/tokens/rebalancing-v2/RebalancingStart.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;








/**
 * @title RebalancingStart
 * @author Set Protocol
 *
 * Implementation of Rebalancing Set Token V2 start rebalance functionality
 */
contract RebalancingStart is
    ERC20,
    RebalancingSetState
{
    using SafeMath for uint256;

    /* ============ Internal Functions ============ */

    /**
     * Validate that start rebalance can be called:
     *  - Current state is Default
     *  - rebalanceInterval has elapsed
     *  - Proposed set is valid in Core
     *  - Components in set are all valid
     *  - NaturalUnits are multiples of each other
     *
     * @param _nextSet                    The Set to rebalance into
     */
    function validateStartRebalance(
        ISetToken _nextSet
    )
        internal
        view
    {
        validateRebalanceStateIs(RebalancingLibrary.State.Default);

        // Enough time must have passed from last rebalance to start a new proposal
        require(
            block.timestamp >= lastRebalanceTimestamp.add(rebalanceInterval),
            "Interval not elapsed"
        );

        // Must be a positive supply of the Set
        require(
            totalSupply() > 0,
            "Invalid supply"
        );

        // New proposed Set must be a valid Set created by Core
        require(
            core.validSets(address(_nextSet)),
            "Invalid Set"
        );

        // Check proposed components on whitelist. This is to ensure managers are unable to add contract addresses
        // to a propose that prohibit the set from carrying out an auction i.e. a token that only the manager possesses
        require(
            componentWhiteList.areValidAddresses(_nextSet.getComponents()),
            "Invalid component"
        );

        // Check that the proposed set natural unit is a multiple of current set natural unit, or vice versa.
        // Done to make sure that when calculating token units there will are be rounding errors.
        require(
            naturalUnitsAreValid(currentSet, _nextSet),
            "Invalid natural unit"
        );
    }

    /**
     * Calculates the maximum quantity of the currentSet that can be redeemed. This is defined
     * by how many naturalUnits worth of the Set there are.
     *
     * @return   Maximum quantity of the current Set that can be redeemed
     */
    function calculateStartingSetQuantity()
        internal
        view
        returns (uint256)
    {
        uint256 currentSetBalance = vault.getOwnerBalance(address(currentSet), address(this));
        uint256 currentSetNaturalUnit = currentSet.naturalUnit();

        // Rounds the redemption quantity to a multiple of the current Set natural unit
        return currentSetBalance.sub(currentSetBalance.mod(currentSetNaturalUnit));
    }

    /**
     * Signals to the Liquidator to initiate the rebalance.
     *
     * @param _nextSet                         Next set instance
     * @param _startingCurrentSetQuantity      Amount of currentSets the rebalance is initiated with
     * @param _liquidatorData                  Bytecode formatted data with liquidator-specific arguments
     */
    function liquidatorRebalancingStart(
        ISetToken _nextSet,
        uint256 _startingCurrentSetQuantity,
        bytes memory _liquidatorData
    )
        internal
    {
        liquidator.startRebalance(
            currentSet,
            _nextSet,
            _startingCurrentSetQuantity,
            _liquidatorData
        );
    }

    /**
     * Updates rebalance-related state parameters.
     *
     * @param _nextSet                    The Set to rebalance into
     */
    function transitionToRebalance(ISetToken _nextSet) internal {
        nextSet = _nextSet;
        rebalanceState = RebalancingLibrary.State.Rebalance;
        rebalanceStartTime = block.timestamp;
    }

    /* ============ Private Functions ============ */

    /**
     * Check that the proposed set natural unit is a multiple of current set natural unit, or vice versa.
     * Done to make sure that when calculating token units there will be no rounding errors.
     *
     * @param _currentSet                 The current base SetToken
     * @param _nextSet                    The proposed SetToken
     */
    function naturalUnitsAreValid(
        ISetToken _currentSet,
        ISetToken _nextSet
    )
        private
        view
        returns (bool)
    {
        uint256 currentNaturalUnit = _currentSet.naturalUnit();
        uint256 nextSetNaturalUnit = _nextSet.naturalUnit();

        return Math.max(currentNaturalUnit, nextSetNaturalUnit).mod(
            Math.min(currentNaturalUnit, nextSetNaturalUnit)
        ) == 0;
    }
}

// File: contracts/core/tokens/RebalancingSetTokenV2.sol

/*
    Copyright 2019 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;





















/**
 * @title RebalancingSetTokenV2
 * @author Set Protocol
 *
 * Implementation of Rebalancing Set token V2. Major improvements vs. V1 include:
 * - Decouple the Rebalancing Set state and rebalance state from the rebalance execution (e.g. auction)
 *   This allows us to rapidly iterate and build new liquidation mechanisms for rebalances.
 * - Proposals are removed in favor of starting an auction directly.
 * - The Set retains ability to fail an auction if the minimum fail time has elapsed.
 * - RebalanceAuctionModule execution should be backwards compatible with V1.
 * - Bidding and auction parameters state no longer live on this contract. They live on the liquidator
 *   BackwardsComptability is used to allow retrieving of previous supported states.
 * - Introduces entry and rebalance fees, where rebalance fees are configurable based on an external
 *   fee calculator contract
 */
contract RebalancingSetTokenV2 is
    ERC20,
    ERC20Detailed,
    Initializable,
    RebalancingSetState,
    BackwardCompatibility,
    Issuance,
    RebalancingStart,
    RebalancingBid,
    RebalancingSettlement,
    RebalancingFailure
{

    /* ============ Constructor ============ */

    /**
     * Constructor function for Rebalancing Set Token
     *
     * addressConfig [factory, manager, liquidator, initialSet, componentWhiteList,
     *                liquidatorWhiteList, feeRecipient, rebalanceFeeCalculator]
     * [0]factory                   Factory used to create the Rebalancing Set
     * [1]manager                   Address that is able to propose the next Set
     * [2]liquidator                Address of the liquidator contract
     * [3]initialSet                Initial set that collateralizes the Rebalancing set
     * [4]componentWhiteList        Whitelist that nextSet components are checked against during propose
     * [5]liquidatorWhiteList       Whitelist of valid liquidators
     * [6]feeRecipient              Address that receives any incentive fees
     * [7]rebalanceFeeCalculator    Address to retrieve rebalance fee during settlement
     *
     * uintConfig [initialUnitShares, naturalUnit, rebalanceInterval, rebalanceFailPeriod,
     *             lastRebalanceTimestamp, entryFee]
     * [0]initialUnitShares         Units of currentSet that equals one share
     * [1]naturalUnit               The minimum multiple of Sets that can be issued or redeemed
     * [2]rebalanceInterval:        Minimum amount of time between rebalances
     * [3]rebalanceFailPeriod:      Time after auctionStart where something in the rebalance has gone wrong
     * [4]lastRebalanceTimestamp:   Time of the last rebalance; Allows customized deployments
     * [5]entryFee:                 Mint fee represented in a scaled decimal value (e.g. 100% = 1e18, 1% = 1e16)
     *
     * @param _addressConfig             List of configuration addresses
     * @param _uintConfig                List of uint addresses
     * @param _name                      The name of the new RebalancingSetTokenV2
     * @param _symbol                    The symbol of the new RebalancingSetTokenV2
     */
    constructor(
        address[8] memory _addressConfig,
        uint256[6] memory _uintConfig,
        string memory _name,
        string memory _symbol
    )
        public
        ERC20Detailed(
            _name,
            _symbol,
            18
        )
    {
        factory = IRebalancingSetFactory(_addressConfig[0]);
        manager = _addressConfig[1];
        liquidator = ILiquidator(_addressConfig[2]);
        currentSet = ISetToken(_addressConfig[3]);
        componentWhiteList = IWhiteList(_addressConfig[4]);
        liquidatorWhiteList = IWhiteList(_addressConfig[5]);
        feeRecipient = _addressConfig[6];
        rebalanceFeeCalculator = IFeeCalculator(_addressConfig[7]);

        unitShares = _uintConfig[0];
        naturalUnit = _uintConfig[1];
        rebalanceInterval = _uintConfig[2];
        rebalanceFailPeriod = _uintConfig[3];
        lastRebalanceTimestamp = _uintConfig[4];
        entryFee = _uintConfig[5];

        core = ICore(factory.core());
        vault = IVault(core.vault());
        rebalanceState = RebalancingLibrary.State.Default;
    }

    /*
     * Intended to be called during creation by the RebalancingSetTokenFactory. Can only be initialized
     * once. This implementation initializes the rebalance fee.
     *
     *
     * @param _rebalanceFeeCalldata       Bytes encoded rebalance fee represented as a scaled percentage value
     */
    function initialize(
        bytes calldata _rebalanceFeeCalldata
    )
        external
        initializer
    {
        rebalanceFeeCalculator.initialize(_rebalanceFeeCalldata);
    }

   /* ============ External Functions ============ */

    /*
     * Initiates the rebalance in coordination with the Liquidator contract.
     * In this step, we redeem the currentSet and pass relevant information
     * to the liquidator.
     *
     * @param _nextSet                      The Set to rebalance into
     * @param _liquidatorData               Bytecode formatted data with liquidator-specific arguments
     *
     * Can only be called if the rebalance interval has elapsed.
     * Can only be called by manager.
     */
    function startRebalance(
        ISetToken _nextSet,
        bytes calldata _liquidatorData
    )
        external
        onlyManager
    {
        RebalancingStart.validateStartRebalance(_nextSet);

        uint256 startingCurrentSetQuantity = RebalancingStart.calculateStartingSetQuantity();

        core.redeemInVault(address(currentSet), startingCurrentSetQuantity);

        RebalancingStart.liquidatorRebalancingStart(_nextSet, startingCurrentSetQuantity, _liquidatorData);

        RebalancingStart.transitionToRebalance(_nextSet);

        emit RebalanceStarted(
            address(currentSet),
            address(nextSet),
            rebalanceIndex,
            startingCurrentSetQuantity
        );
    }

    /*
     * Get token inflows and outflows required for bid from the Liquidator.
     *
     * @param _quantity               The amount of currentSet to be rebalanced
     * @return inflowUnitArray          Array of amount of tokens inserted into system in bid
     * @return outflowUnitArray         Array of amount of tokens taken out of system in bid
     */
    function getBidPrice(
        uint256 _quantity
    )
        public
        view
        returns (uint256[] memory, uint256[] memory)
    {
        RebalancingBid.validateGetBidPrice(_quantity);

        return Rebalance.decomposeTokenFlowToBidPrice(
            liquidator.getBidPrice(address(this), _quantity)
        );
    }

    /*
     * Place bid during rebalance auction.
     *
     * The intended caller is the RebalanceAuctionModule, which must be approved by Core.
     * Call Flow:
     * RebalanceAuctionModule -> RebalancingSetTokenV2 -> Liquidator
     *
     * @param _quantity                 The amount of currentSet to be rebalanced
     * @return combinedTokenArray       Array of token addresses invovled in rebalancing
     * @return inflowUnitArray          Array of amount of tokens inserted into system in bid
     * @return outflowUnitArray         Array of amount of tokens taken out of system in bid
     */
    function placeBid(
        uint256 _quantity
    )
        external
        returns (address[] memory, uint256[] memory, uint256[] memory)
    {
        RebalancingBid.validatePlaceBid(_quantity);

        // Place bid and get back inflow and outflow arrays
        Rebalance.TokenFlow memory tokenFlow = liquidator.placeBid(_quantity);

        RebalancingBid.updateHasBiddedIfNecessary();

        return Rebalance.decomposeTokenFlow(tokenFlow);
    }

    /*
     * After a successful rebalance, the new Set is issued. If there is a rebalance fee,
     * the fee is paid via inflation of the Rebalancing Set to the feeRecipient.
     * Full issuance functionality is now returned to set owners.
     *
     * Anyone can call this function.
     */
    function settleRebalance()
        external
    {
        RebalancingSettlement.validateRebalancingSettlement();

        uint256 issueQuantity = RebalancingSettlement.calculateSetIssueQuantity(nextSet);

        // Calculates fees and mints Rebalancing Set to the feeRecipient, increasing supply
        (uint256 feePercent, uint256 feeQuantity) = RebalancingSettlement.handleFees();

        uint256 newUnitShares = RebalancingSettlement.calculateNextSetNewUnitShares(issueQuantity);

        // The unit shares must result in a quantity greater than the number of natural units outstanding
        require(
            newUnitShares > 0,
            "Failed: unitshares is 0."
        );

        RebalancingSettlement.issueNextSet(issueQuantity);

        liquidator.settleRebalance();

        // Rebalance index is the current vs next rebalance
        emit RebalanceSettled(
            feeRecipient,
            feeQuantity,
            feePercent,
            rebalanceIndex,
            issueQuantity,
            newUnitShares
        );

        RebalancingSettlement.transitionToDefault(newUnitShares);

    }

    /*
     * Ends a rebalance if there are any signs that there is a failure.
     * Possible failure reasons:
     * 1. The rebalance has elapsed the failRebalancePeriod
     * 2. The liquidator responds that the rebalance has failed
     *
     * Move to Drawdown state if bids have been placed. Reset to Default state if no bids placed.
     */
    function endFailedRebalance()
        public
    {
        RebalancingFailure.validateFailRebalance();

        RebalancingLibrary.State newRebalanceState = RebalancingFailure.getNewRebalanceState();

        liquidator.endFailedRebalance();

        RebalancingFailure.transitionToNewState(newRebalanceState);
    }

    /*
     * Mint set token for given address. If there if is an entryFee, calculates the fee and mints
     * the rebalancing SetToken to the feeRecipient.
     *
     * Can only be called by Core contract.
     *
     * @param  _issuer      The address of the issuing account
     * @param  _quantity    The number of sets to attribute to issuer
     */
    function mint(
        address _issuer,
        uint256 _quantity
    )
        external
    {
        Issuance.validateMint();

        uint256 issueQuantityNetOfFees = Issuance.handleEntryFees(_quantity);

        ERC20._mint(_issuer, issueQuantityNetOfFees);
    }

    /*
     * Burn set token for given address. Can only be called by authorized contracts.
     *
     * @param  _from        The address of the redeeming account
     * @param  _quantity    The number of sets to burn from redeemer
     */
    function burn(
        address _from,
        uint256 _quantity
    )
        external
    {
        Issuance.validateBurn();

        ERC20._burn(_from, _quantity);
    }

    /* ============ Backwards Compatability ============ */

    /*
     * Alias for endFailedRebalance
     */
    function endFailedAuction() external {
        endFailedRebalance();
    }
}

// File: contracts/core/tokens/RebalancingSetTokenV3.sol

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

pragma solidity 0.5.7;





/**
 * @title RebalancingSetTokenV3
 * @author Set Protocol
 *
 * Implementation of Rebalancing Set token V2. Major improvements vs. V2 include:
 * - Separating incentive fees from the settlement process.
 */
contract RebalancingSetTokenV3 is
    IncentiveFee,
    RebalancingSetTokenV2
{
    /* ============ Constructor ============ */

    /**
     * Constructor function for Rebalancing Set Token
     *
     * addressConfig [factory, manager, liquidator, initialSet, componentWhiteList,
     *                liquidatorWhiteList, feeRecipient, rebalanceFeeCalculator]
     * [0]factory                   Factory used to create the Rebalancing Set
     * [1]manager                   Address that is able to propose the next Set
     * [2]liquidator                Address of the liquidator contract
     * [3]initialSet                Initial set that collateralizes the Rebalancing set
     * [4]componentWhiteList        Whitelist that nextSet components are checked against during propose
     * [5]liquidatorWhiteList       Whitelist of valid liquidators
     * [6]feeRecipient              Address that receives any incentive fees
     * [7]rebalanceFeeCalculator    Address to retrieve rebalance fee during settlement
     *
     * uintConfig [initialUnitShares, naturalUnit, rebalanceInterval, rebalanceFailPeriod,
     *             lastRebalanceTimestamp, entryFee]
     * [0]initialUnitShares         Units of currentSet that equals one share
     * [1]naturalUnit               The minimum multiple of Sets that can be issued or redeemed
     * [2]rebalanceInterval:        Minimum amount of time between rebalances
     * [3]rebalanceFailPeriod:      Time after auctionStart where something in the rebalance has gone wrong
     * [4]lastRebalanceTimestamp:   Time of the last rebalance; Allows customized deployments
     * [5]entryFee:                 Mint fee represented in a scaled decimal value (e.g. 100% = 1e18, 1% = 1e16)
     *
     * @param _addressConfig             List of configuration addresses
     * @param _uintConfig                List of uint addresses
     * @param _name                      The name of the new RebalancingSetTokenV2
     * @param _symbol                    The symbol of the new RebalancingSetTokenV2
     */
    constructor(
        address[8] memory _addressConfig,
        uint256[6] memory _uintConfig,
        string memory _name,
        string memory _symbol
    )
        public
        RebalancingSetTokenV2(
            _addressConfig,
            _uintConfig,
            _name,
            _symbol
        )
    {}

    /*
     * Overrides the RebalancingSetTokenV2 settleRebalance function.
     *
     * After a successful rebalance, the new Set is issued.
     * Full issuance functionality is now returned to set owners. No fees are captured.
     *
     * Anyone can call this function.
     */
    function settleRebalance()
        external
    {
        // It can only be callable in the Default state
        RebalancingSettlement.validateRebalancingSettlement();

        uint256 issueQuantity = RebalancingSettlement.calculateSetIssueQuantity(nextSet);
        uint256 newUnitShares = RebalancingSettlement.calculateNextSetNewUnitShares(issueQuantity);

        validateUnitShares(newUnitShares);

        RebalancingSettlement.issueNextSet(issueQuantity);

        liquidator.settleRebalance();

        emit RebalanceSettled(
            address(0),      // No longer used
            0,               // No longer used
            0,               // No longer used
            rebalanceIndex,  // Current Rebalance index
            issueQuantity,
            newUnitShares
        );

        RebalancingSettlement.transitionToDefault(newUnitShares);
    }

    /*
     * During the Default stage, the incentive / rebalance Fee can be triggered. This will
     * retrieve the current inflation fee from the fee calulator and mint the according
     * inflation to the feeRecipient. The unit shares is then adjusted based on the new
     * supply.
     *
     * Anyone can call this function.
     */
    function actualizeFee()
        public
    {
        IncentiveFee.validateFeeActualization();

        // Calculates fees and mints Rebalancing Set to the feeRecipient, increasing supply
        (uint256 feePercent, uint256 feeQuantity) = IncentiveFee.handleFees();

        // The minting of new supply changes the unit Shares
        uint256 newUnitShares = IncentiveFee.calculateNewUnitShares();

        validateUnitShares(newUnitShares);

        // Set the new unit shares
        unitShares = newUnitShares;

        // Emit IncentiveFeePaid event
        emit IncentiveFeePaid(
            feeRecipient,
            feeQuantity,
            feePercent,
            newUnitShares
        );
    }

    /*
     * Accrue any fees then adjust fee parameters on feeCalculator. Only callable by manager.
     *
     * @param  _newFeeData       Fee type and new streaming fee encoded in bytes
     */
    function adjustFee(
        bytes calldata _newFeeData
    )
        external
        onlyManager
    {
        actualizeFee();

        rebalanceFeeCalculator.adjustFee(_newFeeData);
    }

    /* ============ V3 Internal Functions ============ */

    /*
     * The unit shares must result in a quantity greater than the number of natural units outstanding.
     * In other words, it must be greater than 0
     */
    function validateUnitShares(uint256 _newUnitShares) internal view {
        require(
            _newUnitShares > 0,
            "Unitshares is 0"
        );
    }
}