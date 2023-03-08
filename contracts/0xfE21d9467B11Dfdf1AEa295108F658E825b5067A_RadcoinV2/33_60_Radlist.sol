// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

/*

╢╬╬╬╬╠╠╟╠╬╢╠╬╬╠╠╠╢╬╬╠╠╠╠╬╬╬╣▌▌▓▌▌▌▌▌▌╬╬▓▓▓▓▓▓▌▓▓▓▓▒░»=┐;»:»░»¡;":¡░¡!:░┐░░░░░!░░
╠╠╠╠╠╠╠╬╣╬╬╬╬╬╬╠╠╠╠╠╠╬╬▓████████████████████████████▌▄φφφφφφφφ╦▒φφ╦φ╦▒φ╦╦╦╦φφφφφ
▒╠▓╬▒▒▒▒▒▒▒▒╠╠╠╠╠╣╣╬▓██████████████████████████████████▓▓▌╬╟╬╢╠╟╠╠╠╠╠╟╟╠╠╠╠╠╠╠╠╠
▒╚▓╣▓▓▓▓╣╬▄▓▓▒▒╠▓▒▒▓███████████████████████████▓▓▓█▓█▓█▓▓█▓▓╬╠╠╟╠╠╠╠╢╠╠╠╠╠╬╢╠╠╠╠
▒Å▓▓▓▓▓▓█▓▓▓╬╫▌╠▓▓████████████████████▓▓████████▓█▓▓█▓▓▓▓█▓█▓▓╬╠╠╠╠╠╠╠╠╠╠╬╠╬╠╠╠╟
▒╚╚░▒╚╚╩╠╬╣▓╬╣▓╣▓███████████████▓█▓██████████████████▓█▓██▓█▓██▓╬╢╟╠╠╠╢╠╟╠╠╠╠╠╟╟
╟▒▒░░Γ▒╣▒▒░#▒▒╚▓████████████████▓██████▓████████████████████████▓╬╠╠╠╟╠╬╠╟╠╬╠╠╠╠
▒╠╠╩▒▒╟▓▓▓▓╣▓▓▓███████████████▓████████████▀╫███████████████████▓▓╬╠╠╠╠╠╠╠╠╠╬╠╠╠
▒▒▒Γ░Γ▒╬╬▀╬╣▓▓███████████████████████████▓╨░░╫████████████████████▓╬╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▌╬╬╠╬▒▒▒▒████████████████████████████░¡░░!╫██████████▓╟██▓██████▌╠╠╠╠╠╠╠╠╠╠╠
███████████▓██████▓████████▀╫███████████▒∩¡░░░░╙▀▓╟████▌┤░░╫███▀▀███▌╠╠╠╠╠╠╠╠╠╠╠
███████████████████████████░╙███▌│╩╨╙██▌░░░░░░░░░░░██▓╝░░░Q▓███████▓╠╠╠╟╠╠╠╠╠╠╠╠
▓▓▓███████████████████████▌ü███▓▄▄Q░░██▒\░░░░¡░░░░░╫▓▌▓███████▀▀▀╫╬╠╠╬╠╠╟╟╠╠╠╠╠╟
╬▓╬╣╬╣╣╣╣╬▓╬████████████╩▀▒░▀▀▀▀▀▀▀███████▓▌▄µ░░░░░▀▀▀╫███████Γ░░╠╟╠╠╠╠╠╠╠╠╠╠╠╠╠
█▓▓▓▓▓▓▓▓▓▓▓▓███████████░░░░░░∩░░░Q▄▄▄▄░░░┘┤╨├░¡░░░░░▄███▄█████▒░╟╠╠╠╠╠╠╠╠╠╠╠╠╠╠
▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▒░░░░░▓███▀█████▄░░░░░░░¡░░ΓΓ██████████┤Γ╬╠╠╠╠╠╬╠╠╠╠╠╠╠╠
╬╬╬╣╬╣╬╬╣╬╬╬╣▓███████████░░░▄█████████████▄░░░░░¡░░░░█████████δ░░▓╬╣╣▓▓▓▓▓▓╣╣▓▓▓
╬╬╬╬╣╬╣╬╬╬╬╬╬▓████▒░░∩░▀█▒░▀██╙█▓███████▓█▌░░¡░░░░░░░╚█████▓█▒░░╫▓████▓█▓▓▓▓▓▓▓▓
╬╣╬╢╬╬╣╬╣╬╬╬╣▓███▌░░░░░░░░░░░┤~╙█▓█████▀██▒░¡░░░░░░φ░░███▓██▒░░░▓▓▓╬╚╙╫╬╫███████
╬╬╣╬╬╬╣▓▓██▓╬▓███▓░░░░░░░░░░░░(=├▀██▓█████░░░¡░>░""░Γ░░░░░░Γ░░░╫▓▓▓▓▓▓▓█▓█▓▓▓▓▓▓
╬╫╬╬╬╬╣▓╬╟╬▓╬█████▓▄▒░░░░░░░░░∩░░│▀▀▀╫╨╨╨╨░░░¡░¡░░¡¡░░░░░░░░░░╢▓██▓▓█████████▓██
▓▓▓▓▓▓▓▓╬╬╫█████████████▓▌▒░░░░░░░░░░!░░░░¡░░░░Q▄▄▄▄▄░░░░Γ░Γ▄▓▓█████████████████
▓█████╬╣▓▓▓████████████████▓▌▒░░░░░░░░░░░░░░░░████▀▀░░░░░░▄▓▓▓██████████████████
▓▓▓╬▓▓╬╣╬╬╬╬╬╬╬╬███████████████▌▄▒░░░░░░░░░░░░░░░░░░░░½▄▓▓███▓██████████████████
▓╬╠▓▓▓▓╣╣╬╣╣╬╣▓╬████▓██████████████▓▓▌▄▄░░░░░░░░φ╦▄▄▓▓███████▓█████████████▓╠▓██
▓▌╠▓▓▓╬╬╣╬╬╬╬╬╬╬▓█▓████▓█▓╬╢▓██▓▓▓▓▓▓▓▓▓▒Σ▒▒#░#▓▓▓▓▓▓██████████████▓▓████▓▓▓╬╬╬╬
▓▓╠▓███▓▓╣╣╬╣╬╣╢▓▓▓▓▓▓██▓▓▓╣▓▓█▓▓█▓██▓╬#Γ#▒▒▒░Σ╣█████████████▓╣╬▓███▓████▓╣╣╬╣╣▓
▓▓╬▓▓▓▓▓▓▓▓▓▓█▓╬▓▓▓▓▓▓▓▓█████████████▄ΓΓ╚Γ░ΓΓΓ▐▄█████████████▓╬╬╬╫█████▓╬╬╣╬╬╬╬╬
▓▓▓▓▓▓▓▓▓▓▓█████████████████▓▓██████████▓▓▓▓▓████████████▓▓▓╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬
▓███████████████████████████████████████████████████████╬╣╬╬╬╬╬╬╬╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬
▓████████████████████████████████████████████████████████╬╬╬╬╫╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╬╬╬
██████████████████████████████████▓██▓█▓▓▓███▓██▓█████████╬╬╣╬╬╣╬╬╬╬╬╣╬╬╬╬╬╬╬╬╣╣
▓█████████████████▓▓▓▓╬╬╬██████████████████▓██▓██╣████████▓╬╬╫╬╢╬╫╬╬╬╬╬╣╬╣╬╬╬╣╬╣
██████▓█▓▓╬╬╬╬╬╬╬╬╬╬╣╬╬╬▓██████████▌▓╬▒╫▓▓▌╣██▓▓╬▒█████████▌╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬
╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╣╬╬╬╬╬╬╣████████████╣╟▓╬╣▓▓▓▓▓▓▓▓▓╫█████████╬╬╬╬╬╣╬╬╬╬╬╬╬╬╬╣╬╬╬░
                          ;                                          
                          ED.                                  :     
                          E#Wi                                t#,    
 j.                       E###G.      .          j.          ;##W.   
 EW,                   .. E#fD#W;     Ef.        EW,        :#L:WE   
 E##j                 ;W, E#t t##L    E#Wi       E##j      .KG  ,#D  
 E###D.              j##, E#t  .E#K,  E#K#D:     E###D.    EE    ;#f 
 E#jG#W;            G###, E#t    j##f E#t,E#f.   E#jG#W;  f#.     t#i
 E#t t##f         :E####, E#t    :E#K:E#WEE##Wt  E#t t##f :#G     GK 
 E#t  :K#E:      ;W#DG##, E#t   t##L  E##Ei;;;;. E#t  :K#E:;#L   LW. 
 E#KDDDD###i    j###DW##, E#t .D#W;   E#DWWt     E#KDDDD###it#f f#:  
 E#f,t#Wi,,,   G##i,,G##, E#tiW#G.    E#t f#K;   E#f,t#Wi,,, f#D#;   
 E#t  ;#W:   :K#K:   L##, E#K##i      E#Dfff##E, E#t  ;#W:    G#t    
 DWi   ,KK: ;##D.    L##, E##D.       jLLLLLLLLL;DWi   ,KK:    t     
            ,,,      .,,  E#t                                        
                          L:                                         

*/

import { OwnerPausable } from "@divergencetech/ethier/contracts/utils/OwnerPausable.sol";
import { ERC721Redeemer } from "@divergencetech/ethier/contracts/erc721/ERC721Redeemer.sol";
import { MerkleProofLib } from "solmate/src/utils/MerkleProofLib.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/*//////////////////////////////////////////////////////////////
                        PARAMETER TYPES
//////////////////////////////////////////////////////////////*/

struct AddCollectionParams {
    address collection;
    uint16 multiplier;
    uint16 maxPerWallet;
}

struct ClaimRadlistParams {
    ClaimRadlistForMerkleProof merkleProof;
    ClaimRadlistForCollection[] collections;
}

struct ClaimRadlistForMerkleProof {
    uint256 merkleAmount;
    bytes32[] merkleProof;
}

struct ClaimRadlistForCollection {
    address collection;
    uint256[] ids;
}

/// @notice Radlist, on-chain Radness verification.
/// @author 10xdegen
abstract contract Radlist is OwnerPausable {
    using ERC721Redeemer for ERC721Redeemer.SingleClaims;
    using Strings for uint16;

    /*//////////////////////////////////////////////////////////////
                                 STORAGE TYPES
    //////////////////////////////////////////////////////////////*/

    struct RadlistedCollection {
        Options options;
        Claimed claimed;
    }

    struct Options {
        uint16 multiplier;
        uint16 maxPerWallet;
    }

    struct Claimed {
        ERC721Redeemer.SingleClaims claims;
        // number claimed per wallet
        mapping(address => uint16) perWallet;
    }

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    // radlist merkle root
    bytes32 public merkleRoot;

    // claimed radlist
    mapping(address => uint16) public merkleClaimed;

    // list of radlisted nft collections
    address[] public collectionList;

    // config and state of radlisted nft collections
    mapping(address => RadlistedCollection) collections;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Constructor.
     * @param _merkleRoot The merkle root.
     * @param _collections The radlisted collections to add.
     */
    constructor(bytes32 _merkleRoot, AddCollectionParams[] memory _collections) {
        merkleRoot = _merkleRoot;
        for (uint256 i = 0; i < _collections.length; i++) {
            uint16 multiplier = _collections[i].multiplier;
            uint16 maxPerWallet = _collections[i].maxPerWallet;
            if (multiplier == 0) multiplier = 1;
            collectionList.push(_collections[i].collection);
            collections[_collections[i].collection].options = Options(multiplier, maxPerWallet);
        }
    }

    /**
     * @dev Add a collection to the radlist.
     * @param _collections The collections to add.
     */
    function addCollections(AddCollectionParams[] memory _collections) external onlyOwner {
        for (uint256 i = 0; i < _collections.length; i++) {
            address collection = _collections[i].collection;
            uint16 multiplier = _collections[i].multiplier;
            if (multiplier == 0) multiplier = 1;
            collectionList.push(collection);
            collections[collection].options = Options(multiplier, _collections[i].maxPerWallet);
        }
    }

    /**
    @dev Update the merkle root, for adding new radlisters.
     */
    function updateMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    /**
    @dev Check if an NFT has already been claimed.
     */
    function claimedNFT(address collection, uint256 id) public view returns (bool) {
        RadlistedCollection storage radlistedCollection = collections[collection];
        Claimed storage claimed = radlistedCollection.claimed;
        return claimed.claims.claimed(id);
    }

    function _claimRadlist(address wallet, ClaimRadlistParams calldata params) internal returns (uint16 totalClaimed) {
        // verify merkle proof
        if (params.merkleProof.merkleAmount > 0) {
            require(
                verifyMerkleProof(
                    wallet,
                    params.merkleProof.merkleAmount + merkleClaimed[wallet],
                    params.merkleProof.merkleProof
                ),
                "Radlist: invalid merkle proof"
            );
            merkleClaimed[wallet] += uint16(params.merkleProof.merkleAmount);
            totalClaimed += uint16(params.merkleProof.merkleAmount);
        }

        // claim radlisted nfts
        for (uint256 i = 0; i < params.collections.length; i++) {
            address collection = params.collections[i].collection;
            uint256[] calldata ids = params.collections[i].ids;

            RadlistedCollection storage radlistedCollection = collections[collection];
            Claimed storage claimed = radlistedCollection.claimed;
            Options storage options = radlistedCollection.options;

            // check redemption
            uint256 amount = claimed.claims.redeem(wallet, IERC721(collection), ids) * options.multiplier;

            // check max per wallet
            uint256 alreadyClaimed = claimed.perWallet[wallet];
            require(
                alreadyClaimed + amount <= options.maxPerWallet,
                string(
                    abi.encodePacked(
                        "Radlist: max per wallet exceeded",
                        " ",
                        wallet,
                        " ",
                        uint16(amount).toString(),
                        " ",
                        options.maxPerWallet.toString()
                    )
                )
            );

            // increment claimed amounts
            claimed.perWallet[wallet] = uint16(alreadyClaimed + amount);
            totalClaimed += uint16(amount);
        }
    }

    /**
     * @dev Helper fuction to get already claimed amount for a wallet.
     */
    function claimedAmount(address wallet, address collection) public view returns (uint16) {
        RadlistedCollection storage radlistedCollection = collections[collection];
        Claimed storage claimed = radlistedCollection.claimed;
        return claimed.perWallet[wallet];
    }

    /**
     * @dev Verify a merkle proof.
     * @param wallet The address to claim spots for.
     * @param amount The number of spots to claim.
     * @param merkleProof The merkle proof.
     * @return valid if the proof is valid.
     */
    function verifyMerkleProof(
        address wallet,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) public view returns (bool valid) {
        if (amount == 0) return true; // no spots to claim
        bytes32 node = keccak256(abi.encodePacked(wallet, amount));
        valid = MerkleProofLib.verify(merkleProof, merkleRoot, node);
    }

    /**
     * @dev Verify radlisted NFTs.
     * @param wallet The address to claim spots for.
     * @param collection The NFT collection address.
     * @param ids The NFT ids to claim spots with.
     * @return eligibleIds The NFT ids that are valid to claim with.
     * @return claims The number of total redeemable claims for the list.
     */
    function getRadlistedNFTs(
        address wallet,
        address collection,
        uint256[] calldata ids
    ) external view returns (uint256[] memory, uint256 claims) {
        RadlistedCollection storage radlistedCollection = collections[collection];
        uint16 alreadyClaimed = radlistedCollection.claimed.perWallet[wallet];

        IERC721 nft = IERC721(collection);

        uint256[] memory eligibleIds = new uint256[](ids.length);
        uint256 eligibleCount = 0;

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            if (nft.ownerOf(id) == wallet && !radlistedCollection.claimed.claims.claimed(id)) {
                eligibleIds[eligibleCount] = id;
                eligibleCount++;
                claims += radlistedCollection.options.multiplier;
            }
        }

        if (claims + alreadyClaimed > radlistedCollection.options.maxPerWallet) {
            claims = radlistedCollection.options.maxPerWallet - alreadyClaimed;
        }

        return (eligibleIds, claims);
    }
}