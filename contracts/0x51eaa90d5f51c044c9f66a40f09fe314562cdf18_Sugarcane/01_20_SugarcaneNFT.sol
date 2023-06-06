// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOGToken.sol";

contract Sugarcane is ERC721, ERC2981, ERC721Enumerable, Pausable, Ownable {
    uint256 public maximumMintedPerAddress = 10;
    IOGToken public ogToken;
    uint256[5] public pricePerTier = [
        0,
        700000000000000000000,
        1000000000000000000000,
        1200000000000000000000,
        1500000000000000000000
    ];
    uint256[5] public tokensLeftPerTier = [100, 100, 100, 100, 100];
    uint256 public unlockedTier = 1;
    IERC20 public immutable usdc;
    uint256 public immutable timeLockTimestamp;
    uint256 public constant TOTAL_SUPPLY_LOCK = 500;

    //Events
    event Withdrawn(uint256 amount, address recipient);
    event RoyaltyInformationChanged(address receiver, uint256 royalty);

    //Mappings
    mapping(address => uint256) public addressToTokensMinted;
    mapping(address => uint256) public whitelistReserved;
    mapping(address => bool) public whitelist;
    mapping(uint256 => bool) public tokenClaimed;
    uint256 private currentTokenId = 101;
    uint256 private currentWhitelistedTokenId = 1;

    constructor(
        address usdc_,
        uint256 timeLockTimestamp_
    ) ERC721("Sugarcane", "CANE") {
        usdc = IERC20(usdc_);
        timeLockTimestamp = timeLockTimestamp_;
        setRoyaltyInformation(msg.sender, 800);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * ClaimOG Function
     * @notice      changes the status of a token to claimed
     * @param tokenId     the token ID to claim
     */
    function claimOG(uint256 tokenId) external {
        _requireMinted(tokenId);
        require(msg.sender == ownerOf(tokenId), "SugarcaneNFT: Invalid callee");
        require(!tokenClaimed[tokenId], "SugarcaneNFT: Claimed");
        tokenClaimed[tokenId] = true;
        ogToken.redeem(msg.sender, tokenId);
    }

    /**
     * withdrawUSDCBalance
     * @notice    sends usdc from the NFT contract to the Multi-Sig Wallet
     */
    function withdrawUSDCBalance(address recipient) external onlyOwner {
        emit Withdrawn(usdc.balanceOf(address(this)), recipient);
        require(
            usdc.transfer(recipient, usdc.balanceOf(address(this))),
            "SugarcaneNFT: Transfer reverted"
        );
    }

    /**
     * withdrawETHBalance
     * @notice    sends ETH from the NFT contract to the Multi-Sig Wallet
     */
    function withdrawETHBalance(address recipient) external onlyOwner {
        uint ETH = address(this).balance;
        require(ETH > 0, "SugarcaneNFT: There is no ETH to be sent");
        emit Withdrawn(ETH, recipient);
        (bool success, ) = recipient.call{value: ETH}("");
        require(success, "SugarcaneNFT: Transfer failed");
    }

    /**
     * Change ogToken  address
     * @notice changes the ogToken Contract address
     * @param  contractAddress of the new ogToken Contract address
     */
    function setOGContract(address contractAddress) external onlyOwner {
        require(
            IOGToken(contractAddress).supportsInterface(
                type(IOGToken).interfaceId
            ),
            "SugarcaneNFT: Does not support its interface"
        );
        ogToken = IOGToken(contractAddress);
    }

    /**
     * Change Minting Limit
     * @notice changes the maximum miniting limit for all accounts
     * @param  mintingLimit amount
     */
    function changeMintLimit(uint256 mintingLimit) external onlyOwner {
        require(
            mintingLimit <= 500,
            "SugarcaneNFT: The minting limit can not be more that 500"
        );
        maximumMintedPerAddress = mintingLimit;
    }

    /**
     * SetTierPrice
     * @notice  sets price for the selected tier
     * @param tier to be updated
     * @param newPrice  in usdc in WEI notation
     */
    function setTierPrice(uint256 tier, uint256 newPrice) external onlyOwner {
        pricePerTier[tier] = newPrice;
    }

    /**
     * UnlockTier
     * @notice unlock next tier for purchase
     */
    function unlockTier() public onlyOwner {
        unlockedTier++;
    }

    /**
     * whitelistReservedAddresses
     * @notice Enables wallets to mint reserved tokenIds
     * @param  addresses set to have their reserved amount of tokenIds
     * @param setTo amount
     */
    function whitelistAddressesForReserved(
        address[] memory addresses,
        uint256 setTo
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelistReserved[addresses[i]] = setTo;
        }
    }

    /**
     * WhitelistAddresses
     * @notice Enables wallets to mint
     * @param  addresses to give permissions to
     * @param setTo allowed or not
     */
    function whitelistAddresses(
        address[] memory addresses,
        bool setTo
    ) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = setTo;
        }
    }

    /**
     * CheckClaimEligibility
     * @notice Required by Paper, https://docs.withpaper.com/reference/eligibilitymethod
     * @param to which wallet should be check for eligibility
     * @param quantity of tokens to be checked
     */
    function checkClaimEligibility(
        address to,
        uint256 quantity
    ) external view returns (string memory) {
        if (paused()) {
            return "Contract is paused";
        } else if (!whitelist[to]) {
            return "SugarcaneNFT: The address is not whitelisted";
        } else if (quantity == 0) {
            return "SugarcaneNFT: Mint at least 1 Sugarcane";
        } else if (
            quantity + addressToTokensMinted[to] > maximumMintedPerAddress
        ) {
            return "SugarcaneNFT: You have reached your limit of Sugarcanes";
        }
        return "";
    }

    /**
     * SafeMint
     * @notice mints the number of tokens requested if all the conditions are met
     * @param to which wallet should those be sent
     * @param orderQuantity of tokens to mint
     */
    function safeMint(
        address to,
        uint256 orderQuantity
    ) external whenNotPaused {
        require(whitelist[to], "SugarcaneNFT: You are not whitelisted");
        require(orderQuantity > 0, "SugarcaneNFT: Mint at least 1 Sugarcane");
        require(
            orderQuantity + addressToTokensMinted[to] <=
                maximumMintedPerAddress,
            "SugarcaneNFT: You have reached your limit of Sugarcanes"
        );

        addressToTokensMinted[to] += orderQuantity;

        uint256 reservedTokensToMint;

        if (whitelistReserved[to] > 0 && tokensLeftPerTier[0] > 0) {
            if (
                whitelistReserved[to] >= orderQuantity &&
                tokensLeftPerTier[0] >= orderQuantity
            ) {
                reservedTokensToMint = orderQuantity;
            } else if (tokensLeftPerTier[0] > whitelistReserved[to]) {
                reservedTokensToMint = whitelistReserved[to];
            } else {
                reservedTokensToMint = tokensLeftPerTier[0];
            }

            // Update the counters of reserved tokens
            tokensLeftPerTier[0] -= reservedTokensToMint;
            whitelistReserved[to] -= reservedTokensToMint;
        }

        uint256 tokensToMint = reservedTokensToMint;
        uint256 totalUSDC;

        for (
            uint256 i = 1;
            i < tokensLeftPerTier.length &&
                unlockedTier >= i &&
                tokensToMint < orderQuantity;
            i++
        ) {
            if (tokensLeftPerTier[i] == 0) {
                continue;
            }

            uint256 orderTokensLeft = orderQuantity - tokensToMint;

            if (tokensLeftPerTier[i] >= orderTokensLeft) {
                totalUSDC += orderTokensLeft * pricePerTier[i];
                tokensToMint += orderTokensLeft;
                tokensLeftPerTier[i] -= orderTokensLeft;
            } else {
                totalUSDC += tokensLeftPerTier[i] * pricePerTier[i];
                tokensToMint += tokensLeftPerTier[i];
                tokensLeftPerTier[i] = 0;
            }
        }

        if (totalUSDC > 0) {
            require(
                usdc.transferFrom(msg.sender, address(this), totalUSDC),
                "SugarcaneNFT: Transfer reverted"
            );
        }

        for (uint256 i = 0; i < tokensToMint; i++) {
            _safeMint(
                to,
                i < reservedTokensToMint
                    ? currentWhitelistedTokenId
                    : currentTokenId
            );
            i < reservedTokensToMint
                ? currentWhitelistedTokenId++
                : currentTokenId++;
        }
    }

    /**
     * SetRoyaltyInformation
     * @notice  sets the royalty receiver and the feeNumerator
     * @param  royaltyReceiver      the address that receives the royalties
     * @param feeNumerator percentage of the sale that goes to the royaltyReceiver
     */
    function setRoyaltyInformation(
        address royaltyReceiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setDefaultRoyalty(royaltyReceiver, feeNumerator);
        emit RoyaltyInformationChanged(royaltyReceiver, feeNumerator);
    }

    /**
     * BeforeTokenTransfer
     * @notice     from Open Zeppelin wizard contract, executes functions before the contract
     * @param from address from the token is transferred
     * @param to   address to the token is sent
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 _batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, _batchSize);
        require(
            from == address(0) ||
                tokenClaimed[tokenId] ||
                block.timestamp >= timeLockTimestamp ||
                this.totalSupply() >= TOTAL_SUPPLY_LOCK,
            "SugarcaneNFT: Either token haven't been redeem, timelock or total supply lock is still active"
        );
    }

    /**
     * tokenURI Override
     * @notice   overrides the super TokenURI method to implement the changing of claimed tokens
     * @param  tokenId      the token ID to get the Token URI
     */
    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        _requireMinted(tokenId);
        if (!tokenClaimed[tokenId]) {
            // Unclaimed
            return "ipfs://QmcWJJPpeQrQ6aRfnptd1nfmo7eUGCVXVqJcU1XM4WDHEG";
        } else {
            // Claimed
            return "ipfs://QmWepun7vY9pUzjQ1XPtwqaBrziQg2u8Tsu5K4ytcEgGkR";
        }
    }

    /**
     * Sugarcanes in Wallet
     * @notice             returns the list of all owned tokens from an specific address
     * @param  wallet      the address to be checked
     * @return tokenIds    the list of tokens owned by the address
     */
    function walletOfOwner(
        address wallet
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(wallet);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(wallet, i);
        }
        return tokenIds;
    }

    function allPricesPerTier() external view returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](pricePerTier.length);
        for (uint256 i; i < pricePerTier.length; i++) {
            prices[i] = pricePerTier[i];
        }
        return prices;
    }

    function allTokensLeftPerTier() external view returns (uint256[] memory) {
        uint256[] memory tokensPerTier = new uint256[](
            tokensLeftPerTier.length
        );
        for (uint256 i; i < tokensLeftPerTier.length; i++) {
            tokensPerTier[i] = tokensLeftPerTier[i];
        }
        return tokensPerTier;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC721Enumerable.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }
}