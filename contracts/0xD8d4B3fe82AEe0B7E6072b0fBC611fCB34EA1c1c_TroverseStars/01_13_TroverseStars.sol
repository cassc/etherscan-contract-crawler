// contracs/TroverseStars.sol
// SPDX-License-Identifier: MIT

// ████████╗██████╗  ██████╗ ██╗   ██╗███████╗██████╗ ███████╗███████╗    
// ╚══██╔══╝██╔══██╗██╔═══██╗██║   ██║██╔════╝██╔══██╗██╔════╝██╔════╝    
//    ██║   ██████╔╝██║   ██║██║   ██║█████╗  ██████╔╝███████╗█████╗      
//    ██║   ██╔══██╗██║   ██║╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██╔══╝      
//    ██║   ██║  ██║╚██████╔╝ ╚████╔╝ ███████╗██║  ██║███████║███████╗    
//    ╚═╝   ╚═╝  ╚═╝ ╚═════╝   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝    

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IYieldToken {
    function burn(address _from, uint256 _amount) external;
}


contract TroverseStars is ERC721Enumerable, Ownable {

    uint256 public constant TOTAL_STARS = 750;

    string private _baseTokenURI;

    IYieldToken public yieldToken;
    address public minter;

    mapping (uint256 => string) private _starName;
    mapping (string => bool) private _nameReserved;
    mapping (uint256 => string) private _starDescription;

    uint256 public nameChangePrice = 100 ether;
    uint256 public descriptionChangePrice = 100 ether;

    event YieldTokenChanged(address _yieldToken);
    event UpdatedMinter(address _minter);

    event NameChanged(uint256 starId, string starName);
    event NameCleared(uint256 starId, bool permanent);
    event DescriptionChanged(uint256 starId, string starDescription);
    event DescriptionCleared(uint256 starId);

    event UpdatedNameChangePrice(uint256 price);
    event UpdatedDescriptionChangePrice(uint256 price);


    constructor() ERC721("Troverse Stars", "STAR") { }

    
    modifier onlyMinter() {
        require(msg.sender == minter, "The caller is not the minter");
        _;
    }

    function updateMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Bad Minter address");
        minter = _minter;

        emit UpdatedMinter(_minter);
    }

    function Mint(address to, uint256 quantity) external onlyMinter {
        require(totalSupply() + quantity <= TOTAL_STARS, "Reached max supply");

        uint256 firstIndex = totalSupply() + 1;
        uint256 lastIndex = firstIndex + quantity - 1;

        for (uint256 i = firstIndex; i <= lastIndex; i++) {
            _safeMint(to, i);
        }
    }
    
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setYieldToken(address _yieldToken) external onlyOwner {
        require(_yieldToken != address(0), "Bad YieldToken address");
        yieldToken = IYieldToken(_yieldToken);

        emit YieldTokenChanged(_yieldToken);
    }

    function updateNameChangePrice(uint256 price) external onlyOwner {
        nameChangePrice = price;

        emit UpdatedNameChangePrice(price);
    }

    function updateDescriptionChangePrice(uint256 price) external onlyOwner {
        descriptionChangePrice = price;

        emit UpdatedDescriptionChangePrice(price);
    }

    /**
    * @notice Changes the name of a star. Make sure to use appropriate names only
    */
    function changeName(uint256 starId, string memory newName) external {
        require(_msgSender() == ownerOf(starId), "Caller is not the owner");
        require(validateName(newName) == true, "Not a valid new name");
        require(sha256(bytes(newName)) != sha256(bytes(_starName[starId])), "New name is same as the current one");
        require(isNameReserved(newName) == false, "Name already reserved");

        if (bytes(_starName[starId]).length > 0) {
            toggleReserveName(_starName[starId], false);
        }
        toggleReserveName(newName, true);

        if (nameChangePrice > 0) {
            yieldToken.burn(msg.sender, nameChangePrice);
        }

        _starName[starId] = newName;

        emit NameChanged(starId, newName);
    }

    /**
    * @notice Clears the name of a star, in case an inappropriate name has set
    */
    function clearName(uint256 starId, bool permanent) external onlyOwner {
        if (!permanent) {
            toggleReserveName(_starName[starId], false);
        }

        delete _starName[starId];
        emit NameCleared(starId, permanent);
    }

    /**
    * @notice Changes the description of a star. Make sure to use appropriate descriptions only
    */
    function changeDescription(uint256 starId, string memory newDescription) external {
        require(_msgSender() == ownerOf(starId), "Caller is not the owner");

        if (descriptionChangePrice > 0) {
            yieldToken.burn(msg.sender, descriptionChangePrice);
        }
        
        _starDescription[starId] = newDescription;

        emit DescriptionChanged(starId, newDescription);
    }

    /**
    * @notice Clears the description of a star, in case an inappropriate description has set
    */
    function clearDescription(uint256 starId) external onlyOwner {
        delete _starDescription[starId];
        emit DescriptionCleared(starId);
    }

    /**
    * Changes a name reserve state
    */
    function toggleReserveName(string memory name, bool isReserve) internal {
        _nameReserved[toLower(name)] = isReserve;
    }

    /**
    * Returns the name of the star at index
    */
    function starNameByIndex(uint256 index) external view returns (string memory) {
        return _starName[index];
    }

    /**
    * Returns the description of the star at index
    */
    function starDescriptionByIndex(uint256 index) external view returns (string memory) {
        return _starDescription[index];
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
}