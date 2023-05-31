// SPDX-License-Identifier: MIT
// NEKOCORE Pilot Program
//
//                       @@@@@@@%                                                 /@@@
//                      @@@%    @@@@@                                         @@@@@@@@@@
//                     @@@          @@@@@                                 @@@@@       @@@
//                    ,@@#             %@@@@@@@@@@@@@@@@@@@@@@@@@@    #@@@@            @@@
//                    @@@                  @@@@@#             ,@@@@@@@@@               %@@
//                   ,@@%                                                               @@@
//                   @@@                                                                @@@
//                   @@@                                                                 @@@
//                   @@@                                                                 @@@
//                   @@@                                                                 @@@
//                  @@@@                                                                 &@@(
//                @@@@                                                                    @@@
//               @@@@                                                                      @@@
//              @@@,                                                                        @@@*
//             @@@                                                                           @@@
//            &@@@                                                                           ,@@@
//            @@@            @%(((((((((((((((((((@@@        @@@#((((((((((((((((((#@         @@@
//            @@@           @(((((((((((((((((((((((((@####@&((((((((((((((((((((((((@        @@@
//            @@@           @(((((((((((((((((((((((((((#%(((((((((((((((((((((((((((@        @@@
//            @@@            @////////////////////////@    @////////////////////////@         @@@
//            #@@@            @//////////////////////@      @//////////////////////@         @@@,
//             @@@@              @@@////////////////@        @&///////////////&@@           @@@@
//              @@@@                                                                       @@@%
//               &@@@                                 @*/@*@                             @@@@
//                 @@@@                               &/***@                           @@@@&
//                   @@@@@                                                           @@@@/
//                      @@@@@                                                    /@@@@@
//                         @@@@@@@                                           @@@@@@%
//                             /@@@@                                     @@@@@@
//                             @@@@                                      @@@(
//                            @@@&                                        @@@
//                           @@@#                                         @@@/
//                          #@@@                                           @@@
//                          @@@                                            @@@
//                         @@@@                                            @@@
//                         @@@                                             @@@
//                      @@@@@@                                             @@@
//                    @@@@                                                /@@@
//                   @@@*                                                 @@@
//                  %@@@           @@@@@@@@@@@@@        @@        @@@@@@@@@@
//                  #@@@            %@@@@@@   @@@      @@@@      @@@@
//                   @@@@                @@@   @@@@@@@@@@@@@@@@@@@@,
//                     @@@@@@            @@@      &@@%        /
//                         @@@@@@@@@@@@@@@@
//
//

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./NekoCore.sol";

contract NekoCorePilotProgram is ERC721, Ownable {
    NekoCore public immutable ORIGINAL_CONTRACT;
    bytes32 public immutable PROVENANCE; // keccak256 of all images in order, 1..9999

    uint public constant MAX_CLAIM_SIZE = 1 << 7;
    bool public MINTABLE; // default = false;

    string private _baseTokenURI; // default = "";

    constructor(
        address originalNekoCore,
        string memory baseTokenURI,
        bytes32 provenance
    ) ERC721("NekoCore Pilot Program", "NEKOPILOTS") {
        _baseTokenURI = baseTokenURI;
        PROVENANCE = provenance;
        ORIGINAL_CONTRACT = NekoCore(originalNekoCore);
    }

    // --- overrides --------------------------------------------------
    // ----------------------------------------------------------------

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // --- only owner -------------------------------------------------
    // ----------------------------------------------------------------

    function setTokenURI(string calldata uri) public onlyOwner {
        // ipfs://<CID>/token_id
        _baseTokenURI = uri;
    }

    function setMintable(bool allow) public onlyOwner {
        MINTABLE = allow;
    }

    // --- public views -----------------------------------------------
    // ----------------------------------------------------------------

    function totalSupply() external view returns (uint256) {
        return ORIGINAL_CONTRACT.totalSupply();
    }

    function claimsAvailable(address test)
        public
        view
        returns (uint[MAX_CLAIM_SIZE] memory)
    {
        uint[MAX_CLAIM_SIZE] memory result;
        uint next;
        for (uint i = 1; i <= this.totalSupply(); i++) {
            if (!_exists(i) && test == ORIGINAL_CONTRACT.ownerOf(i)) {
                result[next++] = i;
                if (next == MAX_CLAIM_SIZE) {
                    break;
                }
            }
        }
        return result;
    }

    // --- public use -------------------------------------------------
    // ----------------------------------------------------------------

    function claim(uint256 token_id) public {
        require(MINTABLE, "Contract is not currently mintable");
        require(!_exists(token_id), "Pilot has already been claimed");
        require(_msgSender() == ORIGINAL_CONTRACT.ownerOf(token_id), "Caller is not the token owner");
        _safeMint(_msgSender(), token_id);
    }

    function claimAll(uint256[] calldata claims) public {
        for (uint256 i = 0; i < claims.length; i++) {
            claim(claims[i]);
        }
    }
}