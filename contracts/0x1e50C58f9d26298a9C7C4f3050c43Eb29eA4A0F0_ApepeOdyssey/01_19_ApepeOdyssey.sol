// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./opensea-operator-filterer/DefaultOperatorFilterer.sol";

//                                .__        ___.
//  ____________ _______   ____    |  | _____ \_ |__   ______
//  \_  __ \__  \\_  __ \_/ __ \   |  | \__  \ | __ \ /  ___/
//   |  | \// __ \|  | \/\  ___/   |  |__/ __ \| \_\ \\___ \
//   |__|  (____  /__|    \___  >  |____(____  /___  /____  >
//              \/            \/             \/    \/     \/
//
// Apepe Odyssey: Chapter 1
// the story unravels..
//

interface IDelegationRegistry {
    function checkDelegateForToken(
        address delegate,
        address vault,
        address contract_,
        uint256 tokenId
    ) external view returns (bool);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function balanceOf(address _owner) external view returns (uint256);
}

contract ApepeOdyssey is
    DefaultOperatorFilterer,
    ERC1155,
    ERC2981,
    Ownable,
    ERC1155Burnable,
    ERC1155Supply
{
    IDelegationRegistry dc;

    constructor(
        uint96 _royaltyFeesInBips,
        address _royaltyRecipient,
        IERC721 _rayc,
        IERC721 _zayc,
        IDelegationRegistry delegateContract
    ) ERC1155("") {
        setRoyaltyInfo(_royaltyRecipient, _royaltyFeesInBips);
        rayc = _rayc;
        zayc = _zayc;
        dc = delegateContract;
    }

    string public name = "Apepe Odyssey: Chapter 1";
    string public symbol = "AO:C1";

    string baseURI = "";
    string baseExtension = ".json";

    IERC721 public rayc;
    IERC721 public zayc;
    address payable private payoutAddress;
    mapping(uint256 => TokenConfig) public tokenIdToConfig;
    mapping(uint256 => uint256) ownerMints; // piece id to quantity

    struct TokenConfig {
        uint256 startDate;
        uint256 endDate;
        uint256 limit;
        bool isLimited;
        bool openToPublic;
        uint256 priceRayc;
        uint256 priceZayc;
        uint256 pricePublic;
    }
    struct UsedAllocation {
        address tokenUsed;
        uint256 id;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => bool)))
        public tokensUsed;

    function setURI(string memory newUri) public onlyOwner {
        baseURI = newUri;
    }

    function mint(
        uint256 id, // the odyssey token id to mint
        IERC721 token, // the 'mint pass' token
        uint256 tokenId, // the 'mint pass' token id
        address _vault
    ) public payable {
        require(
            block.timestamp >= tokenIdToConfig[id].startDate &&
                tokenIdToConfig[id].startDate != 0,
            "Mint not started"
        );

        require(block.timestamp <= tokenIdToConfig[id].endDate, "Mint ended");
        address requester = msg.sender;

        if (_vault != address(0)) {
            bool isDelegateValid = dc.checkDelegateForToken(
                msg.sender,
                _vault,
                address(token),
                tokenId
            );
            require(isDelegateValid, "Invalid delegate-vault pairing");
            requester = _vault;
        }

        // if no 'mint pass' token is used
        if (address(token) == address(0)) {
            require(
                tokenIdToConfig[id].openToPublic,
                "Token is not available for public mint"
            );
        }

        if (tokenIdToConfig[id].isLimited) {
            require(tokenIdToConfig[id].limit > totalSupply(id), "All minted");
        }

        // when using a 'mint pass' token
        if (address(token) != address(0)) {
            require(
                !tokensUsed[address(token)][id][tokenId],
                "Token already used"
            );
            require(
                token.ownerOf(tokenId) == requester,
                "You are not the owner of the token"
            );
            tokensUsed[address(token)][id][tokenId] = true;
        }

        uint256 _price;

        if (rayc == token) {
            _price = tokenIdToConfig[id].priceRayc;
        } else if (zayc == token) {
            _price = tokenIdToConfig[id].priceZayc;
        } else {
            require(tokenIdToConfig[id].openToPublic, "Not open to public.");
            _price = tokenIdToConfig[id].pricePublic;
        }

        require(
            msg.value >= _price,
            string(
                abi.encodePacked(
                    "Invalid price, please send: ",
                    Strings.toString(_price),
                    " wei"
                )
            )
        );

        _mint(requester, id, 1, "0x00");
    }

    function mintAsPublic(
        uint256 id, // the odyssey token id to mint
        uint256 qty // how many to mint
    ) public payable {
        require(
            block.timestamp >= tokenIdToConfig[id].startDate &&
                tokenIdToConfig[id].startDate != 0,
            "Mint not started"
        );
        require(block.timestamp <= tokenIdToConfig[id].endDate, "Mint ended");
        require(tokenIdToConfig[id].openToPublic, "Not open to public.");
        require(qty > 0, "Min 1");
        require(qty <= 10, "Max 10 in one txn");

        if (tokenIdToConfig[id].isLimited) {
            require(tokenIdToConfig[id].limit >= totalSupply(id) + qty, "Supply exceeded");
        }

        require(
            msg.value >= tokenIdToConfig[id].pricePublic * qty,
            string(
                abi.encodePacked(
                    "Invalid price, please send: ",
                    Strings.toString(tokenIdToConfig[id].pricePublic * qty),
                    " wei"
                )
            )
        );

        _mint(msg.sender, id, qty, "0x00");
    }

    function mintMultiple(
        uint256[] memory ids, // array of odyssey token ids to mint
        IERC721[] memory tokens, // array of 'mint pass' tokens
        uint256[] memory tokenIds, // array of 'mint pass' token ids
        address[] memory vaults
    ) public payable {
        if (msg.sender == owner()) {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];
                require(ownerMints[id] + ids.length <= 20, "Max reached.");
                ownerMints[id]++;
                _mint(msg.sender, id, 1, "0x00");
            }
            return;
        }

        require(ids.length > 0, "Must not be empty");
        require(ids.length < 51, "50 or below");

        require(
            ids.length == tokens.length &&
                ids.length == tokenIds.length &&
                ids.length == vaults.length,
            "Input arrays must have the same length"
        );

        uint256 requiredValue = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            IERC721 token = tokens[i];

            if (token == rayc) {
                requiredValue += tokenIdToConfig[id].priceRayc;
            } else if (token == zayc) {
                requiredValue += tokenIdToConfig[id].priceZayc;
            } else {
                require(
                    tokenIdToConfig[id].openToPublic,
                    "Not open to the public"
                );
                requiredValue += tokenIdToConfig[id].pricePublic;
            }
        }

        require(
            msg.value >= requiredValue,
            string(
                abi.encodePacked(
                    "Invalid total price, please send: ",
                    Strings.toString(requiredValue),
                    " wei"
                )
            )
        );

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            IERC721 token = tokens[i];
            uint256 tokenId = tokenIds[i];
            address _vault = vaults[i];

            mint(id, token, tokenId, _vault);
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory currentBaseURI = baseURI;

        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId),
                        baseExtension
                    )
                )
                : "";
    }

    function setTokenConfig(
        uint256 _id,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _limit,
        bool _isLimited,
        bool _openToPublic,
        uint256 _priceRayc,
        uint256 _priceZayc,
        uint256 _pricePublic
    ) external onlyOwner {
        tokenIdToConfig[_id] = TokenConfig(
            _startDate,
            _endDate,
            _limit,
            _isLimited,
            _openToPublic,
            _priceRayc,
            _priceZayc,
            _pricePublic
        );
    }

    function updatePayoutAddress(address _payoutAddress) external onlyOwner {
        payoutAddress = payable(_payoutAddress);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(
            _amount <= address(this).balance && address(this).balance > 0,
            "Not enough ethers to withdraw"
        );
        if (_amount == 0) {
            // withdraw all
            (bool sent, ) = payoutAddress.call{value: address(this).balance}(
                ""
            );
            require(sent, "Error while transfering");
        } else {
            // withdraw _amount
            (bool sent, ) = payoutAddress.call{value: _amount}("");
            require(sent, "Error while transfering");
        }
    }

    // For ERC2981
    function setRoyaltyInfo(
        address _receiver,
        uint96 _royaltyFeesInBips
    ) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Opensea Filter Registry

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     *      In this example the added modifier ensures that the operator is allowed by the OperatorFilterRegistry.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}