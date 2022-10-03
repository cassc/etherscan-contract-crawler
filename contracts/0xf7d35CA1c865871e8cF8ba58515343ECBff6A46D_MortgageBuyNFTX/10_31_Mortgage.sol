pragma solidity ^0.5.16;

import "./MTokenCommon.sol";
import "./MTokenInterfaces.sol";
import "./MEtherAdmin.sol";
import "./MERC721TokenAdmin.sol";
import "./ErrorReporter.sol";

contract MortgageERC721UsingETH is FlashLoanReceiverInterface, TokenErrorReporter {

    address payable public admin;
    bool internal _notEntered; // re-entrancy check flag
    MERC721InterfaceFull public mERC721;
    IERC721 public underlyingERC721;
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

            /* call NFTX with flashParams call data, obtained e.g. using getBuyAndRedeemData() */
            NFTXInterface(nFTXAddress).buyAndRedeem.value(paidOutAmount)(vaultId, amount, specificIds, path, address(this));
            require(underlyingERC721.ownerOf(underlyingID) == address(this), "buy from NFTX failed");
        }

        uint balance = address(this).balance;
        if (balance >= refund) {
            refund = balance - refund;
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