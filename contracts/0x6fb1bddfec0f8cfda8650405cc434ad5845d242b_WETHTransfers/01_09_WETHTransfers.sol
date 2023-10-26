// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IALTS {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract WETHTransfers is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IALTS public immutable ALTS;
    IERC20 public immutable WETH;

    struct Transfer {
        address buyer;
        uint16[3] buyerAlts;
        uint16[3] sellerAlts;
        address seller;
        uint72 amount;
        uint24 id;
    }

    struct Exchange {
        uint120 minFee;
        uint120 minOrder;
        uint16 fee;
    }

    Exchange public exchange;
    address payable public receiver;
    mapping(uint24 => Transfer) private transfers;

    event TransferWETH(uint24 indexed id, address indexed buyer, address indexed seller, uint256 amount, uint256 fee);

    constructor(
        uint120 _minFee,
        uint120 _minOrder,
        uint16 _fee,
        address _weth,
        address _alts,
        address payable _receiver
    ) {
        exchange.minFee = _minFee;
        exchange.minOrder = _minOrder;
        exchange.fee = _fee;
        WETH = IERC20(_weth);
        ALTS = IALTS(_alts);
        receiver = _receiver;
    }

    /// @notice Enables a user to create a WETH transfer.
    /// @param transfer The details of the new WETH transfer.
    function executeWETHOrder(Transfer memory transfer) external nonReentrant whenNotPaused {
        require(transfer.buyer == msg.sender, "Buyer must create own order");
        require(transfer.amount >= exchange.minOrder, "Transfer amount is below minimum");
        require(transfers[transfer.id].buyer == address(0), "WETH order no longer available");
        validateAltsOwnership(transfer.buyerAlts, msg.sender);
        validateAltsOwnership(transfer.sellerAlts, transfer.seller);

        unchecked {
            uint256 minFee = exchange.minFee;
            uint256 calculatedFee = (transfer.amount * exchange.fee) / 100;
            uint256 feeAmount = calculatedFee < minFee ? minFee : calculatedFee;

            transfers[transfer.id] = transfer;

            WETH.safeTransferFrom(transfer.buyer, receiver, feeAmount);
            WETH.safeTransferFrom(transfer.buyer, transfer.seller, transfer.amount);

            emit TransferWETH(transfer.id, transfer.buyer, transfer.seller, transfer.amount, feeAmount);
        }
    }

    /// @notice Sets the wallet to receive exchange payments.
    /// @param _receiver The new address of the receiver.
    function setReceiver(address payable _receiver) external onlyOwner {
        receiver = _receiver;
    }

    /// @notice Sets WETH fee and transaction minima.
    /// @param minOrder The minimum order amount.
    /// @param minFee The minimum applicable fee.
    /// @param fee The fee applied to WETH offers.
    function setExchange(uint8 fee, uint56 minFee, uint56 minOrder) external onlyOwner {
        exchange.minFee = minFee;
        exchange.minOrder = minOrder;
        exchange.fee = fee;
    }

    /// @notice Fetches allowances for the user for all supported tokens.
    /// @param user The address of the user.
    function getAllowances(address user) external view returns (uint256) {
        return WETH.allowance(user, address(this));
    }

    /// @notice Fetches transfers including a specific wallet address between the given range.
    /// @param user The address of the user.
    /// @param start The starting ID of the transfer range.
    /// @param end The ending ID of the transfer range.
    /// @param isSeller Whether to fetch orders where the user is the buyer (WETH sender) or the seller (WETH receiver).
    function getTransfersByUser(
        address user,
        uint24 start,
        uint24 end,
        bool isSeller
    ) external view returns (uint24[] memory) {
        require(start <= end, "Invalid range");

        uint24[] memory r = new uint24[](end - start + 1);
        uint256 count = 0;

        unchecked {
            for (uint24 i = start; i <= end; i++) {
                Transfer storage transfer = transfers[i];
                if (transfer.buyer != address(0) && (isSeller ? transfer.seller : transfer.buyer) == user) {
                    r[count++] = i;
                }
            }

            uint24[] memory results = new uint24[](count);
            for (uint256 j = 0; j < count; j++) {
                results[j] = r[j];
            }

            return results;
        }
    }

    /// @notice Gets informatiom about a WETH transfer
    /// @param transferId The ID of the transfer to get data for
    /// @dev Alternative to public transfers mapping to facilitate uint16[3] display
    function getTransfer(
        uint24 transferId
    ) public view returns (address, uint16[3] memory, uint16[3] memory, address, uint24, uint256) {
        Transfer storage t = transfers[transferId];
        return (t.buyer, t.buyerAlts, t.sellerAlts, t.seller, t.id, t.amount);
    }

    /// @notice Drains any Ether from the contract to the owner.
    /// @dev This is an emergency function for funds release.
    function drainETH() external onlyOwner {
        owner().call{value: address(this).balance}("");
    }

    /// @notice Drains any WETH from the contract to the owner.
    /// @dev This is an emergency function for funds release.
    function drainWETH() external onlyOwner {
        WETH.transfer(owner(), WETH.balanceOf(address(this)));
    }

    /// @notice Pauses exchanges and points issuance.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses exchanges and points issuance.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Check a wallet owns the given ALTs
    /// @param tokenIds The ALT tokenIds to check
    /// @param owner The expected owner wallet address
    function validateAltsOwnership(uint16[3] memory tokenIds, address owner) internal view {
        bool validAlt = false;
        unchecked {
            for (uint i = 0; i < 3; i++) {
                if (tokenIds[i] != 0) {
                    validAlt = true;
                    require(ALTS.ownerOf(tokenIds[i]) == owner, "ALT ownership mismatch");
                }
            }
            require(validAlt, "No valid ALT ID provided");
        }
    }
}