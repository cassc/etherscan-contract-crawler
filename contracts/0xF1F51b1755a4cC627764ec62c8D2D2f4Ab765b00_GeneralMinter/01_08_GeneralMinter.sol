// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC721A.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./PriceConverter.sol";
import "./IDelegationRegistry.sol";

error GeneralMinter__CollectionNotEligible();
error GeneralMinter__AllPersonalFreeMintsClaimed();
error GeneralMinter__AllGeneralFreeMintsClaimed();
error GeneralMinter__NftBalanceTooLow();
error GeneralMinter__NoContractsAllowed();
error GeneralMinter__NotEnoughFunds();
error GeneralMinter__TransferFailed();
error GeneralMinter__NotDelegated();

interface VerodmiGenerals {
    function mintGeneral(address to, uint256 quantity) external;
}

contract GeneralMinter is Ownable, ReentrancyGuard {
    using PriceConverter for uint256;

    VerodmiGenerals internal immutable i_generals;
    AggregatorV3Interface internal immutable i_priceFeed;
    IDelegationRegistry internal immutable i_delegate;

    uint256 constant USD_PRICE = 9 * 10 ** 18;

    mapping(address => bool) private freeMintCollections;
    mapping(address => uint256) private numberOfFreeMints;

    uint256 private s_amountFreeClaims = 0;
    uint256 private s_maxFreeClaims = 3;

    constructor(address generalContract, address priceFeedAddress, address delegateContract) {
        i_generals = VerodmiGenerals(generalContract);
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_delegate = IDelegationRegistry(delegateContract);
    }

    function claimFreeMint(uint256 amount, address freeMintAddress, address vaultAddress) external {
        // Collection must be allowed to claim a free General
        if (!freeMintCollections[freeMintAddress]) {
            revert GeneralMinter__CollectionNotEligible();
        }

        // Sender can at max claim 3 free mints
        if (numberOfFreeMints[msg.sender] + amount > s_maxFreeClaims) {
            revert GeneralMinter__AllPersonalFreeMintsClaimed();
        }

        // Only less than or equal to 1500 can been claimed for free
        if (s_amountFreeClaims + amount > 1500) {
            revert GeneralMinter__AllGeneralFreeMintsClaimed();
        }

        // Sender must not be a contract
        if (msg.sender != tx.origin) {
            revert GeneralMinter__NoContractsAllowed();
        }

        // Sender must own NFT from the free mint collection
        IERC721A nft = IERC721A(freeMintAddress);

        // If sender is using the delegate contract
        if (vaultAddress != (address(0))) {
            // Check that they are in fact delegated
            if (i_delegate.checkDelegateForContract(msg.sender, vaultAddress, freeMintAddress)) {
                // Check that the vault owns the NFT, and if not, revert
                if (!(nft.balanceOf(vaultAddress) > 0)) {
                    revert GeneralMinter__NftBalanceTooLow();
                }

                // If they are not delegated, revert
            } else {
                revert GeneralMinter__NotDelegated();
            }

            // If sender is not using delegate contract
        } else {
            // Check if sender themselves own NFT, and if not, revert
            if (!(nft.balanceOf(msg.sender) > 0)) {
                revert GeneralMinter__NftBalanceTooLow();
            }
        }

        // If it hasn't reverted by now then the user is allowed to mint.
        unchecked {
            s_amountFreeClaims += amount;
        }
        numberOfFreeMints[msg.sender] += amount;
        i_generals.mintGeneral(msg.sender, amount);
    }

    function mintGeneral(uint256 amount) external payable nonReentrant {
        require(
            msg.value.getConversionRate(i_priceFeed) >= USD_PRICE * amount,
            "Insufficent amount of ETH."
        );
        i_generals.mintGeneral(msg.sender, amount);
        // Sent back remaining ETH
        if (msg.value.getConversionRate(i_priceFeed) > USD_PRICE * amount) {
            uint256 costInUsd = USD_PRICE * amount;

            uint256 costInEth = costInUsd.getEthAmountFromUsd(i_priceFeed);
            uint256 remainingEth = (msg.value - costInEth);
            (bool callSuccess, ) = payable(msg.sender).call{value: remainingEth}("");
            require(callSuccess, "Refund failed");
        }
    }

    function addFreeMintCollection(address contractAddress) external onlyOwner {
        freeMintCollections[contractAddress] = true;
    }

    function removeFreeMintCollection(address contractAddress) external onlyOwner {
        freeMintCollections[contractAddress] = false;
    }

    function setMaxFreeClaims(uint256 amount) external onlyOwner {
        s_maxFreeClaims = amount;
    }

    function withdrawFunds() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if (!success) {
            revert GeneralMinter__TransferFailed();
        }
    }

    // View

    function isFreeMintCollection(address contractAddress) public view returns (bool) {
        return freeMintCollections[contractAddress];
    }

    function priceInEth() external view returns (uint256) {
        return USD_PRICE.getEthAmountFromUsd(i_priceFeed);
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return i_priceFeed;
    }

    function getMaxFreeClaims() public view returns (uint256) {
        return s_maxFreeClaims;
    }
}