// SPDX-License-Identifier: MIT
/*

                        *                                                    *



                *                 
                                        *
                
      *                                               *

 __   ___  __   ___              ___       ___     __               *
|__) |__  |__) |__     | |\ |     |  |__| |__     /__` |__/ \ / 
|    |___ |    |___    | | \|     |  |  | |___    .__/ |  \  |  

                                               *
                *             
                                                           *
                                    *      
   

   
   *

*/

pragma solidity ^0.8.13;

import {iToken} from "./interfaces/iToken.sol";
import {iSeeder} from "./interfaces/iSeeder.sol";
import {iDescriptorMinimal} from "./interfaces/iDescriptorMinimal.sol";
import {IERC4906} from "./interfaces/IERC4906.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract PepeInTheSky is
    ERC721A,
    IERC4906,
    iToken,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer
{
    /* 


             ___        ___  ___             __   __     __       
    | |\ | |  |  |  /\   |  |__      |\/| | /__` /__` | /  \ |\ | 
    | | \| |  |  | /~~\  |  |___     |  | | .__/ .__/ | \__/ | \| 
                                                                

    */

    iSeeder public seeder;
    iDescriptorMinimal public descriptor;
    mapping(uint256 => iSeeder.Seed) private seeds;
    bool public combineIsOpen = false;

    uint256 public mintPrice = 0.007 ether;
    uint256 public publicMintPrice = 0.007 ether;

    uint256 public maxSupply = 3000;
    uint256 public constant RESERVED_TEAM = 20;

    uint256 public whitelistLimit = 5;
    uint256 public publicLimit = 10;

    using ECDSA for bytes32;
    address public signerAddress;
    string private contractMetadataURI;

    constructor(
        iDescriptorMinimal descriptor_,
        iSeeder seeder_,
        address signer_,
        address payable pepeAddress_,
        string memory contractURI_
    ) ERC721A("PepeInTheSky", "PITS") {
        descriptor = descriptor_;
        seeder = seeder_;
        setSignerAddress(signer_);
        setWithdrawAddress(pepeAddress_);
        setRoyaltyInfo(500);
        setContractMetadataURI(contractURI_);
    }

    /*

     __           __                            __  ___ 
    /  \ |\ | __ /  ` |__|  /\  | |\ |     /\  |__)  |  
    \__/ | \|    \__, |  | /~~\ | | \|    /~~\ |  \  |     based & inspired by Nouns
                                                    
    */

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    // prettier-ignore
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        iSeeder.Seed memory _seed = seeds[tokenId];
        
        if (_seed.altitude == 0 && !_exists(tokenId)) {
            return descriptor.tokenURI(tokenId, _seed, true);
        }

        return descriptor.tokenURI(tokenId, _seed, false);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view returns (string memory) {
        iSeeder.Seed memory _seed = seeds[tokenId];

        if (_seed.altitude == 0 && !_exists(tokenId)) {
            return descriptor.dataURI(tokenId, _seed, true);
        }

        return descriptor.dataURI(tokenId, _seed, false);
    }

    //prettier-ignore
    function tokenSeeds(uint256 tokenId) public view returns (iSeeder.Seed memory) {
        require(_exists(tokenId), "Token: URI query for nonexistent token");
        return seeds[tokenId];
    }

    /**
     * @notice Mint with `tokenId` to the provided `to` address.
     */
    function _mintTo(address to_, uint256 quantity_) internal {
        // Randomness
        uint256 nextTokenId = _nextTokenId();
        for (uint nxt = nextTokenId; nxt <= nextTokenId + quantity_; nxt++) {
            seeds[nxt] = seeder.generateSeed(nxt, quantity_, descriptor);
        }

        // Mint
        _mint(to_, quantity_);
        emit Minted(to_, quantity_);
    }

    // prettier-ignore
    function skylistMint(uint256 quantity_, bytes calldata signature_) external payable isSaleState(SaleState.Whitelist) {
        if (!verifySignature(signature_, "Skylist")) revert IncorrectSignature();
        if (_totalMinted() + quantity_ > (maxSupply - RESERVED_TEAM)) revert SoldOut();
        if (_numberMinted(msg.sender) + quantity_ > whitelistLimit) revert LimitExceed();
        if (msg.value != quantity_ * mintPrice) revert IncorrectPrice();
        if (quantity_ > whitelistLimit) revert LimitExceed();

        _mintTo(msg.sender, quantity_);
    }

    // prettier-ignore
    function publicMint(uint256 quantity_) external payable isSaleState(SaleState.Public) {
        if (_totalMinted() + quantity_ > (maxSupply - RESERVED_TEAM)) revert SoldOut();
        if (_numberMinted(msg.sender) + quantity_ > publicLimit) revert LimitExceed();
        if (msg.value != quantity_ * publicMintPrice) revert IncorrectPrice();
        if (quantity_ > publicLimit) revert LimitExceed();

        _mintTo(msg.sender, quantity_);
    }

    function reserve(address receiver_, uint256 quantity_) external onlyOwner {
        if (_totalMinted() + quantity_ > maxSupply) revert ReservedExceeded();

        _mintTo(receiver_, quantity_);
    }

    /*

     __   __         __          ___                
    /  ` /  \  |\/| |__) | |\ | |__                 
    \__, \__/  |  | |__) | | \| |___    to reach the unknown..


    */

    function combine(
        uint256 mainTokenId_,
        uint256[] memory burnedTokenIds_
    ) external {
        // Owner validation
        if (!combineIsOpen) revert NotOpen();
        if (ownerOf(mainTokenId_) != msg.sender) revert NotOwner();
        for (uint256 i = 0; i < burnedTokenIds_.length; i++) {
            if (ownerOf(burnedTokenIds_[i]) != msg.sender) revert NotOwner();
        }

        // SET mainTokenId_ as the primary
        uint256 newAltitude = seeds[mainTokenId_].altitude;

        // BURN!
        for (uint256 i = 0; i < burnedTokenIds_.length; i++) {
            newAltitude += seeds[burnedTokenIds_[i]].altitude;
            seeds[burnedTokenIds_[i]] = seeder.reachNewAltitude(0);
            _burn(burnedTokenIds_[i]);
            emit MetadataUpdate(burnedTokenIds_[i]);
        }

        // COMBINED!
        seeds[mainTokenId_] = seeder.reachNewAltitude(newAltitude);
        emit MetadataUpdate(mainTokenId_);
    }

    function setOpenToCombine(bool open_) external onlyOwner {
        combineIsOpen = open_;
    }

    /*
          ___       __   ___  __  
    |__| |__  |    |__) |__  |__) 
    |  | |___ |___ |    |___ |  \ 

    */

    //prettier-ignore
    function verifySignature(bytes memory signature_, string memory saleStateName_) internal view returns (bool) {
        return signerAddress ==
            keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    bytes32(abi.encodePacked(msg.sender, saleStateName_))
            )).recover(signature_);
    }

    function numberMinted(address account) external view returns (uint256) {
        return _numberMinted(account);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function contractURI() public view returns (string memory) {
        return contractMetadataURI;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A, IERC721A, ERC2981) returns (bool) {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }

    enum SaleState {
        Closed,
        Whitelist,
        Public
    }
    SaleState public saleState;
    event Minted(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleState saleState);

    /* 

     __             ___  __      __                
    /  \ |  | |\ | |__  |__)    /  \ |\ | |    \ / 
    \__/ |/\| | \| |___ |  \    \__/ | \| |___  |  
                                               

     */
    function setDescriptor(iDescriptorMinimal descriptor_) external onlyOwner {
        descriptor = descriptor_;

        emit DescriptorUpdated(descriptor_);
    }

    function setSeeder(iSeeder seeder_) external onlyOwner {
        seeder = seeder_;

        emit SeederUpdated(seeder_);
    }

    function setSaleState(uint256 saleState_) external onlyOwner {
        saleState = SaleState(saleState_);
        emit SaleStateChanged(saleState);
    }

    modifier isSaleState(SaleState saleState_) {
        if (msg.sender != tx.origin) revert NotUser();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }

    function setSignerAddress(address signerAddress_) public onlyOwner {
        if (signerAddress_ == address(0)) revert ZeroAddress();
        signerAddress = signerAddress_;
    }

    function setContractMetadataURI(
        string memory contractMetadataURI_
    ) public onlyOwner {
        contractMetadataURI = contractMetadataURI_;
    }

    function setWithdrawAddress(
        address payable withdrawAddress_
    ) public onlyOwner {
        if (withdrawAddress_ == address(0)) revert ZeroAddress();
        withdrawAddress = withdrawAddress_;
    }

    function setRoyaltyInfo(uint96 royaltyPercentage_) public onlyOwner {
        if (withdrawAddress == address(0)) revert ZeroAddress();
        _setDefaultRoyalty(withdrawAddress, royaltyPercentage_);
    }

    function setMaxSupply(uint256 maxSupply_) public onlyOwner {
        maxSupply = maxSupply_;
    }

    function setMintPrice(uint256 mintPrice_) public onlyOwner {
        mintPrice = mintPrice_;
    }

    function setPublicMintPrice(uint256 publicMintPrice_) public onlyOwner {
        publicMintPrice = publicMintPrice_;
    }

    function setPublicLimit(uint256 publicLimit_) public onlyOwner {
        publicLimit = publicLimit_;
    }

    //prettier-ignore
    function setWhitelistLimit(uint256 whitelistLimit_) public onlyOwner {
        whitelistLimit = whitelistLimit_;
    }

    address payable public withdrawAddress;

    function withdraw() external onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}(
            ""
        );
        require(success, "Transfer failed.");
    }

    /*
    
     __   __   ___  __       ___  __   __      ___        ___  ___  __  
    /  \ |__) |__  |__)  /\   |  /  \ |__)    |__  | |     |  |__  |__) 
    \__/ |    |___ |  \ /~~\  |  \__/ |  \    |    | |___  |  |___ |  \ 
                                                                    
    */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(
        address operator,
        uint256 tokenId
    )
        public
        payable
        override(ERC721A, IERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*
     ___       __   
    |__  |\ | |  \ .
    |___ | \| |__/ ,

    */
}