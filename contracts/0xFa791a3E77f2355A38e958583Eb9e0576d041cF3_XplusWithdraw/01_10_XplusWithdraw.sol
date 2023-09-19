// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/TransferHelper.sol";


contract XplusWithdraw is Ownable,Pausable{

    using ECDSAUpgradeable for bytes32;

    event WithdrawRecord(uint256 bizId, uint256 destChainId, uint256[] amounts, address[] tokens, address[] accounts, address recipient, uint256 timestamp);
    event RelayerChanged(address oldRelayer, address newRelayer);
    event AllowWithdraw(uint256 bizId, bool isAllow);
    event RescueWithdraw(address token, address form, address to, uint256 amount);

    modifier onlyOperator() {
        require(msg.sender == relayer || msg.sender == owner(), "XplusWithdraw: operator only");
        _;
    }
    struct WithdrawData {
        uint256 bizId;
        uint256[] amounts;
        address[] tokens;
        address[] accounts;
        address recipient;
        uint256 timestamp;
    }

    uint256 public currentChainId;

    address public relayer;

    mapping(uint256 => WithdrawData) private _withdrawRecords;

    mapping(uint256 => bool) private _blacklist;

    mapping(address => uint256) public withdrawalTotal;

    bytes32 public DOMAIN_SEPARATOR; // For EIP-712

    bytes32 public constant WITHDRAW_TYPEHASH = keccak256(
        "Withdraw(uint256 bizId,uint256 destChainId,uint256[] amounts,address[] tokens,address[] accounts,address recipient)"
    );

    constructor(address _relayer) {
        _init(_relayer);
    }

    function setRelayer(address _relayer) external onlyOwner {
        _setRelayer(_relayer);
    }

    function _setRelayer(address _relayer) private {
        require(_relayer != address(0), "XplusWithdraw: zero address");
        require(_relayer != relayer, "XplusWithdraw: relayer not changed");

        address oldRelayer = relayer;
        relayer = _relayer;

        emit RelayerChanged(oldRelayer, relayer);
    }

    function _init(address _relayer) private {
        _setRelayer(_relayer);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        currentChainId = chainId;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("XPLUS")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    receive() external payable {}

    function withdraw(
        uint256 bizId,
        uint256 destChainId,
        uint256[] memory amounts,
        address[] memory tokens,
        address[] memory accounts,
        address recipient,
        bytes memory signature
    ) external whenNotPaused {
        require(bizId > 0, "XplusWithdraw: wrong bizId");
        require(!_blacklist[bizId],"XplusWithdraw: refused withdrawn");
        require(_withdrawRecords[bizId].bizId == 0, "XplusWithdraw: already withdrawn");
        require(destChainId == currentChainId, "XplusWithdraw: wrong chain");
        require(recipient != address(0), "XplusWithdraw: zero address");
        require(amounts.length > 0 && amounts.length == tokens.length && amounts.length == accounts.length, "XplusWithdraw: invalid input");

        // Verify EIP-712 signature
        bytes32 digest =
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        WITHDRAW_TYPEHASH,
                        bizId,
                        destChainId,
                        keccak256(abi.encodePacked(amounts)),
                        keccak256(abi.encodePacked(tokens)),
                        keccak256(abi.encodePacked(accounts)),
                        recipient
                    )
                )
            )
        );
        address recoveredAddress = digest.recover(signature);
        require(recoveredAddress == relayer, "XplusWithdraw: invalid signature");

        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "XplusWithdraw: invalid cashier account");
            require(amounts[i] > 0, "XplusWithdraw: invalid withdraw amount");
            //origin token
            if(tokens[i] == address(0)){
                require(accounts[i] == address(this), "XplusWithdraw: invalid cashier account");
                TransferHelper.safeTransferETH(recipient, amounts[i]);
            }else{
                if(accounts[i] == address(this)){
                    TransferHelper.safeTransfer(tokens[i], recipient, amounts[i]);
                }else{
                    TransferHelper.safeTransferFrom(tokens[i], accounts[i], recipient, amounts[i]);
                }
            }
            withdrawalTotal[tokens[i]] += amounts[i];
        }

        WithdrawData memory withdrawData = WithdrawData({
            bizId: bizId,
            amounts: amounts,
            tokens: tokens,
            accounts: accounts,
            recipient: recipient,
            timestamp: block.timestamp
        });

        _withdrawRecords[bizId] = withdrawData;

        emit WithdrawRecord(bizId, destChainId, amounts, tokens, accounts, recipient,block.timestamp);
    }

    function allowWithdraw(uint256 bizId, bool isAllow) external onlyOperator{
        require(bizId > 0, "XplusWithdraw: wrong bizId");
        require(_withdrawRecords[bizId].bizId == 0, "XplusWithdraw: already withdrawn");
        if(isAllow){
            require(_blacklist[bizId],"XplusWithdraw: already allowed");
            _blacklist[bizId] = false;
        }else{
            require(!_blacklist[bizId],"XplusWithdraw: already not allowed");
            _blacklist[bizId] = true;
        }
        emit AllowWithdraw(bizId,isAllow);
    }

    function rescueWithdraw(address token,address to) external onlyOwner whenPaused {
        uint256 amount = 0;
        if (token == address(0)) {
            amount = address(this).balance;
            require(amount > 0, "XplusWithdraw: zero balance");
            TransferHelper.safeTransferETH(to,amount);
        }else{
            amount = IERC20(token).balanceOf(address(this));
            require(amount > 0, "XplusWithdraw: zero balance");
            TransferHelper.safeTransfer(token,to,amount);
        }
        emit RescueWithdraw(token,address(this),to,amount);
    }

    function pause() public onlyOperator {
        _pause();
    }

    function unpause() public onlyOperator {
        _unpause();
    }

    function getWithdrawData(uint256 bizId) external view returns (WithdrawData memory){
        return _withdrawRecords[bizId];
    }

    function isAllowWithdraw(uint256 bizId) external view returns(bool){
        return !_blacklist[bizId];
    }
}