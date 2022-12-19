// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface INeonPlexusNft { 
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function mintBatch(address to, uint256[] memory tokenIds) external;
}

contract DiffusionNftSaleV1 is Ownable, ReentrancyGuard {

    // Subtract Final NEON PLEXUS: Override Collection 0xDd782034307ff54C4F0BF2719C9d8e78FCEFDD40
    uint256 public constant OVERRIDE_TOTAL_SUPPLY = 1006; // 1006 (one indexed)
    uint256 public constant DIFFUSION_MAX_SUPPLY = 9000 - OVERRIDE_TOTAL_SUPPLY; // 7994 (one indexed)
    uint256 public constant DIFFUSION_MAX_SUPPLY_INDEX = OVERRIDE_TOTAL_SUPPLY + DIFFUSION_MAX_SUPPLY ; // 9000

    uint256 public constant HOLDER_FREE_MINT_AMOUT = 3; 
    uint256 public constant PUBLIC_FREE_MINT_AMOUT = 5; 

    uint256 public mintLimitPerTx = 90;

    address public overrideNftContract;
    address public diffusionNftContract;

    uint64 public holderFreeMinted;
    uint64 public publicFreeMinted;
    uint64 public airdropFreeMinted; // only if public doesn't complete mint

    uint256 public holderFreeMintStartTime; // See holderMint
    uint256 public publicFreeMintStartTime; // See freeMint

    // uncompressed balances by type
    mapping(uint64 => uint64) fabFreeBalanceByFabId;

    event Minted(address sender, uint256 count);

    constructor(address _overrideNftContract, 
        address _diffusionNftContract, 
        uint256 _publicFreeMintStartTime,
        uint256 _holderFreeMintStartTime) Ownable() ReentrancyGuard() {
        overrideNftContract = _overrideNftContract;
        diffusionNftContract = _diffusionNftContract;
        publicFreeMintStartTime = _publicFreeMintStartTime;
        holderFreeMintStartTime = _holderFreeMintStartTime;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function setMintLimit(uint256 _mintLimitPerTx) external onlyOwner {
        mintLimitPerTx = _mintLimitPerTx;
    }

    function setTimes(uint256 _publicFreeMintStartTime, uint256 _holderFreeMintStartTime) external onlyOwner {
        publicFreeMintStartTime = _publicFreeMintStartTime;
        holderFreeMintStartTime = _holderFreeMintStartTime;
    }

    function setNftContracts(address _overrideNftContract, address _diffusionNftContract) public onlyOwner {
        overrideNftContract = _overrideNftContract;
        diffusionNftContract = _diffusionNftContract;
    }
    
    function fabFreeBalance(uint256 fabId) public view returns (uint256) {
        return fabFreeBalanceByFabId[uint64(fabId)];
    }

    function publicFreeBalance(address who) public view returns (uint256) {
        return INeonPlexusNft(diffusionNftContract).balanceOf(who);
    }
    
    function publicFreeAvailable(address who) public view returns (uint256) {
        return PUBLIC_FREE_MINT_AMOUT - publicFreeBalance(who);
    }

    function holderFreeAvailable(address who) public view returns (uint256) {

        uint256 targetMintIndex = currentMintIndex();

        uint256 fabBalance = INeonPlexusNft(overrideNftContract).balanceOf(who);
        uint256 quantity = 0;

        for (uint256 ownerFabIndex; ownerFabIndex < fabBalance; ++ownerFabIndex) {
            uint256 fabId = INeonPlexusNft(overrideNftContract).tokenOfOwnerByIndex(who, ownerFabIndex);
            uint256 fabIdAvailable = HOLDER_FREE_MINT_AMOUT - fabFreeBalance(fabId);
            uint256 supplyAvailable = DIFFUSION_MAX_SUPPLY_INDEX - targetMintIndex - 1 - quantity; 
            uint256 fabIdQuantity = fabIdAvailable < supplyAvailable ? fabIdAvailable : supplyAvailable; 
            // ignore tx limit (just info for holders)

            if (fabIdQuantity > 0) {
                quantity += fabIdQuantity;
            }
        }
        return quantity;
    }

    function holderFreeMint() external nonReentrant callerIsUser {

        require(
        holderFreeMintStartTime != 0 && block.timestamp >= holderFreeMintStartTime,
        "holder mint has not started yet"
        );

        uint256 targetMintIndex = currentMintIndex();
        require(targetMintIndex <= DIFFUSION_MAX_SUPPLY_INDEX, "Sold out! Sorry!");

        uint256 fabBalance = INeonPlexusNft(overrideNftContract).balanceOf(msg.sender);
        require(fabBalance > 0, "No Fabricants sorry!");

        uint256 quantity = 0;

        for (uint256 ownerFabIndex; ownerFabIndex < fabBalance; ++ownerFabIndex) {
            uint256 fabId = INeonPlexusNft(overrideNftContract).tokenOfOwnerByIndex(msg.sender, ownerFabIndex);
            uint256 fabIdAvailable = HOLDER_FREE_MINT_AMOUT - fabFreeBalance(fabId);
            uint256 supplyAvailable = DIFFUSION_MAX_SUPPLY_INDEX - targetMintIndex - 1 - quantity; 
            uint256 fabIdQuantity = fabIdAvailable < supplyAvailable ? fabIdAvailable : supplyAvailable; // min fabIdAvailable, supplyAvailable

            if (fabIdQuantity > 0) {
                if ((quantity + fabIdQuantity) > mintLimitPerTx) {
                    break;
                }

                holderFreeMinted += uint64(fabIdQuantity);
                fabFreeBalanceByFabId[uint64(fabId)] += uint64(fabIdQuantity);
                quantity += fabIdQuantity;
            }
        }

        require(quantity > 0, "Cannot mint 0");
        require((targetMintIndex - 1 + quantity) <= DIFFUSION_MAX_SUPPLY_INDEX, "Sold out! Sorry!");

        uint256[] memory ids = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            ids[i] = targetMintIndex + i;
        }

        INeonPlexusNft(diffusionNftContract).mintBatch(msg.sender, ids);

        emit Minted(msg.sender, quantity);
    }

    function publicFreeMint(uint256 quantity) external nonReentrant callerIsUser {

        require(
        publicFreeMintStartTime != 0 && block.timestamp >= publicFreeMintStartTime,
        "free mint has not started yet"
        );

        uint256 targetMintIndex = currentMintIndex();
        require(targetMintIndex <= DIFFUSION_MAX_SUPPLY_INDEX, "Sold out! Sorry!");

        uint256 supplyAvailable = DIFFUSION_MAX_SUPPLY_INDEX - targetMintIndex - 1; // 9000 - 1007 - 1
        quantity = quantity < supplyAvailable ? quantity : supplyAvailable;

        require(quantity > 0, "Cannot mint 0");
        require(quantity <= publicFreeAvailable(msg.sender), "addr free limit 5: can not mint this many");

        publicFreeMinted += uint64(quantity);

        uint256[] memory ids = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            ids[i] = targetMintIndex + i;
        }

        INeonPlexusNft(diffusionNftContract).mintBatch(msg.sender, ids);

        emit Minted(msg.sender, quantity);
    }

    // only to complete mint if needed after holder and public mint are complete
    function airdropFreeMint(address who, uint256 quantity) external onlyOwner {

        uint256 targetMintIndex = currentMintIndex();
        require(targetMintIndex <= DIFFUSION_MAX_SUPPLY_INDEX, "Sold out! Sorry!");
        require(quantity > 0, "Cannot mint 0");

        airdropFreeMinted += uint64(quantity);

        uint256[] memory ids = new uint256[](quantity);
        for (uint256 i; i < quantity; ++i) {
            ids[i] = targetMintIndex + i;
        }

        INeonPlexusNft(diffusionNftContract).mintBatch(who, ids);

        emit Minted(who, quantity);
    }

    function currentMintIndex() public view returns (uint256) {
        // Add Final NEON PLEXUS: Override Collection 0xDd782034307ff54C4F0BF2719C9d8e78FCEFDD40
        return totalSupply() + OVERRIDE_TOTAL_SUPPLY + 1;
    }

    function totalSupply() public view returns (uint256) {
        // remaining supply
        return IERC721Enumerable(diffusionNftContract).totalSupply();
    }
}