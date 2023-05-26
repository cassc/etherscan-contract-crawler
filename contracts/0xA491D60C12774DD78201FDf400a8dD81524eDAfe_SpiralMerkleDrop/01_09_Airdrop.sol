// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { BitMaps } from "../libraries/BitMaps.sol";

contract SpiralMerkleDrop is Ownable {
    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;

    bytes32 public merkleRoot;

    IERC20 public immutable dropToken;

    uint256 public startTime;
    uint256 public immutable expiryTime;
    uint256 public immutable boostTime;

    enum CLAIM_TYPE {
        AuraFinance, ConvexFinance,
        Debank,      DegenScore,
        LobsterDAO,  veBAL,
        veCRV,       veFXS,
        veSDT,       vlAURA,
        vlCVX
    }

    struct Duration {
        uint64 start;
        uint64 end;
    }

    uint256 private constant CLAIM_AMOUNT = 100e18;
    mapping(CLAIM_TYPE => Duration) public claimWindow;
    mapping(CLAIM_TYPE => uint256) private _availableClaims;
    mapping(CLAIM_TYPE => BitMaps.BitMap) private _hasClaimed;
    mapping(address => uint256) public toRedeem;

    event RootSet(bytes32 newRoot);
    event StartedEarly();
    event ExpiredWithdrawn(uint256 amount);
    event Claimed(address addr, uint256 amt);
    event Redeemed(address addr, uint256 amt);
    event Rescued();
    event Initialized();

    /**
     * @param _merkleRoot       Merkle root
     * @param _dropToken        Drop token
     * @param _startTime        Exact time when contract is live
     * @param _expiresAfter     Timestamp when contract expires
     * @param _boostTime        Duration of linear increase of redeem multiplier
     */
    constructor(
        bytes32 _merkleRoot,
        address _dropToken,
        uint256 _startTime,
        uint256 _expiresAfter,
        uint256 _boostTime
    ) {
        merkleRoot = _merkleRoot;
        require(_dropToken != address(0), "!dropToken");
        dropToken = IERC20(_dropToken);

        startTime = _startTime;

        require(_expiresAfter * 1 days >= 1 weeks, "!expiry");
        expiryTime = _startTime + _expiresAfter * 1 days;

        require(_boostTime > 0, "!divzero");
        boostTime = _startTime + _boostTime * 1 days;

        emit Initialized();
    }

    /***************************************
                    CONFIG
    ****************************************/

    function startNow() external {
        require(msg.sender == owner(), "!auth");
        startTime = block.timestamp;
        emit StartedEarly();
    }

    function setRoot(bytes32 _merkleRoot) external {
        require(msg.sender == owner(), "!auth");
        merkleRoot = _merkleRoot;
        emit RootSet(_merkleRoot);
    }

    function withdrawExpired() external {
        require(msg.sender == owner(), "!auth");
        require(block.timestamp > expiryTime, "!expired");
        uint256 amt = dropToken.balanceOf(address(this));
        dropToken.safeTransfer(owner(), amt);
        emit ExpiredWithdrawn(amt);
    }

    function setClaimTypeSizeAndDuration(
        CLAIM_TYPE claim_type,
        uint256 size,
        Duration calldata duration_
    ) external {
        require(msg.sender == owner(), "!auth");
        require(claim_type <= CLAIM_TYPE.vlCVX, "!type");
        require(duration_.start < duration_.end, "!duration");
        _availableClaims[claim_type] = size;
        claimWindow[claim_type] = duration_;
    }

    /***************************************
                    VIEWS
    ****************************************/

    function hasClaimed(address user_) external view returns(bool[] memory) {
        bool[] memory data = new bool[](uint8(CLAIM_TYPE.vlCVX) + 1);
        for (uint8 i; i <= uint8(CLAIM_TYPE.vlCVX);i++) {
            data[i] = _hasClaimed[CLAIM_TYPE(i)].get(uint256(uint160(user_)));
        }

        return data;
    }

    function claimWindows() external view returns(Duration[] memory) {
        Duration[] memory data = new Duration[](uint8(CLAIM_TYPE.vlCVX) + 1);
        for (uint8 i; i <= uint8(CLAIM_TYPE.vlCVX);i++) {
            data[i] = claimWindow[CLAIM_TYPE(i)];
        }

        return data;
    }

    function availableClaims() external view returns(uint256[] memory) {
        uint256[] memory data = new uint256[](uint8(CLAIM_TYPE.vlCVX) + 1);
        for (uint8 i; i <= uint8(CLAIM_TYPE.vlCVX);i++) {
            data[i] = _availableClaims[CLAIM_TYPE(i)];
        }
        return data;
    }

    /**
     * @notice actually it's a redeem amount, but back compatibility
     */
    function claimableAmount(address address_) external view returns(uint256){
        return _claimableAmount(address_);
    }

    function maxClaimableAmount(address address_) external view returns(uint256){
        uint256 amount_ = toRedeem[address_];
        uint256 multiplier = 15 * 1e6 / 10;
        return amount_ * multiplier / 1e6;
    }

    function _claimableAmount(address address_) internal view returns(uint256){
        uint256 amount_ = toRedeem[address_];
        uint256 multiplier;
        if (block.timestamp > boostTime) {
            multiplier = 15 * 1e6 / 10;
        }
        else {
            multiplier = 1e6 + (block.timestamp - startTime) * 1e6 / (boostTime - startTime) / 2;
        }
        return amount_ * multiplier / 1e6;
    }

    /***************************************
                    CLAIM
    ****************************************/

    /**
     * @notice `flags` is a bit-packed value, each bit represents flag for claim type
     * e.g. 2047 == 0b11111111111 will result eligibility to all entries
     * and 1024 == 0b10000000000 will result only last entry eligibility
     */
    function claim(
        bytes32[] calldata _proof,
        address addr,
        uint16 flags
    ) external returns (bool) {
        require(merkleRoot != bytes32(0), "!root");
        require(block.timestamp > startTime, "!started");
        require(block.timestamp < expiryTime, "!active");
        bytes32 leaf = keccak256(abi.encodePacked(addr, flags));
        require(MerkleProof.verify(_proof, merkleRoot, leaf), "invalid proof");

        bool isEligible;
        uint256 claimAmount;
        uint8 claimsLength = uint8(CLAIM_TYPE.vlCVX);
        for(uint8 i; i <= claimsLength;) {
            CLAIM_TYPE type_ = CLAIM_TYPE(i);

            assembly {
                isEligible := and(shr(i, flags), 0x1)
                i := add(i, 1)
            } // Divided checks to separate `if`s to avoid unnecessary storage read in case of `false` flag
            if ( !isEligible || _hasClaimed[type_].get(uint256(uint160(addr))) ) {
                continue;
            }

            Duration memory claimWindow_ = claimWindow[type_];
            if( block.timestamp < claimWindow_.start || block.timestamp > claimWindow_.end ){
                continue;
            }

            uint256 remainedClaims = _availableClaims[type_];
            if (remainedClaims == 0) {
                continue;
            }

            unchecked {
                _hasClaimed[type_].set(uint256(uint160(addr)));
                _availableClaims[type_] = remainedClaims - 1;
                claimAmount += CLAIM_AMOUNT;
            }
        }

        toRedeem[addr] += claimAmount;
        emit Claimed(addr, claimAmount);
        return true;
    }

    function redeem() external {
        uint256 amount_ = _claimableAmount(msg.sender);
        if(amount_ > 0){
            toRedeem[msg.sender] = 0;
            dropToken.safeTransfer(msg.sender, amount_);
            emit Redeemed(msg.sender, amount_);
        }
    }
}