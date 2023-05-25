// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "@openzeppelin/contracts/security/Pausable.sol";

import "./ONFT721.sol";

contract ONFTBased is ONFT721, Pausable {
    using Strings for uint;

    uint public startMintId;
    uint public immutable endMintId;
    uint public startHonoraryMintId;
    string public contractURI;
    string public customName;
    string public customSymbol;
    bool public reveal;
    IERC721 public immutable erc721Contract;

    /// @notice Constructor for the ONFTBased
    /// @param _name the name of the token
    /// @param _symbol the token symbol
    /// @param _baseTokenURI the base URI for computing the tokenURI
    /// @param _layerZeroEndpoint handles message transmission across chains
    /// @param _startMintId the starting mint number on this chain
    /// @param _endMintId the max number of mints on this chain
    /// @param _startHonoraryMintId the starting honorary mint number on this chain
    /// @param _erc721Address the address of the original erc721Address
    constructor(string memory _name, string memory _symbol, string memory _baseTokenURI, address _layerZeroEndpoint, uint _startMintId, uint _endMintId, uint _startHonoraryMintId, address _erc721Address) ONFT721(_name, _symbol, _layerZeroEndpoint) {
        customName = _name;
        customSymbol = _symbol;
        setBaseURI(_baseTokenURI);
        contractURI = _baseTokenURI;
        startMintId = _startMintId;
        endMintId = _endMintId;
        startHonoraryMintId = _startHonoraryMintId;
        erc721Contract = IERC721(_erc721Address);
        _pause();
    }

    function mintHonorary(address to) external onlyOwner {
        _safeMint(to, startHonoraryMintId++);
    }

    function assignNewONFT(uint amount) external onlyOwner {
        uint numOfLoops = startMintId + amount;
        for (uint i = startMintId; i < numOfLoops; i++) {
            require(startMintId <= endMintId, "ONFT: Max Mint limit reached.");
            try erc721Contract.ownerOf(i) returns (address toAddress) {
                _safeMint(toAddress, startMintId++);
            } catch {
                _safeMint(address(0xdEaD), startMintId++);
            }
        }
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

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function setName(string memory name) external onlyOwner {
        customName = name;
    }

    function setSymbol(string memory symbol) external onlyOwner {
        customSymbol = symbol;
    }

    function name() public view virtual override returns (string memory) {
        return customName;
    }

    function symbol() public view virtual override returns (string memory) {
        return customSymbol;
    }
}