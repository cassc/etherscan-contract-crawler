// //SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ERC2981ContractWideRoyalties.sol";
import "./Utils.sol";
import "./ERC721Tradable.sol";

/**************                                                                                             
                                                                                                                                                                                                                                     




                                                                
                                ████████████████                                
                                ██            ██                                
                           ▐████████████████████████▌                           
                         ▐██                        ▐██                         
                       ██                              ██                       
                       ██                              ██                       
                       ██                              ██                       
                       ██       ████▌                  ██                       
                       ██       ████▌       ████▌      ██                       
                       ██                              ██                       
                       ██                              ██                       
                       ██          ██       ██         ██                       
                       ██            ███████           ██
                       ██                              ██                       
                         ▐██                        ▐██            
                            ▐███████████████████████▌                         
                                ██            ██
                  █████  ▐████████████████████████████▌  █████                
                ██     ██                              ██     ██  
              ██       ██                              ██       ██             
              ██       ██                              ██       ██            
           ▐██       ██                                  ██▌      ██▌           
                                                                                
     ▄▄▄▄▄   ▄▄▄  ▄▄▄▄    ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄ ▄▄▄  ▄▄▄▄▄▄   ▄▄▄▄ ▄▄▄▄▄▄    ▄▄▄▄     
    █     █ █   █▀    █▄█▀   ▐█  █   █   █  ▀▄█▌     ██▀    █       ██▀    ▐█   
   █▌ ▀▀  ██  ▄█▌ ██▌  █   ████    ▄██      ▐██   ▀▀██   █  █  ▐██   ██  ▀▀█▄   
   █  ▀▀  █▌  ▀▀▌      ██     █▌     █   ██  █   ▀▀▀█▌  ▄▄  ██      █▌  ▀   █▌  
   ▀█▄▄▄▄█▀█▄▄▄█▀█▄▄▄██▀▀██▄▄█▀█▄██▄███▄█▀█▄▀▀█▄▄▄▄▄█▀██▀█▄███▄▄▄▄▄███▄▄▄▄██▀   
                                                                                





******************/

// Interface that all the data blocks exported from figma fulfill
interface ImageDataBlock {
    // Provide a renderable SVG string at the given slot
    function getData(uint256 slot) external pure returns (bytes memory);

    // Provide a human readable name at the given slot
    function getLabel(uint256 slot) external pure returns (string memory);
}

// ERC20 used for the 'withdrawERC20' just-in-case function, there is no actual erc20 involved here.
interface IERC20 {
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract Blockheads is ERC721Tradable, ERC2981ContractWideRoyalties {
    event BlockheadReconfigured(uint256 tokenId);

    // Max there will ever be available
    uint256 public constant totalAvailable = 10000;
    // currentlyAvailable for releasing in batches
    uint256 public currentlyAvailable = 1;
    uint256 public mintCost = 0.05 ether;
    uint256 public nextTokenId = 1; // 1, for friendship
    bool public mintingEnabled = false;

    /**
    Attributes can be referenced by an index into the labels and image data
    the xxxIndex(uint256) functions will return what index that particular trait should be for a token.  It can be
    used to find image data or labels via the blocks of data exported from figma at the bottom.
    It default to a random value, but can be swapped and overridden using the maps below.
     */

    // Override mappings for each attribute.
    // If there is an override we use that, otherwise we fall back to `initialValueFor`
    // Since all values are initialized to 0, we need a flag to know if we've actually set
    // the override.
    struct Overrides {
        // Storing uint32s is cheaper and should be enough for representing all options for each slot
        uint32 background;
        uint32 body;
        uint32 arms;
        uint32 head;
        uint32 face;
        uint32 headwear;
        bool backgroundOverridden;
        bool bodyOverridden;
        bool armsOverridden;
        bool headOverridden;
        bool faceOverridden;
        bool headwearOverridden;
    }

    // If we store the profession override in the struct above it bumps it over the size limit for a single slot and makes
    // a few of the swap calls ~50% more expensive to call
    struct ProfessionOverride {
        uint32 profession;
        bool overridden;
    }

    // Storing 1 big mapping instead of different mappings for everything makes successive
    // swaps much cheaper since we don't need to call the expensive random function
    mapping(uint256 => Overrides) public overrides;
    mapping(uint256 => ProfessionOverride) public professionOverrides;
    mapping(uint256 => string) public nameOverrides;
    // Birth registry is a mapping of taken names so each blockhead has a unique name.
    mapping(string => bool) birthRegistry;

    // All the data blocks are deployed to separate contracts because its too big to put all this data in one contract.
    // They're deployed separately and referenced here, to be used with the ImageDataBlock interface.
    address backgroundDataBlock;
    address bodyDataBlock;
    address armsDataBlock;
    address headDataBlock;
    address faceDataBlock;
    address headwearDataBlock;

    // Constructor requires the proxy for opensea, and all the data blocks
    constructor(
        address proxyRegistryAddress,
        address _backgroundDataBlock,
        address _bodyDataBlock,
        address _armsDataBlock,
        address _headDataBlock,
        address _faceDataBlock,
        address _headwearDataBlock
    ) ERC721Tradable("Blockheads", "BLOK", proxyRegistryAddress) {
        // 10% royalties for ERC2981.  Not sure if anyone supports this yet.
        _setRoyalties(msg.sender, 1000);
        backgroundDataBlock = _backgroundDataBlock;
        bodyDataBlock = _bodyDataBlock;
        armsDataBlock = _armsDataBlock;
        headDataBlock = _headDataBlock;
        faceDataBlock = _faceDataBlock;
        headwearDataBlock = _headwearDataBlock;
    }

    // Mint a single blockhead
    function mint() public payable {
        require(mintingEnabled);
        require(msg.value >= mintCost, "Save up your quarters");
        require(nextTokenId <= currentlyAvailable, "Batch Sold Out");
        require(nextTokenId <= totalAvailable, "Sold out");
        _safeMint(msg.sender, nextTokenId);
        nextTokenId++;
    }

    // Mint 5 for the price of 4
    function buy4get1free() public payable {
        require(mintingEnabled);
        // Ensure they've paid for 4
        require(msg.value >= mintCost * 4, "Save up your quarters");
        require(nextTokenId + 5 < totalAvailable, "Sold out");
        require(nextTokenId + 5 <= currentlyAvailable, "Batch Sold Out");
        // But give them 5
        for (uint256 i = 0; i < 5; i++) {
            _safeMint(msg.sender, nextTokenId);
            nextTokenId++;
        }
    }

    function setMintingEnabled(bool _enabled) public onlyOwner {
        mintingEnabled = _enabled;
    }

    function setCurrentlyAvailable(uint256 available) public onlyOwner {
        require(available > nextTokenId);
        require(available <= totalAvailable);
        currentlyAvailable = available;
    }

    // Allow owners to update the mint cost if needed
    function setMintCost(uint256 newCost) public onlyOwner {
        mintCost = newCost;
    }

    // Withdraw balance to the owners
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawToContract() external onlyOwner {
        // This forwards all available gas. Be sure to check the return value!
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(address tokenContract) external onlyOwner {
        IERC20 tc = IERC20(tokenContract);
        tc.transfer(owner(), tc.balanceOf(address(this)));
    }

    //
    // xxxIndex functions will return the current index of this tokens property.
    // If there is an override we'll use that otherwise we'll fall back to the pseudorandom `initialValueFor`.
    //

    function backgroundIndex(uint256 tokenId) public view returns (uint32) {
        if (overrides[tokenId].backgroundOverridden) {
            return overrides[tokenId].background;
        }
        return initialValueFor(tokenId, "bg");
    }

    function bodyIndex(uint256 tokenId) public view returns (uint32) {
        if (overrides[tokenId].bodyOverridden) {
            return overrides[tokenId].body;
        }
        return initialValueFor(tokenId, "body");
    }

    function armsIndex(uint256 tokenId) public view returns (uint32) {
        if (overrides[tokenId].armsOverridden) {
            return overrides[tokenId].arms;
        }
        return initialValueFor(tokenId, "arms");
    }

    function headIndex(uint256 tokenId) public view returns (uint32) {
        if (overrides[tokenId].headOverridden) {
            return overrides[tokenId].head;
        }
        return initialValueFor(tokenId, "head");
    }

    function faceIndex(uint256 tokenId) public view returns (uint32) {
        if (overrides[tokenId].faceOverridden) {
            return overrides[tokenId].face;
        }
        return initialValueFor(tokenId, "face");
    }

    function headwearIndex(uint256 tokenId) public view returns (uint32) {
        if (overrides[tokenId].headwearOverridden) {
            return overrides[tokenId].headwear;
        }
        return initialValueFor(tokenId, "headwear");
    }

    function professionIndex(uint256 tokenId) public view returns (uint32) {
        if (professionOverrides[tokenId].overridden) {
            return professionOverrides[tokenId].profession;
        }
        return initialValueFor(tokenId, "profession");
    }

    function random(bytes memory input) internal pure returns (uint256) {
        return uint256(keccak256(input));
    }

    // The randomly selected initial value for this token.
    // Can be overridden by overrides.
    function initialValueFor(uint256 tokenId, string memory keyPrefix)
        private
        pure
        returns (uint32)
    {
        // It's ok to downcast this since its just random numbers and its downcast predictably
        return uint32(random(abi.encodePacked(keyPrefix, tokenId)));
    }

    modifier ownsBoth(uint256 token1, uint256 token2) {
        require(ownerOf(token1) == msg.sender);
        require(ownerOf(token2) == msg.sender);
        _;
    }

    function swapParts(
        uint256 token1,
        uint256 token2,
        bool background,
        bool body,
        bool arms,
        bool heads,
        bool faces,
        bool headwear
    ) public ownsBoth(token1, token2) {
        require(background || body || arms || heads || faces || headwear);
        if (background) {
            uint32 newBG1 = backgroundIndex(token2);
            uint32 newBG2 = backgroundIndex(token1);
            overrides[token1].background = newBG1;
            overrides[token2].background = newBG2;
            overrides[token1].backgroundOverridden = true;
            overrides[token2].backgroundOverridden = true;
        }
        if (body) {
            uint32 newBody1 = bodyIndex(token2);
            uint32 newBody2 = bodyIndex(token1);
            overrides[token1].body = newBody1;
            overrides[token2].body = newBody2;
            overrides[token1].bodyOverridden = true;
            overrides[token2].bodyOverridden = true;
        }
        if (arms) {
            uint32 newArm1 = armsIndex(token2);
            uint32 newArm2 = armsIndex(token1);
            overrides[token1].arms = newArm1;
            overrides[token2].arms = newArm2;
            overrides[token1].armsOverridden = true;
            overrides[token2].armsOverridden = true;
        }
        if (heads) {
            uint32 newHead1 = headIndex(token2);
            uint32 newHead2 = headIndex(token1);
            overrides[token1].head = newHead1;
            overrides[token2].head = newHead2;
            overrides[token1].headOverridden = true;
            overrides[token2].headOverridden = true;
        }
        if (faces) {
            uint32 newFace1 = faceIndex(token2);
            uint32 newFace2 = faceIndex(token1);
            overrides[token1].face = newFace1;
            overrides[token2].face = newFace2;
            overrides[token1].faceOverridden = true;
            overrides[token2].faceOverridden = true;
        }
        if (headwear) {
            uint32 newHeadwear1 = headwearIndex(token2);
            uint32 newHeadwear2 = headwearIndex(token1);
            overrides[token1].headwear = newHeadwear1;
            overrides[token2].headwear = newHeadwear2;
            overrides[token1].headwearOverridden = true;
            overrides[token2].headwearOverridden = true;
        }
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function swapProfessions(uint256 token1, uint256 token2)
        public
        ownsBoth(token1, token2)
    {
        uint32 newProfession1 = professionIndex(token2);
        uint32 newProfession2 = professionIndex(token1);
        professionOverrides[token1].profession = newProfession1;
        professionOverrides[token2].profession = newProfession2;
        professionOverrides[token1].overridden = true;
        professionOverrides[token2].overridden = true;
        emit BlockheadReconfigured(token1);
        emit BlockheadReconfigured(token2);
    }

    function setName(uint256 tokenId, string memory name) public {
        require(ownerOf(tokenId) == msg.sender);
        require(bytes(name).length > 0);
        require(!birthRegistry[name]);
        birthRegistry[nameOverrides[tokenId]] = false;
        nameOverrides[tokenId] = name;
        birthRegistry[name] = true;
        emit BlockheadReconfigured(tokenId);
    }

    function getName(uint256 tokenId) public view returns (string memory) {
        if (bytes(nameOverrides[tokenId]).length > 0) {
            return nameOverrides[tokenId];
        }
        return string(abi.encodePacked("Blockhead #", Utils.toString(tokenId)));
    }

    function getProfession(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        // Storing these here saves a good amount of gas by not needing to create storage slots for them
        // Since you can't really do constants for string arrays
        string[71] memory professions = [
            "Firefighter",
            "Teacher",
            "Solidity Engineer",
            "Architect",
            "Philosopher",
            "Dog Trainer",
            "Pilot",
            "Spy",
            "Astronaut",
            "Groundskeeper",
            "Doctor",
            "Investor",
            "Curator",
            "Chef",
            "Artist",
            "Police Officer",
            "Fisherman",
            "Nurse",
            "Botanist",
            "Influencer",
            "Graphic Designer",
            "Businessman",
            "Podcaster",
            "Racecar Driver",
            "Midwife",
            "Plumber",
            "Product Manager",
            "Founder",
            "Comedian",
            "Super Hero",
            "Scuba Diver",
            "Photographer",
            "Yoga Instructor",
            "Carpenter",
            "Singer",
            "Therapist",
            "Mycologist",
            "Forest Ranger",
            "Mail Carrier",
            "Secret Agent",
            "DJ",
            "Magician",
            "Dog Whisperer",
            "Zookeeper",
            "Shaman",
            "Curator",
            "Bus Driver",
            "Construction Worker",
            "Train Conductor",
            "Archeologist",
            "Hockey Player",
            "Basketball Player",
            "Baseball Player",
            "Golfer",
            "Scientist",
            "Florist",
            "Farmer",
            "Ski Instructor",
            "Pet Groomer",
            "Concierge",
            "Dentist",
            "Billionaire",
            "Psychoanalyst",
            "Mayor",
            "Retired",
            "Dogecoin Investor",
            "Psychic",
            "Uber Driver",
            "Game Designer",
            "President",
            "Vice President"
        ];
        return professions[professionIndex(tokenId) % professions.length];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes
            memory svg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 25 25' width='500' height='500'>";
        svg = abi.encodePacked(svg, getBgData(tokenId));
        svg = abi.encodePacked(svg, getBodyData(tokenId));
        svg = abi.encodePacked(svg, getArmsData(tokenId));
        svg = abi.encodePacked(svg, getHeadData(tokenId));
        svg = abi.encodePacked(svg, getFaceData(tokenId));
        svg = abi.encodePacked(svg, getHeadwearData(tokenId));
        svg = abi.encodePacked(svg, "</svg>");
        // Need to break up the json generation into 2 encodePackeds to avoid stack too deep errors
        bytes memory jsonPt1 = abi.encodePacked(
            '{"name": "',
            getName(tokenId),
            '", "description": "Blockheads", "image": "data:image/svg+xml;base64,',
            Utils.base64Encode(svg),
            '", "attributes": [{"trait_type": "Background", "value": "',
            getBgLabel(tokenId),
            '"}, ',
            '{"trait_type": "Profession", "value": "',
            getProfession(tokenId),
            '"}, '
        );
        string memory json = Utils.base64Encode(
            abi.encodePacked(
                jsonPt1,
                '{"trait_type": "Body", "value": "',
                getBodyLabel(tokenId),
                '"}, ',
                '{"trait_type": "Arms", "value": "',
                getArmsLabel(tokenId),
                '"}, ',
                '{"trait_type": "Head", "value": "',
                getHeadLabel(tokenId),
                '"}, ',
                '{"trait_type": "Face", "value": "',
                getFaceLabel(tokenId),
                '"}, ',
                '{"trait_type": "Headwear", "value": "',
                getHeadwearLabel(tokenId),
                '"}]}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function getBgData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock bgData = ImageDataBlock(backgroundDataBlock);
        return bgData.getData(backgroundIndex(tokenId));
    }

    function getBodyData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock bodyData = ImageDataBlock(bodyDataBlock);
        return bodyData.getData(bodyIndex(tokenId));
    }

    function getArmsData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock armsData = ImageDataBlock(armsDataBlock);
        return armsData.getData(armsIndex(tokenId));
    }

    function getHeadData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock headData = ImageDataBlock(headDataBlock);
        return headData.getData(headIndex(tokenId));
    }

    function getFaceData(uint256 tokenId) public view returns (bytes memory) {
        ImageDataBlock faceData = ImageDataBlock(faceDataBlock);
        return faceData.getData(faceIndex(tokenId));
    }

    function getHeadwearData(uint256 tokenId)
        public
        view
        returns (bytes memory)
    {
        ImageDataBlock dataBlock = ImageDataBlock(headwearDataBlock);
        return dataBlock.getData(headwearIndex(tokenId));
    }

    function getBgLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock bgData = ImageDataBlock(backgroundDataBlock);
        return bgData.getLabel(backgroundIndex(tokenId));
    }

    function getBodyLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock bodyData = ImageDataBlock(bodyDataBlock);
        return bodyData.getLabel(bodyIndex(tokenId));
    }

    function getArmsLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock armsData = ImageDataBlock(armsDataBlock);
        return armsData.getLabel(armsIndex(tokenId));
    }

    function getHeadLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock headData = ImageDataBlock(headDataBlock);
        return headData.getLabel(headIndex(tokenId));
    }

    function getFaceLabel(uint256 tokenId) public view returns (string memory) {
        ImageDataBlock faceData = ImageDataBlock(faceDataBlock);
        return faceData.getLabel(faceIndex(tokenId));
    }

    function getHeadwearLabel(uint256 tokenId)
        public
        view
        returns (string memory)
    {
        ImageDataBlock dataBlock = ImageDataBlock(headwearDataBlock);
        return dataBlock.getLabel(headwearIndex(tokenId));
    }

    function isMintInBox(uint256 tokenId) public view returns (bool) {
        Overrides memory o = overrides[tokenId];
        if (
            o.backgroundOverridden ||
            o.bodyOverridden ||
            o.armsOverridden ||
            o.headOverridden ||
            o.faceOverridden ||
            o.headwearOverridden
        ) {
            return false;
        }
        return true;
    }

    function setBackgroundDataBlockAddress(address newAddr) public onlyOwner {
        backgroundDataBlock = newAddr;
    }

    function setBodyDataBlockAddress(address newAddr) public onlyOwner {
        bodyDataBlock = newAddr;
    }

    function setHeadDataBlockAddress(address newAddr) public onlyOwner {
        headDataBlock = newAddr;
    }

    function setFaceDataBlockAddress(address newAddr) public onlyOwner {
        faceDataBlock = newAddr;
    }

    function setArmsDataBlockAddress(address newAddr) public onlyOwner {
        armsDataBlock = newAddr;
    }

    function setHeadwearDataBlockAddress(address newAddr) public onlyOwner {
        headwearDataBlock = newAddr;
    }

    function setRoyalties(address newRoyaltiesAddr) public onlyOwner {
        _setRoyalties(newRoyaltiesAddr, 1000);
    }
}