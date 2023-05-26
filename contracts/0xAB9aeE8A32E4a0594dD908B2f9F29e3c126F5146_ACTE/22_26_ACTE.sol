// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./DefaultOperatorFilterer.sol";
import './AbstractERC1155Factory.sol';

contract ACTE is AbstractERC1155Factory, DefaultOperatorFilterer, AccessControl, ERC2981 {

    uint256 public constant MAX_SUPPLY = 19998;
    uint256 public maxFreeMint = 3333;
    uint256 public maxWhitelist = 3333;

    uint8 public maxAmountPublic = 10;
    uint8 public maxAmountFreeMint = 1;
    uint8 public maxAmountWhitelist = 2;
    uint private randGenKey = 0;
    uint256[] supplies = [3333, 3333, 3333, 3333, 3333, 3333];
    uint256 public whitelistPrice = 0.02 ether;
    uint256 public mintPrice = 0.05 ether;
    
    bool public publicSale;
    bool public freeMinting;
    bool public whitelistSale;
	bool public isRaining;

    bytes32 public merkleRootFreeMint;
    bytes32 public merkleRootWhitelist;
    mapping(address => uint256) public mintFreeAmount;
    mapping(address => uint256) public mintWhitelistAmount;
    mapping(address => uint256) public mintPublicSaleAmount;

    bytes32 public constant TOGGLER_ROLE = keccak256("TOGGLER_ROLE");

    string private baseTokenUri;
	string private baseRainTokenUri;
    
    event Purchased(uint256[] indexed ids, address indexed account, uint256 amount);

    /* Errors */
    error SendToAddressZero();
    error WithdrawSendFailed();

    constructor(
        string memory _uri
    ) ERC1155(_uri) {
        name_ = "A Chance To Encounter";
        symbol_ = "ACTE";
        baseTokenUri = _uri;

        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Set royalty receiver to the contract creator,
        // at 5% (default denominator is 10000).
        _setDefaultRoyalty(msg.sender, 500);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Permission :: Cannot be called by a contract");
        _;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
    * @notice edit the merkle root for Free minting
    *
    * @param _merkleRootFreeMint the new merkle root
    */
    function setMerkleRootFreeMint(bytes32 _merkleRootFreeMint) external onlyOwner {
        merkleRootFreeMint = _merkleRootFreeMint;
    }

    /**
    * @notice edit the merkle root for Whitelist sale
    *
    * @param _merkleRootWhitelist the new merkle root
    */
    function setMerkleRootWhitelist(bytes32 _merkleRootWhitelist) external onlyOwner {
        merkleRootWhitelist = _merkleRootWhitelist;
    }

    /**
    * @notice edit the Whitelist price
    *
    * @param _whitelistPrice the new price in wei
    */
    function setWhitelistPrice(uint256 _whitelistPrice) external onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    /**
    * @notice edit the mint price
    *
    * @param _mintPrice the new price in wei
    */
    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
    * @notice edit the free mint limit
    *
    * @param _maxFreeMint the new maxFreeMint
    */
    function setMaxFreeMint(uint256 _maxFreeMint) external onlyOwner {
        maxFreeMint = _maxFreeMint;
    }

    /**
    * @notice edit the whitelist mint limit
    *
    * @param _maxWhitelist the new maxWhitelist
    */
    function setMaxWhitelist(uint256 _maxWhitelist) external onlyOwner {
        maxWhitelist = _maxWhitelist;
    }

    /**
    * @notice update sale restrictions
    *
    * @param _maxAmountFreeMint the max amount of tokens allowed during free minting
    * @param _maxAmountWhitelist the max amount of tokens allowed during whitelist sale
    * @param _maxAmountPublic the max amount of tokens allowed during public sale
    */
    function updateSaleRestrictions(uint8 _maxAmountFreeMint, uint8 _maxAmountWhitelist, uint8 _maxAmountPublic) external onlyOwner {
        maxAmountFreeMint = _maxAmountFreeMint;
        maxAmountWhitelist = _maxAmountWhitelist;
        maxAmountPublic = _maxAmountPublic;
    }

    /**
    * @notice toggler role grant/revoke
    */
    function grantTogglerRole(address account) external onlyOwner{
        _grantRole(TOGGLER_ROLE, account);
    }

    function revokeTogglerRole(address account) external onlyOwner{
        _revokeRole(TOGGLER_ROLE, account);
    }

    /**
    * @notice toggling status variables
    */
    function toggleFreeMinting() external onlyOwner{
        freeMinting = !freeMinting;
    }

    function toggleWhitelistSale() external onlyOwner{
        whitelistSale = !whitelistSale;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleRaining() external{
        require(hasRole(TOGGLER_ROLE, msg.sender), "Caller is not a toggler");
        isRaining = !isRaining;
    }

    /**
    * @notice set token URI
    */
    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
	
	function setRainTokenUri(string memory _baseRainTokenUri) external onlyOwner{
        baseRainTokenUri = _baseRainTokenUri;
    }
	
    /**
    * @notice returns the metadata uri for a given id
    *
    * @param _id the card id to return metadata for
    */
    function uri(uint256 _id) public view override returns (string memory) {
        require(exists(_id), "URI :: nonexistent token");

		if(isRaining){
			return bytes(baseRainTokenUri).length > 0 ? string(abi.encodePacked(baseRainTokenUri, Strings.toString(_id), ".json")) : "";
		}
		
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, Strings.toString(_id), ".json")) : "";
    }

    function getRandomNumber(uint256 _upper) private returns (uint) {
        randGenKey++;
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, randGenKey, msg.sender))) % _upper;
    }

    function getMinimumTotalSupplyID() private view returns (uint256) {
        uint256 minTotalSupplyID = 0;
        uint256 minTotalSupply = supplies[0];
        for(uint256 i = 1; i < supplies.length; i++) {
            uint256 totalSupplyByID = totalSupply(i);
            if(totalSupplyByID < minTotalSupply){
               minTotalSupply = totalSupplyByID;
               minTotalSupplyID = i;
           }
        }
        return minTotalSupplyID;
    }

    function getSumTotalSupplies() private view returns (uint256) {
        uint256 sumTotalSupplies = 0;
        for(uint256 k = 0; k < supplies.length; k++ ) {
            sumTotalSupplies += totalSupply(k);
        }
        return sumTotalSupplies;
    }
    
    /**
    * @notice Free Minting
    *
    * @param amount the amount to mint
    * @param merkleProof the valid merkle proof of sender
    */
    function freeMint(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external whenNotPaused callerIsUser {
        require(freeMinting, "Free Minting :: Free Minting is on Pause");
        require(amount > 0, "Free Minting :: Amount prohibited");
        uint256 sumTotalSupply = getSumTotalSupplies();
        require(sumTotalSupply + amount <= maxFreeMint, "Free Minting :: Max supply reached");
        require(mintFreeAmount[msg.sender] + amount <= maxAmountFreeMint , "Free Minting :: Max amount exceeded");
        
        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRootFreeMint, sender),
            "MerkleDistributor :: Invalid proof."
        );

        mintFreeAmount[msg.sender] += amount;
        minting(amount);
    }

    /**
    * @notice mint during whitelist sale
    *
    * @param amount the amount to mint
    * @param merkleProof the valid merkle proof of sender
    */
    function whitelistMint(
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused callerIsUser {
        require(whitelistSale, "Whitelist Sale :: Whitelist Minting is on Pause");
        require(amount > 0, "Whitelist Sale :: Amount prohibited");
        uint256 sumTotalSupply = getSumTotalSupplies();
        require(sumTotalSupply + amount <= maxWhitelist, "Whitelist Sale :: Max supply reached");
        require(mintWhitelistAmount[msg.sender] + amount <= maxAmountWhitelist , "Whitelist Sale :: Max amount exceeded");
        require(msg.value == amount * whitelistPrice, "Whitelist Sale :: Incorrect payment");

        bytes32 sender = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(merkleProof, merkleRootWhitelist, sender),
            "MerkleDistributor :: Invalid proof."
        );

        mintWhitelistAmount[msg.sender] += amount;
        minting(amount);
    }

    /**
    * @notice mint during public sale
    *
    * @param amount the amount of tokens to mint
    */
    function publicMint(uint256 amount) external payable whenNotPaused callerIsUser {
        require(publicSale, "Public Sale :: Not Yet Active");
        require(amount > 0, "Public Sale :: Amount prohibited");
        uint256 sumTotalSupply = getSumTotalSupplies();
        require(sumTotalSupply + amount <= MAX_SUPPLY, "Public Sale :: Max supply reached");
        require(mintPublicSaleAmount[msg.sender] + amount <= maxAmountPublic , "Public Sale :: Max amount exceeded");
        require(msg.value == amount * mintPrice, "Public Sale :: Incorrect payment");

        mintPublicSaleAmount[msg.sender] += amount;
        minting(amount);
    }

    /**
    * @notice global minting function used in whitelist and public sale
    *
    * @param amount the amount of tokens to minting
    */
    function minting(uint256 amount) private {
        uint256[] memory tokenIDs;
        if ( amount == 1 ) {
            uint256 randomID = getRandomNumber(supplies.length);
            tokenIDs = new uint256[](1);
            tokenIDs[0] = randomID;
            _mint(msg.sender, randomID, amount, "");
        } else {
            uint256[] memory amounts = new uint256[](6);
            
            tokenIDs = new uint256[](6);
            for(uint256 i = 0; i < amounts.length; i++ ) {
                tokenIDs[i] = i;
            }

            for(uint256 k = 0; k < amount; k++ ) {
                uint256 randomID = getRandomNumber(amounts.length);
                if (totalSupply(randomID) + amounts[randomID] + 1 <= supplies[randomID]) {
                    amounts[randomID] += 1;
                } else {
                    uint256 minSupplyID = getMinimumTotalSupplyID();
                    amounts[minSupplyID] += 1;
                }
            }
            _mintBatch(msg.sender, tokenIDs, amounts, "");
        }
        emit Purchased(tokenIDs, msg.sender, amount);
    }

    function teamMint(address to, uint256 id, uint256 amount) public onlyOwner {
        uint256 sumTotalSupply = getSumTotalSupplies();
        require(sumTotalSupply + amount <= MAX_SUPPLY, "Team Mint :: Max supply reached");
        uint256 totalSupplyByID = totalSupply(id);
        require(totalSupplyByID + amount <= supplies[id], "Team Mint :: ID Max supply reached");
        _mint(to, id, amount, "");
    }

    /* Operator Filter */
    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function withdraw(address to) public onlyOwner {
        if (to == address(0)) {
            revert SendToAddressZero();
        }

        uint256 amount = address(this).balance;

        (bool sent,) = payable(to).call{value: amount}("");
        if (!sent) {
            revert WithdrawSendFailed();
        }
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }
}