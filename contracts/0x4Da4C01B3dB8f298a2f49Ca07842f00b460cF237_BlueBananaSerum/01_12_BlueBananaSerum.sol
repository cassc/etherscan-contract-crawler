// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract BlueBananaSerum is ERC1155Supply, Ownable {
    using Strings for uint256;

    address public openseaProxyRegistryAddress;
    string public baseURIString = "https://storage.googleapis.com/alphakongclub/bluebananaserum/";
    string public name = "Blue Banana Serum";
    string public symbol = "BBS";

    mapping(uint256 => bool) public validSerumType;
    mapping(address => bool) public allowedMinter;

    modifier onlyMinter {
        require(allowedMinter[msg.sender], "Sender not allowed to mint");
        _;
    }
    
    event setBaseURIEvent(string indexed baseURI);
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC1155("") Ownable() {        
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
        validSerumType[0] = true;
        allowedMinter[owner()] = true;
    }

    /** === Minting === */

    function mint(uint256 serumType, address to) external onlyMinter {
        require(validSerumType[serumType], "Serum type not valid");
        _mint(to, serumType, 1, "");
    }

    function mintMultiple(uint256 serumType, uint256 amount, address to) external onlyMinter {
        require(validSerumType[serumType], "Serum type not valid");
        _mint(to, serumType, amount, "");
    }

    /** === Burning === */

    function burn(uint256 serumType, address serumOwner) external onlyMinter {
         require(validSerumType[serumType], "Serum type not valid");
        _burn(serumOwner, serumType, 1);
    }

    function burnMultiple(uint256 serumType, uint256 amount, address serumOwner) external onlyMinter {
         require(validSerumType[serumType], "Serum type not valid");
        _burn(serumOwner, serumType, amount);
    }

    /** === View === */

    function uri(uint256 typeId) public view override returns (string memory) {
        require(validSerumType[typeId], "Serum type not valid");
        return string(abi.encodePacked(baseURIString, typeId.toString()));     
    }

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

    /** === Admin only === */

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
        emit setBaseURIEvent(_newBaseURI);
    }

    function setAllowedMinter(address minter, bool allowed) external onlyOwner {
        allowedMinter[minter] = allowed;
    }

    function setValidSerumType(uint256 serumType, bool valid) external onlyOwner {
        validSerumType[serumType] = valid;
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }

    function withdrawEth(address _to) external onlyOwner {
        require(_to != address(0), "CANNOT WITHDRAW TO ZERO ADDRESS");
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "NO ETHER TO WITHDRAW");
        payable(_to).transfer(contractBalance);
    }
}