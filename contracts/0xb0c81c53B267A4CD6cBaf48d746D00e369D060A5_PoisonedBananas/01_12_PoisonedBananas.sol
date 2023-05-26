// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
                  .__                                          .___
______     ____   |__|   ______   ____     ____     ____     __| _/
\____ \   /  _ \  |  |  /  ___/  /  _ \   /    \  _/ __ \   / __ | 
|  |_> > (  <_> ) |  |  \___ \  (  <_> ) |   |  \ \  ___/  / /_/ | 
|   __/   \____/  |__| /____  >  \____/  |___|  /  \___  > \____ | 
|__|                        \/                \/       \/       \/ 
__________                                                         
\______   \ _____      ____   _____      ____   _____      ______  
 |    |  _/ \__  \    /    \  \__  \    /    \  \__  \    /  ___/  
 |    |   \  / __ \_ |   |  \  / __ \_ |   |  \  / __ \_  \___ \   
 |______  / (____  / |___|  / (____  / |___|  / (____  / /____  >  
        \/       \/       \/       \/       \/       \/       \/                  
 */

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Represents opensea's proxy contract for delegated transactions
 */
contract OwnableDelegateProxy {}

/**
 * @notice Represents opensea's ProxyRegistry contract.
 * Used to find the opensea proxy contract of a user
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title PoisonedBananas.
 *
 * @notice The smart contract representing the Prime Ape Planet Poisoned Banana's.
 * The poisoned banana's implement and ERC1155 standard and can be burned to mutate
 * Prime Apes into Infected Apes
 */
contract PoisonedBananas is ERC1155Supply, Ownable {
    using Strings for uint256;

    /** VARIABLES */
    address public openseaProxyRegistryAddress;
    address private claimContract;
    address private infectContract;

    string public baseURIString = "https://primeapeplanet.com/bananas/";
    string public name = "Poisoned Bananas";
    string public symbol = "PSB";

    uint256 public lvl1Banana = 0;
    uint256 public lvl2Banana = 1;
    uint256 public lvl3Banana = 2;

    mapping(uint256 => bool) public isPoisonedBanana;

    /** MODIFIERS */
    modifier onlyClaimer {
        require(msg.sender != address(0), "Zero address");
        require(msg.sender == claimContract, "Sender not claimer");
        _;
    }

    modifier onlyInfector {
        require(msg.sender != address(0), "Zero address");
        require(msg.sender == infectContract, "Sender not infector");
        _;
    }
    
    /** EVENTS */
    event setBaseURIEvent(string indexed baseURI);
    event setOwnersExplicitEvent(uint256 indexed quantity);
    event setClaimContractEvent(address indexed claimContract);
    event setInfectContractEvent(address indexed infectContract);

    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC1155("") Ownable() {        
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;

        isPoisonedBanana[lvl1Banana] = true;
        isPoisonedBanana[lvl2Banana] = true;
        isPoisonedBanana[lvl3Banana] = true;
    }

    /** MINTING */

    /**
     * @notice Function to mint a signle BANANA to a specified address.
     * Can only be called by claimContract
     *
     * @param bananaType The type of the poisoned banana
     * @param to The address to which the Banana will be minted to
     */
    function mintSingle(uint256 bananaType, address to) external onlyClaimer {
        require(isPoisonedBanana[bananaType], "Provided type is not poisoned");
        _mint(to, bananaType, 1, "");
    }

    /**
     * @notice Function to mint multiple BANANA's to a specified address.
     * Can only be called by claimContract
     *
     * @param bananaTypes The types of the poisoned bananas
     * @param amounts The amounts of each poisoned banana type
     * @param to The address to which the Banana will be minted to
     */
    function mintMultiple(uint256[] memory bananaTypes, uint256[] memory amounts, address to) external onlyClaimer {
        require(bananaTypes.length > 0, "Zero types provided");
        require(bananaTypes.length == amounts.length, "Non equal amounts specified");        
        for (uint i = 0; i < bananaTypes.length; i++) {
            require(isPoisonedBanana[bananaTypes[i]], "Provided type is not poisoned");
        }

        _mintBatch(to, bananaTypes, amounts, "");
    }

    /**
     * @dev BURNING
     */

    /**
     * @notice Function to burn a banana. 
     * Can only be called by infectContract
     *
     * @param bananaOwner. The address of the banana owner
     * @param bananaType. The type of banana to burn
     */
    function burnSingle(address bananaOwner, uint256 bananaType) external onlyInfector {
         require(isPoisonedBanana[bananaType], "Provided type is not poisoned");
        _burn(bananaOwner, bananaType, 1);
    }

    /**
     * @notice Function to burn multiple bananas.
     * Can only be called by infectContract
     *
     * @param bananaOwner. The address of the banana owner
     * @param bananaTypes. The types of bananas to burn
     * @param amounts. The amounts of bananas to burn
     */
    function burnMultiple(address bananaOwner, uint256[] memory bananaTypes, uint256[] memory amounts) external onlyInfector {
        require(bananaTypes.length > 0, "Zero types provided");
        require(bananaTypes.length == amounts.length, "Non equal amounts specified");        
        for (uint i = 0; i < bananaTypes.length; i++) {
            require(isPoisonedBanana[bananaTypes[i]], "Provided type is not poisoned");
             _burn(bananaOwner, bananaTypes[i], amounts[i]);
        }       
    }

    /** 
     * @dev VIEW ONLY
     */

    /**
     * @notice Function to get the URI for the metadata of a specific tokenId
     * @dev Return value is based on revealDate.
     *
     * @param typeId. The poisoned banana type.
     * @return URI. The URI of the banana type
     */
    function uri(uint256 typeId) public view override returns (string memory) {
        require(isPoisonedBanana[typeId], "Provided type is not poisoned");

        return string(abi.encodePacked(baseURIString, typeId.toString()));     
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy account to enable gas-less listings.
     * @dev Used for integration with opensea's Wyvern exchange protocol.
     * See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Create an instance of the ProxyRegistry contract from Opensea
        ProxyRegistry proxyRegistry = ProxyRegistry(openseaProxyRegistryAddress);
        // whitelist the ProxyContract of the owner of the NFT
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        if (openseaProxyRegistryAddress == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @dev OWNER  ONLY
     */

    /**
     * @notice Allow for changing of metadata URL.
     *
     * @param _newBaseURI. The new base URL.
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
        emit setBaseURIEvent(_newBaseURI);
    }

    function setClaimContract(address newClaimContract) external onlyOwner {
        claimContract = newClaimContract;
        emit setClaimContractEvent(newClaimContract);
    }

    function setInfectContract(address newInfectContract) external onlyOwner {
        infectContract = newInfectContract;
        emit setInfectContractEvent(newInfectContract);
    }

    /**
     * @dev Fallback function for receiving Ether
     */
    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

     /**
     * @notice Allows owner to withdraw stuck eth.
     *
     * @param _to. The address to send the funds to.
     */
    function withdrawEth(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
    }
}