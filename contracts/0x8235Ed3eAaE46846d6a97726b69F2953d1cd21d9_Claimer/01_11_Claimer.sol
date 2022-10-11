pragma solidity ^0.8.17;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Claimer is Ownable {
    IERC20 public coinAddress;

    struct CallData {
        uint256 contractId;
        uint256 tokenId;
    }

    struct ClaimInfo {
        bool enabled;
        IERC721 tokens;
        uint256 coinsPerClaim;
        uint64 totalClaimed;
        mapping(uint256 => address) claimed;
    }

    ClaimInfo[] private claims;

    event Setup(
        uint256 indexed claimId,
        IERC721 indexed tokens,
        uint256 coinsPerClaim,
        uint256 totalClaimed
    );
    event Toggle(uint256 indexed claimId, bool enabled);
    event UpdateClaimCoins(uint256 indexed claimId, uint256 coinsPerClaim);

    event Claim(
        uint256 indexed claimId,
        uint256 indexed tokenId,
        address indexed user
    );

    /* how many heartcoin does this contract have */
    function contractBalance() external view returns (uint256) {
        return coinAddress.balanceOf(address(this));
    }

    /* how many heartcoin does the caller have */
    function coinBalance() external view returns (uint256) {
        return coinAddress.balanceOf(msg.sender);
    }

    function setCoinAddress(IERC20 _coinAddress) external onlyOwner {
        coinAddress = _coinAddress;
    }

    function setupClaim(IERC721 tokens, uint256 coinsPerClaim)
        external
        onlyOwner
        returns (uint256)
    {
        uint256 id = claims.length;

        ClaimInfo storage info = claims.push();
        info.enabled = false;
        info.tokens = tokens;
        info.coinsPerClaim = coinsPerClaim;

        emit Setup(id, tokens, coinsPerClaim, 0);
        return id;
    }

    function toggle(uint256 id, bool enabled) external onlyOwner {
        claims[id].enabled = enabled;
        emit Toggle(id, enabled);
    }

    function updateClaimCoins(uint256 id, uint256 coinsPerClaim)
        external
        onlyOwner
    {
        claims[id].coinsPerClaim = coinsPerClaim;
        emit UpdateClaimCoins(id, coinsPerClaim);
    }

    function claim(uint256 id, uint256 tokenId) public {
        ClaimInfo storage info = claims[id]; // revert if out-of-bound;

        require(info.enabled, "Claim not active");
        require(info.tokens.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(info.claimed[tokenId] == address(0), "Token already claimed");
        info.claimed[tokenId] = msg.sender;
        info.totalClaimed += 1;

        SafeERC20.safeTransfer(
            coinAddress,
            msg.sender,
            info.coinsPerClaim * (1 ether)
        );

        emit Claim(id, tokenId, msg.sender);
    }

    function batchClaim(CallData[] calldata _calldata) external {
        for (uint256 i = 0; i < _calldata.length; ++i) {
            claim(_calldata[i].contractId, _calldata[i].tokenId);
        }
    }

    function claimsCount() external view returns (uint256) {
        return claims.length;
    }

    function claimsDetails(uint256 id)
        external
        view
        returns (
            bool,
            IERC721,
            uint256,
            uint256
        )
    {
        ClaimInfo storage info = claims[id]; // revert if out-of-bound;
        return (
            info.enabled,
            info.tokens,
            info.coinsPerClaim,
            info.totalClaimed
        );
    }

    function claimedByToken(uint256 id, uint256 tokenId)
        external
        view
        returns (address)
    {
        return claims[id].claimed[tokenId]; // revert if out-of-bound;
    }

    // DANGER: this will block all claims that use this asset.
    function withdraw(IERC20 asset) external onlyOwner {
        SafeERC20.safeTransfer(
            asset,
            msg.sender,
            asset.balanceOf(address(this))
        );
    }
}