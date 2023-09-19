// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981Royalties.sol";

/**
    ___       ___       ___       ___       ___       ___       ___   
   /\__\     /\  \     /\__\     /\  \     /\  \     /\  \     /\  \  
  /::L_L_   /::\  \   /:| _|_   /::\  \   /::\  \   _\:\  \   /::\  \ 
 /:/L:\__\ /:/\:\__\ /::|/\__\ /::\:\__\ /::\:\__\ /\/::\__\ /\:\:\__\
 \/_/:/  / \:\/:/  / \/|::/  / \/\::/  / \;:::/  / \::/\/__/ \:\:\/__/
   /:/  /   \::/  /    |:/  /    /:/  /   |:\/__/   \:\__\    \::/  / 
   \/__/     \/__/     \/__/     \/__/     \|__|     \/__/     \/__/  
*/

/**
 * @title NYC Underground Stories
 * @author story: monaris, solidity: nnnnicholas
 * @notice This contract mints all 51 NYCUS NFTs upon deploy. No further NFTs can be minted on this contract once deployed.
 */
contract NYCUS is ERC721Enumerable, IERC2981Royalties {
    /// @notice Maximum total number of NFTs that can be minted on this contract.
    uint256 public maxTotalSupply;
    string public baseTokenURI;

    address private _royaltiesRecipient;
    uint256 private _royaltiesValue;

    event MaxTotalSupplySet(uint256 maxTotalSupply);
    event RoyaltiesSet(address royaltyRecipient, uint256 royaltyValue);
    event BaseURIChanged(string baseTokenURI);

    /**
     * @notice Names contract then mints all tokens and transfers them to artist.
     * @dev Explain to a developer any extra details
     * @param _name Contract name
     * @param _symbol Contract's symbol
     * @param _ipfsURI The IPFS CID that will contain all the token data
     * @param _toAddress The address to which all 50 tokens will be minted.
     * @param _maxTotalSupply The collection's total supply. No more than this will ever be minted.
     * @param _royaltyRecipient The address receiving royalties for all tokens.
     * @param _royaltyValue The royalty value out of 10000.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _ipfsURI,
        address _toAddress,
        uint256 _maxTotalSupply,
        address _royaltyRecipient,
        uint256 _royaltyValue
    ) ERC721(_name, _symbol) {
        baseTokenURI = string(abi.encodePacked("ipfs://", _ipfsURI));
        emit BaseURIChanged(baseTokenURI);
        maxTotalSupply = _maxTotalSupply;
        emit MaxTotalSupplySet(maxTotalSupply);
        _setRoyalties(_royaltyRecipient, _royaltyValue);
        emit RoyaltiesSet(_royaltyRecipient, _royaltyValue);
        _mintAll(_toAddress);
    }

    /// @notice Mints all 50 tokens. Called by the contstructor.
    function _mintAll(address _to) internal {
        for (uint256 i = 0; i < maxTotalSupply; i++) {
            _safeMint(_to, i);
        }
    }

    function _safeMint(address _to, uint256 _tokenId) internal override {
        require(
            _tokenId <= maxTotalSupply,
            "Token: mint would exceed max total supply"
        );
        _mint(_to, _tokenId);
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @param tokenId The identifier for an NFT
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        //ownerOf(tokenId) will revert if owner is 0x0, hence the try catch
        try this.ownerOf(tokenId) returns (address) {
            return
                string(
                    abi.encodePacked(
                        baseTokenURI,
                        "/",
                        Strings.toString(tokenId)
                    )
                );
        } catch {
            revert("URI query for nonexistent token");
        }
    }

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    /// @param tokenId The identifier for an NFT
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Burn: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, "ERC2981Royalties: Too high");
        _royaltiesRecipient = recipient;
        _royaltiesValue = value;
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltiesRecipient, (value * _royaltiesValue) / 10000);
    }

    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            interfaceId == type(IERC165).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}