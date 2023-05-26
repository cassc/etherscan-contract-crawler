pragma solidity ^0.6.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/GSN/Context.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

    }
}


contract BIBLEdefichurch is ERC20 {
    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
 
    
    address owner;
    bool private purchaselimit = true; // default to true, it will be disabled prior to launch of farming
    address private fundVotingAddress;
    bool private isSendingFunds;
    uint256 private lastBlockSent;
    address public PriestAddress = 0xd865344d80e7480beC2Bd6cE2bB9bD1d549120cA; // PRIEST contract
    uint public transferFee = 15; // 3% fee on transfer -> 1.5% BURN / 1.5% BIBLE/ETH LP stakers.

    mapping (address => uint256) internal _balances;

    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public payable ERC20("defi.church", "BIBLE") {
        owner = msg.sender;
        uint256 supply = 10000 ether;
        lastBlockSent = block.number;
        _mint(msg.sender, supply);
    }
    

       function setPriestAddress(address _PriestAddress) public _onlyOwner {
       PriestAddress = _PriestAddress; 
   }
    

   
       function setTransferFee(uint256 _transferFee) public _onlyOwner {
        require(_transferFee <= 100, "It's over 10%");
        transferFee = _transferFee;
    }
    
    
    
     function transfer(address recipient, uint256 _amount) public override returns (bool) {

        uint256 transferBurnFeeAmount;
        uint256 tokensToTransfer;
        uint256 transferToPRIESTsAmount;
        uint256 transferTotalFee;

        if (purchaselimit) {
            if (_amount > 50 ether && msg.sender != owner) {
                revert('Purchasing limit!');
            }
        }
        
        transferBurnFeeAmount = _amount.mul(transferFee).div(1000);
        transferToPRIESTsAmount = _amount.mul(transferFee).div(1000);
        transferTotalFee = transferBurnFeeAmount + transferToPRIESTsAmount;
        _balances[PriestAddress] = _balances[PriestAddress].add(transferBurnFeeAmount);
        _burn(msg.sender, transferBurnFeeAmount);
        super._transfer(msg.sender, PriestAddress, transferToPRIESTsAmount);
        tokensToTransfer = _amount.sub(transferTotalFee);
        super._transfer(msg.sender, recipient, tokensToTransfer);
        return true;
}

    function enableLimits() public {
        if (msg.sender != owner) {
            revert();
        }
        purchaselimit = true;
    }
    
    function disableLimits() public {
        if (msg.sender != owner) {
            revert();
        }
        purchaselimit = false;
    }
    
    function transferOwnership(address _newOwner) public _onlyOwner {
    require(msg.sender == owner);

    owner = _newOwner;

}
    
   
}