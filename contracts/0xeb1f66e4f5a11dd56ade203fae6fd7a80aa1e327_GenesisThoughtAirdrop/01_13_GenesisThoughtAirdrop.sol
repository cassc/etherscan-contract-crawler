// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title GenesisThoughtAirdrop
 * @author Gunvant Kathrotiya (https://github.com/gunvantk)
 * @dev ERC721 token airdropped to whitelisted addresses
 */
contract GenesisThoughtAirdrop is ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private supplyCounter;

    event BaseURIChanged(string baseURI);

    /**
     * @param _initialBaseURI Base URI for all NFTs
     */
    constructor(string memory _initialBaseURI)
        ERC721("GenesisThoughtAirdrop", "GTA")
    {
        baseURI = _initialBaseURI;
    }

    /** MINTING **/

    uint256 public constant MAX_SUPPLY = 111;

    /**
     * @dev Airdrop token to the whitelisted addresses
     * @param _addresses List of addresses to mint token to
     */
    function mintTokensToAddresses(address[] calldata _addresses)
        external
        onlyOwner
    {
        require(
            totalSupply() + _addresses.length <= MAX_SUPPLY,
            "Exceeds max supply"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            uint256 mintIndex = totalSupply();
            supplyCounter.increment();
            _mint(_addresses[i], mintIndex);
        }
    }

    function totalSupply() public view returns (uint256) {
        return supplyCounter.current();
    }

    /** URI HANDLING **/

    string public baseURI;

    /**
     * @notice Sets a new base URI for all NFTs
     * @param _newBaseURI New base URI for all NFTs
     */
    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
        emit BaseURIChanged(_newBaseURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            tokenId < totalSupply(),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return
            string(
                abi.encodePacked(
                    baseURI,
                    "metadata/",
                    tokenId.toString(),
                    ".json"
                )
            );
    }
}