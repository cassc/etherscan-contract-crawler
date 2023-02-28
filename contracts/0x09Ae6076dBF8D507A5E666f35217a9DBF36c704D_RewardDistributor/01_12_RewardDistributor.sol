// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract RewardDistributor is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    bytes32 public constant MOD = keccak256("MOD");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    event UserClaimed(address user, uint256 amount);
    event SignerChanged(address newSigner);

    address public signer;
    mapping(address => mapping(address => uint256)) public claimedToken;

    constructor(address _signer) {
        _setRoleAdmin(MOD, ADMIN);
        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, msg.sender);
        _setupRole(MOD, msg.sender);

        require(_signer != address(0), "AllocationPool: invalid address");

        signer = _signer;

        emit SignerChanged(_signer);
    }

    function pauseContract () external {
        require(
            hasRole(MOD, msg.sender),
            "RewardDistrobutor: require MOD role"
        );

        _pause();
    }


    function unPauseContract () external {
        require(
            hasRole(MOD, msg.sender),
            "RewardDistrobutor: require MOD role"
        );

        _unpause();
    }

    function changeSigner(address newSigner) external whenNotPaused {
        require(
            hasRole(MOD, msg.sender),
            "RewardDistrobutor: require MOD role"
        );

        signer = newSigner;
        emit SignerChanged(newSigner);
    }

    function claimRewards(
        address _token,
        uint256 _amount,
        bytes calldata _signature
    ) external whenNotPaused {
        bytes32 _messageHash = getMessageHash(_amount, _msgSender(), _token);
        require(
            _verifySignature(_messageHash, _signature),
            "RewardDistrobutor: invalid signature"
        );
        uint256 claimAmount = _amount - claimedToken[msg.sender][_token];
        require(
            IERC20(_token).balanceOf(address(this)) >= claimAmount,
            "RewardDistrobutor: inffuse amount"
        );

        claimedToken[msg.sender][_token] += claimAmount;
        require(
            IERC20(_token).transfer(_msgSender(), claimAmount),
            "RewardDistrobutor: transfer failed"
        );

        emit UserClaimed(_msgSender(), claimAmount);
    }

    function adminWithdraw(address _token, uint256 _amount)
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN, msg.sender),
            "RewardDistrobutor: require ADMIN role"
        );

        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "RewardDistrobutor: inffuse amount"
        );

        IERC20(_token).transfer(_msgSender(), _amount);
    }

    // Using Openzeppelin ECDSA cryptography library

    function getMessageHash(
        uint256 _amount,
        address _user,
        address _token
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_amount, _user, _token));
    }

    // Verify signature function
    function _verifySignature(bytes32 _msgHash, bytes calldata signature)
        public
        view
        returns (bool)
    {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_msgHash);

        return getSignerAddress(ethSignedMessageHash, signature) == signer;
    }

    function getSignerAddress(bytes32 _messageHash, bytes memory _signature)
        public
        pure
        returns (address)
    {
        return ECDSA.recover(_messageHash, _signature);
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return ECDSA.toEthSignedMessageHash(_messageHash);
    }
}