pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "./MTokenCommon.sol";
import "./MTokenInterfaces.sol";
import "./MEtherAdmin.sol";
import "./MERC721TokenAdmin.sol";
import "./ErrorReporter.sol";

contract WETHInterface is IERC20 {
    function withdraw(uint wad) public;
}

contract MortgageERC721UsingETH is FlashLoanReceiverInterface, TokenErrorReporter {

    address payable public admin;
    bool internal _notEntered; // re-entrancy check flag
    MERC721InterfaceFull public mERC721;
    IERC721 public underlyingERC721;
    WETHInterface WETHContract = WETHInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    mapping (address => bool) public isWhiteListed;

    constructor(address _mERC721Address) public {
        admin = msg.sender;
        mERC721 = MERC721InterfaceFull(_mERC721Address);
        underlyingERC721 = IERC721(mERC721.underlyingContract());
        underlyingERC721.setApprovalForAll(_mERC721Address, true);
        _notEntered = true; // Start true prevents changing from zero to non-zero (smaller gas cost)
    }

    function _setWhiteList(address candidate, bool state) external {
        require(msg.sender == admin, "only admin");
        isWhiteListed[candidate] = state;
    }

    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external returns (uint) {
        tokenId;
        seller;
        sellPrice;
        transferParams;
        revert("not implemented");
    }

    /**
     * @notice Handle the receipt of an NFT, see Open Zeppelin's IERC721Receiver.
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public view returns (bytes4) {
        /* unused parameters - silence warnings */
        operator;
        from;
        tokenId;
        data;
        address(this);

        return this.onERC721Received.selector;
    }

    /**
     * @notice Used in 'executeFlashOperation()' to perform initial checks (reverts on error)
     */
    function checkReceivedFunds(address sender, uint240 mToken, uint paidOutAmount) internal view returns (MEtherInterfaceFull mEther) {
        mEther = MEtherInterfaceFull(sender);
        require(isWhiteListed[sender], "caller not whitelisted");
        require(mEther.thisFungibleMToken() == mToken, "invalid mToken");
        require(mEther.underlyingContract() == address(uint160(-1)), "borrow must be in ETH");
        require(paidOutAmount <= address(this).balance, "insufficient contract balance");
    }

    /**
     * @notice Used in 'executeFlashOperation()' to pay refunds: use any remaining funds 
     * to repay part of the borrow, transfer the rest in cash (reverts on error)
     */
    function payRefunds(MEtherInterface mEther, address payable borrower, uint240 mToken, uint refund) internal {
        if (refund > 0) {
            uint borrowBalance = mEther.borrowBalanceStored(borrower, mToken);
            if (borrowBalance < refund) {
                borrower.transfer(refund - borrowBalance);
            }
            else {
                borrowBalance = refund;
            }
            if (borrowBalance > 0) {
                mEther.repayBorrowBehalf.value(borrowBalance)(borrower);
            }
        }
    }

    /**
     * @notice Used in 'executeTransfer()' to check and pay out sales proceeds: first, repay any
     * borrows of the seller, then pay out the rest in cash (reverts on error)
     */
    function checkReceivedWETHAndPayOut(uint256 oldWETHBalance, address payable seller, uint sellPrice) internal {
        /* check if sufficient funds (in WETH) received for sale */
        uint256 cashReceived = WETHContract.balanceOf(address(this));
        require(cashReceived >= oldWETHBalance, "WETH balance corrupted");
        cashReceived = cashReceived - oldWETHBalance;
        require(cashReceived >= sellPrice, "Insufficient price received");

        /* convert received WETH -> ETH */
        WETHContract.withdraw(cashReceived);

        // use proceeds to repay outstanding borrows, transfer any surplus cash to original owner
        MEtherUserInterface mEther = mERC721.tokenAuction().paymentToken();
        uint borrowBalance = mEther.borrowBalanceStored(seller, MTokenCommon(address(mEther)).thisFungibleMToken());
        if (borrowBalance > cashReceived) {
            borrowBalance = cashReceived;
        }
        if (borrowBalance > 0) {
            require(mEther.repayBorrowBehalf.value(borrowBalance)(seller) == borrowBalance, "Borrow repayment failed");
        }
        if (cashReceived > borrowBalance) {
            seller.transfer(cashReceived - borrowBalance);
        }
    }

    /**
     * @dev Block reentrancy (directly or indirectly)
     */
    modifier nonReentrant() {
        require(_notEntered, "Reentrance not allowed");
        _notEntered = false;
        _;
        _notEntered = true; // get a gas-refund post-Istanbul
    }

    // this is sometimes needed in case of (ETH) refunds, e.g. from NFTX buyAndRedeem()
    function () payable external {}

// The functions below this are safety measures in case of (ETH, ERC20, ERC721) transfers gone wrong.
// The admin can then retreive those left-over funds. This should not be needed in normal operation.

    function _withdraw() external {
        require(msg.sender == admin, "only admin");
        admin.transfer(address(this).balance);
    }

    /**
        @notice Admin may collect any ERC-20 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @param tokenContract The contract address of the "lost" token.
        @return (uint) Returns the amount of tokens successfully collected, otherwise reverts.
    */
    function _sweepERC20(address tokenContract) external returns (uint) {
        require(msg.sender == admin, "only admin");
        uint256 amount = IERC20(tokenContract).balanceOf(address(this));
        require(amount > 0, "No leftover tokens found");
        IERC20(tokenContract).transfer(admin, amount);
        return amount;
    }

    /**
        @notice Admin may collect any ERC-721 token that have been transferred to this contract 
                inadvertently (otherwise they would be locked forever).
        @dev Reverts upon any failure.        
        @param tokenContract The contract address of the "lost" token.
        @param tokenID The ID of the "lost" token.
    */
    function _sweepERC721(address tokenContract, uint256 tokenID) external {
        require(msg.sender == admin, "only admin");
        require(address(this) == IERC721(tokenContract).ownerOf(tokenID), "Token not owned by contract");
        IERC721(tokenContract).safeTransferFrom(address(this), admin, tokenID);
    }
}

contract MortgageMintGlasses is MortgageERC721UsingETH {

    constructor(address _mGlassesAddress) public MortgageERC721UsingETH(_mGlassesAddress) {
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;
        flashParams;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);

        /* Get Glasses contract address */
        TestNFT glasses = TestNFT(address(uint160(mERC721.underlyingContract())));

        /* mint new Glasses */
        uint price = glasses.price();
        require(price <= paidOutAmount, "insufficient funds");
        uint refund = paidOutAmount - price;
        uint256 newGlassesID = glasses.mint.value(price)();
        require(glasses.ownerOf(newGlassesID) == address(this), "minting failed");

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, newGlassesID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }
}

contract NFTXInterface {
    function buyAndRedeem(
        uint256 vaultId, 
        uint256 amount,
        uint256[] calldata specificIds, 
        address[] calldata path,
        address to
    ) external payable;
}

contract MortgageBuyNFTX is MortgageERC721UsingETH {

    address public nFTXAddress;

    constructor(address _mERC721Address, address _nFTXAddress) public MortgageERC721UsingETH(_mERC721Address) {
        nFTXAddress = _nFTXAddress;
    }

    /**
     * @notice Convenience function for assembling flashParams call data for NFTX buyAndRedeem()
     */
    function getBuyAndRedeemData(uint256 vaultId, uint256 amount, uint256[] calldata specificIds, address[] calldata path) external pure returns (bytes memory) {
        return abi.encode(vaultId, amount, specificIds, path);
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* retrieve call arguments from flashParams */
            (uint256 vaultId, uint256 amount, uint256[] memory specificIds, address[] memory path) = abi.decode(flashParams, (uint256, uint256, uint256[], address[]));
            require(amount == 1 && specificIds.length == 1, "invalid token amount");
            underlyingID = specificIds[0];
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");

            /* call NFTX with flashParams call data, obtained e.g. using getBuyAndRedeemData() */
            NFTXInterface(nFTXAddress).buyAndRedeem.value(paidOutAmount)(vaultId, amount, specificIds, path, address(this));
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from NFTX failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }
}

contract OpenSeaWyvernInterface {
    /* Fee method: protocol fee or split fee. */
    enum FeeMethod { ProtocolFee, SplitFee }
    enum Side { Buy, Sell }
    enum SaleKind { FixedPrice, DutchAuction }
    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    function atomicMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) public payable;
}

contract MortgageBuyOpenSeaWyvern is MortgageERC721UsingETH {

    address payable public constant openSeaExchange = 0x7f268357A8c2552623316e2562D90e642bB538E5;
    address public constant merkleValidatorTarget = 0xBAf2127B49fC93CbcA6269FAdE0F7F31dF4c88a7;
    address public constant openSeaWallet = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;

    constructor(address _mERC721Address) public MortgageERC721UsingETH(_mERC721Address) {
    }

    /**
     * @notice Convenience function for assembling flashParams call data for OpenSea atomicMatch_()
     * @return Returns the flashParams calldata to be used directly in flashBorrow().
     */
    function getAtomicMatchData(
            address seller, 
            address sellOrderFeeRecipient, 
            uint sellMakerRelayerFee, 
            uint sellOrderPrice, 
            uint[2] memory sellOrderListingAndExpirationTime,
            uint sellOrderSalt,
            OpenSeaWyvernInterface.FeeMethod sellerFeeMethod,
            uint[3] memory sellerSignature_vrs,
            address tokenAddress,
            uint256 tokenId
        ) public view returns (bytes memory) 
    {
        AtomicMatchParameters memory params = AtomicMatchParameters(
            seller,
            sellOrderFeeRecipient, 
            sellMakerRelayerFee, 
            sellOrderPrice, 
            sellOrderListingAndExpirationTime,
            sellOrderSalt,
            sellerFeeMethod,
            sellerSignature_vrs,
            tokenAddress,
            tokenId
        );
        return getAtomicMatchDataInternal(params);
    }

    struct AtomicMatchParameters {
        address seller; 
        address sellOrderFeeRecipient; 
        uint sellMakerRelayerFee;
        uint sellOrderPrice;
        uint[2] sellOrderListingAndExpirationTime; 
        uint sellOrderSalt;
        OpenSeaWyvernInterface.FeeMethod sellerFeeMethod;
        uint[3] sellerSignature_vrs;
        address tokenAddress;
        uint256 tokenId;
    }

    struct AtomicMatchLocalVars {
        /* for stack size reasons, the following fixed size (32 bytes) params are combined into one uint[40] array:
         * address[14] addrs;
         * uint[18] uints;
         * uint8[8] feeMethodsSidesKindsHowToCalls;
        */
        uint[40] fixedSize;
        bytes calldataBuy;
        bytes calldataSell;
        bytes replacementPatternBuy;
        bytes replacementPatternSell;
        bytes staticExtradataBuy;
        bytes staticExtradataSell;
        uint[7] signatureData; // uint8[2] vs: v, v; bytes32[5] rssMetadata: r, s, r, s
    }

    function getAtomicMatchDataInternal(AtomicMatchParameters memory params) internal view returns (bytes memory) 
    {

        AtomicMatchLocalVars memory vars;

        vars.fixedSize[0] = uint(openSeaExchange); // buy order opensea exchange contract address
        vars.fixedSize[1] = uint(address(this)); // buy order maker: buyer address
        vars.fixedSize[2] = uint(params.seller); // buy order taker: selling owner address
        vars.fixedSize[3] = uint(address(0)); // buy order feeRecipient - must be zero if seller nonzero
        vars.fixedSize[4] = uint(merkleValidatorTarget); // buy order target: MerkleValidator contract - must match sell order
        vars.fixedSize[5] = uint(address(0)); // buy order staticTarget: zero if no static target
        vars.fixedSize[6] = uint(address(0)); // buy order paymentToken: zero for ETH

        vars.fixedSize[7] = uint(openSeaExchange); // sell order opensea exchange contract address
        vars.fixedSize[8] = uint(params.seller); // sell order maker: selling owner address
        vars.fixedSize[9] = uint(address(0)); // sell order taker: nobody
        if (params.sellOrderFeeRecipient != address(0)) {
            vars.fixedSize[10] = uint(params.sellOrderFeeRecipient); // sell order feeRecipient: set by user
        } else {
            vars.fixedSize[10] = uint(openSeaWallet); // sell order feeRecipient: OpenSea Wallet contract
        }
        vars.fixedSize[11] = uint(merkleValidatorTarget); // sell order target: MerkleValidator contract - must match buy order
        vars.fixedSize[12] = uint(address(0)); // sell order staticTarget: zero if no static target
        vars.fixedSize[13] = uint(address(0)); // sell order paymentToken: zero for ETH

        vars.fixedSize[14] = params.sellMakerRelayerFee; // makerRelayerFee - unused for taker order
        vars.fixedSize[15] = 0; // takerRelayerFee
        vars.fixedSize[16] = 0; // makerProtocolFee
        vars.fixedSize[17] = 0; // takerProtocolFee
        vars.fixedSize[18] = params.sellOrderPrice; // buy order price (= sellOrderPrice)
        vars.fixedSize[19] = 0; // auction extra: 0 if not used
        vars.fixedSize[20] = block.number; // buy order listing time
        vars.fixedSize[21] = 0; // buy order expiration time: 0 if no expiration
        vars.fixedSize[22] = uint(keccak256(abi.encode(params.sellerSignature_vrs[1], msg.sender, block.number))); // buy order salt

        vars.fixedSize[23] = params.sellMakerRelayerFee; // sell order makerRelayerFee
        vars.fixedSize[24] = 0; // takerRelayerFee
        vars.fixedSize[25] = 0; // makerProtocolFee
        vars.fixedSize[26] = 0; // takerProtocolFee
        vars.fixedSize[27] = params.sellOrderPrice; // sell order price
        vars.fixedSize[28] = 0; // auction extra: 0 if not used
        vars.fixedSize[29] = params.sellOrderListingAndExpirationTime[0]; // sell order listing time
        vars.fixedSize[30] = params.sellOrderListingAndExpirationTime[1]; // sell order expiration time
        vars.fixedSize[31] = params.sellOrderSalt; // sell order salt

        vars.fixedSize[32] = uint8(params.sellerFeeMethod); // FeeMethod buy order - must match sell order
        vars.fixedSize[33] = uint8(OpenSeaWyvernInterface.Side.Buy); // Side buy order - must be opposite sell order
        vars.fixedSize[34] = uint8(OpenSeaWyvernInterface.SaleKind.FixedPrice); // SaleKind buy order - must match sell order
        vars.fixedSize[35] = uint8(OpenSeaWyvernInterface.HowToCall.DelegateCall); // HowToCall buy order - must match sell order

        vars.fixedSize[36] = uint8(params.sellerFeeMethod); // FeeMethod sell order
        vars.fixedSize[37] = uint8(OpenSeaWyvernInterface.Side.Sell); // Side sell order
        vars.fixedSize[38] = uint8(OpenSeaWyvernInterface.SaleKind.FixedPrice); // SaleKind sell order
        vars.fixedSize[39] = uint8(OpenSeaWyvernInterface.HowToCall.DelegateCall); // HowToCall sell order

        (vars.calldataBuy, 
        vars.calldataSell, 
        vars.replacementPatternBuy, 
        vars.replacementPatternSell) = constructCalldata(params.seller, params.tokenAddress, params.tokenId);

        vars.staticExtradataBuy; // unused - leave empty
        vars.staticExtradataSell; // unused - leave empty

        vars.signatureData[0] = params.sellerSignature_vrs[0];
        vars.signatureData[1] = params.sellerSignature_vrs[0];

        vars.signatureData[2] = params.sellerSignature_vrs[1];
        vars.signatureData[3] = params.sellerSignature_vrs[2];
        vars.signatureData[4] = params.sellerSignature_vrs[1];
        vars.signatureData[5] = params.sellerSignature_vrs[2];
        vars.signatureData[6] = 0;
        
        return abi.encode(vars.fixedSize, vars.calldataBuy, vars.calldataSell, vars.replacementPatternBuy, vars.replacementPatternSell, vars.staticExtradataBuy, vars.staticExtradataSell, vars.signatureData);
    }

    // calldata for token transfer call: calldataBuy must match callDataSell after replacement pattern
    function constructCalldata(address seller, address tokenAddress, uint256 tokenId) internal view 
        returns (
            bytes memory calldataBuy,
            bytes memory calldataSell,
            bytes memory replacementPatternBuy,
            bytes memory replacementPatternSell
        ) 
    {
        bytes32[] memory proof;
        calldataBuy = abi.encodeWithSelector(
            bytes4(0xfb16a595), // token transfer function selector
            address(0), // from: seller address
            address(this), // to: buyer address
            tokenAddress, // token: e.g. Penguin contract address
            tokenId, // tokenId: e.g. Penguin ID
            bytes32(0), // root: set to zero means no proof
            proof // proof (if root != 0)
        );

        calldataSell = abi.encodeWithSelector(
            bytes4(0xfb16a595), // token transfer function selector
            seller, // from: seller address
            address(0), // to: buyer address
            tokenAddress, // token: e.g. Penguin contract address
            tokenId, // tokenId: e.g. Penguin ID
            bytes32(0), // root: set to zero means no proof
            proof // proof (if root != 0)
        );
        
        bytes memory replacementPatternBuyFirst = abi.encodeWithSelector(
            bytes4(0), // token transfer function selector
            bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff), // from: seller address
            bytes32(0) // to: buyer address
        );
        replacementPatternBuy = abi.encodePacked(replacementPatternBuyFirst, new bytes(calldataBuy.length - replacementPatternBuyFirst.length));

        bytes memory replacementPatternSellFirst = abi.encodeWithSelector(
            bytes4(0), // token transfer function selector
            bytes32(0), // from: seller address
            bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) // to: buyer address
        );
        replacementPatternSell = abi.encodePacked(replacementPatternSellFirst, new bytes(calldataSell.length - replacementPatternSellFirst.length));
    }

    /**
     * @notice Convenience function for assembling flashParams call data for OpenSea atomicMatch_().
     * @param dataWithSignature Call data obtained e.g. from Metamask when manually buying an NFT on OpenSea
     * @return flashParams is the call data with buyer fields adjusted to be used directly in flashBorrow().
     * The other return values can be used to analyse the call data, or for getAtomicMatchData()
     */
    function parseAtomicMatchCalldata(bytes memory dataWithSignature) 
        public view returns (
            address seller,
            address sellOrderFeeRecipient,
            uint sellMakerRelayerFee,
            uint sellOrderPrice,
            uint[2] memory sellOrderListingAndExpirationTime,
            uint sellOrderSalt,
            OpenSeaWyvernInterface.FeeMethod sellerFeeMethod,
            uint[3] memory sellerSignature_vrs,
            address tokenAddress,
            uint256 tokenId,
            bytes memory flashParams
        ) 
    {
        for (uint i = 4; i < dataWithSignature.length; i++) {
            dataWithSignature[i - 4] = dataWithSignature[i];
        }
        uint[40] memory fixedSize;
        bytes memory calldataSell;
        uint[7] memory signatureData;
        // skip function signature
        (fixedSize, , calldataSell, , , , , signatureData) = abi.decode(dataWithSignature, (uint[40], bytes, bytes, bytes, bytes, bytes, bytes, uint[7]));
        seller = address(fixedSize[8]);
        sellOrderFeeRecipient = address(fixedSize[10]);
        sellMakerRelayerFee = fixedSize[23];
        sellOrderPrice = fixedSize[27];
        sellOrderListingAndExpirationTime[0] = fixedSize[29];
        sellOrderListingAndExpirationTime[1] = fixedSize[30];
        sellOrderSalt = fixedSize[31];
        sellerFeeMethod = OpenSeaWyvernInterface.FeeMethod(uint8(fixedSize[36]));
        sellerSignature_vrs[0] = signatureData[1];
        sellerSignature_vrs[1] = signatureData[4];
        sellerSignature_vrs[2] = signatureData[5];
        // skip function signature
        for (uint i = 4; i < calldataSell.length; i++) {
            calldataSell[i - 4] = calldataSell[i];
        }
        ( , , tokenAddress, tokenId) = abi.decode(calldataSell, (address, address, address, uint256));
        flashParams = getAtomicMatchData(seller, sellOrderFeeRecipient, sellMakerRelayerFee, sellOrderPrice, sellOrderListingAndExpirationTime, sellOrderSalt, sellerFeeMethod, sellerSignature_vrs, tokenAddress, tokenId);
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* retrieve underlyingID from flashParams and do some sanity checks */
            ( , bytes memory calldataBuy, , , , , , ) = abi.decode(flashParams, (uint[40], bytes, bytes, bytes, bytes, bytes, bytes, uint[7]));
            // skip function signature
            for (uint i = 4; i < calldataBuy.length; i++) {
                calldataBuy[i - 4] = calldataBuy[i];
            }
            address buyer;
            address underlyingAddress;
            ( , buyer, underlyingAddress, underlyingID) = abi.decode(calldataBuy, (address, address, address, uint256));
            require(buyer == address(this), "buyer mismatch");
            require(underlyingAddress == address(underlyingERC721), "underlying contract mismatch");
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");

            /* call OpenSeaExchange with flashParams call data, obtained e.g. using getAtomicMatchData() */
            bytes memory atomicMatchCallData = abi.encodePacked(OpenSeaWyvernInterface(openSeaExchange).atomicMatch_.selector, flashParams);
            (bool success, ) = openSeaExchange.call.value(paidOutAmount)(atomicMatchCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from OpenSea failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }
}

contract OpenSeaSeaportInterface {
    
    /** BASIC ORDERS */

    /**
    * @dev For basic orders involving ETH / native / ERC20 <=> ERC721 / ERC1155
    *      matching, a group of six functions may be called that only requires a
    *      subset of the usual order arguments. Note the use of a "basicOrderType"
    *      enum; this represents both the usual order type as well as the "route"
    *      of the basic order (a simple derivation function for the basic order
    *      type is `basicOrderType = orderType + (4 * basicOrderRoute)`.)
    */
    struct BasicOrderParameters {
        // calldata offset
        address considerationToken; // 0x24
        uint256 considerationIdentifier; // 0x44
        uint256 considerationAmount; // 0x64
        address payable offerer; // 0x84
        address zone; // 0xa4
        address offerToken; // 0xc4
        uint256 offerIdentifier; // 0xe4
        uint256 offerAmount; // 0x104
        BasicOrderType basicOrderType; // 0x124
        uint256 startTime; // 0x144
        uint256 endTime; // 0x164
        bytes32 zoneHash; // 0x184
        uint256 salt; // 0x1a4
        bytes32 offererConduitKey; // 0x1c4
        bytes32 fulfillerConduitKey; // 0x1e4
        uint256 totalOriginalAdditionalRecipients; // 0x204
        AdditionalRecipient[] additionalRecipients; // 0x224
        bytes signature; // 0x244
        // Total length, excluding dynamic array data: 0x264 (580)
    }

    /**
    * @dev Basic orders can supply any number of additional recipients, with the
    *      implied assumption that they are supplied from the offered ETH (or other
    *      native token) or ERC20 token for the order.
    */
    struct AdditionalRecipient {
        uint256 amount;
        address payable recipient;
    }

    // prettier-ignore
    enum BasicOrderType {
        // 0: no partial fills, anyone can execute
        ETH_TO_ERC721_FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        ETH_TO_ERC721_PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        ETH_TO_ERC721_FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC721_PARTIAL_RESTRICTED,

        // 4: no partial fills, anyone can execute
        ETH_TO_ERC1155_FULL_OPEN,

        // 5: partial fills supported, anyone can execute
        ETH_TO_ERC1155_PARTIAL_OPEN,

        // 6: no partial fills, only offerer or zone can execute
        ETH_TO_ERC1155_FULL_RESTRICTED,

        // 7: partial fills supported, only offerer or zone can execute
        ETH_TO_ERC1155_PARTIAL_RESTRICTED,

        // 8: no partial fills, anyone can execute
        ERC20_TO_ERC721_FULL_OPEN,

        // 9: partial fills supported, anyone can execute
        ERC20_TO_ERC721_PARTIAL_OPEN,

        // 10: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC721_FULL_RESTRICTED,

        // 11: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC721_PARTIAL_RESTRICTED,

        // 12: no partial fills, anyone can execute
        ERC20_TO_ERC1155_FULL_OPEN,

        // 13: partial fills supported, anyone can execute
        ERC20_TO_ERC1155_PARTIAL_OPEN,

        // 14: no partial fills, only offerer or zone can execute
        ERC20_TO_ERC1155_FULL_RESTRICTED,

        // 15: partial fills supported, only offerer or zone can execute
        ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

        // 16: no partial fills, anyone can execute
        ERC721_TO_ERC20_FULL_OPEN,

        // 17: partial fills supported, anyone can execute
        ERC721_TO_ERC20_PARTIAL_OPEN,

        // 18: no partial fills, only offerer or zone can execute
        ERC721_TO_ERC20_FULL_RESTRICTED,

        // 19: partial fills supported, only offerer or zone can execute
        ERC721_TO_ERC20_PARTIAL_RESTRICTED,

        // 20: no partial fills, anyone can execute
        ERC1155_TO_ERC20_FULL_OPEN,

        // 21: partial fills supported, anyone can execute
        ERC1155_TO_ERC20_PARTIAL_OPEN,

        // 22: no partial fills, only offerer or zone can execute
        ERC1155_TO_ERC20_FULL_RESTRICTED,

        // 23: partial fills supported, only offerer or zone can execute
        ERC1155_TO_ERC20_PARTIAL_RESTRICTED
    }


    /** NORMAL / ADVANCED ORDERS */

    /**
    * @dev The full set of order components, with the exception of the counter,
    *      must be supplied when fulfilling more sophisticated orders or groups of
    *      orders. The total number of original consideration items must also be
    *      supplied, as the caller may specify additional consideration items.
    */
    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        OfferItem[] offer; // 0x40
        ConsiderationItem[] consideration; // 0x60
        OrderType orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
        // offer.length                          // 0x160
    }

    /**
    * @dev Orders require a signature in addition to the other order parameters.
    */
    struct Order {
        OrderParameters parameters;
        bytes signature;
    }

    /**
    * @dev Advanced orders include a numerator (i.e. a fraction to attempt to fill)
    *      and a denominator (the total size of the order) in addition to the
    *      signature and other order parameters. It also supports an optional field
    *      for supplying extra data; this data will be included in a staticcall to
    *      `isValidOrderIncludingExtraData` on the zone for the order if the order
    *      type is restricted and the offerer or zone are not the caller.
    */
    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    /**
    * @dev An offer item has five components: an item type (ETH or other native
    *      tokens, ERC20, ERC721, and ERC1155, as well as criteria-based ERC721 and
    *      ERC1155), a token address, a dual-purpose "identifierOrCriteria"
    *      component that will either represent a tokenId or a merkle root
    *      depending on the item type, and a start and end amount that support
    *      increasing or decreasing amounts over the duration of the respective
    *      order.
    */
    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    /**
    * @dev A consideration item has the same five components as an offer item and
    *      an additional sixth component designating the required recipient of the
    *      item.
    */
    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    // prettier-ignore
    enum OrderType {
        // 0: no partial fills, anyone can execute
        FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED
    }

    // prettier-ignore
    enum ItemType {
        // 0: ETH on mainnet, MATIC on polygon, etc.
        NATIVE,

        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,

        // 2: ERC721 items
        ERC721,

        // 3: ERC1155 items
        ERC1155,

        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,

        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }

    // prettier-ignore
    enum Side {
        // 0: Items that can be spent
        OFFER,

        // 1: Items that must be received
        CONSIDERATION
    }

    /**
    * @dev A criteria resolver specifies an order, side (offer vs. consideration),
    *      and item index. It then provides a chosen identifier (i.e. tokenId)
    *      alongside a merkle proof demonstrating the identifier meets the required
    *      criteria.
    */
    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }


    /**
     * @notice Fulfill an order offering an ERC20, ERC721, or ERC1155 item by
     *         supplying Ether (or other native tokens), ERC20 tokens, an ERC721
     *         item, or an ERC1155 item as consideration. Six permutations are
     *         supported: Native token to ERC721, Native token to ERC1155, ERC20
     *         to ERC721, ERC20 to ERC1155, ERC721 to ERC20, and ERC1155 to
     *         ERC20 (with native tokens supplied as msg.value). For an order to
     *         be eligible for fulfillment via this method, it must contain a
     *         single offer item (though that item may have a greater amount if
     *         the item is not an ERC721). An arbitrary number of "additional
     *         recipients" may also be supplied which will each receive native
     *         tokens or ERC20 items from the fulfiller as consideration. Refer
     *         to the documentation for a more comprehensive summary of how to
     *         utilize this method and what orders are compatible with it.
     *
     * @param parameters Additional information on the fulfilled order. Note
     *                   that the offerer and the fulfiller must first approve
     *                   this contract (or their chosen conduit if indicated)
     *                   before any tokens can be transferred. Also note that
     *                   contract recipients of ERC1155 consideration items must
     *                   implement `onERC1155Received` in order to receive those
     *                   items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(BasicOrderParameters calldata parameters)
        external
        payable
        returns (bool fulfilled);

    /**
     * @notice Fill an order, fully or partially, with an arbitrary number of
     *         items for offer and consideration alongside criteria resolvers
     *         containing specific token identifiers and associated proofs.
     *
     * @param advancedOrder       The order to fulfill along with the fraction
     *                            of the order to attempt to fill. Note that
     *                            both the offerer and the fulfiller must first
     *                            approve this contract (or their preferred
     *                            conduit if indicated by the order) to transfer
     *                            any relevant tokens on their behalf and that
     *                            contracts must implement `onERC1155Received`
     *                            to receive ERC1155 tokens as consideration.
     *                            Also note that all offer and consideration
     *                            components must have no remainder after
     *                            multiplication of the respective amount with
     *                            the supplied fraction for the partial fill to
     *                            be considered valid.
     * @param criteriaResolvers   An array where each element contains a
     *                            reference to a specific offer or
     *                            consideration, a token identifier, and a proof
     *                            that the supplied token identifier is
     *                            contained in the merkle root held by the item
     *                            in question's criteria element. Note that an
     *                            empty criteria indicates that any
     *                            (transferable) token identifier on the token
     *                            in question is valid and that no associated
     *                            proof needs to be supplied.
     * @param fulfillerConduitKey A bytes32 value indicating what conduit, if
     *                            any, to source the fulfiller's token approvals
     *                            from. The zero hash signifies that no conduit
     *                            should be used, with direct approvals set on
     *                            Seaport.
     * @param recipient           The intended recipient for all received items,
     *                            with `address(0)` indicating that the caller
     *                            should receive the items.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external payable returns (bool fulfilled);
}

contract MortgageBuyOpenSeaSeaportBasic is MortgageERC721UsingETH {

    address payable public constant openSeaSeaport = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address payable public constant openSeaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor(address _mERC721Address) public MortgageERC721UsingETH(_mERC721Address) {
        // allow OpenSea conduit to access all WETH of this contract
        WETHContract = WETHInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        WETHContract.approve(openSeaConduit, uint256(-1));
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* retrieve underlyingID from flashParams and do some sanity checks */
            OpenSeaSeaportInterface.BasicOrderParameters memory parameters = abi.decode(flashParams, (OpenSeaSeaportInterface.BasicOrderParameters));
            require(parameters.offerToken == address(underlyingERC721), "underlying contract mismatch");
            require(parameters.offerAmount == 1, "token amount mismatch");
            underlyingID = parameters.offerIdentifier;
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");

            /* call openSeaSeaport fulfillBasicOrder() with flashParams call data */
            bytes memory fulfillBasicOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillBasicOrder.selector, flashParams);
            (bool success, ) = openSeaSeaport.call.value(paidOutAmount)(fulfillBasicOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            /* check if NFT received */
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from OpenSea failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }

    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external nonReentrant returns (uint) {

        // only allow linked ERC721 contract to call this
        require(msg.sender == address(mERC721), "invalid caller");
    
        // allow openSeaConduit to transfer this tokenId (which is currently owned by this contract already)
        underlyingERC721.approve(openSeaConduit, tokenId);

        // get current WETH balance for this contract
        uint256 oldWETHBalance = WETHContract.balanceOf(address(this));

        {
            /* decode transferParams and do some sanity checks */
            OpenSeaSeaportInterface.BasicOrderParameters memory parameters = abi.decode(transferParams, (OpenSeaSeaportInterface.BasicOrderParameters));
            require(parameters.considerationToken == address(underlyingERC721), "underlying contract mismatch");
            require(parameters.considerationAmount == 1, "token amount mismatch");
            require(parameters.considerationIdentifier == tokenId, "tokenId mismatch");

            /* call openSeaSeaport fulfillBasicOrder() with transferParams call data */
            bytes memory fulfillBasicOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillBasicOrder.selector, transferParams);
            (bool success, ) = openSeaSeaport.call(fulfillBasicOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            checkReceivedWETHAndPayOut(oldWETHBalance, seller, sellPrice);
        }

        return uint(Error.NO_ERROR);
    }
}

contract MortgageBuyOpenSeaSeaportAdvanced is MortgageERC721UsingETH {

    address payable public constant openSeaSeaport = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address payable public constant openSeaConduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor(address _mERC721Address) public MortgageERC721UsingETH(_mERC721Address) {
        // allow OpenSea conduit to access all WETH of this contract
        WETHContract = WETHInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        WETHContract.approve(openSeaConduit, uint256(-1));
    }

    /**
     * @notice Function to be called on a receiver contract after flash loan has been disbursed to
     * that receiver contract. This function should handle repayment or increasing collateral 
     * sufficiently for flash loan to succeed (=remove borrower's shortfall). 
     * @param borrower The address who took out the borrow (funds were sent to the receiver contract)
     * @param mToken The mToken whose underlying was borrowed
     * @param borrowAmount The amount of the underlying asset borrowed
     * @param paidOutAmount The amount actually disbursed to the receiver contract (borrowAmount - fees)
     * @param flashParams Any other data forwarded from flash borrow function call
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function executeFlashOperation(address payable borrower, uint240 mToken, uint borrowAmount, uint paidOutAmount, bytes calldata flashParams) external nonReentrant returns (uint) {
        borrowAmount;

        /* Check inputs and received funds, and get mEther contract */
        MEtherInterfaceFull mEther = checkReceivedFunds(msg.sender, mToken, paidOutAmount);
        /* no underflow here, since checkReceivedFunds() reverts if paidOutAmount > address(this).balance */
        uint refund = address(this).balance - paidOutAmount;

        uint256 underlyingID;
        {
            /* decode flashParams and do some sanity checks including tokenId and funds recipient */
            (OpenSeaSeaportInterface.AdvancedOrder memory advancedOrder, OpenSeaSeaportInterface.CriteriaResolver[] memory criteriaResolvers, , address recipient) = abi.decode(flashParams, (OpenSeaSeaportInterface.AdvancedOrder, OpenSeaSeaportInterface.CriteriaResolver[], bytes32, address));
            require(advancedOrder.parameters.offer.length >= 1, "invalid flashParams");
            require(advancedOrder.parameters.offer[0].token == address(underlyingERC721), "underlying contract mismatch");
            require(advancedOrder.parameters.offer[0].startAmount == 1, "token amount mismatch");
            require(advancedOrder.parameters.offer[0].endAmount == 1, "token amount mismatch");
            if (advancedOrder.parameters.offer[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721) {
                underlyingID = advancedOrder.parameters.offer[0].identifierOrCriteria;
            }
            else if (advancedOrder.parameters.offer[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721_WITH_CRITERIA) {
                require(criteriaResolvers.length >= 1, "invalid criteria length");
                underlyingID = criteriaResolvers[0].identifier;
            }
            else {
                revert("tokenId not found");
            }
            require(underlyingERC721.ownerOf(underlyingID) != borrower, "already owner");
            require(mERC721.balanceOf(borrower, mERC721.mTokenFromUnderlying(underlyingID)) == 0, "already owner");
            require(recipient == address(0) || recipient == address(this), "invalid funds recipient");
    
            /* call openSeaSeaport fulfillAdvancedOrder() with transferParams call data */
            bytes memory fulfillAdvancedOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillAdvancedOrder.selector, flashParams);
            (bool success, ) = openSeaSeaport.call(fulfillAdvancedOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            /* check if NFT received */
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from OpenSea failed");
        }

        uint newBalance = address(this).balance;
        if (newBalance >= refund) {
            refund = newBalance - refund;
        }
        else {
            revert("balance lower than expected");
        }

        /* supply them to mERC721 contract and collateralize them (reverts on any failure) */
        mERC721.mintAndCollateralizeTo(borrower, underlyingID);

        /* pay refunds, if any, to borrower */
        payRefunds(mEther, borrower, mToken, refund);

        return uint(Error.NO_ERROR);
    }

    function executeTransfer(uint256 tokenId, address payable seller, uint sellPrice, bytes calldata transferParams) external nonReentrant returns (uint) {

        // only allow linked ERC721 contract to call this
        require(msg.sender == address(mERC721), "invalid caller");
    
        // allow openSeaConduit to transfer this tokenId (which is currently owned by this contract already)
        underlyingERC721.approve(openSeaConduit, tokenId);

        // get current WETH balance for this contract
        uint256 oldWETHBalance = WETHContract.balanceOf(address(this));

        {
            /* decode transferParams and do some sanity checks including tokenId and funds recipient */
            (OpenSeaSeaportInterface.AdvancedOrder memory advancedOrder, OpenSeaSeaportInterface.CriteriaResolver[] memory criteriaResolvers, , address recipient) = abi.decode(transferParams, (OpenSeaSeaportInterface.AdvancedOrder, OpenSeaSeaportInterface.CriteriaResolver[], bytes32, address));
            require(advancedOrder.parameters.consideration.length >= 1, "invalid transferParams");
            require(advancedOrder.parameters.consideration[0].token == address(underlyingERC721), "underlying contract mismatch");
            require(advancedOrder.parameters.consideration[0].startAmount == 1, "token amount mismatch");
            require(advancedOrder.parameters.consideration[0].endAmount == 1, "token amount mismatch");
            if (advancedOrder.parameters.consideration[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721) {
                require(advancedOrder.parameters.consideration[0].identifierOrCriteria == tokenId, "tokenId mismatch");
            }
            else if (advancedOrder.parameters.consideration[0].itemType == OpenSeaSeaportInterface.ItemType.ERC721_WITH_CRITERIA) {
                require(criteriaResolvers.length >= 1, "invalid criteria length");
                require(criteriaResolvers[0].identifier == tokenId, "tokenId criteria mismatch");
            }
            else {
                revert("tokenId not found");
            }
            require(recipient == address(0) || recipient == address(this), "invalid funds recipient");
    
            /* call openSeaSeaport fulfillAdvancedOrder() with transferParams call data */
            bytes memory fulfillAdvancedOrderCallData = abi.encodePacked(OpenSeaSeaportInterface(openSeaSeaport).fulfillAdvancedOrder.selector, transferParams);
            (bool success, ) = openSeaSeaport.call(fulfillAdvancedOrderCallData);
            assembly {
                let free_mem_ptr := mload(0x40)
                returndatacopy(free_mem_ptr, 0, returndatasize)

                switch success
                case 0 { revert(free_mem_ptr, returndatasize) }
                default { }
            }

            checkReceivedWETHAndPayOut(oldWETHBalance, seller, sellPrice);
        }

        return uint(Error.NO_ERROR);
    }
}