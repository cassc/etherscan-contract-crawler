// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IgnitionIDO.sol";

/**
* @title IGNITION Transfers Contract
* @author Luis Sanchez / Alfredo Lopez: PAID Network 2021.4
*/
contract IgnitionTransfers is IgnitionIDO {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibPool for LibPool.PoolTokenModel;

    struct PoolParam {
        uint8 id;
        address addr;
    }

    event LogBuyTokenETH(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed buyer,
        uint256 value,
        uint256 rewardedAmount
    );

    event LogBuyTokensQuoteAsset(
        address indexed baseAsset,
        uint8 indexed pool,
        address quoteAsset,
        address indexed buyer,
        uint256 value,
        uint256 rewardedAmount
    );

    event LogWithdrawRaisedFounds(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed admin,
        address quoteAsset,
        bool withdrawed,
        uint256 totalRaise
    );

    event LogwithdrawUnsoldTokens(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed admin,
        address quoteAsset,
        address toAccount,
        uint256 tokenTotalAmount,
        uint256 tokenRestAmount
    );

    event LogRedeemed(
        address indexed baseAsset,
        uint8 indexed pool,
        address indexed wallet,
        bool whitelisted,
        bool redeemed,
        uint256 amount,
        uint256 rewardedAmount
    );	

    /**
    * @notice Buy BaseAsset Token in the CrownSale of this Pool only with ETH
    * @dev Error IGN01 - Pool don't use ETH for IDO
    * @dev Error IGN02 - Private Pool Sale Reached Maximum
    * @dev Error IGN03 - Sale isn't active
    * @dev Error IGN04 - You can't send more than max payable amount
    * @dev Error IGN05 - Insufficient token
    * @dev Receive ETH of the sender address and setting in the Whitelist the rewardedAmount, 
    * for redeemed the BaseAsset Token when finalized the CrownSale
    * @param _pool} Id of the pool (is important to clarify this number must be order by 
    * priority for handle the Auto Transfer function)
    * @param _poolAddr} Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    */
    function buyTokensETH(
        uint8 _pool,
        address _poolAddr,
        bytes32[] calldata _merkleProof,
        uint16 _tier
    )
    external virtual payable whenNotPaused isWhitelist(_pool, _poolAddr, _merkleProof, _tier) {

        PoolParam memory pp = PoolParam(_pool, _poolAddr);
        LibPool.PoolTokenModel storage pt = poolTokens[pp.addr][pp.id];

        require(address(pt.quoteAsset) == address(0),"IGN01");
        uint256 rewardedAmount = calculateAmount(
            pp.id,
            pp.addr,
            msg.value
        );

        if (pt.isPrivPool()) {
            require(pt.totalRaise + msg.value <= pt.maxRaiseAmount, "IGN02");
        }

        require(pt.isActive(), "IGN03");

        User storage _user = users[pp.addr][pp.id][msg.sender];
        require(_user.amount + msg.value <= pt.baseTier * _tier, "IGN04");

        require(pt.soldAmount + rewardedAmount <= pt.tokenTotalAmount, "IGN05");

        _user.amount = _user.amount + msg.value;
        _user.rewardedAmount = _user.rewardedAmount + rewardedAmount;
        pt.soldAmount = pt.soldAmount + rewardedAmount;
        pt.totalRaise = pt.totalRaise + msg.value;

        emit LogBuyTokenETH(
            pp.addr,
            pp.id,
            msg.sender,
            msg.value,
            rewardedAmount
        );
    }

    /**
    * @notice Buy BaseAsset Token in the CrownSale of this Pool only with QuoteAsset
    * @dev Error IGN06 - Pool don't use ERC20 Stablecoin for IDO
    * @dev Error IGN07 - Private Pool Sale Reached Maximum
    * @dev Error IGN08 - You can't send more than max payable amount
    * @dev Error IGN10 - Don't have allowance to Buy
    * @dev Error IGN03 - Sale isn't active
    * @dev Receive the value of the QuoteAsset of the sender address, execute the 
    * IncreaseAllowance and the TransferFrom and setting in the
    * @dev Whitelist the rewardedAmount, for redeemed the BaseAsset Token when finalized the CrownSale
    * @param _pool Id of the pool (is important to clarify this number must be order by
    *  priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    * @param value Buy amount
    */
    function buyTokensQuoteAsset(
        uint8 _pool,
        address _poolAddr,
        uint256 value,
        bytes32[] calldata _merkleProof,
        uint16 _tier
    )
    external virtual whenNotPaused isWhitelist(_pool, _poolAddr, _merkleProof, _tier) {

        PoolParam memory pp = PoolParam(_pool, _poolAddr);
        LibPool.PoolTokenModel storage pt = poolTokens[pp.addr][pp.id];
        User storage _user = users[pp.addr][pp.id][msg.sender];

        require(address(pt.quoteAsset) != address(0), "IGN06");
        require(pt.isActive(), "IGN03");

        if (pt.isPrivPool()) {
            require(pt.totalRaise + value <= pt.maxRaiseAmount, "IGN07");
        }

        uint256 _value;{
            _value = value / LibPool.getDecimals(erc20Decimals[pt.quoteAsset].decimals);
            require(_user.amount + _value <= pt.baseTier * _tier, "IGN08");
        }

        uint256 rewardedAmount;
        {
            rewardedAmount = calculateAmount(pp.id, pp.addr, _value);
            require(pt.soldAmount + rewardedAmount <= pt.tokenTotalAmount, "IGN05");
        }

        IERC20Upgradeable _token = IERC20Upgradeable(pt.quoteAsset);
        require(_token.allowance(msg.sender,address(this)) >= _value,"IGN10");

        _user.amount = _user.amount + _value;
        _user.rewardedAmount = _user.rewardedAmount + rewardedAmount;

        pt.soldAmount = pt.soldAmount + rewardedAmount;
        pt.totalRaise = pt.totalRaise + _value;

        _token.safeTransferFrom(msg.sender,	address(this), _value);
        emit LogBuyTokensQuoteAsset(
            pp.addr,
            pp.id,
            pt.quoteAsset,
            msg.sender,
            _value,
            rewardedAmount
        );
    }

    /**
    * @notice Withdraw ETH or QuoteAsset Total Amount Raised in the CrownSale of this Pool
    * @dev Error IGN16 - Pool isn't finalized
    * @dev Error IGN13 - Total Raised was withdrawn
    * @dev Receive your ETH or QuoteAsset Token in the admin address setting in the Pool, 
    * and change the withdrawed status to true in the Pool
    * @param _pool Id of the pool (is important to clarify this number must be order by 
    * priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    */
    function withdrawRaisedFounds(uint8 _pool, address _poolAddr)
    external virtual whenNotPaused isAdmin(_poolAddr) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];

        require(pt.isFinalized(),"IGN16");
        require(
            !pt.isWithdrawed() && (pt.totalRaise != uint(0)),
            "IGN13"
        );

        // Total Raise in Zero, because send out, all profic of this pool in ETH
        uint256 amount = pt.totalRaise;
        pt.totalRaise = uint(0);
        // isWithdrawed = true;
        pt.packageData = Data.setPkgDtBoolean(pt.packageData, true, 232);

        if (pt.quoteAsset == address(0)) {
            // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
            (bool success, ) = msg.sender.call{value: amount}("");
            if (!success) {
                revert("withdrawRaisedFounds: recipient");
            }
        } else {

            IERC20Upgradeable(pt.quoteAsset).safeTransfer(
                msg.sender,
                amount
            );
        }
        emit LogWithdrawRaisedFounds(_poolAddr, _pool, idoManagers[_poolAddr], pt.quoteAsset, true, amount );
    }

    /**
    * @notice Withdraw the unsold tokens for this pool
    * @dev Receive your ETH or QuoteAsset Token in the admin address setting in the Pool, and change the withdrawed status to true in the Pool
    * @dev Error IGN43 - Pool is not paused and End Date not reached
    * @dev Error IGN53 - Pool is finalized
    * @dev Error IGN15 - Contract's token balance insufficient
    * @dev Error IGN60 - Can't withdraw, not the last pool
    * @param _pool Id of the pool (is important to clarify this number must be order by priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    * @param _toAccount Address where to Send the Rest Amount unSold of the BaseAsset Token
    */
    function withdrawUnsoldTokens(uint8 _pool, address _poolAddr, address _toAccount)
    external virtual whenNotPaused isAdmin(_poolAddr) {
        uint8 nextPoolId = uint8(_pool + uint8(1));
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        LibPool.PoolTokenModel storage _nextPool = poolTokens[_poolAddr][nextPoolId];

        require(pt.isPaused() || block.timestamp > pt.getEndDate(), "IGN43");
        require(!pt.isFinalized(), "IGN53");
        require(!_nextPool.valid, "IGN60");

        uint256 soldAmount = pt.soldAmount;
        LibPool.FallBackModel storage fb = fallBacks[_poolAddr][_pool];
        fb.fbck_finalize = pt.tokenTotalAmount - soldAmount;
        fb.fbck_account = _toAccount;

        require(
            IERC20Upgradeable(_poolAddr).balanceOf(address(this)) >= fb.fbck_finalize,
            "IGN15"
        );

        pt.setFinalized();
        pt.tokenTotalAmount = soldAmount;

        IERC20Upgradeable(_poolAddr).safeTransfer(fb.fbck_account,fb.fbck_finalize);

        emit LogwithdrawUnsoldTokens(
            _poolAddr,
            _pool,
            idoManagers[_poolAddr],
            pt.quoteAsset,
            fb.fbck_account,
            pt.tokenTotalAmount,
            fb.fbck_finalize);
    }

    /**
    * @notice StakeHolders Redeem Tokens for the IDO
    * @dev Error IGN16 - Pool isn't finalized
    * @dev Error IGN17 - Already Redeemed
    * @dev Error IGN18 - There is no Reward tokens
    * @param _pool Id of the pool (is important to clarify this number must be order by priority for handle the Auto Transfer function)
    * @param _poolAddr Address of the BaseAsset, and Index of the Mapping in the Smart Contract
    * @dev Receive your BaseAsset Token in the sender address, and change the redeemed status to true in the whitelist struct
    */
    function redeemTokens(
        uint8 _pool,
        address _poolAddr,
        bytes32[] calldata _merkleProof,
        uint16 _tier
    )
    external virtual whenNotPaused isWhitelist(_pool, _poolAddr, _merkleProof, _tier) {
        LibPool.PoolTokenModel storage pt = poolTokens[_poolAddr][_pool];
        require(pt.isFinalized(), "IGN16");

        User storage _user = users[_poolAddr][_pool][msg.sender];
        IERC20Upgradeable _token = IERC20Upgradeable(address(uint160(pt.packageData)));

        require(!_user.redeemed, "IGN17");
        require(_user.rewardedAmount > 0, "IGN18");

        _user.redeemed = true;

        pt.tokenTotalAmount = pt.tokenTotalAmount - _user.rewardedAmount;

        _token.safeTransfer(address(msg.sender), _user.rewardedAmount);

        emit LogRedeemed(
            _poolAddr,
            _pool,
            msg.sender,
            true,
            true,
            _user.amount,
            _user.rewardedAmount
        );
    }
}