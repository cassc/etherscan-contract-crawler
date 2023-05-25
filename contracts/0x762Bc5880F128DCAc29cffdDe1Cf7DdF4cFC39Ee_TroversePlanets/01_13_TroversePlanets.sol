// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC721A.sol";


interface IYieldToken {
    function burn(address _from, uint256 _amount) external;
}


contract TroversePlanets is Ownable, ERC721A {

    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant TOTAL_PLANETS = 10000;

    string private _baseTokenURI;

    IYieldToken public yieldToken;

    mapping (uint256 => string) private _planetName;
    mapping (string => bool) private _nameReserved;
    mapping (uint256 => string) private _planetDescription;

    uint256 public nameChangePrice = 100 ether;
    uint256 public descriptionChangePrice = 100 ether;

    event NameChanged(uint256 planetId, string planetName);
    event NameCleared(uint256 planetId);
    event DescriptionChanged(uint256 planetId, string planetDescription);
    event DescriptionCleared(uint256 planetId);

    address public minter;
    bool public isMinterLocked = false;
    

    constructor() ERC721A("Troverse Planets", "PLANET") { }

    modifier callerIsMinter() {
        require(msg.sender == minter, "The caller is not the minter");
        _;
    }

    /**
    * Changes the minter address
    */
    function updateMinter(address _minter) external onlyOwner {
        require(isMinterLocked == false, "Minter ownership renounced");
        minter = _minter;
    }

    /**
    * Locks the minter
    */
    function lockMinter() external onlyOwner  {
        isMinterLocked = true;
    }

    /**
    * Sets the YieldToken address to be burnt for changing name or description
    */
    function setYieldToken(address yieldTokenAddress) external onlyOwner {
        yieldToken = IYieldToken(yieldTokenAddress);
    }
    
    /**
    * Updates the price for changing the planet's name
    */
    function updateNameChangePrice(uint256 price) external onlyOwner {
        nameChangePrice = price;
    }

    /**
    * Updates the price for changing the planet's description
    */
    function updateDescriptionChangePrice(uint256 price) external onlyOwner {
        descriptionChangePrice = price;
    }

    /**
    * @notice Changes the name of a planet. Make sure to use appropriate names only
    */
    function changeName(uint256 planetId, string memory newName) external {
        require(_msgSender() == ownerOf(planetId), "Caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_planetName[planetId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        if (bytes(_planetName[planetId]).length > 0) {
            toggleReserveName(_planetName[planetId], false);
        }
        toggleReserveName(newName, true);

        if (nameChangePrice > 0) {
            yieldToken.burn(msg.sender, nameChangePrice);
        }

        _planetName[planetId] = newName;

        emit NameChanged(planetId, newName);
    }

    /**
    * @notice Clears the name of a planet, in case an inappropriate name has set
    */
    function clearName(uint256 planetId) external onlyOwner {
        delete _planetName[planetId];
        emit NameCleared(planetId);
    }

    /**
    * @notice Changes the description of a planet. Make sure to use appropriate descriptions only
    */
    function changeDescription(uint256 planetId, string memory newDescription) external {
        require(_msgSender() == ownerOf(planetId), "Caller is not the owner");

        if (descriptionChangePrice > 0) {
            yieldToken.burn(msg.sender, descriptionChangePrice);
        }
        
        _planetDescription[planetId] = newDescription;

        emit DescriptionChanged(planetId, newDescription);
    }

    /**
    * @notice Clears the description of a planet, in case an inappropriate description has set
    */
    function clearDescription(uint256 planetId) external onlyOwner {
        delete _planetDescription[planetId];
        emit DescriptionCleared(planetId);
    }

    /**
    * Changes a name reserve state
    */
    function toggleReserveName(string memory name, bool isReserve) internal {
        _nameReserved[toLower(name)] = isReserve;
    }

    /**
    * Returns the name of the planet at index
    */
    function planetNameByIndex(uint256 index) public view returns (string memory) {
        return _planetName[index];
    }

    /**
    * Returns the description of the planet at index
    */
    function planetDescriptionByIndex(uint256 index) public view returns (string memory) {
        return _planetDescription[index];
    }

    /**
    * Returns true if the name has been reserved
    */
    function isNameReserved(string memory nameString) public view returns (bool) {
        return _nameReserved[toLower(nameString)];
    }

    /**
    * Validates a name string
    */
    function validateName(string memory newName) public pure returns (bool) {
        bytes memory b = bytes(newName);
        if (b.length < 1) return false;
        if (b.length > 25) return false; // Cannot be longer than 25 characters
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for(uint256 i; i < b.length; i++){
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            )
            return false;

            lastChar = char;
        }

        return true;
    }

    /**
    * Converts a string to lowercase
    */
    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
    

    /**
    * Tries to mint NFTs for an address called by the minter contract
    */
    function Mint(address to, uint256 quantity) external payable callerIsMinter {
        _safeMint(to, quantity);
    }


    /**
     * See {ERC721A-_baseURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * Sets the base URI of the metadata
     */
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    /**
     * See {ERC721A-_setOwnersExplicit}.
     */
    function setOwnersExplicit(uint256 quantity) external onlyOwner {
        _setOwnersExplicit(quantity);
    }

    /**
     * Gets the total mints by an address
     */
    function numberMinted(address owner) external view returns (uint256) {
        return _numberMinted(owner);
    }

    /**
     * Gets the ownership info of a planet
     */
    function getOwnershipData(uint256 tokenId) external view returns (address) {
        return ownershipOf(tokenId);
    }
    
    /**
     * Returns the total supply for the minter contract
     */
    function totalSupplyExternal() external view returns (uint256) {
        return currentIndex;
    }
}