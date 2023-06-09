pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/interfaces/IERC721.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./AnonymiceLibrary.sol";
import "./OriginalAnonymiceInterface.sol";

//
//  ╔═╗┌┐┌┌─┐┌┐┌┬ ┬┌┬┐┬┌─┐┌─┐  ╔═╗┬ ┬┌─┐┌─┐┌─┐┌─┐  ╔═╗┬  ┬ ┬┌┐
//  ╠═╣││││ ││││└┬┘│││││  ├┤   ║  ├─┤├┤ ├┤ └─┐├┤   ║  │  │ │├┴┐
//  ╩ ╩┘└┘└─┘┘└┘ ┴ ┴ ┴┴└─┘└─┘  ╚═╝┴ ┴└─┘└─┘└─┘└─┘  ╚═╝┴─┘└─┘└─┘
//
//  Own Burned Anonymice and create an exclusive Cheese Club!
//  Minting dApp on anonymicecheese.club
//
//  We know other projects tried to do this before and failed. So we fixed all their issues and
//  we're ready to let you own those mice.
//  Cheese club will be the heart of those 6,450 burned mice.
//

contract AnonymiceCheeseClub is ERC721Enumerable, Ownable {

    using AnonymiceLibrary for uint8;

    //Mappings
    uint16[6450] internal tokenToOriginalMiceId;
    uint256 internal nextOriginalMiceToLoad = 0;
    OriginalAnonymiceInterface.Trait[] internal burnedTraitType;

    //uint256s
    uint256 MAX_SUPPLY = 6450;
    uint256 FREE_MINTS = 500;
    uint256 PRICE = .02 ether;

    //addresses
    address anonymiceContract = 0xbad6186E92002E312078b5a1dAfd5ddf63d3f731;

    //string arrays
    string[] LETTERS = [ "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"
    ];

    //events
    event TokenMinted(uint256 supply);

    constructor() ERC721("Anonymice Cheese Club", "MICE-CHEESE-CLUB") {
    }

    //  ███╗   ███╗██╗███╗   ██╗████████╗██╗███╗   ██╗ ██████╗
    //  ████╗ ████║██║████╗  ██║╚══██╔══╝██║████╗  ██║██╔════╝
    //  ██╔████╔██║██║██╔██╗ ██║   ██║   ██║██╔██╗ ██║██║  ███╗
    //  ██║╚██╔╝██║██║██║╚██╗██║   ██║   ██║██║╚██╗██║██║   ██║
    //  ██║ ╚═╝ ██║██║██║ ╚████║   ██║   ██║██║ ╚████║╚██████╔╝
    //  ╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚═╝╚═╝  ╚═══╝ ╚═════╝

    /**
     * @dev Loads the IDs of burned mices
     * @param _howMany The number of mices to load. Starts from the last loaded
     */
    function _loadOriginalMices(uint256 _howMany) internal {
        require(nextOriginalMiceToLoad <= MAX_SUPPLY, "All possible mices loaded");
        ERC721Enumerable originalMiceCollection = ERC721Enumerable(anonymiceContract);
        uint start = nextOriginalMiceToLoad;
        for (uint i=start; (i<start+_howMany && i<MAX_SUPPLY); i++) {
            uint id = originalMiceCollection.tokenOfOwnerByIndex(0x000000000000000000000000000000000000dEaD, i);
            tokenToOriginalMiceId[i] = uint16(id);
        }
        nextOriginalMiceToLoad = start + _howMany;
    }

    /**
     * @dev Mint internal, this is to avoid code duplication.
     */
    function mintInternal(uint256 num_tokens, address to) internal {
        uint256 _totalSupply = totalSupply();
        require(_totalSupply < MAX_SUPPLY, 'Sale would exceed max supply');

        require(!AnonymiceLibrary.isContract(msg.sender));

        if ((num_tokens + _totalSupply) > MAX_SUPPLY) {
            num_tokens = MAX_SUPPLY - _totalSupply;
        }

        _loadOriginalMices(num_tokens);
        for (uint i=0; i < num_tokens; i++) {
            _safeMint(to, _totalSupply);
            emit TokenMinted(_totalSupply);
            _totalSupply = _totalSupply + 1;
        }
    }

    /**
     * @dev Mints new tokens.
     */
    function mint(address _to, uint _count) public payable {
        uint _totalSupply = totalSupply();
        if (_totalSupply > FREE_MINTS) {
            require(PRICE*_count <= msg.value, 'Not enough ether sent (send 0.03 eth for each mice you want to mint)');
        }
        return mintInternal(_count, _to);
    }

    /**
     * @dev Kills the mice again, this time forever.
     * @param _tokenId The token to burn.
     */
    function killForever(uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender);
        //Burn token
        _transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            _tokenId
        );
    }

    //  ██████╗ ███████╗ █████╗ ██████╗
    //  ██╔══██╗██╔════╝██╔══██╗██╔══██╗
    //  ██████╔╝█████╗  ███████║██║  ██║
    //  ██╔══██╗██╔══╝  ██╔══██║██║  ██║
    //  ██║  ██║███████╗██║  ██║██████╔╝
    //  ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝


    /**
     * @dev Helper function to reduce pixel size within contract
     */
    function letterToNumber(string memory _inputLetter)
    internal
    view
    returns (uint8)
    {
        for (uint8 i = 0; i < LETTERS.length; i++) {
            if (
                keccak256(abi.encodePacked((LETTERS[i]))) ==
                keccak256(abi.encodePacked((_inputLetter)))
            ) return (i + 1);
        }
        revert();
    }

    /**
     * @dev Hash to SVG function
     */
    function hashToSVG(string memory _hash)
    public
    view
    returns (string memory)
    {
        string memory svgString;
        bool[24][24] memory placedPixels;
        OriginalAnonymiceInterface originalMiceCollection = OriginalAnonymiceInterface(anonymiceContract);

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );
            OriginalAnonymiceInterface.Trait memory trait;
            if (i == 0) {
                trait = OriginalAnonymiceInterface.Trait(
                    burnedTraitType[thisTraitIndex].traitName,
                    burnedTraitType[thisTraitIndex].traitType,
                    burnedTraitType[thisTraitIndex].pixels,
                    burnedTraitType[thisTraitIndex].pixelCount
                );
            } else {
                (string memory traitName, string memory traitType, string memory pixels, uint pixelCount) =
                    originalMiceCollection.traitTypes(i, thisTraitIndex);
                trait = OriginalAnonymiceInterface.Trait(
                    traitName,
                        traitType,
                        pixels,
                        pixelCount
                );
            }

            for (
                uint16 j = 0;
                j < trait.pixelCount;
                j++
            ) {
                string memory thisPixel = AnonymiceLibrary.substring(
                    trait.pixels,
                    j * 4,
                    j * 4 + 4
                );

                uint8 x = letterToNumber(
                    AnonymiceLibrary.substring(thisPixel, 0, 1)
                );
                uint8 y = letterToNumber(
                    AnonymiceLibrary.substring(thisPixel, 1, 2)
                );

                if (placedPixels[x][y]) continue;

                svgString = string(
                    abi.encodePacked(
                        svgString,
                        "<rect class='c",
                        AnonymiceLibrary.substring(thisPixel, 2, 4),
                        "' x='",
                        x.toString(),
                        "' y='",
                        y.toString(),
                        "'/>"
                    )
                );

                placedPixels[x][y] = true;
            }
        }

        svgString = string(
            abi.encodePacked(
                '<svg id="mouse-svg" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 24 24"> ',
                svgString,
                "<style>rect{width:1px;height:1px;} #mouse-svg{shape-rendering: crispedges;} .c00{fill:#000000}.c01{fill:#B1ADAC}.c02{fill:#D7D7D7}.c03{fill:#FFA6A6}.c04{fill:#FFD4D5}.c05{fill:#B9AD95}.c06{fill:#E2D6BE}.c07{fill:#7F625A}.c08{fill:#A58F82}.c09{fill:#4B1E0B}.c10{fill:#6D2C10}.c11{fill:#D8D8D8}.c12{fill:#F5F5F5}.c13{fill:#433D4B}.c14{fill:#8D949C}.c15{fill:#05FF00}.c16{fill:#01C700}.c17{fill:#0B8F08}.c18{fill:#421C13}.c19{fill:#6B392A}.c20{fill:#A35E40}.c21{fill:#DCBD91}.c22{fill:#777777}.c23{fill:#848484}.c24{fill:#ABABAB}.c25{fill:#BABABA}.c26{fill:#C7C7C7}.c27{fill:#EAEAEA}.c28{fill:#0C76AA}.c29{fill:#0E97DB}.c30{fill:#10A4EC}.c31{fill:#13B0FF}.c32{fill:#2EB9FE}.c33{fill:#54CCFF}.c34{fill:#50C0F2}.c35{fill:#54CCFF}.c36{fill:#72DAFF}.c37{fill:#B6EAFF}.c38{fill:#FFFFFF}.c39{fill:#954546}.c40{fill:#0B87F7}.c41{fill:#FF2626}.c42{fill:#180F02}.c43{fill:#2B2319}.c44{fill:#FBDD4B}.c45{fill:#F5B923}.c46{fill:#CC8A18}.c47{fill:#3C2203}.c48{fill:#53320B}.c49{fill:#7B501D}.c50{fill:#FFE646}.c51{fill:#FFD627}.c52{fill:#F5B700}.c53{fill:#242424}.c54{fill:#4A4A4A}.c55{fill:#676767}.c56{fill:#F08306}.c57{fill:#FCA30E}.c58{fill:#FEBC0E}.c59{fill:#FBEC1C}.c60{fill:#14242F}.c61{fill:#B06837}.c62{fill:#8F4B0E}.c63{fill:#D88227}.c64{fill:#B06837}.c65{fill:#FFEB3B}.c66{fill:#FFC107}</style></svg>"
            )
        );

        return svgString;
    }

    /**
     * @dev Hash to metadata function
     */
    function hashToMetadata(string memory _hash, uint _tokenId)
    public
    view
    returns (string memory)
    {
        string memory metadataString;
        OriginalAnonymiceInterface originalMiceCollection = OriginalAnonymiceInterface(anonymiceContract);

        for (uint8 i = 0; i < 9; i++) {
            uint8 thisTraitIndex = AnonymiceLibrary.parseInt(
                AnonymiceLibrary.substring(_hash, i, i + 1)
            );

            OriginalAnonymiceInterface.Trait memory trait;
            if (i == 0) {
                trait = OriginalAnonymiceInterface.Trait(
                    burnedTraitType[thisTraitIndex].traitName,
                    burnedTraitType[thisTraitIndex].traitType,
                    burnedTraitType[thisTraitIndex].pixels,
                    burnedTraitType[thisTraitIndex].pixelCount
                );
            } else {
                (string memory traitName, string memory traitType, string memory pixels, uint pixelCount) =
                originalMiceCollection.traitTypes(i, thisTraitIndex);
                trait = OriginalAnonymiceInterface.Trait(
                    traitName,
                    traitType,
                    pixels,
                    pixelCount
                );
            }

            metadataString = string(
                abi.encodePacked(
                    metadataString,
                    '{"trait_type":"',
                        trait.traitType,
                    '","value":"',
                        trait.traitName,
                    '"}'
                )
            );

            if (i != 8)
                metadataString = string(abi.encodePacked(metadataString, ","));
        }

        // add the property of original token id number
        metadataString = string(
            abi.encodePacked(
                metadataString,
                ',{"trait_type":"',
                'Original Mice Token Id',
                '","value":"',
                AnonymiceLibrary.toString(tokenToOriginalMiceId[_tokenId]),
                '"}'
            )
        );

        return string(abi.encodePacked("[", metadataString, "]"));
    }

    /**
     * @dev Returns the SVG and metadata for a token Id
     * @param _tokenId The tokenId to return the SVG and metadata for.
     */
    function tokenURI(uint256 _tokenId)
    public
    view
    override
    returns (string memory)
    {
        require(_exists(_tokenId));

        string memory tokenHash = _tokenIdToHash(_tokenId);

        return
        string(
            abi.encodePacked(
                "data:application/json;base64,",
                AnonymiceLibrary.encode(
                    bytes(
                        string(
                            abi.encodePacked(
                                '{"name": "Anonymice #',
                                AnonymiceLibrary.toString(_tokenId),
                                '", "description": "Anonymice Cheese Club is a collection of 6,450 mice burned in the original Anonymice collection. They preserve the same traits of the burned ones, with metadata and images generated and stored 100% on-chain. No IPFS, no API. Just the Ethereum blockchain.", "image": "data:image/svg+xml;base64,',
                                AnonymiceLibrary.encode(
                                    bytes(hashToSVG(tokenHash))
                                ),
                                '","attributes":',
                                hashToMetadata(tokenHash, _tokenId),
                                "}"
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev Returns a hash for a given tokenId
     * @param _tokenId The tokenId to return the hash for.
     */
    function _tokenIdToHash(uint256 _tokenId)
    public
    view
    returns (string memory)
    {
        OriginalAnonymiceInterface originalMiceCollection = OriginalAnonymiceInterface(anonymiceContract);
        string memory tokenHash = originalMiceCollection._tokenIdToHash(uint256(tokenToOriginalMiceId[_tokenId]));
        //If this is a burned token, override the previous hash
        if (ownerOf(_tokenId) == 0x000000000000000000000000000000000000dEaD) {
            tokenHash = string(
                abi.encodePacked(
                    "1",
                    AnonymiceLibrary.substring(tokenHash, 1, 9)
                )
            );
        } else {
            tokenHash = string(
                abi.encodePacked(
                    "0",
                    AnonymiceLibrary.substring(tokenHash, 1, 9)
                )
            );
        }

        return tokenHash;
    }

    /**
     * @dev Returns the wallet of a given wallet. Mainly for ease for frontend devs.
     * @param _wallet The wallet to get the tokens of.
     */
    function walletOfOwner(address _wallet)
    public
    view
    returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_wallet);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_wallet, i);
        }
        return tokensId;
    }


//   ██████╗ ██╗    ██╗███╗   ██╗███████╗██████╗
//  ██╔═══██╗██║    ██║████╗  ██║██╔════╝██╔══██╗
//  ██║   ██║██║ █╗ ██║██╔██╗ ██║█████╗  ██████╔╝
//  ██║   ██║██║███╗██║██║╚██╗██║██╔══╝  ██╔══██╗
//  ╚██████╔╝╚███╔███╔╝██║ ╚████║███████╗██║  ██║
//   ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝


    /**
     * @dev Clears the traits.
     */
    function clearBurnedTraits() public onlyOwner {
        for (uint256 i = 0; i < burnedTraitType.length; i++) {
            delete burnedTraitType[i];
        }
    }

    /**
     * @dev Add trait types of burned
     * @param traits Array of traits to add
     */

    function addBurnedTraitType(OriginalAnonymiceInterface.Trait[] memory traits)
    public
    onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            burnedTraitType.push(
                OriginalAnonymiceInterface.Trait(
                    traits[i].traitName,
                    traits[i].traitType,
                    traits[i].pixels,
                    traits[i].pixelCount
                )
            );
        }

        return;
    }

    /**
     * @dev Collects the total amount in the contract
     */
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

}