// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {ERC1155} from "@thirdweb-dev/contracts/eip/ERC1155.sol";

import "@thirdweb-dev/contracts/extension/Ownable.sol";
import "@thirdweb-dev/contracts/extension/BatchMintMetadata.sol";
import "@thirdweb-dev/contracts/extension/LazyMint.sol";

import "@thirdweb-dev/contracts/lib/TWStrings.sol";
import "@thirdweb-dev/contracts/openzeppelin-presets/security/ReentrancyGuard.sol";
/**
 *                                WWWWWWWWW                  WNNNW
 *                         WNXK0OkkxxxxxxkkOO0XNW          N0xdddx0N
 *                     WNX0kxoooooooooooooooooodkOKNW     NOoooooookN
 *                   WXOxooooooooooooooooooooooooooxOXW   NkoooooooxX
 *                 WXkdoooooooooooooooooooooooooooooookKW WKxoooooxKW
 *                NOdoooooooooooooooooooooooooooooooooodK   NX000KN
 *              WKxoooooooooooooooooooodkOOOxooooooooodKW
 *             WKdoooooooooooooooooooxOKW  WNOdooooooxXW
 *             Kxoooooooooooooooooood0WW     WKxooookX      W
 *            NkoooooooooooddxdoooooON         NOooON     WKOX
 *           W0dooooooooodOXNNXOdooxX           WKKW     WKdoOW
 *           WOoooooooood0W    WXkxKW                   N0dooxN
 *           NkoooooooookN       WNW      NKX          NkooooxX
 *           NkooooooooxX                WOoxKW      WXxoooooxX
 *           WOoooooooo0W               WKdoodON    WKxooooookN
 *            XdooooookN     WXN        Xxooooox0KKKkdooooooo0W
 *            WOooooodKW    W0dkXW     NOoooooooooooooooooookN
 *             NkooooOW     XxoodOKXX00koooooooooooooooooooxXW
 *              XkoooOW    NOoooooodooooooooooooooooooooooxKW
 *               NOdodOKXXKkdooooooooooooooooooooooooooookXW
 *                WKkoooddooooooooooooooooooooooooooooox0N
 *                  WKkdooooooooooooooooooooooooooooox0NW
 *                    WXOxdoooooooooooooooooooooooxOKN
 *                       WXKOkxdooooooooooooddxO0XN
 *                           WNXKK00OOOO000KXNW
 *                                WWWWWWWWW
 *
 *      BASE:      ERC1155Base
 *      EXTENSION: LazyMint
 *
 *  The `MFGACHA` smart contract implements the ERC1155 NFT standard.
 *  It includes the following additions to standard ERC1155 logic:
 *
 *      - Lazy minting
 *
 *      - Ability to mint NFTs via the provided `mintTo` and `batchMintTo` functions.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *
 *  The `MFGACHA` contract uses the `LazyMint` extension.
 *
 *  'Lazy minting' means defining the metadata of NFTs without minting it to an address. Regular 'minting'
 *  of  NFTs means actually assigning an owner to an NFT.
 *
 *  As a contract admin, this lets you prepare the metadata for NFTs that will be minted by an external party,
 *  without paying the gas cost for actually minting the NFTs.
 *
 */

contract MFGACHA is
    ERC1155,
    Ownable,
    BatchMintMetadata,
    LazyMint,
    ReentrancyGuard
{
    using TWStrings for uint256;

    /// @notice The end time(unix timestamp) of the claim duration
    uint256 public claimEndTimestamp;

    /*//////////////////////////////////////////////////////////////
                        Mappings
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the total supply of NFTs of a given tokenId
     *  @dev Mapping from tokenId => total circulating supply of NFTs of that tokenId.
     */
    mapping(uint256 => uint256) public totalSupply;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _claimEndTimestamp
    ) ERC1155(_name, _symbol) {
        _setupOwner(msg.sender);
        claimEndTimestamp = _claimEndTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                    Overriden metadata logic
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the metadata URI for the given tokenId.
    function uri(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        string memory batchUri = _getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    /*//////////////////////////////////////////////////////////////
                            CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when tokens are claimed
    event TokensClaimed(
        address indexed claimer,
        uint256 indexed tokenId,
        uint256 quantityClaimed
    );

    /**
     *  @dev             The logic in `verifyClaim` determines whether the caller is authorized to mint NFTs.
     *                   The logic in `transferTokensOnClaim` does actual minting of tokens,
     *                   can also be used to apply other state changes.
     *
     *  @param _tokenId   The tokenId of the lazy minted NFT to mint.
     */
    function _claim(uint256 _tokenId) internal {
        verifyClaim(_tokenId); // Add your claim verification logic by overriding this function.

        _mint(msg.sender, _tokenId, 1, "");
        emit TokensClaimed(msg.sender, _tokenId, 1);
    }

    /**
     *  @notice          Lets an address claim multiple lazy minted NFTs at once to a recipient.
     *                   This function prevents any reentrant calls, and is not allowed to be overridden.
     *
     *                   Contract creators should override `verifyClaim` and `transferTokensOnClaim`
     *                   functions to create custom logic for verification and claiming,
     *                   for e.g. price collection, allowlist, max quantity, etc.
     *
     *  @param _tokenId   The tokenId of the lazy minted NFT to mint.
     */
    function claim(uint256 _tokenId) public nonReentrant {
        _claim(_tokenId);
    }

    /**
     *  @notice          Let's try if you can't get the NFT you want.
     */
    function claimAll() public nonReentrant {
        for (uint256 tokenId = 0; tokenId < nextTokenIdToMint(); tokenId++) {
            _claim(tokenId);
        }
    }

    /**
     *  @notice          Override this function to add logic for claim verification, based on conditions
     *                   such as allowlist, price, max quantity etc.
     *
     *  @dev             Checks a request to claim NFTs against a custom condition.
     *
     *  @param _tokenId   The tokenId of the lazy minted NFT to mint.
     */
    function verifyClaim(uint256 _tokenId) public view {
        require(_tokenId < nextTokenIdToMint(), "invalid id");
        require(
            block.timestamp < claimEndTimestamp,
            "The claimable period has ended."
        );
    }

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenId.
     *
     *  @param _owner   The owner of the NFT to burn.
     *  @param _tokenId The tokenId of the NFT to burn.
     *  @param _amount  The amount of the NFT to burn.
     */
    function burn(
        address _owner,
        uint256 _tokenId,
        uint256 _amount
    ) external virtual {
        address caller = msg.sender;

        require(
            caller == _owner || isApprovedForAll[_owner][caller],
            "Unapproved caller"
        );
        require(
            balanceOf[_owner][_tokenId] >= _amount,
            "Not enough tokens owned"
        );

        _burn(_owner, _tokenId, _amount);
    }

    /**
     *  @notice         Lets an owner or approved operator burn NFTs of the given tokenIds.
     *
     *  @param _owner    The owner of the NFTs to burn.
     *  @param _tokenIds The tokenIds of the NFTs to burn.
     *  @param _amounts  The amounts of the NFTs to burn.
     */
    function burnBatch(
        address _owner,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    ) external virtual {
        address caller = msg.sender;

        require(
            caller == _owner || isApprovedForAll[_owner][caller],
            "Unapproved caller"
        );
        require(_tokenIds.length == _amounts.length, "Length mismatch");

        for (uint256 i = 0; i < _tokenIds.length; i += 1) {
            require(
                balanceOf[_owner][_tokenIds[i]] >= _amounts[i],
                "Not enough tokens owned"
            );
        }

        _burnBatch(_owner, _tokenIds, _amounts);
    }

    /**
     *  @notice             For owner to update claimEndTimestamp.
     *
     *  @param _timestamp   The end time(unix timestamp) of the claim duration.
     */
    function setClaimEndTimestamp(uint256 _timestamp) external onlyOwner {
        claimEndTimestamp = _timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                            View functions
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be lazy minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return nextTokenIdToLazyMint;
    }

    /*//////////////////////////////////////////////////////////////
                        Internal functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether lazy minting can be done in the given execution context.
    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual override returns (bool) {
        return msg.sender == owner();
    }

    /// @dev Runs before every token transfer / mint / burn.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}