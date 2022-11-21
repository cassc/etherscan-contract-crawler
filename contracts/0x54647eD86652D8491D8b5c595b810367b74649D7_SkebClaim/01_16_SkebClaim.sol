// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../ISkebStaking.sol";
import "../util/TGPausable.sol";
import "../util/VerifySignature.sol";
import "./ISkebClaim.sol";

contract SkebClaim is TGPausable, ReentrancyGuard, VerifySignature, ISkebClaim {
    mapping(address => uint256) public latestUserTermId;
    uint256 public currentTermId = 1;
    IERC20 public skebcoin;
    ISkebStaking public staking;

    bytes32 public constant SIGNER_ROLE = keccak256("Signer");

    constructor(IERC20 _skebcoin, ISkebStaking _staking) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        skebcoin = _skebcoin;
        staking = _staking;
        skebcoin.approve(address(staking), 10**28);
    }

    function claim(
        address signer,
        address user,
        uint256 amount,
        uint256 expiry,
        bytes memory sig
    ) external override nonReentrant whenNotPaused {
        require(user == msg.sender, "Error: Invalid sender");
        require(block.timestamp < expiry, "Error: Signature already expired");
        require(isSigner(signer), "Error: Invalid Signer");
        require(
            currentClaimableId() > latestUserTermId[user],
            "Invalid term Id"
        );
        require(
            validateSignature(
                signer,
                user,
                amount,
                expiry,
                sig,
                currentClaimableId()
            ),
            "Error: Invalid Signature"
        );
        staking.stakeFor(user, uint128(amount));
        latestUserTermId[user] = currentClaimableId();
    }

    function incrementTermId() external override onlyAdmin {
        currentTermId++;
    }

    function changeTermId(uint256 newTermId) external override onlyAdmin {
        require(newTermId != 0, "Error: termid != 0");
        currentTermId = newTermId;
    }

    function currentClaimableId() public view returns (uint256) {
        return currentTermId - 1;
    }

    function grantSigner(address newSigner) external override onlyAdmin {
        grantRole(SIGNER_ROLE, newSigner);
    }

    function revokeSigner(address oldSigner) external override onlyAdmin {
        _revokeRole(SIGNER_ROLE, oldSigner);
    }

    function isSigner(address signer) public view override returns (bool) {
        return hasRole(SIGNER_ROLE, signer);
    }

    function getTokenBalance() external view override returns (uint256) {
        return skebcoin.balanceOf(address(this));
    }

    function withdrawToken(uint256 amount) external override onlyAdmin {
        require(
            skebcoin.transfer(msg.sender, amount),
            "Error: Withdrawal Failed"
        );
    }

    function createClaimMessage(
        address user,
        uint256 amount,
        uint256 expiry,
        uint256 termId
    ) public pure override returns (bytes32) {
        return keccak256(abi.encodePacked(user, amount, expiry, termId));
    }

    function validateSignature(
        address signer,
        address user,
        uint256 amount,
        uint256 expiry,
        bytes memory sig,
        uint256 termId
    ) public pure override returns (bool) {
        bytes32 message = createClaimMessage(user, amount, expiry, termId);
        return verify(signer, message, sig);
    }
}