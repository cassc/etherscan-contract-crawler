// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {ERC721, ERC721TokenReceiver} from "solmate/tokens/ERC721.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {LSSVMPairMissingEnumerableETH} from "lssvm/LSSVMPairMissingEnumerableETH.sol";
import {PuttyV2} from "putty-v2/PuttyV2.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {MintBurnToken} from "./lib/MintBurnToken.sol";
import {OptionBonding} from "./OptionBonding.sol";
import {FeeBonding} from "./FeeBonding.sol";

/**
 * @notice hiya! ~~ welcome to wheyfus :3 ~
 * General overview:
 *
 * Wheyfus is an NFT collection with a max supply of 30,000.
 * 9000 is distributed via a free mint.
 * 18000 is reserved for yield farming (distributed over 900 days).
 * 3000 is minted to the team.
 *
 * Yield farming works by LP'ing into a shared xyk curve sudo pool then locking up the LP tokens for a fixed bond duration.
 * The duration is variable (0 days, 30 days, 90 days etc.). The longer you bond for, the higher your yield boost.
 * The bonds yield call option tokens which can be converted 1:1 for putty call options on wheyfus. Each call option
 * expires in 5 years and has a strike of 0.1 eth.
 *
 * There is also LP fee farming. This works similarly by LP'ing into a shared xyk curve sudo pool and also locking up LP
 * tokens for a fixed bond duration. Except this time, instead of yield farming call option tokens, you yield farm the fees
 * generated from the sudoswap pool. Fees are distributed pro rata based on the amount already staked and your yield boost.
 *
 * So there are 2 farms. 1 yielding call option tokens and 1 yielding sudoswap LP fees.
 *
 * note: The yield from the LP farm is boosted by the yield from the staked LP tokens in the call option farm. This is because
 * LPs in the call option farm don't receive any LP fees; instead opting for call option yield.
 *
 * thanks for reading *blush* uwu
 *
 * @author 0xacedia
 */
contract Wheyfu is FeeBonding, OptionBonding, ERC721, ERC721TokenReceiver {
    /// @notice The max supply of wheyfus.
    /// @dev 18k for yield farming, 9k for free mint, 3k for team.
    uint256 public constant MAX_SUPPLY = 30_000;

    /// @notice The total minted supply.
    uint256 public totalSupply;

    /// @notice Whether or not the whitelist can be modified.
    bool public closedWhitelist = false;

    /// @notice The total whitelisted supply.
    /// @dev This should never exceed the max supply.
    uint256 public whitelistedSupply;

    /// @notice Mapping of address -> whitelist amount.
    mapping(address => uint256) public mintWhitelist;

    LSSVMPairMissingEnumerableETH public pair;
    ERC721 public tokenUri;

    /**
     * @notice Emitted when liquidity is added.
     * @param tokenAmount The amount of eth that was added.
     * @param nftAmount The amount of nfts that were added.
     * @param shares The amount of shares that were minted.
     */
    event AddLiquidity(uint256 tokenAmount, uint256 nftAmount, uint256 shares);

    /**
     * @notice Emitted when liquidity is removed.
     * @param tokenAmount The amount of eth that was removed.
     * @param nftAmount The amount of nfts that were removed.
     * @param shares The amount of shares that were burned.
     */
    event RemoveLiquidity(uint256 tokenAmount, uint256 nftAmount, uint256 shares);

    // solhint-disable-next-line
    receive() external payable {}

    constructor(address _lpToken, address _callOptionToken, address _putty, address _weth)
        ERC721("Wheyfus anonymous :3", "UwU")
        OptionBonding(_lpToken, _callOptionToken, _putty, _weth)
        FeeBonding(_lpToken)
    {}

    /**
     * @notice Sets the sudoswap pool address.
     * @param _pair The sudoswap pool.
     */
    function setPair(address payable _pair) public onlyOwner {
        require(address(pair) == address(0), "Pair already set");

        pair = LSSVMPairMissingEnumerableETH(_pair);
        _setPair(_pair);
    }

    /**
     * ~~~~~~~~~~~~~~~
     * ADMIN FUNCTIONS
     * ~~~~~~~~~~~~~~~
     */

    /**
     * @notice Sets the tokenURI contract.
     * @param _tokenUri The tokenURI contract.
     */
    function setTokenUri(address _tokenUri) public onlyOwner {
        tokenUri = ERC721(_tokenUri);
    }

    /**
     * @notice Closes the whitelist.
     * @dev After this point the whitelist can no longer be modified.
     */
    function closeWhitelist() public onlyOwner {
        closedWhitelist = true;
    }

    /**
     * ~~~~~~~~~~~~~~~~~
     * MINTING FUNCTIONS
     * ~~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Whitelists a minter so that they can mint a certain amount.
     * @param target The address to whitelist.
     * @param amount The amount to whitelist them for.
     */
    function whitelistMinter(address target, uint256 amount) public onlyOwner {
        // check whitelist is not closed
        require(!closedWhitelist, "Whitelist has been closed");

        // increment/decrement the new whitelistedSupply
        uint256 oldAmount = mintWhitelist[target];
        whitelistedSupply -= oldAmount;
        whitelistedSupply += amount;

        // check whitelisted supply is less than the max supply
        require(whitelistedSupply <= MAX_SUPPLY, "Max supply already reached");

        // save the new whitelist amount to the target
        mintWhitelist[target] = amount;
    }

    /**
     * @notice Mints a certain amount of nfts to msg.sender.
     * @param amount The amount of nfts to mint.
     */
    function mint(uint256 amount) public returns (uint256) {
        mintTo(amount, msg.sender);

        return totalSupply;
    }

    /**
     * @notice Mints a certain amount of nfts to an address.
     * @param amount The amount of nfts to mint.
     * @param to Who to mint the nfts to.
     */
    function mintTo(uint256 amount, address to) public returns (uint256) {
        return _mintTo(amount, to, msg.sender);
    }

    /**
     * @notice Mints a certain amount of nfts to an address from an account.
     * @param amount The amount of nfts to mint.
     * @param to Who to mint the nfts to.
     * @param from Who to mint the nfts from.
     */
    function _mintTo(uint256 amount, address to, address from) internal returns (uint256) {
        // check that the from account is whitelisted to mint the amount
        require(mintWhitelist[from] >= amount, "Not whitelisted for this amount");

        // loop through and mint N nfts to the to account
        for (uint256 i = totalSupply; i < totalSupply + amount; i++) {
            _mint(to, i + 1);
        }

        // increase the balance of the to account
        _balanceOf[to] += amount;

        // increase the total supply
        totalSupply += amount;

        // decrease the whitelisted amount from the from account
        mintWhitelist[from] -= amount;

        return totalSupply;
    }

    /**
     * @notice Mints a particular nft to an account.
     * @param to Who to mint the nft to.
     * @param id The id of the nft to mint.
     */
    function _mint(address to, uint256 id) internal override {
        require(to != address(0), "INVALID_RECIPIENT");
        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    /**
     * ~~~~~~~~~~~~~~~~~~~~~~~
     * SUDOSWAP POOL FUNCTIONS
     * ~~~~~~~~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Adds liquidity to the shared sudoswap pool and mints lp tokens.
     * @dev Updates the sudo reserves.
     * @param tokenIds The tokenIds of the nfts to send to the sudoswap pool.
     * @param minPrice The min price to lp at.
     * @param maxPrice The max price to lp at.
     */
    function addLiquidity(uint256[] calldata tokenIds, uint256 minPrice, uint256 maxPrice)
        public
        payable
        returns (uint256 shares)
    {
        // check current price is in between min and max
        uint256 _tokenReserves = tokenReserves();
        uint256 _nftReserves = nftReserves();
        uint256 _price = _tokenReserves > 0 && _nftReserves > 0 ? _tokenReserves / _nftReserves : 0;
        require(_price <= maxPrice && _price >= minPrice, "Price slippage");

        // check min eth amount was sent
        require(msg.value > 0.0001 ether, "Must send at least 0.0001 ether");

        // update sudoswap reserves
        _updateReserves(_tokenReserves + msg.value, _nftReserves + tokenIds.length);

        // mint shares to sender
        uint256 _totalSupply = lpToken.totalSupply();
        shares =
            _totalSupply == 0
            ? msg.value * tokenIds.length
            : Math.min((_totalSupply * msg.value) / _tokenReserves, (_totalSupply * tokenIds.length) / _nftReserves);
        lpToken.mint(msg.sender, shares);

        // deposit tokens to sudoswap pool
        for (uint256 i = 0; i < tokenIds.length;) {
            _safeTransferFrom(msg.sender, address(pair), tokenIds[i]);

            unchecked {
                i++;
            }
        }

        // deposit eth to sudoswap pool
        SafeTransferLib.safeTransferETH(address(pair), msg.value);

        emit AddLiquidity(msg.value, tokenIds.length, shares);
    }

    /**
     * @notice Removes liquidity from the shared sudoswap pool and burns lp tokens.
     * @dev Updates the sudo reserves.
     * @param tokenIds The tokenIds of the nfts to remove from the sudoswap pool.
     * @param minPrice The min price to remove the lp at.
     * @param maxPrice The max price to remove lp at.
     */
    function removeLiquidity(uint256[] calldata tokenIds, uint256 minPrice, uint256 maxPrice) public {
        // check current price is in between min and max
        uint256 _price = price();
        require(_price <= maxPrice && _price >= minPrice, "Price slippage");

        // update sudoswap reserves
        uint256 _tokenReserves = tokenReserves();
        uint256 _nftReserves = nftReserves();
        uint256 tokenAmount = (_tokenReserves * tokenIds.length) / _nftReserves;
        _updateReserves(_tokenReserves - tokenAmount, _nftReserves - tokenIds.length);

        // withdraw liquidity
        pair.withdrawETH(tokenAmount);
        pair.withdrawERC721(IERC721(address(this)), tokenIds);

        // burn shares
        uint256 _totalSupply = lpToken.totalSupply();
        uint256 shares = (_totalSupply * tokenIds.length) / _nftReserves;
        lpToken.burn(msg.sender, shares);

        // send tokens to user
        for (uint256 i = 0; i < tokenIds.length;) {
            _safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            unchecked {
                i++;
            }
        }

        // send eth to user
        SafeTransferLib.safeTransferETH(msg.sender, tokenAmount);

        emit RemoveLiquidity(tokenAmount, tokenIds.length, shares);
    }

    /**
     * @notice Getter for the token reserves in the sudoswap pool.
     */
    function tokenReserves() public view returns (uint256) {
        return pair.spotPrice();
    }

    /**
     * @notice Getter for the nft reserves in the sudoswap pool.
     */
    function nftReserves() public view returns (uint256) {
        return pair.delta();
    }

    /**
     * @notice Getter for the price in the sudoswap pool.
     */
    function price() public view returns (uint256) {
        uint256 _tokenReserves = tokenReserves();
        uint256 _nftReserves = nftReserves();

        return _tokenReserves > 0 && _nftReserves > 0 ? _tokenReserves / _nftReserves : 0;
    }

    /**
     * @notice Updates the sudoswap pool's virtual reserves.
     * @param _tokenReserves The new token reserves.
     * @param _nftReserves The new nft reserves.
     */
    function _updateReserves(uint256 _tokenReserves, uint256 _nftReserves) internal {
        pair.changeSpotPrice(uint128(_tokenReserves));
        pair.changeDelta(uint128(_nftReserves));
    }

    /**
     * ~~~~~~~~~~~~~~~~~~~
     * PERIPHERY FUNCTIONS
     * ~~~~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Wrapper around addLiquidity() and optionStake()
     * @param tokenIds The tokenIds of the nfts to send to the sudoswap pool.
     * @param minPrice The min price to lp at.
     * @param maxPrice The max price to lp at.
     * @param termIndex Index into the terms array which tells how long to stake for.
     */
    function addLiquidityAndOptionStake(
        uint256[] calldata tokenIds,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 termIndex
    )
        public
        payable
        returns (uint256 tokenId)
    {
        uint256 shares = addLiquidity(tokenIds, minPrice, maxPrice);
        tokenId = optionStake(uint128(shares), termIndex);
    }

    /**
     * @notice Wrapper around addLiquidity() and feeStake()
     * @param tokenIds The tokenIds of the nfts to send to the sudoswap pool.
     * @param minPrice The min price to lp at.
     * @param maxPrice The max price to lp at.
     * @param termIndex Index into the terms array which tells how long to stake for.
     */
    function addLiquidityAndFeeStake(uint256[] calldata tokenIds, uint256 minPrice, uint256 maxPrice, uint256 termIndex)
        public
        payable
        returns (uint256 tokenId)
    {
        uint256 shares = addLiquidity(tokenIds, minPrice, maxPrice);
        tokenId = feeStake(uint128(shares), termIndex);
    }

    /**
     * ~~~~~~~~~~~~~~~~~~
     * OVERRIDE FUNCTIONS
     * ~~~~~~~~~~~~~~~~~~
     */

    /**
     * @notice Tells putty that we support the handler interface.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal _safeTransferFrom() that ignores the authorized checks.
     * Skips checking that from == msg.sender, approvals etc.
     */
    function _safeTransferFrom(address from, address to, uint256 id) internal virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);

        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /**
     * @dev safeTransferFrom() skips transfers if `mintingOption` is set to true.
     * And also skips transfers if putty is trying to transfer on exercise.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        // if minting an option then no need to transfer
        // (means that we need to mint onExercise instead)
        if (mintingOption == 2) {
            return;
        }

        // if putty is trying to send tokens for a tokenId greater than max supply
        // then mint tokens. the only way this should ever be reachable is if the bonding contract
        // minted an option. otherwise putty should never have received tokens with ids greater
        // than the max supply. When the call option is exercised putty will call this function. it
        // mints nfts to the exerciser. Should only be callable by putty. We defer the mint to here
        // instead of on call option creation to save gas.
        if (from == address(putty) && tokenId > MAX_SUPPLY && msg.sender == address(putty)) {
            _mintTo(type(uint256).max - tokenId, to, address(putty));
            return;
        }

        super.safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Returns the tokenURI of a particular token.
     * This method can be "edited" by changing the tokenUri contract variable.
     */
    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return tokenUri.tokenURI(id);
    }
}