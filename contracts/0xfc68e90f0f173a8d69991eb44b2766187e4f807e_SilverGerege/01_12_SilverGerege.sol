// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Silver Gerege NFT Contract
 * @author DeOrderBook
 * @custom:license Copyright (c) DeOrderBook, 2023 — All Rights Reserved
 * @notice This contract is responsible for minting and managing the Silver Gerege NFTs
 * @dev This contract extends the ERC721A contract from Azuki, and ERC2981, Ownable, and ReentrancyGuard contracts from the OpenZeppelin library. The contract includes a variety of features such as minting with tiered pricing, custom token URI generation, transfer fees for private sales, NFT metadata updates, and whitelisting for minting and managers. Additionally, it supports the ERC2981 royalty standard for secondary sales.
 */
contract SilverGerege is ERC721A, ERC2981, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;

    /**
     * @notice Emitted when the token information is changed
     * @dev This event notifies when a token's XP, level, or rank is updated
     */
    event tokenInfoChangeEvent(
        uint256 tokenId,
        uint256 xp,
        uint256 level,
        uint256 rank,
        uint256 newXp,
        uint256 newLevel,
        uint256 newRank
    );

    /**
     * @dev The base URI for the token metadata. It is used in the `tokenURI` function to create the full URI for a specific token.
     */
    string _baseTokenURI;

    /**
     * @notice The base file extension for all token metadata
     * @dev This constant is used to construct the token URI for all tokens in the contract
     */
    string public constant baseExtension = ".json";

    /**
     * @notice The maximum supply of tokens in the contract
     * @dev This variable is used to limit the total supply of tokens
     */
    uint256 public maxSupply = 10000;

    /**
     * @notice The price for minting tokens
     * @dev This variable is used to determine the cost of minting tokens
     */
    uint256 public price = 0.1 ether;

    /**
     * @notice The fee associated with private sale transfers
     * @dev This fee is only applicable to transfers not utilizing whitelisted contracts
     */
    uint256 public privateSaleFee = 0.05 ether;

    /**
     * @notice The mode of minting tokens
     * @dev When true, minting is unrestricted. When false, only whitelisted users can mint up to 5 tokens (private mint mode)
     */
    bool public publicMint = false;

    /**
     * @notice The treasury address that receives Ether from the contract
     * @dev This is the recipient address used in the withdrawAll function. It's expected to be a non-zero address
     */
    address public treasury;

    /**
     * @notice A list of special token IDs that are one of ones
     * @dev This array is used to store the token IDs of special one of one tokens
     */
    uint256[] public oneOfOnes = [1021, 2002, 2023, 3000, 3011, 3025, 4507, 4512, 4519, 4525];

    /**
     * @notice Publicly accessible mapping that indicates whether an address is whitelisted
     * @dev This mapping is used to determine if an address is whitelisted and allowed to interact with certain functions of the contract without being charged a private sale fee.
     */
    mapping(address => bool) public contractWhitelist;

    /**
     * @notice The timestamp at which minting is allowed to start.
     * @dev The timestamp at which minting is allowed to start. This is used to prevent tokens from being minted before the contract is properly initialized.
     */
    uint256 public startTimestamp;

    /**
     * @dev The multiplier for increasing the token price every time a certain supply step is reached.
     *      Initially set to 125, meaning that the token price increases by 25% at each step.
     *      This value can be adjusted by the contract owner to change the rate of price increase.
     */
    uint256 public stepMultiplier = 125;

    /**
     * @dev Struct to store NFT information
     */
    struct NFTInfo {
        uint256 xp;
        uint256 level;
        uint256 rank;
        bool oneOfOnes;
    }

    /**
     * @notice A mapping to keep track of addresses that have manager privileges
     * @dev A mapping from an address to a boolean indicating whether the address has manager privileges
     */
    mapping(address => bool) public managerList;

    /**
     * @notice A mapping to keep track of addresses that are allowed to mint tokens
     * @dev A mapping from an address to a boolean indicating whether the address is whitelisted for minting tokens
     */
    mapping(address => bool) public mintWhitelist;

    /**
     * @notice A mapping to keep track of how many tokens each whitelisted address has minted
     * @dev A mapping from an address to a uint256 indicating the number of tokens that the address has minted
     */
    mapping(address => uint256) public mintWhitelistCount;

    /**
     * @notice A mapping to store the NFTInfo for each token ID
     * @dev This mapping is used to keep track of the information for each NFT.
     */
    mapping(uint256 => NFTInfo) public NFTInfos;

    /**
     * @dev Modifier that requires the caller to be in the manager list
     */
    modifier onlyManager(address _address) {
        require(managerList[_address], "User not in manager list");
        _;
    }

    /**
     * @notice The constructor initializes the contract with a baseURI, a start timestamp and sets the default royalty.
     * @dev Constructor sets the baseURI, start timestamp and default royalty of the ERC721A contract.
     *      The royalty is initially set at 5%.
     * @param baseURI The baseURI for the token metadata.
     * @param _startTimestamp The start timestamp for minting operations.
     */
    constructor(string memory baseURI, uint256 _startTimestamp)
        ERC721A("Silver Gereges", "SILVERGEREGE")
    {
        startTimestamp = _startTimestamp;
        setBaseURI(baseURI);
        _setDefaultRoyalty(msg.sender, 500); // 5%
    }

    /**
     * @notice Overrides supportsInterface function to include IERC2981 interface
     * @dev Overridden function to support IERC2981 interface along with ERC721A and ERC2981
     * @param interfaceId The interface ID to check
     * @return True if the contract supports the interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the base URI for the token metadata
     * @dev Returns the base URI set for the contract
     * @return The base URI for the token metadata
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Sets the base URI for the token metadata
     * @dev Allows the owner to set the base URI of the contract
     * @param baseURI The new base URI
     */
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Calculates the cost of minting a specific number of tokens
     * @dev Uses a step function to calculate the minting cost based on total supply and requested number of tokens
     * @param num The number of tokens to mint
     * @return cost to mint the tokens
     */
    function _calculateMintCost(uint256 num) private view returns (uint256 cost) {
        require(num < 6, "Amount must less than 6");

        uint256 supply = totalSupply();
        uint256 step = supply.div(500);
        uint256 nextStep = (num.add(supply)).div(500);

        if (step == nextStep) {
            cost = num.mul(price);
        } else {
            uint256 lowStepCount = (step.add(1)).mul(500).sub(supply);
            uint256 highStepCount = num.sub(lowStepCount);
            cost = (lowStepCount.mul(price)).add(
                highStepCount.mul(price.mul(stepMultiplier).div(100))
            );
        }
    }

    /**
     * @notice Mints a number of tokens for the sender, assigns them unique properties, and adjusts the price for future mints if necessary
     * @dev
     *    - Mints 'num' tokens
     *    - Assigns unique properties to each token
     *    - Increases the token price for future mints every 500 tokens
     *
     *    The function checks that the sender has sent enough Ether to cover the cost of minting.
     *    If publicMint is false, it ensures that the sender is whitelisted and has not exceeded their mint limit.
     *
     *    After minting, the function assigns unique properties to each token. Lastly, the function
     *    increases the token price by a step multipier (e.g. +25%) for future mints every 500 tokens.
     *
     *    Also, it checks that the current block timestamp is later than or equal to the start timestamp set on deployment to prevent premature minting.
     *
     * @param num The number of tokens to mint
     */
    function mint(uint256 num) public payable nonReentrant {
        require(block.timestamp >= startTimestamp, "NFT minting has not started");
        uint256 supply = totalSupply();
        require(num < 6, "You can mint a maximum of 5 Gereges");
        require(supply + num <= maxSupply, "Exceeds maximum Silver Gerege supply");

        uint256 cost = _calculateMintCost(num);
        require(msg.value >= cost, "Ether sent is not correct");
        if (!publicMint) {
            require(mintWhitelist[msg.sender], "User not in mint whilteList");
            require(
                (mintWhitelistCount[msg.sender] + num) < 6,
                "WhilteList maximum mint amount is 5"
            );
        }

        if (!publicMint && mintWhitelist[msg.sender]) {
            mintWhitelistCount[msg.sender] += num;
        }
        _safeMint(msg.sender, num);
        for (uint256 i = 0; i < num; i++) {
            NFTInfo memory info;
            info.level = 1;
            info.xp = 0;
            info.rank = 1;
            info.oneOfOnes = false;

            for (uint256 j = 0; j < oneOfOnes.length; j++) {
                if ((supply + i) == oneOfOnes[j]) {
                    info.oneOfOnes = true;
                    info.level = 5;
                    break;
                }
            }
            NFTInfos[supply + i] = info;
        }
        uint256 newSupply = totalSupply();
        if (supply.div(500) != newSupply.div(500)) {
            price = price.mul(stepMultiplier).div(100);
        }
    }

    /**
     * @notice Returns the token URI for the specified token ID
     * @dev Constructs the full URI for a token in the contract by appending the token ID to the base URI
     * @param tokenId The token ID to query
     * @return The token URI for the specified token ID
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), baseExtension))
                : "";
    }

    /**
     * @notice Transfers a token from one address to another, and requires a private sale fee if applicable
     * @dev Overrides the default transferFrom function in ERC721 to implement a fee on private sales.
     *      The fee is not applied to transactions involving a whitelisted contract, or during mint or burn operations.
     * @param from The address to transfer the token from
     * @param to The address to transfer the token to
     * @param tokenId The token ID to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        if (
            !contractWhitelist[to] &&
            !contractWhitelist[from] &&
            !contractWhitelist[msg.sender] &&
            from != address(0) && // mint not charge
            to != address(0) && // burn not charge
            privateSaleFee > 0
        ) {
            require(msg.value >= privateSaleFee, "Private sale fee sent is not correct");
        }
        return super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Updates the XP of a token
     * @dev Updates the XP of a token and emits a tokenInfoChangeEvent with the new and old XP, level, and rank
     * @param _tokenId The token ID to update
     * @param _newXp The new XP value
     */
    function updateXp(uint256 _tokenId, uint256 _newXp) external onlyManager(msg.sender) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        NFTInfo memory info = NFTInfos[_tokenId];
        NFTInfos[_tokenId].xp = _newXp;
        emit tokenInfoChangeEvent(
            _tokenId,
            info.xp,
            info.level,
            info.rank,
            _newXp,
            info.level,
            info.rank
        );
    }

    /**
     * @notice Bulk updates the XP of several token
     * @dev Bulk updates the XP of several tokens without emitting a tokenInfoChangeEvent in order to save gas
     * @param _tokenIds The token ID list to update
     * @param _newXps The new XP values
     */
    function bulkUpdateXp(uint256[] memory _tokenIds, uint256[] memory _newXps)
        external
        onlyManager(msg.sender)
    {
        require(_tokenIds.length == _newXps.length, "ERC721Metadata: array length not match");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "ERC721Metadata: URI query for nonexistent token");
            NFTInfos[_tokenIds[i]].xp = _newXps[i];
        }
    }

    /**
     * @notice Updates the XP and level of a token
     * @dev Updates the XP and level of a token and emits a tokenInfoChangeEvent with the new and old XP, level, and rank
     * @param _tokenId The token ID to update
     * @param _newXp The new XP value
     * @param _newLevel The new level value
     */
    function updateXpAndLevel(
        uint256 _tokenId,
        uint256 _newXp,
        uint256 _newLevel
    ) external onlyManager(msg.sender) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        NFTInfo memory info = NFTInfos[_tokenId];
        NFTInfos[_tokenId].xp = _newXp;
        NFTInfos[_tokenId].level = _newLevel;
        emit tokenInfoChangeEvent(
            _tokenId,
            info.xp,
            info.level,
            info.rank,
            _newXp,
            _newLevel,
            info.rank
        );
    }

    /**
     * @notice Bulk updates the XP and level of several tokens
     * @dev Bulk updates the XP and level of several tokens without emitting a tokenInfoChangeEvent in order to save gas
     * @param _tokenIds The token ID list to update
     * @param _newXps The new XP value list
     * @param _newLevels The new level value list
     */
    function bulkUpdateXpAndLevel(
        uint256[] memory _tokenIds,
        uint256[] memory _newXps,
        uint256[] memory _newLevels
    ) external onlyManager(msg.sender) {
        require(_tokenIds.length == _newXps.length, "ERC721Metadata: array length not match");
        require(_newXps.length == _newLevels.length, "ERC721Metadata: array length not match");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "ERC721Metadata: URI query for nonexistent token");
            NFTInfos[_tokenIds[i]].xp = _newXps[i];
            NFTInfos[_tokenIds[i]].level = _newLevels[i];
        }
    }

    /**
     * @notice Updates the XP, level, and rank of a token
     * @dev Updates the XP, level, and rank of a token and emits a tokenInfoChangeEvent with the new and old XP, level, and rank
     * @param _tokenId The token ID to update
     * @param _newXp The new XP value
     * @param _newLevel The new level value
     * @param _newRank The new rank value
     */
    function updateXpAndLevelAndRank(
        uint256 _tokenId,
        uint256 _newXp,
        uint256 _newLevel,
        uint256 _newRank
    ) external onlyManager(msg.sender) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        NFTInfo memory info = NFTInfos[_tokenId];
        NFTInfos[_tokenId].xp = _newXp;
        NFTInfos[_tokenId].level = _newLevel;
        NFTInfos[_tokenId].rank = _newRank;

        emit tokenInfoChangeEvent(
            _tokenId,
            info.xp,
            info.level,
            info.rank,
            _newXp,
            _newLevel,
            _newRank
        );
    }

    /**
     * @notice Bulk updates the XP, level, and rank of several tokens
     * @dev Bulk updates the XP, level, and rank of several tokens without emitting a tokenInfoChangeEvent in order to save gas
     * @param _tokenIds The token ID list to update
     * @param _newXps The new XP value list
     * @param _newLevels The new level value list
     * @param _newRanks The new rank value list
     */
    function bulkUpdateXpAndLevelAndRank(
        uint256[] memory _tokenIds,
        uint256[] memory _newXps,
        uint256[] memory _newLevels,
        uint256[] memory _newRanks
    ) external onlyManager(msg.sender) {
        require(_tokenIds.length == _newXps.length, "ERC721Metadata: array length not match");
        require(_newXps.length == _newLevels.length, "ERC721Metadata: array length not match");
        require(_newLevels.length == _newRanks.length, "ERC721Metadata: array length not match");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(_exists(_tokenIds[i]), "ERC721Metadata: URI query for nonexistent token");
            NFTInfos[_tokenIds[i]].xp = _newXps[i];
            NFTInfos[_tokenIds[i]].level = _newLevels[i];
            NFTInfos[_tokenIds[i]].rank = _newRanks[i];
        }
    }

    /**
     * @notice Sets the public mint status of the contract
     * @dev Allows the contract owner to enable or disable public minting
     * @param _publicMint The new public mint status
     */
    function setPublicMint(bool _publicMint) external onlyOwner {
        publicMint = _publicMint;
    }

    /**
     * @notice Sets the mint whitelist status for a list of addresses
     * @dev Allows the contract owner to add or remove a list of addresses address from the mint whitelist
     * @param _mintAddressList The address list to update the whitelist status
     * @param _isWhitelist The new whitelist status
     */
    function setMintWhitelist(address[] memory _mintAddressList, bool _isWhitelist)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _mintAddressList.length; i++) {
            address _mintAddress = _mintAddressList[i];
            require(_mintAddress != address(0), "Zero address");
            mintWhitelist[_mintAddress] = _isWhitelist;
        }
    }

    /**
     * @notice Sets the manager status for a list of addresses
     * @dev Allows the contract owner to add or remove a list of addresses from the list of managers
     * @param _managerList The address list to update the manager status
     * @param _isWhitelist The new manager status
     */
    function setManager(address[] memory _managerList, bool _isWhitelist) external onlyOwner {
        for (uint256 i = 0; i < _managerList.length; i++) {
            address _manager = _managerList[i];
            require(_manager != address(0), "Zero address");
            managerList[_manager] = _isWhitelist;
        }
    }

    /**
     * @notice Updates the maximum supply of tokens
     * @dev This function allows the contract owner to increase the maximum supply of tokens.
     *      The new maximum supply cannot be less than the existing maximum supply.
     * @param _maxSupply The new maximum supply
     */
    function updateMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > maxSupply, "New max supply cannot be less than current max supply");
        maxSupply = _maxSupply;
    }

    /**
     * @notice Updates the treasury address
     * @dev Allows the contract owner to change the treasury address, which receives the proceeds from minting and sales
     * @param _treasury The new treasury address
     */
    function updateTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero address");
        treasury = _treasury;
    }

    /**
     * @notice Sets the royalty information
     * @dev Allows the contract owner to specify the address that receives royalties, and the fee as a percentage of the sale price
     * @param receiver The address to receive royalties
     * @param feeBasisPoints The royalty fee in basis points
     */
    function setRoyaltyInfo(address receiver, uint96 feeBasisPoints) external onlyOwner {
        _setDefaultRoyalty(receiver, feeBasisPoints);
    }

    /**
     * @notice Sets the private sale fee
     * @dev Allows the contract owner to set the fee charged for private sales
     * @param _privateSaleFee The new private sale fee
     */
    function setPrivateSaleFee(uint256 _privateSaleFee) external onlyOwner {
        privateSaleFee = _privateSaleFee;
    }

    /**
     * @notice Sets the contract whitelist status for an address
     * @dev Allows the contract owner to add or remove an address from the contract whitelist
     * @param _contractAddress The address to update the whitelist status
     * @param _isWhitelist The new whitelist status
     */
    function setContractWhitelist(address _contractAddress, bool _isWhitelist) external onlyOwner {
        require(_contractAddress != address(0), "Zero address");
        contractWhitelist[_contractAddress] = _isWhitelist;
    }

    /**
     * @notice Sets the oneOfOnes array
     * @dev Allows the contract owner to set the list of token IDs that are considered "one of ones"
     * @param _oneOfOnes The new oneOfOnes array
     */
    function setOneOfOnes(uint256[] memory _oneOfOnes) external onlyOwner {
        oneOfOnes = _oneOfOnes;
    }

    /**
     * @notice Allows the owner to set the step multiplier
     * @dev This value determines by how much the price increases every 500 mints
     * @param _stepMultiplier The new step multiplier in percentage terms (e.g., 100 for no increase, 110 for a 10% increase, 125 for a 25% increase, etc.)
     */
    function setStepMultiplier(uint256 _stepMultiplier) external onlyOwner {
        require(
            _stepMultiplier >= 100,
            "Multiplier must be at least 100 to maintain a non-decreasing price"
        );
        stepMultiplier = _stepMultiplier;
    }

    /**
     * @notice Updates the start timestamp for minting
     *
     * @dev
     *      This function allows the owner of the contract to update the start timestamp.
     *      The new timestamp must be a non-zero value. This start timestamp restricts minting
     *      operations before the set time.
     *
     * @param _startTimestamp The new start timestamp
     */
    function updateStartTimestamp(uint256 _startTimestamp) external onlyOwner {
        require(_startTimestamp > 0, "Start timestamp cannot be zero");
        startTimestamp = _startTimestamp;
    }

    /**
     * @notice Updates the price for minting
     *
     * @dev
     *      This function allows the owner of the contract to update price.
     *      The new price must large than zero value.
     *
     * @param _newPrice The new price
     */
    function updatePrice(uint256 _newPrice) external onlyOwner {
        require(_newPrice > 0, "Price cannot be zero");
        price = _newPrice;
    }

    /**
     * @notice Withdraws all Ether from the contract to the treasury address
     * @dev
     *    - This function sends all the Ether balance of the contract to the treasury address.
     *    - It can only be called by the contract owner.
     *    - The treasury address must be non-zero.
     *    - Uses "call" instead of "send" to transfer funds, providing improved compatibility with multi-sig addresses.
     *    - In case the transfer fails, it will revert the transaction.
     */
    function withdrawAll() public payable onlyOwner {
        uint256 _balance = address(this).balance;
        require(treasury != address(0), "Treasury address is zero");
        (bool success, ) = treasury.call{value: _balance}("");

        require(success, "Transfer failed.");
    }
}