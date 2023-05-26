// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title gmDAO Token v2
/// @notice Migration of gm token v1 from shared Rarible contract to v2 custom contract
/// @author: 0xChaosbi.eth
/// "Omnia sol temperat" - The sun warms all

///////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                               //
//               ::::::::  ::::    ::::  ::::    ::: :::::::::::     :::                         //
//              :+:    :+: +:+:+: :+:+:+ :+:+:   :+:     :+:       :+: :+:                       //
//              +:+    +:+ +:+ +:+:+ +:+ :+:+:+  +:+     +:+      +:+   +:+                      //
//              +#+    +:+ +#+  +:+  +#+ +#+ +:+ +#+     +#+     +#++:++#++:                     //
//              +#+    +#+ +#+       +#+ +#+  +#+#+#     +#+     +#+     +#+                     //
//              #+#    #+# #+#       #+# #+#   #+#+#     #+#     #+#     #+#                     //
//               ########  ###       ### ###    #### ########### ###     ###                     //
//                              ::::::::   ::::::::  :::                                         //
//                             :+:    :+: :+:    :+: :+:                                         //
//                             +:+        +:+    +:+ +:+                                         //
//                             +#++:++#++ +#+    +:+ +#+                                         //
//                                    +#+ +#+    +#+ +#+                                         //
//                             #+#    #+# #+#    #+# #+#                                         //
//                              ########   ########  ##########                                  //
//   ::::::::::: :::::::::: ::::    ::::  :::::::::  :::::::::: :::::::::      ::: :::::::::::   //
//       :+:     :+:        +:+:+: :+:+:+ :+:    :+: :+:        :+:    :+:   :+: :+:   :+:       //
//       +:+     +:+        +:+ +:+:+ +:+ +:+    +:+ +:+        +:+    +:+  +:+   +:+  +:+       //
//       +#+     +#++:++#   +#+  +:+  +#+ +#++:++#+  +#++:++#   +#++:++#:  +#++:++#++: +#+       //
//       +#+     +#+        +#+       +#+ +#+        +#+        +#+    +#+ +#+     +#+ +#+       //
//       #+#     #+#        #+#       #+# #+#        #+#        #+#    #+# #+#     #+# #+#       //
//       ###     ########## ###       ### ###        ########## ###    ### ###     ### ###       //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GmV2 is ERC721, IERC1155Receiver, IERC2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    address public raribleContractAddress; // shared Rarible ERC-1155 contract address
    uint256 public raribleTokenId = 706480; // gm v1 token id on shared Rarible contract
    address public gmDAOAddress = 0xD18e205b41eEe3D208D3B10445DB95Ff02ba4acA; // gmdao.eth
    uint256 public royaltyPercent = 20; // 20%
    uint256 public maxSupply = 900;
    uint256 public maxNormalTokens = 870; // v2 tokens that correspond directly to existing v1 tokens
    uint256 public maxSpecialTokens = 30; // special edition 1/1 tokens that can be created from burned tokens
    string public baseTokenURI;
    bool public isMigrationActive;

    // @dev Using special counter functions due to token id requirements for special tokens
    uint256 public nextNormalTokenId = 0;
    uint256 public nextSpecialTokenId = maxSupply - maxSpecialTokens;

    // @dev When a gm dao member sends their v1 token to this contract, we record that.
    mapping(address => uint256) public sentV1Tokens;

    constructor(string memory baseURI, address raribleAddress) ERC721("gmDAO Token v2", "GMV2") {
        baseTokenURI = string(abi.encodePacked(baseURI));
        raribleContractAddress = raribleAddress;
    }

    // ☉☉☉ MINT FUNCTIONS ☉☉☉

    /**
     * @dev Mints a gm v2 ERC-721 token.
     * @dev Requires user to have transferred their Rarible ERC-1155 gm v1 token to this contract first.
     */
    function upgradeToken() external migrationActive nonReentrant {
        require(getTotalTokenCount() < maxSupply, "MAX_TOTAL_SUPPLY");
        require(nextNormalTokenId < maxNormalTokens, "MAX_NORMAL_SUPPLY");

        // Requires that the minter has sent their v1 token and we have recorded that in sentV1Tokens
        require(sentV1Tokens[msg.sender] > 0, "NO_V1");

        uint256 newItemId = nextNormalTokenId;

        // Update state
        nextNormalTokenId += 1;
        sentV1Tokens[msg.sender] -= 1;

        // Mint v2 token
        _safeMint(msg.sender, newItemId);
    }

    /**
     * @dev Mints a batch of gm v2 ERC-721 tokens.
     * @dev Only callable by the owner.
     */
    function upgradeBatch(uint256 qty) external onlyOwner nonReentrant {
        require((getTotalTokenCount() + qty) <= maxSupply, "MAX_TOTAL_SUPPLY");
        require((getNormalTokenCount() + qty) <= maxNormalTokens, "MAX_NORMAL_SUPPLY");

        for (uint256 i = 0; i < qty; i++) {
            uint256 newItemId = nextNormalTokenId;

            // Update state
            nextNormalTokenId += 1;

            // Mint v2 token
            _safeMint(msg.sender, newItemId);
        }
    }

    /**
     * @dev Mints a special edition 1/1 gm v2 ERC-721 token.
     * @dev Only callable by the owner.
     */
    function upgradeSpecialToken() public onlyOwner nonReentrant {
        require(getTotalTokenCount() < maxSupply, "MAX_TOTAL_SUPPLY");
        require(getSpecialTokenCount() < maxSpecialTokens, "MAX_SPECIAL_SUPPLY");

        uint256 newItemId = nextSpecialTokenId;

        // Update state
        nextSpecialTokenId += 1;

        // Mint v2 token
        _safeMint(msg.sender, newItemId);
    }

    /**
     * @dev Mints a batch of special edition 1/1 gm v2 ERC-721 tokens.
     * @dev Only callable by the owner.
     */
    function upgradeSpecialBatch(uint256 qty) external onlyOwner nonReentrant {
        require((getTotalTokenCount() + qty) <= maxSupply, "MAX_TOTAL_SUPPLY");
        require((getSpecialTokenCount() + qty) <= maxSpecialTokens, "MAX_SPECIAL_SUPPLY");

        for (uint256 i = 0; i < qty; i++) {
            uint256 newItemId = nextSpecialTokenId;

            // Update state
            nextSpecialTokenId += 1;

            // Mint v2 token
            _safeMint(msg.sender, newItemId);
        }
    }

    // ☉☉☉ RECEIVE FUNCTIONS ☉☉☉

    /**
     * @dev Implements custom onERC1155Received hook.
     * @dev Only allows the gm v1 token (an ERC-1155 with tokenId 706480 on the shared Rarible contract 0xd07dc4262bcdbf85190c01c996b4c06a461d2430) to be sent.
     * @dev Stores the address of the sender so we know who can mint/redeem a gm v2 token.
     * @dev msg.sender is the NFT contract and param 'from' is the owner of the NFT.
     */
    function onERC1155Received(
        address,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata
    ) external override migrationActive nonReentrant returns (bytes4) {
        require(msg.sender == address(raribleContractAddress), "WRONG_NFT_CONTRACT");
        require(id == raribleTokenId, "ONLY_GM");

        sentV1Tokens[from] += amount;

        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    /**
     * @dev Implements custom onERC1155BatchReceived hook.
     * @dev Only allows batches of the gm v1 token to be sent by checking the ids array.
     * @dev Stores the address of the sender so we know who can mint/redeem a gm v2 token.
     */
    function onERC1155BatchReceived(
        address,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes memory
    ) external override migrationActive nonReentrant returns (bytes4) {
        require(msg.sender == address(raribleContractAddress), "WRONG_NFT_CONTRACT");
        require(ids[0] == raribleTokenId, "ONLY_GM");
        require(ids.length == 1, "ONLY_GM");

        sentV1Tokens[from] += values[0];

        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    // ☉☉☉ ADMIN ACTIONS ☉☉☉

    function setBaseURI(string memory uri) external onlyOwner {
        baseTokenURI = uri;
    }

    function setRoyaltyPercent(uint256 percent) external onlyOwner {
        royaltyPercent = percent;
    }

    function setRaribleContractAddress(address raribleAddress) external onlyOwner {
        raribleContractAddress = raribleAddress;
    }

    function setRaribleTokenId(uint256 tokenId) external onlyOwner {
        raribleTokenId = tokenId;
    }

    /**
     * @dev Toggle whether contract is active or not.
     */
    function toggleMigrationActive() public onlyOwner {
        isMigrationActive = !isMigrationActive;
    }

    // ☉☉☉ MODIFIERS ☉☉☉

    modifier migrationActive() {
        require(isMigrationActive, "NOT_ACTIVE");
        _;
    }

    // ☉☉☉ PUBLIC VIEW FUNCTIONS ☉☉☉

    function getNormalTokenCount() public view returns (uint256) {
        return nextNormalTokenId;
    }

    function getSpecialTokenCount() public view returns (uint256) {
        return nextSpecialTokenId - (maxSupply - maxSpecialTokens);
    }

    function getTotalTokenCount() public view returns (uint256) {
        return getNormalTokenCount() + getSpecialTokenCount();
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "NONEXISTENT_TOKEN");

        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    // ☉☉☉ ROYALTIES ☉☉☉

    /**
     * @dev See {IERC165-royaltyInfo}.
     * @dev Sets a 90% royalty on the token to discourage resales.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "NONEXISTENT_TOKEN");

        return (address(gmDAOAddress), SafeMath.div(SafeMath.mul(salePrice, royaltyPercent), 100));
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }
}