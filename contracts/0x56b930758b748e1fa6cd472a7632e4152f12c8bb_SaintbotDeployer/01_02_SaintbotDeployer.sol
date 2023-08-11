// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ModelERC20V2} from "src/ModelERC20V2.sol";

// ALL CONTRACTS DEPLOYED USING OUR FACTORY ARE ANTI-RUG BY DEFAULT: CONTRACT RENOUNCED, LIQ LOCKED FOR 90 DAYS, CANT CHANGE ANY VARIABLE
// Saintbot
// Deploy and manage fair launch anti-rug tokens seamlessly and lightning-fast with low gas on our free-to-use Telegram bot.
// Website: saintbot.app/
// Twitter: twitter.com/TeamSaintbot
// Telegram Bot: https://t.me/saintbot_deployer_bot
// Tutorials: learn.saintbot.app/
// Youtube: https://www.youtube.com/@TeamSaintbot

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
}

contract SaintbotDeployer is Ownable {
    struct UnlockLp {
        address owner;
        uint256 endCooldown;
    }

    address public immutable implementation;

    address public ethLiquidityTax;
    address public tradingTaxes;

    mapping(address => UnlockLp) public lockedLp;

    constructor() {
        implementation = address(new ModelERC20V2());
    }

    function deployNew(string memory _name, string memory _symbol)
        external
        payable
        returns (address token, address uniPair)
    {
        require(msg.value > 0, "weth liquidity need to be bigger than 0");

        token = _clone(implementation);

        uniPair = ModelERC20V2(payable(token)).init{value: msg.value}(_name, _symbol, msg.sender);

        lockedLp[uniPair] = UnlockLp(msg.sender, block.timestamp + 90 days);

        emit NewSaintbotDeployment(token, uniPair, msg.sender);
    }

    function unlockLp(address _lp) external {
        UnlockLp memory lp = lockedLp[_lp];

        require(lp.owner == msg.sender, "auth");
        require(lp.endCooldown < block.timestamp, "locked");

        IERC20 lp_ = IERC20(_lp);

        lp_.transfer(msg.sender, lp_.balanceOf(address(this)));
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
    function updateMultisig(address _ethLiquidityTax, address _newTradingTaxes) external onlyOwner {
        ethLiquidityTax = _ethLiquidityTax;
        tradingTaxes = _newTradingTaxes;
    }

    event NewSaintbotDeployment(address deployedContract, address uniV2Pool, address owner);

    error ERC1167FailedCreateClone();
}