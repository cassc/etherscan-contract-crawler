// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./WittyPixelsLib.sol";
import "./interfaces/IWittyPixelsToken.sol";
import "./interfaces/IWittyPixelsTokenVault.sol";
import "./patterns/WittyPixelsClonableBase.sol";

/// @title  WittyPixels NFT - ERC20 token vault contract
/// @author Otherplane Labs Ltd., 2022
/// @dev    This contract needs to be cloned and initialized.
contract WittyPixelsTokenVault
    is
        ERC20Upgradeable,
        IWittyPixelsTokenVault,
        WittyPixelsClonableBase
{
    using ERC165Checker for address;

    modifier notAcquiredYet {
        require(
            !acquired(),
            "WittyPixelsTokenVault: already acquired"
        );
        _;
    }

    modifier onlyCurator {
        require(
            msg.sender == __wpx20().curator,
            "WittyPixelsTokenVault: not the curator"
        );
        _;
    }

    receive() external payable {}

    function setCurator(address newCurator)
        external
        onlyCurator
    {
        assert(newCurator != address(0));
        __wpx20().curator = newCurator;
    }

    function version()
        virtual override
        external view
        returns (string memory)
    {
        return WittyPixelsClonableBase(address(__wpx20().parentToken)).version();
    }


    // ================================================================================================================
    // --- Overrides IERC20Upgradeable interface ----------------------------------------------------------------------

    /// @notice Increment `__wpx20().stats.totalTransfers` every time an ERC20 transfer is confirmed.
    /// @dev Hook that is called after any transfer of tokens. This includes minting and burning.
    /// Calling conditions:
    /// - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens has been transferred to `to`.
    /// - when `from` is zero, `amount` tokens have been minted for `to`.
    /// - when `to` is zero, `amount` of ``from``'s tokens have been burned.
    /// - `from` and `to` are never both zero.
    function _afterTokenTransfer(
            address _from,
            address _to,
            uint256
        )
        internal
        virtual override
    {
        if (
            _from != address(0)
                && _to != address(0)
        ) {
            __wpx20().stats.totalTransfers ++;
        }
    }


    // ================================================================================================================
    // --- Overrides IERC165 interface --------------------------------------------------------------------------------

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 _interfaceId)
      public view
      virtual override
      returns (bool)
    {
        return _interfaceId == type(IERC165).interfaceId
            || _interfaceId == type(IWittyPixelsTokenVault).interfaceId
            || _interfaceId == type(ITokenVault).interfaceId
            || _interfaceId == type(IERC1633).interfaceId
            || _interfaceId == type(IERC20Upgradeable).interfaceId
            || _interfaceId == type(IERC20MetadataUpgradeable).interfaceId
            || _interfaceId == type(Clonable).interfaceId
        ;
    }


    // ================================================================================================================
    // --- Implements 'IERC1633' --------------------------------------------------------------------------------------

    function parentToken()
        override
        external view
        returns (address)
    {
        return __wpx20().parentToken;
    }

    function parentTokenId()
        override
        external view
        returns(uint256)
    {
        return __wpx20().parentTokenId;
    }


    // ================================================================================================================
    // --- Implements 'ITokenVault' -----------------------------------------------------------------------------------

    /// @notice Address of the previous owner, the one that decided to fractionalized the NFT.
    function curator()
        override
        external view
        wasInitialized
        returns (address)
    {
        return __wpx20().curator;
    }

    /// @notice Mint ERC-20 tokens, ergo token ownership, by providing ownership deeds.
    function redeem(bytes calldata _deedsdata)
        virtual override
        public
        wasInitialized
        nonReentrant
    {
        // deserialize deeds data:
        WittyPixels.TokenVaultOwnershipDeeds memory _deeds = abi.decode(
            _deedsdata,
            (WittyPixels.TokenVaultOwnershipDeeds)
        );

        // check intrinsicals:
        require(
            _deeds.parentToken == __wpx20().parentToken
                && _deeds.parentTokenId == __wpx20().parentTokenId
            , "WittyPixelsTokenVault: bad token"
        );
        require(
            _deeds.playerAddress != address(0),
            "WittyPixelsTokenVault: null address"
        );
        require(
            __wpx20().players[_deeds.playerIndex].addr == address(0),
            "WittyPixelsTokenVault: already redeemed"
        );
        require(
            __wpx20().stats.redeemedPixels + _deeds.playerPixels <= __wpx20().stats.totalPixels,
            "WittyPixelsTokenVault: overbooking :/"
        );

        // verify player's pixels proof:
        require(
            IWittyPixelsToken(_deeds.parentToken).verifyTokenAuthorship(
                _deeds.parentTokenId,
                _deeds.playerIndex,
                _deeds.playerPixels,
                _deeds.playerPixelsProof
            ),
            "WittyPixelsTokenVault: false deeds"
        );
        
        // verify curator's signature:
        bytes32 _deedshash = keccak256(abi.encode(
            _deeds.parentToken,
            _deeds.parentTokenId,
            _deeds.playerAddress,
            _deeds.playerIndex,
            _deeds.playerPixels,
            _deeds.playerPixelsProof
        ));
        require(
            WittyPixelsLib.recoverAddr(_deedshash, _deeds.signature) == __wpx20().curator,
            "WittyPixelsTokenVault: bad signature"
        );

        // store player's info:
        uint _currentPixels = __wpx20().legacyPixels[_deeds.playerAddress];
        if (
            _currentPixels == 0
                && !__wpx20().redeemed[_deeds.playerAddress]
        ) {
            // upon first redemption from playerAddress, add it to the author's list
            __wpx20().authors.push(_deeds.playerAddress);
            __wpx20().redeemed[_deeds.playerAddress] = true;
        }
        if (_deeds.playerPixels > 0) {
            __wpx20().legacyPixels[_deeds.playerAddress] = _currentPixels + _deeds.playerPixels;    
        }
        __wpx20().players[_deeds.playerIndex] = WittyPixels.TokenVaultPlayerInfo({
            addr: _deeds.playerAddress,
            pixels: _deeds.playerPixels
        });

        // update stats meters:
        __wpx20().stats.redeemedPixels += _deeds.playerPixels;
        __wpx20().stats.redeemedPlayers ++;

        // transfer sovereign tokens to player's verified address:
        _transfer(
            address(this),
            _deeds.playerAddress,
            _deeds.playerPixels * 10 ** 18
        );

        // emit wpx721 token's EIP-4906 MetadataUpdate event
        IWittyPixelsToken(__wpx20().parentToken).updateMetadataFromTokenVault(__wpx20().parentTokenId);
    }

    /// @notice Returns whether this NFT vault has already been acquired. 
    function acquired()
        override
        public view
        wasInitialized
        returns (bool)
    {
        return IERC721(__wpx20().parentToken).ownerOf(__wpx20().parentTokenId) != address(this);
    }

    /// @notice Withdraw paid value in proportion to number of shares.
    /// @dev Fails if not yet acquired. 
    function withdraw()
        virtual override
        public
        wasInitialized
        nonReentrant
        returns (uint256 _withdrawn)
    {
        // check the nft token has indeed been acquired:
        require(
            acquired(),
            "WittyPixelsTokenVault: not acquired yet"
        );
        
        // check caller's erc20 balance is greater than zero:
        uint _erc20balance = balanceOf(msg.sender);
        require(
            _erc20balance > 0,
            "WittyPixelsTokenVault: no balance"
        );
        
        // check vault contract has enough funds for the cash out:
        WittyPixels.TokenVaultCharity storage __charity = __wpx20().charity;
        _withdrawn = (
            (100 - __charity.percentage) * __wpx20().finalPrice * _erc20balance
        ) / (
            100 * __wpx20().stats.totalPixels * 10 ** 18
        );
        require(
            address(this).balance >= _withdrawn,
            "WittyPixelsTokenVault: insufficient funds :/"
        );
        
        // burn erc20 tokens before cashing out !!
        _burn(msg.sender, _erc20balance);
        
        // cash out to the wpx20 owner:
        payable(msg.sender).transfer(_withdrawn);
        emit Withdrawal(msg.sender, _withdrawn);

        // update stats meters:
        __wpx20().stats.totalWithdrawals ++;
    }

    /// @notice Tells withdrawable amount in weis from the given address.
    /// @dev Returns 0 in all cases while not yet acquired. 
    function withdrawableFrom(address _from)
        virtual override
        public view
        wasInitialized
        returns (uint256)
    {
        if (acquired()) {
            return (
                __wpx20().finalPrice * balanceOf(_from) * (100 - __wpx20().charity.percentage)
            ) / (
                100 * __wpx20().stats.totalPixels * 10 ** 18
            );
        } else {
            return 0;
        }
    }


    // ================================================================================================================
    // --- Implements ITokenVaultWitnet -------------------------------------------------------------------------------

    function cloneAndInitialize(bytes memory _initdata)
        virtual override
        external
        returns (ITokenVaultWitnet)
    {
        return __afterCloning(_clone(), _initdata);
    }

    function cloneDeterministicAndInitialize(bytes32 _salt, bytes memory _initdata)
        virtual override
        external
        returns (ITokenVaultWitnet)
    {
        return __afterCloning(_cloneDeterministic(_salt), _initdata);
    }


    // ================================================================================================================
    // --- Implements 'IWittyPixelsTokenVault' ------------------------------------------------------------------------
    
    /// @notice Returns number of legitimate players that have redeemed authorhsip of at least one pixel from the NFT token.
    function getAuthorsCount()
        virtual override
        external view
        wasInitialized
        returns (uint256)
    {
        return __wpx20().authors.length;
    }

    /// @notice Returns range of authors's address and legacy pixels, as specified by `offset` and `count` params.
    function getAuthorsRange(uint offset, uint count)
        virtual override
        external view
        wasInitialized
        returns (address[] memory addrs, uint256[] memory pixels)
    {
        uint _total = __wpx20().authors.length;
        if (offset < _total) {
            if (offset + count > _total) {
                count = _total - offset;
            }
            addrs = new address[](count);
            pixels = new uint256[](count);
            for (uint _i = 0; _i < count; _i ++) {
                addrs[_i] = __wpx20().authors[_i + offset];
                pixels[_i] = __wpx20().legacyPixels[addrs[_i]];
            }
        }
    }

    /// @notice Returns status data about the token vault contract, relevant from an UI/UX perspective
    /// @return status Enum value representing current contract status: Awaiting, Randomizing, Auctioning, Sold
    /// @return stats Set of meters reflecting number of pixels, players, ERC20 transfers and withdrawls, up to date. 
    /// @return currentPrice Price in ETH/wei at which the whole NFT ownership can be bought, or at which it was actually sold.
    /// @return nextPriceTs The approximate timestamp at which the currentPrice may change. Zero, if it's not expected to ever change again.
    function getInfo()
        override
        external view
        wasInitialized
        returns (
            Status status,
            Stats memory stats,
            uint256 currentPrice,
            uint256 nextPriceTs
        )
    {
        if (acquired()) {
            status = IWittyPixelsTokenVault.Status.Acquired;
        } else if (auctioning()) {
            status = IWittyPixelsTokenVault.Status.Auctioning;
        } else {
            status = IWittyPixelsTokenVault.Status.Awaiting;
        }
        stats = __wpx20().stats;
        currentPrice = getPrice();
        nextPriceTs = getNextPriceTimestamp();
    }

    /// @notice Returns Charity information related to this token vault contract.
    /// @return wallet The Charity EVM address where donations will be transferred to.
    /// @return percentage Percentage of the final price that will be eventually donated to the Charity wallet.
    /// @return ethSoFarDonated Cumuled amount of ETH that has been so far donated to the Charity wallet.
    function getCharityInfo()
        virtual override
        external view
        wasInitialized
        returns (
            address wallet,
            uint8   percentage,
            uint256 ethSoFarDonated
        )
    {
        WittyPixels.TokenVaultCharity storage __charity = __wpx20().charity;
        return (
            __charity.wallet,
            __charity.percentage,
            __wpx20().stats.ethSoFarDonated
        );
    }

    /// @notice Gets info regarding a formerly verified player, given its index. 
    /// @return Address from which the token's ownership was redeemed. Zero if this player hasn't redeemed ownership yet.
    /// @return Number of pixels formerly redemeed by given player. 
    function getPlayerInfo(uint256 index)
        virtual override
        external view
        wasInitialized
        returns (address, uint256)
    {
        WittyPixels.TokenVaultPlayerInfo storage __info = __wpx20().players[index];
        return (
            __info.addr,
            __info.pixels
        );
    }

    /// @notice Returns set of meters reflecting number of pixels, players, ERC20 transfers, withdrawals, 
    /// @notice and totally donated funds up to now.
    function getStats()
        virtual override
        external view
        wasInitialized 
        returns (Stats memory stats)
    {
        return __wpx20().stats;
    }

    /// @notice Gets accounting info regarding given address.
    /// @return wpxBalance Current ERC20 balance.
    /// @return wpxShare10000 NFT ownership percentage based on current ERC20 balance, multiplied by 100.
    /// @return ethWithdrawable ETH/wei amount that can be potentially withdrawn from this address.
    /// @return soulboundPixels Soulbound pixels contributed from this wallet address, if any.    
    function getWalletInfo(address _addr)
        virtual override
        external view
        wasInitialized
        returns (
            uint256 wpxBalance,
            uint256 wpxShare10000,
            uint256 ethWithdrawable,
            uint256 soulboundPixels
        )
    {
        return (
            balanceOf(_addr),
            (10 ** 4 * balanceOf(_addr)) / (__wpx20().stats.totalPixels * 10 ** 18),
            withdrawableFrom(_addr),
            pixelsOf(_addr)
        );
    }

    /// @notice Returns sum of legacy pixels ever redeemed from the given address.
    /// The moral right over a player's finalized pixels is inalienable, so the value returned by this method
    /// will be preserved even though the player transfers ERC20/WPX tokens to other accounts, or if she decides to cash out 
    /// her share if the parent NFT token ever gets acquired. 
    function pixelsOf(address _wallet)
        virtual override
        public view
        wasInitialized
        returns (uint256)
    {
        return __wpx20().legacyPixels[_wallet];
    }    

    /// @notice Returns total number of finalized pixels within the WittyPixelsLib canvas.
    function totalPixels()
        virtual override
        external view
        wasInitialized
        returns (uint256)
    {
        return __wpx20().stats.totalPixels;
    }

    
    // ================================================================================================================
    // --- Implements 'ITokenVaultAuctionDutch' ------------------------------------------------------------

    function acquire()
        override
        external payable
        wasInitialized
        nonReentrant
        notAcquiredYet
    {
        // verify provided value is greater or equal to current price:
        uint256 _finalPrice = getPrice();
        require(
            msg.value >= _finalPrice,
            "WittyPixelsTokenVault: insufficient value"
        );

        // safely transfer parent token id ownership to the bidder:
        IERC721(__wpx20().parentToken).safeTransferFrom(
            address(this),
            msg.sender,
            __wpx20().parentTokenId
        );

        // store final price:
        __wpx20().finalPrice = _finalPrice;

        WittyPixels.TokenVaultCharity storage __charity = __wpx20().charity;
        if (__charity.wallet != address(0)) {
            // transfer charitable donation, if any:
            uint _donation = (__charity.percentage * _finalPrice) / 100;
            payable(__charity.wallet).transfer(_donation);
            __wpx20().stats.ethSoFarDonated = _donation;
            emit Donation(msg.sender, __charity.wallet, _donation);
        }
        
        // transfer back unused funds if `msg.value` was higher than current price:
        if (msg.value > _finalPrice) {
            payable(msg.sender).transfer(msg.value - _finalPrice);
        }

        // emit wpx721 token's EIP-4906 MetadataUpdate event
        IWittyPixelsToken(__wpx20().parentToken).updateMetadataFromTokenVault(
            __wpx20().parentTokenId
        );
    }

    function auctioning()
        virtual override
        public view
        wasInitialized
        returns (bool)
    {
        uint _startingTs = __wpx20().settings.startingTs;
        return (
            _startingTs != 0
                && block.timestamp >= _startingTs
                && !acquired()
        );
    }

    function getAuctionSettings()
        override
        external view
        wasInitialized
        returns (bytes memory)
    {
        return abi.encode(__wpx20().settings);
    }

    function getAuctionType()
        override
        external pure
        returns (bytes4)
    {
        return type(ITokenVaultAuctionDutch).interfaceId;
    }

    function setAuctionSettings(bytes memory _settings)
        override
        external
        onlyCurator
        notAcquiredYet
    {
        __setAuctionSettings(_settings);
    }

    function getPrice()
        virtual override
        public view
        wasInitialized
        returns (uint256)
    {
        ITokenVaultAuctionDutch.Settings memory _settings = __wpx20().settings;
        if (block.timestamp >= _settings.startingTs) {
            if (__wpx20().finalPrice == 0) {
                uint _tsDiff = block.timestamp - _settings.startingTs;
                uint _priceRange = _settings.startingPrice - _settings.reservePrice;
                uint _round = _tsDiff / _settings.deltaSeconds;
                if (_round * _settings.deltaPrice <= _priceRange) {
                    return _settings.startingPrice - _round * _settings.deltaPrice;
                } else {
                    return _settings.reservePrice;
                }
            } else {
                return __wpx20().finalPrice;
            }
        } else {
            return _settings.startingPrice;
        }
    }


    // ================================================================================================================
    // --- Implements 'ITokenVaultAuctionDutch' ------------------------------------------------------------

    function getNextPriceTimestamp()
        override
        public view
        wasInitialized
        returns (uint256)
    {
        ITokenVaultAuctionDutch.Settings memory _settings = __wpx20().settings;
        if (
            acquired()
                || getPrice() == _settings.reservePrice
        ) {
            return 0;
        }
        else if (block.timestamp >= _settings.startingTs) {
            uint _tsDiff = block.timestamp - _settings.startingTs;
            uint _round = _tsDiff / _settings.deltaSeconds;
            return (
                _settings.startingTs
                    + _settings.deltaSeconds * (_round + 1)
            );
        }
        else {
            return _settings.startingTs;
        }
    }    


    // ================================================================================================================
    // --- Overrides 'Clonable' ---------------------------------------------------------------------------------------

    function initialized()
        override
        public view
        returns (bool)
    {
        return __wpx20().curator != address(0);
    }

    /// Initialize storage-context when invoked as delegatecall. 
    /// @dev Must fail when trying to initialize same instance more than once.
    function __initialize(bytes memory _initBytes) 
        virtual override
        internal
    {   
        super.__initialize(_initBytes);

        // decode and validate initialization parameters:
        WittyPixels.TokenVaultInitParams memory _params = abi.decode(
            _initBytes,
            (WittyPixels.TokenVaultInitParams)
        );
        require(
            _params.curator != address(0),
            "WittyPixelsTokenVault: no curator"
        );
        require(
            _params.token.supportsInterface(type(IWittyPixelsToken).interfaceId),
            "WittyPixelsTokenVault: uncompliant vault factory"
        );
        require(
            _params.tokenPixels > 0,
            "WittyPixelsTokenVault: no pixels"
        );

        // initialize openzeppelin's ERC20Upgradeable implementation
        __ERC20_init(_params.name, _params.symbol);

        // mint initial supply that will be owned by the contract itself
        _mint(address(this), _params.tokenPixels * 10 ** 18);

        // initialize clone storage:
        __wpx20().curator = _params.curator;
        __wpx20().parentToken = _params.token;
        __wpx20().parentTokenId = _params.tokenId;
        __wpx20().stats.totalPixels = _params.tokenPixels;

        // read charity values from parent token:
        (address _charityWallet, uint8 _charityPercentage) = IWittyPixelsToken(
            _params.token
        ).getTokenCharityValues(_params.tokenId);
        require(
            (_charityWallet == address(0) && _charityPercentage == 0)
                || (_charityWallet != address(0) && _charityPercentage <= 100)
            , "WittyPixelsTokenVault: bad charity values"
        );
        if (
            _charityWallet != address(0) 
                && _charityPercentage != uint8(0)
        ) {
            __wpx20().charity.wallet = _charityWallet;
            __wpx20().charity.percentage = _charityPercentage;
        }

        // deserialize and set auction settings passed over from the vault factory:
        __setAuctionSettings(_params.settings);
    }


    // ================================================================================================================
    // --- Internal virtual methods -----------------------------------------------------------------------------------

    function __afterCloning(address _newInstance, bytes memory _initdata)
        virtual internal
        returns (ITokenVaultWitnet)
    {
        WittyPixelsClonableBase(_newInstance).initializeClone(_initdata);
        return ITokenVaultWitnet(_newInstance);
    }

    function __setAuctionSettings(bytes memory _bytes) virtual internal {
        // decode dutch auction settings:
        ITokenVaultAuctionDutch.Settings memory _settings = abi.decode(
            _bytes,
            (ITokenVaultAuctionDutch.Settings)
        );
        // verify settings:
        require(
            _settings.startingPrice >= _settings.reservePrice
                && _settings.deltaPrice <= (_settings.startingPrice - _settings.reservePrice)
                && _settings.deltaSeconds > 0
                && _settings.startingPrice > 0
            , "WittyPixelsTokenVault: bad settings"
        );
        // update storage:
        __wpx20().settings = _settings;
        emit AuctionSettings(msg.sender, _bytes);
    }

    function __wpx20()
        internal pure
        returns (WittyPixels.TokenVaultStorage storage ptr)
    {
        bytes32 slothash = WittyPixels.WPX_TOKEN_VAULT_SLOTHASH;
        assembly {
            ptr.slot := slothash
        }
    }
}