// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../../libraries/draft-EIP712Upgradable.sol';


contract BonusDistributor is Ownable, EIP712Upgradable {
    using SafeERC20 for IERC20;

    string private constant _NAME = 'YIELD TOKEN DISTRIBUTOR';
    string private constant _VERSION = '1.0';
    address private signer;

    bytes32 constant MESSAGE_TYPEHASH = keccak256('Message(address token,address account,bytes32 key,uint256 amountMax,uint256 expireTime)');

    // account => key  => amount
    mapping(address => mapping(bytes32 => uint256)) private claimedMap;

    constructor(address _signer) {
        _EIP712_init(_NAME, _VERSION);
        updateSigner(_signer);
    }

    //-------------------------------
    //------- Events ----------------
    //-------------------------------
    event WithdrawDust(address token, address to, uint256 amount);
    event Claimed(address account, bytes32 key, uint256 amount, uint256 amountMax, uint256 expireTime);
    event SetSigner(address, address);

    //-------------------------------
    //------- Admin functions -------
    //-------------------------------

    function updateSigner(address newSigner) public onlyOwner {
        require(newSigner != address(0), 'ZERO_ADDRESS');
        address oldSigner = signer;
        signer = newSigner;
        emit SetSigner(oldSigner, newSigner);
    }

    function withdrawDust(
        address _token,
        address _to,
        uint256 _amounts
    ) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amounts);
        emit WithdrawDust(_token, _to, _amounts);
    }

    //-------------------------------
    //------- Users Functions -------
    //-------------------------------

    function claimWithSig(
        address account,
        bytes32 key,
        uint256 amountMax,
        uint256 expireTime,
        bytes calldata signature
    ) external {
        uint256 claimed = claimedMap[account][key];
        require(amountMax > claimed, 'no bonus to claim');

        address token = address(bytes20(key));
        bytes32 digest = keccak256(abi.encode(MESSAGE_TYPEHASH, token, account, key, amountMax, expireTime));
        require(block.timestamp <= expireTime, 'time expired');
        require(validateSig(digest, signature), 'sign error');

        claimed = amountMax - claimed;
        claimedMap[account][key] = amountMax;
        IERC20(token).safeTransfer(account, claimed);
        emit Claimed(account, key, claimed, amountMax, expireTime);
    }

    function getUserClaimedAmount(address user, bytes32 key) external view returns (uint256) {
        return claimedMap[user][key];
    }

    function getSigner() external view returns (address) {
        return signer;
    }

    function validateSig(bytes32 message, bytes memory signature) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(message);

        bytes32 operatorSigR;
        bytes32 operatorSigVs;

        assembly {
            operatorSigR := mload(add(signature, 0x20))
            operatorSigVs := mload(add(signature, 0x40))
        }
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        address signerRecovered = ecrecover(digest, v, r, s);

        return signerRecovered == signer;
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, 'B');

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
}