// SPDX-License-Identifier: MIT

/**
*
*      ___           ___           ___           ___                    ___           ___                    ___           ___           ___           ___ 
*     /\__\         /\  \         /\  \         /\  \                  /\  \         /\  \                  /\  \         /\  \         /\  \         /\__\
*    /:/  /        /::\  \       /::\  \       /::\  \                 \:\  \       /::\  \                /::\  \       /::\  \       /::\  \       /:/  /
*   /:/__/        /:/\:\  \     /:/\:\  \     /:/\:\  \                 \:\  \     /:/\:\  \              /:/\:\  \     /:/\:\  \     /:/\:\  \     /:/  / 
*  /::\  \ ___   /::\~\:\  \   /::\~\:\  \   /::\~\:\  \                /::\  \   /:/  \:\  \            /:/  \:\  \   /:/  \:\  \   /:/  \:\  \   /:/  /  
* /:/\:\  /\__\ /:/\:\ \:\__\ /:/\:\ \:\__\ /:/\:\ \:\__\              /:/\:\__\ /:/__/ \:\__\          /:/__/ \:\__\ /:/__/ \:\__\ /:/__/ \:\__\ /:/__/   
* \/__\:\/:/  / \:\~\:\ \/__/ \/_|::\/:/  / \:\~\:\ \/__/             /:/  \/__/ \:\  \ /:/  /          \:\  \  \/__/ \:\  \ /:/  / \:\  \ /:/  / \:\  \   
*      \::/  /   \:\ \:\__\      |:|::/  /   \:\ \:\__\              /:/  /       \:\  /:/  /            \:\  \        \:\  /:/  /   \:\  /:/  /   \:\  \  
*      /:/  /     \:\ \/__/      |:|\/__/     \:\ \/__/              \/__/         \:\/:/  /              \:\  \        \:\/:/  /     \:\/:/  /     \:\  \ 
*     /:/  /       \:\__\        |:|  |        \:\__\                               \::/  /                \:\__\        \::/  /       \::/  /       \:\__\
*     \/__/         \/__/         \|__|         \/__/                                \/__/                  \/__/         \/__/         \/__/         \/__/
*
* @title Tres Cool Contract
* @author Tres Cool (www.trescool.xyz)
* @notice This contract is uniquely designed to hardcode in perpetual carbon removal to any NFT use case that adopts this standard.
* This is dedicated to Leanne's, Whitney's, and Monty's kids, & all current and future generations. May this help revert some of the 
* damage we've done so you will always have a beautiful world. 
*/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol";
import "../Carbon/ERCCooldown.sol";
import "../Finance/PaymentDistributor.sol";

pragma solidity ^0.8.2;

/// @dev Implementation of the TresCoolLabs ERCCooldown class to enable Carbon Removal for each NFT mint and sale.
contract TresCool is ERC721A, ERCCooldown, Ownable, ReentrancyGuard, PaymentDistributor {
    
    /* Public Variables */

    uint256 public minCost = 0.005 ether;
    uint128 public maxSupply = 1074;
    uint128 public maxMintAmountPerTx = 2;

    /* Private Variables */

    bool private _paused = true;
    string private _baseTokenURI;
    
    /* Construction */

    constructor() ERC721A("TresCool", "TCool") ERCCooldown(1000, 500, 500) { }

    /* Setters */

    /// @notice Sets the mint price in WEI
    function setMinCost(uint256 cost) external onlyOwner {
        minCost = cost;
    }

    /// @notice Sets the max supply of the collection
    function setMaxSupply(uint128 supply) external onlyOwner {
        maxSupply = supply;
    }

    /// @notice Sets the maximum number of tokens per mint
    function setMaxMintAmountPerTx(uint128 maxMints) external onlyOwner {
        maxMintAmountPerTx = maxMints;
    }

    /// @notice Sets the Token URI for the Metadata
    function setTokenURI(string memory uri) external onlyOwner {
        _baseTokenURI = uri;
    }

    /// @notice Sets the public mint to paused or not paused
    function setPaused(bool pause) external onlyOwner {
        _paused = pause;
    }

    /* Getters */

    /// @notice Gets all required config variables
    function getSettings() external view returns(uint256, uint128, uint128, uint256, bool) {
        return (minCost, maxMintAmountPerTx, maxSupply, _totalMinted(), _paused);
    }

    /* Metadata */

    /// @dev Override to pass in metadata URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /* Mint */

    /// @notice Public mint function that accepts a quantity and mints to the recipient.
    /// @dev Mint function with price and maxMints checks.
    function mint(address recipient, uint256 quantity) external payable nonReentrant {
        require(_paused == false, "Cannot mint while paused");
        require(msg.value >= quantity * minCost, "Must send at least the minimum cost to mint.");
        require(quantity <= maxMintAmountPerTx, "Cannot mint over maximum allowed mints per transaction");
        _mintCooldown(msg.value);
        _internalMint(recipient, quantity);
    }

    /// @notice Minting functionality for the contract owner which mints a quantity to a set address.
    /// @dev Owner mint with no checks other than those included in _internalMint().
    function ownerMint(address to, uint256 quantity) external onlyOwner nonReentrant {
        _internalMint(to, quantity);
    }

    /// @dev Internal mint function that runs basic max supply check and mints to a set address.
    function _internalMint(address to, uint256 quantity) private {
        require(_totalMinted() + quantity <= maxSupply, "Request exceeds maximum contract supply.");
        _safeMint(to, quantity);
    }

    /* Ownership */

    /// @notice Gets all the token IDs of an owner
    /// @dev Should not be called on chain. Runs a simple loop to calculate all the token IDs of a specific address.
    function tokensOfOwner(address owner) external view returns(uint256[] memory ownerTokens) {
        uint256 tokenCount = balanceOf(owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 total = totalSupply();
            uint256 resultIndex = 0;
            uint256 id;

            for (id = 0; id < total; id++) {
                if (ownerOf(id) == owner) {
                    result[resultIndex] = id;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    /// @notice Prevents ownership renouncement
    /// @dev overrides the internal renounceOwnership() function and does nothing.
    function renounceOwnership() public override onlyOwner {}

    /// @notice Burn function that destroys the token with the passed in ID.
    /// @dev Will burn only if the owner of the token calls this function.
    function burn(uint256 tokenID) public {
        require(ownerOf(tokenID) == msg.sender, "Msg.sender must be the owner of the token to burn.");
        _burn(tokenID);
    }

    /* Interface Support */

    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, ERCCooldown) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /* Fallbacks */

    /// @notice Processes a cooldown upon receiving funds
    /// @dev Passes the msg.value to the ERCCoolDown class to handle a transfer cooldown. This is where funds are secured for carbon removal.
    receive() payable external {
        _transferCooldown(msg.value);
    }

    /* Carbon */

    /// @notice Adjusts the royalty based on ERC2981 as well as the mint and transfer cool rates
    /// @dev Exposses the ERCCooldown.sol _adjustCoolRates with the onlyOwner modifier to protect from unwanted adjustments.
    function adjustCoolRates(uint16 royalty, uint16 transferCoolRate, uint16 mintCoolRate) external onlyOwner {
        _adjustCoolRates(royalty, transferCoolRate, mintCoolRate);
    }

    /* Funds */

    /// @notice Adds a payee to the distribution list
    /// @dev Internal redirect to PaymentDistributor._addPayee( ... )
    function addPayee(address payee, uint16 share) public onlyOwner {
        _addPayee(payee, share);
    }

    /// @notice Updates a payee to the distribution list
    /// @dev Internal redirect to PaymentDistributor._updatePayee( ... )
    function updatePayee(address payee, uint16 share) external onlyOwner {
        _updatePayee(payee, share);
    }

    /// @notice Removes a payee from the distribution list
    /// @dev Internal redirect to PaymentDistributor._removePayee( ... )
    function removePayee(address payee) external onlyOwner {
        _removePayee(payee);
    }

    /// @notice Fund distribution function.
    /** @dev Internal redirect to PaymentDistributor._distributeShares( ... ) which 
     *  will distribute the contract ETH balance based on assigned payees. If no
     *  payees set then the balance will be sent to the owner.
     */
    function distributeShares() external onlyOwner nonReentrant {
        _distributeShares();
    }

    /// @notice ERC20 fund distribution function.
    /** @dev Internal redirect to PaymentDistributor._distributeERC20Shares( ... ) which 
     *  will distribute the contract ERC20 balance based on assigned payees. If no
     *  payees set then the balance will be sent to the owner.
     */
    function distributeERC20Shares(address tokenAddress) external onlyOwner nonReentrant {
        _distributeERC20Shares(tokenAddress);
    }
}