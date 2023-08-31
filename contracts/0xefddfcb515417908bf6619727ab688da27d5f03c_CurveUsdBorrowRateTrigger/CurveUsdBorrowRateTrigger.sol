/**
 *Submitted for verification at Etherscan.io on 2023-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





contract MainnetAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0xCCf3d848e08b94478Ed8f46fFead3008faF581fD;
    address internal constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;
    address internal constant ADMIN_ADDR = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9; // USED IN ADMIN VAULT CONSTRUCTOR
}





contract AuthHelper is MainnetAuthAddresses {
}





contract AdminVault is AuthHelper {
    address public owner;
    address public admin;

    error SenderNotAdmin();

    constructor() {
        owner = msg.sender;
        admin = ADMIN_ADDR;
    }

    /// @notice Admin is able to change owner
    /// @param _owner Address of new owner
    function changeOwner(address _owner) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        owner = _owner;
    }

    /// @notice Admin is able to set new admin
    /// @param _admin Address of multisig that becomes new admin
    function changeAdmin(address _admin) public {
        if (admin != msg.sender){
            revert SenderNotAdmin();
        }
        admin = _admin;
    }

}





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}




library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}







library SafeERC20 {
    using SafeMath for uint256;
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}







contract AdminAuth is AuthHelper {
    using SafeERC20 for IERC20;

    AdminVault public constant adminVault = AdminVault(ADMIN_VAULT_ADDR);

    error SenderNotOwner();
    error SenderNotAdmin();

    modifier onlyOwner() {
        if (adminVault.owner() != msg.sender){
            revert SenderNotOwner();
        }
        _;
    }

    modifier onlyAdmin() {
        if (adminVault.admin() != msg.sender){
            revert SenderNotAdmin();
        }
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount) public onlyOwner {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }

    /// @notice Destroy the contract
    function kill() public onlyAdmin {
        selfdestruct(payable(msg.sender));
    }
}





interface ICrvUsdController {
    function create_loan(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands) external payable;
    function create_loan_extended(uint256 _collateralAmount, uint256 _debtAmount, uint256 _nBands, address _callbacker, uint256[] memory _callbackArgs) external payable;

    /// @dev all functions below: if _collateralAmount is 0 will just return
    function add_collateral(uint256 _collateralAmount) external payable;
    function add_collateral(uint256 _collateralAmount, address _for) external payable;

    function remove_collateral(uint256 _collateralAmount) external;
    /// @param _useEth relevant only for ETH collateral pools (currently not deployed)
    function remove_collateral(uint256 _collateralAmount, bool _useEth) external;

    /// @dev all functions below: if _debtAmount is 0 will just return
    function borrow_more(uint256 _collateralAmount, uint256 _debtAmount) external payable;

    /// @dev if _debtAmount > debt will do full repay
    function repay(uint256 _debtAmount) external payable;
    function repay(uint256 _debtAmount, address _for) external payable;
    /// @param _maxActiveBand Don't allow active band to be higher than this (to prevent front-running the repay)
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand) external payable;
    function repay(uint256 _debtAmount, address _for, int256 _maxActiveBand, bool _useEth) external payable;
    function repay_extended(address _callbacker, uint256[] memory _callbackArgs) external;

    function liquidate(address user, uint256 min_x) external;
    function liquidate(address user, uint256 min_x, bool _useEth) external;
    function liquidate_extended(address user, uint256 min_x, uint256 frac, bool use_eth, address callbacker, uint256[] memory _callbackArgs) external;


    /// GETTERS
    function amm() external view returns (address);
    function monetary_policy() external view returns (address);
    function collateral_token() external view returns (address);
    function debt(address) external view returns (uint256);
    function total_debt() external view returns (uint256);
    function health_calculator(address, int256, int256, bool, uint256) external view returns (int256);
    function health_calculator(address, int256, int256, bool) external view returns (int256);
    function health(address) external view returns (int256);
    function health(address, bool) external view returns (int256);
    function max_borrowable(uint256 collateralAmount, uint256 nBands) external view returns (uint256);
    function min_collateral(uint256 debtAmount, uint256 nBands) external view returns (uint256);
    function calculate_debt_n1(uint256, uint256, uint256) external view returns (int256);
    function minted() external view returns (uint256);
    function redeemed() external view returns (uint256);
    function amm_price() external view returns (uint256);
    function user_state(address) external view returns (uint256[4] memory);
    function user_prices(address) external view returns (uint256[2] memory);
    function loan_exists(address) external view returns (bool);
    function liquidation_discount() external view returns (uint256);
}

interface ICrvUsdControllerFactory {
    function get_controller(address) external view returns (address); 
    function debt_ceiling(address) external view returns (uint256);
}

interface ILLAMMA {
    function active_band_with_skip() external view returns (int256);
    function get_sum_xy(address) external view returns (uint256[2] memory);
    function get_xy(address) external view returns (uint256[][2] memory);
    function get_p() external view returns (uint256);
    function read_user_tick_numbers(address) external view returns (int256[2] memory);
    function p_oracle_up(int256) external view returns (uint256);
    function p_oracle_down(int256) external view returns (uint256);
    function p_current_up(int256) external view returns (uint256);
    function p_current_down(int256) external view returns (uint256);
    function bands_x(int256) external view returns (uint256);
    function bands_y(int256) external view returns (uint256);
    function get_base_price() external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function active_band() external view returns (int256);
    function A() external view returns (uint256);
    function min_band() external view returns (int256);
    function max_band() external view returns (int256);
    function rate() external view returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 in_amount, uint256 min_amount) external returns (uint256[2] memory);
    function coins(uint256 i) external view returns (address);
    function user_state(address _user) external view returns (uint256[4] memory);
}

interface IAGG {
    function rate() external view returns (uint256);
    function rate0() external view returns (uint256);
    function target_debt_fraction() external view returns (uint256);
    function sigma() external view returns (int256);
    function peg_keepers(uint256) external view returns (address); 
}

interface IPegKeeper {
    function debt() external view returns (uint256);
}

interface ICurveUsdSwapper {
    function encodeSwapParams(uint256[3][4] memory swapParams,  uint32 gasUsed, uint32 dfsFeeDivider, uint8 useSteth) external pure returns (uint256 encoded);
    function setAdditionalRoutes(address[6] memory _additionalRoutes) external;
}




abstract contract ITrigger {
    function isTriggered(bytes memory, bytes memory) public virtual returns (bool);
    function isChangeable() public virtual returns (bool);
    function changedSubData(bytes memory) public virtual returns (bytes memory);
}







contract CurveUsdBorrowRateTrigger is ITrigger, AdminAuth {
 
    enum TargetRateState { OVER, UNDER }
    
    /// @param market - CurveUsd market
    /// @param targetRate - Rate that represents the triggerable point
    /// @param state - Represents if we want the current state to be higher or lower than targetRate
    struct SubParams {
        address market;
        uint256 targetRate;
        uint8 state;
    }
    
    /// @dev checks current borrow rate for CurveUsd market and triggers if it's in a correct state
    function isTriggered(bytes memory, bytes memory _subData)
        public
        view
        override
        returns (bool)
    {   
        SubParams memory triggerSubData = parseInputs(_subData);

        uint256 currentRate = calcBorrowRate(triggerSubData.market);

        if (TargetRateState(triggerSubData.state) == TargetRateState.OVER) {
            if (currentRate > triggerSubData.targetRate) {
                return true;
            }
        }

        if (TargetRateState(triggerSubData.state) == TargetRateState.UNDER) {
            if (currentRate < triggerSubData.targetRate) {
                return true;
            }
        }

        return false;
    }

    function calcBorrowRate(address _market) public view returns (uint256) {
        ICrvUsdController ctrl = ICrvUsdController(_market);
        ILLAMMA amm = ILLAMMA(ctrl.amm());

        return amm.rate();
    }

    function parseInputs(bytes memory _subData) internal pure returns (SubParams memory params) {
        params = abi.decode(_subData, (SubParams));
    }
    function changedSubData(bytes memory _subData) public pure override  returns (bytes memory) {
    }
    
    function isChangeable() public pure override returns (bool){
        return false;
    }

}