// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.11;

import "./interfaces/IERC20Query.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AstaSwapBridge is Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(string => bool) private registeredBEP20;
    mapping(bytes32 => bool) public filledOtherChainsTx;

    address payable public owner;
    address public superAdmin;
    address payable public feeReceiver;
    uint256 public swapFee;
    uint256 public feePercentageInAsta;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event SuperAdminChanged(
        address indexed previousSuperAdmin,
        address indexed newSuperAdmin
    );
    event FeeReceiverUpdated(
        address indexed prevFeeReceiver,
        address indexed newFeeReceiver
    );
    event SwapPairRegisterFor(
        address indexed sponsor,
        address indexed eth20Addr,
        string name,
        string symbol,
        uint8 decimals,
        string pair
    );
    event SwapStarted(
        address indexed eth20Addr,
        address indexed fromAddr,
        uint256 amount,
        uint256 feeAmount,
        uint256 feeInAsta,
        string chain
    );
    event SwapFilled(
        address indexed eth20Addr,
        bytes32 indexed inputTxHash,
        address indexed toAddress,
        uint256 amount
    );

    constructor(
        uint256 fee_Native,
        uint256 fee_PerAsta,
        address payable fee_Receiver,
        address super_Admin
    ) {
        swapFee = fee_Native;
        feePercentageInAsta = fee_PerAsta;
        owner = payable(msg.sender);
        feeReceiver = fee_Receiver;
        superAdmin = super_Admin;
    }

    /**
     * Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * Throws if called transferOwnership by any account other than the super admin.
     */
    modifier onlySuperAdmin() {
        require(
            superAdmin == _msgSender(),
            "Super Admin: caller is not the super admin"
        );
        _;
    }

    modifier notContract() {
        require(!isContract(msg.sender), "contract is not allowed to swap");
        _;
    }

    modifier noProxy() {
        require(msg.sender == tx.origin, "no proxy is allowed");
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /**
     * Leaves the contract without owner. It will not be possible to call
     * `onlySuperAdmin` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlySuperAdmin {
        emit OwnershipTransferred(owner, address(0));
        owner = payable(0);
    }

    /**
     * Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlySuperAdmin {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * Change Super Admin of the contract to a new account (`newSuperAdmin`).
     * Can only be called by the current super admin.
     */
    function changeSuperAdmin(address newSuperAdmin) public onlySuperAdmin {
        require(
            newSuperAdmin != address(0),
            "Super Admin: new super admin is the zero address"
        );
        emit SuperAdminChanged(superAdmin, newSuperAdmin);
        superAdmin = newSuperAdmin;
    }

    /**
     * Transfers fee receiver to a new account (`newFeeReceiver`).
     * Can only be called by the current owner.
     */
    function changeFeeReceiver(address payable newFeeReceiver)
        public
        onlySuperAdmin
    {
        require(
            newFeeReceiver != address(0),
            "Fee Receiver: new fee receiver address is zero "
        );
        emit FeeReceiverUpdated(feeReceiver, newFeeReceiver);
        feeReceiver = newFeeReceiver;
    }

    /**
     * Returns set minimum swap fee from BEP20 to other chains
     */
    function setSwapFee(uint256 fee) external onlyOwner {
        swapFee = fee;
    }

    /**
     * Returns set minimum swap fee in ASTA from BEP20 to other chains
     */
    function setSwapFeePercentageOfASTA(uint256 _feePerAsta)
        external
        onlyOwner
    {
        require(
            _feePerAsta < 100000000000000000000,
            "feePercentageInAsta: Greater than 100 %"
        );
        feePercentageInAsta = _feePerAsta;
    }

    /**
     * Register swap pair for chain
     */
    function registerSwapPair(address eth20Addr, string calldata chain)
        external
        onlyOwner
        returns (bool)
    {
        require(
            !registeredBEP20[string(abi.encode(eth20Addr, chain))],
            "already registered"
        );

        string memory name = IERC20Query(eth20Addr).name();
        string memory symbol = IERC20Query(eth20Addr).symbol();
        uint8 decimals = IERC20Query(eth20Addr).decimals();

        require(bytes(name).length > 0, "empty name");
        require(bytes(symbol).length > 0, "empty symbol");

        registeredBEP20[string(abi.encode(eth20Addr, chain))] = true;

        emit SwapPairRegisterFor(
            msg.sender,
            eth20Addr,
            name,
            symbol,
            decimals,
            chain
        );
        return true;
    }

    /**
     * Fill swap by BEP20
     */
    function fillSwap(
        bytes32 crossChainTxHash,
        address eth20Addr,
        address toAddress,
        uint256 amount,
        string calldata chain
    ) external onlyOwner returns (bool) {
        require(!filledOtherChainsTx[crossChainTxHash], "tx filled already");
        require(
            registeredBEP20[string(abi.encode(eth20Addr, chain))],
            "not registered token"
        );
        require(amount > 0, "Amount should be greater than 0");

        IERC20(eth20Addr).safeTransfer(toAddress, amount);
        filledOtherChainsTx[crossChainTxHash] = true;

        emit SwapFilled(eth20Addr, crossChainTxHash, toAddress, amount);
        return true;
    }

    /**
     * Swap BEP20 on other chain
     */
    function swapToken(
        address eth20Addr,
        uint256 amount,
        string calldata chain
    ) external payable notContract noProxy returns (bool) {
        require(
            registeredBEP20[string(abi.encode(eth20Addr, chain))],
            "not registered token"
        );
        require(msg.value >= swapFee, "swap fee is not enough");
        require(amount > 0, "Amount should be greater than 0");
        require(
            feePercentageInAsta < 100000000000000000000,
            "feePercentageInAsta: Greater than 100 %"
        );

        uint256 feeAmountInAsta = 0;
        if (feePercentageInAsta > 0) {
            feeAmountInAsta = amount.mul(feePercentageInAsta);
            feeAmountInAsta = feeAmountInAsta.div(100000000000000000000);
            amount = amount.sub(feeAmountInAsta);
            IERC20(eth20Addr).safeTransferFrom(
                msg.sender,
                feeReceiver,
                feeAmountInAsta
            );
        }

        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        IERC20(eth20Addr).safeTransferFrom(msg.sender, address(this), amount);

        emit SwapStarted(
            eth20Addr,
            msg.sender,
            amount,
            msg.value,
            feeAmountInAsta,
            chain
        );
        return true;
    }

    /**
     * Check the token pair
     */
    function getRegisteredPairs(address eth20Addr, string calldata chain)
        external
        view
        returns (bool)
    {
        return registeredBEP20[string(abi.encode(eth20Addr, chain))];
    }
}