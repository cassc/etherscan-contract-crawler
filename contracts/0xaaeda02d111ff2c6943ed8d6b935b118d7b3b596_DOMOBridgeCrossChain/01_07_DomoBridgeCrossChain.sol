// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "./interfaces/ISwap.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";


contract DOMOBridgeCrossChain is Context {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => address) public swapMapping2BSC;
    mapping(address => address) public swapMappingFrmBSC;
    mapping(bytes32 => bool) public filledBSCTx;

    address payable public owner;
    address public superAdmin;
    address payable public feeReceiver;
    uint256 public swapFee;
    uint256 public feePercentageInDOMO;

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
    event SwapPairCreated(
        bytes32 indexed bscRegisterTxHash,
        address indexed gen20Addr,
        address indexed bep20Addr
    );
    event SwapStarted(
        address indexed gen20Addr,
        address indexed bep20Addr,
        address indexed fromAddr,
        uint256 amount,
        uint256 feeAmount,
        uint256 feeInDOMO,
        string chain
    );
    event SwapFilled(
        address indexed bep20Addr,
        bytes32 indexed bscTxHash,
        address indexed toAddress,
        uint256 amount,
        string chain
    );

    constructor(
        uint256 fee_Native,
        uint256 fee_PerDOMO,
        address payable fee_Receiver,
        address super_Admin
    ) {
        swapFee = fee_Native;
        feePercentageInDOMO = fee_PerDOMO;
        feeReceiver = fee_Receiver;
        owner = payable(msg.sender);
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
     * Returns set minimum swap fee
     */
    function setSwapFee(uint256 fee) external onlyOwner {
        swapFee = fee;
    }

    /**
     * Returns set minimum swap fee in DOMO
     */
    function setSwapFeePercentageOfDOMO(uint256 _feePerDOMO)
        external
        onlyOwner
    {
        require(
            _feePerDOMO < 100000000000000000000,
            "feePercentageInDOMO: Greater than 100 %"
        );
        feePercentageInDOMO = _feePerDOMO;
    }

    /**
     * createSwapPair
     */
    function createSwapPair(
        bytes32 bscTxHash,
        address bep20Addr,
        address gen20TokenAddr
    ) external onlyOwner returns (address) {
        require(
            swapMapping2BSC[bep20Addr] == address(0x0),
            "duplicated swap pair"
        );

        swapMapping2BSC[bep20Addr] = address(gen20TokenAddr);
        swapMappingFrmBSC[address(gen20TokenAddr)] = bep20Addr;

        emit SwapPairCreated(
            bscTxHash,
            gen20TokenAddr,
            bep20Addr
        );
        return address(gen20TokenAddr);
    }

    /**
     * fill Swap between 2 chains
     */
    function fillSwap(
        bytes32 requestSwapTxHash,
        address bep20Addr,
        address toAddress,
        uint256 amount,
        string calldata chain
    ) external onlyOwner returns (bool) {
        require(!filledBSCTx[requestSwapTxHash], "bsc tx filled already");
        address genTokenAddr = swapMapping2BSC[bep20Addr];
        require(genTokenAddr != address(0x0), "no swap pair for this token");
        require(amount > 0, "Amount should be greater than 0");

        ISwap(genTokenAddr).mint(toAddress, amount);
        filledBSCTx[requestSwapTxHash] = true;
        emit SwapFilled(
            genTokenAddr,
            requestSwapTxHash,
            toAddress,
            amount,
            chain
        );

        return true;
    }

    /**
     * swap token to other chain
     */
    function swapToken(
        address gen20Addr,
        uint256 amount,
        string calldata chain
    ) external payable notContract noProxy returns (bool) {
        address bep20Addr = swapMappingFrmBSC[gen20Addr];
        require(bep20Addr != address(0x0), "no swap pair for this token");
        require(msg.value >= swapFee, "swap fee is not enough");
        require(amount > 0, "Amount should be greater than 0");
        require(
            feePercentageInDOMO < 100000000000000000000,
            "feePercentageInDOMO: Greater than 100 %"
        );

        uint256 feeAmountInDOMO = 0;
        if (feePercentageInDOMO > 0) {
            feeAmountInDOMO = amount.mul(feePercentageInDOMO);
            feeAmountInDOMO = feeAmountInDOMO.div(100000000000000000000);
            amount = amount.sub(feeAmountInDOMO);
            IERC20(gen20Addr).safeTransferFrom(
                msg.sender,
                feeReceiver,
                feeAmountInDOMO
            );
        }

        if (msg.value != 0) {
            owner.transfer(msg.value);
        }
        IERC20(gen20Addr).safeTransferFrom(msg.sender, address(this), amount);
        ISwap(gen20Addr).burn(amount);

        emit SwapStarted(
            gen20Addr,
            bep20Addr,
            msg.sender,
            amount,
            msg.value,
            feeAmountInDOMO,
            chain
        );
        return true;
    }
}