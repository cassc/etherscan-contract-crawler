// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

import { Withdrawable } from "@delegatecall/utils/contracts/Withdrawable.sol";

import "./Math.sol";
import "./Vault.sol";
import "./IVestable.sol";
import "./InteractsWithVestable.sol";

contract Vesting is Ownable, Withdrawable, ReentrancyGuard, InteractsWithVestable {
    using EnumerableSet for EnumerableSet.UintSet;

    IERC20 public immutable token;

    bytes32 public whitelistRoot;
    uint256 public presaleStartTimestamp;
    uint256 public presaleDurationSeconds;
    uint256 public immutable tokensWeiWorthOneEthEther;
    uint256 public immutable maxTokenAllocationWei;
    uint256 public tgeStartTimestamp;
    uint32 public immutable tgeNumerator;
    uint32 public immutable tgeDenominator;
    uint32 public immutable vestingPeriodCount;
    uint32 public immutable vestingPeriodDurationSeconds;
    address payable public capitalCollector;

    uint256 public vaultSerialId;
    mapping(uint256 => Vault) public vaults;
    mapping(address => EnumerableSet.UintSet) private _vaultsByOwner;
    mapping(address => uint256) private _primaryVaults;

    modifier protectedWithdrawal() virtual override {
        _checkOwner();
        _;
    }

    modifier onlyDuringPresale() {
        require(block.timestamp >= presaleStartTimestamp, "Vesting: presale has not started");

        require(sale(), "Vesting: presale has ended");
        _;
    }

    /**
     * @param token_ an address of vested token
     * @param whitelistRoot_ merkle tree root where leaf == abi.encode(_msgSender(), totalAllocationWei).
     * Pass 0 if the vesting is permissionless.
     * @param presaleStartTimestamp_ unix time in seconds specifying a start of the presale
     * @param presaleDurationSeconds_ presale duration in seconds. Pass 0 if you
     * don’t want the presale to be time limited.
     * @param tokensWeiWorthOneEthEther_ how many wei of the sold token equals in
     * value 1 ether of the native blockchain currency. Pass 0 if you do not
     * want to collect capital or if deploying a vesting where funds where
     * collected in another way.
     * @param maxTokenAllocationWei_ max token allocation per address
     * Irrelevant if the presale is permissioned (whitelistRoot_ is not 0)
     * @param tgeStartTimestamp_ if the first tokens should be available
     * immidiatelly, pass 0. If not, pass appropriate timestamp in seconds.
     * @param tgeNumerator_ fraction of the allocation that should be released immidiatelly
     * @param tgeDenominator_ denominator of tgeNumerator_
     * @param vestingPeriodCount_ how many periods should the vesting be divided into
     * @param vestingPeriodDurationSeconds_ how many seconds one vesting period should last
     * @param capitalCollector_ an address where native blockchain currency is sent
     */
    constructor(
        address payable token_,
        bytes32 whitelistRoot_,
        uint256 presaleStartTimestamp_,
        uint256 presaleDurationSeconds_,
        uint256 tokensWeiWorthOneEthEther_,
        uint256 maxTokenAllocationWei_,
        uint256 tgeStartTimestamp_,
        uint32 tgeNumerator_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_,
        address payable capitalCollector_
    ) {
        require(tgeNumerator_ <= tgeDenominator_, "Vesting: tgeNumerator_ can not be greater than tgeDenominator_");
        require(vestingPeriodCount_ == 0 || vestingPeriodDurationSeconds_ > 0, "Vesting: periods of duration 0 seconds");
        require(capitalCollector_ != address(0), "Vesting: capital collector can not be address zero");

        if (presaleDurationSeconds_ > 0) require(presaleStartTimestamp_ > 0, "Vesting: can not specify duration without start");

        /**
         * @dev public presales should have maxTokenAllocationWei > 0
         */
        if (whitelistRoot_ == 0) require(maxTokenAllocationWei_ > 0, "Vesting: maxTokenAllocationWei can not be 0");

        require(
            tgeStartTimestamp_ == 0 || tgeStartTimestamp_ > (presaleStartTimestamp_ + presaleDurationSeconds_),
            "Vesting: tge start can not be earlier than presale end"
        );

        token = IERC20(token_);
        whitelistRoot = whitelistRoot_;
        presaleStartTimestamp = presaleStartTimestamp_;
        presaleDurationSeconds = presaleDurationSeconds_;
        tokensWeiWorthOneEthEther = tokensWeiWorthOneEthEther_;
        maxTokenAllocationWei = maxTokenAllocationWei_;
        tgeStartTimestamp = tgeStartTimestamp_;
        tgeNumerator = tgeNumerator_;
        tgeDenominator = tgeDenominator_;
        vestingPeriodCount = vestingPeriodCount_;
        vestingPeriodDurationSeconds = vestingPeriodDurationSeconds_;
        capitalCollector = capitalCollector_;
    }

    function sale() public view returns (bool) {
        if (block.timestamp < presaleStartTimestamp) return false;

        if (presaleDurationSeconds != 0 && block.timestamp > presaleStartTimestamp + presaleDurationSeconds) return false;

        return token.balanceOf(address(this)) > 0;
    }

    function vaultsByOwner(address owner) external view returns (uint256[] memory) {
        return _vaultsByOwner[owner].values();
    }

    function primaryVaultId(address owner) public view returns (uint256) {
        return _primaryVaults[owner];
    }

    function primaryVault(address owner) public view returns (Vault) {
        if (_primaryVaults[owner] == 0) return Vault(payable(address(0)));

        return vaults[_primaryVaults[owner]];
    }

    /**
     * @dev Returns the amount of tokens bought for a specific vault.
     */
    function bought(uint256 id) public view returns (uint256) {
        Vault vault = vaults[id];

        if (address(vault) == address(0)) return 0;

        return token.balanceOf(address(vault)) + vault.released(address(token));
    }

    /**
     * @dev Returns the amount of tokens releasable for a specific vault
     */
    function releasable(uint256 id) external view returns (uint256) {
        Vault vault = vaults[id];

        if (address(vault) == address(0)) return 0;

        return vault.vestedAmount(address(token), uint64(block.timestamp)) - vault.released(address(token));
    }

    /**
     * @dev Returns the amount of tokens released for all owned vaults
     */
    function released(uint256 id) public view returns (uint256) {
        Vault vault = vaults[id];

        if (address(vault) == address(0)) return 0;

        return vault.released(address(token));
    }

    /**
     * @dev Returns the amount of tokens locked for a specific vault
     */
    function nextUnlock(uint256 id) public view returns (uint256) {
        Vault vault = vaults[id];

        if (address(vault) == address(0) || vault.start() + vault.duration() <= block.timestamp) return 0;

        if (vault.start() > block.timestamp) return vault.start();

        if (vestingPeriodDurationSeconds == 0) return 0;

        uint256 timeSinceStart = block.timestamp - vault.start();
        uint256 timeSinceLastUnlock = timeSinceStart % vestingPeriodDurationSeconds;
        uint256 nextUnlockIn = vestingPeriodDurationSeconds - timeSinceLastUnlock;

        return block.timestamp + nextUnlockIn;
    }

    /* Domain
     ****************************************************************/

    function buy() external payable onlyDuringPresale nonReentrant {
        require(whitelistRoot == bytes32(0), "Vesting: please provide totalAllocationWei and a proof");

        _buy(maxTokenAllocationWei, 0, tgeNumerator, tgeDenominator, vestingPeriodCount, vestingPeriodDurationSeconds);
    }

    function buy(bytes32[] calldata proof) external payable onlyDuringPresale nonReentrant {
        require(MerkleProof.verify(proof, whitelistRoot, keccak256(abi.encode(_msgSender()))), "Vesting: account mismatch");

        _buy(maxTokenAllocationWei, 0, tgeNumerator, tgeDenominator, vestingPeriodCount, vestingPeriodDurationSeconds);
    }

    function buy(
        uint256 totalAllocationWei,
        uint256 delay,
        uint32 tgeNumerator_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_,
        bytes32[] calldata proof
    ) external payable nonReentrant onlyDuringPresale {
        require(
            MerkleProof.verify(
                proof,
                whitelistRoot,
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
            "Vesting: account mismatch"
        );

        _buy(totalAllocationWei, delay, tgeNumerator_, tgeDenominator_, vestingPeriodCount_, vestingPeriodDurationSeconds_);
    }

    function _buy(
        uint256 maxAllocation,
        uint256 delay,
        uint32 tgeNumerator_,
        uint32 tgeDenominator_,
        uint32 vestingPeriodCount_,
        uint32 vestingPeriodDurationSeconds_
    ) private {
        address sender = _msgSender();

        Vault vault = primaryVault(sender);

        if (address(vault) == address(0)) {
            uint256 startTimestamp = tgeStartTimestamp > 0 ? tgeStartTimestamp : block.timestamp;

            vault = new Vault(
                sender,
                uint64(startTimestamp + delay),
                tgeNumerator_,
                tgeDenominator_,
                vestingPeriodCount_,
                vestingPeriodDurationSeconds_
            );

            vaults[++vaultSerialId] = vault;

            _vaultsByOwner[sender].add(vaultSerialId);

            _primaryVaults[sender] = vaultSerialId;

            address vestable = address(token);
            if (_checkSupportsVestableInterface(vestable)) IVestable(vestable).onVaultCreated(address(address(vault)));
        }

        require(vault.beneficiary() == sender, "Vesting: only owner can buy tokens");

        address vaultAddress = address(vault);
        uint256 remainingETH = msg.value;
        uint256 walletAllocationWei = token.balanceOf(vaultAddress) + vault.released(address(token));

        if (maxAllocation > walletAllocationWei) {
            uint256 allocation = maxAllocation - walletAllocationWei;

            if (tokensWeiWorthOneEthEther == 0) {
                SafeERC20.safeTransfer(token, vaultAddress, Math.min(token.balanceOf(address(this)), allocation));
            }

            if (tokensWeiWorthOneEthEther != 0 && remainingETH > 0) {
                uint256 canBuyTokenWei = Math.min(token.balanceOf(address(this)), allocation);
                uint256 boughtTokenWei = Math.roundUp((remainingETH * tokensWeiWorthOneEthEther), 1 ether);

                if (boughtTokenWei <= canBuyTokenWei) {
                    SafeERC20.safeTransfer(token, vaultAddress, boughtTokenWei);

                    Address.sendValue(capitalCollector, msg.value);

                    remainingETH = 0;
                } else {
                    SafeERC20.safeTransfer(token, vaultAddress, canBuyTokenWei);

                    uint256 usedETH = (canBuyTokenWei * 1 ether) / tokensWeiWorthOneEthEther;

                    Address.sendValue(capitalCollector, usedETH);

                    remainingETH = remainingETH - usedETH;
                }
            }
        }

        vault.release(address(token));

        if (remainingETH > 0) Address.sendValue(payable(sender), remainingETH);
    }

    function claim(uint256 id) external nonReentrant {
        Vault vault = vaults[id];

        require(address(vault) != address(0), "Vesting: vault does not exist");
        require(vault.beneficiary() == _msgSender(), "Vesting: only owner can claim tokens");

        vault.release(address(token));
    }

    function transferVaultOwnership(uint256 id, address newOwner) external nonReentrant {
        address oldOwner = _msgSender();

        Vault vault = vaults[id];

        require(address(vault) != address(0), "Vesting: vault does not exist");
        require(oldOwner == vault.beneficiary(), "Vesting: only beneficiary can set new beneficiary");
        require(newOwner != address(0), "Vesting: new owner can not be address zero");
        require(newOwner != oldOwner, "Vesting: new owner can not be the same as old owner");
        require(newOwner != address(this), "Vesting: new owner can not be the vesting contract");

        _vaultsByOwner[oldOwner].remove(id);

        vault.changeBeneficiary(newOwner);

        _vaultsByOwner[newOwner].add(id);
    }

    /* Configuration
     ****************************************************************/

    function setWhitelistRoot(bytes32 whitelistRoot_) external onlyOwner {
        whitelistRoot = whitelistRoot_;
    }

    function schedule(uint256 presaleStartTimestamp_, uint256 presaleDurationSeconds_, uint256 tgeStartTimestamp_) external onlyOwner {
        require(vaultSerialId == 0, "Vesting: can not schedule started vesting");

        if (presaleDurationSeconds_ > 0) require(presaleStartTimestamp_ > 0, "Vesting: can not specify duration without start");

        require(
            tgeStartTimestamp_ == 0 || tgeStartTimestamp_ > (presaleStartTimestamp_ + presaleDurationSeconds_),
            "Vesting: tge start can not be earlier than presale end"
        );

        presaleStartTimestamp = presaleStartTimestamp_;
        presaleDurationSeconds = presaleDurationSeconds_;
        tgeStartTimestamp = tgeStartTimestamp_;
    }
}