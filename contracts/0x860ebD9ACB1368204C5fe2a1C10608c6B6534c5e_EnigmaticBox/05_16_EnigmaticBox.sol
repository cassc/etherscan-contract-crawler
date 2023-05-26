// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "./ERC721A/extensions/ERC721AQueryable.sol";
import "./libs/BitMaps.sol";
import "./libs/BitMaps4.sol";
import "./SSTORE2/SSTORE2.sol";
import "./Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DefaultOperatorFilterer} from "./filter/DefaultOperatorFilterer.sol";

error MaxSupplyReached();
error NotOwnerOfClaim();
error AlreadyClaimed();
error ClaimConditionNotMet();
error FalseInput();
error ImageDataFrozen();
error MaxAllowlist();
error NotAltar();
error BoxOpeningIsClosed();
error ClaimIsDisabled();
error NonUpgradable();
error UpgradesNotActive();

interface IClaimer {
    function nestingPeriod(uint256 tokenId) external view returns (bool nesting, uint256 current, uint256 total);
    function ownerOf(uint256 tokenId) external view returns (address);
}

interface IAltar {
    function batchStartRitual(address to, uint256[] calldata boxTypes) external;
    function startRitual(address to, uint256 boxType) external;
}

contract EnigmaticBox is ERC721AQueryable, Ownable, DefaultOperatorFilterer {
    using BitMaps for BitMaps.BitMap;
    using BitMaps4 for BitMaps4.BitMap4;

    uint256 private claimStart = block.timestamp;

    IClaimer private immutable claimContract;

    uint256 public constant maxPerTx = 10;
    uint256 public constant BATCH_SIZE = 6;
    uint256 public price = 0.1 ether;
    uint256 public constant priceClaimUpgrade = 0.015 ether;

    bool public supplyFrozen;
    uint256 public publicMaxSupply;
    uint256 private reservation;
    bool private reservationMinted;

    uint256 public publicMinted;
    uint256 public claim3Minted;
    uint256 public claim5Minted;
    mapping(address => uint256) private claim5Whitelist;
    bool public claim5Limited = true;

    bool public imageDataFrozen;
    bool public onChainLocked;
    bool private offChainFallback = true;

    bool public upgradesEnabled;
    
    BitMaps.BitMap private claimed;
    mapping(uint256 => uint256) public upgradesClaimed;
    BitMaps4.BitMap4 private boxType;

    mapping(uint256 => address[]) private imageChunks;

    // main collection contract
    IAltar public masonicAltar;
    bool private lockedAltar;

    bool public claimDisabled;
    uint256 private legendariesAirdropped;

    string[] private boxNames = ["Soul Box","Spirit Box","Machina Box","Omen Box","Air Box","Water Box","Alchemy Box","Fire Box","Earth Box","Legendary Box"];
    string private imagePrefix = "data:image/avif;base64,";
    string private baseURI;

    constructor(address claimer, string memory uri) ERC721A("EnigmaticBox", "EBOX") {
        claimContract = IClaimer(claimer);
        baseURI = uri;
    }

    function disableClaim() external onlyOwner {
        claimDisabled = true;
    }

    function addAltar(address addr) external onlyOwner {
        if(lockedAltar) revert();
        masonicAltar = IAltar(addr);
        lockedAltar = true;
    }

    function legendaryMint(address[] calldata addr) external onlyOwner {
        if(legendariesAirdropped>=74) revert();
        uint256 nextId = _nextTokenId();
        for(uint256 i; i < addr.length; ++i) {
            _mint(addr[i], 1);
            boxType.setTo(nextId+i, 9);    
            legendariesAirdropped++;
        }
    }

    function tokenIdToType(uint256 tokenId) external view returns(uint256) {
        return boxType.get(tokenId);
    }

    function claim5AllowlistLeft(address addr) external view returns(uint256) {
        if(_getAux(msg.sender)>=claim5Whitelist[addr]) {
            return 0;
        } else {
            return claim5Whitelist[addr]-_getAux(msg.sender);
        }
    }

    function disableClaim5Limit() external onlyOwner {
        claim5Limited=false;
    }

    function addClaim5Allowlist(address[] calldata addr, uint256 amount) external {
        for (uint256 i; i < addr.length; ++i) {
            claim5Whitelist[addr[i]] = amount;
        }
    }

    function maxSupply() external view returns(uint256) {
        return 10000-2*claim3Minted-4*claim5Minted+publicMaxSupply+reservation;
    }

    function setPublicMaxSupply(uint256 newSupply) external onlyOwner {
        if(supplyFrozen) revert();
        uint256 reducedClaim = 2*claim3Minted+4*claim5Minted-reservation;
        if(newSupply>reducedClaim) revert();
        publicMaxSupply = newSupply;
    }

    function setReservation(uint256 amount) external onlyOwner {
        if(supplyFrozen || reservationMinted) revert();
        uint256 reducedClaim = 2*claim3Minted+4*claim5Minted-publicMaxSupply;
        if(amount>reducedClaim) revert();
        reservation = amount;
    }

    function freezeSupply() external onlyOwner {
        supplyFrozen = true;
    }

    function mintReservation() external onlyOwner {
        if(reservationMinted) revert();
        uint256 nextId = _nextTokenId();
        uint256 newSupply = nextId+reservation;
        for (; nextId < newSupply; ++nextId) {
            boxType.setTo(nextId, 6);
        }
        _mintWrapper(reservation);
        reservationMinted = true;
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) revert();
    }

    function mint(uint256 quantity) external payable {
        unchecked {
            uint256 newPublicSupply = publicMinted + quantity;
            require(newPublicSupply <= publicMaxSupply, "Sold Out");
            require(quantity <= maxPerTx, "Max mints per transaction");
            require(msg.value >= price * quantity, "Ether value sent is incorrect");
            publicMinted = newPublicSupply;
            uint256 nextId = _nextTokenId();
            uint256 newSupply = nextId + quantity;
            for (; nextId < newSupply; ++nextId) {
                boxType.setTo(nextId, 6);
            }
            _mintWrapper(quantity);
        }
    }

    function freezeImageData() external onlyOwner {
        imageDataFrozen = true;
    }

    function deleteImage(uint256 index) external onlyOwner {
        if(imageDataFrozen) revert ImageDataFrozen();
        delete imageChunks[index];
    }

    function uploadImageChunk(uint256 index, bytes calldata chunk) external onlyOwner {
        if(imageDataFrozen) revert ImageDataFrozen();
        imageChunks[index].push(SSTORE2.write(chunk));
    }

    function setImagePrefix(string calldata prefix) external onlyOwner {
        if(imageDataFrozen) revert ImageDataFrozen();
        imagePrefix = prefix;
    }

    function toggleOnChainTokenURI() external onlyOwner {
        if(onChainLocked) revert();
        offChainFallback = !offChainFallback;
    }

    function freezeOnChainTokenURI() external onlyOwner {
        onChainLocked = true;
        offChainFallback = false;
    }

    function setBaseURI(string calldata url) external onlyOwner {
        if(onChainLocked) revert();
        baseURI = url;
    }

    function tokenURI(uint256 tokenId) public view override (ERC721A, IERC721A) returns (string memory) {
        bool isBurned = explicitOwnershipOf(tokenId).burned;
        if (!_exists(tokenId)&&!isBurned) revert URIQueryForNonexistentToken();
        uint256 btype = boxType.get(tokenId);
        uint256 adjustTier = (btype==5)?6:btype==6?5:btype;
        ++adjustTier;
        string memory imageURI = offChainFallback?string.concat(baseURI,_toString(btype)):renderImage(btype);
        return
            string.concat(
                    "data:application/json,",
                    '{"name":"#',
                    _toString(tokenId),
                    '","image":"',
                    imageURI,
                    '","attributes":[{"trait_type":"',
                    (isBurned?'Burned':'Unopened'),
                    '","value":"',
                    boxNames[btype],
                    '"},{"trait_type":"Tier","value":"',
                    _toString(adjustTier),
                    '"}]}'
                //)
            );
    }

    function renderTokenId(uint256 tokenId) external view returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return renderImage(boxType.get(tokenId));
    }

    // render images from chunks (License: MIT)
    function renderImage(uint256 index) public view returns (string memory) 
    {
        bytes memory image;
        address[] storage chunks = imageChunks[index];
        uint256 size;
        uint ptr = 0x20;
        address currentChunk;
        unchecked {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                image := mload(0x40)
            }
            for (uint i = 0; i < chunks.length; i++) {
                currentChunk = chunks[i];
                size = Bytecode.codeSize(currentChunk) - 1;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    extcodecopy(currentChunk, add(image, ptr), 1, size)
                }
                ptr += size;
            }

            // solhint-disable-next-line no-inline-assembly
            assembly {
                mstore(0x40, add(image, and(add(ptr, 0x1f), not(0x1f))))
                mstore(image, sub(ptr, 0x20))
            }
        }
        return string.concat(imagePrefix, Base64.encode(image));
    }

    function tokensClaimable(uint256[] calldata tokenIds) external view returns(bool[] memory) {
        bool[] memory claimable = new bool[](tokenIds.length);
        uint256 currentCutoff = block.timestamp - claimStart;
        for (uint256 i; i < tokenIds.length; ++i) {
            if(!claimed.get(tokenIds[i])) {
                (,uint256 current,) = claimContract.nestingPeriod(tokenIds[i]);
                if(current >= currentCutoff) claimable[i]=true;
            }
        }
        return claimable;
    }

    function _setClaimed(uint256[] calldata tokenIds) internal {
        uint256 currentCutoff = block.timestamp - claimStart;
        for (uint256 i; i < tokenIds.length; ++i) {
            if(claimContract.ownerOf(tokenIds[i])!=msg.sender) revert NotOwnerOfClaim();
            if(claimed.get(tokenIds[i])) revert AlreadyClaimed();
            (,uint256 current,) = claimContract.nestingPeriod(tokenIds[i]);
            if(current < currentCutoff) revert ClaimConditionNotMet();
            claimed.set(tokenIds[i]);
        }
    }

    function claim(uint256[] calldata tokenIds) external payable {
        if(claimDisabled) revert ClaimIsDisabled();
        _setClaimed(tokenIds);
        uint256 upgradeAmount = msg.value/priceClaimUpgrade;
        if(upgradeAmount>tokenIds.length) revert FalseInput();
        uint256 nextId = _nextTokenId();
        for (uint256 i; i < upgradeAmount; ++i) {
            boxType.setTo(nextId, 1);
            ++nextId;
        }
        _mintWrapper(tokenIds.length);
    }

    function claimTypes(uint256[] calldata tokenIds, uint256 type1, uint256 type2, uint256 type3) external payable {
        if(claimDisabled) revert ClaimIsDisabled();
        uint256 newT2Supply = claim3Minted+type2;
        uint256 newT3Supply = claim5Minted+type3;
        if(newT2Supply>800 || newT3Supply>300) revert MaxSupplyReached();
        claim3Minted = newT2Supply;
        claim5Minted = newT3Supply;
        _setClaimed(tokenIds);
        if(tokenIds.length != type1+type2*3+type3*5) revert FalseInput();
        uint256 nextId = _nextTokenId();
        _mintWrapper(type1+type2+type3);
        for (uint256 i; i < type2; ++i) {
            boxType.setTo(nextId, 7);
            ++nextId;
        }
        for (uint256 i; i < type3; ++i) {
            boxType.setTo(nextId, 8);
            ++nextId;
        }
        uint256 upgradeAmount = msg.value/priceClaimUpgrade;
        for (uint256 i; i < upgradeAmount; ++i) {
            boxType.setTo(nextId, 1);
            ++nextId;
        }
        if(type3>0 && claim5Limited) {
            uint256 newC5Minted = uint256(_getAux(msg.sender))+type3;
            if(newC5Minted > claim5Whitelist[msg.sender]) revert MaxAllowlist();
            _setAux(msg.sender,uint64(newC5Minted));
        }
        
    }

    function _mintWrapper(uint256 numToMint) internal {
        uint256 numBatches = numToMint / BATCH_SIZE;
        for (uint256 i; i < numBatches; ++i) {
        _mint(msg.sender, BATCH_SIZE);
        }
        if (numToMint % BATCH_SIZE > 0) {
        _mint(msg.sender, numToMint % BATCH_SIZE);
        }
    }

    function burn(uint256 tokenId) external {
        if(!lockedAltar) revert BoxOpeningIsClosed();
        _burn(tokenId, true);
        masonicAltar.startRitual(msg.sender, boxType.get(tokenId));
    }

    function batchBurn(uint256[] calldata tokenIds) external {
        if(!lockedAltar) revert BoxOpeningIsClosed();
        uint256[] memory types = new uint256[](tokenIds.length);
        for (uint256 i; i < tokenIds.length; ++i) {
            _burn(tokenIds[i], true);
            types[i] = boxType.get(tokenIds[i]);
        }
        masonicAltar.batchStartRitual(msg.sender, types);
    }

    function toggleUpgrading() external onlyOwner {
        upgradesEnabled = !upgradesEnabled;
    }

    function upgradeBoxes(uint256[] calldata tokenIds, uint256[] calldata amounts, uint256[] calldata claimIds) external {
        if(!upgradesEnabled) revert UpgradesNotActive();
        uint256 amount;
        for(uint256 i; i < tokenIds.length; ++i) {
            uint256 boxLevelUp = boxType.get(tokenIds[i])+amounts[i];
            amount+=amounts[i];
            if(boxLevelUp>5) revert NonUpgradable();
            boxType.setTo(tokenIds[i],boxLevelUp);
        }
        uint256 spent;
        for(uint256 i; i < claimIds.length; ++i) {
                (,,uint256 total) = claimContract.nestingPeriod(claimIds[i]);
                uint256 months = total/2592000-upgradesClaimed[claimIds[i]];
                if(months == 0) continue;
                if(claimContract.ownerOf(claimIds[i])!=msg.sender) revert NotOwnerOfClaim();
                uint256 newSpent = months+spent;
                if(newSpent==amount) {
                    upgradesClaimed[claimIds[i]] += months;
                    spent = newSpent;
                    break;
                } else if(newSpent<amount) {
                    upgradesClaimed[claimIds[i]] += months;
                    spent = newSpent;
                } else {
                    upgradesClaimed[claimIds[i]] += amount-spent;
                    spent = amount;
                    break;
                }
        }
        if(spent<amount) revert NonUpgradable();

    }

    function upgradeBox(uint256 tokenId, uint256 amount, uint256[] calldata claimIds) public {
        if(!upgradesEnabled) revert UpgradesNotActive();
        uint256 boxLevelUp = boxType.get(tokenId)+amount;
        if(boxLevelUp>5) revert NonUpgradable();
        boxType.setTo(tokenId,boxLevelUp);
        uint256 spent;
        for(uint256 i; i < claimIds.length; ++i) {
                (,,uint256 total) = claimContract.nestingPeriod(claimIds[i]);
                uint256 months = total/2592000-upgradesClaimed[claimIds[i]];
                if(months == 0) continue;
                if(claimContract.ownerOf(claimIds[i])!=msg.sender) revert NotOwnerOfClaim();
                uint256 newSpent = months+spent;
                if(newSpent==amount) {
                    upgradesClaimed[claimIds[i]] += months;
                    spent = newSpent;
                    break;
                } else if(newSpent<amount) {
                    upgradesClaimed[claimIds[i]] += months;
                    spent = newSpent;
                } else {
                    upgradesClaimed[claimIds[i]] += amount-spent;
                    spent = amount;
                    break;
                }
        }
        if(spent<amount) revert NonUpgradable();
    }

    function upgradesAvailable(uint256[] calldata tokenIds) external view returns(uint256[] memory) {
        uint256[] memory available = new uint256[](tokenIds.length);
        for(uint256 i; i < tokenIds.length; ++i) {
                (,,uint256 total) = claimContract.nestingPeriod(tokenIds[i]);
                uint256 months = total/2592000-upgradesClaimed[tokenIds[i]];
                available[i] = months;
        }
        return available;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override(ERC721A, IERC721A) onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

}