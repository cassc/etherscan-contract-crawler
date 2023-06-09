// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../access/GenArtAccess.sol";
import "../app/GenArtCurated.sol";
import "../interface/IGenArtMintAllocator.sol";
import "../interface/IGenArtInterfaceV4.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtPaymentSplitterV5.sol";
import "./GenArtMinterBase.sol";
import {GenArtLoyalty} from "../loyalty/GenArtLoyalty.sol";

/**
 * @dev GEN.ART Minter Loyalty
 * Admin for collections deployed on {GenArtCurated}
 * Claims rebate from {GenArtLoyalty} on mint
 */

struct FixedPriceParams {
    uint256 startTime;
    uint256 price;
    address mintAllocContract;
    uint8[3] mintAlloc;
}

contract GenArtMinterLoyalty is
    GenArtMinterBase,
    GenArtLoyalty,
    ReentrancyGuard
{
    mapping(address => uint256) public prices;

    constructor(
        address genartInterface_,
        address genartCurated_,
        address genartVault_
    )
        GenArtMinterBase(genartInterface_, genartCurated_)
        GenArtLoyalty(genartVault_)
    {}

    /**
     * @dev Set pricing for collection
     * @param collection contract address of the collection
     * @param data encoded pricing data
     */
    function setPricing(address collection, bytes memory data)
        external
        override
        onlyAdmin
        returns (uint256)
    {
        FixedPriceParams memory params = abi.decode(data, (FixedPriceParams));
        super._setMintParams(
            collection,
            params.startTime,
            params.mintAllocContract
        );
        prices[collection] = params.price;
        IGenArtMintAllocator(params.mintAllocContract).init(
            collection,
            params.mintAlloc
        );

        return params.price;
    }

    /**
     * @dev Helper function to check for mint price and start date
     */
    function _checkMint(address collection, uint256 amount)
        internal
        view
        returns (uint256 price)
    {
        price = getPrice(collection);
        uint256 timestamp = mintParams[collection].startTime;
        uint256 value = price * amount;
        require(msg.value >= value, "wrong amount sent");
        require(
            timestamp != 0 && timestamp <= block.timestamp,
            "mint not started yet"
        );
    }

    /**
     * @dev Helper function to check for available mints for sender
     */
    function _checkAvailableMints(
        address collection,
        uint256 membershipId,
        uint256 amount
    ) internal view returns (bool) {
        uint256 availableMints = IGenArtMintAllocator(
            mintParams[collection].mintAllocContract
        ).getAvailableMintsForMembership(collection, membershipId);
        require(availableMints >= amount, "no mints available");
        (address owner, bool isVaulted) = IGenArtInterfaceV4(genartInterface)
            .ownerOfMembership(membershipId);
        require(owner == msg.sender, "sender must be owner of membership");

        return isVaulted;
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param membershipId owned GEN.ART membershipId
     */
    function mintOne(address collection, uint256 membershipId)
        external
        payable
        override
        nonReentrant
    {
        address user = _msgSender();
        bool isVaulted = _checkAvailableMints(collection, membershipId, 1);
        uint256 price = _checkMint(collection, 1);

        IGenArtMintAllocator(mintParams[collection].mintAllocContract).update(
            collection,
            membershipId,
            1
        );
        IGenArtERC721(collection).mint(user, membershipId);
        _splitPayment(collection, user, price, isVaulted ? 1 : 0, 1);
    }

    /**
     * @dev Mint a token
     * @param collection contract address of the collection
     * @param amount amount of tokens to mint
     */
    function mint(address collection, uint256 amount)
        external
        payable
        override
        nonReentrant
    {
        // get all available mints for sender
        uint256 price = _checkMint(collection, amount);

        address user = _msgSender();
        IGenArtInterfaceV4 iface = IGenArtInterfaceV4(genartInterface);
        // get all memberships for sender
        uint256[] memory memberships = iface.getMembershipsOf(user);
        uint256 minted;
        uint256 vaultedMints;
        uint256 i;
        IGenArtMintAllocator mintAlloc = IGenArtMintAllocator(
            mintParams[collection].mintAllocContract
        );
        // loop until the desired amount of tokens was minted
        while (minted < amount && i < memberships.length) {
            // get available mints for membership
            uint256 membershipId = memberships[i];
            uint256 mints = mintAlloc.getAvailableMintsForMembership(
                collection,
                membershipId
            );
            // mint tokens with membership and stop if desired amount reached
            uint256 j;
            for (j = 0; j < mints && minted < amount; j++) {
                IGenArtERC721(collection).mint(user, membershipId);
                minted++;
                if (iface.isVaulted(membershipId)) vaultedMints++;
            }
            // update mint state once membership minted tokens
            mintAlloc.update(collection, membershipId, j);
            i++;
        }
        require(minted > 0, "no mints available");
        _splitPayment(collection, user, price, vaultedMints, minted);
    }

    /**
     * @dev Internal function to forward funds to a {GenArtPaymentSplitter}
     */
    function _splitPayment(
        address collection,
        address user,
        uint256 price,
        uint256 vaultedMints,
        uint256 totalMints
    ) internal {
        uint256 value = msg.value;
        uint256 rebate = (price * baseRebateBps) / DOMINATOR;
        address paymentSplitter = GenArtCurated(genArtCurated)
            .store()
            .getPaymentSplitterForCollection(collection);
        IGenArtPaymentSplitterV5(paymentSplitter).splitPayment{
            value: value - (rebate * totalMints)
        }(value);
        uint256 rebateWindow = mintParams[collection].startTime +
            rebateWindowSec;
        if (vaultedMints > 0 && block.timestamp <= rebateWindow) {
            genartVault.lockUserWithdraw(user, rebateWindow);
            payable(user).transfer(
                ((rebate * vaultedMints * (DOMINATOR - loyaltyRewardBps)) /
                    DOMINATOR)
            );
        }
    }

    /**
     * @dev Get price for collection
     * @param collection contract address of the collection
     */
    function getPrice(address collection)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return prices[collection];
    }
}