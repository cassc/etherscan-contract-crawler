pragma solidity ^0.8.0;

import {Errors} from "../libraries/helpers/Errors.sol";
import {TransferHelper} from "../libraries/helpers/TransferHelper.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {ISettings} from "../interfaces/ISettings.sol";
import {SettingStorage} from "../libraries/proxy/SettingStorage.sol";
import {IERC20} from "../libraries/openzeppelin/token/ERC20/IERC20.sol";
import {IERC721} from "../libraries/openzeppelin/token/ERC721/IERC721.sol";
import {ERC20Upgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC721HolderUpgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import {ERC1155HolderUpgradeable} from "../libraries/openzeppelin/upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import {OwnableUpgradeable} from "../libraries/openzeppelin/upgradeable/access/OwnableUpgradeable.sol";
import {TokenVaultTreasuryLogic} from "../libraries/logic/TokenVaultTreasuryLogic.sol";
import {TokenVaultStakingLogic} from "../libraries/logic/TokenVaultStakingLogic.sol";
import {TokenVaultGovernorLogic} from "../libraries/logic/TokenVaultGovernorLogic.sol";
import {TokenVaultExchangeLogic} from "../libraries/logic/TokenVaultExchangeLogic.sol";
import {TokenVaultLogic} from "../libraries/logic/TokenVaultLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IGovernorUpgradeable} from "../libraries/openzeppelin/upgradeable/governance/IGovernorUpgradeable.sol";
import {IVotesUpgradeable} from "../libraries/openzeppelin/upgradeable/governance/extensions/GovernorVotesUpgradeable.sol";
import {IGovernor} from "../interfaces/IGovernor.sol";
import {IStaking} from "../interfaces/IStaking.sol";

contract TokenVault is
    SettingStorage,
    OwnableUpgradeable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    ERC721HolderUpgradeable,
    ERC1155HolderUpgradeable
{
    /// -----------------------------------
    /// -------- BASIC INFORMATION --------
    /// -----------------------------------

    /// @notice weth address
    IWETH public immutable weth;

    /// -----------------------------------
    /// -------- TOKEN INFORMATION --------
    /// -----------------------------------

    /// @notice the ERC721 token address of the vault's token
    //address public token;
    ///  @notice nftGovernor
    address public nftGovernor;
    /// @notice the ERC721 token ID of the vault's token
    // uint256 public id;

    address[] public listTokens;
    uint256[] public listIds;
    uint256 public listTokensLength;

    // for staking
    bool public stakingPoolEnabled;

    /// -------------------------------------
    /// -------- AUCTION INFORMATION --------
    /// -------------------------------------

    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;

    uint256 public fractionStart;

    /// @notice the length of auctions
    uint256 public exitLength;

    /// @notice exitPrice * votingTokens
    uint256 public exitTotal;
    /// @notice the current price of the token during an auction
    uint256 public livePrice;

    uint256 public bidHoldInETH;
    uint256 public bidHoldInToken;

    /// @notice the current user winning the token auction
    address public winning;

    DataTypes.State public auctionState;

    /// -----------------------------------
    /// -------- VAULT INFORMATION --------
    /// -----------------------------------

    /// @notice the address who initially deposited the NFT
    address public curator;

    /// @notice the number of ownership tokens voting on the exit price at any given time
    uint256 public votingTokens;

    /// @notice a mapping of users to their desired token price
    mapping(address => uint256) public userPrices;

    address public treasury;
    address public staking;
    address public government;
    address public exchange;
    address public bnft;

    /// @notice  gap for reserve, minus 1 if use
    uint256[10] public __gapUint256;
    /// @notice  gap for reserve, minus 1 if use
    uint256[5] public __gapAddress;

    /// ------------------------
    /// -------- EVENTS --------
    /// ------------------------

    /// @notice An event emitted when a user updates their price
    event PriceUpdate(address indexed user, uint256 price);

    /// @notice An event emitted when an auction starts
    event Start(address indexed buyer, uint256 price);

    /// @notice An event emitted when a bid is made
    event Bid(address indexed buyer, uint256 price);

    /// @notice An event emitted when an auction is won
    event Won(address indexed buyer, uint256 price);

    /// @notice An event emitted when someone redeems all tokens for the NFT
    event Redeem(address indexed redeemer);

    /// @notice An event emitted when someone cashes in ERC20 tokens for ETH from an ERC721 token sale
    event Cash(address indexed owner, uint256 shares);

    event StakingInitialized(address staking);

    event NftProposalExecuteWhenDefeated(
        uint256 proposalId,
        uint256 NftProposalId
    );

    constructor(address _settings) SettingStorage(_settings) {
        weth = IWETH(ISettings(settings).weth());
    }

    receive() external payable {}

    function initialize(DataTypes.TokenVaultInitializeParams memory params)
        external
        initializer
    {
        // initialize inherited contracts
        __ERC20_init(params.name, params.symbol);
        __Ownable_init();
        __ERC20Burnable_init();
        __ERC721Holder_init();
        __ERC1155Holder_init();
        // set storage variables
        require(params.listPrice > 0, "bad list price");
        require(
            params.listTokens.length == params.ids.length,
            "bad list length"
        );
        fractionStart = block.timestamp;
        listTokens = params.listTokens;
        listIds = params.ids;
        listTokensLength = params.listTokens.length;
        require(
            ISettings(settings).checkGovernorSetting(listTokens),
            "invalid input tokens"
        );
        (
            address _nftGovernorToken,
            address _nftGovernor,
            uint256 delayBlock,
            uint256 periodBlock
        ) = ISettings(settings).getGovernorSetting(listTokens);
        nftGovernor = _nftGovernor;
        exitLength = params.exitLength;
        curator = params.curator;
        auctionState = DataTypes.State.inactive;
        userPrices[curator] = params.listPrice;
        // validate treasury balance for governor
        if (nftGovernor != address(0)) {
            require(
                params.treasuryBalance >=
                    ((params.supply *
                        ISettings(settings).votingMinTokenPercent()) / 10000),
                Errors.VAULT_TREASURY_INVALID
            );
        }
        // update mint
        require(
            params.supply > 0 &&
                (params.supply * 50) / 100 >= params.treasuryBalance,
            Errors.VAULT_SUPPLY_INVALID
        ); //_treasuryBalance <= 50% _supply
        {
            exchange = TokenVaultExchangeLogic.newExchangeInstance(
                settings,
                address(this)
            );
            TokenVaultExchangeLogic.addRewardToken(exchange, address(this));
            TokenVaultExchangeLogic.addRewardToken(exchange, address(weth));
        }
        {
            _mint(curator, params.supply - params.treasuryBalance);

            treasury = TokenVaultTreasuryLogic.newTreasuryInstance(
                settings,
                address(this),
                exitLength
            );

            _mint(treasury, params.treasuryBalance);

            TokenVaultTreasuryLogic.addRewardToken(treasury, address(this));
            TokenVaultTreasuryLogic.addRewardToken(treasury, address(weth));
        }
        {
            staking = TokenVaultStakingLogic.newStakingInstance(
                settings,
                string(abi.encodePacked("ve", params.name)),
                string(abi.encodePacked("ve", params.symbol)),
                params.supply
            );
            TokenVaultStakingLogic.addRewardToken(staking, address(this));
            TokenVaultStakingLogic.addRewardToken(
                staking,
                ISettings(settings).weth()
            );
        }
        {
            government = TokenVaultGovernorLogic.newGovernorInstance(
                settings,
                address(this),
                staking,
                params.supply,
                delayBlock,
                periodBlock
            );
        }
        {
            bnft = TokenVaultLogic.newBnftInstance(
                settings,
                address(this),
                listTokens[0],
                listIds[0]
            );
        }
    }

    function initializeGovernorToken() external onlyOwner {
        if (nftGovernor != address(0)) {
            IVotesUpgradeable(listTokens[0]).delegate(address(this));
        }
        TokenVaultTreasuryLogic.initializeGovernorToken(treasury);
    }

    function _getSettings() public view returns (ISettings) {
        return ISettings(settings);
    }

    modifier onlyGovernor() {
        require(government == _msgSender(), Errors.VAULT_NOT_GOVERNOR);
        _;
    }

    function _getStaking() internal view returns (IStaking) {
        return IStaking(staking);
    }

    /// --------------------------------
    /// -------- VIEW FUNCTIONS --------
    /// --------------------------------

    function exitPrice() public view returns (uint256) {
        return votingTokens == 0 ? 0 : exitTotal / votingTokens;
    }

    function exitReducePrice() public view returns (uint256) {
        uint256 reducePrice = exitPrice();
        if (
            auctionState == DataTypes.State.inactive &&
            exitLength > 0 &&
            block.timestamp >= fractionStart + exitLength
        ) {
            uint256 reduceNum = (block.timestamp -
                (fractionStart + exitLength)) /
                ISettings(settings).auctionLength();
            for (uint256 idx = 0; idx < reduceNum; idx++) {
                reducePrice =
                    (reducePrice * (10000 - ISettings(settings).reduceStep())) /
                    10000;
            }
        }
        return reducePrice;
    }

    function exitTotalSupply() public view returns (uint256) {
        uint256 treasuryBalance = TokenVaultTreasuryLogic.getPoolBalanceToken(
            treasury,
            address(this)
        ) + TokenVaultTreasuryLogic.getBalanceVeToken(treasury);
        return totalSupply() - treasuryBalance;
    }

    /// --------------------------------
    /// -------- CORE FUNCTIONS --------
    /// --------------------------------

    /// @notice a function for an end user to update their desired sale price
    /// @param _new the desired price in ETH
    function updateUserPrice(uint256 _new) external {
        require(
            auctionState == DataTypes.State.inactive &&
                (exitLength == 0 ||
                    block.timestamp < fractionStart + exitLength),
            Errors.VAULT_STATE_INVALID
        );

        uint256 _exitPrice = exitPrice();
        uint256 old = userPrices[msg.sender];
        uint256 weight = balanceOf(msg.sender) +
            _getStaking().balanceOf(msg.sender);

        uint256 _votingTokens;
        uint256 _exitTotal;
        (_votingTokens, _exitTotal) = TokenVaultLogic.getUpdateUserPrice(
            DataTypes.VaultGetUpdateUserPrice({
                settings: settings,
                votingTokens: votingTokens,
                exitTotal: exitTotal,
                exitPrice: _exitPrice,
                newPrice: _new,
                oldPrice: old,
                weight: weight
            })
        );
        votingTokens = _votingTokens;
        exitTotal = _exitTotal;

        userPrices[msg.sender] = _new;

        emit PriceUpdate(msg.sender, _new);
    }

    /// @notice an internal function used to update sender and receivers price on token transfer
    /// @param _from the ERC20 token sender
    /// @param _to the ERC20 token receiver
    /// @param _amount the ERC20 token amount
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        if (
            auctionState == DataTypes.State.inactive &&
            (exitLength == 0 || block.timestamp < fractionStart + exitLength)
        ) {
            if (staking != address(0)) {
                uint256 changingBalance = _getStaking().changingBalance();
                // processing staking
                if (changingBalance > 0) {
                    // if user staking
                    if (_to == staking) {
                        return;
                    }
                    // if user unstaking
                    else if (_from == staking) {
                        require(
                            _amount >= changingBalance,
                            Errors.VAULT_CHANGING_BALANCE_INVALID
                        );
                        _amount = _amount - changingBalance;
                        if (_amount == 0) {
                            return;
                        }
                    }
                }
            }
            uint256 fromPrice = userPrices[_from];
            uint256 toPrice = userPrices[_to];
            uint256 _votingTokens;
            uint256 _exitTotal;
            (_votingTokens, _exitTotal) = TokenVaultLogic
                .getBeforeTokenTransferUserPrice(
                    DataTypes.VaultGetBeforeTokenTransferUserPriceParams({
                        votingTokens: votingTokens,
                        exitTotal: exitTotal,
                        fromPrice: fromPrice,
                        toPrice: toPrice,
                        amount: _amount
                    })
                );
            votingTokens = _votingTokens;
            exitTotal = _exitTotal;
        }
    }

    /// @notice kick off an auction. Must send exitPrice in ETH
    function start(uint256 bidPrice) external payable {
        uint256 reqValue = msg.value;
        (
            auctionEnd,
            auctionState,
            winning,
            bidHoldInETH,
            bidHoldInToken,
            livePrice
        ) = TokenVaultLogic.start(
            msg.sender,
            address(this),
            bidPrice,
            reqValue
        );
        _transfer(msg.sender, address(this), bidHoldInToken);
        emit Start(msg.sender, bidPrice);
    }

    /// @notice an external function to bid on purchasing the vaults NFT. The msg.value is the bid amount
    function bid(uint256 bidPrice) external payable {
        uint256 reqValue = msg.value;
        (
            auctionEnd,
            winning,
            bidHoldInETH,
            bidHoldInToken,
            livePrice
        ) = TokenVaultLogic.bid(msg.sender, address(this), bidPrice, reqValue);
        _transfer(msg.sender, address(this), bidHoldInToken);
        emit Bid(msg.sender, bidPrice);
    }

    /// @notice an external function to end an auction after the timer has run out
    function end() external {
        auctionState = TokenVaultLogic.end(address(this));
        // burn hold token
        if (bidHoldInToken > 0) {
            _burn(address(this), bidHoldInToken);
        }

        emit Won(winning, livePrice);
    }

    /// @notice an external function to burn all ERC20 tokens to receive the ERC721 token
    function redeem() external {
        auctionState = TokenVaultLogic.redeem(address(this), msg.sender);
        // burn all
        _burn(msg.sender, totalSupply());
        emit Redeem(msg.sender);
    }

    /// @notice an external function to burn ERC20 tokens to receive ETH from ERC721 token purchase
    function cash() external {
        require(
            auctionState == DataTypes.State.ended,
            Errors.VAULT_STATE_INVALID
        );
        uint256 bal = balanceOf(msg.sender);
        require(bal > 0, Errors.VAULT_BALANCE_INVALID);

        // share cash
        uint256 share = (bal * TransferHelper.balanceOfETH(address(this))) /
            totalSupply();
        _burn(msg.sender, bal);

        TransferHelper.safeTransferETHOrWETH(address(weth), msg.sender, share);

        emit Cash(msg.sender, share);
    }

    function stakingInitialize(uint256 _stakingLength) external onlyGovernor {
        require(
            auctionState == DataTypes.State.inactive,
            Errors.VAULT_STATE_INVALID
        );
        require(!stakingPoolEnabled, Errors.VAULT_STAKING_INVALID);
        require(
            exitLength > 0 || _stakingLength > 0,
            Errors.VAULT_STAKING_LENGTH_INVALID
        );
        // share reward
        TokenVaultTreasuryLogic.shareTreasuryRewardToken(treasury);
        // update treasury info
        TokenVaultTreasuryLogic.stakingInitialize(treasury, _stakingLength);
        // flag staking
        stakingPoolEnabled = true;
        // event
        emit StakingInitialized(staking);
    }

    // for internal

    function permitTransferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(msg.sender == staking, "not allow");
        _transfer(from, to, amount);
        return true;
    }

    //========================= NFT vote =============================
    function adminTargetCall(
        address target,
        bytes memory data,
        uint256 nonce,
        bytes memory signature
    ) external {
        address flashLoanAdmin = _getSettings().flashLoanAdmin();
        require(flashLoanAdmin != address(0), Errors.VAULT_INVALID_SIGNER);
        require(
            TokenVaultLogic.verifyTargetCallSignature(
                _msgSender(),
                address(this),
                target,
                data,
                nonce,
                flashLoanAdmin,
                signature
            ),
            Errors.VAULT_INVALID_SIGNER
        );
        TokenVaultLogic.proposalTargetCall(
            DataTypes.VaultProposalTargetCallParams({
                isAdmin: true,
                msgSender: _msgSender(),
                vaultToken: address(this),
                government: government,
                treasury: treasury,
                staking: staking,
                exchange: exchange,
                target: target,
                value: 0,
                data: data,
                nonce: nonce
            })
        );
        // check after call
        _checkAfterTargetCall();
    }

    function proposalTargetCall(
        address target,
        uint256 value,
        bytes memory data
    ) external onlyGovernor {
        if (data.length > 0) {
            TokenVaultLogic.proposalTargetCall(
                DataTypes.VaultProposalTargetCallParams({
                    isAdmin: false,
                    msgSender: _msgSender(),
                    vaultToken: address(this),
                    government: government,
                    treasury: treasury,
                    staking: staking,
                    exchange: exchange,
                    target: target,
                    value: value,
                    data: data,
                    nonce: 0
                })
            );
        } else {
            TokenVaultLogic.proposalETHTransfer(
                DataTypes.VaultProposalETHTransferParams({
                    msgSender: _msgSender(),
                    government: government,
                    recipient: target,
                    amount: value
                })
            );
        }
        // check after call
        _checkAfterTargetCall();
    }

    function _checkAfterTargetCall() public view virtual {
        for (uint i = 0; i < listTokens.length; i++) {
            require(
                IERC721(listTokens[i]).ownerOf(listIds[i]) == address(this),
                Errors.VAULT_AFTER_TARGET_CALL_FAILED
            );
        }
        require(
            TransferHelper.balanceOfETH(address(this)) >= bidHoldInETH,
            Errors.VAULT_AFTER_TARGET_CALL_FAILED
        );
    }

    function proposalExecuteWhenDefeated(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata calldatas,
        string memory description
    ) external returns (bool) {
        //check
        uint256 proposalId = IGovernorUpgradeable(government).hashProposal(
            targets,
            values,
            calldatas,
            keccak256(bytes(description))
        );
        require(
            IGovernor(government).isAgainstVote(proposalId),
            Errors.VAULT_PROPOSAL_NOT_AGAINST
        );
        for (uint256 i = 0; i < targets.length; ++i) {
            if (targets[i] == address(this)) {
                if (
                    TokenVaultGovernorLogic.validTargetCallFunction(
                        calldatas[i][:4]
                    )
                ) {
                    (
                        address originTarget,
                        ,
                        bytes memory originData
                    ) = TokenVaultGovernorLogic.decodeTargetCallParams(
                            calldatas[i]
                        );
                    (uint256 pId, ) = TokenVaultGovernorLogic
                        .decodeCastVoteData(originData);
                    if (pId > 0) {
                        require(
                            TokenVaultLogic.proposalTargetCallValid(
                                DataTypes.VaultProposalTargetCallValidParams({
                                    msgSender: _msgSender(),
                                    vaultToken: address(this),
                                    government: government,
                                    treasury: treasury,
                                    staking: staking,
                                    exchange: exchange,
                                    target: originTarget,
                                    data: originData
                                })
                            ),
                            Errors.VAULT_NOT_TARGET_CALL
                        );
                        IGovernorUpgradeable(originTarget).castVote(pId, 0);
                        emit NftProposalExecuteWhenDefeated(proposalId, pId);
                    }
                }
            }
        }
        return true;
    }

    //================== END Nouns vote =====================
}