pragma solidity ^0.5.16;

import "./MTokenAdmin.sol";
import "./MTokenInterfaces.sol";
import "./MtrollerInterface.sol";
import "./ErrorReporter.sol";
import "./compound/Exponential.sol";
import "./compound/InterestRateModel.sol";
import "./open-zeppelin/token/ERC721/IERC721Receiver.sol";
import "./open-zeppelin/token/ERC721/ERC721.sol";
import "./open-zeppelin/token/ERC20/IERC20.sol";
import "./open-zeppelin/introspection/ERC165.sol";

/**
 * @title ERC-721 Token Contract
 * @notice Base for mNFTs
 * @author mmo.finance
 */
contract MERC721TokenAdmin is MTokenAdmin, ERC721("MERC721","MERC721"), MERC721AdminInterface {

    /**
     * @notice Constructs a new MERC721TokenAdmin
     */
    constructor() public MTokenAdmin() {
        implementedSelectors.push(bytes4(keccak256('initialize(address,address,address,address,string,string)')));
        implementedSelectors.push(bytes4(keccak256('redeemAndSell(uint240,uint256,address,bytes)')));
        implementedSelectors.push(bytes4(keccak256('redeem(uint240)')));
        implementedSelectors.push(bytes4(keccak256('redeemUnderlying(uint256)')));
        implementedSelectors.push(bytes4(keccak256('borrow(uint256)')));
        implementedSelectors.push(bytes4(keccak256('name()')));
        implementedSelectors.push(bytes4(keccak256('symbol()')));
        implementedSelectors.push(bytes4(keccak256('tokenURI(uint256)')));
    }

    /**
     * Marker function identifying this contract as "ERC721_MTOKEN" type
     */
    function getTokenType() public pure returns (MTokenIdentifier.MTokenType) {
        return MTokenIdentifier.MTokenType.ERC721_MTOKEN;
    }

    /**
     * @notice Initialize a new ERC-721 MToken money market
     * @dev Since each non-fungible ERC-721 is unique and thus cannot have "reserves" in the conventional sense, we have to set
     * reserveFactorMantissa_ = 0 in the mToken initialisation. Similarly, we have to set protocolSeizeShareMantissa_ = 0 since
     * seizing a NFT asset can only be done in one piece and it cannot be split up to be transferred partly to the protocol.
     * @param underlyingContract_ The contract address of the underlying asset for this MToken
     * @param mtroller_ The address of the Mtroller
     * @param interestRateModel_ The address of the interest rate model
     * @param tokenAuction_ The address of the TokenAuction contract
     * @param name_ EIP-721 name of this MToken
     * @param symbol_ EIP-721 symbol of this MToken
     */
    function initialize(address underlyingContract_,
                MtrollerInterface mtroller_,
                InterestRateModel interestRateModel_,
                TokenAuction tokenAuction_,
                string memory name_,
                string memory symbol_) public {
        MTokenAdmin.initialize(underlyingContract_, mtroller_, interestRateModel_, 0, mantissaOne, 0, name_, symbol_, 18);
        // _registerInterface(this.onERC721Received.selector);
        uint err = _setTokenAuction(tokenAuction_);
        require(err == uint(Error.NO_ERROR), "setting tokenAuction failed");
    }

    /**
     * @notice Sender redeems mToken in exchange for the underlying nft asset. Also exits the mToken's market.
     * Redeem is only possible if after redeeming the owner still has positive overall liquidity (no shortfall),
     * unless the redeem is immediately followed by a sale in the same transaction (when transferHandler != address(0)) and
     * the received sale price is sufficient to cover any such shortfall.
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mToken The mToken to redeem into underlying
     * @param sellPrice In case of redeem followed directly by a sale to another user, this is the (minimum) price to collect from the buyer
     * @param transferHandler If this is nonzero, the redeem is directly followed by a sale, the details of which are handled by a contract at this address (see Mortgage.sol)
     * @param transferParams Call parameters for the transferHandler call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemAndSell(uint240 mToken, uint sellPrice, address payable transferHandler, bytes memory transferParams) public nonReentrant returns (uint) {
        /* Fail if sender not owner */
        if (msg.sender != ownerOf(mToken)) {
            return fail(Error.UNAUTHORIZED, FailureInfo.REDEEM_NOT_OWNER);
        }

        /* Sanity check, this should never revert */
        require(accountTokens[mToken][msg.sender] == oneUnit, "Invalid internal token amount");

        /* Reset the asking price to zero (= "not set") */
        if (askingPrice[mToken] > 0) {
            askingPrice[mToken] = 0;
        }

        /* Redeem / burn the mToken */
        uint err = redeemInternal(mToken, oneUnit, 0, msg.sender, sellPrice, transferHandler, transferParams);
        if (err != uint(Error.NO_ERROR)) {
            return err;
        }

        /////////////////////////
        // EFFECTS & INTERACTIONS
        // (No safe failures beyond this point)

        /* Revert if market cannot be exited */
        err = mtroller.exitMarketOnBehalf(mToken, msg.sender);
        requireNoError(err, "redeem market exit failed");

        /* Burn the ERC-721 specific parts of the mToken */
        _burn(mToken);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Sender redeems mToken in exchange for the underlying nft asset. Also exits the mToken's market.
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mToken The mToken to redeem into underlying
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeem(uint240 mToken) public returns (uint) {
        return redeemAndSell(mToken, 0, address(0), "");
    }

    /**
     * @notice Sender redeems mToken in exchange for the underlying nft asset. Also exits the mToken's market.
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param underlyingID The ID of the underlying nft to be redeemed
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function redeemUnderlying(uint256 underlyingID) external returns (uint) {
        return redeem(mTokenFromUnderlying[underlyingID]);
    }

    /**
      * @notice Sender enters mToken market and borrows NFT assets from the protocol to their own address.
      * @param borrowUnderlyingID The ID of the underlying NFT asset to borrow
      * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
      */
    function borrow(uint256 borrowUnderlyingID) external returns (uint) {
        borrowUnderlyingID;
        /* No NFT borrowing for now */
        return fail(Error.MTROLLER_REJECTION, FailureInfo.BORROW_MTROLLER_REJECTION);
    }

    /**
      * @notice Returns the name of the mToken (contract). For now this is simply the name of the underlying.
      * @return string The name of the mToken.
      */
    function name() external view returns (string memory) {
        return IERC721Metadata(underlyingContract).name();
    }

    /**
      * @notice Returns the symbol of the mToken (contract). For now this is simply the symbol of the underlying.
      * @return string The symbol of the mToken.
      */
    function symbol() external view returns (string memory) {
        return IERC721Metadata(underlyingContract).symbol();
    }

    /**
      * @notice Returns an URI for the given mToken. For now this is simply the URI of the underlying NFT.
      * @param tokenId The mToken whose URI to get.
      * @return string The URI of the mToken.
      */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        require(tokenId <= uint240(-1), "URI query for nonexistent token");
        uint240 mToken = uint240(tokenId);
        return IERC721Metadata(underlyingContract).tokenURI(underlyingIDs[mToken]);
    }


   /*** Safe Token ***/

    /**
     * @notice Transfers an underlying NFT asset out of this contract
     * @dev Performs a transfer out, reverting upon failure.
     *  If caller has not called checked protocol's balance, may revert due to insufficient cash held in the contract.
     *  If caller has checked protocol's balance, and verified it is >= amount, this should not revert in normal conditions.
     * @param to The address where to transfer underlying assets to
     * @param underlyingID The ID of the underlying asset
     * @param amount The amount of underlying to transfer, must be == oneUnit here
     */
    function doTransferOut(address payable to, uint256 underlyingID, uint amount, uint sellPrice, address payable transferHandler, bytes memory transferParams) internal returns (uint) {
        /** 
         * For now, amounts transferred out must always be oneUnit. Later, with NFT borrowing enabled
         * amount could be larger than oneUnit and the difference would be the lender's and protocol's
         * profit and should be distributed here. 
         */
        require(amount == oneUnit, "Amount must be oneUnit");
        if (transferHandler == address(0)) {
            // transfer without subsequent sale to a third party
            IERC721(underlyingContract).safeTransferFrom(address(this), to, underlyingID);
            require(IERC721(underlyingContract).ownerOf(underlyingID) == to, "Transfer out failed");
        }
        else {
            // transfer followed by sale to a third party (handled by transferHandler)
            // transfer underlying to transferHandler first (reduced risk, grant access rights only from transferHandler)
            IERC721(underlyingContract).safeTransferFrom(address(this), transferHandler, underlyingID);
            MEtherUserInterface mEther = tokenAuction.paymentToken();
            uint240 mEtherToken = MTokenCommon(address(mEther)).thisFungibleMToken();
            uint oldBalance = to.balance;
            uint oldBorrowBalance = mEther.borrowBalanceCurrent(to, mEtherToken);
            uint error = FlashLoanReceiverInterface(transferHandler).executeTransfer(underlyingID, to, sellPrice, transferParams);
            require(error == uint(Error.NO_ERROR), "Transfer operation failed");
            uint cashReceived = to.balance;
            require(cashReceived >= oldBalance, "Negative received payment");
            cashReceived = cashReceived - oldBalance;
            uint borrowReduced = mEther.borrowBalanceStored(to, mEtherToken);
            require(oldBorrowBalance >= borrowReduced, "Borrow increased");
            borrowReduced = oldBorrowBalance - borrowReduced;
            require((cashReceived + borrowReduced) >= sellPrice, "Received payment too low");
        }
        return amount;
    }

    /**
     * @notice Transfers underlying assets from sender to a beneficiary (e.g. for flash loan down payment)
     * @dev Performs a transfer from, reverting upon failure (e.g. insufficient allowance from owner)
     * @param to the address where to transfer underlying assets to
     * @param underlyingID the ID of the underlying asset (in case of a NFT) or 1 (in case of a fungible asset)
     * @param amount the amount of underlying to transfer (for fungible assets) or oneUnit (for NFTs)
     * @return (uint) Returns the amount actually transferred (lower in case of a fee).
     */
    function doTransferOutFromSender(address payable to, uint256 underlyingID, uint amount) internal returns (uint) {
        /** 
         * For now, amounts transferred must always be oneUnit. Later, with NFT borrowing enabled
         * amount could be larger than oneUnit.
         */
        require(amount == oneUnit, "Amount must be oneUnit");
        IERC721(underlyingContract).safeTransferFrom(msg.sender, to, underlyingID);
        require(IERC721(underlyingContract).ownerOf(underlyingID) == to, "Transfer out failed");
        return amount;
    }
}

contract MERC721InterfaceFull is MERC721TokenAdmin, MERC721Interface {}