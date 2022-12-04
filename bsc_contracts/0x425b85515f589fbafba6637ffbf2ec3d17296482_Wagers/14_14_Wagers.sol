// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../lib/ninja-syndicate/contracts/utils/Crypto_SignatureVerifier.sol";

contract Wagers is SignatureVerifier, ERC1155, ERC1155Supply, Ownable {
    enum Factions {
        UNKNOWN,
        ZHI,
        RMOMC,
        BC,
        ZHI_RAKE,
        RMOMC_RAKE,
        BC_RAKE
    }
    uint256 AdminSavingsAccount = 0;
    uint256 AdminBoostAccount = 1;
    bool paused = false;
    bool skip_signatures = false;

    // Take amounts from pot to rake back to admin
    // Linear increase
    // Directly proportional
    uint256 public RakeMax = 0.1 ether;
    uint256 public RakeProportion = 0.1 * 10**18;

    // Take amounts from pot to incentivise commit rewards
    // Linear increase
    // Inversely proportional
    // Takes from the rake
    bool CommitRewardEnabled = true;
    uint256 public CommitRewardMax = 0.05 ether;
    uint256 public CommitRewardProportion = 0.2 * 10**18;

    // Take amounts from pot to fill up the boost pot
    // Linear increase
    // Directly proportional
    // Takes from the rake
    bool BoostEnabled = true;
    uint256 public BoostMax = 0.1 ether;
    uint256 public BoostProportion = 0.2 * 10**18;

    // BattleCommit for signature verification parameters
    struct BattleCommit {
        uint256 number;
        uint256 started_at;
        uint256 ended_at;
        Factions winner;
        Factions runner_up;
        Factions loser;
    }

    // CurrentBattle for signature verification parameters
    struct CurrentBattle {
        uint256 number;
        uint256 started_at;
        uint256 expires_at;
    }

    // Results of historical battles
    mapping(uint256 => Factions) public Winners;

    constructor(address _signer)
        SignatureVerifier(_signer)
        ERC1155("https://supremacy.wagers.app/api/{id}.json")
    {
        signer = _signer;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    modifier notPaused() {
        require(!paused, "contract paused");
        _;
    }

    // -----------------------
    // User Callable Functions
    // -----------------------

    // Commit battle results
    function Commit(BattleCommit memory _battleCommit, bytes memory signature)
        public
        notPaused
    {
        require(
            Winners[_battleCommit.number] == Factions.UNKNOWN,
            "battle already committed"
        );
        bytes32 digest = BattleCommitHash(_battleCommit);
        if (!skip_signatures) {
            require(
                SignatureVerifier.verify(digest, signature),
                "invalid signature"
            );
        }
        Winners[_battleCommit.number] = _battleCommit.winner;

        uint256 zhi_rake = 0;
        uint256 rmomc_rake = 0;
        uint256 bc_rake = 0;
        ClearBoosts(_battleCommit.number, _battleCommit.winner);
        if (
            totalSupply(
                BuildBNFComposite(_battleCommit.number, _battleCommit.winner)
            ) == 0
        ) {
            // No winners, rake everything to admin

            zhi_rake = totalSupply(
                BuildBNFComposite(_battleCommit.number, Factions.ZHI)
            );
            rmomc_rake = totalSupply(
                BuildBNFComposite(_battleCommit.number, Factions.RMOMC)
            );
            bc_rake = totalSupply(
                BuildBNFComposite(_battleCommit.number, Factions.BC)
            );
        } else {
            // Calculate rakes
            (zhi_rake, rmomc_rake, bc_rake) = rakeable(
                _battleCommit.number,
                _battleCommit.winner
            );
        }

        uint256 rewardAmt = MintCommitTokens(
            _battleCommit.number,
            zhi_rake,
            rmomc_rake,
            bc_rake
        );
        if (rewardAmt > 0) {
            (bool success, ) = msg.sender.call{value: rewardAmt}("");
            require(success, "Failed to send rewards");
        }

        emit UserCommit(_battleCommit.number);
    }

    // Bet on a battle
    function Bet(
        uint256 bet_battle_number,
        Factions bet_faction,
        CurrentBattle memory _currentBattle,
        bytes memory signature
    ) public payable notPaused {
        require(
            Winners[bet_battle_number] == Factions.UNKNOWN,
            "battle results already committed"
        );
        require(
            bet_battle_number > _currentBattle.number,
            "bet battle in past"
        );
        require(msg.value > 0, "no value received");
        uint256 bnf_id = BuildBNFComposite(bet_battle_number, bet_faction);
        bytes32 digest = CurrentBattleNumberHash(_currentBattle);
        if (!skip_signatures) {
            require(
                SignatureVerifier.verify(digest, signature),
                "invalid signature"
            );
        }
        uint256[] memory ids = new uint256[](2);
        ids[0] = bnf_id;
        ids[1] = BattleNumberTotalID(bet_battle_number);

        uint256[] memory amts = new uint256[](2);
        amts[0] = msg.value;
        amts[1] = msg.value;

        _mintBatch(msg.sender, ids, amts, bytes(""));
        emit UserBet(bet_battle_number, bet_faction, msg.value);
    }

    // Claim winnings
    function Claim(
        uint256 claim_battle_number,
        CurrentBattle memory _currentBattle,
        bytes memory signature
    ) public notPaused {
        Factions winner = Winners[claim_battle_number];
        require(winner != Factions.UNKNOWN, "battle not committed yet");
        bytes32 digest = CurrentBattleNumberHash(_currentBattle);
        if (!skip_signatures) {
            require(
                SignatureVerifier.verify(digest, signature),
                "invalid signature"
            );
        }
        require(claim_battle_number < _currentBattle.number);
        uint256 claimAmt = Claimable(claim_battle_number);
        require(claimAmt > 0 ether, "0 claim balance");
        (bool success, ) = msg.sender.call{value: claimAmt}("");
        uint256 bnf_id = BuildBNFComposite(claim_battle_number, winner);
        uint256 burnAmt = balanceOf(msg.sender, bnf_id);
        _burn(msg.sender, bnf_id, burnAmt);
        require(success, "Failed to claim");
        emit UserClaim(claim_battle_number, claimAmt);
    }

    function RakeBoostable(uint256 rakeAmt) internal view returns (uint256) {
        // Take boost
        if (!BoostEnabled) {
            return 0;
        }
        uint256 boostAmt = (rakeAmt * BoostProportion) / 10**18;
        if (boostAmt > BoostMax) {
            boostAmt = BoostMax;
        }
        return boostAmt;
    }

    function CommitRewardEstimate(uint256 battle_number, Factions winner)
        public
        view
        returns (uint256)
    {
        uint256 totalRaked = ((TotalBattleShares(battle_number) -
            TotalFactionShares(battle_number, winner)) * RakeProportion) /
            10**18;

        return (totalRaked * CommitRewardProportion) / 10**18;
    }

    function RakeRewardable(uint256 rakeAmt) internal view returns (uint256) {
        // Take reward
        if (!CommitRewardEnabled) {
            return 0;
        }

        uint256 rewardAmt = (rakeAmt * CommitRewardProportion) / 10**18;
        return rewardAmt;
    }

    // Boost next pot with everything in the boost account
    function Boost(
        uint256 battle_number,
        CurrentBattle memory _currentBattle,
        bytes memory signature
    ) public notPaused {
        require(
            _currentBattle.number + 1 == battle_number,
            "can only boost next battle"
        );

        bytes32 digest = CurrentBattleNumberHash(_currentBattle);
        if (!skip_signatures) {
            require(
                SignatureVerifier.verify(digest, signature),
                "invalid signature"
            );
        }

        uint256 ZHI_id = BuildBNFComposite(battle_number, Factions.ZHI);
        uint256 RMOMC_id = BuildBNFComposite(battle_number, Factions.RMOMC);
        uint256 BC_id = BuildBNFComposite(battle_number, Factions.BC);

        uint256 amt = balanceOf(address(this), AdminBoostAccount);

        uint256[] memory ids = new uint256[](5);
        ids[0] = ZHI_id;
        ids[1] = RMOMC_id;
        ids[2] = BC_id;
        ids[3] = BattleNumberTotalID(battle_number);

        uint256[] memory amts = new uint256[](5);
        amts[0] = amt / 3;
        amts[1] = amt / 3;
        amts[2] = amt / 3;
        amts[3] = amt;

        _mintBatch(address(this), ids, amts, bytes(""));
        _burn(address(this), AdminBoostAccount, amt);
    }

    // DonateToBoost adds donations to boost pool
    function DonateToBoost() public payable {
        uint256 amt = msg.value;
        require(amt > 0, "no value provided for boost");
        _mint(address(this), AdminBoostAccount, amt, bytes(""));
    }

    // ------------------------
    // User Read-only Functions
    // ------------------------

    // Boostable the amt allowed to boost
    function Boostable() public view returns (uint256) {
        return balanceOf(address(this), AdminBoostAccount);
    }

    // TotalBoosted returns total boost for a single battle
    function TotalBoosted(uint256 battle_number) public view returns (uint256) {
        return
            TotalFactionInjections(battle_number, Factions.ZHI) +
            TotalFactionInjections(battle_number, Factions.RMOMC) +
            TotalFactionInjections(battle_number, Factions.BC);
    }

    function TotalFactionInjections(uint256 battle_number, Factions faction)
        public
        view
        returns (uint256)
    {
        return
            balanceOf(address(this), BuildBNFComposite(battle_number, faction));
    }

    // Claimable winnings
    function Claimable(uint256 claim_battle_number)
        public
        view
        returns (uint256)
    {
        uint256 totalShares = TotalBattleShares(claim_battle_number);
        uint256 userWinningShares = UserWinningShares(claim_battle_number);
        uint256 totalWinningShares = TotalWinningShares(claim_battle_number);

        uint256 ZHIRakeAccountID = BuildBNFRakeID(
            claim_battle_number,
            Factions.ZHI
        );
        uint256 RMOMCRakeAccountID = BuildBNFRakeID(
            claim_battle_number,
            Factions.RMOMC
        );
        uint256 BCRakeAccountID = BuildBNFRakeID(
            claim_battle_number,
            Factions.BC
        );

        uint256 totalRake = totalSupply(ZHIRakeAccountID) +
            totalSupply(RMOMCRakeAccountID) +
            totalSupply(BCRakeAccountID);

        if (totalWinningShares == 0) {
            return 0;
        }

        uint256 availableShares = totalShares - totalRake;
        return (availableShares * userWinningShares) / (totalWinningShares);
    }

    // -----------------------
    // Internal functions
    // -----------------------

    // Dangerous
    // Do not use
    // Only use if you're SURE no one has betted in a specific battle and you need to reclaim the tokens
    function AdminCancelBoost(uint256 battle_number) public onlyOwner {
        uint256 ZHI_id = BuildBNFComposite(battle_number, Factions.ZHI);
        uint256 RMOMC_id = BuildBNFComposite(battle_number, Factions.RMOMC);
        uint256 BC_id = BuildBNFComposite(battle_number, Factions.BC);

        uint256[] memory amts = new uint256[](4);
        amts[0] = balanceOf(address(this), ZHI_id);
        amts[1] = balanceOf(address(this), RMOMC_id);
        amts[2] = balanceOf(address(this), BC_id);

        uint256[] memory mint_ids = new uint256[](4);
        mint_ids[0] = AdminSavingsAccount;
        mint_ids[1] = AdminSavingsAccount;
        mint_ids[2] = AdminSavingsAccount;

        _mintBatch(address(this), mint_ids, amts, bytes(""));

        uint256[] memory burn_ids = new uint256[](4);
        burn_ids[0] = ZHI_id;
        burn_ids[1] = RMOMC_id;
        burn_ids[2] = BC_id;

        _burnBatch(address(this), burn_ids, amts);
    }

    // AdminManualBoost moves treasury to boost pool
    function AdminManualBoost(uint256 amt) public onlyOwner {
        require(
            amt < balanceOf(address(this), 0),
            "not enough treasury to move to boost"
        );
        _burn(address(this), AdminSavingsAccount, amt);
        _mint(address(this), AdminBoostAccount, amt, bytes(""));
    }

    // AdminWithdrawable the amt allowed to withdraw in the contract
    function AdminWithdrawable() public view onlyOwner returns (uint256) {
        return balanceOf(address(this), AdminSavingsAccount);
    }

    // AdminWithdraw the amt in the contract
    function AdminWithdraw(uint256 amt) public onlyOwner {
        _burn(address(this), AdminSavingsAccount, amt);
        (bool success, ) = owner().call{value: amt}("");
        require(success, "Failed to withdraw");
        emit Withdraw(amt);
    }

    // AdminSetPaused the contract
    function AdminSetPaused(bool _paused) public onlyOwner {
        paused = _paused;
        emit SetPaused(_paused);
    }

    // AdminSetURI update the baseURI of the ERC1155
    function AdminSetURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
        emit SetURI(newuri);
    }

    function AdminSetRakeMax(uint256 _RakeMax) public onlyOwner {
        RakeMax = _RakeMax;
        emit SetRakeMax(_RakeMax);
    }

    function AdminSetRakeProportion(uint256 _RakeProportion) public onlyOwner {
        RakeProportion = _RakeProportion;
        emit SetRakeProportion(_RakeProportion);
    }

    function AdminSetCommitRewardEnabled(bool _CommitRewardEnabled)
        public
        onlyOwner
    {
        CommitRewardEnabled = _CommitRewardEnabled;
        emit SetCommitRewardEnabled(_CommitRewardEnabled);
    }

    function AdminSetCommitRewardMax(uint256 _CommitRewardMax)
        public
        onlyOwner
    {
        CommitRewardMax = _CommitRewardMax;
        emit SetCommitRewardMax(_CommitRewardMax);
    }

    function AdminSetCommitRewardProportion(uint256 _CommitRewardProportion)
        public
        onlyOwner
    {
        CommitRewardProportion = _CommitRewardProportion;
        emit SetCommitRewardProportion(_CommitRewardProportion);
    }

    function AdminSetBoostEnabled(bool _BoostEnabled) public onlyOwner {
        BoostEnabled = _BoostEnabled;
        emit SetBoostEnabled(_BoostEnabled);
    }

    function AdminSetBoostMax(uint256 _BoostMax) public onlyOwner {
        BoostMax = _BoostMax;
        emit SetBoostMax(_BoostMax);
    }

    function AdminSetBoostProportion(uint256 _BoostProportion)
        public
        onlyOwner
    {
        BoostProportion = _BoostProportion;
        emit SetBoostProportion(_BoostProportion);
    }

    function AdminSetSkipSignatures(bool skip) public onlyOwner {
        skip_signatures = skip;
    }

    // -----------------------
    // Helpers and internal functions
    // -----------------------

    function rakeable(uint256 battle_number, Factions winner)
        public
        view
        returns (
            uint256 zhi_rake,
            uint256 rmomc_rake,
            uint256 bc_rake
        )
    {
        // Take rake from losers
        uint256 ZHIBetsID = BuildBNFComposite(battle_number, Factions.ZHI);
        uint256 RMOMCBetsID = BuildBNFComposite(battle_number, Factions.RMOMC);
        uint256 BCBetsID = BuildBNFComposite(battle_number, Factions.BC);
        zhi_rake = (totalSupply(ZHIBetsID) * RakeProportion) / 10**18;
        rmomc_rake = (totalSupply(RMOMCBetsID) * RakeProportion) / 10**18;
        bc_rake = (totalSupply(BCBetsID) * RakeProportion) / 10**18;

        // Winner has zero rake
        if (winner == Factions.ZHI) {
            zhi_rake = 0;
        }
        if (winner == Factions.RMOMC) {
            rmomc_rake = 0;
        }
        if (winner == Factions.BC) {
            bc_rake = 0;
        }
    }

    function MintCommitTokens(
        uint256 battle_number,
        uint256 zhi_rake,
        uint256 rmomc_rake,
        uint256 bc_rake
    ) internal returns (uint256) {
        uint256 rakeAmt = zhi_rake + rmomc_rake + bc_rake;
        uint256 boostAmt = RakeBoostable(rakeAmt);
        uint256 rewardAmt = RakeRewardable(rakeAmt);
        uint256 ZHIRakeAccountID = BuildBNFRakeID(battle_number, Factions.ZHI);
        uint256 RMOMCRakeAccountID = BuildBNFRakeID(
            battle_number,
            Factions.RMOMC
        );
        uint256 BCRakeAccountID = BuildBNFRakeID(battle_number, Factions.BC);

        uint256[] memory ids = new uint256[](5);
        ids[0] = AdminSavingsAccount;
        ids[1] = AdminBoostAccount;
        ids[2] = ZHIRakeAccountID;
        ids[3] = RMOMCRakeAccountID;
        ids[4] = BCRakeAccountID;

        uint256[] memory amts = new uint256[](5);
        amts[0] = rakeAmt - boostAmt - rewardAmt;
        amts[1] = boostAmt;
        amts[2] = zhi_rake;
        amts[3] = rmomc_rake;
        amts[4] = bc_rake;

        // Store offset quantities for future claimable calculation
        _mintBatch(address(this), ids, amts, bytes(""));
        return rewardAmt;
    }

    // BattleCommitHash returns the hash of a historical battle record for signature verification
    function BattleCommitHash(BattleCommit memory _battleCommit)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _battleCommit.number,
                    _battleCommit.started_at,
                    _battleCommit.ended_at,
                    uint256(_battleCommit.winner),
                    uint256(_battleCommit.runner_up),
                    uint256(_battleCommit.loser)
                )
            );
    }

    // CurrentBattleNumberHash returns the hash of the current battle for signature verification
    function CurrentBattleNumberHash(CurrentBattle memory _currentBattle)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _currentBattle.number,
                    _currentBattle.started_at,
                    _currentBattle.expires_at
                )
            );
    }

    // TotalBattleShares total bets for a single battle
    function TotalBattleShares(uint256 battle_number)
        public
        view
        returns (uint256)
    {
        uint256 totalAmt = totalSupply(
            BuildBNFComposite(battle_number, Factions.ZHI)
        ) +
            totalSupply(BuildBNFComposite(battle_number, Factions.RMOMC)) +
            totalSupply(BuildBNFComposite(battle_number, Factions.BC));
        return totalAmt;
    }

    // TotalFactionShares total bets for a single battle for a single faction
    function TotalFactionShares(uint256 battle_number, Factions faction)
        public
        view
        returns (uint256)
    {
        if (faction == Factions.ZHI) {
            return totalSupply(BuildBNFComposite(battle_number, Factions.ZHI));
        }
        if (faction == Factions.RMOMC) {
            return
                totalSupply(BuildBNFComposite(battle_number, Factions.RMOMC));
        }
        if (faction == Factions.BC) {
            return totalSupply(BuildBNFComposite(battle_number, Factions.BC));
        }

        return 0;
    }

    // TotalFactionShares total bets for a single battle for the winning faction
    function TotalWinningShares(uint256 battle_number)
        public
        view
        returns (uint256)
    {
        Factions winner = Winners[battle_number];
        uint256 totalWinShares = 0;
        if (winner == Factions.ZHI) {
            uint256 id = BuildBNFComposite(battle_number, Factions.ZHI);
            totalWinShares = totalSupply(id) - balanceOf(address(this), id); // Remove admin shares from boost
        }

        if (winner == Factions.RMOMC) {
            uint256 id = BuildBNFComposite(battle_number, Factions.RMOMC);
            totalWinShares = totalSupply(id) - balanceOf(address(this), id); // Remove admin shares from boost
        }

        if (winner == Factions.BC) {
            uint256 id = BuildBNFComposite(battle_number, Factions.BC);
            totalWinShares = totalSupply(id) - balanceOf(address(this), id); // Remove admin shares from boost
        }
        return totalWinShares;
    }

    // UserWinningShares the number of shares the user has that are winning
    function UserWinningShares(uint256 battle_number)
        public
        view
        returns (uint256)
    {
        Factions winner = Winners[battle_number];
        uint256 userAmt = 0;
        if (winner == Factions.ZHI) {
            userAmt = balanceOf(
                msg.sender,
                BuildBNFComposite(battle_number, Factions.ZHI)
            );
        }

        if (winner == Factions.RMOMC) {
            userAmt = balanceOf(
                msg.sender,
                BuildBNFComposite(battle_number, Factions.RMOMC)
            );
        }

        if (winner == Factions.BC) {
            userAmt = balanceOf(
                msg.sender,
                BuildBNFComposite(battle_number, Factions.BC)
            );
        }
        return userAmt;
    }

    // Burn admin bets for winning factions because admin doesn't claim
    // Mint admin bet for winner faction back into 0 account
    // Do not touch admin bets for losing factions because this will go to claimants
    function ClearBoosts(uint256 battle_number, Factions winner) internal {
        uint256 bnf_id = BuildBNFComposite(battle_number, winner);
        uint256 amt = balanceOf(address(this), bnf_id);
        if (amt > 0) {
            _burn(address(this), bnf_id, amt);
            _mint(address(this), AdminSavingsAccount, amt, bytes(""));
        }
    }

    // BattleNumberTotalID returns the battle_number total ID
    function BattleNumberTotalID(uint256 battle_number)
        internal
        pure
        returns (uint256)
    {
        return battle_number * 10;
    }

    // BattleNumberFromBNFComposite returns the battle_number from composite ID
    function BattleNumberFromBNFComposite(uint256 battle_number_faction)
        internal
        pure
        returns (uint256)
    {
        return battle_number_faction / 10;
    }

    // FactionFromBNFComposite returns the faction from composite ID
    function FactionFromBNFComposite(uint256 battle_number_faction)
        internal
        pure
        returns (Factions)
    {
        return Factions(battle_number_faction % 10);
    }

    // BuildBNFComposite returns the faction from composite ID
    function BuildBNFComposite(uint256 battle_number, Factions faction)
        internal
        pure
        returns (uint256)
    {
        return battle_number * 10 + uint256(faction);
    }

    // BuildBNFComposite returns the faction from composite ID
    function BuildBNFRakeID(uint256 battle_number, Factions faction)
        internal
        pure
        returns (uint256)
    {
        // 1,2,3 -> 4,5,6
        return battle_number * 10 + uint256(faction) + 3;
    }

    // ---
    // Overrides
    // ---

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // ---
    // Events
    // ---

    event UserBet(uint256 battle_number, Factions faction, uint256 amt);
    event UserClaim(uint256 battle_number, uint256 amt);
    event UserCommit(uint256 battle_number);
    event Withdraw(uint256 amt);
    event SetURI(string newuri);
    event SetSkipSignatures(bool skip);
    event SetPaused(bool paused);
    event SetRakeMax(uint256 _RakeMax);
    event SetRakeProportion(uint256 _RakeProportion);
    event SetCommitRewardEnabled(bool _CommitRewardEnabled);
    event SetCommitRewardMax(uint256 _CommitRewardMax);
    event SetCommitRewardProportion(uint256 _CommitRewardProportion);
    event SetBoostEnabled(bool _BoostEnabled);
    event SetBoostMax(uint256 _BoostMax);
    event SetBoostProportion(uint256 _BoostProportion);
}