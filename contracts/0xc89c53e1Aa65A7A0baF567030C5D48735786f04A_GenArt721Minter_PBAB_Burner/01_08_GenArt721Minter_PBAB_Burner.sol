// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc. with ERC721 burn stuff by Anthonye.eth

import "./IGenArt721CoreV2_PBAB.sol";
import "./IBonusContract.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

pragma solidity 0.8.9;

/**
 * @title Powered by Art Blocks minter contract that allows tokens to be
 * minted by burning any ERC-721 token.
 * @author Art Blocks Inc. Burn changes by Anthonye.eth
 */
contract GenArt721Minter_PBAB_Burner is ReentrancyGuard {
    /// PBAB core contract this minter may interact with.
    IGenArt721CoreV2_PBAB public genArtCoreContract;
    /// Contract that this minter will burn from.
    IERC721 public burnTokenContract;
    
    event BurnRedeem(uint256 burnedTokenTotal);

    uint256 constant ONE_MILLION = 1_000_000;

    address payable public ownerAddress;
    uint256 public ownerPercentage;

    mapping(uint256 => bool) public projectIdToBonus;
    mapping(uint256 => address) public projectIdToBonusContractAddress;
    mapping(uint256 => bool) public contractFilterProject;
    mapping(address => mapping(uint256 => uint256)) public projectMintCounter;
    mapping(uint256 => uint256) public projectMintLimit;
    mapping(uint256 => bool) public projectMaxHasBeenInvoked;
    mapping(uint256 => uint256) public projectMaxInvocations;
    mapping(uint256 => bool)public BurnedTokens;
    /**
     * @notice Initializes contract to be a Minter for PBAB core contract at
     * address `_genArt721Address`.
     */
    constructor(address _genArt721Address, address _burnTokenAddress) ReentrancyGuard() {
        genArtCoreContract = IGenArt721CoreV2_PBAB(_genArt721Address);
        burnTokenContract = IERC721(_burnTokenAddress);
    }

    /**
     * @notice Gets your balance of the ERC-20 token currently set
     * as the payment currency for project `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return balance Balance of ERC-20
     */
    function getYourBalanceOfProjectERC20(
        uint256 _projectId
    ) public view returns (uint256) {
        uint256 balance = IERC20(
            genArtCoreContract.projectIdToCurrencyAddress(_projectId)
        ).balanceOf(msg.sender);
        return balance;
    }

    /**
     * @notice Gets your allowance for this minter of the ERC-20
     * token currently set as the payment currency for project
     * `_projectId`.
     * @param _projectId Project ID to be queried.
     * @return remaining Remaining allowance of ERC-20
     */
    function checkYourAllowanceOfProjectERC20(
        uint256 _projectId
    ) public view returns (uint256) {
        uint256 remaining = IERC20(
            genArtCoreContract.projectIdToCurrencyAddress(_projectId)
        ).allowance(msg.sender, address(this));
        return remaining;
    }

    /**
     * @notice Sets the mint limit of a single purchaser for project
     * `_projectId` to `_limit`.
     * @param _projectId Project ID to set the mint limit for.
     * @param _limit Number of times a given address may mint the project's
     * tokens.
     */
    function setProjectMintLimit(uint256 _projectId, uint8 _limit) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        projectMintLimit[_projectId] = _limit;
    }

    /**
     * @notice Sets the maximum invocations of project `_projectId` based
     * on the value currently defined in the core contract.
     * @param _projectId Project ID to set the maximum invocations for.
     * @dev also checks and may refresh projectMaxHasBeenInvoked for project
     */
    function setProjectMaxInvocations(uint256 _projectId) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        uint256 maxInvocations;
        uint256 invocations;
        (, , invocations, maxInvocations, , , , , ) = genArtCoreContract
            .projectTokenInfo(_projectId);
        projectMaxInvocations[_projectId] = maxInvocations;
        if (invocations < maxInvocations) {
            projectMaxHasBeenInvoked[_projectId] = false;
        }
    }

    /**
     * @notice Sets the owner address to `_ownerAddress`.
     * @param _ownerAddress New owner address.
     */
    function setOwnerAddress(address payable _ownerAddress) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        ownerAddress = _ownerAddress;
    }

    /**
     * @notice Sets the owner mint revenue to `_ownerPercentage` percent.
     * @param _ownerPercentage New owner percentage.
     */
    function setOwnerPercentage(uint256 _ownerPercentage) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        ownerPercentage = _ownerPercentage;
    }

    /**
     * @notice Toggles if contracts are allowed to mint tokens for
     * project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function toggleContractFilter(uint256 _projectId) public {
        require(
            genArtCoreContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        contractFilterProject[_projectId] = !contractFilterProject[_projectId];
    }

    /**
     * @notice Toggles if bonus contract for project `_projectId`.
     * @param _projectId Project ID to be toggled.
     */
    function artistToggleBonus(uint256 _projectId) public {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId),
            "can only be set by artist"
        );
        projectIdToBonus[_projectId] = !projectIdToBonus[_projectId];
    }

    /**
     * @notice Sets bonus contract for project `_projectId` to
     * `_bonusContractAddress`.
     * @param _projectId Project ID to be toggled.
     * @param _bonusContractAddress Bonus contract.
     */
    function artistSetBonusContractAddress(
        uint256 _projectId,
        address _bonusContractAddress
    ) public {
        require(
            msg.sender ==
                genArtCoreContract.projectIdToArtistAddress(_projectId),
            "can only be set by artist"
        );
        projectIdToBonusContractAddress[_projectId] = _bonusContractAddress;
    }

    //  ERC721SeaDrop Burn Changes
    //  Cant use regular burn function or address, ERC721SeaDrop didnt have it.
    //  Moved if "(contractFilterProject[projectId]) .... 'No Contract Buys');}" from purchaseTo to new functions to reduce for loop gas cost
    //  Removed bonus contract and split code.

    /**
     * @notice Sets a new contract address to use as a `_burnTokenContract`
     * @param _burnTokenContract New contract address.
     */
    function setActiveBurnToken(address _burnTokenContract) public {
        require(genArtCoreContract.isWhitelisted(msg.sender),"can only be set by admin");
        burnTokenContract = IERC721(_burnTokenContract);
    }

    /**
     * @notice Purchases a token from project `projectId` by burning 'tokenId' 
     * @param projectId Project ID to mint a token on.
     * @param tokenId Token to burn.
     * @return _tokenId Token ID of minted token
     */
    function purchaseSingleWithBurn(uint256 projectId, uint256 tokenId) public nonReentrant returns (uint256 _tokenId) {
        if (contractFilterProject[projectId]) {
        require(msg.sender == tx.origin, 'No Contract Buys');
        }
        require(burnTokenContract.isApprovedForAll(msg.sender, address(this)), 'This contract is not approved to transfer the specified ERC721 token');     
        require(burnTokenContract.ownerOf(tokenId) == msg.sender, 'You do not own the specified ERC721 token');
        require(!BurnedTokens[tokenId],'This token is already burned');
        burnTokenContract.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenId);
        BurnedTokens[tokenId]=true;
        emit BurnRedeem(1);
        return purchaseTo(msg.sender,projectId); 
    }

    /**
     * @notice Purchases a token from project `projectId` by burning 'tokenIds' (up to 5 at a time)
     * @param projectId Project ID to mint a token on.
     * @param tokenIds Tokens to burn, up to 5.
     * @return _tokenIds Token ID of minted token
     */
    function purchaseManyWithBurn(uint256 projectId, uint256[] memory tokenIds) public nonReentrant returns (uint256[] memory _tokenIds) {
        if (contractFilterProject[projectId]) {
        require(msg.sender == tx.origin, 'No Contract Buys');
        }
        require(tokenIds.length <= 5, "You cannot burn more than 5 tokens at a time");
        require(burnTokenContract.isApprovedForAll(msg.sender, address(this)), 'This contract is not approved to transfer the specified ERC721 token');
        uint256[] memory newTokenIds = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(burnTokenContract.ownerOf(tokenIds[i]) == msg.sender, 'You do not own the specified ERC721 token');
            require(!BurnedTokens[tokenIds[i]],'This token is already burned');
            // Cant use regular burn function or address, ERC721SeaDrop didnt have it.
            burnTokenContract.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenIds[i]);
            BurnedTokens[tokenIds[i]]=true;
            newTokenIds[i] = purchaseTo(msg.sender,projectId);
        }
        emit BurnRedeem( tokenIds.length);
        return newTokenIds;    
    }


    /**
     * @notice Purchases a token from project `projectId` by burning 'tokenIds' (up to 5 at a time) and sets
     * the token's owner to `to`.
     * @param to Address to be the new token's owner.
     * @param projectId Project ID to mint a token on.
     * @param tokenIds Tokens to burn, up to 5.
     * @return _tokenIds Token ID of minted token
     */
    function purchaseToWithBurn(address to, uint256 projectId, uint256[] memory tokenIds) public nonReentrant returns (uint256[] memory _tokenIds) {
        if (contractFilterProject[projectId]) {
            require(msg.sender == tx.origin, "No Contract Buys");
        }
        require(tokenIds.length <= 5, "You cannot burn more than 5 tokens at a time");
        require(burnTokenContract.isApprovedForAll(msg.sender, address(this)), 'This contract is not approved to transfer the specified ERC721 token');
        uint256[] memory newTokenIds = new uint256[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(burnTokenContract.ownerOf(tokenIds[i]) == msg.sender, 'You do not own the specified ERC721 token');
            require(!BurnedTokens[tokenIds[i]],'This token is already burned');
            burnTokenContract.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tokenIds[i]);
            BurnedTokens[tokenIds[i]]=true;
            newTokenIds[i] = purchaseTo(to, projectId);
        }
        emit BurnRedeem( tokenIds.length);
        return newTokenIds;    
    }

    /**
     * @notice Purchases a token from project `_projectId` and sets
     * the token's owner to `_to`.
     * @param _to Address to be the new token's owner.
     * @param _projectId Project ID to mint a token on.
     * @return _tokenId Token ID of minted token
     */
    function purchaseTo(
        address _to,
        uint256 _projectId
    ) internal returns (uint256 _tokenId) {
        // CHECKS
        require(
            !projectMaxHasBeenInvoked[_projectId],
            "Maximum number of invocations reached"
        );
      
        // limit mints per address by project
        if (projectMintLimit[_projectId] > 0) {
            require(
                projectMintCounter[msg.sender][_projectId] <
                    projectMintLimit[_projectId],
                "Reached minting limit"
            );
            // EFFECTS
            projectMintCounter[msg.sender][_projectId]++;
        }

        uint256 tokenId = genArtCoreContract.mint(_to, _projectId, msg.sender);

        // What if this overflows, since default value of uint256 is 0?
        // That is intended, so that by default the minter allows infinite
        // transactions, allowing the `genArtCoreContract` to stop minting
        // `uint256 tokenInvocation = tokenId % ONE_MILLION;`
        if (
            projectMaxInvocations[_projectId] > 0 &&
            tokenId % ONE_MILLION == projectMaxInvocations[_projectId] - 1
        ) {
            projectMaxHasBeenInvoked[_projectId] = true;
        }


        return tokenId;
    }

    
}