// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './Vault.sol';
import '../utils/Withdrawable.sol';

/**
 * @dev please make sure there is enough tokens transferred to the VestingController before the sale start
 */
contract VestingController is Ownable, Withdrawable, ReentrancyGuard {
    IERC20 public immutable token;
    bytes32 public merkleTreeRoot;
    uint256 public presaleStartTimestamp;
    uint256 public presaleDurationSeconds;
    // TODO this should be called tokensWeiWorthOneEthEther
    uint256 public immutable tokensWeiWorthOneEther;
    uint256 public immutable maxTokenAllocationWei;
    uint64 public immutable tgeDelaySeconds;
    uint32 public immutable tgeNumerator;
    uint32 public immutable tgeDenominator;
    uint32 public immutable vestingPeriodCount;
    uint32 public immutable vestingPeriodDurationSeconds;
    address payable public capitalCollector;
    mapping(address => Vault) public vaults;

    modifier protectedWithdrawal() override {
        _checkOwner();
        _;
    }

    /**
     * @param token_ an address of vested token
     * @param merkleTreeRoot_ merkle tree root where leaf == abi.encode(_msgSender(), totalAllocationWei).
     * Pass 0 if the vesting is permissionless.
     * @param presaleStartTimestamp_ unix time in seconds specifying a start of the presale
     * @param presaleDurationSeconds_ presale duration in seconds. Pass 0 if you
     * don’t want the presale to be time limited.
     * @param tokensWeiWorthOneEther_ how many wei of the sold token equals in
     * value 1 ether of the native blockchain currency. Pass 0 if you do not
     * want to collect capital or if deploying a vesting where funds where
     * collected in another way.
     * @param maxTokenAllocationWei_ max token allocation per address
     * Irrelevant if the presale is permissioned (merkleTreeRoot_ is not 0)
     * @param tgeDelaySeconds_ if the first tokens should be available
     * immidiatelly, pass 0. If not, pass appropriate delay in seconds.
     * @param tgeNumerator_ fraction of the allocation that should be released immidiatelly
     * @param tgeDenominator_ denominator of tgeNumerator_
     * @param vestingPeriodCount_ how many periods should the vesting be divided into
     * @param vestingPeriodDurationSeconds_ how many seconds one vesting period should last
     * @param capitalCollector_ an address where native blockchain currency is sent
     */
    constructor(
        address payable token_,
        bytes32 merkleTreeRoot_,
        uint256 presaleStartTimestamp_,
        uint256 presaleDurationSeconds_,
        uint256 tokensWeiWorthOneEther_,
        uint256 maxTokenAllocationWei_,
        uint64 tgeDelaySeconds_,
        uint32 tgeNumerator_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_,
        address payable capitalCollector_
    ) {
        require(tgeNumerator_ <= tgeDenominator_, 'tgeNumerator_ can not be greater than tgeDenominator_');
        require(vestingPeriodCount_ == 0 || vestingPeriodDurationSeconds_ > 0, 'Vesting periods of duration 0 seconds');
        require(capitalCollector_ != address(0), 'Capital collector can not be address zero');
        if (presaleDurationSeconds_ > 0) require(presaleStartTimestamp_ > 0, 'Can not specify duration without start');
        token = IERC20(token_);
        merkleTreeRoot = merkleTreeRoot_;
        presaleStartTimestamp = presaleStartTimestamp_;
        presaleDurationSeconds = presaleDurationSeconds_;
        tokensWeiWorthOneEther = tokensWeiWorthOneEther_;
        maxTokenAllocationWei = maxTokenAllocationWei_;
        tgeDelaySeconds = tgeDelaySeconds_;
        tgeNumerator = tgeNumerator_;
        tgeDenominator = tgeDenominator_;
        vestingPeriodCount = vestingPeriodCount_;
        vestingPeriodDurationSeconds = vestingPeriodDurationSeconds_;
        capitalCollector = capitalCollector_;
    }

    function _isPermissionless() private view returns (bool) {
        return merkleTreeRoot == 0;
    }

    function _freeTokens() private view returns (bool) {
        return tokensWeiWorthOneEther == 0;
    }

    function _hasPresaleEnded() private view returns (bool) {
        if (presaleStartTimestamp == 0 || presaleDurationSeconds == 0) return false;
        return block.timestamp >= presaleStartTimestamp + presaleDurationSeconds;
    }

    function _vault() private view returns (Vault) {
        return vaults[_msgSender()];
    }

    function claimTokens() external payable nonReentrant {
        if (!_isPermissionless() && address(_vault()) != address(0)) {
            _vault().release(address(token));
            if (msg.value > 0) {
                Address.sendValue(payable(_msgSender()), msg.value);
            }
        } else {
            require(_isPermissionless(), 'Please provide totalAllocationWei and a proof');
            _claimTokens(
                maxTokenAllocationWei,
                tgeDelaySeconds,
                tgeNumerator,
                tgeDenominator,
                vestingPeriodCount,
                vestingPeriodDurationSeconds
            );
        }
    }

    function claimTokens(bytes32[] calldata proof) external payable nonReentrant {
        require(!_isPermissionless(), 'This vesting does not require proofs');
        require(maxTokenAllocationWei > 0, 'This vesting requires a custom token allocation');
        require(
            MerkleProof.verify(proof, merkleTreeRoot, keccak256(abi.encode(_msgSender()))),
            'Address not whitelisted'
        );
        _claimTokens(
            maxTokenAllocationWei,
            tgeDelaySeconds,
            tgeNumerator,
            tgeDenominator,
            vestingPeriodCount,
            vestingPeriodDurationSeconds
        );
    }

    function claimTokens(
        uint256 totalAllocationWei,
        uint256 delay,
        uint32 tgeNumerator_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_,
        bytes32[] calldata proof
    ) external payable nonReentrant {
        require(!_isPermissionless(), 'This vesting does not require proofs');
        require(tgeNumerator_ <= tgeDenominator_, 'numerator can not be greater than denominator');
        require(tgeDenominator_ != 0, 'denominator can not equal 0');
        require(
            MerkleProof.verify(
                proof,
                merkleTreeRoot,
                keccak256(
                    abi.encode(
                        _msgSender(),
                        totalAllocationWei,
                        delay,
                        tgeNumerator_,
                        tgeDenominator_,
                        vestingPeriodCount_,
                        vestingPeriodDurationSeconds_
                    )
                )
            ),
            'Address configuration mismatch'
        );
        _claimTokens(
            totalAllocationWei,
            delay,
            tgeNumerator_,
            tgeDenominator_,
            vestingPeriodCount_,
            vestingPeriodDurationSeconds_
        );
    }

    function bought() external view returns (uint256) {
        if (address(_vault()) == address(0)) return 0;
        return token.balanceOf(address(_vault())) + _vault().released(address(token));
    }

    function releasable() external view returns (uint256) {
        if (address(_vault()) == address(0)) return 0;
        return _vault().vestedAmount(address(token), uint64(block.timestamp)) - _vault().released(address(token));
    }

    function released() public view returns (uint256) {
        if (address(_vault()) == address(0)) return 0;
        return _vault().released(address(token));
    }

    function nextUnlock() public view returns (uint256) {
        if (address(_vault()) == address(0) || _vault().start() + _vault().duration() <= block.timestamp) return 0;
        if (_vault().start() > block.timestamp) return _vault().start();
        if (vestingPeriodDurationSeconds == 0) return 0;
        uint256 timeSinceStart = block.timestamp - _vault().start();
        uint256 timeSinceLastUnlock = timeSinceStart % vestingPeriodDurationSeconds;
        uint256 nextUnlockIn = vestingPeriodDurationSeconds - timeSinceLastUnlock;
        return block.timestamp + nextUnlockIn;
    }

    function setMerkleTreeRoot(bytes32 newMerkleTreeRoot) external onlyOwner {
        merkleTreeRoot = newMerkleTreeRoot;
    }

    function _min(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? b : a;
    }

    function roundUp(uint256 fraction, uint256 denominator) internal pure returns (uint256) {
        uint256 imprecise = fraction / denominator;
        bool shouldRound = fraction - imprecise * denominator > 0;
        if (shouldRound) {
            return imprecise + 1;
        }
        return imprecise;
    }

    function _claimTokens(
        uint256 maxAllocation,
        uint256 delay,
        uint32 tgeNumerator_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_
    ) private {
        require(block.timestamp >= presaleStartTimestamp, 'Presale has not started');
        if (address(_vault()) == address(0)) {
            require(!_hasPresaleEnded(), 'The presale ended');
            vaults[_msgSender()] = new Vault(
                _msgSender(),
                uint64(block.timestamp + delay),
                tgeNumerator_,
                tgeDenominator_,
                vestingPeriodCount_,
                vestingPeriodDurationSeconds_
            );
        }
        uint256 walletAllocationWei = token.balanceOf(address(_vault())) + _vault().released(address(token));
        uint256 remainingETH = msg.value;
        if (!_hasPresaleEnded() && maxAllocation > walletAllocationWei) {
            if (_freeTokens()) {
                SafeERC20.safeTransfer(
                    token,
                    address(_vault()),
                    _min(token.balanceOf(address(this)), maxAllocation - walletAllocationWei)
                );
            } else if (remainingETH > 0) {
                require(token.balanceOf(address(this)) > 0, 'Presale ended');
                uint256 canBuyTokenWei = _min(token.balanceOf(address(this)), maxAllocation - walletAllocationWei);
                uint256 boughtTokenWei = roundUp((remainingETH * tokensWeiWorthOneEther), 1 ether);
                if (boughtTokenWei <= canBuyTokenWei) {
                    SafeERC20.safeTransfer(token, address(_vault()), boughtTokenWei);
                    Address.sendValue(capitalCollector, msg.value);
                    remainingETH = 0;
                } else {
                    SafeERC20.safeTransfer(token, address(_vault()), canBuyTokenWei);
                    uint256 usedETH = (canBuyTokenWei * 1 ether) / tokensWeiWorthOneEther;
                    Address.sendValue(capitalCollector, usedETH);
                    remainingETH = remainingETH - usedETH;
                }
            }
        }
        _vault().release(address(token));
        if (remainingETH > 0) {
            Address.sendValue(payable(_msgSender()), remainingETH);
        }
    }
}