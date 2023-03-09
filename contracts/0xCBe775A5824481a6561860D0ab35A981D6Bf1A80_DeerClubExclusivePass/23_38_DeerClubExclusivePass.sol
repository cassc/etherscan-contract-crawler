// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ERC721SeaDropBurnable } from "./extensions/ERC721SeaDropBurnable.sol";

import { IERC721A, ERC721A } from "lib/ERC721A/contracts/ERC721A.sol";

/*
 ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
 ▓▓                                                                                            ▓▓
 ▓▓                  ▓▓      ▓▓                                ▓▓      ▓▓                      ▓▓
 ▓▓                 ▓▓    ▓▓▓▓                                  ▓▓▓▓    ▓▓                     ▓▓
 ▓▓                 ▓▓▓▓  ▓▓                                      ▓▓  ▓▓▓▓                     ▓▓
 ▓▓                    ▓▓▓▓▓▓      ▓▓                    ▓▓      ▓▓▓▓▓▓                        ▓▓
 ▓▓                       ▓▓▓▓▓▓    ▓▓  ▓▓            ▓▓  ▓▓    ▓▓▓▓▓▓                         ▓▓
 ▓▓                         ▓▓▓▓▓▓  ▓▓▓▓                ▓▓▓▓  ▓▓▓▓▓▓                           ▓▓      
 ▓▓                             ▓▓▓▓▓▓▓▓                ▓▓▓▓▓▓▓▓                               ▓▓
 ▓▓                                 ▓▓▓▓                ▓▓▓▓                                   ▓▓
 ▓▓                                   ▓▓▓▓            ▓▓▓▓                                     ▓▓
 ▓▓                                     ▓▓▓▓        ▓▓▓▓                                       ▓▓
 ▓▓                                   ▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒                                     ▓▓
 ▓▓                     ▓▓▓▓▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒  ▒▒▒▒▒▒▓▓▓▓                       ▓▓
 ▓▓                       ▓▓░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▓▓                         ▓▓
 ▓▓                         ░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░                           ▓▓
 ▓▓                           ░░░░▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░▒▒░░░░                             ▓▓
 ▓▓                               ░░░░░░░░░░▒▒▒▒▒▒▒▒░░░░░░░░░░                                 ▓▓
 ▓▓                               ░░▓▓▓▓░░░░░░▒▒▒▒░░░░░░▓▓▓▓░░                                 ▓▓
 ▓▓                               ░░░░▓▓░░░░░░▒▒▒▒░░░░░░▓▓░░░░                                 ▓▓
 ▓▓                                 ░░░░░░░░░░▒▒▒▒░░░░░░░░░░                                   ▓▓
 ▓▓                                 ▒▒░░░░░░▓▓▒▒▒▒▓▓░░░░░░▒▒                                   ▓▓
 ▓▓                                 ▒▒░░░░░░░░▓▓▓▓░░░░░░░░▒▒                                   ▓▓
 ▓▓                                 ▒▒░░░░░░░░▓▓▓▓░░░░░░░░▒▒                                   ▓▓
 ▓▓                                 ▒▒▒▒░░▓▓▓▓▓▓▓▓▓▓▓▓░░▒▒▒▒▒▒                                 ▓▓
 ▓▓                                   ▒▒▒▒░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒                               ▓▓
 ▓▓                                   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒                         ▓▓
 ▓▓                                   ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒                           ▓▓
 ▓▓                                     ▒▒░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒                             ▓▓
 ▓▓                                     ▒▒▒▒░░░░░░░░░░░░▒▒▒▒▒▒                                 ▓▓
 ▓▓                                       ▒▒░░░░░░░░░░░░▒▒▒▒                                   ▓▓
 ▓▓                                         ▒▒░░░░░░░░░░▒▒▒▒                                   ▓▓
 ▓▓                                           ▒▒░░░░░░▒▒▒▒                                     ▓▓
 ▓▓                                             ░░░░░░▒▒▒▒                                     ▓▓
 ▓▓                                               ░░░░▒▒                                       ▓▓
 ▓▓                                                 ░░▒▒                                       ▓▓
 ▓▓                                                                                            ▓▓
 ▓▓                                  DEER CLUB EXCLUSIVE PASS                                  ▓▓
 ▓▓                                                                                            ▓▓
 ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
*/


contract DeerClubExclusivePass is ERC721SeaDropBurnable {
    string private constant BASE_EXTENSION = ".json";

    struct TokenMintInfo {
        address creater;
        uint64 mintedTimestamp;
    }

    TokenMintInfo[] private tokenMintInfos;

    // Mapping from token ID to creator address and minted time
    mapping(uint => uint) private tokenMintInfo;

    // The tier struct will keep all the information about the tier
    struct Tier {
        uint16 totalSupply;
        uint16 maxSupply;
        uint16 startingIndex;
    }

    mapping (uint=>Tier) public tiers;
    mapping (uint=>uint) public metadataUri;

    mapping(uint => uint) private assignOrders;
    uint private dceRemainingToAssign;

    /**
     * @notice Deploy the token contract with its name, symbol,
     *         and allowed SeaDrop addresses.
     */
    constructor(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) ERC721SeaDropBurnable(name, symbol, allowedSeaDrop) {
    }

    /**
     * @dev Set each tier's info of the contract.
     */
    function setTierInfo(uint16[] memory maxSupplies, uint16[] memory startIndexes) external {
        _onlyOwnerOrSelf();
        require(maxSupplies.length == startIndexes.length, "Wrong values");
        for (uint i=0; i<maxSupplies.length; i++) {
            tiers[i+1] = Tier({totalSupply: 0, maxSupply: maxSupplies[i], startingIndex: startIndexes[i]});
        }
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) 
            public 
            view 
            virtual 
            override(IERC721A, ERC721A) 
            returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(metadataUri[tokenId]), BASE_EXTENSION)) : '';
    }

    /**
     * @notice Mint tokens, restricted to the SeaDrop contract.
     *
     * @dev    NOTE: If a token registers itself with multiple SeaDrop
     *         contracts, the implementation of this function should guard
     *         against reentrancy. If the implementing token uses
     *         _safeMint(), or a feeRecipient with a malicious receive() hook
     *         is specified, the token or fee recipients may be able to execute
     *         another mint in the same transaction via a separate SeaDrop
     *         contract.
     *         This is dangerous if an implementing token does not correctly
     *         update the minterNumMinted and currentTotalSupply values before
     *         transferring minted tokens, as SeaDrop references these values
     *         to enforce token limits on a per-wallet and per-stage basis.
     *
     *         ERC721A tracks these values automatically, but this note and
     *         nonReentrant modifier are left here to encourage best-practices
     *         when referencing this contract.
     *
     * @param minter   The address to mint to.
     * @param quantity The number of tokens to mint.
     */

    function mintSeaDrop(address minter, uint256 quantity)
        external
        virtual
        override
        nonReentrant
    {
        // Ensure the SeaDrop is allowed.
        _onlyAllowedSeaDrop(msg.sender);

        // Extra safety check to ensure the max supply is not exceeded.
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }

        // Mint the quantity of tokens to the minter.
        uint startTokenId = _nextTokenId();

        _safeMint(minter, quantity);

        uint nextTokenId = _nextTokenId();

        tokenMintInfos.push(TokenMintInfo({
            creater: minter,
            mintedTimestamp: uint64(block.timestamp)
        }));

        for (uint i=startTokenId; i<nextTokenId; i++) {
            tokenMintInfo[i] = tokenMintInfos.length - 1;

            // Generate randomized tokenUri
            randomUri(i);
        }
    }

    /** 
     *  @dev Initates the random numbers request
     */
    function randomUri(uint tokenId) internal {
        if (dceRemainingToAssign == 0)
            dceRemainingToAssign = _maxSupply;

        uint randIndex = _random(tokenId) % dceRemainingToAssign;
        uint uri = _fillAssignOrder(--dceRemainingToAssign, randIndex) + 1;

        if (tiers[1].startingIndex <= uri && tiers[2].startingIndex > uri) {
            require(tiers[1].totalSupply < tiers[1].maxSupply, "Too supply in Tier1");
            tiers[1].totalSupply ++;
        }
        else if (tiers[2].startingIndex <= uri && tiers[3].startingIndex > uri) {
            require(tiers[2].totalSupply < tiers[2].maxSupply, "Too supply in Tier2");
            tiers[2].totalSupply ++;
        }
        else {
            require(tiers[3].totalSupply < tiers[3].maxSupply, "Too supply in Tier3");
            tiers[3].totalSupply ++;
        }

        metadataUri[tokenId] = uri;
    }

    /**
     * @dev Generated the random number.
     */
    function _random(uint index) internal view returns(uint) {
        return uint(
            keccak256(
                abi.encodePacked(block.timestamp + block.difficulty
                    + ((uint(keccak256(abi.encodePacked(block.coinbase)))) / block.timestamp)
                    + block.gaslimit + ((uint(keccak256(abi.encodePacked(msg.sender)))) / block.timestamp)
                    + block.number + index)
            )
        ) / dceRemainingToAssign;
    }

    /**
     * @dev Check and regenerated the random number.
     */
    function _fillAssignOrder(uint orderA, uint orderB) internal returns(uint) {
        uint temp = orderA;
        if (assignOrders[orderA] != 0) temp = assignOrders[orderA];
        assignOrders[orderA] = orderB;
        if (assignOrders[orderB] != 0) assignOrders[orderA] = assignOrders[orderB];
        assignOrders[orderB] = temp;
        return assignOrders[orderA];
    }

    /**
    * @dev Get the tokenId's information
    */
    function getTokenMintInfo(uint tokenId) public view returns (TokenMintInfo memory) {
        uint index = tokenMintInfo[tokenId];
        return tokenMintInfos[index];
    }

    /**
    * @dev Get the tokenId's tier's info
    */
    function getTiersOfTokenIds(uint[] memory tokenIds) public view returns (uint[] memory) {
        uint tokenLength = tokenIds.length;
        uint[] memory tiersOfTokenIds = new uint[](tokenLength);
        for (uint i = 0; i < tokenLength; i++) {
            if (tiers[1].startingIndex <= metadataUri[tokenIds[i]] && 
                tiers[2].startingIndex > metadataUri[tokenIds[i]]) {
                tiersOfTokenIds[i] = 1;
            }
            else if (tiers[2].startingIndex <= metadataUri[tokenIds[i]] && 
                     tiers[3].startingIndex > metadataUri[tokenIds[i]]) {
                tiersOfTokenIds[i] = 2;
            }
            else {
                tiersOfTokenIds[i] = 3;
            }
        }

        return tiersOfTokenIds;
    }
}