// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./Interfaces/IVlEqb.sol";
import "./Interfaces/IXEqbToken.sol";

contract XEqbToken is
    IXEqbToken,
    ERC20Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    struct RedeemInfo {
        uint256 eqbAmount; // EQB amount to receive when vesting has ended
        uint256 xEqbAmount; // xEQB amount to redeem
        uint256 endTime;
    }

    IERC20 public eqb; // eqb to convert to/from
    address public vlEqb;
    address public burnAddress; // burn address to send excess eqb to

    EnumerableSet.AddressSet private _transferWhitelist; // addresses allowed to send/receive xEQB

    uint256 public constant MAX_FIXED_RATIO = 100; // 100%

    // Redeeming min/max settings
    uint256 public minRedeemRatio;
    uint256 public maxRedeemRatio;
    uint256 public minRedeemDuration;
    uint256 public maxRedeemDuration;

    mapping(address => uint256) public redeemingAmounts; // User's redeeming amounts
    mapping(address => RedeemInfo[]) public userRedeems; // User's redeeming instances

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();

        __ERC20_init_unchained("max EQB", "xEQB");
    }

    /***********************************************/
    /****************** MODIFIERS ******************/
    /***********************************************/

    /*
     * @dev Check if a redeem entry exists
     */
    modifier validateRedeem(address userAddress, uint256 redeemIndex) {
        require(
            redeemIndex < userRedeems[userAddress].length,
            "validateRedeem: redeem entry does not exist"
        );
        _;
    }

    /**************************************************/
    /****************** PUBLIC VIEWS ******************/
    /**************************************************/
    /*
     * @dev returns redeemable EQB for "amount" of xEQB vested for "duration" seconds
     */
    function getEqbByVestingDuration(
        uint256 amount,
        uint256 duration
    ) public view returns (uint256) {
        if (duration < minRedeemDuration) {
            return 0;
        }

        // capped to maxRedeemDuration
        if (duration > maxRedeemDuration) {
            return (amount * maxRedeemRatio) / MAX_FIXED_RATIO;
        }

        uint256 ratio = minRedeemRatio +
            (((duration - minRedeemDuration) *
                (maxRedeemRatio - minRedeemRatio)) /
                (maxRedeemDuration - minRedeemDuration));

        return (amount * ratio) / MAX_FIXED_RATIO;
    }

    /**
     * @dev returns quantity of "userAddress" pending redeems
     */
    function getUserRedeemsLength(
        address userAddress
    ) external view returns (uint256) {
        return userRedeems[userAddress].length;
    }

    /**
     * @dev returns "userAddress" info for a pending redeem identified by "redeemIndex"
     */
    function getUserRedeem(
        address userAddress,
        uint256 redeemIndex
    )
        external
        view
        validateRedeem(userAddress, redeemIndex)
        returns (uint256 eqbAmount, uint256 xEqbAmount, uint256 endTime)
    {
        RedeemInfo memory _redeem = userRedeems[userAddress][redeemIndex];
        return (_redeem.eqbAmount, _redeem.xEqbAmount, _redeem.endTime);
    }

    /**
     * @dev returns length of transferWhitelist array
     */
    function transferWhitelistLength() external view returns (uint256) {
        return _transferWhitelist.length();
    }

    /**
     * @dev returns transferWhitelist array item's address for "index"
     */
    function transferWhitelist(uint256 index) external view returns (address) {
        return _transferWhitelist.at(index);
    }

    /**
     * @dev returns if "account" is allowed to send/receive xEQB
     */
    function isTransferWhitelisted(
        address account
    ) external view returns (bool) {
        return _transferWhitelist.contains(account);
    }

    /*******************************************************/
    /****************** OWNABLE FUNCTIONS ******************/
    /*******************************************************/

    function setParams(
        address _eqb,
        address _vlEqb,
        address _burnAddress
    ) external onlyOwner {
        require(address(eqb) == address(0), "setParams: already set");
        require(_eqb != address(0), "setParams: eqb cannot be null");
        require(_vlEqb != address(0), "setParams: vlEqb cannot be null");
        require(
            _burnAddress != address(0),
            "setParams: burnAddress cannot be null"
        );

        eqb = IERC20(_eqb);
        vlEqb = _vlEqb;
        burnAddress = _burnAddress;

        minRedeemRatio = 50; // 1:0.5
        maxRedeemRatio = 100; // 1:1
        minRedeemDuration = 14 days;
        maxRedeemDuration = 168 days;

        _transferWhitelist.add(address(this));
    }

    /**
     * @dev Updates all redeem ratios and durations
     *
     * Must only be called by owner
     */
    function updateRedeemSettings(
        uint256 minRedeemRatio_,
        uint256 maxRedeemRatio_,
        uint256 minRedeemDuration_,
        uint256 maxRedeemDuration_
    ) external onlyOwner {
        require(
            minRedeemRatio_ <= maxRedeemRatio_,
            "updateRedeemSettings: wrong ratio values"
        );
        require(
            minRedeemDuration_ < maxRedeemDuration_,
            "updateRedeemSettings: wrong duration values"
        );
        // should never exceed 100%
        require(
            maxRedeemRatio_ <= MAX_FIXED_RATIO,
            "updateRedeemSettings: wrong ratio values"
        );

        minRedeemRatio = minRedeemRatio_;
        maxRedeemRatio = maxRedeemRatio_;
        minRedeemDuration = minRedeemDuration_;
        maxRedeemDuration = maxRedeemDuration_;

        emit UpdateRedeemSettings(
            minRedeemRatio_,
            maxRedeemRatio_,
            minRedeemDuration_,
            maxRedeemDuration_
        );
    }

    /**
     * @dev Adds or removes addresses from the transferWhitelist
     */
    function updateTransferWhitelist(
        address account,
        bool add
    ) external onlyOwner {
        require(
            account != address(this),
            "updateTransferWhitelist: Cannot remove xEqb from whitelist"
        );

        if (add) {
            _transferWhitelist.add(account);
        } else {
            _transferWhitelist.remove(account);
        }

        emit SetTransferWhitelist(account, add);
    }

    /*****************************************************************/
    /******************  EXTERNAL PUBLIC FUNCTIONS  ******************/
    /*****************************************************************/

    /**
     * @dev Convert caller's "amount" of EQB to xEQB
     */
    function convert(uint256 amount) external override nonReentrant {
        _convert(amount, msg.sender);
    }

    /**
     * @dev Convert caller's "amount" of EQB to xEQB to "to" address
     */
    function convertTo(
        uint256 amount,
        address to
    ) external override nonReentrant {
        require(address(msg.sender).isContract(), "convertTo: not allowed");
        _convert(amount, to);
    }

    /**
     * @dev Initiates redeem process (xEQB to EQB)
     */
    function redeem(
        uint256 xEqbAmount,
        uint256 duration
    ) external nonReentrant {
        require(xEqbAmount > 0, "redeem: xEqbAmount cannot be null");
        require(duration >= minRedeemDuration, "redeem: duration too low");

        _transfer(msg.sender, address(this), xEqbAmount);

        // get corresponding EQB amount
        uint256 eqbAmount = getEqbByVestingDuration(xEqbAmount, duration);
        emit Redeem(msg.sender, xEqbAmount, eqbAmount, duration);

        // if redeeming is not immediate, go through vesting process
        if (duration > 0) {
            redeemingAmounts[msg.sender] += xEqbAmount;

            // add redeeming entry
            userRedeems[msg.sender].push(
                RedeemInfo(
                    eqbAmount,
                    xEqbAmount,
                    _currentBlockTimestamp() + duration
                )
            );
        } else {
            // immediately redeem for EQB
            _finalizeRedeem(msg.sender, msg.sender, xEqbAmount, eqbAmount);
        }
    }

    /**
     * @dev Finalizes redeem process when vesting duration has been reached
     *
     * Can only be called by the redeem entry owner
     */
    function finalizeRedeem(
        uint256 redeemIndex
    ) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
        RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];
        require(
            _currentBlockTimestamp() >= _redeem.endTime,
            "finalizeRedeem: vesting duration has not ended yet"
        );

        redeemingAmounts[msg.sender] -= _redeem.xEqbAmount;
        _finalizeRedeem(
            msg.sender,
            msg.sender,
            _redeem.xEqbAmount,
            _redeem.eqbAmount
        );

        // remove redeem entry
        _deleteRedeemEntry(redeemIndex);
    }

    /**
     * @dev Cancels an ongoing redeem entry
     *
     * Can only be called by its owner
     */
    function cancelRedeem(
        uint256 redeemIndex
    ) external nonReentrant validateRedeem(msg.sender, redeemIndex) {
        RedeemInfo storage _redeem = userRedeems[msg.sender][redeemIndex];

        // make redeeming xEQB available again
        redeemingAmounts[msg.sender] -= _redeem.xEqbAmount;
        _transfer(address(this), msg.sender, _redeem.xEqbAmount);

        emit CancelRedeem(msg.sender, _redeem.xEqbAmount);

        // remove redeem entry
        _deleteRedeemEntry(redeemIndex);
    }

    /**
     * @dev Lock to VlEqb (xEQB to EQB to VlEqb)
     */
    function lock(uint256 _xEqbAmount, uint256 _weeks) external nonReentrant {
        require(_xEqbAmount > 0, "lock: xEqbAmount cannot be null");
        uint256 duration = _weeks * 1 weeks;
        require(duration >= minRedeemDuration, "lock: duration too low");

        _transfer(msg.sender, address(this), _xEqbAmount);

        // get corresponding EQB amount
        uint256 eqbAmount = getEqbByVestingDuration(_xEqbAmount, duration);
        _finalizeRedeem(msg.sender, address(this), _xEqbAmount, eqbAmount);

        _approveTokenIfNeeded(address(eqb), vlEqb, eqbAmount);
        IVlEqb(vlEqb).lock(msg.sender, eqbAmount, _weeks);

        emit Lock(msg.sender, _xEqbAmount, eqbAmount, _weeks);
    }

    /********************************************************/
    /****************** INTERNAL FUNCTIONS ******************/
    /********************************************************/

    /**
     * @dev Convert caller's "amount" of EQB into xEQB to "to"
     */
    function _convert(uint256 amount, address to) internal {
        require(amount != 0, "convert: amount cannot be null");

        // mint new xEQB
        _mint(to, amount);

        emit Convert(msg.sender, to, amount);
        eqb.safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Finalizes the redeeming process for "userAddress" by transferring him "eqbAmount" and removing "xEqbAmount" from supply
     *
     * Any vesting check should be ran before calling this
     * EQB excess is automatically sent to burn address
     */
    function _finalizeRedeem(
        address userAddress,
        address receiverAddress,
        uint256 xEqbAmount,
        uint256 eqbAmount
    ) internal {
        // sends due eqb
        if (receiverAddress != address(this)) {
            eqb.safeTransfer(receiverAddress, eqbAmount);
        }

        // sends EQB excess to burn address if any
        if (xEqbAmount > eqbAmount) {
            eqb.safeTransfer(burnAddress, xEqbAmount - eqbAmount);
        }

        _burn(address(this), xEqbAmount);

        emit FinalizeRedeem(
            userAddress,
            receiverAddress,
            xEqbAmount,
            eqbAmount
        );
    }

    function _deleteRedeemEntry(uint256 index) internal {
        userRedeems[msg.sender][index] = userRedeems[msg.sender][
            userRedeems[msg.sender].length - 1
        ];
        userRedeems[msg.sender].pop();
    }

    /**
     * @dev Hook override to forbid transfers except from whitelisted addresses and minting
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal view override {
        require(
            from == address(0) ||
                _transferWhitelist.contains(from) ||
                _transferWhitelist.contains(to),
            "transfer: not allowed"
        );
    }

    /**
     * @dev Utility function to get the current block timestamp
     */
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _approveTokenIfNeeded(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _to) < _amount) {
            IERC20(_token).safeApprove(_to, 0);
            IERC20(_token).safeApprove(_to, type(uint256).max);
        }
    }
}