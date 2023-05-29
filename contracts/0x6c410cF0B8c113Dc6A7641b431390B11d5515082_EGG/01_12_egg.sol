// SPDX-License-Identifier: MIT

//
//          [email protected]@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         Egg Contract (made by @CardilloSamuel)
//         Special thanks to MoonBird contract for the nesting logic

/*

    
    RTFKT Legal Overview [https://rtfkt.com/legaloverview]
    1. RTFKT Platform Terms of Services [Document #1, https://rtfkt.com/tos]
    2. End Use License Terms
    A. Digital Collectible Terms (RTFKT-Owned Content) [Document #2-A, https://rtfkt.com/legal-2A]
    B. Digital Collectible Terms (Third Party Content) [Document #2-B, https://rtfkt.com/legal-2B]
    C. Digital Collectible Limited Commercial Use License Terms (RTFKT-Owned Content) [Document #2-C, https://rtfkt.com/legal-2C]
    D. Digital Collectible Terms [Document #2-D, https://rtfkt.com/legal-2D]
    
    3. Policies or other documentation
    A. RTFKT Privacy Policy [Document #3-A, https://rtfkt.com/privacy]
    B. NFT Issuance and Marketing Policy [Document #3-B, https://rtfkt.com/legal-3B]
    C. Transfer Fees [Document #3C, https://rtfkt.com/legal-3C]
    C. 1. Commercialization Registration [https://rtfkt.typeform.com/to/u671kiRl]
    
    4. General notices
    A. Murakami Short Verbiage – User Experience Notice [Document #X-1, https://rtfkt.com/legal-X1]
*/

// - Clarify if we need to reset data of incubation between transfers (holder locked?)

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "https://github.com/ProjectOpenSea/operator-filter-registry/blob/529cceeda9f5f8e28812c20042cc57626f784718/src/DefaultOperatorFilterer.sol";
import "https://github.com/chiru-labs/ERC721A/blob/2342b592d990a7710faf40fe66cfa1ce61dd2339/contracts/ERC721A.sol";
import "https://github.com/chiru-labs/ERC721A/blob/2342b592d990a7710faf40fe66cfa1ce61dd2339/contracts/extensions/ERC721AQueryable.sol";
import "https://github.com/chiru-labs/ERC721A/blob/2342b592d990a7710faf40fe66cfa1ce61dd2339/contracts/extensions/ERC721ABurnable.sol";

abstract contract HatchedEggInterface {
    function hatchEgg(uint256 tokenId, address owner) public virtual returns(uint256);
}

contract EGG is ERC721A, ERC721ABurnable, ERC721AQueryable, DefaultOperatorFilterer, Ownable {
    constructor(address clonexAddress) ERC721A("Egg", "Egg") {
        mintIsOpen = false;
        incubationIsOpen = false;
        hatchingIsOpen = false;
        clonexContractAddress = clonexAddress;

        normalUri = "ipfs://QmVmpaoWw7zZp53nc5WJMaUGDfa5hD64V26EZS69RXexJk";
    }

    event newEgg(uint256 cloneId, uint256 eggId, address minter);
    event incubationStateChanged(uint256 stateOfIncubation, uint256 tokenId);
    event expelledFromIncubation(uint256 tokenId);
    event eggHatched(uint256 eggId, address hatcherAddress, uint256 incubatedTotal);

    bool public mintIsOpen;
    bool public incubationIsOpen;
    bool public hatchingIsOpen;

    uint256 private incubationTransfer = 1;
    uint256 public MAX_SUPPLY = 20000;

    string normalUri;
    address public clonexContractAddress;
    address hatchedEggAddress;

    mapping (uint256 => bool) public claimedClone;
    mapping (uint256 => uint256) public eggToClone;
    mapping (address => mapping(uint256 => uint256)) incubatedEggs;
    mapping (address => mapping(uint256 => uint256)) incubatedTotal;
    mapping (uint256 => string) customURIs;

    function mint(uint256[] calldata cloneIds) public {
        require(mintIsOpen, "Mint is not open for now");

        uint256 length = cloneIds.length;
        require(_totalMinted() + length <= MAX_SUPPLY, "No remaining supply");

        ERC721A externalToken = ERC721A(clonexContractAddress);

        for(uint256 i = 0; i < length; ++i) {
            require(externalToken.ownerOf(cloneIds[i]) == msg.sender, "You don't own that clone");
            require(!claimedClone[cloneIds[i]], "This clone has been claimed already");

            uint256 currentIndex = _nextTokenId();
            
            claimedClone[cloneIds[i]] = true;
            eggToClone[currentIndex] = cloneIds[i];

            _safeMint(msg.sender, 1); // Minting of the token
            emit newEgg(cloneIds[i], currentIndex, msg.sender);
        }
    }

    function airdropEgg(uint256[] calldata amount, address[] calldata owners) public onlyOwner {
        uint256 amountToMint;
        for (uint256 i = 0; i < amount.length; ++i) {
            amountToMint += amount[i];
        }
        require(_totalMinted() + amountToMint <= MAX_SUPPLY, "No remaining supply");

        for(uint256 i = 0; i < owners.length; ++i) {            
            _safeMint(owners[i], amount[i]); // Minting of the token
        }
    }

    function hatchEgg(uint256 eggId) public returns (uint256) {
        require(hatchingIsOpen, "Hatching has not started");
        require(_exists(eggId), "Egg doesn't exist");
        require(ownerOf(eggId) == msg.sender, "Doesn't own the egg");

        burn(eggId);

        // Just as protection
        if (incubatedEggs[msg.sender][eggId] > 0) {
            incubatedTotal[msg.sender][eggId] += block.timestamp - incubatedEggs[msg.sender][eggId];
            incubatedEggs[msg.sender][eggId] = 0;
        }

        HatchedEggInterface hatchedEggContract = HatchedEggInterface(hatchedEggAddress);
        uint256 mintedId = hatchedEggContract.hatchEgg(eggId, msg.sender);
        
        emit eggHatched(eggId, msg.sender, incubatedTotal[msg.sender][eggId]);
 
        return mintedId; // Return the minted ID
    }

    /////////////////////////////
    // INCUBATION FUNCTIONS    //
    /////////////////////////////

    function incubateEggs(uint256[] calldata eggsIds) public {
        require(incubationIsOpen, "Incubation is currently not available");

        for(uint256 i = 0; i < eggsIds.length; ++i) {
            require(_exists(eggsIds[i]), "Egg doesn't exist");
            require(ownerOf(eggsIds[i]) == msg.sender, "Doesn't own the egg");

            if (incubatedEggs[msg.sender][eggsIds[i]] == 0) {
                incubatedEggs[msg.sender][eggsIds[i]] = block.timestamp;
            } else {
                incubatedTotal[msg.sender][eggsIds[i]] += block.timestamp - incubatedEggs[msg.sender][eggsIds[i]];
                incubatedEggs[msg.sender][eggsIds[i]] = 0;
            }

            emit incubationStateChanged(incubatedEggs[msg.sender][eggsIds[i]], eggsIds[i]);
        }
    }

    function incubatingPeriodByAddress(uint256 eggId, address incubatorAddress) external view returns (bool incubating, uint256 current, uint256 total) {
        if (incubatedEggs[incubatorAddress][eggId] != 0) {
            incubating = true;
            current = block.timestamp - incubatedEggs[incubatorAddress][eggId];
        }
        total = current + incubatedTotal[incubatorAddress][eggId];
    }

    function incubatingPeriod(uint256 eggId) external view returns (bool incubating, uint256 current, uint256 total) {
        if (incubatedEggs[msg.sender][eggId] != 0) {
            incubating = true;
            current = block.timestamp - incubatedEggs[msg.sender][eggId];
        }
        total = current + incubatedTotal[msg.sender][eggId];
    }

    function safeTransferWhileIncubating(address to,  uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "You don't own that egg");
        require(msg.sender != to, "You can't send the egg to yourself");

        incubationTransfer = 2;
        safeTransferFrom(msg.sender, to, tokenId);
        incubationTransfer = 1;

        incubatedTotal[to][tokenId] = incubatedTotal[msg.sender][tokenId];
        incubatedEggs[to][tokenId] = incubatedEggs[msg.sender][tokenId];
        incubatedTotal[msg.sender][tokenId] += block.timestamp - incubatedEggs[msg.sender][tokenId];
        incubatedEggs[msg.sender][tokenId] = 0;
    }

    function _beforeTokenTransfers(address, address, uint256 startTokenId, uint256 quantity) internal view override {
        uint256 tokenId = startTokenId;
        for (uint256 end = tokenId + quantity; tokenId < end; ++tokenId) {
            if(_exists(tokenId)) {
                require(incubatedEggs[ownerOf(tokenId)][tokenId] == 0 || incubationTransfer == 2, "Egg is incubated");
            }
        }
    }

    //////////////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////////////

    // For airdrop post-Mintvial
    function linkCloneToEgg(uint256[] calldata cloneId, uint256[] calldata eggId) public onlyOwner {
        uint256 length = cloneId.length;

        for(uint i = 0; i < length; ++i) {
            require(!claimedClone[cloneId[i]], "This clone is already linked");
            require(eggToClone[eggId[i]] == 0, "This egg is already linked to a clone");
            ERC721A externalToken = ERC721A(clonexContractAddress);
            require(externalToken.ownerOf(cloneId[i]) == ownerOf(eggId[i]), "The clone is not owned by the egg owner");

            claimedClone[cloneId[i]] = true;
            eggToClone[eggId[i]] = cloneId[i];
        }
    }

    function toggleHatching() public onlyOwner {
        hatchingIsOpen = !hatchingIsOpen;
    }

    function toggleIncubation() public onlyOwner {
        incubationIsOpen = !incubationIsOpen;
    }

    function toggleMint() public onlyOwner {
        mintIsOpen = !mintIsOpen;
    }

    function setClonexAddress(address newAddress) public onlyOwner {
        clonexContractAddress = newAddress;
    }

    function setHatchedEggAddress(address newAddress) public onlyOwner {
        hatchedEggAddress = newAddress;
    }

    function setNewTokenURI(uint256 typeOfURI, uint256 tokenId, string calldata newURI) public onlyOwner {
        if(typeOfURI == 0) 
            normalUri = newURI;
        else 
            customURIs[tokenId] = newURI;
    }

    // Emergency function
    function setSupply(uint256 newSupply) public onlyOwner {
		MAX_SUPPLY = newSupply;
	}

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        return (bytes(customURIs[tokenId]).length == 0) ? normalUri : customURIs[tokenId];
    }

    function expelFromIncubation(uint256 tokenId) external onlyOwner {
        address eggOwner = ownerOf(tokenId);

        require(incubatedEggs[eggOwner][tokenId] != 0, "Egg is not incubating");

        incubatedTotal[eggOwner][tokenId] += block.timestamp - incubatedEggs[eggOwner][tokenId];
        incubatedEggs[eggOwner][tokenId] = 0;

        emit incubationStateChanged(incubatedEggs[eggOwner][tokenId], tokenId);
        emit expelledFromIncubation(tokenId);
    }

    function overrideIncubationTransfer(uint256 newValue) public onlyOwner {
        incubationTransfer = newValue;
    }

    /////////////////////////////
    // OPENSEA FILTER REGISTRY 
    /////////////////////////////

    function setApprovalForAll(address operator, bool approved) public override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable override(ERC721A, IERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}