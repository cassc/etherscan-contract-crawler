// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./ONFT721.sol";

contract ONFT is ONFT721, Pausable, ReentrancyGuard {
    using Strings for uint;

    uint public currentMintId;
    uint public immutable maximumSupply;
    bool public reveal;
    string public contractURI;
    address public feeCollectorAddress;
    mapping(uint => uint16) public chainId;

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Must have minter role.");
        _;
    }

    /// @notice Constructor for the ONFT
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _feeCollectorAddress the address fee collector
    /// @param _maxSupply of the the nft
    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, address _layerZeroEndpoint, address _feeCollectorAddress, uint _maxSupply) ONFT721(_name, _symbol, _layerZeroEndpoint) {
        setBaseURI(_baseTokenURI);
        contractURI = _baseTokenURI;
        feeCollectorAddress = _feeCollectorAddress;
        currentMintId = 0;
        maximumSupply = _maxSupply;
        reveal = false;
    }

    function mint(address to) external onlyMinter {
        require(currentMintId < maximumSupply, "Max supply reached.");
        _mint(to, currentMintId++);
    }

    function mintHonorary(address to, uint tokenId) external onlyMinter {
        _mint(to, tokenId);
    }

    function _beforeSend(address, uint16, bytes memory, uint _tokenId) internal override whenNotPaused {
        _burn(_tokenId);
    }

    function pauseSendTokens(bool pause) external onlyOwner {
        pause ? _pause() : _unpause();
    }

    function activateReveal() external onlyOwner {
        reveal = true;
    }

    function tokenURI(uint tokenId) public view override returns (string memory) {
        if (reveal) {
            return string(abi.encodePacked(_baseURI(), tokenId.toString()));
        }
        return _baseURI();
    }

    function tokenChainId(uint tokenId) public view returns (uint16) {
        return chainId[tokenId];
    }

    function setFeeCollector(address _feeCollectorAddress) external onlyOwner {
        feeCollectorAddress = _feeCollectorAddress;
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function totalSupply() public view virtual returns (uint) {
        return currentMintId;
    }

    function maxSupply() public view virtual returns (uint) {
        return maximumSupply;
    }

    function setChainId(uint _tokenId, uint16 _chainId) public onlyOwner {
        _setChainId(_tokenId, _chainId);
    }

    //tokenIds and chainIds must be in matching order
    function setChainIds(uint[] memory _tokenIds, uint16[] memory _chainIds) public onlyOwner {
        for (uint i = 0; i < _tokenIds.length; i++) {
            _setChainId(_tokenIds[i], _chainIds[i]);
        }
    }

    function _setChainId(uint _tokenId, uint16 _chainId) internal {
        chainId[_tokenId] = _chainId;
    }
}