/**
 *Submitted for verification at Etherscan.io on 2023-04-29
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/altoids2.sol

pragma solidity 0.8.17;


interface ICurvePool {
    function get_dy(
        int128 in_index,
        int128 out_index,
        uint256 in_amount
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}

interface IDepositor {
    function incentiveToken() external view returns (uint256);

    function lockToken() external;

    function minter() external view returns (address);

    function token() external view returns (address);
}

interface IUniV2Router {
    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external;

    function balanceOf(address) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract Altoids is Ownable {
    struct Package {
        IDepositor depositor;
        ICurvePool curvePool;
        address[] path;
    }

    IUniV2Router constant sushiswap =
        IUniV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    uint256 constant MAX_UINT = ~uint256(0); // maximum uint value

    function approves(IERC20[] memory tokens, address[] memory tos)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];
            address to = tos[i];

            if (token.allowance(address(this), to) < MAX_UINT) {
                token.approve(to, MAX_UINT);
            }
        }
    }

    function earnables(Package[] memory packages)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory earnings = new uint256[](packages.length);
        for (uint256 i = 0; i < packages.length; i++) {
            Package memory package = packages[i];
            uint256 mintable = package.depositor.incentiveToken();
            if (mintable > 0) {
                if (address(package.curvePool) != address(0x0)) {
                    uint256 native = package.curvePool.get_dy(1, 0, mintable);
                    if (package.path.length > 0) {
                        uint256 earning = sushiswap.getAmountsOut(
                            native,
                            package.path
                        )[package.path.length - 1];
                        earnings[i] = earning;
                    } else {
                        earnings[i] = native;
                    }
                } else {
                    earnings[i] = mintable;
                }
            }
        }
        return earnings;
    }

    function deposit(Package[] memory packages) external payable onlyOwner {
        for (uint256 i = 0; i < packages.length; i++) {
            Package memory package = packages[i];
            IDepositor depositor = package.depositor;
            IERC20 sdToken = IERC20(depositor.minter());
            IERC20 baseToken = IERC20(depositor.token());

            depositor.lockToken();
            if (address(package.curvePool) != address(0x0)) {
                package.curvePool.exchange(
                    1,
                    0,
                    sdToken.balanceOf(address(this)),
                    0
                );
                if (package.path.length > 0) {
                    sushiswap.swapExactTokensForETH(
                        baseToken.balanceOf(address(this)),
                        0,
                        package.path,
                        owner(),
                        MAX_UINT
                    );
                } else {
                    baseToken.transfer(
                        owner(),
                        baseToken.balanceOf(address(this))
                    );
                }
            } else {
                sdToken.transfer(owner(), sdToken.balanceOf(address(this)));
            }
        }
    }

    function sweep(IERC20 token) external payable onlyOwner {
        if (
            address(token) == address(0x0) ||
            address(token) ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            payable(owner()).transfer(owner().balance);
        } else {
            token.transfer(owner(), token.balanceOf(address(this)));
        }
    }

    receive() external payable {}

    fallback() external payable {}
}