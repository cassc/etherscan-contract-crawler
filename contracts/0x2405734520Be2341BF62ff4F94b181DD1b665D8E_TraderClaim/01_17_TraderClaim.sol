// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TraderClaim is ReentrancyGuard, EIP712, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public immutable signer = address(0xBf1B0912F22bc74C23Da8bC3A297C7251536c1D5);

    IERC20 public immutable monToken = IERC20(0xcaCc19C5Ca77E06D6578dEcaC80408Cc036e0499);

    mapping(bytes32 => bool) public claimLog;

    bytes32 public constant CLAIM_HASH_TYPE = keccak256("claim(address wallet,uint8 period,uint256 amount)");
    event Claim(address indexed account, uint256 period, uint256 amount);

    constructor() EIP712("TraderClaim", "1.0") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function claim(
        uint8 period,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s)
    public nonReentrant {
        bytes32 receiver = keccak256(abi.encodePacked(msg.sender, period));
        require(!claimLog[receiver], "TraderClaim: already claimed");
        require(amount > 0, "invalid amount");

        bytes32 digest = ECDSA.toTypedDataHash(
            _domainSeparatorV4(),
            keccak256(abi.encode(CLAIM_HASH_TYPE, msg.sender, period, amount))
        );
        require(
            ecrecover(digest, v, r, s) == signer,
            "TraderClaim: Invalid signer"
        );

        claimLog[receiver] = true;
        monToken.transfer(msg.sender, amount);
        emit Claim(msg.sender, period, amount);
    }

    function emergencyWithdraw(address wallet) public  onlyRole(DEFAULT_ADMIN_ROLE) {
        monToken.transfer(wallet, monToken.balanceOf(address(this)));
    }
}