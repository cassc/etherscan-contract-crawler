/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;


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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

address constant USDT = 0x55d398326f99059fF775485246999027B3197955;
IRouter constant ROUTER = IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

interface IRouter {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract HUOFH_Lock is Owned {
    IERC20 public HUOFH;
    IERC20 public LP;
    uint8 public status;
    uint256 public releaseAmount;
    address[17] public members;

    uint256 constant p0 = 3 * 1e17;
    uint256 constant p1 = 6 * 1e17;
    uint256 constant p2 = 9 * 1e17;
    uint256 constant p3 = 12 * 1e17;
    uint256 constant p4 = 15 * 1e17;

    function setTokenAddr(IERC20 _huofh, IERC20 _lp) external onlyOwner {
        HUOFH = _huofh;
        LP = _lp;
    }

    function setMembers(address[17] memory _members) external onlyOwner {
        members = _members;
    }

    function finalize() external onlyOwner {
        uint256 bal = LP.balanceOf(address(this));
        releaseAmount = bal / (20 * 5);
    }

    function stage00() external onlyOwner {
        require(releaseAmount > 0, "finalize");
        require(status == 0, "stage00");
        uint256 price = getPrice();
        require(price >= p0, "p0");
        for (uint256 i = 0; i < members.length; i++) {
            LP.transfer(members[i], releaseAmount);
        }
        status = 1;
    }

    function stage01() external onlyOwner {
        require(status == 1, "stage01");
        uint256 price = getPrice();
        require(price >= p1, "p1");
        for (uint256 i = 0; i < members.length; i++) {
            LP.transfer(members[i], releaseAmount);
        }
        status = 2;
    }

    function stage02() external onlyOwner {
        require(status == 2, "stage02");
        uint256 price = getPrice();
        require(price >= p2, "p2");
        for (uint256 i = 0; i < members.length; i++) {
            LP.transfer(members[i], releaseAmount);
        }
        status = 3;
    }

    function stage03() external onlyOwner {
        require(status == 3, "stage03");
        uint256 price = getPrice();
        require(price >= p3, "p3");
        for (uint256 i = 0; i < members.length; i++) {
            LP.transfer(members[i], releaseAmount);
        }
        status = 4;
    }

    function stage04() external onlyOwner {
        require(status == 4, "stage04");
        uint256 price = getPrice();
        require(price >= p4, "p4");
        for (uint256 i = 0; i < members.length; i++) {
            LP.transfer(members[i], releaseAmount);
        }
    }

    function emergencyWithdraw(IERC20 _token, uint256 _amount)
        external
        onlyOwner
    {
        _token.transfer(msg.sender, _amount);
    }

    function getPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(HUOFH);
        path[1] = address(USDT);

        try ROUTER.getAmountsOut(1 ether, path) returns (
            uint256[] memory amounts
        ) {
            return amounts[1];
        } catch {
            return 0;
        }
    }
}