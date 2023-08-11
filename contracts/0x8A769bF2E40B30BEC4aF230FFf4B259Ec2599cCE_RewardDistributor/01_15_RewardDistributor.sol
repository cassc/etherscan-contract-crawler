// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RewardDistributor is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant MOD = keccak256("MOD");
    bytes32 public constant ADMIN = keccak256("ADMIN");

    address public signer;
    mapping(address => mapping(address => uint256)) public claimedToken;
    mapping(address => mapping(address => uint256)) public claimedDirect;
    mapping(address => mapping(address =>uint256)) public isDirect;

    event SignerChanged(address newSigner);
    event UserClaimed(address user, address token, uint256 amount);
    event UserDirectClaimed(address user, address token, uint256 directClaimPercent, uint256 amount);

    function initialize(
        address _signer,
        address _admin,
        address _mod
    ) public initializer {
        __AccessControl_init();
        __Pausable_init();
        _setRoleAdmin(MOD, ADMIN);
        _setRoleAdmin(ADMIN, ADMIN);
        _setupRole(ADMIN, _admin);
        _setupRole(MOD, _mod);
        require(_signer != address(0), "RewardDistributor: invalid address");
        signer = _signer;
        emit SignerChanged(_signer);
    }

    function pauseContract () external {
        require(
            hasRole(MOD, msg.sender),
            "RewardDistributor: require MOD role"
        );

        _pause();
    }


    function unPauseContract() external {
        require(
            hasRole(MOD, msg.sender),
            "RewardDistributor: require MOD role"
        );

        _unpause();
    }

    function changeSigner(address newSigner) external whenNotPaused {
        require(
            hasRole(MOD, msg.sender),
            "RewardDistributor: require MOD role"
        );

        signer = newSigner;
        emit SignerChanged(newSigner);
    }

    function claimRewards(
        address _token,
        uint256 _amount,
        uint256 _directClaimPercent,
        bytes calldata _signature
    ) external whenNotPaused {
        bytes32 _messageHash = getMessageHash(_amount, _msgSender(), _token, _directClaimPercent);
        require(
            _verifySignature(_messageHash, _signature),
            "RewardDistributor: invalid signature"
        );
        require(_directClaimPercent == 0 || isDirect[msg.sender][_token] < _directClaimPercent, "Invalid direct claim");
        uint256 claimAmount = _amount - claimedToken[msg.sender][_token];
        require(
            IERC20(_token).balanceOf(address(this)) >= claimAmount,
            "RewardDistributor: not enough amount"
        );

        claimedToken[msg.sender][_token] += claimAmount;
        if (_directClaimPercent > 0) {
            isDirect[msg.sender][_token] = _directClaimPercent;
            claimedDirect[msg.sender][_token] += claimAmount;
            emit UserDirectClaimed(_msgSender(), _token, _directClaimPercent, claimAmount);
        } else {
            emit UserClaimed(_msgSender(), _token, claimAmount);
        }
        require(
            IERC20(_token).transfer(_msgSender(), claimAmount),
            "RewardDistributor: transfer failed"
        );

    }

    function adminWithdraw(address _token, uint256 _amount)
    external
    whenNotPaused
    {
        require(
            hasRole(ADMIN, msg.sender),
            "RewardDistributor: require ADMIN role"
        );

        require(
            IERC20(_token).balanceOf(address(this)) >= _amount,
            "RewardDistributor: not enough amount"
        );

        IERC20(_token).transfer(_msgSender(), _amount);
    }

    // Using Openzeppelin ECDSA cryptography library

    function getMessageHash(
        uint256 _amount,
        address _user,
        address _token,
        uint256 _directClaimPercent
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_amount, _user, _token, _directClaimPercent));
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