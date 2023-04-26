// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

interface MyNFTInterface is IERC721Upgradeable {
    function safeMint(address to, uint256 tokenId) external;
}

/**
 * @title RXXODrop
 * @notice A smart contract for managing the drop sale
 */
contract RXXODrop is Initializable,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable  {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Role constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Struct to define a level within a drop
    struct Level {
        uint256 price; // The price per NFT, in wei
        uint256 quantity; // The number of NFTs available at this level
        uint256 sold; // The number of NFTs available at this level
        uint256[] tokenIds; // An array of the NFT ids available at this level
    }

    // Struct to define a drop
    struct Drop {
        string name; // The name of the drop
        uint8 maxMintsPerAddress; // The maximum number of NFTs each address can mint during this drop
        uint32 waitListStartTime; // The time when the waitlist opens
        uint32 waitListEndTime; // The time when the waitlist closes and the allowlist opens
        uint32 allowListEndTime; // The time when the allowlist closes
        mapping(address => bool) waitList; // A mapping of addresses on the waitlist for this drop
        mapping(address => bool) allowList; // A mapping of addresses on the allowlist for this drop
        mapping(uint8 => Level) levels; // A mapping of levels for this drop
        mapping(address => uint256) mintCounts; // A mapping of the number of NFTs minted by each address during this drop
    }

    mapping(uint256 => Drop) public drops; // A mapping of drops
    uint24 public currentDrop; // The current number of drops

    uint8 private totalLevel; // The total number of levels across all drops

    address public nftAddress; // The address of the NFT contract
    MyNFTInterface public nft; // The instance of the NFT contract

    // Events
    event DropAdded(uint256 indexed id, string name, uint8 maxMintsPerAddress, uint32 startTime, uint32 waitListEndTime,  uint32 endTime);
    event DropUpdated(uint256 indexed id, string name, uint8 maxMintsPerAddress, uint32 startTime, uint32 waitListEndTime,  uint32 endTime);
    event MintedToken(uint256 indexed tokenId);

    /** @notice Initializes the contract with the address of the deployed MyNFT contract and sets up roles
    * @param _nftAddress The address of the MyNFT contract that this contract will mint tokens for
    * Effects:
    * - Initializes the contract with a reference to the MyNFT contract and sets up default roles for contract roles
    */
    function initialize(address _nftAddress) public initializer {
        __UUPSUpgradeable_init();
        nftAddress = _nftAddress;
        nft = MyNFTInterface(nftAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(UPGRADER_ROLE, msg.sender);
        currentDrop = 0;
        totalLevel = 130;
    }

    /** @notice Initializes the contract with the address of the deployed MyNFT contract and sets up roles
    * @param _nftAddress The address of the MyNFT contract that this contract will mint tokens for
    * Effects:
    * - Initializes the contract with a reference to the MyNFT contract and sets up default roles for contract roles
    */
    function setNftAddress(address _nftAddress) public onlyRole(ADMIN_ROLE) {
        nftAddress = _nftAddress;
        nft = MyNFTInterface(nftAddress);
    }

    /**
     * @dev Adds a new drop with the given parameters.
     * @param _name The name of the drop.
     * @param _maxMintsPerAddress The maximum number of tokens that can be minted per address.
     * @param _startTime The time at which the waitlist will start, specified in UNIX timestamp.
     * @param _waitListEndTime The time at which the waitlist will end, specified in UNIX timestamp.
     * @param _endTime The time at which the allowlist will end, specified in UNIX timestamp.
     * Emits a {DropAdded} event indicating the successful addition of the drop.
     */
    function addDrop(string memory _name, uint8 _maxMintsPerAddress, uint32 _startTime, uint32 _waitListEndTime, uint32 _endTime) public onlyRole(ADMIN_ROLE) {
        // Set the properties of the new drop in the `drops` mapping    
        drops[currentDrop].name = _name;
        drops[currentDrop].maxMintsPerAddress = _maxMintsPerAddress;
        drops[currentDrop].waitListStartTime = _startTime;
        drops[currentDrop].waitListEndTime = _waitListEndTime;
        drops[currentDrop].allowListEndTime = _endTime;
        // Increment the current drop count for the next drop
        currentDrop++;
        // Emit an event to signal that the drop has been added
        emit DropAdded(currentDrop-1, _name, _maxMintsPerAddress, _startTime ,_waitListEndTime, _endTime);
    }

    /**
     * @dev Updates an existing drop.
     * @param _dropId The ID of the drop to be updated.
     * @param _name The updated name of the drop.
     * @param _maxMintsPerAddress The updated maximum number of mints per address for the drop.
     * @param _startTime The updated start time for the drop.
     * @param _waitListEndTime The updated waitlist end time for the drop.
     * @param _endTime The updated end time for the drop.
     */
    function updateDrop(uint24 _dropId, string memory _name, uint8 _maxMintsPerAddress, uint32 _startTime, uint32 _waitListEndTime, uint32 _endTime) public onlyRole(ADMIN_ROLE) {
        // Ensure that the specified drop exists
        require(_dropId < currentDrop, "Drop does not exist");

        // Update the drop's details
        drops[_dropId].name = _name;
        drops[_dropId].maxMintsPerAddress = _maxMintsPerAddress;
        drops[_dropId].waitListStartTime = _startTime;
        drops[_dropId].waitListEndTime = _waitListEndTime;
        drops[_dropId].allowListEndTime = _endTime;

        // Emit an event indicating that the drop has been updated
        emit DropUpdated(_dropId, _name, _maxMintsPerAddress, _startTime, _waitListEndTime, _endTime);
    }

    /**
     * @notice Add one or more addresses to the waitlist for a specific drop
     * @dev Add the specified addresses to the waitlist for the specified drop
     * @param drop The ID of the drop to add the addresses to the waitlist for
     * @param addresses An array of addresses to add to the waitlist
     * Requirements:
     * - The function caller must have the ADMIN_ROLE
     * Effects:
     * - The specified addresses are added to the waitlist for the specified drop
     */
    function addWaitListAddress(uint256 drop, address[] memory addresses) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            drops[drop].waitList[addresses[i]] = true;
        }
    }

    /**
     * @notice Add one or more addresses to the waitlist for a specific drop
     * @dev Add the specified addresses to the waitlist for the specified drop
     * @param drop The ID of the drop to add the addresses to the waitlist for
     * @param addresses An array of addresses to add to the waitlist
     * Requirements:
     * - The function caller must have the ADMIN_ROLE
     * Effects:
     * - The specified addresses are added to the waitlist for the specified drop
     */
    function addAllowListAddress(uint256 drop, address[] memory addresses) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            drops[drop].allowList[addresses[i]] = true;
        }
    }

    /**
     * @notice Check whether an address is on the allowlist for a specific drop
     * @param _drop The ID of the drop to check the allowlist for
     * @param _address The address to check
     * @return Whether the specified address is on the allowlist for the specified drop
     */
    function isAllowListed(uint24 _drop, address _address) public view returns (bool) {
        return drops[_drop].allowList[_address];
    }

    /**
     * @notice Check whether an address is on the waitlist for a specific drop
     * @param _drop The ID of the drop to check the waitlist for
     * @param _address The address to check
     * @return Whether the specified address is on the waitlist for the specified drop
     */
    function isWaitListed(uint24 _drop, address _address) public view returns (bool) {
        return drops[_drop].waitList[_address];
    }

    /**
     * @notice Remove one or more addresses from the waitlist for a specific drop
     * @dev Remove the specified addresses from the waitlist for the specified drop
     * @param drop The ID of the drop to remove the addresses from the waitlist for
     * @param addresses An array of addresses to remove from the waitlist
     * Requirements:
     * - The function caller must have the ADMIN_ROLE
     * Effects:
     * - The specified addresses are removed from the waitlist for the specified drop
     */
    function removeWaitListAddress(uint256 drop, address[] memory addresses) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            drops[drop].waitList[addresses[i]] = false;
        }
    }

    /**
     * @notice Removes the specified addresses from the waitlist for the given drop
     * @param drop The ID of the drop to modify
     * @param addresses The list of addresses to remove from the waitlist
     * Requirements:
     * - The function caller must have the ADMIN_ROLE
     * Effects:
     * - The specified addresses are removed from the waitlist for the given drop
     */
    function removeAllowListAddress(uint256 drop, address[] memory addresses) public onlyRole(ADMIN_ROLE) {
        for (uint256 i = 0; i < addresses.length; i++) {
            drops[drop].allowList[addresses[i]] = false;
        }
    }


    /**
     * @notice Sets the prices for each level of the specified drop
     * @param _drop The ID of the drop to modify
     * @param _prices An array of prices for each level of the drop
     * Requirements:
     * - The function caller must have the ADMIN_ROLE
     * Effects:
     * - The prices for each level of the specified drop are set
     */
    function setLevels(uint24 _drop, uint256[] memory _prices) public onlyRole(ADMIN_ROLE) {
        for (uint8 i = 1; i < _prices.length+1; i++) {
            drops[_drop].levels[i].price = _prices[i-1];
        }
    }
    
    /**
     * @notice Returns the level of a given token ID for the specified drop
     * @param _drop The ID of the drop to search
     * @param _tokenId The token ID to search for
     * @return The level of the given token ID for the specified drop
     * Requirements:
     * - The token ID must exist within the specified drop
     */
    function getTokenLevel(uint24 _drop, uint256 _tokenId) internal view returns (uint256) {
        for (uint8 i = 0; i < totalLevel; i++) {
            for (uint256 j = 0; j < drops[_drop].levels[i].tokenIds.length; j++) {
                if (drops[_drop].levels[i].tokenIds[j] == _tokenId) {
                    return i;
                }
            }
        }
        revert("Token ID not found.");
    }

    /**
     * @notice Add tokens to a specific drop and level
     * @dev A function that allows an admin to add tokens to a specific drop and level
     * @param _drop The iteration of the drop to add tokens to
     * @param _level An array of levels to add tokens to
     * @param _tokenIds An array of token IDs to add to the specified levels
     * Requirements:
     * - The input arrays must have the same length
     * Effects:
     * - The specified tokens are added to the specified levels of the specified drop
     * - The quantity of tokens available for sale at the specified levels of the specified drop is incremented by the number of tokens added
     */
    function addTokens(uint24 _drop, uint8[] memory _level, uint256[] memory _tokenIds) public onlyRole(ADMIN_ROLE) {
        require(_level.length == _tokenIds.length, "Input arrays must have the same length.");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            drops[_drop].levels[_level[i]].tokenIds.push(_tokenIds[i]);
            drops[_drop].levels[_level[i]].quantity++;
        }
    }

    /** 
    * @notice Mint NFTs from a specified drop and level
    * @dev A payable function that allows minting of NFTs from a specific drop and level
    * @param _drop The iteration of the drop to mint from
    * @param _level The level to mint from (between 1 and 130)
    * @param _quantity The number of NFTs to mint
    * Requirements:
    * - The function caller must be whitelisted in the waitlist or allowlist for the specified drop
    * - The total number of NFTs sold at the specified level for the specified drop must not exceed the quantity of NFTs available for sale at that level
    * - The number of NFTs minted by the function caller for the specified drop must not exceed the maximum number of NFTs that can be minted per address
    * - The drop must be within the specified waitlist and allowlist periods
    * - The level must exist and must have tokens available for minting
    * - The amount of Ether sent must not exceed the cost of the NFTs being minted
    * Effects:
    * - The NFTs are minted and sent to the function caller's address
    * - If the quantity of NFTs minted is greater than the quantity available for sale at the specified level, the excess Ether is refunded to the function caller
    */
    function mint(uint24 _drop, uint8 _level, uint8 _quantity) public payable nonReentrant {
        // Ensure that the waitlist period has started
        require(uint32(block.timestamp) >= drops[_drop].waitListStartTime, "Minting is not yet allowed.");
        // Ensure that the value of Ether sent is sufficient
        require(msg.value >= drops[_drop].levels[_level].price * _quantity, "Insufficient funds.");
        // Ensure that all NFTs for the specified level have not already been sold
        require(drops[_drop].levels[_level].sold <= drops[_drop].levels[_level].tokenIds.length, "All NFTs for this level have been sold.");
        // Ensure that the number of NFTs minted by the function caller for the specified drop does not exceed the maximum number of NFTs that can be minted per address
        if (!hasRole(MINTER_ROLE, msg.sender)) {  // todo: remove for production
            require(drops[_drop].mintCounts[msg.sender] < drops[_drop].maxMintsPerAddress, "You have already minted the maximum number of NFTs allowed.");
        }
        // Determine if the function caller is authorized to mint NFTs
        bool isMinter = hasRole(MINTER_ROLE, msg.sender); // no minter on production
        bool canMint = isMinter || (uint32(block.timestamp) >= drops[_drop].waitListStartTime && isWaitListed(_drop, msg.sender)) || (uint32(block.timestamp) >= drops[_drop].waitListEndTime && isAllowListed(_drop, msg.sender)) || (uint32(block.timestamp) > drops[_drop].allowListEndTime);

        if (canMint) {
            uint256[] memory tokenIds = drops[_drop].levels[_level].tokenIds;
            uint256 tokensRemaining = drops[_drop].levels[_level].quantity - drops[_drop].levels[_level].sold;
            uint256 refundAmount = 0;
            uint256 mintCount = drops[_drop].mintCounts[msg.sender];
            uint8 maxMints = drops[_drop].maxMintsPerAddress;
            uint256 sold = drops[_drop].levels[_level].sold ;
            
            // Iterate over the number of tokens to be minted
            for (uint8 i = 0; i < _quantity ; i++) {
                // Determine if the function caller is authorized to mint NFTs
                if ((isMinter || mintCount + i < maxMints) && i < tokensRemaining) {
                    // Calculate the token ID to be minted
                    uint256 tokenId = tokenIds[sold + i];
                    emit MintedToken(tokenId);
                    // Mint the token and transfer it to the caller's address
                    nft.safeMint(msg.sender, tokenId);
                } else {
                    // If the caller has reached a mint limit, add the cost of the token to the refund amount
                    refundAmount += drops[_drop].levels[_level].price;
                }
            }
            
            // Update the number of tokens sold at the specified level
            drops[_drop].levels[_level].sold += _quantity;
            // Update the number of tokens minted by the caller for the specified drop
            drops[_drop].mintCounts[msg.sender] += _quantity;

            // If there is a refund due, send it back to the caller
            if (refundAmount > 0  && msg.value >= refundAmount ) {
                payable(msg.sender).transfer(refundAmount);
            }
        } else {
             // If the caller is not authorized to mint, revert the transaction
            revert("You are not allowed to mint.");
        }
    }

    /**
    @notice Returns an array of token IDs available for a given drop and level
    @param _drop The iteration of the drop
    @param _level The level to retrieve tokens from
    @return An array of uint256 values representing the available token IDs
    */
    function getTokenListByLevel(uint24 _drop, uint8 _level) public view returns(uint256[] memory){
        return drops[_drop].levels[_level].tokenIds;
    }

    /**
    @notice Returns the price for a given drop and level
    @param _drop The iteration of the drop
    @param _level The level to retrieve the price for
    @return A uint256 value representing the price of the NFTs at the given level
    */
    function getPriceByLevel(uint24 _drop, uint8 _level) public view returns(uint256){
        return drops[_drop].levels[_level].price;
    }

    /**
    @notice Allows the contract owner to withdraw any Ether held in the contract
    Requirements:
    The function caller must have the ADMIN_ROLE permission
    Effects:
    The Ether is transferred to the owner's address
    */
    function withdraw() public onlyRole(ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    /**
    @dev Overrides the function in the Upgradable contract to restrict upgrades to authorized addresses with the UPGRADER_ROLE permission
    @param newImplementation The address of the new implementation contract
    Requirements:
    The function caller must have the UPGRADER_ROLE permission
    */
    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}


    ///@dev returns the contract version
    function version() external pure virtual returns (uint256) {
        return 1;
    }
}