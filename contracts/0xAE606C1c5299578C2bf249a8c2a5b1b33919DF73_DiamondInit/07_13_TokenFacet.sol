// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { GlobalState } from "../libraries/GlobalState.sol";

import "erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library TokenFacetLib {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("tokenfacet.storage");

    struct state {
        address ash;
        address authorisedSigner;
        string description;
        string imageUrl;
        string animUrlPrefix;
        bool publicMintEnabled;
        mapping(uint256 => uint8) editions;
    }

    /**
    * @dev Return stored state struct.
    */
    function getState() internal pure returns (state storage _state) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            _state.slot := position
        }
    }
}

interface IASH {
    function balanceOf(address account) external view returns (uint);
}

contract TokenFacet is ERC721AUpgradeable {
    using ECDSA for bytes;
    using ECDSA for bytes32;

    modifier restrict {
        GlobalState.requireCallerIsAdmin();
        _;
    }

    // ADMIN FUNCTIONS //

    function setDescription(string memory d) external restrict {
        TokenFacetLib.getState().description = d;
    }

    function setImageUrl(string memory url) external restrict {
        TokenFacetLib.getState().imageUrl = url;
    }

    function setAnimUrlPrefix(string memory url) external restrict {
        TokenFacetLib.getState().animUrlPrefix = url;
    }

    function setPublicMintStatus(bool s) external restrict {
        TokenFacetLib.getState().publicMintEnabled = s;
    }

    function setAshAddress(address a) external restrict {
        TokenFacetLib.getState().ash = a;
    }

    function setAuthorisedSigner(address a) external restrict {
        TokenFacetLib.getState().authorisedSigner = a;
    }

    function reserve(uint amount, bool edition) external restrict {
        if (edition) TokenFacetLib.getState().editions[_nextTokenId()] = 1;
        _mint(msg.sender, amount);
    }

    // PUBLIC FUNCTIONS //

    function editionMint(bytes memory signature) external {
        TokenFacetLib.state storage s = TokenFacetLib.getState();

        require(
            abi.encodePacked(msg.sender)
            .toEthSignedMessageHash()
            .recover(signature) == s.authorisedSigner,
            "TokenFacet: invalid signature"
        );
        require(
            _numberMinted(msg.sender) == 0,
            "TokenFacet: this address has already minted"
        );

        s.editions[_nextTokenId()] = 1;
        _mint(msg.sender, 1);
    }

    function publicMint() external {
        TokenFacetLib.state storage s = TokenFacetLib.getState();

        require(
            s.publicMintEnabled,
            "TokenFacet: public minting is not available now"
        );
        require(
            _numberMinted(msg.sender) == 0,
            "TokenFacet: this address has already minted"
        );
        _mint(msg.sender, 1);
    }

    function burn(uint tokenId) external {
        _burn(tokenId, true);
    }

    // METADATA FUNCTIONS //

    function tokenURI(uint tokenId) public view override returns (string memory) {
        TokenFacetLib.state storage s = TokenFacetLib.getState();

        uint ashBalance = IASH(s.ash).balanceOf(ownerOf(tokenId));
        string memory edition = _toString(s.editions[tokenId]);

        string memory name = s.editions[tokenId] == 1 ? "Collectors Edition" : "Public Edition";
        string memory imageUrl = string.concat(
            s.imageUrl,
            edition,
            ".gif"
        );
        string memory animUrl = string.concat(
            s.animUrlPrefix,
            "?balance=",
            _toString(ashBalance),
            "&edition=",
            edition
        );

        return string(
            abi.encodePacked(
                'data:application/json;utf8,',
                '{"name": "AshVault | ', name, '",',
                '"created_by": "ktrby",',
                '"description": "', s.description, '",',
                '"image": "', imageUrl , '",',
                '"image_url": "', imageUrl , '",',
                '"animation": "', animUrl, '",',
                '"animation_url": "', animUrl, '"',
                '}'
            )
        );
    }
}