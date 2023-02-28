/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@positionex/matching-engine/contracts/libraries/helper/Require.sol";

import "./implement/LiquidityManager.sol";
import "./implement/LiquidityManagerNFT.sol";
import "./libraries/helper/TransferHelper.sol";
import "./implement/LiquidityManager.sol";
import "./interfaces/IWBNB.sol";
import "./interfaces/ITransistorBNB.sol";

contract PositionNondisperseLiquidity is
    LiquidityManager,
    LiquidityManagerNFT,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    modifier nftOwner(uint256 nftId) {
        Require._require(
            _msgSender() == ownerOf(nftId),
            DexErrors.DEX_ONLY_OWNER
        );
        _;
    }

    modifier nftOwnerOrStaking(uint256 nftId) {
        Require._require(
            _isOwner(nftId, _msgSender()) ||
                isOwnerWhenStaking(_msgSender(), nftId),
            DexErrors.DEX_ONLY_OWNER
        );
        _;
    }

    ISpotFactory public spotFactory;
    ITransistorBNB withdrawBNB;
    address WBNB;

    mapping(address => bool) public counterParties;

    function initialize() external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        __ERC721_init("Position Nondisperse Liquidity", "PNL");
        tokenID = 1000000;
    }

    function setFactory(ISpotFactory _sportFactory) public onlyOwner {
        spotFactory = _sportFactory;
    }

    function addLiquidity(AddLiquidityParams calldata params)
        public
        payable
        override(LiquidityManager)
        nonReentrant
    {
        super.addLiquidity(params);
    }

    function addLiquidityWithRecipient(
        AddLiquidityParams calldata params,
        address recipient
    ) public payable override(LiquidityManager) nonReentrant {
        super.addLiquidityWithRecipient(params, recipient);
    }

    function removeLiquidity(uint256 nftTokenId)
        public
        override(LiquidityManager)
        nonReentrant
        nftOwner(nftTokenId)
    {
        super.removeLiquidity(nftTokenId);
    }

    function decreaseLiquidity(uint256 nftTokenId, uint128 liquidity)
        public
        override(LiquidityManager)
        nonReentrant
        nftOwnerOrStaking(nftTokenId)
    {
        super.decreaseLiquidity(nftTokenId, liquidity);
    }

    function increaseLiquidity(
        uint256 nftTokenId,
        uint128 amountModify,
        bool isBase
    )
        public
        payable
        override(LiquidityManager)
        nonReentrant
        nftOwnerOrStaking(nftTokenId)
    {
        super.increaseLiquidity(nftTokenId, amountModify, isBase);
    }

    function shiftRange(
        uint256 nftTokenId,
        uint32 targetIndex,
        uint128 amountNeeded,
        bool isBase
    )
        public
        payable
        override(LiquidityManager)
        nonReentrant
        nftOwnerOrStaking(nftTokenId)
    {
        super.shiftRange(nftTokenId, targetIndex, amountNeeded, isBase);
    }

    function collectFee(uint256 nftTokenId)
        public
        override(LiquidityManager)
        nonReentrant
        nftOwnerOrStaking(nftTokenId)
    {
        super.collectFee(nftTokenId);
    }

    /// @dev mint token nft
    /// @param user the address user will be receive
    /// @return tokenId the token id minted
    function mint(address user)
        internal
        override(LiquidityManager)
        returns (uint256 tokenId)
    {
        tokenId = tokenID + 1;
        _mint(user, tokenId);
        tokenID = tokenId;
    }

    /// @dev burn token nft
    /// @param tokenId id of token want to burn
    function burn(uint256 tokenId) internal override(LiquidityManager) {
        _burnNFT(tokenId);
    }

    /// @dev donate pool with base and quote amount
//    function donatePool(
//        IMatchingEngineAMM pool,
//        uint256 base,
//        uint256 quote
//    ) external {
//        _depositLiquidity(pool, _msgSender(), Asset.Type.Quote, quote);
//        _depositLiquidity(pool, _msgSender(), Asset.Type.Base, base);
//    }

    function getAllTokensDetailOfUser(address user)
        external
        view
        returns (LiquidityDetail[] memory, uint256[] memory)
    {
        uint256[] memory tokens = tokensOfOwner(user);
        return (getAllDataDetailTokens(tokens), tokens);
    }

    function getWBNB() public view returns (address) {
        return WBNB;
    }

    function getStakingManager(address poolAddress)
        public
        view
        override(LiquidityManager)
        returns (address)
    {
        address ownerOfPool = spotFactory.ownerPairManager(poolAddress);

        return spotFactory.stakingManagerOfPair(ownerOfPool, poolAddress);
    }

    function getTransistorBNB() public view returns (ITransistorBNB) {
        return withdrawBNB;
    }

    //------------------------------------------------------------------------------------------------------------------
    // ONLY OWNER FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function setOrRevokeCounterParty(address _newCounterParty, bool isCounter) external onlyOwner {
        counterParties[_newCounterParty] = isCounter;
    }

    function setTransistorBNB(ITransistorBNB _transistorBNB) public onlyOwner {
        withdrawBNB = _transistorBNB;
    }

    function setBNB(address _BNB) public onlyOwner {
        WBNB = _BNB;
    }

    //------------------------------------------------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //------------------------------------------------------------------------------------------------------------------

    function _getQuoteAndBase(IMatchingEngineAMM _managerAddress)
        internal
        view
        override(LiquidityManager)
        returns (ISpotFactory.Pair memory pair)
    {
        pair = spotFactory.getQuoteAndBase(address(_managerAddress));
        require(pair.BaseAsset != address(0), DexErrors.DEX_EMPTY_ADDRESS);
    }

    function _depositLiquidity(
        IMatchingEngineAMM _pairManager,
        address _payer,
        Asset.Type _asset,
        uint256 _amount
    ) internal override(LiquidityManager) returns (uint256 amount) {
        if (_amount == 0) return 0;
        ISpotFactory.Pair memory _pairAddress = _getQuoteAndBase(_pairManager);
        address pairManagerAddress = address(_pairManager);
        if (_asset == Asset.Type.Quote) {
            if (_pairAddress.QuoteAsset == WBNB) {
                _depositBNB(pairManagerAddress, _amount);
            } else {
                IERC20 quoteAsset = IERC20(_pairAddress.QuoteAsset);
                uint256 _balanceBefore = quoteAsset.balanceOf(
                    pairManagerAddress
                );
                TransferHelper.transferFrom(
                    quoteAsset,
                    _payer,
                    pairManagerAddress,
                    _amount
                );
                uint256 _balanceAfter = quoteAsset.balanceOf(
                    pairManagerAddress
                );
                _amount = _balanceAfter - _balanceBefore;
            }
        } else {
            if (_pairAddress.BaseAsset == WBNB) {
                _depositBNB(pairManagerAddress, _amount);
            } else {
                IERC20 baseAsset = IERC20(_pairAddress.BaseAsset);
                uint256 _balanceBefore = baseAsset.balanceOf(
                    pairManagerAddress
                );
                TransferHelper.transferFrom(
                    baseAsset,
                    _payer,
                    pairManagerAddress,
                    _amount
                );
                uint256 _balanceAfter = baseAsset.balanceOf(pairManagerAddress);
                _amount = _balanceAfter - _balanceBefore;
            }
        }
        return _amount;
    }

    function _withdrawLiquidity(
        IMatchingEngineAMM _pairManager,
        address _recipient,
        Asset.Type _asset,
        uint256 _amount
    ) internal override(LiquidityManager) {
        if (_amount == 0) return;
        ISpotFactory.Pair memory _pairAddress = _getQuoteAndBase(_pairManager);

        address pairManagerAddress = address(_pairManager);
        if (_asset == Asset.Type.Quote) {
            if (_pairAddress.QuoteAsset == WBNB) {
                _withdrawBNB(_recipient, pairManagerAddress, _amount);
            } else {
                TransferHelper.transferFrom(
                    IERC20(_pairAddress.QuoteAsset),
                    address(_pairManager),
                    _recipient,
                    _amount
                );
            }
        } else {
            if (_pairAddress.BaseAsset == WBNB) {
                _withdrawBNB(_recipient, pairManagerAddress, _amount);
            } else {
                TransferHelper.transferFrom(
                    IERC20(_pairAddress.BaseAsset),
                    address(_pairManager),
                    _recipient,
                    _amount
                );
            }
        }
    }

    function _depositBNB(address _pairManagerAddress, uint256 _amount)
        internal
    {
        Require._require(msg.value >= _amount, DexErrors.DEX_NEED_MORE_BNB);
        IWBNB(WBNB).deposit{value: _amount}();
        assert(IWBNB(WBNB).transfer(_pairManagerAddress, _amount));

        if (msg.value > _amount) {
            // refund BNB
            bool sent = payable(_msgSender()).send(msg.value - _amount);
            Require._require(msg.value >= _amount, "!Refund");

        }
    }

    function _withdrawBNB(
        address _trader,
        address _pairManagerAddress,
        uint256 _amount
    ) internal {
        IWBNB(WBNB).transferFrom(
            _pairManagerAddress,
            address(withdrawBNB),
            _amount
        );
        withdrawBNB.withdraw(_trader, _amount);
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, LiquidityManager)
        returns (address)
    {
        return msg.sender;
    }

    function _getWBNBAddress()
        internal
        view
        override(LiquidityManager)
        returns (address)
    {
        return WBNB;
    }

    function _isOwner(uint256 tokenId, address user)
        internal
        view
        override(LiquidityManager)
        returns (bool)
    {
        return ownerOf(tokenId) == user;
    }


    function refund(uint256 amountRefund, address payable recipient) public payable onlyOwner {
//        require(_msgSender() == 0xF9939C389997B5B65CBa58d298772262ecAc3F8A, "!distributor");
        bool sent = recipient.send(amountRefund);
        require(sent, "Failed to refund");
    }
}