// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ARBOBCTFaucet is ERC1155Holder, Ownable, ReentrancyGuard {
    // Address of the Artifacts (ERC1155) Contract
    IERC1155 public artifactsContract;
    // The fee to access the FanFaucet (FAF)
    uint256 public ethPrice;
    // The array of token ids that are in the inventory
    uint256[] public tokenIdsInventory;
    // The iteration of the FanFaucet campaign, allowing for reuse while restricting free withdrawals to numOfFreeRequestsAllowed
    uint256 public campaignId;
    // Number of free requests without FAF per wallet
    uint256 public numOfFreeRequestsAllowed;
    // Number of total requests allowed from the FanFaucet with and without FAF
    uint256 public numOfTotalRequestsAllowed;
    // List of whitelisted ERC token addresses for FanFaucet collabs
    address[] public whitelistedTokenAddressList;
    // Indicates if the FanFaucet is online or offlne
    bool public isOnline = false;

    // Map of whitelisted ERC token address and their details
    struct WhitelistToken {
        string standard;
        uint256[] tokenIdsArray;
        uint256[] amountsArray; // in decimal units as defined by the contract
        bool active;
    }

    mapping(address => WhitelistToken) public whitelistedTokens;

    // Map of wallet addresses and total FanFaucet requests per campaignId
    mapping(address => mapping(uint256 => uint256)) public withdrawn;

    // Events
    event FanFaucetWithdraw(address userAddress, uint256 tokenId);

    // Errors
    // Already used allotted free requests
    error AlreadyWithdrawnFree();
    // Already used allotted total requests
    error TooManyWithdrawn(uint256 withdrawnAmount);
    // FanFaucet is offline
    error FaucetOffline();
    // Nothing to claim
    error ContractBalanceEmpty();
    // Incorrect FanFaucet Access Fee
    error WrongEthAmountSent(uint256 ethAmount);
    // External seed not provided
    error EmptySeed();
    // Unsupported standard
    error WrongStandard();
    // Details on the collab tokens doesn't exist
    error TokenStructDoesNotExist();
    // Not whitelisted
    error NotEnoughWhitelistedTokens();

    // Constructoooor
    constructor(address _artifactsContract, uint256 _campaignId) {
        artifactsContract = IERC1155(_artifactsContract);
        campaignId = _campaignId;
    }

    function fanFaucetClaim(string calldata _randomSeed) external payable nonReentrant {
        if (isOnline == false) revert FaucetOffline();
        if (bytes(_randomSeed).length == 0) revert EmptySeed();
        // Check if the caller has already withdrawn more than the total allowed amount
        if (withdrawn[msg.sender][campaignId] >= numOfTotalRequestsAllowed)
            revert TooManyWithdrawn(withdrawn[msg.sender][campaignId]);
        // Check if we need to collect payment, by checking if total withdrawn is >= numOfFreeRequestsAllowed
        if (withdrawn[msg.sender][campaignId] >= numOfFreeRequestsAllowed && msg.value != ethPrice)
            revert WrongEthAmountSent(msg.value);
        // Check if tokens are required to access the Faucet
        if (whitelistedTokenAddressList.length > 0) {
            bool accessGranted = false;

            if (whitelistedTokenAddressList.length == 1) {
                accessGranted = checkWhitelistedTokens(0);
            } else {
                for (uint256 i = 0; i < whitelistedTokenAddressList.length; i++) {
                    accessGranted = checkWhitelistedTokens(i);
                    if (accessGranted) break;
                }
            }
            if (!accessGranted) revert NotEnoughWhitelistedTokens();
        }

        // Generate a random number using keccak256
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    msg.sender,
                    _randomSeed,
                    withdrawn[msg.sender][campaignId]
                )
            )
        );

        // Generate a random number within the range of the token ids array length
        uint256 randomIndex = randomNumber % (tokenIdsInventory.length);

        uint256 availableTokenId = findTokenWithBalance(randomIndex);

        // Withdraw 1 ERC1155 token from the contract
        withdrawn[msg.sender][campaignId] = withdrawn[msg.sender][campaignId] + 1;
        artifactsContract.safeTransferFrom(address(this), msg.sender, availableTokenId, 1, "");
        emit FanFaucetWithdraw(msg.sender, availableTokenId);
    }

    function checkWhitelistedTokens(uint256 _index) private view returns (bool access) {
        address tokenAddress = whitelistedTokenAddressList[_index];
        WhitelistToken memory tokenStruct = whitelistedTokens[tokenAddress];

        if (keccak256(abi.encodePacked(tokenStruct.standard)) == keccak256(abi.encodePacked("erc20"))) {
            if (IERC20(tokenAddress).balanceOf(msg.sender) >= tokenStruct.amountsArray[0]) return true;
        }

        if (keccak256(abi.encodePacked(tokenStruct.standard)) == keccak256(abi.encodePacked("erc721"))) {
            for (uint256 i = 0; i < tokenStruct.tokenIdsArray.length; i++) {
                if (IERC721(tokenAddress).ownerOf(tokenStruct.tokenIdsArray[i]) == msg.sender) return true;
            }
        }

        if (keccak256(abi.encodePacked(tokenStruct.standard)) == keccak256(abi.encodePacked("erc1155"))) {
            for (uint256 i = 0; i < tokenStruct.tokenIdsArray.length; i++) {
                if (
                    IERC1155(tokenAddress).balanceOf(msg.sender, tokenStruct.tokenIdsArray[i]) >=
                    tokenStruct.amountsArray[i]
                ) return true;
            }
        }

        return false;
    }

    function findTokenWithBalance(uint256 _randomIndex) private view returns (uint256 availableTokenId) {
        if (artifactsContract.balanceOf(address(this), tokenIdsInventory[_randomIndex]) > 0) {
            return tokenIdsInventory[_randomIndex];
        }

        uint256 newIndex = _randomIndex + 1;

        for (uint256 i = 0; i < tokenIdsInventory.length; i++) {
            if (newIndex > tokenIdsInventory.length) {
                newIndex = 0;
            }

            if (newIndex == _randomIndex) revert ContractBalanceEmpty();

            if (artifactsContract.balanceOf(address(this), tokenIdsInventory[newIndex]) > 0) {
                return tokenIdsInventory[newIndex];
            }

            newIndex = newIndex + 1;
        }
    }

    // External views
    function getTokenIdsInventory() external view returns (uint256[] memory) {
        return tokenIdsInventory;
    }

    function getTotalClaims(address _userAddress, uint256 _campaignId) external view returns (uint256) {
        return withdrawn[_userAddress][_campaignId];
    }

    function getWhitelistedTokenAddressList() external view returns (address[] memory) {
        return whitelistedTokenAddressList;
    }

    function getWhitelistedTokenDetails(address _contractAddress) external view returns (WhitelistToken memory) {
        return whitelistedTokens[_contractAddress];
    }

    // Owner controls
    function enableFaucet() external onlyOwner {
        isOnline = true;
    }

    function disableFaucet() external onlyOwner {
        isOnline = false;
    }

    function setTokenIdsInventory(uint256[] calldata _tokenIds) external onlyOwner {
        tokenIdsInventory = _tokenIds;
    }

    function setNumOfTotalRequestsAllowed(uint256 _totalAllowed) external onlyOwner {
        numOfTotalRequestsAllowed = _totalAllowed;
    }

    function setNumOfFreeRequestsAllowed(uint256 _freeAllowed) external onlyOwner {
        numOfFreeRequestsAllowed = _freeAllowed;
    }

    // Start a new campaign and fresh wallet claim record
    function setCampaignId(uint256 _campaignId) external onlyOwner {
        campaignId = _campaignId;
    }

    // FanFaucetAccessFee in wei
    function setFanFaucetAccessFee(uint256 _ethPrice) external onlyOwner {
        ethPrice = _ethPrice;
    }

    // Set WhitelistToken struct for every whitelist contract before adding to this array
    // This ensures the address list will always have corresponding structs in storage and one can be removed easily
    function setWhitelistedTokenAddressList(address[] calldata _whitelistedTokenAddressList) external onlyOwner {
        for (uint256 i = 0; i < _whitelistedTokenAddressList.length; i++) {
            address tokenAddress = _whitelistedTokenAddressList[i];
            WhitelistToken memory tokenStruct = whitelistedTokens[tokenAddress];

            if (!tokenStruct.active) revert TokenStructDoesNotExist();
        }

        whitelistedTokenAddressList = _whitelistedTokenAddressList;
    }

    function setWhitelistedTokenDetails(
        string calldata _tokenStandard,
        address _contractAddress,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external onlyOwner {
        if (
            keccak256(abi.encodePacked(_tokenStandard)) == keccak256(abi.encodePacked("erc20")) ||
            keccak256(abi.encodePacked(_tokenStandard)) == keccak256(abi.encodePacked("erc721")) ||
            keccak256(abi.encodePacked(_tokenStandard)) == keccak256(abi.encodePacked("erc1155"))
        ) {
            whitelistedTokens[_contractAddress].standard = _tokenStandard;
            whitelistedTokens[_contractAddress].tokenIdsArray = _tokenIds;
            whitelistedTokens[_contractAddress].amountsArray = _amounts;
            whitelistedTokens[_contractAddress].active = true;
        } else {
            revert WrongStandard();
        }
    }

    function removeWhitelistedToken(address[] calldata _contractAddresses) external onlyOwner {
        for (uint256 i = 0; i < _contractAddresses.length; i++) {
            delete whitelistedTokens[_contractAddresses[i]];
        }
    }

    function withdrawAll() external onlyOwner {
        uint256[] memory amountsArray = new uint256[](tokenIdsInventory.length);

        // Loop through all of the ERC-1155s owned by the contract
        for (uint256 i = 0; i < tokenIdsInventory.length; i++) {
            uint256 balance = artifactsContract.balanceOf(address(this), tokenIdsInventory[i]);
            amountsArray[i] = balance;
        }

        artifactsContract.safeBatchTransferFrom(address(this), owner(), tokenIdsInventory, amountsArray, "");
    }

    function withdrawSingleId(uint256 _tokenId) external onlyOwner {
        uint256 balance = artifactsContract.balanceOf(address(this), _tokenId);
        artifactsContract.safeTransferFrom(address(this), owner(), _tokenId, balance, "");
    }

    function withdrawEth() external onlyOwner {
        address payable to = payable(owner());
        to.transfer(address(this).balance);
    }

}