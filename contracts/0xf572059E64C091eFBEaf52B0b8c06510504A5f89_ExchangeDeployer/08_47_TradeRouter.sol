//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../external/IERC677Receiver.sol";
import "../external/IWETH9.sol";
import "./interfaces/IExchangeLedger.sol";
import "./TokenVault.sol";
import "../lib/Utils.sol";

/// @title The outward facing API of the trading functions of the exchange.
/// This contract has a single responsibility to deal with ERC20/ETH. This way the `ExchangeLedger`
/// code does not contain any code related to ERC20 and only deals with abstract balances.
/// The benefits of this design are
/// 1) The code that actually touches the valuables of users is simple, verifiable and
///    non-upgradeable. Making it easy to audit and safe to infinite approve.
/// 2) We can easily specialize the API for important special cases (close) without adding
///    noise to more complicated `ExchangeLedger` code. On some L2's (Arbitrum) tx cost is dominated by
///    calldata and specializing important use cases can save a significant amount on tx cost.
/// 3) Easy "view" function for changePosition. By calling the exchange ledger (using callstatic) from
///    this address, the frontend can see the result of potential trade without needing approval
///    for the necessary funds.
/// 4) Easy testability of different components. The exchange logic can be tested without the
///    need of tests to setup ERC20's and liquidity.
contract TradeRouter is Ownable, EIP712, IERC677Receiver, GitCommitHash {
    using SafeERC20 for IERC20;

    IWETH9 public immutable wethToken;
    IExchangeLedger public immutable exchangeLedger;
    IERC20 public immutable stableToken;
    IERC20 public immutable assetToken;
    TokenVault public immutable tokenVault;
    IOracle public oracle;

    /// @notice Keeps track of the nonces used by each trader that interacted with the contract using
    /// changePositionOnBehalfOf. Users can get a new nonce to use in the signature of their message by calling
    /// nonce(userAddress).
    mapping(address => uint256) public nonce;

    /// @notice Struct to be used together with an ERC677 transferAndCall to pass data to the onTokenTransfer function
    /// in this contract. Note that this struct only contains deltaAsset and stableBound, since the deltaStable comes as
    /// the `amount` transferred in transferAndCall.
    struct ChangePositionInputData {
        int256 deltaAsset;
        int256 stableBound;
    }

    /// @notice Emitted when trader's position changed (except if it is the result of a liquidation).
    event TraderPositionChanged(
        address indexed trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound
    );

    /// @notice Emitted when a `trader` was successfully liquidated by a `liquidator`.
    event TraderLiquidated(address indexed trader, address indexed liquidator);

    /// @notice Emitted when payments to different actors are successfully done.
    event PayoutsTransferred(IExchangeLedger.Payout[] payouts);

    /// @notice Emitted when the oracle address changes.
    event OracleChanged(address oldOracle, address newOracle);

    /// @param _exchangeLedger An instance of IExchangeLedger that will trust this TradeRouter.
    /// @param _wethToken Address of WETH token.
    /// @param _tokenVault The TokenVault that will store the tokens for this TradeRouter. TokenVault needs trust this
    /// contract.
    /// @param _oracle An instance of IOracle to use for pricing in liquidations and change position.
    /// @param _assetToken ERC20 that represents the "asset" in the exchange.
    /// @param _stableToken ERC20 that represents the "stable" in the exchange.
    constructor(
        address _exchangeLedger,
        address _wethToken,
        address _tokenVault,
        address _oracle,
        address _assetToken,
        address _stableToken
    ) EIP712("Futureswap TradeRouter", "1") {
        exchangeLedger = IExchangeLedger(FsUtils.nonNull(_exchangeLedger));
        wethToken = IWETH9(FsUtils.nonNull(_wethToken));
        assetToken = IERC20(FsUtils.nonNull(_assetToken));
        stableToken = IERC20(FsUtils.nonNull(_stableToken));
        tokenVault = TokenVault(FsUtils.nonNull(_tokenVault));
        oracle = IOracle(FsUtils.nonNull(_oracle));
    }

    /// @notice Updates the oracle the TokenRouter uses for trades, can only be performed
    /// by the voting executor.
    function setOracle(address _oracle) external onlyOwner {
        if (address(oracle) == _oracle) {
            return;
        }
        address oldOracle = address(oracle);
        oracle = IOracle(FsUtils.nonNull(_oracle));
        emit OracleChanged(oldOracle, _oracle);
    }

    /// @notice Gets the asset price from the oracle associated to this contract.
    function getPrice() external view returns (int256) {
        return oracle.getPrice(address(assetToken));
    }

    /// @notice Allow ETH to be sent to this contract for unwrapping WETH only.
    receive() external payable {
        require(msg.sender == address(wethToken), "Wrong sender");
    }

    /// @notice Changes a trader's position.
    /// @param deltaAsset  The amount of asset the position should be changed by.
    /// @param deltaStable The amount of stable to change the position by
    /// Positive values will add stable to the position and move stable token from the trader into the TokenVault.
    /// Negative values will remove stable from the position and send the trader tokens from the TokenVault.
    /// @param stableBound The maximum/minimum amount of stable that the user is willing to pay/receive for the
    /// deltaAsset change
    /// If the user is buying asset (deltaAsset > 0), they will have to choose a maximum negative number that they are
    /// going to be in debt for.
    /// If the user is selling asset (deltaAsset < 0), they will have to choose a minimum positive number of stable that
    /// they wants to be credited with.
    function changePosition(
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound
    ) public returns (bytes memory) {
        address trader = msg.sender;
        if (deltaStable > 0) {
            // slither-disable-next-line safe-cast
            stableToken.safeTransferFrom(trader, address(tokenVault), uint256(deltaStable));
        }
        return
            doChangePosition(
                trader,
                deltaAsset,
                deltaStable,
                stableBound,
                false /* useETH */
            );
    }

    /// @notice Changes a trader's position, same as `changePosition`, but using a compacted data representation to save
    /// gas cost.
    /// @param packedData Contains `deltaAsset`, `deltaStable` and `stableBound` packed in the following format:
    /// 112 bits for deltaAsset (signed) and 112 bits for deltaStable (signed)
    /// 8 bits for stableBound exponent (unsigned) and 24 bits for stableBound mantissa (signed)
    /// stableBound is obtained by doing mantissa * (2 ** exponent).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionPacked(uint256 packedData) external returns (bytes memory) {
        (int256 deltaAsset, int256 deltaStable, int256 stableBound) = unpack(packedData);
        return changePosition(deltaAsset, deltaStable, stableBound);
    }

    /// @notice Closes the trader's current position.
    /// @dev This helper function is useful to save gas in L2 chains where call data is the dominating cost factor (for
    /// example, Arbitrum).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function closePosition() external returns (bytes memory) {
        return changePosition(0, 0, 0);
    }

    /// @notice Changes a trader's position, using the IERC677 transferAndCall flow on the stable token contract.
    /// @param from This is the sender of the transferAndCall transaction and is used as the trader.
    /// @param amount This is the amount transferred during transferAndCall and is used as the deltaStable.
    /// @param data Needs to be an encoded version of `ChangePositionInputData`.
    function onTokenTransfer(
        address from,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(msg.sender == address(stableToken), "Wrong token");
        // slither-disable-next-line safe-cast
        require(amount <= uint256(type(int256).max), "`amount` is over int256.max");

        ChangePositionInputData memory cpid = abi.decode(data, (ChangePositionInputData));
        stableToken.safeTransfer(address(tokenVault), amount);

        // We checked that `amount` fits into `int256` above.
        // slither-disable-next-line safe-cast
        doChangePosition(
            from,
            cpid.deltaAsset,
            int256(amount),
            cpid.stableBound,
            false /* useETH */
        );
        return true;
    }

    /// @notice Changes a trader's position, same as `changePosition`, but allows users to pay their collateral in ETH
    /// instead of WETH (only valid for exchanges that use WETH as collateral).
    /// The value in `deltaStable` needs to match the amount of ETH sent in the transaction.
    /// @dev The ETH received is converted to WETH and stored into the TokenVault. The whole system operates with ERC20,
    /// not ETH.
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionWithEth(
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound
    ) public payable returns (bytes memory) {
        require(stableToken == wethToken, "Exchange doesn't accept ETH");
        address trader = msg.sender;
        if (deltaStable > 0) {
            uint256 amount = msg.value;
            // slither-disable-next-line safe-cast
            require(amount == uint256(deltaStable), "msg.value doesn't match deltaStable");
            wethToken.deposit{ value: amount }();
            IERC20(wethToken).safeTransfer(address(tokenVault), amount);
        } else {
            require(msg.value == 0, "msg.value doesn't match deltaStable");
        }
        return
            doChangePosition(
                trader,
                deltaAsset,
                deltaStable,
                stableBound,
                true /* useETH */
            );
    }

    /// @notice Changes a trader's position, same as `changePositionWithEth`, but using a compacted data representation
    /// to save gas cost.
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionWithEthPacked(uint256 packed) external payable returns (bytes memory) {
        (int256 deltaAsset, int256 deltaStable, int256 stableBound) = unpack(packed);
        return changePositionWithEth(deltaAsset, deltaStable, stableBound);
    }

    /// @notice Closes the trader's current position, and returns ETH instead of WETH in exchanges that use WETH as
    /// collateral.
    /// @dev This helper function is useful to save gas in L2 chains where call data is the dominating cost factor (for
    /// example, Arbitrum).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function closePositionWithEth() external payable returns (bytes memory) {
        return changePositionWithEth(0, 0, 0);
    }

    /// @notice Change's a trader's position, same as in changePosition, but can be called by any arbitrary contract
    /// that the trader trusts.
    /// @param trader The trader to change position to.
    /// @param deltaAsset see deltaAsset in `changePosition`.
    /// @param deltaStable see deltaStable in `changePosition`.
    /// @param stableBound see stableBound in `changePosition`.
    /// @param extraHash Can be used to verify extra data from the calling contract.
    /// @param signature A signature created using `trader` private keys. The signed message needs to have the following
    /// data:
    ///    address of the trader which is signing the message.
    ///    deltaAsset, deltaStable, stableBound (parameters that determine the trade).
    ///    extraHash (the same as the parameter passed above).
    ///    nonce: unique number used to ensure that the message can't be replayed. Can be obtained by calling
    ///           `nonce(trader)` in this contract.
    ///    address of the sender (to ensure that only the contract authorized by the trader can execute this).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function changePositionOnBehalfOf(
        address trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound,
        bytes32 extraHash,
        bytes calldata signature
    ) external returns (bytes memory) {
        // Capture trader's address at top of stack to prevent stack to deep.
        address traderTmp = trader;

        // _hashTypedDataV4 combines the hash of this message with a hash specific to this
        // contract and chain, such that this message cannot be replayed.
        bytes32 digest =
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "changePositionOnBehalfOf(address trader,int256 deltaAsset,int256 deltaStable,int256 stableBound,bytes32 extraHash,uint256 nonce,address sender)"
                        ),
                        traderTmp,
                        deltaAsset,
                        deltaStable,
                        stableBound,
                        // extraHash can be used to verify extra data from the calling contract.
                        extraHash,
                        // Use a unique nonce to ensure that the message cannot be replayed.
                        nonce[traderTmp],
                        // Including msg.sender ensures only the signer authorized Ethereum account can execute.
                        msg.sender
                    )
                )
            );
        address signer = ECDSA.recover(digest, signature);
        require(signer == trader, "Not signed by trader");
        nonce[trader]++;

        if (deltaStable > 0) {
            // slither-disable-next-line safe-cast
            stableToken.safeTransferFrom(trader, address(tokenVault), uint256(deltaStable));
        }
        return
            doChangePosition(
                trader,
                deltaAsset,
                deltaStable,
                stableBound,
                false /* useETH */
            );
    }

    /// @notice Liquidates `trader` if its position is liquidatable and pays out to the different actors involved (the
    /// liquidator, the pool and the trader).
    /// @return Encoded IExchangeLedger.ChangePositionData.
    function liquidate(address trader) external returns (bytes memory) {
        address liquidator = msg.sender;
        int256 oraclePrice = oracle.getPrice(address(assetToken));
        (IExchangeLedger.Payout[] memory payouts, bytes memory changePositionData) =
            exchangeLedger.liquidate(trader, liquidator, oraclePrice, block.timestamp);
        transferPayouts(
            payouts,
            false /* useETH */
        );
        emit TraderLiquidated(trader, liquidator);
        return changePositionData;
    }

    function doChangePosition(
        address trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound,
        bool useETH
    ) private returns (bytes memory) {
        int256 oraclePrice = oracle.getPrice(address(assetToken));
        (IExchangeLedger.Payout[] memory payouts, bytes memory changePositionData) =
            exchangeLedger.changePosition(
                trader,
                deltaAsset,
                deltaStable,
                stableBound,
                oraclePrice,
                block.timestamp
            );
        transferPayouts(payouts, useETH);
        emit TraderPositionChanged(trader, deltaAsset, deltaStable, stableBound);
        return changePositionData;
    }

    function transferPayouts(IExchangeLedger.Payout[] memory payouts, bool useETH) private {
        // If the TokenVault doesn't have enough `stableToken` to make all the payments, the whole transaction reverts.
        // This can only happen if (1) There is a *bug* in the accounting (2) Liquidations don't happen on time and
        // bankrupt trades deplete the TokenVault (this is highly unlikely).
        for (uint256 i = 0; i < payouts.length; i++) {
            IExchangeLedger.Payout memory payout = payouts[i];
            if (payout.to == address(0) || payout.amount == 0) {
                continue;
            }

            if (useETH && stableToken == wethToken && payout.to == msg.sender) {
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                tokenVault.transfer(address(this), address(wethToken), payout.amount);
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                wethToken.withdraw(payout.amount);
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                Address.sendValue(payable(payout.to), payout.amount);
            } else {
                // `payouts.length` is actually limited to 3.  It is generate by `recordPayouts` in
                // `ExchangeLedger`.
                // slither-disable-next-line calls-loop
                tokenVault.transfer(payout.to, address(stableToken), payout.amount);
            }
        }

        emit PayoutsTransferred(payouts);
    }

    // public for testing
    function unpack(uint256 packed)
        public
        pure
        returns (
            int256 deltaAsset,
            int256 deltaStable,
            int256 stableBound
        )
    {
        // slither-disable-next-line safe-cast
        deltaAsset = int112(uint112(packed));
        // slither-disable-next-line safe-cast
        deltaStable = int112(uint112(packed >> 112));
        // slither-disable-next-line safe-cast
        uint8 stableBoundExp = uint8(packed >> 224);
        // slither-disable-next-line safe-cast
        int256 stableBoundMantissa = int24(uint24(packed >> 232));
        stableBound = stableBoundMantissa << stableBoundExp;
    }
}