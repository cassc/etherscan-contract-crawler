// SPDX-License-Identifier: MIT
                                                                                                      
//                                                                                                                       
//                                                     *%@@@@@@@@@@@@@@@@@@@&#.                                          
//                                     @@@@@@@(      (&@@@@@@      @& (@@@@@@@@#     (@@@                                
//                                   @       @@@@@@@@@@@@@@    @ @@ &@ @@@@@@@@@@@@@@@@@@ *@                             
//                                  @ &@ @@   @@@    /@@@*     @ @@@@@@ @@@@@@@@@@@@@@@@@@    @@*                        
//              @@@@@@&             @*,@% @        @           @ @@@@@@. @@@@@@@@@@@@@@@@%    @@  @                      
//          @@   (@@@@. @           .@ @@ @@     @ (@ @@@@@    @ @@@@@@ @@ @@@@@@@@@@@@@@    @@@@@/*@                    
//         @ @@@@@@@ @@@ @@          @ @@@ @@    @ #@@ @@@@   /@ @@@@@ @@@@@@@@@@@@@@@@@@ @@% @@@@@@ @                   
//       @. @%   @@@@ /@@@@ &@       /@ @@@ @    @ @@@@ @@@@  @ &@@@@@ @@@@@@@@@@@@@   *@@@@@@@@@@*  .@@                 
//      @ @@@@@@@@ @ %@@@@@@ @*       @..@@@ &, @* @@@@@  @@@@ &@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@@@@@  @%              
//      @ #@@(@@@@( @@@@@@@@ @         @ /@@@@   /@@@@@@@@@#%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@* @/            
//       @  @@@@@@@@@@@@@@    @.        @/ @@@@@@@@@@@@@@@@@@@@@@@@  @@@@@@@@@@@@@@@@@#.   *@@@@@@@@#       #@%          
//         @  @@@@@@@@@ @@@@@@ @     .@@  @ @@@@@@@@@@@@@@@@@*   @@@@@@@@@@@@@@@@@@@ @@@@@  @@  % @@@@@@@@@@@@ @         
//           #@@ /@@@@@@@@@@  @#     (@@@@@@@ @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  ,@@@@@@@@@@ @@@@@@@@@@@@@. @         
//            @ @@@@@@@@@  @@@@@@@@@@@@@@@@@@@  %@@@@@@@@@@@@@@@@@@@    @@@@@@@     @@@@@@@@  @( @@@@@@@@@@@@@, @        
//            %@     &@@@@@@@@@@@@@@@@@@@@@ ,@  @@  @@@@@@@@@@  %@@@@@@@@@@,         @   @@@ @  @@@@@@@@@@@@@@@@ @       
//                  @@  @@@@@@@@@@@@@@(  @@       @         @@@@@@@@@&  *@@@@@@@@@@@(       @ @@@@@@@@@@@@@@@@@@(.@      
//                      @@@&.     %@@@,           @     *@@@@@@@@  @@%      @@   ( @@  @    @% @@@/@@@@@@@@@@@@@*.@      
//                                .%@&/            @  @@@@@@@@  @#    &@@@  ((((((, @@ &%    @.,@@ @@@@@ @@@@ @@ @       
//                           %@,  %@@@@   @@     @@ @@@@@@@& @@@#       ( (@@@ (((( @@@ @     @ @@@@@@@@ @@@@  @@        
//                         @& %,   @@@@@@ (  @@      %@@@@ @@@@@@@@@@@@% * @@  ((((( @@ @/     @@   .    .   @           
//                        @     #@@@@@@   ((( (((((((.   %@.  @@@@@@@@@@ ((((((((((( @@@ @                               
//                        @% @@@@@@@  *@@@@@  (((((( @@@  %@  @@@@/      (((((((((((. @@ @                               
//                          @  @@@@@@@@@@  ,@@@@  ((*   . @              @@ /(((((((( @@**@                              
//                            @@ ,@@@@@@@@@@@&  @@@@  ((( @&              .@ (((((((( @@@ @                              
//                               @@ .@@@@@@@@@@@@( &@@@ ,( @               @   @@@@@@ &@@ @                              
//                                  @@  @@@@@@@@@@@@& &@@  @               *@ @@@@@@@/,@@ @                              
//                                      @@. .@@@@@@@@@@    @                .@ @@@@@@& @@ @                              
//                                          .@@(  ,@@@@@ *@                    @@      ,@@                               
//                                                 &@@@@#                                                                
//                                                                                                                                                                                                                                

pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {UpdatableOperatorFilterer} from "operator-filter-registry/src/UpdatableOperatorFilterer.sol";
import {RevokableDefaultOperatorFilterer} from "operator-filter-registry/src/RevokableDefaultOperatorFilterer.sol";

interface ogcontract {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function burn(uint256 tokenId) external;
}

interface Delegate {
   function checkDelegateForAll(address delegate, address vault) external view returns (bool);
}

contract SCUM is ERC721AQueryable, Ownable, RevokableDefaultOperatorFilterer, ReentrancyGuard {

    address private OGContract = 0xAc5Aeb3b4Ac8797c2307320Ed00a84B869ab9333;
    address private signer = 0x2f2A13462f6d4aF64954ee84641D265932849b64;
    string public _metadataRegular = "ipfs://QmY2oBi4p5zASJmzbjxMrn3poBj5QZFKxwF6zBpg8puVRt";
    string public _metadataSOTY = "ipfs://QmbZ7NNu4A9qoxGwMHFw4n92dpz7zCCJbsFJPgdtpvdyqE";

    uint256 public regularMinted = 0;
    uint256 public SOTYMinted = 0;
    uint256 private maxBurnPerWallet = 5;

    uint256 private MAX_REGULAR_MINT = 250;
    uint256 private MAX_SOTY_MINT = 25;

    mapping(uint256 => uint256) public tokenMapping;
    mapping(uint256 => uint256) public tokenType;

    mapping(address => uint256) public totalMintedRegular;
    mapping(address => bool) public mintedSOTY;

    bool burnActive = false;

    constructor() ERC721A("SCUMBAGS", "SCUM") {}

    function burnToken(uint256[] memory tokenIds) public nonReentrant {
        require(burnActive, "Burn not Active");

        uint256 amount = tokenIds.length;

        require(msg.sender == tx.origin, "EOA only");
        require(amount + totalMintedRegular[msg.sender] <= maxBurnPerWallet, "Too many");
        require(regularMinted + amount <= MAX_REGULAR_MINT, "Minted out");

        totalMintedRegular[msg.sender] += amount;
        regularMinted += amount;

        _mint(msg.sender, tokenIds.length);

        for(uint256 i = 0; i < tokenIds.length; i++)
            _burnOG(tokenIds[i]);
    }

    function _burnOG(uint256 tokenId) internal {
        require(msg.sender == ogcontract(OGContract).ownerOf(tokenId), "Not the owner");
        ogcontract(OGContract).burn(tokenId);
    }

    function adminMint(bool isSOTY, address wallet) public onlyOwner {
        if(isSOTY){
            require(SOTYMinted + 1 <= MAX_SOTY_MINT, "Minted out");
            uint16 mintId = uint16(_totalMinted());
            tokenMapping[mintId] = SOTYMinted;
            tokenType[mintId] = 1;
            SOTYMinted += 1;
        }
        else{
            require(regularMinted + 1 <= MAX_REGULAR_MINT, "Minted out");
            totalMintedRegular[wallet] += 1;
            regularMinted += 1;
        }
        
        _mint(wallet, 1);
    }

    function claimSOTY(address wallet, bytes calldata voucher, bool delegate) public nonReentrant {
        require(burnActive, "Burn not Active");

    	if(delegate) require(Delegate(0x00000000000076A84feF008CDAbe6409d2FE638B).checkDelegateForAll(msg.sender, wallet), "Not delegate");
        else require(msg.sender == wallet, "Not wallet");
    
        require(msg.sender == tx.origin, "EOA only");
        bytes32 hash = keccak256(abi.encodePacked(wallet));

        require(_verifySignature(signer, hash, voucher), "Invalid voucher");
        require(!mintedSOTY[wallet], "Already minted");

        require(SOTYMinted + 1 <= MAX_SOTY_MINT, "Minted out");

        mintedSOTY[wallet] = true;

        uint16 mintId = uint16(_totalMinted());
        
        tokenMapping[mintId] = SOTYMinted;
        tokenType[mintId] = 1;

        _mint(msg.sender, 1);

        SOTYMinted += 1;
    }

    function _verifySignature(address _signer, bytes32 _hash, bytes memory _signature) internal pure returns (bool) {
        return _signer == ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), _signature);
    }

    function setMaxBurnPerWallet(uint256 _amount) public onlyOwner {
        maxBurnPerWallet = _amount;
    }

    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setOGContract(address _addr) public onlyOwner {
        OGContract = _addr;
    }
    function setMetadataRegular(string memory metadata) public onlyOwner {
        _metadataRegular = metadata;
    }

    function setMetadataSOTY(string memory metadata) public onlyOwner {
        _metadataSOTY = metadata;
    }

    function setBurn(bool _state) public onlyOwner {
        burnActive = _state;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURIRegular = _baseURIRegular();
        string memory baseURISOTY = _baseURISOTY();

        uint id = tokenMapping[tokenId];
        uint path = tokenType[tokenId];

        if(path == 0) return string(abi.encodePacked(baseURIRegular, "/", Strings.toString(tokenId)));
        else return string(abi.encodePacked(baseURISOTY, "/", Strings.toString(id)));
    }

    function _baseURIRegular() internal view virtual returns(string memory) {
        return _metadataRegular;
    }

    function _baseURISOTY() internal view virtual returns(string memory) {
        return _metadataSOTY;
    }

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }
}