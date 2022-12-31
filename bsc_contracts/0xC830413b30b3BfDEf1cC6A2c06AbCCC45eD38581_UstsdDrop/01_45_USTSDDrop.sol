// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;
import "./CzUstsdReserves.sol";
import "./LSDT.sol";
import "./CZUsd.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract UstsdDrop is AccessControlEnumerable {
    using SafeERC20 for IERC20;

    bytes32 public constant DROPSENDER_ROLE = keccak256("DROPSENDER_ROLE");

    CzUstsdReserves public reserves =
        CzUstsdReserves(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    LSDT public lsdt = LSDT(0xD9A255F79d7970A3Ed4d81eef82b054B0a21eCF8);
    CZUsd public czusd = CZUsd(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    JsonNftTemplate public ustsdNft =
        JsonNftTemplate(0xA2eCD85433C8F8Ffd6Cc3573A913AC0F0092b9f2);
    uint256 public ustsdRewardPeriod = 30 hours;
    uint256 public lastUstsdRewardEpoch;
    uint256 public totalUstsdRewarded;

    mapping(address => bool) public wasDropped;
    mapping(address => bool) public isIneligible;

    uint256 public czusdSpentByThis;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(DROPSENDER_ROLE, msg.sender);
        lastUstsdRewardEpoch = lsdt.lastUstsdRewardEpoch();
        totalUstsdRewarded = lsdt.totalUstsdRewarded();
    }

    function DROPSENDER_sendDrop(uint256 _id, address _winner)
        external
        onlyRole(DROPSENDER_ROLE)
    {
        wasDropped[_winner] = true;
        uint256 czusdBalInitial = czusd.balanceOf(address(this));
        uint256[] memory toBuy = new uint256[](1);
        toBuy[0] = _id;
        reserves.buy(toBuy, CzUstsdReserves.CURRENCY.CZUSD);
        ustsdNft.transferFrom(address(this), _winner, toBuy[0]);
        czusdSpentByThis += (czusdBalInitial - czusd.balanceOf(address(this)));
        totalUstsdRewarded++;
        lastUstsdRewardEpoch = block.timestamp;
    }

    function getWinnerAndId(uint256 _randWord)
        public
        view
        returns (uint256 id_, address winner_)
    {
        winner_ = address(0x0);
        while (winner_ == address(0x0)) {
            address potentialWinner = lsdt.getWinner(_randWord);
            if (addressIsEligible(potentialWinner)) {
                winner_ = potentialWinner;
            }
        }
        id_ = ustsdNft.tokenOfOwnerByIndex(
            address(reserves),
            _randWord % ustsdNft.balanceOf(address(reserves))
        );
    }

    function addressIsEligible(address _for) public view returns (bool) {
        return (!wasDropped[_for] &&
            !isIneligible[_for] &&
            !lsdt.addressHasWon(_for));
    }

    function ustsdToReward() public view returns (uint256 rabbitMintCount_) {
        return ((lsdt.lockedCzusd() -
            lsdt.baseCzusdLocked() -
            lsdt.totalCzusdSpent() -
            czusdSpentByThis) / lsdt.czusdLockPerReward());
    }

    function isDropReady() public view returns (bool) {
        return
            ustsdToReward() > 0 &&
            (block.timestamp > (ustsdRewardPeriod + lastUstsdRewardEpoch));
    }

    function ADMIN_setIsIneligible(address _for, bool _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        isIneligible[_for] = _to;
    }

    function ADMIN_setRewardPeriod(uint256 _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ustsdRewardPeriod = _to;
    }

    function ADMIN_setReserves(CzUstsdReserves _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        reserves = _to;
    }

    function ADMIN_recoverWrongTokens(address _tokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(_tokenAddress).safeTransfer(
            address(msg.sender),
            IERC20(_tokenAddress).balanceOf(address(this))
        );
    }

    function ADMIN_executeAsThis(
        address _for,
        bytes memory _abiSignatureEncoded
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address(_for).call(_abiSignatureEncoded);
    }
}