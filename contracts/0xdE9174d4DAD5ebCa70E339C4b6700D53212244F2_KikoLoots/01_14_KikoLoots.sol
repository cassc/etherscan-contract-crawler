// SPDX-License-Identifier: MIT

// ██╗░░██╗██╗██╗░░██╗░█████╗░██╗░░░░░░█████╗░░█████╗░████████╗░██████╗
// ██║░██╔╝██║██║░██╔╝██╔══██╗██║░░░░░██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
// █████═╝░██║█████═╝░██║░░██║██║░░░░░██║░░██║██║░░██║░░░██║░░░╚█████╗░
// ██╔═██╗░██║██╔═██╗░██║░░██║██║░░░░░██║░░██║██║░░██║░░░██║░░░░╚═══██╗
// ██║░╚██╗██║██║░╚██╗╚█████╔╝███████╗╚█████╔╝╚█████╔╝░░░██║░░░██████╔╝
// ╚═╝░░╚═╝╚═╝╚═╝░░╚═╝░╚════╝░╚══════╝░╚════╝░░╚════╝░░░░╚═╝░░░╚═════╝░

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import './operator-filter-registry/DefaultOperatorFiltererUpgradeable.sol';

contract KikoLoots is ERC1155Upgradeable, DefaultOperatorFiltererUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    
    /**
     * ======= Structs and enums definitions =======
     */
     
    struct MTDetails {
        string name;
        uint256 price;
        uint256[] mtRequirementIds;
        uint256[] mtRequirementCounts;
        bool available;
        bool reusable;
    }
    
    /**
     * ======= Variables =======
     * 
     * We are using the upgradeable pattern - please do not change names, types, or order of variables
     * New variables must be added at the end of the list
     * 
     */
     
    mapping (uint256 => MTDetails) public typeToDetails;
    uint256 public typeCount;
    address public mainContract;
    mapping (address => bool) public isAdmin;
    
    /**
     * ======= Events =======
     * 
     */
    
    event ToggleItem(uint256 indexed index, bool indexed available);
    event SetAdmin(address indexed addr, bool indexed enabled);
    
    /**
     * ======= Constructor =======
     */
    
    /**
     * @dev Initializes the contract
     */
    function initialize(string memory _uri, address _mainContract) public initializer
    {
        __ERC1155_init(_uri);
        __Ownable_init();
        __DefaultOperatorFilterer_init();

        mainContract = _mainContract;
    }
    
    /**
     * ======= M & T management functions =======
     */
     
    /**
     * @dev Updates the metadata URI
     * 
     * URI must use the string "{id}" that will be replaced on the client side with the type id
     */
    function updateUri(string calldata newUri) public onlyOwner {
        _setURI(newUri);
    }
    
    /**
     * @dev Add and configure new MT types
     */
    function addMaterialsAndTools(MTDetails[] calldata itemsToAdd) external onlyOwner {
        for (uint256 i = 0; i < itemsToAdd.length;) {
            require(itemsToAdd[i].mtRequirementIds.length == itemsToAdd[i].mtRequirementCounts.length, "Invalid length");
            typeToDetails[typeCount] = itemsToAdd[i];
            emit ToggleItem(typeCount, itemsToAdd[i].available);
            typeCount++;
            unchecked{i++;}
        }
    }
    
    /**
     * @dev Edit existing MT types
     */
    function editMaterialsAndTools(MTDetails[] calldata itemsToEdit, uint256[] calldata indexes) external onlyOwner{
        require(itemsToEdit.length == indexes.length, "Bad lengths");
        
        for (uint256 i = 0; i < itemsToEdit.length;) {
            require(itemsToEdit[i].mtRequirementIds.length == itemsToEdit[i].mtRequirementCounts.length, "Invalid length");
            require(indexes[i] < typeCount, "Invalid type");
            typeToDetails[indexes[i]] = itemsToEdit[i];
            emit ToggleItem(indexes[i], itemsToEdit[i].available);
            unchecked{i++;}
        }
    }
    
    /**
     * @dev Add and edit MT types
     */
    function addAndEditMaterialsAndTools(MTDetails[] calldata itemsToEdit, uint256[] calldata indexes, MTDetails[] calldata itemsToAdd) external onlyOwner{
        require(itemsToEdit.length == indexes.length, "Bad lengths");
        
        for (uint256 i = 0; i < itemsToEdit.length;) {
            require(itemsToEdit[i].mtRequirementIds.length == itemsToEdit[i].mtRequirementCounts.length, "Invalid length");
            require(indexes[i] < typeCount, "Invalid type");
            typeToDetails[indexes[i]] = itemsToEdit[i];
            emit ToggleItem(indexes[i], itemsToEdit[i].available);
            unchecked{i++;}
        }
        
        for (uint256 i = 0; i < itemsToAdd.length;) {
            require(itemsToAdd[i].mtRequirementIds.length == itemsToAdd[i].mtRequirementCounts.length, "Invalid length");
            typeToDetails[typeCount] = itemsToAdd[i];
            emit ToggleItem(typeCount, itemsToAdd[i].available);
            typeCount++;
            unchecked{i++;}
        }
    }
    
    /**
     * ======= Main contract integration =======
     */
     
    /**
     * @dev Set main contract address
     */
    function setMainContractAddress(address _mainContract) external onlyOwner { 
        mainContract = _mainContract;
    }
    
    /**
     * @dev Use materials and tools (internal)
     */
    function useMaterialAndToolsInternal(address user, uint256[] memory mtTypes, uint256[] memory mtCounts, uint256 countMultiplier) internal {
        require(mtTypes.length == mtCounts.length, "M&T: Bad lengths");
        
        uint256 mtType;
        uint256 mtCount;
        
        for (uint256 i = 0; i < mtTypes.length;) {
            mtType = mtTypes[i];
            mtCount = typeToDetails[mtType].reusable ? mtCounts[i] : mtCounts[i]*countMultiplier;
            
            require(balanceOf(user, mtType) >= mtCount, "M&T: insufficient balance");
            
            if (!typeToDetails[mtType].reusable) {
                _burn(user, mtType, mtCount);
            }
            unchecked{i++;}
        }
    }
    
    /**
     * @dev Use materials and tools
     * Only main contract is allowed to call this
     */
    function useMaterialAndTools(address user, uint256[] memory mtTypes, uint256[] memory mtCounts, uint256 countMultiplier) public {
        require(msg.sender == mainContract, "M&T: Not allowed");
        useMaterialAndToolsInternal(user, mtTypes, mtCounts, countMultiplier);
    }

    /**
     * ======= Public minting =======
     */
     
    /**
     * @dev Public buy
     */
    function buy(uint256 typeId, uint256 count) public payable {
        require(typeId < typeCount, "Invalid type");
        require(typeToDetails[typeId].available, "Item not available for buying");
        require(msg.value == typeToDetails[typeId].price * count, "Ether value incorrect");
        if (typeToDetails[typeId].mtRequirementIds.length > 0) {
            useMaterialAndToolsInternal(msg.sender, typeToDetails[typeId].mtRequirementIds, typeToDetails[typeId].mtRequirementCounts, count);
        }
    
        _mint(msg.sender, typeId, count, "");
    }
    
    /**
     * ======= Owner-facing minting =======
     */
           
    /**
     * @dev Airdrop tokens, callable by owner
     */
    function mintOwner(address[] calldata owners, uint256[] calldata typeIds, uint256[] calldata counts) external {
        require(isAdmin[msg.sender], "Not authorized");
        require(owners.length == typeIds.length && typeIds.length == counts.length, "Bad array lengths");
        
        for (uint256 i = 0; i < owners.length;) {
            require(typeIds[i] < typeCount, "Invalid type");
            _mint(owners[i], typeIds[i], counts[i], "");
            unchecked{i++;}
        }
    }
    
    /**
     * @dev Mark address as admin/non-admin
     */
    function setAdmin(address addr, bool enabled) external onlyOwner {
        isAdmin[addr] = enabled;
        emit SetAdmin(addr, enabled);
    }
    
    /**
     * @dev Withdraw ether from this contract (Callable by owner)
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * ======= View functions =======
     */
    
    /**
     * @dev Get Materials&Tools requirements of collection by collection id
     */
    function getMtsRequirements(uint256 typeId) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory ids = typeToDetails[typeId].mtRequirementIds;
        uint256[] memory counts = typeToDetails[typeId].mtRequirementCounts;
        return (ids, counts);
    }

    
    /**
     * ------------ OPENSEA OPERATOR FILTER OVERRIDES ------------
     */
    
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

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