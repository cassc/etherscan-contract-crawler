// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.10 <0.9.0;

import "./IMoonbirds.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721ACommon.sol";
import "@divergencetech/ethier/contracts/erc721/BaseTokenURI.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
@title Moonbirds Oddities
@author divergence.xyz
 */
contract Oddities is
    ERC721ACommon,
    AccessControlEnumerable,
    BaseTokenURI,
    ERC2981
{
    /**
    @dev The Moonbirds ERC721 contract.
     */
    IMoonbirds public immutable moonbirds;

    /**
    @dev Recipient of a Moonbird's Oddity if not nested.
     */
    address public treasury;

    constructor(IMoonbirds _moonbirds, address _treasury)
        ERC721ACommon("Moonbirds Oddities", "ODDITIES")
        BaseTokenURI("")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        moonbirds = _moonbirds;
        treasury = _treasury;
        _setDefaultRoyalty(0xc8A5592031f93dEbeA5D9e67a396944Ee01BB2ca, 500);
    }

    /**
    @notice Sets the treasury address.
     */
    function setTreasury(address _treasury)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        treasury = _treasury;
    }

    uint256 private constant MAX_TOKENS = 10_000;

    /**
    @notice Airdrops the next `n` Oddities tokens based on the nesting status as
    read from the Moonbirds contract. Unnested Moonbirds are inelligible, and
    the Oddity is minted to the treasury.
     */
    function drop(uint256 n) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 tokenId = totalSupply();
        uint256 end = Math.min(tokenId + n, MAX_TOKENS);

        IMoonbirds mb = moonbirds;
        address backup = treasury;
        for (; tokenId < end; ++tokenId) {
            (bool nested, , ) = mb.nestingPeriod(tokenId);
            // We already know that the address is aware of ERC721, so no need
            // to waste gas on a safe mint. This also stops grieving.
            _mint(nested ? mb.ownerOf(tokenId) : backup, 1, "", false);
        }
    }

    /**
    @notice An alternative mechanism to achieve the drop() functionality, most
    likely not to be used.
    @dev A Heisenbug in testing would, rarely, result in drop() reverting at
    seemingly random calls to mb.ownerOf(). This was most likely due to an error
    in the Moonbirds test-double as it cleared when modified to be a stub
    instead of a fake, but dropTo() exists as a bailout in case we've minted
    the majority of supply with drop() and it then fails. The addresses will be
    computed in the same way, but off-chain, and can still be verified.
     */
    function dropTo(address[] memory recipients)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 n = recipients.length;
        require(totalSupply() + n <= MAX_TOKENS, "Oddities: supply exhausted");

        for (uint256 i = 0; i < n; ++i) {
            _mint(recipients[i], 1, "", false);
        }
    }

    /**
    @notice Sets the default ERC2981 royalty values.
     */
    function setDefaultRoyalty(address receiver, uint96 numerator)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ERC2981._setDefaultRoyalty(receiver, numerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721ACommon, ERC2981, AccessControlEnumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        override(BaseTokenURI, ERC721A)
        returns (string memory)
    {
        return BaseTokenURI._baseURI();
    }
}