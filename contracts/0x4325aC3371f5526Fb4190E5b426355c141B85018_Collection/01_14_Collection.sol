// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./utils/Base64.sol";
import "./utils/MerkleProof.sol";

import "./CollectionDescriptor.sol";

/*
___________.__             __________                                _____                             
\__    ___/|  |__   ____   \______   \ ____   ____   _____     _____/ ____\                            
  |    |   |  |  \_/ __ \   |       _//  _ \ /  _ \ /     \   /  _ \   __\                             
  |    |   |   Y  \  ___/   |    |   (  <_> |  <_> )  Y Y  \ (  <_> )  |                               
  |____|   |___|  /\___  >  |____|_  /\____/ \____/|__|_|  /  \____/|__|                               
                \/     \/          \/                    \/                                            
.___        _____.__       .__  __           __________        .__        __  .__                      
|   | _____/ ____\__| ____ |__|/  |_  ____   \______   \_____  |__| _____/  |_|__| ____    ____  ______
|   |/    \   __\|  |/    \|  \   __\/ __ \   |     ___/\__  \ |  |/    \   __\  |/    \  / ___\/  ___/
|   |   |  \  |  |  |   |  \  ||  | \  ___/   |    |     / __ \|  |   |  \  | |  |   |  \/ /_/  >___ \ 
|___|___|  /__|  |__|___|  /__||__|  \___  >  |____|    (____  /__|___|  /__| |__|___|  /\___  /____  >
         \/              \/              \/                  \/        \/             \//_____/     \/ 

Lost in the simulation, a painter spent the rest of their infinite life, painting the feeling of their infinite room.
No one knows how far it goes, but apparently, it is infinite.
What is known, however is that over time, the painter resorted to increasing minimalism.
Up to the 1 million mints, the odds of increasingly painting with more minimal features becomes possible.

CC0 On-Chain SVG Generative Art.
Untitled Frontier Project by @simondlr (Simon de la Rouviere).
Logged Universe Season 1 Interlude Art.
Free to mint. Infinite Supply.
*/


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Collection is ERC721 {

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for opensea integration. doesn't do anything else.

    CollectionDescriptor public descriptor;

    mapping (uint256 => bytes) public hashes;
    uint256 public totalSupply = 0;

    // todo: for testing
    // uint256 public newlyMinted;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        descriptor = new CollectionDescriptor();

        // mint #1 to UF to kickstart it
        _createNFT(owner);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        bytes memory hash = hashes[tokenId];

        string memory name = descriptor.generateName(tokenId); 
        string memory description = "The Room of Infinite Paintings: a simulated mind's infinite attempt for meaning.";

        string memory image = generateBase64Image(hash, tokenId);
        string memory attributes = generateTraits(hash, tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(hash, tokenId));
        return Base64.encode(img);
    }

    function generateImageFromTokenID(uint256 tokenId) public view returns (string memory) {
        bytes memory hash = hashes[tokenId];
        return descriptor.generateImage(hash, tokenId);
    }

    function generateImage(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(hash, tokenId);
    }

    function generateTraits(bytes memory hash, uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(hash, tokenId);
    }

    function mint() public {
        _mint(msg.sender);
    }

    // internal mint (not necessary, but keeping it for vestigial reasons based on the template used)
    function _mint(address _owner) internal {
        _createNFT(_owner);
    }

    function _createNFT(address _owner) internal {
        totalSupply+=1;
        bytes memory hash = abi.encodePacked(keccak256(abi.encodePacked(totalSupply, block.timestamp, _owner))); 
        hashes[totalSupply] = hash;
        super._mint(_owner, totalSupply);

        // newlyMinted = totalSupply;
    }
}