// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/INFTProtocolDEX.sol";
import "./DEXConstants.sol";
import "./DEXAccessControl.sol";

contract NFTProtocolDEX is
    INFTProtocolDEX,
    DEXAccessControl,
    DEXConstants,
    ERC1155Holder,
    ERC721Holder,
    ReentrancyGuard
{
    using Address for address;
    using SafeERC20 for IERC20;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    string public constant name = "NFTProtocolDEX";

    /**
     * @inheritdoc INFTProtocolDEX
     */
    uint16 public constant majorVersion = 3;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    uint16 public constant minorVersion = 0;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    address public immutable token;

    /**
     * @inheritdoc INFTProtocolDEX
     * @dev Default is 0.001 Ether.
     */
    uint256 public flatFee = 1_000_000_000_000_000;

    /**
     * @inheritdoc INFTProtocolDEX
     * @dev Default is 10,000 tokens.
     */
    uint256 public lowFee = 10_000 * 10**18;

    /**
     * @inheritdoc INFTProtocolDEX
     * @dev Default is 100,000 tokens.
     */
    uint256 public highFee = 100_000 * 10**18;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    uint256 public numSwaps;

    /**
     * @dev Map of Ether balances.
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev Total value locked, including all swap ether, excluding the contract owner's fees.
     */
    uint256 public tvl;

    /**
     * @dev Mapping from swapID to swap structures for all swaps,
     * including closed and dropped swaps.
     */
    mapping(uint256 => Swap) private _swaps;

    /**
     * @dev Mapping from swapID to swap whitelist.
     */
    mapping(uint256 => mapping(address => bool)) private _whitelists;

    /**
     * @dev Valid swap check.
     */
    modifier validSwap(uint256 swapID) {
        require(swapID < numSwaps, "Invalid swapID");
        _;
    }

    /**
     * @dev Valid side check.
     */
    modifier validSide(uint8 side) {
        require(side == MAKER_SIDE || side == TAKER_SIDE, "Invalid side");
        _;
    }

    /**
     * Initializes the contract with the address of the NFT Protocol token
     * and the address of the administrator account.
     * @param token_ address of the NFT Protocol ERC20 token
     * @param admin_ address of the administrator account (multisig)
     */
    constructor(address token_, address admin_) DEXAccessControl(admin_) {
        token = token_;
        emit FeesChanged(flatFee, lowFee, highFee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `deprecated` or `locked` mode, see :sol:func:deprecated and :sol:func:locked, respectively.
     * - to the contract administrator, see :sol:func:owner.
     */
    function makeSwap(
        Component[] calldata make_,
        Component[] calldata take_,
        bool custodial_,
        uint256 expiration_,
        address[] calldata whitelist_
    ) external payable override supported unlocked notOwner nonReentrant {
        require(make_.length > 0, "Make side is empty");
        require(take_.length > 0, "Take side is empty");
        require(_notExpired(expiration_), "Invalid expiration");

        // Calc make value, pay amount, and updated balance, also checks asset types.
        address sender = _msgSender();
        (uint256 pay, uint256 updated) = _requiredValue(sender, make_, msg.value, 0);
        _checkComponents(take_);

        // Check sent value.
        require(msg.value >= pay, "Insufficient Ether value");

        // Create swap.
        _addSwap(make_, take_, custodial_, expiration_, whitelist_);

        // Update tvl.
        tvl += msg.value;

        // Transfer in maker assets.
        _transferAssetsIn(make_, custodial_);

        // Update balance.
        _updateBalance(updated, numSwaps);

        // Finalize swap.
        numSwaps += 1;

        // Issue event.
        emit SwapMade(numSwaps - 1, make_, take_, sender, custodial_, expiration_, whitelist_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `locked` mode, see :sol:func:locked,
     * - to the contract administrator, see :sol:func:owner.
     */
    function takeSwap(uint256 swapID_, uint256 seqNum_) external payable override unlocked notOwner nonReentrant {
        address sender = _msgSender();
        (Swap storage swp, uint256 pay, uint256 updated, uint256 fee) = _takerSwapAndValues(sender, swapID_, msg.value);
        require(swp.seqNum == seqNum_, "Wrong seqNum");
        require(msg.value >= pay, "Insufficient Ether value (price + fee)");

        // Close out swap.
        swp.status = CLOSED_SWAP;
        swp.taker = sender;

        // Update balance.
        _updateBalance(updated, swapID_);

        // Transfer assets from DEX to taker.
        _transferAssetsOut(swp.components[MAKER_SIDE], swp.maker, swp.custodial);

        // Transfer assets from taker to maker.
        for (uint256 i = 0; i < swp.components[TAKER_SIDE].length; i++) {
            _transferAsset(swp.components[TAKER_SIDE][i], sender, swp.maker);
        }

        // Credit fee to owner.
        address owner_ = owner();
        _balances[owner_] += fee;
        tvl += msg.value;
        tvl -= fee;

        // Issue events.
        emit SwapTaken(swapID_, swp.seqNum, sender, fee);
        emit Deposited(owner(), fee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `locked` mode, see :sol:func:locked,
     * - to the contract administrator, see :sol:func:owner.
     */
    function dropSwap(uint256 swapID_) external override unlocked notOwner nonReentrant {
        Swap storage swp = _swaps[swapID_];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(_msgSender() == swp.maker, "Not swap maker");

        // Drop swap.
        swp.status = DROPPED_SWAP;

        // Transfer assets back to maker.
        for (uint256 i = 0; i < swp.components[MAKER_SIDE].length; i++) {
            if (swp.custodial || swp.components[MAKER_SIDE][i].assetType == ETHER_ASSET) {
                _transferAsset(swp.components[MAKER_SIDE][i], address(this), swp.maker);
            }
        }

        // Issue event.
        emit SwapDropped(swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `locked` mode, see :sol:func:locked,
     * - to the contract administrator, see :sol:func:owner.
     */
    function amendSwapEther(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external payable override unlocked notOwner nonReentrant validSide(side_) validSwap(swapID_) {
        Swap storage swp = _swaps[swapID_];
        require(swp.status == OPEN_SWAP, "Swap not open");
        address sender = _msgSender();
        require(sender == swp.maker, "Not swap maker");
        require(_notExpired(swp.expiration), "Swap expired");
        Component[] storage comps = swp.components[side_];

        // Set ether asset.
        (uint256 previous, uint256 index) = _setEtherAsset(comps, value_);
        require(value_ != previous, "Ether value unchanged");
        require(value_ > 0 || comps.length > 1, "Swap side becomes empty");

        // Update balance.
        uint256 balance_ = _balances[sender];
        if (side_ == TAKER_SIDE && msg.value > 0) {
            _updateBalance(balance_ + msg.value, swapID_);
        } else if (side_ == MAKER_SIDE) {
            if (value_ > previous) {
                require(balance_ + msg.value >= value_ - previous, "Insufficient Ether value");
            }
            _updateBalance(balance_ + msg.value + previous - value_, swapID_);
        }

        // Update tvl.
        tvl += msg.value;

        // Update seqNum.
        swp.seqNum += 1;

        // Issue event.
        emit SwapEtherAmended(swapID_, swp.seqNum, side_, index, previous, value_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function requires the swap to be defined.
     */
    function swap(uint256 swapID_) external view override validSwap(swapID_) returns (Swap memory) {
        return _swaps[swapID_];
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function requires the swap to be defined.
     */
    function whitelistedWith(address sender_, uint256 swapID_) public view override validSwap(swapID_) returns (bool) {
        return _whitelists[swapID_][sender_];
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function whitelisted(uint256 swapID_) external view override returns (bool) {
        return whitelistedWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function requires the swap to be defined and open.
     */
    function requireCanTakeSwapWith(address sender_, uint256 swapID_) public view override unlocked validSwap(swapID_) {
        (Swap storage swp, , , ) = _takerSwapAndValues(sender_, swapID_, 0);
        _requireComponents(swp.components[TAKER_SIDE], sender_, true);
        if (!swp.custodial) {
            _requireComponents(swp.components[MAKER_SIDE], swp.maker, false);
        }
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireCanTakeSwap(uint256 swapID_) external view override {
        return requireCanTakeSwapWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireMakerAssets(uint256 swapID) external view override unlocked validSwap(swapID) {
        Swap memory swp = _swaps[swapID];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(!swp.custodial, "Swap custodial");
        _requireComponents(swp.components[MAKER_SIDE], swp.maker, false);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireTakerAssetsWith(address sender_, uint256 swapID_) public view override unlocked validSwap(swapID_) {
        (Swap storage swp, , , ) = _takerSwapAndValues(sender_, swapID_, 0);
        _requireComponents(swp.components[TAKER_SIDE], sender_, true);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireTakerAssets(uint256 swapID_) public view override {
        return requireTakerAssetsWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function balanceOf(address of_) public view override returns (uint256) {
        return _balances[of_];
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function balance() external view override returns (uint256) {
        return balanceOf(_msgSender());
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function withdraw(uint256 value_) external override {
        _withdraw(value_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function withdrawFull() external override {
        _withdraw(_balances[_msgSender()]);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function makerSendValueWith(address sender_, Component[] calldata make_)
        public
        view
        override
        supported
        unlocked
        returns (uint256)
    {
        (uint256 pay, ) = _requiredValue(sender_, make_, 0, 0);
        return pay;
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function makerSendValue(Component[] calldata make_) external view override returns (uint256) {
        return makerSendValueWith(_msgSender(), make_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerSendValueWith(address sender_, uint256 swapID_) public view override unlocked returns (uint256) {
        (, uint256 pay, , ) = _takerSwapAndValues(sender_, swapID_, 0);
        return pay;
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerSendValue(uint256 swapID_) external view override unlocked returns (uint256) {
        return takerSendValueWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function amendSwapEtherSendValueWith(
        address sender_,
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) public view override unlocked validSide(side_) returns (uint256) {
        Swap storage swp = _swaps[swapID_];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(sender_ == swp.maker, "Not swap maker");
        require(_notExpired(swp.expiration), "Swap expired");
        Component[] storage comps = swp.components[side_];

        // Ether value.
        uint256 current = _getEtherAsset(comps);
        require(value_ != current, "Ether value unchanged");
        require(value_ > 0 || comps.length > 1, "Swap side becomes empty");

        // Value required to amend swap Ether.
        uint256 balance_ = _balances[sender_];
        if (side_ == MAKER_SIDE && value_ > current && balance_ < value_ - current) {
            return value_ - current - balance_;
        }

        return 0;
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function amendSwapEtherSendValue(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external view override returns (uint256) {
        return amendSwapEtherSendValueWith(_msgSender(), swapID_, side_, value_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerFeeWith(address sender_) public view override unlocked returns (uint256) {
        uint256 balance_ = IERC20(token).balanceOf(sender_);
        if (balance_ >= highFee) {
            return 0;
        }
        if (balance_ < lowFee) {
            return flatFee;
        }
        // Take 10% off as soon as feeBypassLow is reached.
        uint256 startFee = (flatFee * 9) / 10;
        return startFee - (startFee * (balance_ - lowFee)) / (highFee - lowFee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerFee() external view override returns (uint256) {
        return takerFeeWith(_msgSender());
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function can only be called by the contract administrator, see :sol:func:`owner`.
     */
    function setFees(
        uint256 flatFee_,
        uint256 lowFee_,
        uint256 highFee_
    ) external override supported onlyOwner {
        require(lowFee_ <= highFee_, "lowFee must be <= highFee");
        flatFee = flatFee_;
        lowFee = lowFee_;
        highFee = highFee_;
        emit FeesChanged(flatFee, lowFee, highFee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function can only be called by the contract administrator, see :sol:func:`owner`.
     */
    function rescue() external override onlyOwner nonReentrant {
        address sender = _msgSender();
        uint256 balance_ = _balances[sender];
        uint256 total = address(this).balance - tvl;
        require(total > balance_, "No value to rescue");
        uint256 amount = total - balance_;
        _balances[sender] += amount;
        emit Deposited(sender, amount);
        emit Rescued(sender, amount);
    }

    /**
     * Appends a new swap to the list.
     */
    function _addSwap(
        Component[] calldata make_,
        Component[] calldata take_,
        bool custodial_,
        uint256 expiration_,
        address[] calldata whitelist_
    ) internal {
        _swaps[numSwaps].id = numSwaps;
        _swaps[numSwaps].custodial = custodial_;
        _swaps[numSwaps].expiration = expiration_;
        _swaps[numSwaps].maker = _msgSender();
        for (uint256 i = 0; i < make_.length; i++) {
            _swaps[numSwaps].components[MAKER_SIDE].push(make_[i]);
        }
        for (uint256 i = 0; i < take_.length; i++) {
            _swaps[numSwaps].components[TAKER_SIDE].push(take_[i]);
        }

        // Initialize whitelist mapping for this swap.
        _swaps[numSwaps].whitelist = whitelist_.length > 0;
        for (uint256 i = 0; i < whitelist_.length; i++) {
            _whitelists[numSwaps][whitelist_[i]] = true;
        }
    }

    /**
     * Transfers assets in.
     */
    function _transferAssetsIn(Component[] calldata make_, bool custodial_) internal {
        address sender = _msgSender();
        for (uint256 i = 0; i < make_.length; i++) {
            if (custodial_ || make_[i].assetType == ETHER_ASSET) {
                _transferAsset(make_[i], sender, address(this));
            } else {
                _requireAssets(make_[i], sender, msg.value);
            }
        }
    }

    /**
     * Transfers assets out.
     */
    function _transferAssetsOut(
        Component[] storage comps,
        address from,
        bool custodial
    ) internal {
        address sender = _msgSender();
        for (uint256 i = 0; i < comps.length; i++) {
            if (custodial || comps[i].assetType == ETHER_ASSET) {
                _transferAsset(comps[i], address(this), sender);
            } else {
                _transferAsset(comps[i], from, sender);
            }
        }
    }

    /**
     * Sets the ether component to value, create one if needed.
     * Returns the previous Ether value.
     */
    function _setEtherAsset(Component[] storage comps, uint256 value) internal returns (uint256, uint256) {
        for (uint256 i = 0; i < comps.length; i++) {
            if (comps[i].assetType == ETHER_ASSET) {
                uint256 previous = comps[i].amounts[0];
                comps[i].amounts[0] = value;
                return (previous, i);
            }
        }
        Component memory comp = Component({
            assetType: ETHER_ASSET,
            tokenAddress: address(0),
            tokenIDs: new uint256[](0),
            amounts: new uint256[](1)
        });
        comp.amounts[0] = value;
        comps.push(comp);
        return (0, comps.length - 1);
    }

    /**
     * Gets the Ether component value.
     */
    function _getEtherAsset(Component[] memory comps) internal pure returns (uint256) {
        for (uint256 i = 0; i < comps.length; i++) {
            if (comps[i].assetType == ETHER_ASSET) {
                return comps[i].amounts[0];
            }
        }
        return 0;
    }

    /**
     * Transfers asset from one account to another.
     */
    function _transferAsset(
        Component memory comp,
        address from,
        address to
    ) internal {
        // All component checks were conducted before.
        if (comp.assetType == ERC1155_ASSET) {
            IERC1155 nft = IERC1155(comp.tokenAddress);
            nft.safeBatchTransferFrom(from, to, comp.tokenIDs, comp.amounts, "");
        } else if (comp.assetType == ERC721_ASSET) {
            IERC721 nft = IERC721(comp.tokenAddress);
            nft.safeTransferFrom(from, to, comp.tokenIDs[0]);
        } else if (comp.assetType == ERC20_ASSET) {
            IERC20 coin = IERC20(comp.tokenAddress);
            uint256 amount = comp.amounts[0];
            if (from == address(this)) {
                coin.safeTransfer(to, amount);
            } else {
                coin.safeTransferFrom(from, to, amount);
            }
        } else {
            // Ether, single length amounts array was checked before.
            _balances[to] += comp.amounts[0];
        }
    }

    /**
     * Verifies ownerships, balances, and approval for list of components.
     */
    function _requireComponents(
        Component[] memory comps,
        address wallet,
        bool includeEther
    ) internal view {
        for (uint256 i = 0; i < comps.length; i++) {
            if (includeEther || comps[i].assetType != ETHER_ASSET) {
                _requireAssets(comps[i], wallet, 0);
            }
        }
    }

    /**
     * Verifies ownerships, balances, and approval of component assets.
     */
    function _requireAssets(
        Component memory comp,
        address wallet,
        uint256 sentValue
    ) internal view {
        if (comp.assetType == ERC1155_ASSET) {
            _requireERC1155Assets(comp, wallet);
        } else if (comp.assetType == ERC721_ASSET) {
            _requireERC721Asset(comp, wallet);
        } else if (comp.assetType == ERC20_ASSET) {
            _requireERC20Asset(comp, wallet);
        } else {
            _requireSufficientValue(comp, wallet, sentValue);
        }
    }

    /**
     * Verifies balance and approval of ERC1155 assets.
     */
    function _requireERC1155Assets(Component memory comp, address wallet) internal view {
        IERC1155 nft = IERC1155(comp.tokenAddress);

        // Create accounts for batch balance.
        address[] memory wallets = new address[](comp.tokenIDs.length);
        for (uint256 i = 0; i < comp.tokenIDs.length; i++) {
            wallets[i] = wallet;
        }

        // Batch balance.
        uint256[] memory balances = nft.balanceOfBatch(wallets, comp.tokenIDs);
        require(balances.length == comp.tokenIDs.length, "Invalid balanceOfBatch call");
        for (uint256 i = 0; i < comp.tokenIDs.length; i++) {
            require(balances[i] >= comp.amounts[i], "Insufficient ERC1155 balance");
        }

        // Check if DEX has approval for all.
        bool approved = nft.isApprovedForAll(wallet, address(this));
        require(approved, "DEX not ERC1155 approved");
    }

    /**
     * Verifies balance and approval of ERC721 asset.
     */
    function _requireERC721Asset(Component memory comp, address wallet) internal view {
        IERC721 nft = IERC721(comp.tokenAddress);

        // Check owner.
        address owner = nft.ownerOf(comp.tokenIDs[0]);
        require(owner == wallet, "Not ERC721 token owner");

        // Check approval.
        bool approved = nft.isApprovedForAll(wallet, address(this));
        if (!approved) {
            approved = address(this) == nft.getApproved(comp.tokenIDs[0]);
        }
        require(approved, "DEX not ERC721 approved");
    }

    /**
     * Verifies balance and approval of ERC20 asset.
     */
    function _requireERC20Asset(Component memory comp, address wallet) internal view {
        IERC20 coin = IERC20(comp.tokenAddress);

        // Check balance needed, since ERC20 does not update allowance at transfer (only transferFrom).
        uint256 balance_ = coin.balanceOf(wallet);
        require(balance_ >= comp.amounts[0], "Insufficient ERC20 balance");

        // Check allowance.
        uint256 allowance = coin.allowance(wallet, address(this));
        require(allowance >= comp.amounts[0], "Insufficient ERC20 allowance");
    }

    /**
     * Checks a required Ether value against a wallet balances and sent value.
     * This function ignores transaction (gas) and taker fees.
     */
    function _requireSufficientValue(
        Component memory comp,
        address wallet,
        uint256 sentValue
    ) internal view {
        uint256 balance_ = _balances[wallet];
        require(wallet.balance + balance_ + sentValue >= comp.amounts[0], "Insufficient Ether value");
    }

    /**
     * Checks components against the balance of a sender, the sent value, and a fee.
     * This function ignores transaction (gas) fees.
     */
    function _requiredValue(
        address sender,
        Component[] memory comps,
        uint256 sentValue,
        uint256 fee
    ) internal view returns (uint256, uint256) {
        uint256 value = _checkComponents(comps);
        uint256 balance_ = _balances[sender];
        if (balance_ + sentValue >= value + fee) {
            return (0, balance_ + sentValue - value - fee);
        }
        return (value + fee - balance_, 0);
    }

    /**
     * Checks all assets in a component array.
     */
    function _checkComponents(Component[] memory comps) internal pure returns (uint256) {
        uint256 total;
        bool etherSeen;
        for (uint256 i = 0; i < comps.length; i++) {
            // Allow only one ether component.
            if (comps[i].assetType == ETHER_ASSET) {
                require(!etherSeen, "Multiple ether components");
                etherSeen = true;
            }
            total += _checkComponent(comps[i]);
        }
        return total;
    }

    /**
     * Checks asset type and array sizes within a component.
     */
    function _checkComponent(Component memory comp) internal pure returns (uint256) {
        if (comp.assetType == ERC1155_ASSET) {
            require(comp.tokenIDs.length == comp.amounts.length, "TokenIDs and amounts len differ");
        } else if (comp.assetType == ERC721_ASSET) {
            require(comp.tokenIDs.length == 1, "TokenIDs array length must be 1");
        } else if (comp.assetType == ERC20_ASSET) {
            require(comp.amounts.length == 1, "Amounts array length must be 1");
        } else if (comp.assetType == ETHER_ASSET) {
            require(comp.amounts.length == 1, "Amounts array length must be 1");
            return comp.amounts[0];
        } else {
            revert("Invalid asset type");
        }
        return 0;
    }

    /**
     * Checks an expiration parameter against the current block.
     */
    function _notExpired(uint256 expiration) internal view returns (bool) {
        return expiration == 0 || expiration > block.number;
    }

    /**
     * Returns information about a swap take operation.
     *
     * @return (swap, value to send, updated balance, fee)
     */
    function _takerSwapAndValues(
        address sender,
        uint256 swapID,
        uint256 sentValue
    )
        internal
        view
        validSwap(swapID)
        returns (
            Swap storage,
            uint256,
            uint256,
            uint256
        )
    {
        // Get swap.
        Swap storage swp = _swaps[swapID];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(sender != swp.maker, "Sender is swap maker");
        require(!swp.whitelist || _whitelists[swapID][sender], "Not in whitelist");
        require(_notExpired(swp.expiration), "Swap expired");

        // Return total Ether to be provided by the taker (including), updated balance.
        uint256 fee = takerFeeWith(sender);
        (uint256 pay, uint256 updated) = _requiredValue(sender, swp.components[TAKER_SIDE], sentValue, fee);
        return (swp, pay, updated, fee);
    }

    /**
     * Updates the balance of an account.
     */
    function _updateBalance(uint256 updated, uint256 swapID) internal {
        address sender = _msgSender();
        uint256 balance_ = _balances[sender];
        _balances[sender] = updated;
        if (updated > balance_) {
            emit Deposited(sender, updated - balance_);
        } else if (updated < balance_) {
            emit Spent(sender, balance_ - updated, swapID);
        }
    }

    /**
     * Withdraws funds from an account.
     */
    function _withdraw(uint256 value) internal nonReentrant {
        require(value > 0, "Ether value is zero");
        address sender = _msgSender();
        uint256 balance_ = _balances[sender];
        require(value <= balance_, "Ether value exceeds balance");
        _balances[sender] -= value;
        if (sender != owner()) {
            tvl -= value;
        }
        (bool ok, ) = sender.call{value: value}("");
        require(ok, "Withdrawal failed");
        emit Withdrawn(sender, value);
    }

    /**
     * Receives Ether funds.
     */
    receive() external payable supported unlocked notOwner {
        uint256 amount = msg.value;
        require(amount > 0, "Ether value is zero");
        address sender = _msgSender();
        _balances[sender] += amount;
        tvl += amount;
        emit Deposited(sender, amount);
    }
}