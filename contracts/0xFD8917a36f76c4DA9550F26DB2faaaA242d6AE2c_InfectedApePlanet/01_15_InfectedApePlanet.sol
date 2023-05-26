// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OwnableDelegateProxy {}
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract InfectedApePlanet is ERC721Enumerable, Ownable {
    using Strings for uint256;

    address public openseaProxyRegistryAddress;
    address public infectContract;
    string public baseURIString = "https://primeapeplanet.com/infectedmetadata/";

    modifier onlyInfector {
        require(msg.sender != address(0), "Zero address");
        require(msg.sender == infectContract || msg.sender == owner(), "Sender not infector");
        _;
    }

    event setBaseURIEvent(string indexed baseURI);
    event ReceivedEther(address indexed sender, uint256 indexed amount);

    constructor(
        address _openseaProxyRegistryAddress
    ) ERC721("Infected Ape Planet", "IAP") Ownable() {
        openseaProxyRegistryAddress = _openseaProxyRegistryAddress;
    }

    function mintTo(uint256 tokenId, address _to) external onlyInfector {
        _safeMint(_to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURIString, tokenId.toString()));     
    }

    function exists(uint256 tokenId) external view returns(bool) {
        return _exists(tokenId);
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURIString = _newBaseURI;
        emit setBaseURIEvent(_newBaseURI);
    }

    function setInfectContract(address newInfectContract) external onlyOwner {
        infectContract = newInfectContract;       
    }

    receive() external payable {
        emit ReceivedEther(msg.sender, msg.value);
    }
}