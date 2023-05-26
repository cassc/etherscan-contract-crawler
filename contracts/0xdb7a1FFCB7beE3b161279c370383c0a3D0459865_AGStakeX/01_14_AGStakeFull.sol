// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./interfaces/IAGStakeFull.sol";
import "./interfaces/IAlphaGangGenerative.sol";
import "./interfaces/IAlphaGangOG.sol";
import "./interfaces/IGangToken.sol";

contract AGStakeX is IAGStake, Ownable, ERC721Holder, ERC1155Holder {
    // address to timestamp of last update
    mapping(address => uint256) public lastUpdate;

    IAlphaGangOG immutable AlphaGangOG;
    IAlphaGangGenerative AlphaGangG2;
    IGangToken immutable GANG;

    // maps OG tokenId to mapping of address to count of staked tokens
    mapping(uint256 => mapping(address => uint256)) public vaultOG;

    // Mapping: address to token to staked timestamp
    mapping(address => mapping(uint256 => uint256)) public override vaultG2;

    /**
     * token ID to staked at timestamp or 0 if token is not staked
     * Note 1 is more gas optimal than 0 for unstaked state but we won't expect too many of these changes
     */
    mapping(address => uint256) public stakedAtG2;

    // Mapping: address to count of tokens staked
    mapping(address => uint256) public ownerG2StakedCount;

    /**
     * mapping of address to timestamp when last OG was staked
     * Note This offers less granular controll of staking tokens at a benefit of less complexity/gas savings
     */
    mapping(address => uint256) stakedAtOG;

    // OG rate 300 per week
    uint256 public ogStakeRate = 496031746031746;
    // G2 rate 30 per week
    uint256 public G2StakeRate = 49603174603175;
    // Bonus base for holding OG tokens
    uint256 bonusBase = 500_000;
    // Bonus for holding all 3 kind of OG tokens
    uint256 triBonus = 100_000;

    uint256 constant BASE = 1_000_000;

    mapping(address => uint256) public override ogAllocation;

    constructor(
        IAlphaGangOG _og,
        IAlphaGangGenerative _G2,
        IGangToken _token
    ) {
        AlphaGangOG = _og;
        AlphaGangG2 = _G2;
        GANG = _token;
    }

    /**
     * @dev Stake tokens for generative.
     * Note This makes stakeAll obsolete, since we'd have to check every token minted to get all user tokens with ERC721A.
     */
    function stakeG2(uint256[] calldata tokenIds) public override {
        uint256 timeNow = block.timestamp;
        // for extra check both msg.sender and tx origin are correct:
        address _owner = msg.sender;
        if (msg.sender == address(AlphaGangG2)) {
            _owner = tx.origin;
        }

        _claim(_owner);

        for (uint8 i = 0; i < tokenIds.length; i++) {
            // verify the ownership
            require(
                AlphaGangG2.ownerOf(tokenIds[i]) == _owner,
                "Not your token"
            );

            require(vaultG2[_owner][tokenIds[i]] == 0, "Token already staked");

            // stake the token for _owner
            AlphaGangG2.transferFrom(_owner, address(this), tokenIds[i]);
            vaultG2[_owner][tokenIds[i]] = timeNow;
        }
        // update lastStake time for _owner
        // stakedAtG2[_owner] = timeNow;
        unchecked {
            ownerG2StakedCount[_owner] += tokenIds.length;
        }

        emit StakedG2(_owner, tokenIds, timeNow);
    }

    /**
     * @dev Unstake tokens for generative.
     *
     * @param tokenIds Array of tokens to unstake
     */
    function unstakeG2(uint256[] memory tokenIds) external {
        address _owner = msg.sender;
        _claim(_owner);

        for (uint8 i = 0; i < tokenIds.length; ++i) {
            require(vaultG2[_owner][tokenIds[i]] > 0, "Not your token");
            require(
                vaultG2[_owner][tokenIds[i]] < block.timestamp + 72 hours,
                "Token locked for 3 days"
            );
            vaultG2[_owner][tokenIds[i]] = 0;

            AlphaGangG2.transferFrom(address(this), _owner, tokenIds[i]);
        }

        ownerG2StakedCount[_owner] -= tokenIds.length;

        emit UnstakedG2(_owner, tokenIds, block.timestamp);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claimForAddress(address account) external {
        _claim(account);
    }

    function _claim(address account) internal {
        uint256 earned;

        // if there is no last update just set the first timestamp for address
        if (lastUpdate[account] > 0) {
            earned = earningInfo(account);
        }

        lastUpdate[account] = block.timestamp;

        if (earned > 0) {
            GANG.mint(account, earned);
        }

        emit Claimed(account, earned, block.timestamp);
    }

    // Check how much tokens account has for claiming
    function earningInfo(address account) public view returns (uint256 earned) {
        uint256 earnedWBonus;
        uint256 earnedNBonus;

        uint256 timestamp = block.timestamp;
        uint256 _lastUpdate = lastUpdate[account];

        // no earnings so far
        if (_lastUpdate == 0) return 0;

        uint256 tokenCountOG;

        uint256[] memory stakedCountOG = stakedOGBalanceOf(account);

        // bonus is applied for holding all 3 assets(can only be applied once)
        uint256 triBonusCount;
        unchecked {
            for (uint32 i; i < 3; ++i) {
                if (stakedCountOG[i] > 0) {
                    tokenCountOG += stakedCountOG[i];
                    ++triBonusCount;
                }
            }
        }

        uint256 bonus = BASE; // multiplier of 1

        unchecked {
            // add G2 tokens to bonusBase
            earnedWBonus += G2StakeRate * ownerG2StakedCount[account]; // count of owners tokens times rate for G2

            // Calculate bonus to be applied
            if (tokenCountOG > 0) {
                // Order: 50, Mac, Riri, bonus is halved by 50% for each additional token
                uint256 _bonusBase = bonusBase;

                // Add a single token to bonusBase
                earnedWBonus += ogStakeRate;
                // Add rest to noBonusBase
                earnedNBonus += ogStakeRate * (tokenCountOG - 1);

                // calculate total bonus to be applied, start adding bonus for more hodls
                for (uint32 i = 0; i < tokenCountOG; ++i) {
                    bonus += _bonusBase;
                    _bonusBase /= 2;
                }

                // triBonus for holding all 3 OGs
                if (triBonusCount == 3) {
                    bonus += triBonus;
                }
            }
        }

        // calculate and return how much is earned
        return
            (((earnedWBonus * bonus) / BASE) + earnedNBonus) *
            (timestamp - _lastUpdate);
    }

    /** OG Functions */
    function stakeSingleOG(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;

        // claim unstaked tokens, since count/rate will change
        _claim(_owner);

        AlphaGangOG.safeTransferFrom(
            _owner,
            address(this),
            tokenId,
            tokenCount,
            ""
        );

        stakedAtOG[_owner] = block.timestamp;

        unchecked {
            vaultOG[tokenId][_owner] += tokenCount;
        }

        emit StakedOG(
            _owner,
            _asSingletonArray(tokenId),
            _asSingletonArray(tokenCount),
            block.timestamp
        );
    }

    function unstakeSingleOG(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;
        uint256 _totalStaked = vaultOG[tokenId][_owner];

        require(
            _totalStaked >= 0,
            "You do have any tokens available for unstaking"
        );
        require(
            _totalStaked >= tokenCount,
            "You do not have requested token amount available for unstaking"
        );
        require(
            stakedAtOG[_owner] < block.timestamp + 72 hours,
            "Tokens locked for 3 days"
        );

        // claim rewards before unstaking
        _claim(_owner);

        unchecked {
            vaultOG[tokenId][_owner] -= tokenCount;
        }

        AlphaGangOG.safeTransferFrom(
            address(this),
            _owner,
            tokenId,
            tokenCount,
            ""
        );

        emit UnstakedOG(
            msg.sender,
            _asSingletonArray(tokenId),
            _asSingletonArray(tokenCount),
            block.timestamp
        );
    }

    function updateOGAllocation(address _owner, uint256 _count)
        external
        override
    {
        require(msg.sender == address(AlphaGangG2), "Only Generative");
        ogAllocation[_owner] -= _count;
    }

    /**
     * @dev
     *
     * Note this will stake all available tokens, but makes it possible to not immediately stake G2 tokens (@Hax)
     */
    function stakeOGForMint() external payable {
        // check if OG minting is active
        require(AlphaGangG2.mintActive(1), "Sale is not active");

        address _owner = msg.sender;
        uint256[] memory totalAvailable = unstakedOGBalanceOf(_owner);

        // get the count of tokens
        uint256 _totalOGsToBeStaked = totalAvailable[0] +
            totalAvailable[1] +
            totalAvailable[2];
        // make sure there are tokens to be staked
        require(_totalOGsToBeStaked > 0, "No tokens to stake");

        /**
         * Ammount of eth is sent to G2 contract, but checked here first
         * all OG get 2 tokens for WL + one additional for each token staked
         * in addition whales(3+ tokens) get reduced price
         */
        uint256 g2MintCount = _totalOGsToBeStaked + 2;

        uint256 timeNow = block.timestamp;

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        // claim and update the timestamp for this account
        _claim(_owner);

        AlphaGangOG.safeBatchTransferFrom(
            _owner,
            address(this),
            tokens,
            totalAvailable,
            ""
        );

        // Update stake time
        stakedAtOG[_owner] = timeNow;

        ogAllocation[_owner] += g2MintCount;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vaultOG[i][_owner] += totalAvailable[i - 1];
            }
        }

        emit StakedForMint(msg.sender, tokens, totalAvailable, block.timestamp);
    }

    /**
     * @dev Stakes all OG tokens of {_owner} by transfering them to this contract.
     *
     * Emits a {StakedOG} event.
     */
    function stakeAllOG() external {
        address _owner = msg.sender;
        uint256[] memory totalAvailable = unstakedOGBalanceOf(_owner);

        // claim for owner
        _claim(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        AlphaGangOG.safeBatchTransferFrom(
            _owner,
            address(this),
            tokens,
            totalAvailable,
            ""
        );

        // Update stake time
        stakedAtOG[_owner] = block.timestamp;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vaultOG[i][_owner] += totalAvailable[i - 1];
            }
        }

        emit StakedOG(msg.sender, tokens, totalAvailable, block.timestamp);
    }

    function unstakeAllOG() external {
        address _owner = msg.sender;
        require(
            stakedAtOG[_owner] < block.timestamp + 72 hours,
            "Tokens locked for 3 days"
        );

        // claim for owner
        _claim(_owner);

        uint256[] memory _totalStaked = stakedOGBalanceOf(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vaultOG[i][_owner] -= _totalStaked[i - 1];
            }
        }

        AlphaGangOG.safeBatchTransferFrom(
            address(this),
            _owner,
            tokens,
            _totalStaked,
            ""
        );

        emit UnstakedOG(_owner, tokens, _totalStaked, block.timestamp);
    }

    /** Views */
    function stakedOGBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        uint256[] memory tokenBalance = new uint256[](3);

        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                uint256 stakedCount = vaultOG[i][account];
                if (stakedCount > 0) {
                    tokenBalance[i - 1] += stakedCount;
                }
            }
        }
        return tokenBalance;
    }

    function unstakedOGBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        // This consumes ~4k gas less than batchBalanceOf with address array
        uint256[] memory totalTokenBalance = new uint256[](3);
        totalTokenBalance[0] = AlphaGangOG.balanceOf(account, 1);
        totalTokenBalance[1] = AlphaGangOG.balanceOf(account, 2);
        totalTokenBalance[2] = AlphaGangOG.balanceOf(account, 3);

        return totalTokenBalance;
    }

    /** Utils */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev
     * (@Hax) Migrate feature in case we need to manage tokens
     * Eg. someone sends token to staking contract directly or we need to migrate
     *
     */
    function setApprovalForAll(address operator, bool approved)
        external
        onlyOwner
    {
        AlphaGangG2.setApprovalForAll(operator, approved);
        AlphaGangOG.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Withdraw any ether that might get sent/stuck on this contract
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function stakedG2TokensOfOwner(address account)
        external
        view
        returns (uint256[] memory)
    {
        uint256 supply = AlphaGangG2.totalSupply();

        uint256 ownerStakedTokenCount = ownerG2StakedCount[account];
        uint256[] memory tokens = new uint256[](ownerStakedTokenCount);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (vaultG2[account][tokenId] > 0) {
                tokens[index] = tokenId;
            }
        }
        return tokens;
    }
}