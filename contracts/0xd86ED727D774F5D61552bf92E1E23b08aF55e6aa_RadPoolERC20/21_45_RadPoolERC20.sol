// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**                                                                                 
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GGG5YYJJJ?????JJYYYPGB#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BPY?7!~^::::::::::::::::::::::^^!7?5PB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&B5?!^::::::::::::::::::::::::::::::::::::::~!?5B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&GY7~:::::::::^^~~!77???JJJJJJJJJJ???7!!~~^::::::::::~7YG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&P?~::::::::^~!7?JYYYYYYYYYYYYYYYYYYYYYYYYYYYJJ?7!~^::::::::~?P#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&P?~:::::::~!7JJYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJJ7!^:::::::^7P&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@#J~::^^::^!7JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?7JYYYYYYYYYYYYYJ7~^::::::[email protected]@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@&P7^^^^^:^!?JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY~::!YYYYYYYYYYYYYYYYJ?~^:::::^7P&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@P!^^^^^^~?JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ~::::!YYYYYYYYYYYYYYYYYYJ7~::::::[email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@G7^^^^^^!JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?^::::::!YYYYYYYYYYYYYYYYYYYY?!^:^^::[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@#?^^^^^^!JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?:::::::::~YYYYYYYYYYYYYYYYYYYYYJ!^:^^^^?#@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@P~^^^^^!JYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY?:::::::::::~JYYYYYYYYYYYYYYYYYYYYYJ~^^^^^^[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@&J^^^^^~?YYYYYYYYYYYJYYYYYYYYYYYYYYYYYYYYYYYYYYYYJ^::::::::::::!JYYYYYYYYYYYYYYYYYYYYYY!:^^^^^?&@@@@@@@@@@@@
@@@@@@@@@@@B!^^^^^!YYYYYYYYYYYY?^?YYYYYYYYYYYYYYYYYYYYYYYYYYY^::::::::::::^:^77JYYY7?YYYYYYYYYYYJ!~^^^^^^^^!#@@@@@@@@@@@
@@@@@@@@@@B~^^^^^7YYYYYYYYYYYYY^^7YYYYYYYYYYYYYYYYYYYYYYYYYY7::::::::::^^^^^^::^!?!:!YYYYYYYYYY7^^^^^^^^^^^^[email protected]@@@@@@@@@
@@@@@@@@@B~^^^^^?YYYYYYYYYYYYY?^^!YYYYYYYYYJ7?JYJJJ?JYYYYYY?^::::::::::^^^^^^^^:::::~YYYYYYYYJ~:^^^^^^^^^^^^^[email protected]@@@@@@@@
@@@@@@@@#~^^^^^?5YYYYYYYYYYYYY~^^^JYYYYYYYJ^::^^^^^:~YYYYYY^:::::::::::::::::::::::::?YYYYYY7^:^^^^^^^^^!^^^^^~#@@@@@@@@
@@@@@@@&7^^^^^?5YYYYYYYYYYYYY?^^^^~YYYYYY?^:^:::::::^YYYYYJ::::::::::::::::::::::::::~YYYYJ~:::^^^~!7?JJY?^^^^^7&@@@@@@@
@@@@@@@Y^^^^^75YYYYYYYYYYYYY57^^?J?YYYYY?^::::::::::^JYYYY!::::::::::::::::::::::::::^!7?7~~!7?JYYYYYY5YY57^^^^^[email protected]@@@@@@
@@@@@@B^^^^^!YYYYYYYYYY555YYY~^!555YYYYYYJJ~77~?7!!~~?YYYY^:::::::::::::::::::::::::^!??JYYY5YYYYYYYYYYJJ?7^^^^^[email protected]@@@@@
@@@@@@?^^^^^J5YYYYYYYY5??JY5?^^~J????JJJJYYJ?Y!YY5YYYYYYYY??7!!~~^^^::::::::::::::^^:7YYYYJJ??JJJJYYYYYYYYY?^^^[email protected]@@@@@
@@@@@#~^^^^!YYYYYYYYYYY~^^!?!^^^^^^^^^^^^^~~~!~!????JJYJJJYYYYYYYYYYJJ7!^:^^^^^^^^^^^^~~^~^^:!YYYY555YYYYY55~~~~~~#@@@@@
@@@@@Y^^^^^?5YYYYYYYYYY~^^^^^^^^^^^^^^^^^^^^^^^^::::^^^^^^^^~~~~!!77?JJJ7^^^^^^^^^^^^^^^^^^^!YYYY57!?YYYYY55?^[email protected]@@@@
@@@@@?^^^^^J5YYYYYY55557^^^^^^^^^^^^^^^^^^^^^^^^^^^~!!!!~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^?5YYYY5?!7YYY5555J^[email protected]@@@@
@@@@@7^^^^~Y55555555555?~~~~^^^^^^^^^^^^~~!!7?JJJYYYYYYYYJ!^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@
@@@@&!^^^^!Y55555555555Y!~~~~~^^^^^^^~JYYY55YYJ??YYYYYYYYY5J!^~~~^^^^^^^^^^^^^^^^^^^^^^^^^JYYYYYY5Y5Y?YY55555~~~~~!&@@@@
@@@@&~^^^~55555555555555?~~~~~~~~^^^!Y5YYYYYY!^^!YYYYYYYYYY55J!~~~^^^^^^^^^^^^^^^^^^^^^^^~YYYYJYY5Y57J5Y555555!~~~!&@@@@
@@@@@7^~~~P55555555555555!~~~~~~~~~?55YYYYYYYYJ?YYYYYYYYYY55555J~~~^^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@
@@@@@?~~~~Y5YYJJ??7?55555?~~~~~~~7Y555Y555YYYYY5YYYY?YYY55555555Y7~~^^^^^^^^^^^^^^^^^^^^^^[email protected]@@@@
@@@@@5~~~~JY~~~~~~~~7J555Y~~~~~!J5555Y555Y?55YYYYYYYJ5Y55555Y5555J~~^^^^^^^^^^^^^^^^^^[email protected]@@@@
@@@@@#~~~~!Y~~~~~~~~~!?555?~~~7555557~J55Y!?555555555Y55Y555J5555?^^^^^^^^^^~~^^^[email protected]@@@@
@@@@@@?~~~~J?~~~~~~~~~~7JY?!~~!!!!7J?!!J55Y!7Y5555555555Y555555Y57^^^^^^^^^^^^^^^[email protected]@@@@@
@@@@@@B!~~~!5!~!!!!!!!!!!!!!!!!!!!!!?7!!J55Y7!J5555555555YJYYYYY57^^^^^^^^^^^^^^^^[email protected]@@@@@
@@@@@@@5~!!!JY!!!!!!!!!!!!!!!!!!!!!!!!!!!J555?!!7?JJYJJY5!^J5YYY5!^^^^^^^^^^^^^^^^^[email protected]@@@@@@
@@@@@@@&?!!!!YJ!!!!!!!!!!!!!!!!!!!!!!!!!!!7Y555J?!~~~~~J5YJYYYYY5~^^^^^^^^^^^^^^^^^^~~~~~~!!!!!!!!!!!!!!!JY!!!!J&@@@@@@@
@@@@@@@@B7!777YJ!777777777777!!!!!!!!!!!!!~~!7J5555YYYY5Y55Y5YYY5~^^^^^^^^^^^^^^^^^^^~~~~~~~!!!!!!!!!!!!?Y!!!!?&@@@@@@@@
@@@@@@@@@B77777YJ7777777777777!!!!!!!!!~~~~~!7Y5555555YYJJJJJJJYJ~^^^^^^^^^^^^^^^^^^^~~~~~~~!!!!!!!!!!!JY!!!!7#@@@@@@@@@
@@@@@@@@@@B?7777YY77777777777!!!!!!!!!~~~~~~~!7???77!!~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~!!!!!!!JJ!!!!?#@@@@@@@@@@
@@@@@@@@@@@#?!77!JYJ?777!!!!!!!!!!!!!~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^~~~~~~~~~~~~!!!7Y?!!!!?#@@@@@@@@@@@
@@@@@@@@@@@@&Y!!!!75PP55YJ?7!!!!!!!~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^~~!7777???777??J???77!~~~~~!?J7!!!!Y&@@@@@@@@@@@@
@@@@@@@@@@@@@@G7!!!!?5P55P55Y7!!!!~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^~!?JJY7!!~~!J5!^[email protected]@@@@@@@@@@@@@
@@@@@@@@@@@@@@@#Y!!!!!J5P55555Y?7!~~~~~~~~~~~~~~~~^^^^^^^^^^^^^!7JY55YY5J~^^^^!Y~~~~~J5Y7777??J55J!~!~!J&@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@G?!!!!!J5P555555Y?!~~~~~~~~~~~~~~~^^^^^^^^^~7YYY?7!!~~7YY!^^^^[email protected]@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@G?!~!!!?5PP555555Y?7!~~~~~~~~~~~~~^^^^^^~??!~^^^^^^^^[email protected]@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@GJ!!!!!7J5PP555555YJ7!!~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^!7?77??7!~~~!?J?7!~~~!JG&@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@B57!!!!7?Y5PP5555555YYJ?7!~~~~~~^^^^^^^^^^^^^^^^^^^^~~~~~~~~~7?J?7!~~~~7Y#@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&GY7!!!!7?JY5PPP55555555YJ?7!~~^^^^^^^^^^^^^^^^^^^~~~~!7?JJ?7!~~~~!JG&@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@&BY?777!!7?JY55PPP5555555YYYJ??~^^^^^^^^^^^^~~!7?JJ?77!~~~~~!YG&@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#PY?7!!!!!!77?JY5Y555P5JJY5J!!!!!!777?????77!!~~~~~~!J5B&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#G5J7!~~~~~~~~~!!777777777777!!!~~^^^^^^^~~!7JPB&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#GPY?7!!~~^^~~~^^^^^^^^^^^^^^^~~!7Y5G#&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&##BP5555YJ???JJYY55YPGB&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                                                                            
                                                                            
                      ________                   ___   ____                                       
                      `MMMMMMMb.                 `MM  6MMMMb\                                     
                       MM    `Mb                  MM 6M'    `                                     
                       MM     MM     ___      ____MM MM       ____    _    ___    ___    __ ____  
                       MM     MM   6MMMMb    6MMMMMM YM.      `MM(   ,M.   )M'  6MMMMb   `M6MMMMb 
                       MM    .M9  8M'  `Mb  6M'  `MM  YMMMMb   `Mb   dMb   d'  8M'  `Mb   MM'  `Mb
                       MMMMMMM9'      ,oMM  MM    MM      `Mb   YM. ,PYM. ,P       ,oMM   MM    MM
                       MM  \M\    ,6MM9'MM  MM    MM       MM   `Mb d'`Mb d'   ,6MM9'MM   MM    MM
                       MM   \M\   MM'   MM  MM    MM       MM    YM,P  YM,P    MM'   MM   MM    MM
                       MM    \M\  MM.  ,MM  YM.  ,MM L    ,M9    `MM'  `MM'    MM.  ,MM   MM.  ,M9
                      _MM_    \M\_`YMMM9'Yb. YMMMMMM_MYMMMM9      YP    YP     `YMMM9'Yb. MMYMMM9 
                                                                                          MM      
                                                                                          MM      
                                                                                         _MM_     

*/

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ERC721TokenReceiver } from "lib/solmate/src/tokens/ERC721.sol";
import { Owned } from "lib/solmate/src/auth/Owned.sol";
import { ERC20 } from "lib/solmate/src/tokens/ERC20.sol";

import { LSSVMPairMissingEnumerableERC20 } from "lib/lssvm/src/LSSVMPairMissingEnumerableERC20.sol";
import { LSSVMPairFactory } from "lib/lssvm/src/LSSVMPairFactory.sol";

import { FeeBondingERC20 } from "./FeeBondingERC20.sol";

/**
 * @notice General overview:
 *
 * RadPoolERC20 is a contract that provides decentralized liquidity for a single Sudoswap pool.
 *
 * LP fee farming works by LP'ing into a shared xyk curve sudo pool and also locking up LP
 * tokens for a fixed bond duration, yield farming the fees
 * generated from the sudoswap pool. Fees are distributed pro rata based on the amount already staked and your yield boost.
 *
 * Credit to Wheyfus Anonymous for inspiration.
 *
 * Thanks for reading, Radbro.
 *
 * @author 10xdegen
 */
contract RadPoolERC20 is FeeBondingERC20, Owned, ERC721TokenReceiver {
    // sudo pair address
    LSSVMPairMissingEnumerableERC20 public pair;

    // nft address
    IERC721 public nft;

    /// @notice The withdrawl fee, in basis points. (1e18 = 100%)
    uint256 public withdrawalFee;

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

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        string memory nftName,
        string memory nftSymbol,
        uint256 _withdrawalFee
    ) FeeBondingERC20(tokenName, tokenSymbol, nftName, nftSymbol) Owned(msg.sender) {
        withdrawalFee = _withdrawalFee;
    }

    /**
     * @notice Sets the sudoswap pool address.
     * @param _pair The sudoswap pool.
     */
    function setPair(address payable _pair) public onlyOwner {
        require(address(pair) == address(0), "Pair already set");

        pair = LSSVMPairMissingEnumerableERC20(_pair);
        nft = pair.nft();
        _setPair(_pair);
    }

    /**
     * @notice Sets the withdrawl fee.
     * @param _withdrawalFee The withdrawl fee.
     */
    function setWithdrawalFee(uint256 _withdrawalFee) public onlyOwner {
        withdrawalFee = _withdrawalFee;
    }

    /**
     * @notice Sets the tokenURI provider.
     * @param _tokenURIProvider The tokenURI provider of the BondingNFT.
     */
    function setTokenURIProvider(address _tokenURIProvider) public onlyOwner {
        _setTokenURIProvider(_tokenURIProvider);
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
    function addLiquidity(
        uint256[] calldata tokenIds,
        uint256 minPrice,
        uint256 maxPrice
    ) public nonReentrant returns (uint256 shares) {
        // check current price is in between min and max
        uint256 _tokenReserves = tokenReserves();
        uint256 _nftReserves = nftReserves();
        uint256 _price = _tokenReserves > 0 && _nftReserves > 0 ? _tokenReserves / _nftReserves : minPrice;

        require(_price <= maxPrice && _price >= minPrice, "Price slippage");

        uint256 cost = _price * tokenIds.length;
        // update sudoswap reserves
        _updateReserves(_tokenReserves + cost, _nftReserves + tokenIds.length);

        // mint shares to sender
        uint256 _totalSupply = totalSupply; // saves extra SLOAD
        shares = _totalSupply == 0
            ? cost * tokenIds.length
            : Math.min((_totalSupply * cost) / _tokenReserves, (_totalSupply * tokenIds.length) / _nftReserves);
        _mint(msg.sender, shares);

        // deposit tokens to sudoswap pool
        for (uint256 i = 0; i < tokenIds.length; ) {
            nft.safeTransferFrom(msg.sender, address(pair), tokenIds[i]);

            unchecked {
                i++;
            }
        }

        // deposit tokens to sudoswap pool
        feeToken.transferFrom(msg.sender, address(pair), cost);

        emit AddLiquidity(cost, tokenIds.length, shares);
    }

    /**
     * @notice Removes liquidity from the shared sudoswap pool and burns lp tokens.
     * @dev Updates the sudo reserves.
     * @param tokenIds The tokenIds of the nfts to remove from the sudoswap pool.
     * @param minPrice The min price to remove the lp at.
     * @param maxPrice The max price to remove lp at.
     */
    function removeLiquidity(uint256[] calldata tokenIds, uint256 minPrice, uint256 maxPrice) public nonReentrant {
        // check current price is in between min and max
        uint256 _price = price();
        require(_price <= maxPrice && _price >= minPrice, "Price slippage");

        // update sudoswap reserves
        uint256 _tokenReserves = tokenReserves();
        uint256 _nftReserves = nftReserves();
        uint256 tokenAmount = (_tokenReserves * tokenIds.length) / _nftReserves;
        uint256 _updateTokenReserves = _tokenReserves - tokenAmount;
        _updateReserves(_updateTokenReserves, _nftReserves - tokenIds.length);

        // burn shares
        uint256 _totalSupply = totalSupply;
        uint256 shares = (_totalSupply * tokenIds.length) / _nftReserves;

        require(shares <= balanceOf[msg.sender], "Insufficient balance");
        _burn(msg.sender, shares);

        // charge fee except for the final withdrawal
        if (_updateTokenReserves > 0) {
            uint256 fee = (tokenAmount * withdrawalFee) / 1e18;
            tokenAmount -= fee;
        }

        // withdraw liquidity
        pair.withdrawERC20(feeToken, tokenAmount);
        pair.withdrawERC721(nft, tokenIds);

        // send nfts to user
        for (uint256 i = 0; i < tokenIds.length; ) {
            nft.safeTransferFrom(address(this), msg.sender, tokenIds[i]);

            unchecked {
                i++;
            }
        }

        // send fee erc20 tokens to user
        feeToken.transfer(msg.sender, tokenAmount);

        emit RemoveLiquidity(tokenAmount, tokenIds.length, shares);
    }

    /**
     * @notice Returns the amount of liquidity removed liquidity from the sudoswap pool for a given amount of burned lp tokens.
     * @param shares The amount of shares to burn.
     * @return tokenAmount The amount of eth that will be removed.
     * @return nftAmount The amount of nfts that will be removed.
     */
    function getRemoveLiquidityQuote(uint256 shares) public view returns (uint256 tokenAmount, uint256 nftAmount) {
        uint256 _totalSupply = totalSupply; // saves extra SLOAD
        uint256 _tokenReserves = tokenReserves();
        uint256 _nftReserves = nftReserves();
        tokenAmount = (_tokenReserves * shares) / _totalSupply;
        nftAmount = (_nftReserves * shares) / _totalSupply;
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
     * @notice Wrapper around addLiquidity() and feeStake()
     * @param tokenIds The tokenIds of the nfts to send to the sudoswap pool.
     * @param minPrice The min price to lp at.
     * @param maxPrice The max price to lp at.
     * @param termIndex Index into the terms array which tells how long to stake for.
     * @return bondId The tokenId of the bond nft that was minted.
     */
    function addLiquidityAndFeeStake(
        uint256[] calldata tokenIds,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 termIndex
    ) public payable returns (uint256 bondId) {
        uint256 shares = addLiquidity(tokenIds, minPrice, maxPrice);

        bondId = feeStake(uint128(shares), termIndex);
    }

    /**
     * @notice Wrapper around removeLiquidity() and feeUnstake()
     * @param tokenIds The tokenIds of the nfts to remove from the sudoswap pool.
     * @param minPrice The min price to remove the lp at.
     * @param maxPrice The max price to remove lp at.
     * @param bondId The tokenId of the bond nft to unstake.
     */
    function removeLiquidityAndFeeUnstake(
        uint256[] calldata tokenIds,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 bondId
    ) public {
        feeUnstake(bondId);
        removeLiquidity(tokenIds, minPrice, maxPrice);
    }
}