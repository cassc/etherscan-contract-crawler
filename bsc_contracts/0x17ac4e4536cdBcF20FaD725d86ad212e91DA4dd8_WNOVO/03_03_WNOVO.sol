// SPDX-License-Identifier: MIT

/*
 * This $WNOVO wrapped contract and all other contracts, inclusive of dApps and any other platform is developed and maintained by Novoos
 * Novoos Ecosystem
 * Telegram: https://t.me/novoosecosystem
 * Website: https://novoos.net
 * Github: https://github.com/Novoos
 * 
 * The NAC follows strict recommendations made by OpenZeppelin, this assists in minimizing risk because the libraries of the NAC smart contracts have already been tested against vulnerabilities, bugs
 * and security issues and therefore includes the most used implementations of ERC standards. 
 *
 * This is the $WNOVO contract (For trading on CEX's)
 * 
███╗░░██╗░█████╗░██╗░░░██╗░█████╗░░█████╗░░██████╗
████╗░██║██╔══██╗██║░░░██║██╔══██╗██╔══██╗██╔════╝
██╔██╗██║██║░░██║╚██╗░██╔╝██║░░██║██║░░██║╚█████╗░
██║╚████║██║░░██║░╚████╔╝░██║░░██║██║░░██║░╚═══██╗
██║░╚███║╚█████╔╝░░╚██╔╝░░╚█████╔╝╚█████╔╝██████╔╝
╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░╚═════╝░

███████╗░█████╗░░█████╗░░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗
██╔════╝██╔══██╗██╔══██╗██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║
█████╗░░██║░░╚═╝██║░░██║╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║
██╔══╝░░██║░░██╗██║░░██║░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║
███████╗╚█████╔╝╚█████╔╝██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║
╚══════╝░╚════╝░░╚════╝░╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝
 * 
 * Novoos Ecosystem implements upgradable contracts as they are more efficient and cost-effective inlcuding but not limited to:
 * Continuous Seamless Enhancements
 * No Relaunches
 * No migrations 
 * No Downtime
 * No Negative Effect for investors
 * 
 * This is the $WNOVO Contract (For trading on CEX's)
 */

pragma solidity >=0.8.4;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract WNOVO is Initializable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    IERC20 public Token;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /**
    * @dev Contract module that helps prevent reentrant calls to a function.
    *
    * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
    * available, which can be applied to functions to make sure there are no nested
    * (reentrant) calls to them.
    *
    * Note that because there is a single `nonReentrant` guard, functions marked as
    * `nonReentrant` may not call one another. This can be worked around by making
    * those functions `private`, and then adding `external` `nonReentrant` entry
    * points to them.
    *
    * TIP: If you would like to learn more about reentrancy and alternative ways
    * to protect against it, check out our blog post
    * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
    */

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;


    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    

    function initialize(address _token) public initializer {
        name = "Wrapped Novoos";
        symbol = "WNOVO";
        decimals = 18;
        Token = IERC20(_token);
    }

    function deposit(uint256 wad) public nonReentrant {
        require(Token.balanceOf(msg.sender) >= wad, "Insufficient balance.");
        Token.transferFrom(msg.sender, address(this), wad);
        balanceOf[msg.sender] += wad;
        _totalSupply += wad;
        emit Deposit(msg.sender, wad);
    }

    function withdraw(uint256 wad) public nonReentrant {
        require(balanceOf[msg.sender] >= wad, "Insufficient balance.");
        balanceOf[msg.sender] -= wad;
        _totalSupply -= wad;
        Token.transfer(msg.sender, wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "Insufficient balance.");

        if (src != msg.sender && allowance[src][msg.sender] != uint256(0)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}