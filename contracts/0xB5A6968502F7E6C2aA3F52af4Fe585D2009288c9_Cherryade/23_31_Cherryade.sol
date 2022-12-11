// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import "./ERC721Base.sol";
import "./Pandimensionals.sol";
import 'erc721a-upgradeable/contracts/ERC721AUpgradeable.sol';

/** -----------------------------
*   This contract was developed by DanTheDev(at)protonmail.com
*   If you have questions, (constructive) feedback or need a smart contract developer, please get in touch
*   -----------------------------
*/
contract Cherryade is ERC721Base {

    // Custom Errors
    error AlreadyMinted();
    error MintingDeactivated();
    error Unauthorized();

    // VARIABLES
    bool public mintingActivated;
    address public pandimensionalsAddress;
    mapping(address => uint256) public publicMinted;

    // FUNCTIONS
    function __Cherryade_init(address _pandimensionals) external initializer {
        __ERC721Base_init(
            "Cherryade",                                          // name
            "CHE",                                                // symbol
            "https://pandimensionals.mypinata.cloud/ipfs/QmXoTFrzr7WMAkG3TF1stS8LugCATLGk4GHRJ6y7V6EWAx",   // base URI                                      // initialBaseURI
            "https://pandimensionals.mypinata.cloud/ipfs/QmVpByHhKHZpr2RscbEkWcfiaC1WPmxRfxoaTsYQvUDYMg",                                                // contractURI NEW
            0,                                                    // initial token (mint) price
            0,                                                    // team reserve
            460                                                  // maxTotalSupply
        );
        pandimensionalsAddress = _pandimensionals;
        owner = address(0xE0A67B78555827b3758531c1Ff938199a3512F15);
        _setupRole(DEFAULT_ADMIN_ROLE,owner);
        // _setupRole(DEFAULT_ADMIN_ROLE,_msgSender());
        _setupRole(MANAGE_COLLECTION_ROLE, owner);
        // _setupRole(MANAGE_COLLECTION_ROLE, _msgSender());
        _setupRole(MANAGE_UPGRADES_ROLE, owner);
        // _setupRole(MANAGE_UPGRADES_ROLE, _msgSender());
        _setupRole(PAUSABILITY_ROLE, owner);
        // _setupRole(PAUSABILITY_ROLE, _msgSender());
        mintingActivated = true;
    }

    function mint(uint256 tokenId) public whenNotPaused nonReentrant {
        // ensure that minting is activated
        if (!mintingActivated) revert MintingDeactivated();

        // ensure that NFT was not minted already
        if (_exists(tokenId)) revert AlreadyMinted();

        // ensure that holder holds Pandimensionals NFT with same tokenId
        try IERC721Upgradeable(pandimensionalsAddress).ownerOf(tokenId) returns (address owner) {
            // check owner address
            if (owner != _msgSender()) revert Unauthorized();

            // mint
            _safeMint(_msgSender(), tokenId);
        } catch {
            revert Unauthorized();
        }
    }

    function mintBatch(uint256[] memory tokenIds) external {
        for(uint i = 0; i < tokenIds.length;) {
            mint(tokenIds[i]);
            ++i;
        }

    }

    function flipMintingStatus() external onlyRoleCustom(MANAGE_COLLECTION_ROLE) {
        mintingActivated = !mintingActivated;
    }
}