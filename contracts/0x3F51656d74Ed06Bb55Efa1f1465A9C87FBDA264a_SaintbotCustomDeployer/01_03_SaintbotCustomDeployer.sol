// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ModelERC20V2} from "src/ModelERC20V2.sol";

// ALL CONTRACTS DEPLOYED USING OUR FACTORY ARE ANTI-RUG BY DEFAULT: CONTRACT RENOUNCED, LIQ LOCKED FOR AT LEAST 30 DAYS, CANT CHANGE ANY VARIABLE!
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

interface IRefSys {
    function getRefReceiver(bytes memory _refCode) external view returns (address receiverWallet);
}

interface IERCBurn {
    function burn(uint256 _amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUNCX {
    function lockLPToken(
        address _lpToken,
        uint256 _amount,
        uint256 _unlock_date,
        address payable _referral,
        bool _fee_in_eth,
        address payable _withdrawer
    ) external payable;
}

contract SaintbotCustomDeployer is Ownable {
    IUNCX public constant LOCKER = IUNCX(0x663A5C229c09b049E36dCc11a9B0d4a8Eb9db214);

    address public immutable implementation;

    address public ethLiquidityTax;
    address public tradingTaxes;

    IRefSys public refSys;

    constructor() {
        implementation = address(new ModelERC20V2());
    }

    function deployNew(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _lockTime,
        uint256 _buyTaxes,
        uint256 _sellTaxes,
        address _lockOwnerAndTaxReceiver,
        bytes memory _ref
    ) external payable returns (address token, address uniPair) {
        require(msg.value >= 0.3 ether, "weth liquidity need to be bigger than 0.3");
        require(_totalSupply >= 500_000 && _totalSupply <= 1_000_000_000, "InvalidSupply()");
        require(_lockTime > 0 && _lockTime % 30 days == 0, "InvalidLock()");
        require(_buyTaxes >= 1 && _buyTaxes <= 7, "InvalidTaxes()");
        require(_sellTaxes >= 1 && _sellTaxes <= 7, "InvalidTaxes()");

        address owner_ = _validateAddress(_lockOwnerAndTaxReceiver);

        token = _clone(implementation);

        uniPair = ModelERC20V2(payable(token)).init{value: msg.value - 0.08 ether}(
            _name, _symbol, owner_, refSys.getRefReceiver(_ref), _totalSupply, _buyTaxes, _sellTaxes
        );

        IERCBurn(uniPair).approve(address(LOCKER), IERC20(uniPair).balanceOf(address(this)));

        LOCKER.lockLPToken{value: 0.08 ether}(
            uniPair,
            IERC20(uniPair).balanceOf(address(this)),
            block.timestamp + _lockTime,
            payable(address(0)),
            true,
            payable(owner_)
        );

        emit NewSaintbotDeployment(token, uniPair, owner_, _buyTaxes, _sellTaxes, _lockOwnerAndTaxReceiver, _ref);
    }

    function _validateAddress(address _lockAndTaxWallets) private view returns (address) {
        if (_lockAndTaxWallets == address(0)) {
            return msg.sender;
        } else {
            uint256 size;

            assembly {
                size := extcodesize(_lockAndTaxWallets)
            }

            require(size == 0, "Contract()");

            return _lockAndTaxWallets;
        }
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
        tradingTaxes = _newTradingTaxes;
        refSys = IRefSys(_refSys);
    }

    event NewSaintbotDeployment(
        address deployedContract,
        address uniV2Pool,
        address owner,
        uint256 _buyTaxes,
        uint256 _sellTax,
        address _owner,
        bytes _ref
    );

    error ERC1167FailedCreateClone();
}