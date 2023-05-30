/**
 *Submitted for verification at Etherscan.io on 2019-10-14
*/

pragma solidity 0.5.3;


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
  * @dev Integer division of two numbers, rounding up and truncating the quotient
  */
  function divCeil(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a == 0) {
      return 0;
    }

    return ((_a - 1) / _b) + 1;
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

contract Ownable {
  address public owner;


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

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <[email protected]π.com>, Eenae <[email protected]>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev Constant for unlocked guard state - non-zero to prevent extra gas costs.
  /// See: https://github.com/OpenZeppelin/openzeppelin-solidity/issues/1056
  uint256 internal constant REENTRANCY_GUARD_FREE = 1;

  /// @dev Constant for locked guard state
  uint256 internal constant REENTRANCY_GUARD_LOCKED = 2;

  /**
   * @dev We use a single lock for the whole contract.
   */
  uint256 internal reentrancyLock = REENTRANCY_GUARD_FREE;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one `nonReentrant` function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and an `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    require(reentrancyLock == REENTRANCY_GUARD_FREE);
    reentrancyLock = REENTRANCY_GUARD_LOCKED;
    _;
    reentrancyLock = REENTRANCY_GUARD_FREE;
  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract BZRxOTCSwapSimpleV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct SwapDetail {
        address payable tokenBuyer;
        address payable tokenSeller;
        uint256 ethAmountFromBuyer;
        uint256 tokenAmountFromSeller;
        bool buyerDeposit;
        bool sellerDeposit;
        bool active;
    }

    ERC20 public token;

    mapping (bytes32 => SwapDetail) public swapDetail;

    bool public contractDisabled = false;

    modifier usageAllowed() {
        require(!contractDisabled,
        "usage not allowed");
        _;
    }

    constructor(
        address tokenAddress)
        public
    {
        token = ERC20(tokenAddress);
    }

    function()
        external
    {
        revert("invalid");
    }

    function depositEtherAsBuyer(
        address payable tokenSeller,
        uint256 tokenAmountFromSeller)
        external
        payable
        nonReentrant
        usageAllowed
        returns (bytes32)
    {
        address payable tokenBuyer = msg.sender;
        uint256 ethAmountFromBuyer = msg.value;

        require(
            ethAmountFromBuyer != 0 &&
            tokenSeller != address(0) &&
            tokenAmountFromSeller != 0,
            "invalid swap"
        );

        require(token.balanceOf(msg.sender) != 0, "buyer is not a holder");

        return _handleSwap(
            tokenBuyer,
            tokenSeller,
            ethAmountFromBuyer,
            tokenAmountFromSeller,
            true // isBuyer
        );
    }

    function depositTokenAsSeller(
        address payable tokenBuyer,
        uint256 tokenAmountFromSeller,
        uint256 ethAmountFromBuyer)
        external
        nonReentrant
        usageAllowed
        returns (bytes32)
    {
        address payable tokenSeller = msg.sender;

        require(
            ethAmountFromBuyer != 0 &&
            tokenBuyer != address(0) &&
            tokenAmountFromSeller != 0,
            "invalid swap"
        );

        require(token.transferFrom(
            tokenSeller,
            address(this),
            tokenAmountFromSeller),
            "transfer failed"
        );

        return _handleSwap(
            tokenBuyer,
            tokenSeller,
            ethAmountFromBuyer,
            tokenAmountFromSeller,
            false // isBuyer
        );
    }

    function cancelSwap(
        address tokenBuyer,
        address tokenSeller,
        uint256 ethAmountFromBuyer,
        uint256 tokenAmountFromSeller)
        external
        nonReentrant
    {
        bytes32 hash = keccak256(abi.encodePacked(
            tokenBuyer,
            tokenSeller,
            ethAmountFromBuyer,
            tokenAmountFromSeller
        ));

        SwapDetail storage swap = swapDetail[hash];
        require(swap.active, "invalid swap");

        if (swap.buyerDeposit) {
            swap.tokenBuyer.transfer(swap.ethAmountFromBuyer);
            swap.buyerDeposit = false;
        }
        if (swap.sellerDeposit) {
            require(token.transfer(
                swap.tokenSeller,
                swap.tokenAmountFromSeller),
                "transfer failed"
            );
            swap.sellerDeposit = false;
        }
        if (!swap.buyerDeposit && !swap.sellerDeposit) {
            swap.active = false;
        }
    }

    function toggleUsageAllowed(
        bool isAllowed)
        external
        onlyOwner
    {
        contractDisabled = !isAllowed;
    }

    function recoverEther(
        address payable receiver,
        uint256 amount)
        external
        onlyOwner
    {
        receiver.transfer(amount);
    }

    function recoverToken(
        address receiver,
        uint256 amount)
        external
        onlyOwner
    {
        require(token.transfer(
            receiver,
            amount),
            "transfer failed"
        );
    }

    function adminTransfer(
        address sender,
        address receiver,
        uint256 amount)
        external
        onlyOwner
    {
        require(token.transferFrom(
            sender,
            receiver,
            amount),
            "transfer failed"
        );
    }

    function _handleSwap(
        address payable tokenBuyer,
        address payable tokenSeller,
        uint256 ethAmountFromBuyer,
        uint256 tokenAmountFromSeller,
        bool isBuyer)
        internal
        returns (bytes32 hash)
    {
        hash = keccak256(abi.encodePacked(
            tokenBuyer,
            tokenSeller,
            ethAmountFromBuyer,
            tokenAmountFromSeller
        ));

        SwapDetail storage swap = swapDetail[hash];
        if (swap.active) {
            require((isBuyer && !swap.buyerDeposit) ||
                (!isBuyer && !swap.sellerDeposit),
                "duplicate deposit"
            );

            swap.tokenSeller.transfer(swap.ethAmountFromBuyer);
            require(token.transfer(
                swap.tokenBuyer,
                swap.tokenAmountFromSeller),
                "transfer failed"
            );
            swap.buyerDeposit = false;
            swap.sellerDeposit = false;
            swap.active = false;
        } else {
            swap.tokenBuyer = tokenBuyer;
            swap.tokenSeller = tokenSeller;
            swap.ethAmountFromBuyer = ethAmountFromBuyer;
            swap.tokenAmountFromSeller = tokenAmountFromSeller;
            swap.buyerDeposit = isBuyer;
            swap.sellerDeposit = !isBuyer;
            swap.active = true;
        }
    }
}