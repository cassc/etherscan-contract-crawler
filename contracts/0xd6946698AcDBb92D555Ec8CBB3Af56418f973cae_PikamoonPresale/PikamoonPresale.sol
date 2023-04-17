/**
 *Submitted for verification at Etherscan.io on 2023-04-17
*/

/**
 *Submitted for verification at Etherscan.io on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function mint(uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);
}

interface IERC20Permit {

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountsOut(
        uint amountIn, 
        address[] memory path
        ) external view returns (uint[] memory amounts);
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);

}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PikamoonPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    
    struct Phase {
        uint256 roundId;
        uint256 maxTokens;
        uint256 tokensSold;
        uint256 fundsRaisedEth;
        uint256 tokenPriceInUsd; // usdt decimals 6
        uint256 claimStart;
        bool saleStatus;
    }

    struct AddPhase {
        uint256 roundId;
        uint256 maxTokens;
        uint256 tokenPriceInUsd;
        uint256 claimStart;
    }

    mapping (uint256 => Phase) public phase;
    mapping (address => mapping(uint256 =>  uint256)) public deservedAmount;
    mapping (address => mapping(uint256 =>  uint256)) public claimedAmount;
    mapping (address => mapping(uint256 =>  uint256)) public depositEth;
    
    address constant marketingWallet = 0x9ba08d159EF661cE0F39E5B36249f1dbDa653bA8;
    uint256 constant partnershipEthAmount = 25 * 1e18;
    uint256 public marketingClaimedEth;

    bool public isWhitelistPresale = true;

    address public tokenAddress;
    address public USDT;
    IRouter public router;
    address private WETH;
    uint256 public activePhase = 1;
    uint256 public discountRate = 10;

    function addPhases(AddPhase[] calldata _addPhase) external onlyOwner {
        for(uint256 i = 0; i < _addPhase.length ; i++) {
            phase[_addPhase[i].roundId].roundId = _addPhase[i].roundId;
            phase[_addPhase[i].roundId].maxTokens = _addPhase[i].maxTokens;
            phase[_addPhase[i].roundId].tokenPriceInUsd = _addPhase[i].tokenPriceInUsd;
            phase[_addPhase[i].roundId].claimStart = _addPhase[i].claimStart;
        }
    }

    function getPhases(uint256[] calldata _roundId) public view returns(Phase[] memory){
        Phase[] memory _phase = new Phase[](_roundId.length);
        for(uint256 i = 0 ; i < _roundId.length ; i++) {
            _phase[i] = phase[_roundId[i]];
        }
        return _phase;
    }

    function updatePhaseClaimTime(uint256 _roundId, uint256 _startTime)external onlyOwner{
            phase[_roundId].claimStart = _startTime;

    }
    function setActivePhase(uint256 _roundId) external onlyOwner {
        activePhase = _roundId;
    }

    function currentTimestamp() public view returns(uint256) {
        return block.timestamp;
    }

    function buyTokensEth() payable public {
        require(phase[activePhase].maxTokens > 0,"Phase is not active");
        require(msg.value > 0, "Must send ETH to get tokens");

        uint256 tokenAmount = estimatedToken(msg.value);

        require(phase[activePhase].maxTokens > tokenAmount + phase[activePhase].tokensSold,"Exceeds the maximum number of tokens");      

        phase[activePhase].tokensSold += tokenAmount;
        phase[activePhase].fundsRaisedEth += msg.value;
        deservedAmount[msg.sender][activePhase] += tokenAmount;
        depositEth[msg.sender][activePhase] += msg.value;
    }

    function claim(uint256 _currentPhase) external {
        require(phase[_currentPhase].maxTokens > 0,"Phase is not active");
        require(block.timestamp > phase[_currentPhase].claimStart , "Claiming Not Started Yet" );
        uint256 claimableReward = deservedAmount[msg.sender][_currentPhase] - claimedAmount[msg.sender][_currentPhase];
        require(claimableReward > 0, "There is no reward" );
        claimedAmount[msg.sender][_currentPhase] = deservedAmount[msg.sender][_currentPhase];
        IERC20(tokenAddress).safeTransfer(msg.sender, claimableReward);
    }

    function claimAll(uint256[] calldata _phases) external {
        uint256 claimableReward;
        for(uint256 i = 0 ; i < _phases.length ; i++) {
            require(phase[_phases[i]].maxTokens > 0,"Phase is not active");
            require(block.timestamp > phase[_phases[i]].claimStart , "Claiming Not Started Yet" );
            claimableReward += deservedAmount[msg.sender][_phases[i]] - claimedAmount[msg.sender][_phases[i]];
            claimedAmount[msg.sender][_phases[i]] = deservedAmount[msg.sender][_phases[i]];
        }
        require(claimableReward > 0, "There is no reward" );
        IERC20(tokenAddress).safeTransfer(msg.sender, claimableReward);
    }

    function estimatedToken (uint256 _weiAmount) public view returns (uint256) {
        uint256 tokenPriceInUsd = phase[activePhase].tokenPriceInUsd;
        if(isWhitelistPresale){
            tokenPriceInUsd = tokenPriceInUsd * (100 - discountRate) / 100;
        }
        uint256 tokensPerEth = usdToEth(tokenPriceInUsd);

        return (_weiAmount / tokensPerEth) * 1e9;

    }

    constructor(address _router,address _USDT) {        
        USDT = _USDT;
        router = IRouter(_router);
        WETH = router.WETH();
    }

    function setToken(address _token) external onlyOwner {
        tokenAddress = _token;
    }
    
    receive() external payable {
        buyTokensEth();
    }
    
    function setWhiteListPresale(bool _flag) external onlyOwner {
        isWhitelistPresale = _flag;
    }
    
    // only use in case of emergency or after presale is over
    function withdrawTokens() external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }


    function usdToEth(uint256 _amount) public view returns(uint256) {
        address[] memory path = new address[](2);

        path[0] = WETH;
        path[1] = USDT;
        uint256[] memory amounts = router.getAmountsIn(_amount,path);
        return amounts[0];
    }
    
    // owner can withdraw ETH after people get tokens
    function withdrawETH() external onlyOwner {
        uint256 ethBalance = address(this).balance;
        uint256 marketingAmount;

        if(marketingClaimedEth < partnershipEthAmount){
            marketingAmount = ethBalance.mul(25).div(100);
        }else {
            marketingAmount = ethBalance.mul(3).div(100);
        }
        
        (bool success,) = marketingWallet.call{value: marketingAmount}("");
        require(success, "Withdrawal was not successful");

        (success,) = owner().call{value: ethBalance.sub(marketingAmount)}("");
        require(success, "Withdrawal was not successful");
        marketingClaimedEth += marketingAmount;
    }

    function getStuckToken(address _tokenAddress) external onlyOwner {
        uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
        uint256 marketingAmount = tokenBalance.mul(25).div(100);
        IERC20(_tokenAddress).safeTransfer(marketingWallet,marketingAmount);
        IERC20(_tokenAddress).safeTransfer(owner(),tokenBalance.sub(marketingAmount));
    }
}