// SPDX-License-Identifier: AGPL-3.0
// ©2022 Ponderware Ltd

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface IMetadata {
    function CONDOS_TOKEN_URI() external pure returns (string memory condosTokenUri);
    function streetsAddress() external pure returns (address contractAddress);
}

interface IReverseResolver {
    function claim(address owner) external returns (bytes32);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}


/*
 * @title CondoMini Streets
 * @author Ponderware Ltd
 * @dev CondoMini Condo ERC-1155 NFT
 */
contract Condos is ERC1155 {
    address public owner;

    IMetadata Metadata;

    bool initialized = false;
    uint8[280] public Items; // Supply of items

    struct Stock {
        uint256 available;
        uint16[] items;
        mapping(uint256 => uint256) indexes;
    }

    Stock[5] public StockedTypes;

    // Type | Name          | Variants | Quantity | Total
    // -----|---------------|----------|----------|-------
    //    0 | Base Condo    |       78 |      170 | 13,260
    //    1 | Premium Condo |       57 |       98 |  5,586
    //    2 | Base Gold     |       78 |        9 |    702
    //    3 | Premium Gold  |       57 |        6 |    342
    //    4 | Landmark      |       10 |       11 |    110
    //----------------------------------------------------
    //        Total                280              20,000

    uint256 public totalAvailableSupply = 0;

    constructor(address metadataAddress) ERC1155("") {
        owner = msg.sender;
        Metadata = IMetadata(metadataAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier onlyStreets() {
        require(msg.sender == Metadata.streetsAddress() || msg.sender == owner, "Not admin");
        _;
    }

    modifier whenInitialized() {
        require(initialized == true, "Not initialized");
        _;
    }

    function initializeStock(uint256 stockIndex, uint256 itemCount, uint8 quantityPerItem) private {
        Stock storage stock = StockedTypes[stockIndex];
        unchecked {
            uint256 idOffset = 0;
            if (stockIndex == 1) {
                idOffset = 78;
            } else if (stockIndex == 2) {
                idOffset = 135;
            } else if (stockIndex == 3) {
                idOffset = 213;
            } else if (stockIndex == 4) {
                idOffset = 270;
            }
            stock.available = itemCount * quantityPerItem;
            totalAvailableSupply += stock.available;
            for (uint index = 0; index < itemCount; index++) {
                uint id = idOffset + index;
                stock.indexes[id] = stock.items.length;
                stock.items.push(uint16(id));
                Items[id] = quantityPerItem;
            }
        }
    }

    function initialize() public onlyOwner {
        require(initialized == false, "Already initialized");
        require(Metadata.streetsAddress() != address(0), "Invalid streets address");

        initializeStock(0, 78, 170);
        initializeStock(1, 57, 98);
        initializeStock(2, 78, 9);
        initializeStock(3, 57, 6);
        initializeStock(4, 10, 11);

        initialized = true;
    }

    function _handleStock(uint256 id) internal {
        require(Items[id] > 0, "No supply");
        unchecked {
            uint itemType = 0;
            if (id >= 270) {
                itemType = 4;
            } else if (id >= 213) {
                itemType = 3;
            } else if (id >= 135) {
                itemType = 2;
            } else if (id >= 78) {
                itemType = 1;
            }

            Stock storage stock = StockedTypes[itemType];
            Items[id]--; // decrement supply;
            if (Items[id] == 0) {
                uint stockIndex = stock.indexes[id];
                uint lastItem = stock.items[stock.items.length - 1];
                stock.indexes[lastItem] = stockIndex;
                stock.indexes[id] = 0;
                stock.items[stockIndex] = uint16(lastItem);
                stock.items.pop();
            }
            stock.available--;
            totalAvailableSupply--;
        }
    }

    function assembleRandomStreet(uint256 seed) external whenInitialized onlyStreets returns (uint16[5] memory ids) {
        require(totalAvailableSupply >= 5, "Insufficient supply");
        unchecked {
            for (uint256 i = 0; i < 5; i++) {
                uint256 stockNumber = seed % totalAvailableSupply;
                uint256 count = 0;
                for (uint256 t = 0; t < 5; t++) {
                    count += StockedTypes[t].available;
                    if (stockNumber <= count && StockedTypes[t].items.length > 0) {
                        uint256 itemIndex = (seed % StockedTypes[t].items.length);
                        uint256 id = StockedTypes[t].items[itemIndex];
                        ids[i] = uint16(id);
                        _handleStock(id);
                        break;
                    }
                }
                seed = uint256(keccak256(abi.encodePacked(seed, stockNumber)));
            }
        }
    }

    uint256[] private assemblyMintQuantities = [1, 1, 1, 1, 1];

    function assembleStreet(address from, uint256[] calldata ids) external whenInitialized onlyStreets {
        _burnBatch(from, ids, assemblyMintQuantities);
    }

    function breakupStreet(address to, uint256[] calldata ids) external whenInitialized onlyStreets {
        _mintBatch(to, ids, assemblyMintQuantities, "");
    }

    function uri(uint256) public view override returns (string memory) {
        return Metadata.CONDOS_TOKEN_URI();
    }

    /**
     * @dev Claim ENS reverse-resolver rights for this contract.
     * https://docs.ens.domains/contract-api-reference/reverseregistrar#claim-address
     */
    function setReverseResolver(address registrar) public onlyOwner {
        IReverseResolver(registrar).claim(msg.sender);
    }

    /**
     * @dev Rescue ERC20 assets sent directly to this contract.
     */
    function withdrawForeignERC20(address tokenContract) public onlyOwner {
        IERC20 token = IERC20(tokenContract);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /**
     * @dev Rescue ERC721 assets sent directly to this contract.
     */
    function withdrawForeignERC721(address tokenContract, uint256 tokenId) public virtual onlyOwner {
        IERC721(tokenContract).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function withdrawEth() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}