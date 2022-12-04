// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "./EIP712.sol";
import "./IUUPSERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";
import "../Library/StringHelper.sol";

abstract contract UUPSERC20 is EIP712, IUUPSERC20
{
    bytes32 private constant TotalSupplySlot = keccak256("SLOT:UUPSERC20:totalSupply");
    bytes32 private constant BalanceSlotPrefix = keccak256("SLOT:UUPSERC20:balanceOf");
    bytes32 private constant AllowanceSlotPrefix = keccak256("SLOT:UUPSERC20:allowance");
    bytes32 private constant NoncesSlotPrefix = keccak256("SLOT:UUPSERC20:nonces");

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable nameBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    bytes32 private immutable symbolBytes;
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    uint8 public immutable decimals;

    bool public constant isUUPSERC20 = true;
    bytes32 private constant permitTypeHash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(string memory _name, string memory _symbol, uint8 _decimals) 
        EIP712(_name)
    {
        nameBytes = StringHelper.toBytes32(_name);
        symbolBytes = StringHelper.toBytes32(_symbol);
        decimals = _decimals;
    }

    function name() public view returns (string memory) { return StringHelper.toString(nameBytes); }
    function symbol() public view returns (string memory) { return StringHelper.toString(symbolBytes); }
    function version() public pure returns (string memory) { return "1"; }

    function balanceSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(BalanceSlotPrefix, user))); }
    function allowanceSlot(address owner, address spender) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(AllowanceSlotPrefix, owner, spender))); }
    function noncesSlot(address user) private pure returns (StorageSlot.Uint256Slot storage) { return StorageSlot.getUint256Slot(keccak256(abi.encodePacked(NoncesSlotPrefix, user))); }

    function totalSupply() public view returns (uint256) { return StorageSlot.getUint256Slot(TotalSupplySlot).value; }
    function balanceOf(address user) public view returns (uint256) { return balanceSlot(user).value; }
    function allowance(address owner, address spender) public view returns (uint256) { return allowanceSlot(owner, spender).value; }
    function nonces(address user) public view returns (uint256) { return noncesSlot(user).value; }

    function checkUpgrade(address newImplementation)
        internal
        virtual
        view
    {
        assert(IUUPSERC20(newImplementation).isUUPSERC20());
        assert(EIP712(newImplementation).nameHash() == nameHash);
    }

    function approveCore(address _owner, address _spender, uint256 _amount) internal returns (bool)
    {
        allowanceSlot(_owner, _spender).value = _amount;
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    function transferCore(address _from, address _to, uint256 _amount) internal returns (bool)
    {
        if (_from == address(0)) { revert TransferFromZeroAddress(); }
        if (_to == address(0)) 
        {
            burnCore(_from, _amount);
            return true;
        }
        StorageSlot.Uint256Slot storage fromBalanceSlot = balanceSlot(_from);
        uint256 oldBalance = fromBalanceSlot.value;
        if (oldBalance < _amount) { revert InsufficientBalance(); }
        beforeTransfer(_from, _to, _amount);
        unchecked 
        {
            fromBalanceSlot.value = oldBalance - _amount; 
            balanceSlot(_to).value += _amount;
        }
        emit Transfer(_from, _to, _amount);
        afterTransfer(_from, _to, _amount);
        return true;
    }

    function mintCore(address _to, uint256 _amount) internal
    {
        if (_to == address(0)) { revert MintToZeroAddress(); }
        beforeMint(_to, _amount);
        StorageSlot.getUint256Slot(TotalSupplySlot).value += _amount;
        unchecked { balanceSlot(_to).value += _amount; }
        afterMint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    function burnCore(address _from, uint256 _amount) internal
    {
        StorageSlot.Uint256Slot storage fromBalance = balanceSlot(_from);
        uint256 oldBalance = fromBalance.value;
        if (oldBalance < _amount) { revert InsufficientBalance(); }
        beforeBurn(_from, _amount);
        unchecked
        {
            fromBalance.value = oldBalance - _amount;
            StorageSlot.getUint256Slot(TotalSupplySlot).value -= _amount;
        }
        emit Transfer(_from, address(0), _amount);
        afterBurn(_from, _amount);
    }

    function approve(address _spender, uint256 _amount) public returns (bool)
    {
        return approveCore(msg.sender, _spender, _amount);
    }

    function transfer(address _to, uint256 _amount) public returns (bool)
    {
        return transferCore(msg.sender, _to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool)
    {
        StorageSlot.Uint256Slot storage fromAllowance = allowanceSlot(_from, msg.sender);
        uint256 oldAllowance = fromAllowance.value;
        if (oldAllowance != type(uint256).max) 
        {
            if (oldAllowance < _amount) { revert InsufficientAllowance(); }
            unchecked { fromAllowance.value = oldAllowance - _amount; }
        }
        return transferCore(_from, _to, _amount);
    }

    function beforeTransfer(address _from, address _to, uint256 _amount) internal virtual {}
    function afterTransfer(address _from, address _to, uint256 _amount) internal virtual {}
    function beforeBurn(address _from, uint256 _amount) internal virtual {}
    function afterBurn(address _from, uint256 _amount) internal virtual {}
    function beforeMint(address _to, uint256 _amount) internal virtual {}
    function afterMint(address _to, uint256 _amount) internal virtual {}

    function DOMAIN_SEPARATOR() public view returns (bytes32) { return domainSeparator(); }

    function permit(address _owner, address _spender, uint256 _amount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public
    {
        if (block.timestamp > _deadline) { revert DeadlineExpired(); }
        uint256 nonce;
        unchecked { nonce = noncesSlot(_owner).value++; }
        address signer = ecrecover(getSigningHash(keccak256(abi.encode(permitTypeHash, _owner, _spender, _amount, nonce, _deadline))), _v, _r, _s);
        if (signer != _owner || signer == address(0)) { revert InvalidPermitSignature(); }
        approveCore(_owner, _spender, _amount);
    }
}