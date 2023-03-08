// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarExecutable.sol";

contract JunkPoop is ERC721, Ownable, ERC721Burnable, AxelarExecutable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;

    string public managerChain;
    string public managerAddress;

    string private _baseTokenURI = "https://poop.junkyard.wtf/";

    uint256 public constant maxItem = 10000;

    event TokenMinted(address indexed to, uint256 indexed tokenid);

    modifier isFromManager(
        string calldata _sourceChain,
        string calldata _sourceAddress
    ) {
        bytes32 source = keccak256(abi.encodePacked(_sourceChain, _sourceAddress));
        bytes32 manager = keccak256(abi.encodePacked(managerChain, managerAddress));

        require(source == manager, "Not allowed to call this contract");
        _;
    }

    constructor(address _gateway)
        ERC721("Junk Poop", "JunkPoop")
        AxelarExecutable(_gateway)
    {
        _tokenIdCounter.increment();
    }

    /**
     * @notice Mint a new token.
     * @dev Emit an event intercepted by the Junkbot to update database
     * @param to wallet to send token
     */
    function safeMint(address to) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        require(tokenId <= maxItem, "No token left");

        _safeMint(to, tokenId);
        _tokenIdCounter.increment();
        emit TokenMinted(to, tokenId);
    }

    /**
     * @notice Update token URI
     * @param _newUri New token URI
     */
    function setBaseTokenUri(string memory _newUri) external onlyOwner {
        _baseTokenURI = _newUri;
    }

    /**
     * @notice Return URI of one token
     * @param tokenId Token ID of token URI requested
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        string memory currentBaseURI = _baseUri();

        return
            bytes(currentBaseURI).length > 0
                ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
                : "";
    }

    /**
     * @notice Return the total supply of Tokens
     */
    function totalSupply() external view returns (uint256 supply) {
        return _tokenIdCounter.current() - 1;
    }

    /**
     * @notice Update managerChain variable.
     * @param newManagerChain The new name.
     */
    function setManagerChain(string memory newManagerChain) external onlyOwner {
        managerChain = newManagerChain;
    }

    /**
     * @notice Update managerChain variable.
     * @param newManagerAddress The new address of the manager.
     */
    function setManagerAddress(string memory newManagerAddress) external onlyOwner {
        managerAddress = newManagerAddress;
    }

    /**
     * @notice Called by Axelar relayer. Decode payload to get values and call _safeMint().
     * @param _sourceChain SouceChain of Axelar request
     * @param _sourceAddress Contract Address of Axelar request
     * @param _payload bytes string with all informations for _safeMint()
     */
    function _execute(
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override isFromManager(_sourceChain, _sourceAddress) {
        (address to, uint256 tokenId, address collection) = abi.decode(
            _payload,
            (address, uint256, address)
        );

        tokenId = _tokenIdCounter.current();
        require(tokenId <= maxItem, "No token left");

        _safeMint(to, tokenId);
        _tokenIdCounter.increment();

        emit TokenMinted(to, tokenId);
    }

    /**
     * @notice Return the current baseTokenURI
     */
    function _baseUri() internal view virtual returns (string memory) {
        return _baseTokenURI;
    }
}