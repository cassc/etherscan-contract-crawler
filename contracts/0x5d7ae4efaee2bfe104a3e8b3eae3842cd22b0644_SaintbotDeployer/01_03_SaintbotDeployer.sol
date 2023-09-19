// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ModelERC20V2} from "src/ModelERC20V2.sol";

// ALL CONTRACTS DEPLOYED USING OUR FACTORY ARE ANTI-RUG BY DEFAULT: CONTRACT RENOUNCED, LIQ LOCKED FOR 30 DAYS ON UNCX, CANT CHANGE ANY VARIABLE BUT TAX RECEIVER!
// Saintbot
// Deploy and manage fair launch anti-rug tokens seamlessly and lightning-fast with low gas on our free-to-use Telegram bot.
// Website: saintbot.app/
// Twitter: twitter.com/TeamSaintbot
// Telegram Bot: https://t.me/saintbot_deployer_bot
// Docs: https://saintbots-organization.gitbook.io/saintbot-docs/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address account, uint256 amount) external;
}

interface IUNCX {
    struct LockParams {
        address payable owner; // the user who can withdraw tokens once the lock expires.
        uint256 amount; // amount of tokens to lock
        uint256 startEmission; // 0 if lock type 1, else a unix timestamp
        uint256 endEmission; // the unlock date as a unix timestamp (in seconds)
        address condition; // address(0) = no condition, otherwise the condition must implement IUnlockCondition
    }

    function lock(address _token, LockParams[] calldata _lock_params) external;
}

interface IRefSys {
    function getRefReceiver(bytes memory _refCode) external view returns (address receiverWallet);
}

contract SaintbotDeployer is Ownable {
    IUNCX public constant LOCKER = IUNCX(0xDba68f07d1b7Ca219f78ae8582C213d975c25cAf);

    uint256 public constant LIQUIDITY_LOCK_TIME = 30 days;

    address public immutable implementation;

    address public ethLiquidityTax;
    address public tradingTaxes;
    IRefSys public refSys;

    constructor() {
        implementation = address(new ModelERC20V2());
    }

    function deployNew(string memory _name, string memory _symbol, bytes memory _ref)
        external
        payable
        returns (address token, address uniPair)
    {
        require(msg.value >= 0.4 ether, "weth liquidity needs to be bigger than 0.4E");

        token = _clone(implementation);

        // Get ref address, if 0, pass address(0)
        address refAddress = refSys.getRefReceiver(_ref);

        uniPair = ModelERC20V2(payable(token)).init{value: msg.value}(_name, _symbol, msg.sender, refAddress);

        _lockIntoUNCX(uniPair, msg.sender);

        emit NewSaintbotDeployment(token, uniPair, msg.sender, _ref, refAddress);
    }

    // Lock in name of the person who called the factory
    function _lockIntoUNCX(address _lp, address _owner) private {
        uint256 amount = IERC20(_lp).balanceOf(address(this));

        IUNCX.LockParams[] memory lockParams = new IUNCX.LockParams[](1);

        lockParams[0] = IUNCX.LockParams(
            payable(_owner), IERC20(_lp).balanceOf(address(this)), 0, block.timestamp + LIQUIDITY_LOCK_TIME, address(0)
        );

        IERC20(_lp).approve(address(LOCKER), amount);

        LOCKER.lock(_lp, lockParams);
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function _clone(address _implementation) private returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, _implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, _implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }

        if (instance == address(0)) {
            revert ERC1167FailedCreateClone();
        }
    }

    // Wallets used to handle the taxes generated through the use of the bot iself
    function updateAddresses(address _ethLiquidityTax, address _newTradingTaxes, address _refSys) external onlyOwner {
        ethLiquidityTax = _ethLiquidityTax;
        refSys = IRefSys(_refSys);
        tradingTaxes = _newTradingTaxes;
    }

    event NewSaintbotDeployment(
        address deployedContract, address uniV2Pool, address owner, bytes _ref, address _addressRef
    );

    error ERC1167FailedCreateClone();
}