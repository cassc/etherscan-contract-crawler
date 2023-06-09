// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '../interfaces/IERC20Mintable.sol';
import '../interfaces/IKIKIVault.sol';
import '../core/SafeOwnable.sol';

contract TeamLocker {
    using SafeMath for uint256;

    event NewReceiver(address receiver, uint totalReleaseAmount, uint lastReleaseAt);
    event ReleaseToken(address receiver, uint releaseAmount, uint nextReleaseAmount, uint nextReleaseBlockNum);

    uint constant TEAM_REEASE_RATIO = 2;
    uint constant VAULT_RELEASE_RATIO = 6;
    uint constant ORGANIZATION_PERCENT = 2500;
    uint constant PERCENT_BASE = 10000;

    ///@notice the token to lock
    IERC20 public immutable token;
    IKIKIVault immutable public vault;
    address immutable public developer;
    address immutable public organization;
    uint public userReleased;

    constructor(
        IERC20 _token, IKIKIVault _vault, address _developer, address _organization
    ) {
        require(address(_token) != address(0), "token address is zero");
        token = _token;
        require(address(_vault) != address(0), "vault address is zero");
        vault = _vault;
        require(_developer != address(0), "deployer address is zero");
        developer = _developer;
        require(_organization != address(0), "organization address is zero");
        organization = _organization;
    }

    function claim() external {
        uint vaultReleaseAmount = vault.totalReleaseAmount();
        uint shouldReleaseAmount = vaultReleaseAmount.mul(TEAM_REEASE_RATIO).div(VAULT_RELEASE_RATIO);
        shouldReleaseAmount = shouldReleaseAmount.sub(userReleased);
        userReleased = userReleased.add(shouldReleaseAmount); 
        uint balance = token.balanceOf(address(this));
        if (balance < shouldReleaseAmount) {
            IERC20Mintable(address(token)).mint(address(this), shouldReleaseAmount.sub(balance));
            balance = token.balanceOf(address(this));
        }
        require(balance >= shouldReleaseAmount, "contract balance not enough");
        uint organizationRelease = shouldReleaseAmount.mul(ORGANIZATION_PERCENT).div(PERCENT_BASE);
        uint developerRelease = shouldReleaseAmount.sub(organizationRelease);
        if (organizationRelease > 0) {
            SafeERC20.safeTransfer(token, organization, organizationRelease);
        }
        if (developerRelease > 0) {
            SafeERC20.safeTransfer(token, developer, developerRelease);
        }
    }

}