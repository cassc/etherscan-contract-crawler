pragma solidity ^0.8.0;
/**
* @title KingFrog contract
* @dev Extends ERC721Enumerable Non-Fungible Token Standard basic implementation
*/

/**
*  SPDX-License-Identifier: UNLICENSED
*/

/**
           (')-=-(')
         __(   "   )__
        / _/'-----'\_ \
     ___\\ \\     // //___
     >____)/_\---/_\(____<
    ribbit motherclucker
*/

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

interface IDucksV6 {
	function getTraits(uint tokenId) external view returns (uint8, uint8, uint8, uint8, uint8, uint8);
    function ownerOf(uint tokenId) external view returns (address);
}

interface ISupShopV6 {
	function burnItem(address burnTokenAddress, uint256 typeId, uint256 amount) external;
}

contract KingFrogsV6 is ERC721EnumerableUpgradeable, OwnableUpgradeable {
    uint256 public constant MAX_FROGS_PUBLIC = 10000;
    uint256 public constant MAX_FROGS_CLAIMED = 10001;
    uint256 public constant NUM_SUPERS = 10;
    uint256 public constant NUM_TRAITS = 6;

    bool public saleIsActive;
    bool public claimIsActive;
    
    uint16[][NUM_TRAITS] internal traitProbs; 
    uint8[][NUM_TRAITS] internal traitAliases;
    uint8[NUM_TRAITS][MAX_FROGS_PUBLIC + MAX_FROGS_CLAIMED] internal frogTraits;
    uint8[NUM_TRAITS] internal PUBLIC_TRAIT_OFFETS;
    uint16[NUM_SUPERS + 1] internal superStock;
    IDucksV6 public SupDucks;
    string internal baseURI;
    uint256 internal nonce;
    uint256 public START;
    uint256 public numPublicMinted;
    uint256 public deployedBlock;
    address internal splitterAddress;

    struct Duck {
        uint8 background;
        uint8 skin;
        uint8 clothes;
        uint8 hat;
        uint8 mouth;
        uint8 eyes;
    }

    /**
    * Public mint !
    */
    function mintFrog(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Frog");
        require(numberOfTokens <= 20, "Can only mint 20 tokens at a time");
        require(numPublicMinted + numberOfTokens <= MAX_FROGS_PUBLIC, "Purchase would exceed max supply of Frogs");
        require(getCurrentPrice() * numberOfTokens <= msg.value, "Ether value sent is not correct");

        for(uint i = 0; i < numberOfTokens; i++) {
            uint seed = uint(keccak256(abi.encodePacked(nonce, block.difficulty, block.timestamp, msg.sender)));
            addTraits(seed, numPublicMinted);
            _safeMint(msg.sender, numPublicMinted);
            numPublicMinted++;
        }
    }

    function determineTrait(uint8 traitType, uint seed) internal view returns (uint8){
        uint8 i = uint8(uint(keccak256(abi.encodePacked(nonce, seed++))) % traitProbs[traitType].length);
        return uint(keccak256(abi.encodePacked(nonce, seed))) % 10000 <= uint(traitProbs[traitType][i]) ? i : traitAliases[traitType][i];
    }

    function addTraits(uint seed, uint tokenId) internal {
        for(uint8 i = 0; i < NUM_TRAITS - 1; i++){            
            nonce++;
            frogTraits[tokenId][i] = determineTrait(i, seed) + PUBLIC_TRAIT_OFFETS[i];
        }
        frogTraits[tokenId][5] = uint8(uint(keccak256(abi.encodePacked(tokenId, seed))) % 24);

        uint16 roll = uint16(seed % (MAX_FROGS_PUBLIC - numPublicMinted));
        for(uint8 i = 0; i < NUM_SUPERS + 1; i++){
           if(roll < superStock[i]){
                superStock[i]--;
                if(i > 0){
                    for(uint8 j = 0; j < NUM_TRAITS; j++){            
                        frogTraits[tokenId][j] = uint8(110 + i);
                    }
                }
                return;
            }
            roll -= superStock[i];
        }
        revert('lilypad');
    }

    function claimFrogs(uint[] memory duckTokenIds) external {
        require(claimIsActive, "Claim must be active to claim Frog");
        require(duckTokenIds.length <= 20, "Limit 20 tokenIds");
        for(uint i = 0; i < duckTokenIds.length; i++){
            uint claimedIndex = duckTokenIds[i] / 256;
            uint claimedBitShift = duckTokenIds[i] % 256;
            require((claimed[claimedIndex] >> claimedBitShift) & uint256(1) == 0, "frog already claimed");
            require(msg.sender == SupDucks.ownerOf(duckTokenIds[i]), "You don't own this duck");
            _safeMint(msg.sender, duckTokenIds[i] + 10000);
            claimed[claimedIndex] = claimed[claimedIndex] | (uint256(1) << claimedBitShift);
        }
    }

    /**
     * Scoop hand from sky
     */
    function grabTadpoles(uint numberOfTokens) external onlyOwner payable{
        for(uint i = 0; i < numberOfTokens; i++) {
            uint seed = uint(keccak256(abi.encodePacked(nonce, block.difficulty, block.timestamp, msg.sender)));
            addTraits(seed, numPublicMinted);
            _safeMint(msg.sender, numPublicMinted);
            numPublicMinted++;
        }
    }

    function pauseSale() external onlyOwner {
        require(saleIsActive == true, "sale is already paused");
        saleIsActive = false;
    }

    function startSale() external onlyOwner {
        require(saleIsActive == false, "sale is already started");
        START = block.timestamp;
        saleIsActive = true;
    }

    function flipClaimState() external onlyOwner {
        claimIsActive = !claimIsActive;
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        payable(splitterAddress).transfer(balance);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function setSupDucks(address supAddy) external onlyOwner {
		SupDucks = IDucksV6(supAddy);
	}

    function setSplitterAddress(address splitter) external onlyOwner {
        splitterAddress = splitter;
    }

    function getTraits(uint tokenId) public view returns (uint, uint, uint, uint, uint, uint){    
        require(_exists(tokenId), "ERC721Metadata: trait query for nonexistent token");
        if(tokenId >= MAX_FROGS_PUBLIC){
            Duck memory duck;
            (duck.background, duck.skin, duck.clothes, duck.hat, duck.mouth, duck.eyes) = SupDucks.getTraits(tokenId - 10000);
            return(
                duck.background,
                duck.skin,
                duck.hat,
                determineTrait(3, uint8(uint(keccak256(abi.encodePacked(tokenId, deployedBlock))))),
                duck.eyes,
                uint8(uint(keccak256(abi.encodePacked(tokenId, deployedBlock))) % 24)
            );
        }else{
            return (
                frogTraits[tokenId][0], 
                frogTraits[tokenId][1], 
                frogTraits[tokenId][2], 
                frogTraits[tokenId][3],
                frogTraits[tokenId][4], 
                frogTraits[tokenId][5]
            );
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function getCurrentPrice() view public returns (uint){
        if((block.timestamp - START) >= 6 hours){
            return 0.01 ether;
        }else{
            return (6 hours - (block.timestamp - START)) * 0.99 ether / 6 hours + .01 ether;
        }
    }

    function exists(uint tokenId) view external returns (bool){
        return _exists(tokenId);
    }

    function getClaimIsActive() view external returns (bool){
        return claimIsActive;
    }

    function initialize(
    uint16[] memory background_p, uint8[] memory background_a,
    uint16[] memory skin_p, uint8[] memory skin_a,
    uint16[] memory hats_p, uint8[] memory hats_a,
    uint16[] memory mouth_p, uint8[] memory mouth_a,
    uint16[] memory eyes_p, uint8[] memory eyes_a) initializer public {
        __ERC721_init("KingFrogs", "KF");
        __ERC721Enumerable_init();
        __Ownable_init();

        /**
        * Some frog gene magic
        */
        traitProbs[0] = background_p;
        traitProbs[1] = skin_p;
        traitProbs[2] = hats_p;
        traitProbs[3] = mouth_p;
        traitProbs[4] = eyes_p;
        traitAliases[0] = background_a;
        traitAliases[1] = skin_a;
        traitAliases[2] = hats_a;
        traitAliases[3] = mouth_a;
        traitAliases[4] = eyes_a;

        saleIsActive = false;
        claimIsActive = false;
        nonce = 42;

        PUBLIC_TRAIT_OFFETS = [
            16,
            18,
            38,
            0,
            27,
            0
        ];
        superStock = [uint16(MAX_FROGS_PUBLIC - NUM_SUPERS), 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
        splitterAddress = 0xD28DBD19B93b6CC55D85dEbe9d93644097Fed773;
        deployedBlock = block.number;
        setBaseURI("https://api.supducks.com/metadata/");
     }

    uint8[20000] public anim;
    ISupShopV6 public SupShop;
    bool public canAnimate;

    function animateFrog(uint tokenId, uint8 animId) external {
        require(ownerOf(tokenId) == msg.sender, "not your frog bud");
        require(canAnimate, "animations closed");
        require(anim[tokenId] == 0, "frog is already animated");
        (uint256 trait, , , , , ) = getTraits(tokenId);
        require(trait < 100, "no supers");
        SupShop.burnItem(msg.sender, animId, 1);
        anim[tokenId] = animId + 1;
    }

    function flipAnimateState() external onlyOwner{
		canAnimate = !canAnimate;
	}

    function setSupShop(address SupAddy) external onlyOwner{
		SupShop = ISupShopV6(SupAddy);
	}

    address public Toad;

    function burnForToads(uint tokenId) external {
        require(msg.sender == Toad, "Unauthorized");
        _burn(tokenId);
    }

    // @notice Permanently deletes a frog
    function burn(uint tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Unauthorized");
        _burn(tokenId);
    }

    function setToad(address ToadAddy) external onlyOwner{
		Toad = ToadAddy;
	}

    function getTrait(uint frogTokenId, uint traitType) external view returns (uint8){
        require(_exists(frogTokenId), "ERC721Metadata: trait query for nonexistent token");
        if(frogTokenId >= MAX_FROGS_PUBLIC){
            uint8[6] memory traitsOfFrog; 
            (traitsOfFrog[0], traitsOfFrog[1], , traitsOfFrog[2], , traitsOfFrog[4]) = SupDucks.getTraits(frogTokenId - 10000);
            traitsOfFrog[3] = determineTrait(3, uint8(uint(keccak256(abi.encodePacked(frogTokenId, deployedBlock)))));
            return traitsOfFrog[traitType];
        }else{
            return frogTraits[frogTokenId][traitType];
        }
    }

    uint256[40] public claimed; // bitfields

    function setClaimed(uint256[40] calldata newClaimedBitfields) external onlyOwner {
        claimed = newClaimedBitfields;
    }

    function isClaimed(uint256 duckTokenId) public view returns (bool){
        uint claimedIndex = duckTokenId / 256;
        uint claimedBitShift = duckTokenId % 256;
        return (claimed[claimedIndex] >> claimedBitShift) & uint256(1) == 1;
    }
}