// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import './interfaces/IManager.sol';
import './interfaces/ILaunchpad.sol';
import './interfaces/IAirdrop.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';
import './CredentialVerifier.sol';

/// @title Manager
/// @author gotbit
contract Manager is CredentialVerifier, IManager2, AccessControl {
    using SafeERC20 for IERC20Metadata;
    using ECDSA for bytes32;

    // read

    uint8 public constant ROUND_TYPES = 3;
    bytes32 public constant LP_ADMIN_ROLE = keccak256('LP_ADMIN');
    address public credentialVerifier;

    address public airdropContract;
    address public iqStaking;
    address public nft;
    uint256 public kickback;
    address public kickbackWallet;
    address public immutable native;
    address public launchpadLogic;
    address public vestingLogic;

    mapping(address => bool) public stables;
    mapping(address => bool) public dexes;

    address[] public rounds;

    NftOracleData public nftOracle;

    Project[] public project2;

    modifier onlyValidRound(uint256 round) {
        require(rounds.length > round, 'bad round');
        _;
    }

    function shouldUseOracle() external view returns (bool) {
        return (block.chainid != nftOracle.chainid);
    }

    function nftBalancesOracle(
        address user,
        bytes calldata data,
        bytes calldata signature
    ) external view returns (uint256[] memory) {
        bytes32 hashedData = keccak256(data).toEthSignedMessageHash();
        address signer = hashedData.recover(signature);
        require(signer == nftOracle.signer, 'wrong signer of signature');

        (
            address user2,
            address nftContract,
            uint256 timestamp,
            uint256 chainid,
            uint256[] memory balances
        ) = abi.decode(data, (address, address, uint256, uint256, uint256[]));

        require(user == user2, 'this signature was requested by a different user');
        require(nftContract == nftOracle.nftContract, 'wrong nft contract in signature');
        require(timestamp + 300 > block.timestamp, 'signature is too old');
        require(chainid == nftOracle.chainid, 'wrong chainid in signature');

        return balances;
    }

    function roundsLength() external view returns (uint256) {
        return rounds.length;
    }

    function roundsRead(uint256 offset, uint256 size)
        external
        view
        returns (address[] memory)
    {
        uint256 limit = Math.min(offset + size, rounds.length);
        address[] memory res = new address[](limit - offset);

        for (uint256 i = offset; i < limit; ) {
            res[i - offset] = rounds[i];
            unchecked {
                ++i;
            }
        }

        return res;
    }

    function project2Length() external view returns (uint256) {
        return project2.length;
    }

    function projectToken(uint256 id) external view returns (address) {
        return project2[id].token;
    }

    function projectWallet(uint256 id) external view returns (address) {
        return project2[id].wallet;
    }

    // write

    constructor(
        address iqStaking_,
        address nft_,
        uint256 kickback_,
        address kickbackWallet_,
        address native_,
        Logic memory logicContracts,
        address[] memory stables_,
        address[] memory dexes_,
        NftOracleData memory nftOracle_,
        address credentialVerifier_
    ) {
        iqStaking = iqStaking_;
        nft = nft_;
        kickback = kickback_;
        kickbackWallet = kickbackWallet_;
        native = native_;
        launchpadLogic = logicContracts.launchpad;
        vestingLogic = logicContracts.vesting;
        nftOracle = nftOracle_;
        credentialVerifier = credentialVerifier_;

        for (uint256 i; i < stables_.length; ) {
            stables[stables_[i]] = true;

            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < dexes_.length; ) {
            dexes[dexes_[i]] = true;
            unchecked {
                ++i;
            }
        }

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function invest(
        uint256 round,
        uint256 usd,
        bytes memory data,
        bytes memory signature,
        FractalProof calldata proof
    )
        external
        requiresCredential(
            credentialVerifier,
            'level:basic;citizenship_not:;residency_not:',
            0,
            proof
        )
        onlyValidRound(round)
    {
        address lpad = rounds[round];
        IERC20Metadata stableToken = ILaunchpad(lpad).stableToken();
        console.log('stableToken');
        stableToken.safeTransferFrom(msg.sender, lpad, usd);
        console.log('safeTransferFrom');

        ILaunchpad(lpad).invest(msg.sender, usd, data, signature);
        console.log('lpad.invest');
    }

    function claim(uint256 round, address investor) public onlyValidRound(round) {
        address lpad = rounds[round];
        address vesting = ILaunchpad(lpad).vestingContract();
        IVesting(vesting).claim(investor);
    }

    /// @dev Performs claim for multiple investors in one transaction
    /// @param claims Array of round IDs and investor addresses
    function claimBatch(Claim[] calldata claims) external {
        for (uint256 i; i < claims.length; ) {
            claim(claims[i].round, claims[i].investor);
            unchecked {
                ++i;
            }
        }
    }

    function payBack(uint256 round) external onlyValidRound(round) {
        address lpad = rounds[round];
        ILaunchpad(lpad).payBack(msg.sender);
    }

    function payBackOnPrice(uint256 round) external onlyValidRound(round) {
        address lpad = rounds[round];
        ILaunchpad(lpad).payBackOnPrice(msg.sender);
    }

    function investorsLength(uint256 round)
        external
        view
        onlyValidRound(round)
        returns (uint256)
    {
        address lpad = rounds[round];
        return ILaunchpad(lpad).investorsLength();
    }

    function airdropOvercap(uint256 round, uint256 size) external onlyValidRound(round) {
        address lpad = rounds[round];

        ILaunchpad(lpad).airdropOvercap(size);
    }

    function changeVestingSchedule(uint256 round, IVesting.Unlock[] calldata schedule)
        external
        onlyRole(LP_ADMIN_ROLE)
        onlyValidRound(round)
    {
        address lpad = rounds[round];

        address vesting = ILaunchpad(lpad).vestingContract();
        IVesting(vesting).changeSchedule(schedule);
    }

    /// @dev Changes the key used to prove a wallet has passed KYC. Can only be called by the admin
    /// @param credentialVerifier_ Address of the new credential verifier
    function setCredentialVerifier(address credentialVerifier_)
        external
        onlyRole(LP_ADMIN_ROLE)
    {
        credentialVerifier = credentialVerifier_;
    }

    function setTokensTransferred(uint256 round) external onlyValidRound(round) {
        address lpad = rounds[round];
        ILaunchpad(lpad).setTokensTransferred();
    }

    function setVestingContract(uint256 round, address vestingContract_)
        external
        onlyRole(LP_ADMIN_ROLE)
        onlyValidRound(round)
    {
        address lpad = rounds[round];

        ILaunchpad(lpad).setVestingContract(vestingContract_);
    }

    /// @dev Changes the address of the NFT contract. Can only be called by the admin
    /// @param nft_ Address of the new NFT contract
    function setNftContract(address nft_) external onlyRole(LP_ADMIN_ROLE) {
        require(nft_ != address(0), 'invalid nft contract');
        nft = nft_;
    }

    /// @dev Changes the address of the IQ staking contract. Can only be called by the admin
    /// @param iqStaking_ Address of the new IQ staking contract
    function setStakingContract(address iqStaking_) external onlyRole(LP_ADMIN_ROLE) {
        require(iqStaking_ != address(0), 'invalid staking contract');
        iqStaking = iqStaking_;
    }

    /// @dev Changes the kickback taken from each investment. Can only be called by the admin
    /// @param kickback_ New kickback value (in 1e18)
    function setKickback(uint256 kickback_) external onlyRole(LP_ADMIN_ROLE) {
        require(kickback_ < 1e18, 'invalid kickback');
        kickback = kickback_;
    }

    /// @dev Changes the address of the kickback wallet. Can only be called by the admin
    /// @param kickbackWallet_ Address of the new kickback wallet
    function setKickbackWallet(address kickbackWallet_) external onlyRole(LP_ADMIN_ROLE) {
        require(kickbackWallet_ != address(0), 'invalid kickback wallet');
        kickbackWallet = kickbackWallet_;
    }

    /// @dev Changes the address of the launchpad logic contract. Can only be called by the admin
    /// @param launchpadLogic_ Address of the new launchpad logic contract
    function setLaunchpadLogic(address launchpadLogic_) external onlyRole(LP_ADMIN_ROLE) {
        require(launchpadLogic_ != address(0), 'invalid launchpad logic');
        launchpadLogic = launchpadLogic_;
    }

    /// @dev Changes the address of the vesting logic contract. Can only be called by the admin
    /// @param vestingLogic_ Address of the new vesting logic contract
    function setVestingLogic(address vestingLogic_) external onlyRole(LP_ADMIN_ROLE) {
        require(vestingLogic_ != address(0), 'invalid vesting logic');
        vestingLogic = vestingLogic_;
    }

    function changeNftOracleSettings(NftOracleData calldata data)
        external
        onlyRole(LP_ADMIN_ROLE)
    {
        require(data.signer != address(0), 'invalid signer');
        require(data.nftContract != address(0), 'invalid nft contract');
        nftOracle = data;
    }

    function createRound(
        uint256 projectId,
        uint8 roundType,
        ILaunchpad.Launch calldata launchData,
        IVesting.Unlock[] calldata sched,
        address stable,
        address dexRouter
    ) external onlyRole(LP_ADMIN_ROLE) {
        require(projectId < project2.length, 'bad project id');
        require(stables[stable], 'non-whitelisted stable');
        require(dexes[dexRouter], 'non-whitelisted dex');

        Project memory proj = project2[projectId];
        require(stable != proj.token, 'stable == project token');

        // deploy the launchpad contract
        address lpad = Clones.clone(launchpadLogic);
        rounds.push(lpad);

        ILaunchpad(lpad).initialize(
            projectId,
            roundType,
            launchData,
            kickback,
            stable,
            native,
            kickbackWallet,
            dexRouter,
            nft
        );

        // deploy the vesting contract
        address vesting = Clones.clone(vestingLogic);
        IVesting(vesting).initialize(roundType, lpad, sched, address(this));

        // let the launchpad know about the vesting contract
        ILaunchpad(lpad).setVestingContract(vesting);

        emit CreateRound(projectId, (rounds.length - 1), lpad);
    }

    function airdrop(
        address token,
        uint256 amount,
        IIqStaking.UserSharesOutput[] memory receivers
    ) external onlyRole(LP_ADMIN_ROLE) {
        require(airdropContract != address(0), 'airdrop contract not set');
        IAirdrop(airdropContract).airdrop(token, amount, receivers);
    }

    function setAirdropContract(address airdropContract_)
        external
        onlyRole(LP_ADMIN_ROLE)
    {
        require(airdropContract_ != address(0), 'zero address');
        airdropContract = airdropContract_;
    }

    function setAirdropManager(address manager_) external onlyRole(LP_ADMIN_ROLE) {
        require(airdropContract != address(0), 'airdrop contract not set');
        IAirdrop(airdropContract).setManager(manager_);
    }

    /// @dev Allows `newDex` to be used in rounds for price info. Can only be called by the admin
    /// @param newDex Address of the new dex
    function addDex(address newDex) external onlyRole(LP_ADMIN_ROLE) {
        dexes[newDex] = true;
    }

    /// @dev Sets whether `dex` can be used in rounds for price info or not. Can only be called by the admin
    /// @param dex Address of the dex
    /// @param value Whether the dex can be used or not
    function setDex(address dex, bool value) external onlyRole(LP_ADMIN_ROLE) {
        dexes[dex] = value;
    }

    /// @dev Allows `stable` to be used in rounds for investment.
    /// Can only be called by the admin
    /// @param stable Address of the new stable
    /// @param value Whether the stable can be used or not
    function setStable(address stable, bool value) external onlyRole(LP_ADMIN_ROLE) {
        stables[stable] = value;
    }

    function createProject(address token, address wallet)
        external
        onlyRole(LP_ADMIN_ROLE)
    {
        require(wallet != address(0), 'wallet is zero');
        project2.push(Project(token, wallet));
    }

    function setProjectParams(
        uint256 id,
        address token,
        address wallet
    ) external onlyRole(LP_ADMIN_ROLE) {
        require(project2.length > id, 'project doesnt exist');
        require(wallet != address(0), 'wallet is zero');
        project2[id] = Project(token, wallet);
    }

    function setRoundType(uint256 round, uint256 roundType_)
        external
        onlyRole(LP_ADMIN_ROLE)
        onlyValidRound(round)
    {
        address lpad = rounds[round];

        ILaunchpad(lpad).setRoundType(roundType_);
    }

    function setRoundData(
        uint256 round,
        ILaunchpad.Launch memory data,
        address stableToken_
    )
        external
        onlyRole(LP_ADMIN_ROLE)
        onlyValidRound(round)
    {
        address lpad = rounds[round];

        ILaunchpad(lpad).setRoundData(data, stableToken_);
    }

    function setDexRouter(uint256 round, address router)
        external
        onlyRole(LP_ADMIN_ROLE)
        onlyValidRound(round)
    {
        address lpad = rounds[round];

        ILaunchpad(lpad).setDexRouter(router);
    }

    /// @dev Updates the project token in an old round `round`
    /// @param round Round ID to update
    function setProjectToken(uint256 round)
        external
        onlyRole(LP_ADMIN_ROLE)
        onlyValidRound(round)
    {
        address lpad = rounds[round];
        ILaunchpad(lpad).setProjectToken();
    }
}