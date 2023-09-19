/**
 *Submitted for verification at Etherscan.io on 2023-08-21
*/

// SPDX-License-Identifier: MIT

// website: https://kekw.gg/
// telegram: https://t.me/kekw_gg
// Twitter: https://x.com/kekw_gg

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/ICO.sol


pragma solidity 0.8.16;


contract TKNICO {
    //Administration Details
    address public admin;
    address payable public ICOWallet;

    //Token
    IERC20 public token;

    //ICO Details
    uint public tokenPrice = 0.00000000001 ether;
    uint public hardCap = 2200 ether;
    uint public raisedAmount;
    uint public minInvestment = 0.01 ether;
    uint public maxInvestment = 10 ether;

    //Investor
    mapping(address => uint) public investedAmountOf;

    //ICO State
    enum State {
        BEFORE,
        RUNNING,
        END,
        HALTED
    }
    State public ICOState;

    //Events
    event Invest(
        address indexed from,
        address indexed to,
        uint value,
        uint tokens
    );
    event TokenBurn(address to, uint amount, uint time);

    //Initialize Variables
    constructor(address payable _icoWallet, address _token) {
        admin = msg.sender;
        ICOWallet = _icoWallet;
        token = IERC20(_token);
    }

    //Access Control
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin Only function");
        _;
    }

    //Receive Ether Directly
    receive() external payable {
        invest();
    }

    fallback() external payable {
        invest();
    }

    /* Functions */

    //Get ICO State
    function getICOState() external view returns (string memory) {
        if (ICOState == State.BEFORE) {
            return "Not Started";
        } else if (ICOState == State.RUNNING) {
            return "Running";
        } else if (ICOState == State.END) {
            return "End";
        } else {
            return "Halted";
        }
    }

    /* Admin Functions */

    //Start, Halt and End ICO
    function startICO() external onlyAdmin {
        require(ICOState == State.BEFORE, "ICO isn't in before state");
        ICOState = State.RUNNING;
    }

    function haltICO() external onlyAdmin {
        require(ICOState == State.RUNNING, "ICO isn't running yet");
        ICOState = State.HALTED;
    }

    function resumeICO() external onlyAdmin {
        require(ICOState == State.HALTED, "ICO State isn't halted yet");
        ICOState = State.RUNNING;
    }

    //Change ICO Wallet
    function changeICOWallet(address payable _newICOWallet) external onlyAdmin {
        ICOWallet = _newICOWallet;
    }

    //Change Admin
    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /* User Function */

    //Invest
    function invest() public payable returns (bool) {
        require(ICOState == State.RUNNING, "ICO isn't running");
        require(
            msg.value >= minInvestment && msg.value <= maxInvestment,
            "Check Min and Max Investment"
        );
        require(
            investedAmountOf[msg.sender] + msg.value <= maxInvestment,
            "Investor reached maximum Investment Amount"
        );

        require(
            raisedAmount + msg.value <= hardCap,
            "Send within hardcap range"
        );

        raisedAmount += msg.value;
        investedAmountOf[msg.sender] += msg.value;

        (bool transferSuccess, ) = ICOWallet.call{value: msg.value}("");
        require(transferSuccess, "Failed to Invest");

        uint tokens = (msg.value / tokenPrice) * 1e18;
        bool saleSuccess = token.transfer(msg.sender, tokens);
        require(saleSuccess, "Failed to Invest");

        emit Invest(address(this), msg.sender, msg.value, tokens);
        return true;
    }

    //Burn Tokens
    function burn() external returns (bool) {
        require(ICOState == State.END, "ICO isn't over yet");

        uint remainingTokens = token.balanceOf(address(this));
        bool success = token.transfer(address(0), remainingTokens);
        require(success, "Failed to burn remaining tokens");

        emit TokenBurn(address(0), remainingTokens, block.timestamp);
        return true;
    }

    //End ICO After reaching Hardcap or ICO Timelimit
    function endIco() public {
        require(ICOState == State.RUNNING, "ICO Should be in Running State");
        ICOState = State.END;
    }

    //Check ICO Contract Token Balance
    function getICOTokenBalance() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    //Check ICO Contract Investor Token Balance
    function investorBalanceOf(address _investor) external view returns (uint) {
        return token.balanceOf(_investor);
    }
}