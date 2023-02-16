// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**************************************

    security-contact:
    - [email protected]

    maintainers:
    - [email protected]
    - [email protected]
    - [email protected]
    - [email protected]

    contributors:
    - [email protected]

**************************************/

// OpenZeppelin
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Local
import { LibTWAP } from "../libraries/LibTWAP.sol";
import { Configurable } from "../utils/Configurable.sol";
import { IVestedAlloc } from "../interfaces/IVestedAlloc.sol";
import { ICommunityRound } from "../interfaces/ICommunityRound.sol";
import { MultiBatch } from "../utils/MultiBatch.sol";

/**************************************
    
    Vested Allocation contract

    ------------------------------

    Reserves and their behaviour:
    - private part of presale - populated with addRecipients + claimable
    - community part of presale - fetchable from communityRound contract + claimable
    - nft holders eligible for airdrop - fetchable from airdrop contract + claimable
    - staking - forwardable by admin to staking pool
    - dex - forwardable by admin to lp creator
    - treasury - forwardable by admin to treasury pool
    - team - populated with addRecipients + claimable
    - advisors - populated with addRecipients + claimable
    - partners - populated with addRecipients + claimable

    ------------------------------

    Batch calls:
    - This contract is able to perform multicall and multiread functions

**************************************/

contract VestedAlloc is IVestedAlloc, Configurable, Ownable, MultiBatch {

    // constants
    uint8 constant internal ALL_RESERVES = 9; // 9 is hardcoded in interface and bytes decoding
    uint256 constant internal THOL_DECIMALS = 10**18;
    address immutable public SAFEGUARD_TREASURY;
    uint256 immutable public PRICE_UNLOCK_VALIDITY;

    // token
    IERC20 public thol;
    ICommunityRound public community;
    address public airdrop;

    // paths
    address[2] public poolPath;
    address[3] public tokenPath;

    // storage
    uint256 public totalSupply;
    uint256 public usdtToTholConversion;
    mapping (ReserveType => VestedReserve) public vestedReserves;

    /**************************************
    
        ** Constructor **

        ------------------------------

        @param _arguments Bytes containing constructor arguments:
        - total supply
        - fixed array of allocation request
        - safeguard treasury address
        - USDT:THOL ratio for CommunityRound contract

     **************************************/

    constructor(
        bytes memory _arguments
    )
    Ownable() {

        // tx.members
        uint256 now_ = block.timestamp;

        // decode arguments
        (
            uint256 _totalSupply,
            AllocationRequest[ALL_RESERVES] memory _payload,
            address _safeguardTreasury,
            uint256 _usdtToTholConversion
        ) = abi.decode(
            _arguments,
            (
                uint256,
                AllocationRequest[9],
                address,
                uint256
            )
        );

        // loop through allocation
        uint256 sum_ = 0;
        for (uint8 i = 0; i < ALL_RESERVES; i++) {

            // check integrity
            AllocationRequest memory request_ = _payload[i];
            if (vestedReserves[request_.reserveType].allocation.totalReserve != 0) {
                revert InvalidAllocation(_payload);
            }

            // sum allocation
            sum_ += request_.allocation.totalReserve;

            // set storage in loop
            vestedReserves[request_.reserveType].allocation.totalReserve = request_.allocation.totalReserve;
            for (uint8 j = 0; j < request_.allocation.releases.length; j++) {
                Release memory release_ = request_.allocation.releases[j];
                if (release_.releaseType == ReleaseType.PRICE && j != 0) {
                    revert InvalidReleaseType(release_, j); // @dev Ensure releases are ordered { PRICE, TS1, TS2, ... }
                }
                vestedReserves[request_.reserveType].allocation.releases.push(release_);
            }

        }

        // check sum versus supply
        if (sum_ != _totalSupply) {
            revert SumNotEqualSupply(sum_, _totalSupply);
        }

        // storage
        totalSupply = _totalSupply;
        SAFEGUARD_TREASURY = _safeguardTreasury;
        usdtToTholConversion = _usdtToTholConversion;
        PRICE_UNLOCK_VALIDITY = now_ + 730 days;

        // event
        emit Initialised(_arguments);

    }

    /**************************************

        ** Add wallets **

         ------------------------------

        @notice Adds wallets for allocation type

        ------------------------------

        @dev Only admin should be able to call it
        @dev Should be called before ending configuration of contract
        @dev Single recipient could be used for forwardable type of allocation
        @dev Many recipient would imply claimable type of allocation
        @param _reserveType Enum defining type of reserve
        @param _recipients List of structs with address and share

     **************************************/

    function addRecipients(
        ReserveType _reserveType,
        Recipient[] calldata _recipients
    ) external
    onlyOwner()
    onlyInState(State.UNCONFIGURED) {

        // loop through wallets
        uint256 sum_ = 0;
        for (uint8 i = 0; i < _recipients.length; i++) {

            // share
            uint256 share_ = _recipients[i].share;

            // sum share
            sum_ += share_;

            // save storage per recipient
            vestedReserves[_reserveType].shareholders[_recipients[i].owner].shares = share_;

        }

        // check recipient sum
        if (vestedReserves[_reserveType].allocation.totalReserve != sum_) {
            revert InvalidRecipientSum(_reserveType, sum_);
        }

        // event
        emit RecipientsAdded(_reserveType, _recipients);

    }

    /**************************************
    
        ** Configure **

        ------------------------------

        @notice Ends configuration of contract

        ------------------------------

        @dev Only admin should be able to call it
        @param _arguments Bytes encoding vested erc20 address

     **************************************/

    function configure(
        bytes calldata _arguments
    ) external virtual override
    onlyOwner()
    onlyInState(State.UNCONFIGURED) {

        // decode arguments
        (
            address erc20_,
            address community_,
            address airdrop_
        ) = abi.decode(
            _arguments,
            (
                address,
                address,
                address
            )
        );

        // token
        IERC20 thol_ = IERC20(erc20_);

        // check balance
        uint256 balance = thol_.balanceOf(address(this));
        if (balance != totalSupply) {
            revert InvalidTokens(balance, totalSupply);
        }

        // storage
        thol = thol_;
        community = ICommunityRound(community_);
        airdrop = airdrop_;

        // init airdrop shares
        vestedReserves[ReserveType.AIRDROP].shareholders[airdrop_].shares = vestedReserves[ReserveType.AIRDROP].allocation.totalReserve;

        // state
        state = State.CONFIGURED;

        // events
        emit Configured(_arguments);

    }

    /**************************************

        ** Set dex paths **

        ------------------------------

        @notice Configures addresses of pools and tokens used in swap

        ------------------------------

        @dev Only admin should be able to call it
        @param _poolPath Address of Uniswap V3 pools: $THOL/wETH and wETH/USDT
        @param _tokenPath Address of tokens ($THOL, wETH and USDT)

     **************************************/

    function setDexPaths(
        address[2] calldata _poolPath,
        address[3] calldata _tokenPath
    ) public
    onlyOwner()
    onlyInState(State.CONFIGURED) {

        // storage
        poolPath = _poolPath;
        tokenPath = _tokenPath;

        // event
        emit DexPoolSet(msg.sender, poolPath, tokenPath);

    }

    /**************************************
    
        ** Forward **

        ------------------------------

        @notice Forwards particular type of allocation to end destination

        ------------------------------

        @dev Only admin should forward funds
        @dev Applicable for staking, dex, treasury and unallocated funds (like partners)
        @param _reserveType Enum which identifies allocation type
        @param _shareholder Address of recipient / destination

     **************************************/

    function forward(
        ReserveType _reserveType,
        address _shareholder
    ) external
    onlyOwner()
    onlyInState(State.CONFIGURED) {

        // get share
        uint256 share_ = vestedReserves[_reserveType].shareholders[_shareholder].shares;

        // check if only share
        if (share_ != vestedReserves[_reserveType].allocation.totalReserve) {
            revert CannotForwardClaimableFunds(_reserveType, _shareholder);
        }

        // get available tokens
        uint256 available_ = getAvailable(_reserveType, _shareholder);
        if (available_ == 0) {
            revert NothingToForward(_reserveType, _shareholder);
        }

        // transfer out
        _transferOut(
            _reserveType,
            _shareholder,
            _shareholder,
            available_
        );

        // event
        emit Forwarded(_reserveType, msg.sender, _shareholder, available_);

    }

    /**************************************

        ** Set shareholder as compromised **

        ------------------------------

        @notice Only applies for team members

        ------------------------------

        @param _shareholder Address of team member

     **************************************/

    function setShareholderAsCompromised(address _shareholder)
    external
    onlyOwner()
    onlyInState(State.CONFIGURED) {
    
        // check if shareholder is a team member
        ReserveType reserveType_ = ReserveType.TEAM;
        if (vestedReserves[reserveType_].shareholders[_shareholder].shares == 0) {
            revert WrongShareholder(_shareholder);
        }

        // set shareholder as compromised
        vestedReserves[reserveType_].shareholders[_shareholder].isCompromised = true;

        // event
        emit ShareholderCompromised(_shareholder);
        
    }

    /**************************************

        ** Claim **

        ------------------------------

        @notice Claims available tokens by shareholder

        ------------------------------

        @dev Applicable for presale, airdrop, team, advisors and partners
        @dev If some funds will be unallocated (like partners) they can be forwarded
        @param _reserveType Enum which identifies allocation type

     **************************************/

    function claim(ReserveType _reserveType) external
    onlyInState(State.CONFIGURED) {

        // tx.members
        address sender_ = msg.sender;

        // check if shareholder is allowed to claim
        if (
            _reserveType == ReserveType.TEAM &&
            vestedReserves[_reserveType].shareholders[sender_].isCompromised
        ) {
            revert NotAllowedToClaim(sender_);
        }

        // get available tokens
        uint256 available_ = getAvailable(_reserveType, sender_);
        if (available_ == 0) {
            revert NothingToClaim(_reserveType, sender_);
        }

        // transfer out
        _transferOut(
            _reserveType,
            sender_,
            sender_,
            available_
        );

        // event
        emit Claimed(_reserveType, sender_, available_);

    }

    /**************************************

        ** Safeguard **

        ------------------------------

        @notice Transfers unclaimed team tokens to treasury

        ------------------------------

        @dev Only admin should be able to safeguard
        @dev Safeguard should be used as emergency function (last resort)
        @dev To call safeguard threshold time needs to pass after share being available
        @param _shareholder Address of owner of shares

     **************************************/

    function safeguard(
        address _shareholder
    ) external
    onlyOwner()
    onlyInState(State.CONFIGURED) {

        // set reserve type
        ReserveType reserveType_ = ReserveType.TEAM;

        // get available tokens
        uint256 available_ = getAvailable(reserveType_, _shareholder);
        if (available_ == 0) {
            revert NothingToSafeguard(_shareholder);
        }

        if (!vestedReserves[reserveType_].shareholders[_shareholder].isCompromised) {
            revert ShareholderIsNotCompromised(_shareholder);
        }

        // transfer out
        _transferOut(
            reserveType_,
            _shareholder,
            SAFEGUARD_TREASURY,
            available_
        );

        // event
        emit Safeguarded(msg.sender, _shareholder, available_);

    }

    /**************************************

        ** Internal: get Tholos from Community contract **

        ------------------------------

        @param _shareholder Address of owner of shares

     **************************************/

    function _getTholosFromCommunity(address _shareholder) internal view
    returns (uint256) {

        // return
        return community.balanceOf(_shareholder) * usdtToTholConversion;

    }

    /**************************************

        ** Transfer (internal, low level) **

        ------------------------------

        @notice Transfer method that takes care of vested reserves

        ------------------------------

        @param _reserveType Enum which identifies allocation type
        @param _shareholder Address of owner of shares
        @param _target Address of recipient
        @param _amount Amount computed out of shares

     **************************************/

    function _transferOut(
        ReserveType _reserveType,
        address _shareholder,
        address _target,
        uint256 _amount
    ) internal {

        // storage
        vestedReserves[_reserveType].shareholders[_shareholder].claimed += _amount;

        // transfer
        bool success = thol.transfer(_target, _amount);
        if (!success) revert CannotTransferThol();

    }

    /**************************************

        ** Get available**

        ------------------------------

        @notice Returns available tokens to claim or forward

        ------------------------------

        @param _reserveType Enum which identifies allocation type
        @param _shareholder Address of owner of shares
        @return available_ Amount of tokens shareholder could claim or forward

     **************************************/

    function getAvailable(ReserveType _reserveType, address _shareholder) public view
    onlyInState(State.CONFIGURED)
    returns (uint256) {

        // get current timestamp
        uint256 timestamp_ = block.timestamp;

        // get reserve
        VestedReserve storage reserve_ = vestedReserves[_reserveType];

        // get share
        uint256 share_;
        if (_reserveType != ReserveType.PRESALE_COMMUNITY) {
            share_ = reserve_.shareholders[_shareholder].shares;
        } else {
            share_ = _getTholosFromCommunity(_shareholder);
        }

        // exit if share is 0
        if (share_ == 0) {
            return 0;
        }

        // get releases
        Release[] memory releases_ = reserve_.allocation.releases;

        // loop through releases and calculate sum of available
        uint256 sum_ = 0;
        for (uint8 i = 0; i < releases_.length; i++) {

            // continue if release based on cost
            if (releases_[i].releaseType == ReleaseType.PRICE) {
                // skip if price not reached or unlock validity not expired
                if (!reserve_.unlocked[i] && timestamp_ < PRICE_UNLOCK_VALIDITY) continue;
            }
            // break if release based on timestamp
            else if (timestamp_ < releases_[i].requirement) {
                break;
            }

            // increase sum with available release
            sum_ += releases_[i].amount;

        }
        
        // calculate share of sum
        uint256 unlocked_ = (sum_ * share_) / reserve_.allocation.totalReserve;

        // check unlocked & claimed
        if (unlocked_ < reserve_.shareholders[_shareholder].claimed) {
            revert UnlockedLessThanClaimed(unlocked_, reserve_.shareholders[_shareholder].claimed, sum_);
        }

        // return diff between share and claimed
        return unlocked_ - reserve_.shareholders[_shareholder].claimed;

    }

    /**************************************

        ** Unlock reserve (for maintainers) **

        ------------------------------

        @notice Unlocks price-based reserve
        @dev Called by anyone or our automation regularly

        ------------------------------

        @param _reserveType Enum which identifies allocation type
        @param _releaseNo Number of release from reserve

     **************************************/

    function unlockReserve(ReserveType _reserveType, uint8 _releaseNo) external override
    onlyInState(State.CONFIGURED) {

        // get releases
        Allocation memory alloc_ = vestedReserves[_reserveType].allocation;
        Release memory release_ = alloc_.releases[_releaseNo];

        // validation
        if (release_.releaseType != ReleaseType.PRICE) {
            revert InvalidReleaseType(release_, _releaseNo);
        }
        if (
            poolPath[0] == address(0) ||
            poolPath[1] == address(0) ||
            tokenPath[0] == address(0) ||
            tokenPath[1] == address(0) ||
            tokenPath[2] == address(0)
        ) {
            revert DexPathsNotSet();
        }

        // check price
        uint256 usdtOut_ = tholToUsdt();
        if (usdtOut_ < release_.requirement) {
            revert PriceNotMet(usdtOut_, release_.requirement);
        }

        // unlock
        vestedReserves[_reserveType].unlocked[_releaseNo] = true;

    }

    /**************************************

        ** THOL to USDT **

        ------------------------------

        @dev Utility view

        ------------------------------

        @return THOL to USDT price

     **************************************/

    function tholToUsdt() public view override
    returns (uint256) {
        if (
            poolPath[0] == address(0) ||
            poolPath[1] == address(0) ||
            tokenPath[0] == address(0) ||
            tokenPath[1] == address(0) ||
            tokenPath[2] == address(0)
        ) return 0;

        return LibTWAP.tholToUsdt(
            poolPath,
            tokenPath,
            THOL_DECIMALS
        );
    }

}