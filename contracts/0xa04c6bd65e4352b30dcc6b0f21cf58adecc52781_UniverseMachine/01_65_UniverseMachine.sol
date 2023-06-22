// SPDX-License-Identifier: UNLICENSED
/* Copyright (c) Joshua Davis. All rights reserved. */

pragma solidity ^0.8.13;

import "@divergencetech/ethier/contracts/crypto/SignatureChecker.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Common.sol";
import "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import "@divergencetech/ethier/contracts/sales/ArbitraryPriceSeller.sol";
import "@divergencetech/ethier/contracts/utils/Monotonic.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

import "../Base64.sol";
import "./Parameters.sol";
import "./IUniverseMachineParameters.sol";
import "./IUniverseMachineRenderer.sol";
import "./IPublicMintable.sol";

/*
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                        //
//                                                                                                        //
//                                            ,,╓╓╥╥╥╥╥╥╥╥╖╓,                                             //
//                                      ╓╥H╢▒░░▄▄▄▄██████▄▄▄▄░░▒▒H╖,                                      //
//                                 ,╓H▒░░▄████████████████████████▄░░▒H╖                                  //
//                              ╓╥▒░▄██████████████████████████████████▄░▒b,                              //
//                           ╓║▒░▄████████████████████████████████████████▄░▒H╓                           //
//                        ╓╥▒░▄██████████████████████████████████████████████▄░▒╥,                        //
//                      ╓╢░▄████▓███████████████████████████████████████████████▄░▒╖                      //
//                    ╥▒░████▓████████████████████████████████████████████████████▄░▒╖                    //
//                  ╥▒░████▓█████████████████████████████████████████████████████████░▒╖                  //
//                ╥▒░████▓████████████████████████████████████████████████████████▓████░▒╖                //
//              ╓▒░█████▓███████████████████████████████████████████████████████████▓████░▒╖              //
//            ,║▒▄████▓███████████████████░'▀██████████████████░]█████████████████████▓███▄▒▒             //
//           ╓▒░█████▓████████████████████▒  ░███████████████▀   ███████████████████████▓███░▒╖           //
//          ╥▒▄█████▓█████████████████████░    └▀▀▀▀▀▀▀▀██▀░    ;████████████████████████▓███▄▒╥          //
//         ╢▒██████▓██████████████████████▌,                    ░█████████████████████████████▌▒▒         //
//        ▒▒██████▓████████████████████████▌     ,, ,╓, ,,     ¿████████████████████████████████▒▒        //
//       ╢▒██████▓█████████████████████████▌    ▒██▒█░█░██░   .█████████████████████████████▓███▌▒▒       //
//      ]▒▐█████▓███████████████████████████▒       ░▀▀        ██████████████████████████████████░▒┐      //
//      ▒░██████▓███████████████████████████                   ▐█████████████████████████████▓████▒▒      //
//     ]▒▐█████▓███████████████████████████░                   ░█████████████████████████████▓████░▒L     //
//     ▒▒██████▓██████████████████████████▌                     ░████████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████░                      ▐███████████████████████████▓█████▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ░███████████████████████████▓████▌▒▒     //
//     ▒▒█████▓███████████████████████████▒                      ▒██████████████████████████▓█████▌▒[     //
//     ]▒░████▓███████████████████████████░                      ▐██████████████████████████▓█████░▒      //
//      ▒▒████▓███████████████████████████▌                      ▐█████████████████████████▓█████▌▒▒      //
//      ╙▒░████▓██████████████████████████▌                      ▐███████████████████████████████░▒       //
//       ╙▒░███▓███████████████████████████░                    ░███████████████████████████████░▒`       //
//        ╙▒░███▓██████████████████████████▌                   ,█████████████████████████▓█████░▒╜        //
//         ╙▒░███▓██████████████████████████░                 ,▐████████████████████████▓█████░▒`         //
//          ╙▒░███▓███████████████████████████░             ;▄██████████████████████████████▀░▒           //
//            ╢▒▀███▓█████████████████████████▄█▌▄▄███▄▄▄,░▄▄▄███████████████████████▓█████░▒╜            //
//             ╙▒░▀███▓█████████████████████████████████████████████████████████████▓████▀░▒`             //
//               ╙▒░████▓█████████████████████████████████████████████████████████▓████▀░▒╜               //
//                 ╨▒░███████████████████████████████████████████████████████████▓███▀░▒╜                 //
//                   ╙▒░▀██████████████████████████████████████████████████████▓███▀░▒╜                   //
//                     ╙▒░▀█████████████████████████████████████████████████▓████▀░▒╜                     //
//                       `╨▒░▀████████████████████████████████████████████████▀▒░╨`                       //
//                          ╙▒░░▀██████████████████████████████████████████▀░░▒╜                          //
//                             ╙╣░░▀████████████████████████████████████▀▒░▒╜                             //
//                                ╙╨▒░░▀████████████████████████████▀░░▒╜`                                //
//                                    ╙╨╢▒░░▀▀███████████████▀▀▀▒░▒▒╜`                                    //
//                                         `╙╙╨╨▒▒░░░░░░░░▒▒╨╨╜"`                                         //
//                                                                                                        //
//       ▄▄▄██▀▀▀▒█████    ██████  ██░ ██  █    ██  ▄▄▄      ▓█████▄  ▄▄▄    ██▒   █▓ ██▓  ██████         //
//         ▒██  ▒██▒  ██▒▒██    ▒ ▓██░ ██▒ ██  ▓██▒▒████▄    ▒██▀ ██▌▒████▄ ▓██░   █▒▓██▒▒██    ▒         //
//         ░██  ▒██░  ██▒░ ▓██▄   ▒██▀▀██░▓██  ▒██░▒██  ▀█▄  ░██   █▌▒██  ▀█▄▓██  █▒░▒██▒░ ▓██▄           //
//      ▓██▄██▓ ▒██   ██░  ▒   ██▒░▓█ ░██ ▓▓█  ░██░░██▄▄▄▄██ ░▓█▄   ▌░██▄▄▄▄██▒██ █░░░██░  ▒   ██▒        //
//       ▓███▒  ░ ████▓▒░▒██████▒▒░▓█▒░██▓▒▒█████▓  ▓█   ▓██▒░▒████▓  ▓█   ▓██▒▒▀█░  ░██░▒██████▒▒        //
//       ▒▓▒▒░  ░ ▒░▒░▒░ ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░▒▓▒ ▒ ▒  ▒▒   ▓▒█░ ▒▒▓  ▒  ▒▒   ▓▒█░░ ▐░  ░▓  ▒ ▒▓▒ ▒ ░        //
//       ▒ ░▒░    ░ ▒ ▒░ ░ ░▒  ░ ░ ▒ ░▒░ ░░░▒░ ░ ░   ▒   ▒▒ ░ ░ ▒  ▒   ▒   ▒▒ ░░ ░░   ▒ ░░ ░▒  ░ ░        //
//       ░ ░ ░  ░ ░ ░ ▒  ░  ░  ░   ░  ░░ ░ ░░░ ░ ░   ░   ▒    ░ ░  ░   ░   ▒     ░░   ▒ ░░  ░  ░          //
//       ░   ░      ░ ░        ░   ░  ░  ░   ░           ░  ░   ░          ░  ░   ░   ░        ░          //
//                                                          ░                  ░                          //
//     ██▓███   ██▀███   ▄▄▄     ▓██   ██▓  ██████ ▄▄▄█████▓ ▄▄▄     ▄▄▄█████▓ ██▓ ▒█████   ███▄    █     //
//    ▓██░  ██▒▓██ ▒ ██▒▒████▄    ▒██  ██▒▒██    ▒ ▓  ██▒ ▓▒▒████▄   ▓  ██▒ ▓▒▓██▒▒██▒  ██▒ ██ ▀█   █     //
//    ▓██░ ██▓▒▓██ ░▄█ ▒▒██  ▀█▄   ▒██ ██░░ ▓██▄   ▒ ▓██░ ▒░▒██  ▀█▄ ▒ ▓██░ ▒░▒██▒▒██░  ██▒▓██  ▀█ ██▒    //
//    ▒██▄█▓▒ ▒▒██▀▀█▄  ░██▄▄▄▄██  ░ ▐██▓░  ▒   ██▒░ ▓██▓ ░ ░██▄▄▄▄██░ ▓██▓ ░ ░██░▒██   ██░▓██▒  ▐▌██▒    //
//    ▒██▒ ░  ░░██▓ ▒██▒ ▓█   ▓██▒ ░ ██▒▓░▒██████▒▒  ▒██▒ ░  ▓█   ▓██▒ ▒██▒ ░ ░██░░ ████▓▒░▒██░   ▓██░    //
//    ▒▓▒░ ░  ░░ ▒▓ ░▒▓░ ▒▒   ▓▒█░  ██▒▒▒ ▒ ▒▓▒ ▒ ░  ▒ ░░    ▒▒   ▓▒█░ ▒ ░░   ░▓  ░ ▒░▒░▒░ ░ ▒░   ▒ ▒     //
//    ░▒ ░       ░▒ ░ ▒░  ▒   ▒▒ ░▓██ ░▒░ ░ ░▒  ░ ░    ░      ▒   ▒▒ ░   ░     ▒ ░  ░ ▒ ▒░ ░ ░░   ░ ▒░    //
//    ░░         ░░   ░   ░   ▒   ▒ ▒ ░░  ░  ░  ░    ░        ░   ▒    ░       ▒ ░░ ░ ░ ▒     ░   ░ ░     //
//                ░           ░  ░░ ░           ░                 ░  ░         ░      ░ ░           ░     //
//                                                                                                        //
//                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

contract UniverseMachine is ERC721Common, ArbitraryPriceSeller, IPublicMintable, IERC2981 {

    bytes constant private JSON_URI_PREFIX = "data:application/json;base64,";   

    using EnumerableSet for EnumerableSet.AddressSet;
    using ERC165Checker for address;
    using ERC721Redeemer for ERC721Redeemer.Claims;
    using Monotonic for Monotonic.Increaser;
    using SignatureChecker for EnumerableSet.AddressSet;     
    
    /** @notice Contract responsible for rendering images from seeds. */
    IUniverseMachineRenderer public renderer;

    /**
    @notice Flag to disable use of setRenderer().
     */
    bool public rendererLocked = false;

    /**
    @notice Permanently sets the renderer-lock flag to true.
     */
    function lockRenderer() external onlyOwner {
        require(
            address(renderer).supportsInterface(
                type(IUniverseMachineRenderer).interfaceId
            ),
            "Not IUniverseMachineRenderer"
        );
        rendererLocked = true;
    }

    /**
    @notice Sets the address of the rendering contract.
    @dev No checks are performed when setting, but lockRenderer() ensures that
    the final address implements the IUniverseMachineRenderer interface.
     */
    function setRenderer(address _renderer) public onlyOwner {
        require(!rendererLocked, "Renderer locked");
        renderer = IUniverseMachineRenderer(_renderer);
    }

    /** @notice Contract responsible for creating metadata from seeds. */
    IUniverseMachineParameters public parameters;

    /**
    @notice Flag to disable use of setParameters().
     */
    bool public parametersLocked = false;

    /**
    @notice Permanently sets the parameters-lock flag to true.
     */
    function lockParameters() external onlyOwner {
        require(
            address(parameters).supportsInterface(
                type(IUniverseMachineParameters).interfaceId
            ),
            "Not IUniverseMachineParameters"
        );
        parametersLocked = true;
    }

    /**
    @notice Sets the address of the parameters contract.
    @dev No checks are performed when setting, but lockParameters() ensures that
    the final address implements the IUniverseMachineParameters interface.
     */
    function setParameters(address _parameters) public onlyOwner {
        require(!parametersLocked, "Parameters locked");
        parameters = IUniverseMachineParameters(_parameters);
    } 

    /** @notice Flag whether to use IPFS or direct rendering. */
    bool public useCDN = true;

    /**
    @notice Flag to disable use of toggleCDN().
     */
    bool public cdnLocked = false;

    /**
    @notice Permanently sets the CDN-lock flag to true.
     */
    function lockCDN() external onlyOwner {        
        cdnLocked = true;
    }

    /**
    @notice Toggles use of a CDN.
     */
    function toggleCDN() public onlyOwner {
        require(!cdnLocked, "CDN locked");
        useCDN = !useCDN;
    }

    string private _cdnBaseUrl;
    string private _externalUrl;
    string private _description;

    constructor(uint totalInventory)
        ERC721Common("the Universe Machine", "TUM")
        ArbitraryPriceSeller(
            Seller.SellerConfig({
                totalInventory: totalInventory,
                maxPerAddress: 0,
                maxPerTx: 0,
                freeQuota: 0,
                reserveFreeQuota: false,
                lockFreeQuota: true,
                lockTotalInventory: true
            }),
            payable(0xFDc91fE3f9fC29A8c53D2Bbb7dB39A29b2639736)
        ) 
    {  
        _externalUrl = "https://linktr.ee/praystation";
        _description = "the Universe Machine is an algorithm I have been working on since 2014. The program can generate 1 of 55 unique generative patterns. Maps 56,000 textures to a grid based Bezier path segment function... to build a universe in 10 possible color sets.";
        _cdnBaseUrl = "https://kohi.art/api/images/tum";
        setRoyaltyBeneficiary(payable(0xFBC78f494aD61d90F02A3258e527De1321095AcB));
    }

    /**
    @notice Sets external details.
    */
    function setDetails(string memory externalUrl, string memory description, string memory cdnBaseUrl) public onlyOwner {
        _externalUrl = externalUrl;
        _description = description;
        _cdnBaseUrl = cdnBaseUrl;
    } 

    /**
    @notice Minting price for presales.
     */
    uint256 public presalePrice = 0.22 ether;

    /**
    @notice Minting price for public minters.
     */
    uint256 public publicPrice = 0.31415 ether;    

    /**
    @notice Updates the prices for the two tiers.
     */
    function setPrice(uint256 public_, uint256 presale) external onlyOwner {
        publicPrice = public_;
        presalePrice = presale;
    }

    /**
    @notice Proxy contract from which public minting requests are allowed.
     */
    address public _publicMinter;

    /**
    @notice Sets the public-minting contract.
     */
    function setPublicMinter(address publicMinter) external onlyOwner {
        _publicMinter = publicMinter;
    }

    /**
    @notice Mint as a member of the public, but only via minter contract.
    @dev This allows for arbitrary control of minting logic post deployment.
     */
    function mintPublic(address to, uint256 n) external payable {
        require(msg.sender == _publicMinter, "Direct public minting");
        _purchase(to, n, publicPrice);
    }

    /**
    @notice Set of addresses from which valid signatures will be accepted to
    provide access to minting.
     */
    EnumerableSet.AddressSet private signers;

    /**
    @notice Add an address allowed to sign minting access.
     */
    function addSigner(address signer) external onlyOwner {
        signers.add(signer);
    }

    /**
    @notice Remove an address from those allowed to sign minting access.
     */
    function removeSigner(address signer) external onlyOwner {
        signers.remove(signer);
    }

    /**
    @notice Already-redeemed signed-minting messages.
     */
    mapping(bytes32 => bool) public usedMessages;

    /**
    @notice Already-redeemed allow list addresses.
     */
    mapping(address => bool) public usedAddresses;    

    /**
    @notice Mint one token as a holder of a signature; most likely from the allow list.
     */
    function mintWithSignature(bytes calldata signature) external payable {
        require(!usedAddresses[msg.sender], "address already claimed allow list mint");
        signers.requireValidSignature(
            abi.encodePacked(msg.sender, uint16(1)),
            signature,
            usedMessages
        );
        _purchase(msg.sender, 1, presalePrice);
        usedAddresses[msg.sender] = true;
    }

    /**
    @notice Partially fulfills the ERC721Enumerable interface.
     */
    Monotonic.Increaser public totalSupply;

    /**
    @notice The per-token seeds used to generate images.
     */
    mapping(uint256 => int32) public seeds;

    /**
    @notice Override of the Seller purchasing logic to mint the required number
    of tokens. The freeOfCharge boolean flag is deliberately ignored.
     */
    function _handlePurchase(
        address to,
        uint256 n,
        bool
    ) internal override {
        uint256 nextId = totalSupply.current();
        uint256 end = nextId + n;

        // These are close enough to unpredictable / uncontrollable to be
        // sufficiently random for our purpose. Only a miner could really
        // influence this.
        bytes memory entropyBase = abi.encodePacked(
            address(this),
            block.coinbase,
            block.number,
            to
        );

        for (; nextId < end; ++nextId) {
            _safeMint(to, nextId);
            seeds[nextId] = int32(int(uint(keccak256(abi.encodePacked(entropyBase, nextId)))));
        }
        totalSupply.add(n);
    }
     
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(address(parameters) != address(0), "No parameters");
        require(useCDN || address(renderer) != address(0), "No renderer");
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory metadata = getTokenMetadata(tokenId);
        string memory dataUri = string(abi.encodePacked(JSON_URI_PREFIX, Base64.encode(bytes(metadata), bytes(metadata).length)));
        return dataUri;
    }

    function getTokenMetadata(uint tokenId) private view returns (string memory metadata) {
        
        Parameters memory p = parameters.getParameters(tokenId, seeds[tokenId]);

        string memory tokenName = this.name();
        string memory tokenIdString = Strings.toString(tokenId);

        string memory image;
        if(useCDN) {
            image = string(abi.encodePacked(_cdnBaseUrl, '/', tokenIdString));
        } else {
            image = renderer.image(p);
        }        

        metadata = string(abi.encodePacked('{"description":"', _description, 
        '","external_url":"', _externalUrl, 
        '","name":"', tokenName, ' #', tokenIdString, 
        '","image":"', image,
        '",', getTokenMetadataAttributes(p),
        '}'));
    }

    function getTokenMetadataAttributes(Parameters memory p) private view returns (string memory attributes) {

        uint8 numberOfTraits = 0;

        attributes = string(abi.encodePacked('"attributes":['));
        {
            (string memory a, uint8 t) = appendTrait(attributes, "Universe", 
            string(abi.encodePacked(Strings.toString(p.whichMasterSet), " of 55")), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        uint8[4] memory universe = parameters.getUniverse(uint8(p.whichMasterSet));

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Map", 
            Strings.toString(uint32(universe[0])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Texture", 
            Strings.toString(uint32(universe[1])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Flow", 
            Strings.toString(uint32(universe[2])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            (string memory a, uint8 t) = appendTrait(attributes, "Orbit", 
            Strings.toString(uint32(universe[3])), 
            numberOfTraits
            );
            attributes = a;
            numberOfTraits = t;
        }

        {
            string memory palette;

            if(p.whichColor == 0) {
                palette = "seafoam";
            } else if(p.whichColor == 1) {
                palette = "slate";
            } else if(p.whichColor == 2) {
                palette = "sunset";
            } else if(p.whichColor == 3) {
                palette = "cocoa";
            } else if(p.whichColor == 4) {
                palette = "tigereye";
            } else if(p.whichColor == 5) {
                palette = "sage";
            } else if(p.whichColor == 6) {
                palette = "moss";
            } else if(p.whichColor == 7) {
                palette = "ice";
            } else if(p.whichColor == 8) {
                palette = "salmon";
            } else if(p.whichColor == 9) {
                palette = "grayscale ";
            }

            (string memory a, uint8 t) = appendTrait(attributes, "Universe Color", palette, numberOfTraits);
            attributes = a;
            numberOfTraits = t;
        }        

        attributes = string(abi.encodePacked(attributes, "]"));
    }

    function appendTrait(string memory attributes, string memory trait_type, string memory value, uint8 numberOfTraits) private pure returns (string memory, uint8) {        
        if(bytes(value).length > 0) {
            numberOfTraits++;
            attributes = string(abi.encodePacked(attributes, numberOfTraits > 1 ? ',' : '', '{"trait_type":"', trait_type, '","value":"', value, '"}'));
        }
        return (attributes, numberOfTraits);
    }

    /**
    @notice Defines royalty proportion in hundredths of a percent.
     */
    uint256 public royaltyBasisPoints = 750;
    uint256 private constant BASIS_POINT_DENOMINATOR = 100 * 100;

    /**
    @notice Sets royalty proportion.
    @param basisPoints Measured in hundredths of a percent; 1% = 100; 1.5% = 150; etc.
     */
    function setRoyalties(uint256 basisPoints) external onlyOwner {
        require(basisPoints <= BASIS_POINT_DENOMINATOR, ">100%");
        royaltyBasisPoints = basisPoints;
    }

    address payable private royaltyBeneficiary;

    /// @notice Sets the recipient of secondary revenues.
    function setRoyaltyBeneficiary(address payable _beneficiary) public onlyOwner {
        royaltyBeneficiary = _beneficiary;
    }

    /**
    @notice Implements ERC2981.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        // Probably safe to assume that salePrice will be less than max(uint256)/10000 ;)
        return (
            royaltyBeneficiary == address(0) ? Seller.beneficiary : royaltyBeneficiary, 
            (salePrice * royaltyBasisPoints) / BASIS_POINT_DENOMINATOR
        );
    }

    /**
    @notice Adds ERC2981 interface to the set of already-supported interfaces.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Common, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}