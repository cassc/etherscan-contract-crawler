pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./token/onft/ONFT.sol";
import "./token/ERC721A.sol";
import "./interfaces/IMint.sol";

contract Rabby is ONFT, IMintNFT {
    address public managerAddress;

    modifier onlyManager() {
        require(msg.sender == managerAddress);
        _;
    }

    /// @param _layerZeroEndpoint handles message transmission across chains
    constructor(address _layerZeroEndpoint)
        ONFT("Cyber Rabby", "Rabby", _layerZeroEndpoint)
    {}

    function mintFor(address to, uint64 numTokens)
        external
        override
        onlyManager
    {
        require(_currentIndex + numTokens <= 10000);
        _safeMint(to, numTokens);
    }

    function transferBundle(
        address to,
        uint256 startingIndex,
        uint64 numTokens
    ) external override onlyManager {
        _transferBatch(msg.sender, to, startingIndex, numTokens);
    }

    function setManagerAddress(address _managerAddress) public onlyOwner {
        managerAddress = _managerAddress;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        onlyMinted(_tokenId)
        returns (string memory)
    {
        return
            string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    modifier onlyMinted(uint256 _tokenId) {
        require(_exists(_tokenId), "This token id does not minted yet.");
        _;
    }
}