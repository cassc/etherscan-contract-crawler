// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/DisplayURISwitchable.sol";

contract Arcade is DisplayURISwitchable, ERC721Enumerable, AccessControl, Ownable {
    mapping(address => uint256) private _mintedList;
    address private _derivativeContractList;
    
    uint256 public MAX_PER_ADDRESS;
    uint256 public MAX_PUBLIC;
    uint256 public MAX_RESERVED;
    uint256 public STARTING_RESERVED_ID;
    
    uint256 public totalReservedSupply = 0;
    uint256 public totalPublicSupply = 0;
    uint256 public temporaryPublicMax = 0;
    bool public frozen = false;

    // Create a new role identifier for the operator role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(uint256 maxPublic, uint256 maxTemporaryPublic, uint256 maxReserved, uint256 startingReservedID, uint256 maxPerAddress, address[] memory whitelistAddresses) ERC721("Arcade", "ARCADE") {
        MAX_PUBLIC = maxPublic;
        MAX_RESERVED = maxReserved;
        STARTING_RESERVED_ID = startingReservedID;
        MAX_PER_ADDRESS = maxPerAddress;
        temporaryPublicMax = maxTemporaryPublic;

        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < whitelistAddresses.length; i++) {
            require(whitelistAddresses[i] != address(0), "Can't add the null address.");
            _setupRole(OPERATOR_ROLE, whitelistAddresses[i]);
        }
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You must be the token owner.");
        _;
    }

    modifier lessThanMaxTotalSupply(uint256 tokenId) {
        require(tokenId <= MAX_PUBLIC + MAX_RESERVED, "Arcade ID is too high.");
        require(tokenId > 0, "Arcade ID cannot be 0.");
        _;
    }

    function setTemporaryPublicMax(uint256 maxTemporaryPublic)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(maxTemporaryPublic <= MAX_PUBLIC, "You cannot set the temporary max above the absolute total.");
        
        temporaryPublicMax = maxTemporaryPublic;
    }

    function freezeBaseURI()
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        frozen = true;
    }
       
    function derivativeContractList() public view returns (address) {
        return _derivativeContractList;
    }
    
    function setDerivativeContractList(address newDerivativeContractList)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _derivativeContractList = newDerivativeContractList;
    }
       
    function setBaseURI(string memory baseURI)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(!frozen, "Contract is frozen.");

        _setBaseURI(baseURI);
    }

    function setDisplayBaseURI(string memory baseURI)
        public
        onlyRole(OPERATOR_ROLE)
    {
        _setDisplayBaseURI(baseURI);
    }

    function setDisplayMode(uint256 tokenId, bool mode)
        public
        override
        lessThanMaxTotalSupply(tokenId)
        onlyTokenOwner(tokenId)
    {
        _setDisplayMode(tokenId, mode);
    }

    function mintPublic(bool mode) public {
        require(_mintedList[msg.sender] < MAX_PER_ADDRESS, "You have reached your minting limit.");
        require(totalPublicSupply < MAX_PUBLIC, "There are no more NFTs for public minting.");
        require(totalPublicSupply < temporaryPublicMax, "There are no more NFTs for public minting at this time.");
        
        _mintedList[msg.sender] += 1;
        
        uint256 tokenId = totalPublicSupply + 1;
        
        // Skip the reserved block
        if (tokenId >= STARTING_RESERVED_ID) {
            tokenId += MAX_RESERVED;
        }

        _setDisplayMode(tokenId, mode);
        totalPublicSupply += 1;
        _safeMint(msg.sender, tokenId);
    }

    function _mintReserved(address targetAddress, uint256[] calldata tokenIds, bool[] calldata modes)
        private
    {
        require(totalReservedSupply + tokenIds.length <= MAX_RESERVED, "This would exceed the total number of reserved NFTs.");
        require(tokenIds.length == modes.length, "Input arrays must have the same length.");

        for(uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId >= STARTING_RESERVED_ID && tokenId < STARTING_RESERVED_ID + MAX_RESERVED, "Token ID is not in the reserve range.");

            _setDisplayMode(tokenId, modes[i]);
            totalReservedSupply += 1;
            _safeMint(targetAddress, tokenId);
        }
    }

    function mintReserved(uint256[] calldata tokenIds, bool[] calldata modes)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _mintReserved(msg.sender, tokenIds, modes);
    }

    function devMintReserved(address targetAddress, uint256[] calldata tokenIds, bool[] calldata modes)
        external
        onlyRole(OPERATOR_ROLE)
    {
        require(targetAddress != address(0), "Can't mint to the null address.");

        _mintReserved(targetAddress, tokenIds, modes);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(DisplayURISwitchable, ERC721)
        lessThanMaxTotalSupply(tokenId)
        returns (string memory)
    {
        return DisplayURISwitchable.tokenURI(tokenId);
    }
}