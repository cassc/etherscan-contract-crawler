// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "contracts/interfaces/IBridgeRouter.sol";
import "contracts/utils/Admin.sol";
import "contracts/utils/Mutex.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableDistribution.sol";
import "contracts/interfaces/IUtilityToken.sol";
import "contracts/libraries/errors/UtilityTokenErrors.sol";
import "contracts/libraries/math/Sigmoid.sol";

/// @custom:salt ALCB
/// @custom:deploy-type deployCreateAndRegister
/// @custom:deploy-group alcb
/// @custom:deploy-group-index 0
contract ALCB is
    IUtilityToken,
    ERC20,
    Mutex,
    MagicEthTransfer,
    EthSafeTransfer,
    Sigmoid,
    ImmutableFactory,
    ImmutableDistribution
{
    using Address for address;

    // multiply factor for the selling/minting bonding curve
    uint256 internal constant _MARKET_SPREAD = 4;

    // Address of the central bridge router contract
    address internal immutable _centralBridgeRouter;

    // Balance in ether that is hold in the contract after minting and burning
    uint256 internal _poolBalance;

    // Monotonically increasing variable to track the ALCBs deposits.
    uint256 internal _depositID;

    // Total amount of ALCBs that were deposited in the AliceNet chain. The
    // ALCBs deposited in the AliceNet are burned by this contract.
    uint256 internal _totalDeposited;

    // Tracks the amount of each deposit. Key is deposit id, value is amount
    // deposited.
    mapping(uint256 => Deposit) internal _deposits;

    // mapping to store allowed account types
    mapping(uint8 => bool) internal _accountTypes;

    /**
     * @notice Event emitted when a deposit is received
     */
    event DepositReceived(
        uint256 indexed depositID,
        uint8 indexed accountType,
        address indexed depositor,
        uint256 amount
    );

    constructor(
        address centralBridgeRouterAddress_
    ) ERC20("AliceNet Utility Token", "ALCB") ImmutableFactory(msg.sender) ImmutableDistribution() {
        if (centralBridgeRouterAddress_ == address(0)) {
            revert UtilityTokenErrors.CannotSetRouterToZeroAddress();
        }
        // initializing allowed account types: 1 for secp256k1 and 2 for BLS
        _accountTypes[1] = true;
        _accountTypes[2] = true;
        _centralBridgeRouter = centralBridgeRouterAddress_;
        _virtualDeposit(1, 0xba7809A4114eEF598132461f3202b5013e834CD5, 500000000000);
    }

    /**
     * @notice function to allow factory to add/set the allowed account types supported by AliceNet
     * blockchain.
     * @param accountType_ uint8 account type id to be added
     * @param allowed_ bool if a type should be enabled/disabled
     */
    function setAccountType(uint8 accountType_, bool allowed_) public onlyFactory {
        _accountTypes[accountType_] = allowed_;
    }

    /**
     * @notice Distributes the yields of the ALCB sale to all stakeholders
     * @return true if the method succeeded
     * */
    function distribute() public returns (bool) {
        return _distribute();
    }

    /**
     * @notice Deposits a ALCB amount into the AliceNet blockchain. The ALCBs amount is deducted
     * from the sender and it is burned by this contract. The created deposit Id is owned by the
     * `to_` address.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param amount_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function deposit(uint8 accountType_, address to_, uint256 amount_) public returns (uint256) {
        return _deposit(accountType_, to_, amount_);
    }

    /**
     * @notice Allows deposits to be minted in a virtual manner and sent to the AliceNet chain by
     * simply emitting a Deposit event without actually minting or burning any tokens, must only be
     * called by _admin.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param amount_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function virtualMintDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) public onlyFactory returns (uint256) {
        return _virtualDeposit(accountType_, to_, amount_);
    }

    /**
     * @notice Allows deposits to be minted and sent to the AliceNet chain without actually minting
     * or burning any ALCBs. This function receives ether and converts them directly into ALCB
     * and then deposit them into the AliceNet chain. This function has the same effect as calling
     * mint (creating the tokens) + deposit (burning the tokens) functions but it costs less gas.
     * @param accountType_ The type of account the to_ address must be equivalent with ( 1 for Eth native, 2 for BN )
     * @param to_ The address of the account that will own the deposit
     * @param minBTK_ The amount of ALCBs to be deposited
     * @return The deposit ID of the deposit created
     */
    function mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_
    ) public payable returns (uint256) {
        return _mintDeposit(accountType_, to_, minBTK_, msg.value);
    }

    /**
     * @notice Mints ALCB. This function receives ether in the transaction and converts them into
     * ALCB using a bonding price curve.
     * @param minBTK_ Minimum amount of ALCB that you wish to mint given an amount of ether. If
     * its not possible to mint the desired amount with the current price in the bonding curve, the
     * transaction is reverted. If the minBTK_ is met, the whole amount of ether sent will be
     * converted in ALCB.
     * @return numBTK the number of ALCB minted
     */
    function mint(uint256 minBTK_) public payable returns (uint256 numBTK) {
        numBTK = _mint(msg.sender, msg.value, minBTK_);
        return numBTK;
    }

    /**
     * @notice Mints ALCB. This function receives ether in the transaction and converts them into
     * ALCB using a bonding price curve.
     * @param to_ The account to where the tokens will be minted
     * @param minBTK_ Minimum amount of ALCB that you wish to mint given an
     * amount of ether. If its not possible to mint the desired amount with the
     * current price in the bonding curve, the transaction is reverted. If the
     * minBTK_ is met, the whole amount of ether sent will be converted in ALCB.
     * @return numBTK the number of ALCB minted
     */
    function mintTo(address to_, uint256 minBTK_) public payable returns (uint256 numBTK) {
        numBTK = _mint(to_, msg.value, minBTK_);
        return numBTK;
    }

    /**
     * @notice Burn the tokens without sending ether back to user as the normal burn
     * function. The generated ether will be distributed in the distribute method. This function can
     * be used to charge ALCBs fees in other systems.
     * @param numBTK_ the number of ALCB to be burned
     * @return true if the burn succeeded
     */
    function destroyTokens(uint256 numBTK_) public returns (bool) {
        _destroyTokens(msg.sender, numBTK_);
        return true;
    }

    /**
     * @notice Deposits arbitrary tokens in the bridge contracts. This function is an entry
     * point to deposit tokens (ERC20, ERC721, ERC1155) in the bridges and have
     * access to them in the side chain. This function will deduce from the user's
     * balance the corresponding amount of fees to deposit the tokens. The user has
     * the option to pay the fees in ALCB or Ether. If any ether is sent, the
     * function will deduce the fee amount and refund any extra amount. If no ether
     * is sent, the function will deduce the amount of ALCB corresponding to the
     * fees directly from the user's balance.
     * @param routerVersion_ The bridge version where to deposit the tokens.
     * @param data_ Encoded data necessary to deposit the arbitrary tokens in the bridges.
     * */
    function depositTokensOnBridges(uint8 routerVersion_, bytes calldata data_) public payable {
        //forward call to router
        uint256 alcbFee = IBridgeRouter(_centralBridgeRouter).routeDeposit(
            msg.sender,
            routerVersion_,
            data_
        );
        if (msg.value > 0) {
            uint256 ethFee = _getEthToMintTokens(totalSupply(), alcbFee);
            if (ethFee > msg.value) {
                revert UtilityTokenErrors.InsufficientFee(msg.value, ethFee);
            }
            uint256 refund;
            unchecked {
                refund = msg.value - ethFee;
            }
            if (refund > 0) {
                _safeTransferEth(msg.sender, refund);
            }
            return;
        }
        _destroyTokens(msg.sender, alcbFee);
    }

    /**
     * @notice Burn ALCB. This function sends ether corresponding to the amount of ALCBs being
     * burned using a bonding price curve.
     * @param amount_ The amount of ALCB being burned
     * @param minEth_ Minimum amount ether that you expect to receive given the
     * amount of ALCB being burned. If the amount of ALCB being burned
     * worth less than this amount the transaction is reverted.
     * @return numEth The number of ether being received
     * */
    function burn(uint256 amount_, uint256 minEth_) public returns (uint256 numEth) {
        numEth = _burn(msg.sender, msg.sender, amount_, minEth_);
        return numEth;
    }

    /**
     * @notice Burn ALCBs and send the ether received to an other account. This
     * function sends ether corresponding to the amount of ALCBs being
     * burned using a bonding price curve.
     * @param to_ The account to where the ether from the burning will be send
     * @param amount_ The amount of ALCBs being burned
     * @param minEth_ Minimum amount ether that you expect to receive given the
     * amount of ALCBs being burned. If the amount of ALCBs being burned
     * worth less than this amount the transaction is reverted.
     * @return numEth the number of ether being received
     * */
    function burnTo(address to_, uint256 amount_, uint256 minEth_) public returns (uint256 numEth) {
        numEth = _burn(msg.sender, to_, amount_, minEth_);
        return numEth;
    }

    /**
     * @notice Gets the address to the central router for the bridge system
     * @return The address to the central router
     */
    function getCentralBridgeRouterAddress() public view returns (address) {
        return _centralBridgeRouter;
    }

    /**
     * @notice Gets the amount that can be distributed as profits to the stakeholders contracts.
     * @return The amount that can be distributed as yield
     */
    function getYield() public view returns (uint256) {
        return address(this).balance - _poolBalance;
    }

    /**
     * @notice Gets the latest deposit ID emitted.
     * @return The latest deposit ID emitted
     */
    function getDepositID() public view returns (uint256) {
        return _depositID;
    }

    /**
     * @notice Gets the pool balance in ether.
     * @return The pool balance in ether
     */
    function getPoolBalance() public view returns (uint256) {
        return _poolBalance;
    }

    /**
     * @notice Gets the total amount of ALCBs that were deposited in the AliceNet
     * blockchain. Since ALCBs are burned when deposited, this value will be
     * different from the total supply of ALCBs.
     * @return The total amount of ALCBs that were deposited into the AliceNet chain.
     */
    function getTotalTokensDeposited() public view returns (uint256) {
        return _totalDeposited;
    }

    /**
     * @notice Gets the deposited amount given a depositID.
     * @param depositID The Id of the deposit
     * @return the deposit info given a depositID
     */
    function getDeposit(uint256 depositID) public view returns (Deposit memory) {
        Deposit memory d = _deposits[depositID];
        if (d.account == address(0)) {
            revert UtilityTokenErrors.InvalidDepositId(depositID);
        }

        return d;
    }

    /**
     * @notice Compute how many ether will be necessary to mint an amount of ALCBs in the
     * current state of the contract. Should be used carefully if its being called
     * outside an smart contract transaction, as the bonding curve state can change
     * before a future transaction is sent.
     * @param numBTK_ Amount of ALCBs that we want to convert in ether
     * @return numEth the number of ether necessary to mint an amount of ALCB
     */
    function getLatestEthToMintTokens(uint256 numBTK_) public view returns (uint256 numEth) {
        return _getEthToMintTokens(totalSupply(), numBTK_);
    }

    /**
     * @notice Compute how many ether will be received during a ALCB burn at the current
     * bonding curve state. Should be used carefully if its being called outside an
     * smart contract transaction, as the bonding curve state can change before a
     * future transaction is sent.
     * @param numBTK_ Amount of ALCBs to convert in ether
     * @return numEth the amount of ether will be received during a ALCB burn at the current
     * bonding curve state
     */
    function getLatestEthFromTokensBurn(uint256 numBTK_) public view returns (uint256 numEth) {
        return _tokensToEth(_poolBalance, totalSupply(), numBTK_);
    }

    /**
     * @notice Gets an amount of ALCBs that will be minted at the current state of the
     * bonding curve. Should be used carefully if its being called outside an smart
     * contract transaction, as the bonding curve state can change before a future
     * transaction is sent.
     * @param numEth_ Amount of ether to convert in ALCBs
     * @return the amount of ALCBs that will be minted at the current state of the
     * bonding curve
     * */
    function getLatestMintedTokensFromEth(uint256 numEth_) public view returns (uint256) {
        return _ethToTokens(_poolBalance, numEth_ / _MARKET_SPREAD);
    }

    /**
     * @notice Gets the market spread (difference between the minting and burning bonding
     * curves).
     * @return the market spread (difference between the minting and burning bonding
     * curves).
     * */
    function getMarketSpread() public pure returns (uint256) {
        return _MARKET_SPREAD;
    }

    /**
     * @notice Compute how many ether will be necessary to mint an amount of ALCBs at a
     * certain point in the bonding curve.
     * @param totalSupply_ The total supply of ALCB at a given moment where we
     * want to compute the amount of ether necessary to mint.
     * @param numBTK_ Amount of ALCBs that we want to convert in ether
     * @return numEth the amount ether that will be necessary to mint an amount of ALCBs at a
     * certain point in the bonding curve
     * */
    function getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) public pure returns (uint256 numEth) {
        return _getEthToMintTokens(totalSupply_, numBTK_);
    }

    /**
     * @notice Compute how many ether will be received during a ALCB burn.
     * @param poolBalance_ The pool balance (in ether) at the moment
     * that of the conversion.
     * @param totalSupply_ The total supply of ALCB at the moment
     * that of the conversion.
     * @param numBTK_ Amount of ALCBs to convert in ether
     * @return numEth the ether that will be received during a ALCB burn
     * */
    function getEthFromTokensBurn(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) public pure returns (uint256 numEth) {
        return _tokensToEth(poolBalance_, totalSupply_, numBTK_);
    }

    /**
     * @notice Gets an amount of ALCBs that will be minted at given a point in the bonding
     * curve.
     * @param poolBalance_ The pool balance (in ether) at the moment
     * that of the conversion.
     * @param numEth_ Amount of ether to convert in ALCBs
     * @return the amount of ALCBs that will be minted at given a point in the bonding
     * curve.
     * */
    function getMintedTokensFromEth(
        uint256 poolBalance_,
        uint256 numEth_
    ) public pure returns (uint256) {
        return _ethToTokens(poolBalance_, numEth_ / _MARKET_SPREAD);
    }

    /// Distributes the yields from the ALCB minting to all stake holders.
    function _distribute() internal withLock returns (bool) {
        // make a local copy to save gas
        uint256 poolBalance = _poolBalance;
        // find all value in excess of what is needed in pool
        uint256 excess = address(this).balance - poolBalance;
        if (excess == 0) {
            return true;
        }
        _safeTransferEthWithMagic(IMagicEthTransfer(_distributionAddress()), excess);
        if (address(this).balance < poolBalance) {
            revert UtilityTokenErrors.InvalidBalance(address(this).balance, poolBalance);
        }
        return true;
    }

    // Burn the tokens during deposits without sending ether back to user as the
    // normal burn function. The ether will be distributed in the distribute
    // method.
    function _destroyTokens(address account, uint256 numBTK_) internal returns (bool) {
        if (numBTK_ == 0) {
            revert UtilityTokenErrors.InvalidBurnAmount(numBTK_);
        }
        _poolBalance -= _tokensToEth(_poolBalance, totalSupply(), numBTK_);
        ERC20._burn(account, numBTK_);
        return true;
    }

    // Internal function that does the deposit in the AliceNet Chain, i.e emit the
    // event DepositReceived. All the ALCBs sent to this function are burned.
    function _deposit(uint8 accountType_, address to_, uint256 amount_) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }

        if (amount_ == 0) {
            revert UtilityTokenErrors.DepositAmountZero();
        }

        if (!_destroyTokens(msg.sender, amount_)) {
            revert UtilityTokenErrors.DepositBurnFail(amount_);
        }

        // copying state to save gas
        return _doDepositCommon(accountType_, to_, amount_);
    }

    // does a virtual deposit into the AliceNet Chain without actually minting or
    // burning any token.
    function _virtualDeposit(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }

        if (amount_ == 0) {
            revert UtilityTokenErrors.DepositAmountZero();
        }

        // copying state to save gas
        return _doDepositCommon(accountType_, to_, amount_);
    }

    // Mints a virtual deposit into the AliceNet Chain without actually minting or
    // burning any token. This function converts ether sent in ALCBs.
    function _mintDeposit(
        uint8 accountType_,
        address to_,
        uint256 minBTK_,
        uint256 numEth_
    ) internal returns (uint256) {
        if (to_.isContract()) {
            revert UtilityTokenErrors.ContractsDisallowedDeposits(to_);
        }
        if (numEth_ < _MARKET_SPREAD) {
            revert UtilityTokenErrors.MinimumValueNotMet(numEth_, _MARKET_SPREAD);
        }

        numEth_ = numEth_ / _MARKET_SPREAD;
        uint256 amount_ = _ethToTokens(_poolBalance, numEth_);
        if (amount_ < minBTK_) {
            revert UtilityTokenErrors.InsufficientEth(amount_, minBTK_);
        }

        return _doDepositCommon(accountType_, to_, amount_);
    }

    function _doDepositCommon(
        uint8 accountType_,
        address to_,
        uint256 amount_
    ) internal returns (uint256) {
        if (!_accountTypes[accountType_]) {
            revert UtilityTokenErrors.AccountTypeNotSupported(accountType_);
        }
        uint256 depositID = _depositID + 1;
        _deposits[depositID] = _newDeposit(accountType_, to_, amount_);
        _totalDeposited += amount_;
        _depositID = depositID;
        emit DepositReceived(depositID, accountType_, to_, amount_);
        return depositID;
    }

    // Internal function that mints the ALCB tokens following the bounding
    // price curve.
    function _mint(
        address to_,
        uint256 numEth_,
        uint256 minBTK_
    ) internal returns (uint256 numBTK) {
        if (numEth_ < _MARKET_SPREAD) {
            revert UtilityTokenErrors.MinimumValueNotMet(numEth_, _MARKET_SPREAD);
        }

        numEth_ = numEth_ / _MARKET_SPREAD;
        uint256 poolBalance = _poolBalance;
        numBTK = _ethToTokens(poolBalance, numEth_);
        if (numBTK < minBTK_) {
            revert UtilityTokenErrors.MinimumMintNotMet(numBTK, minBTK_);
        }

        poolBalance += numEth_;
        _poolBalance = poolBalance;
        ERC20._mint(to_, numBTK);
        return numBTK;
    }

    // Internal function that burns the ALCB tokens following the bounding
    // price curve.
    function _burn(
        address from_,
        address to_,
        uint256 numBTK_,
        uint256 minEth_
    ) internal returns (uint256 numEth) {
        if (numBTK_ == 0) {
            revert UtilityTokenErrors.InvalidBurnAmount(numBTK_);
        }

        uint256 poolBalance = _poolBalance;
        numEth = _tokensToEth(poolBalance, totalSupply(), numBTK_);

        if (numEth < minEth_) {
            revert UtilityTokenErrors.MinimumBurnNotMet(numEth, minEth_);
        }

        poolBalance -= numEth;
        _poolBalance = poolBalance;
        ERC20._burn(from_, numBTK_);
        _safeTransferEth(to_, numEth);
        return numEth;
    }

    // Internal function that converts an ether amount into ALCB tokens
    // following the bounding price curve.
    function _ethToTokens(uint256 poolBalance_, uint256 numEth_) internal pure returns (uint256) {
        return _p(poolBalance_ + numEth_) - _p(poolBalance_);
    }

    // Internal function that converts a ALCB amount into ether following the
    // bounding price curve.
    function _tokensToEth(
        uint256 poolBalance_,
        uint256 totalSupply_,
        uint256 numBTK_
    ) internal pure returns (uint256 numEth) {
        if (totalSupply_ < numBTK_) {
            revert UtilityTokenErrors.BurnAmountExceedsSupply(numBTK_, totalSupply_);
        }
        return _min(poolBalance_, _pInverse(totalSupply_) - _pInverse(totalSupply_ - numBTK_));
    }

    // Internal function to compute the amount of ether required to mint an amount
    // of ALCBs. Inverse of the _ethToALCBs function.
    function _getEthToMintTokens(
        uint256 totalSupply_,
        uint256 numBTK_
    ) internal pure returns (uint256 numEth) {
        return (_pInverse(totalSupply_ + numBTK_) - _pInverse(totalSupply_)) * _MARKET_SPREAD;
    }

    function _newDeposit(
        uint8 accountType_,
        address account_,
        uint256 value_
    ) internal pure returns (Deposit memory) {
        Deposit memory d = Deposit(accountType_, account_, value_);
        return d;
    }
}