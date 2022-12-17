// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title A contract to facilitate private swaps of NFTs and fungible tokens between multipe wallets
 * @author irreverent.eth @ DTTD
 * @notice https://dttd.io/
 * @notice This contract is intended to be used in conjunction within the DTTD ecosystem, with its off-chain swaps
           tracking and signing system as essential components of completing a swap.
 */

//    ___    _____   _____    ___   
//   |   \  |_   _| |_   _|  |   \  
//   | |) |   | |     | |    | |) | 
//   |___/   _|_|_   _|_|_   |___/  
// _|"""""|_|"""""|_|"""""|_|"""""| 
// "`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/SignatureChecker.sol";
import "openzeppelin-contracts/security/Pausable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/token/ERC1155/IERC1155.sol";

import { IDTTDSwap } from "./IDTTDSwap.sol";
import { Swap, Offer, OfferItem, SWAP_TYPEHASH, OFFER_TYPEHASH, OFFERITEM_TYPEHASH } from "./DTTDStructs.sol";
import { OfferItemType } from "./DTTDEnums.sol";


contract DTTDSwap is Ownable, Pausable, IDTTDSwap {

    constructor(address _authority) {
        if(_authority == address(0)) { revert("SetInvalidAuthority"); }
        authority = _authority;
    }


    /*//////////////////////////////////////////////////////////////
                        STORAGE MAPPINGS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev swapNonce is a global nonce for all swaps and their versions.  Not all will end up on chain as the
            negotiation process will result in some being skipped.  If swapNonce exists already, revert, because we
            want to perform the same Swap only once.
     */
    mapping (uint256 => bool) public executedSwapNonce;

    /**
     * @dev blockedSwapHash is a mapping of swapHashes that are blocked from being executed
     */
    mapping (bytes32 => bool) public blockedSwapHash;


    /*//////////////////////////////////////////////////////////////
                        AUTHORITY LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The authority address for the last signature needed for a swap
     */
    address public authority;

    /**
     * @notice Sets a new authority to be used.
     * @dev Cannot be 0x0 and owner settable only
     */
    function setAuthority(address _authority) external onlyOwner {
        if(_authority == address(0)) { revert("SetInvalidAuthority"); }
        authority = _authority;
    }


    /*//////////////////////////////////////////////////////////////
                        PAUSIBLE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Pauses all swaps in case of emergencies
     */
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }


    /*//////////////////////////////////////////////////////////////
                        SIGNATURE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev The EIP712 domain separator for this contract, using predetermined hash values
     *      EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
     *      EIP721_DOMAIN_NAME_HASH = keccak256("DTTD Private Swap");
     */
    bytes32 public immutable domainSeparator = keccak256(abi.encode(
        0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866, // EIP712_DOMAIN_TYPEHASH
        0x3ef8fd112a48aa32ffdc7138bdecf127ca9d363377cf6553bb738d49d484a699, // EIP721_DOMAIN_NAME_HASH
        block.chainid,
        address(this)
    ));

    /**
     * @dev Hash a Swap struct for EIP712 signing
     */
    function hashSwap(Swap calldata _swap) public view returns (bytes32) {
        bytes32[] memory offerHashes = new bytes32[](_swap.offer.length);
        for (uint i = 0; i < _swap.offer.length; i++) {
            offerHashes[i] = _hashOffer(_swap.offer[i]);
        }
        return keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            keccak256(abi.encode(
                SWAP_TYPEHASH,
                keccak256(abi.encodePacked(offerHashes)),
                _swap.endTime,
                _swap.swapNonce
            ))
        ));
    }

    /**
     * @dev Hash a Offer struct
     */
    function _hashOffer(Offer calldata _offer) internal pure returns (bytes32) {
        bytes32[] memory offerItemHashes = new bytes32[](_offer.offerItem.length);
        for (uint i = 0; i < _offer.offerItem.length; i++) {
            offerItemHashes[i] = _hashOfferItem(_offer.offerItem[i]);
        }
        return keccak256(abi.encode(
            OFFER_TYPEHASH,
            keccak256(abi.encodePacked(offerItemHashes)),
            _offer.from
        ));
    }

    /**
     * @dev Hash a OfferItem struct
     */
    function _hashOfferItem(
        OfferItem calldata _offerItem
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OFFERITEM_TYPEHASH,
            _offerItem.to,
            _offerItem.offerItemType,
            _offerItem.token,
            _offerItem.identifier,
            _offerItem.amount
        ));
    }


    /*//////////////////////////////////////////////////////////////
                        MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Ensures that the swap nonce has yet been executed
     */
    modifier ensureUnusedSwapNonce(uint256 _swapNonce) {
        if (executedSwapNonce[_swapNonce]) { revert("SwapExecuted"); }
      _;
   }

    /**
     * @dev Ensures that the swap is not yet expired.  As the time limit of a
            swap is usually in hours and days, manipulated block.timestamp is
            not a concern.
     */
    modifier ensureNotExpired(uint256 _expiry) {
        if (block.timestamp > _expiry) { revert("SwapExpired"); }
      _;
   }


    /*//////////////////////////////////////////////////////////////
                        CORE SWAP LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Executes a swap by checking the signatures and performing the transfers.  Token approvals are required.
     * @dev the signature.length is expected to be 1+swap.offer.length
     */
    function performSwap(
        Swap calldata _swap,
        bytes[] calldata _signature
    ) external
      payable
      whenNotPaused
      ensureUnusedSwapNonce(_swap.swapNonce)
      ensureNotExpired(_swap.endTime)
    {

        uint256 totalOffers = _swap.offer.length;

        if (totalOffers < 1) { revert("TooFewOffers"); }

        if (_signature.length != totalOffers + 1) { revert("WrongSigCount"); }

        // Get the swap hash of a Swap
        bytes32 swapHash = hashSwap(_swap);

        // Check if the Swap has been blocked
        if (blockedSwapHash[swapHash]) {
            revert("SwapBlocked");
        }

        // Each offer has a signature at the corresponding index signed by the offerer
        // The extra and last signature should be the authority signature
        bool validAuthority = SignatureChecker.isValidSignatureNow(authority, swapHash, _signature[totalOffers]);
        if(!validAuthority) { revert("InvalidAuthSig"); }

        uint256 remainingFunds = msg.value;

        // set swapNonce so this Swap cannot happen again
        executedSwapNonce[_swap.swapNonce] = true;

        // Iterate over each offer to check the signature and perform the transfers
        for (uint256 i = 0; i < totalOffers; i++) {
            Offer calldata offer = _swap.offer[i];
            
            uint256 totalOfferItems = offer.offerItem.length;
            address from = offer.from;

            // Check signature unless the offerer is the msg.sender
            if (from != msg.sender) {
                bool validSignature = SignatureChecker.isValidSignatureNow(from, swapHash, _signature[i]);
                if(!validSignature) { revert("InvalidSig"); }
            }

            // Iterate over each offer item now that signature is ok
            for (uint256 j = 0; j < totalOfferItems; j++) {
                OfferItem calldata offerItem = offer.offerItem[j];

                // Check if the offer item value can be converted into the enum
                if (offerItem.offerItemType > 3) { revert("UnknownItemType"); }
                OfferItemType itemType = OfferItemType(offerItem.offerItemType);

                address to = offerItem.to;
                if (to == address(0x0)) { revert("InvalidRecipient"); }

                if (itemType == OfferItemType.ERC721) {
                    // Handle ERC721 transfers
                    IERC721 token = IERC721(offerItem.token);
                    uint256 identifier = offerItem.identifier;
                    
                    token.safeTransferFrom(from, to, identifier);
                } else if (itemType == OfferItemType.ERC1155) {
                    // Handle ERC1155 transfers
                    IERC1155 token = IERC1155(offerItem.token);
                    uint256 identifier = offerItem.identifier;
                    uint256 amount = offerItem.amount;

                    // disallow 0 amount
                    if (amount == 0) { revert("ZeroAmount"); }

                    token.safeTransferFrom(from, to, identifier, amount, "");
                } else if (itemType == OfferItemType.ERC20) {
                    // Handle ERC20 transfers
                    address token = offerItem.token;
                    uint256 amount = offerItem.amount;
                    if (amount == 0) { revert("ZeroAmount"); }

                    (bool ok, bytes memory data) = token.call(
                        abi.encodeWithSelector(
                            IERC20.transferFrom.selector,
                            from,
                            to,
                            amount
                        )
                    );

                    if (!ok || data.length != 32) {
                        revert("ERC20SendFail");
                    }
                } else if (itemType == OfferItemType.NATIVE) {
                    // Handle native token transfers

                    // if native token is involved, msg.sender must be the one sending it
                    if (from != msg.sender) { revert("NonSenderSendNative"); }

                    uint256 amount = offerItem.amount;

                    // disallow 0 amount
                    if (amount == 0) { revert("ZeroAmount"); }

                    // Ensure that sufficient Ether is still available from this tx
                    if (amount > remainingFunds) { revert("InsufficientFunds"); }

                    // reduce the remaining funds by the amount to be transferred in this offer item
                    remainingFunds -= amount;

                    // transfer the native token to the receiver
                    (bool sent, ) = to.call{value: amount}("");
                    if (!sent) { revert("NativeSendFail"); }
                }
            }
        }

        if (remainingFunds > 0) {
            // transfer leftover native tokens back to msg.sender
            (bool sent, ) = msg.sender.call{value: remainingFunds}("");
            if (!sent) {
                revert("NativeSendFail");
            }
        }

        // emit LogSwap event
        emit LogSwap(_swap.swapNonce);
    }

    /**
     * @dev Blocks a swap from happening.  We store the hash of the swap in a mapping and check it while performing a
            swap.  If that hash is found, the swap is blocked.
     * @dev Any of the offerers can block a swap.
     */
    function blockSwap(
        Swap calldata _swap
    ) external ensureUnusedSwapNonce(_swap.swapNonce) ensureNotExpired(_swap.endTime) {
        for (uint256 i = 0; i < _swap.offer.length; i++) {
            Offer calldata offer = _swap.offer[i];

            // find if msg.sender is an offerer
            if (offer.from == msg.sender) {
                bytes32 swapHash = hashSwap(_swap);
                blockedSwapHash[swapHash] = true;
        
                // emit LogBlockSwap event
                emit LogBlockSwap(swapHash);
                return;
            }
        }

        // if we get here, we revert because the msg.sender is none of the offerers
        revert("NotAnOfferer");
    }

    /*//////////////////////////////////////////////////////////////
                        CONVENIENCE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Convenience function to checks all offer item approval allowances and balance.  Returns two flattened
            arrays, one boolean array for sufficient approval and one uint256 array for available balance / amount.
            Please be aware that getting the call may revert if attempting to get approval or balance of invalid
            tokens, or including invalid parameters in the swap.  Handle those cases accordingly.
     */
    function checkApprovalAndBalance(
        Swap calldata _swap
    ) external
      view
      returns (bool[] memory, uint256[] memory)
    {
        // get flattened size
        uint256 totalOffersItems = 0;
        for (uint256 i = 0; i < _swap.offer.length; i++) {
            for (uint256 j = 0; j < _swap.offer[i].offerItem.length; j++) {
                totalOffersItems++;
            }
        }

        // approval array indicates if the offer item has sufficient approval
        bool[] memory approval = new bool[](totalOffersItems);
        // balance array returns available balance
        uint256[] memory balance = new uint256[](totalOffersItems);

        // for each item in the swap, check if the offerer has the required approval and balance
        uint256 currentOfferItem = 0;
        for (uint256 i = 0; i < _swap.offer.length; i++) {
            Offer calldata offer = _swap.offer[i];
            address from = offer.from;
            for (uint256 j = 0; j < offer.offerItem.length; j++) {
                OfferItem calldata item = offer.offerItem[j];
                // Check if the offer item value can be converted into the enum
                if (item.offerItemType > 3) { revert("UnknownItemType"); }
                OfferItemType itemType = OfferItemType(item.offerItemType);
                if (itemType == OfferItemType.ERC721) {
                    approval[currentOfferItem] = IERC721(item.token).isApprovedForAll(from, address(this));
                    balance[currentOfferItem] = (IERC721(item.token).ownerOf(item.identifier) == from)?1:0;
                } else if (itemType == OfferItemType.ERC1155) {
                    approval[currentOfferItem] = IERC1155(item.token).isApprovedForAll(from, address(this));
                    balance[currentOfferItem] = IERC1155(item.token).balanceOf(from, item.identifier);
                } else if (itemType == OfferItemType.ERC20) {
                    approval[currentOfferItem] = IERC20(item.token).allowance(from, address(this)) >= item.amount;
                    balance[currentOfferItem] = IERC20(item.token).balanceOf(from);
                } else if (itemType == OfferItemType.NATIVE) {
                    approval[currentOfferItem] = true;
                    balance[currentOfferItem] = from.balance;
                }
                currentOfferItem++;
            }
        }
        return (approval, balance);
    }
}