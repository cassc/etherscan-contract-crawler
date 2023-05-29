// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './ERC721Burnable.sol';

/**
 * @title Puppy contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

interface IDogePound {
    function ownerOf(uint256 tokenId) external view  returns (address);
}

contract Puppy is ERC721Burnable {
    using SafeMath for uint256;

    IDogePound public dogePound = IDogePound(0xF4ee95274741437636e748DdAc70818B4ED7d043);

    uint256 public maxToMint;

    string public PROVENANCE_HASH = "";

    uint256 breedIndex = 10000;

    bool public mintIsActive;
    bool public breedByDoggoIsActive;

    address public breedFeeWallet;
    uint256 public breedFeePct;

    mapping (bytes32 => bool) public digestUsed;

    string public constant sname = "Puppy Contract";

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the breed struct used by the contract
    bytes32 public constant BREED_TYPEHASH = keccak256("Breed(address doggoOwner,uint256 doggoId,address dogeOwner,uint256 dogeId,uint256 breedPrice,uint256 deadline)");

    event Mint (uint256 indexed puppyId);
    event ReserveByOwner (uint256 indexed puppyId);

    event BreedByDoggo (uint256 indexed puppyId,
                address indexed doggoOwner,
                uint256 doggoId,
                address indexed dogeOwner,
                uint256 dogeId,
                uint256 breedPrice,
                uint256 breedTime);

    event BreedByOwner (uint256 indexed puppyId,
                address indexed doggoOwner,
                uint256 doggoId,
                address indexed dogeOwner,
                uint256 dogeId,
                uint256 breedPrice,
                uint256 breedTime);

    event BreedModeUpdated (bool breedByDoggoIsActive);

    event BreedFeePctUpdated (uint256 breedFeePct);

    constructor() ERC721("Doge Pound Puppies", "PUPPY") {
        maxToMint = 20;
        mintIsActive = false;
        breedByDoggoIsActive = false;
        breedFeeWallet = 0xeE41417780eB5AD0533105A13C85Eae1991AA10E;
        breedFeePct = 20;
    }

    /**
     * Get the array of token for owner.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            for (uint256 index; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Mint Puppy by Owner
     */
    function breedPuppyByOwner (address doggoOwner,
                                uint256 doggoId,
                                address dogeOwner,
                                uint256 dogeId,
                                uint256 breedPrice) external onlyOwner {
        require(mintIsActive, "Mint is not enable now.");
        require(doggoOwner != address(0), "Invalid doggo address.");
        require(dogeOwner != address(0), "Invalid doge address.");

        _safeMint(doggoOwner, breedIndex);

        emit BreedByOwner (breedIndex,
                    doggoOwner,
                    doggoId,
                    dogeOwner,
                    dogeId,
                    breedPrice,
                    block.timestamp);

        breedIndex = breedIndex + 1;
    }

    /**
     * Mint Puppy by Doggo
     */
    function breedPuppyByDoggo (address doggoOwner,
                                uint256 doggoId,
                                address dogeOwner,
                                uint256 dogeId,
                                uint256 breedPrice,
                                uint256 deadline,
                                uint8 v, bytes32 r, bytes32 s) payable external {
        require(mintIsActive, "Mint is not enable now.");
        require(breedByDoggoIsActive, "Breed is not enable by doggo.");
        require(doggoOwner != address(0) && msg.sender == doggoOwner, "Invalid doggo address.");
        require(dogeOwner != address(0), "Invalid doge address.");
        require(block.timestamp <= deadline, "Passed deadline.");
        require(msg.value >= breedPrice, "Passed deadline.");

        // check sign with signKey
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(sname)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BREED_TYPEHASH, doggoOwner, doggoId, dogeOwner, dogeId, breedPrice, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(!digestUsed[digest], "This signature was already used to breed.");
        require(signatory == owner(), "Puppy::breedPuppyByDoggo: invalid signature");

        _safeMint(doggoOwner, breedIndex);

        emit BreedByDoggo (breedIndex,
                    doggoOwner,
                    doggoId,
                    dogeOwner,
                    dogeId,
                    breedPrice,
                    block.timestamp);

        breedIndex = breedIndex + 1;
        digestUsed[digest] = true;

        uint256 breedFee = breedPrice.mul(breedFeePct).div(100);
        uint256 breedValueForDoge = breedPrice.sub(breedFee);
        if(breedValueForDoge > 0)
            payable(dogeOwner).transfer(breedValueForDoge);
    }

    /**
    * Mint Puppy by OGDoge holders
    */
    function mintPuppy(uint256[] memory ogDogeList) external {
        require(mintIsActive, "Mint is not enable now.");
        require(ogDogeList.length <= maxToMint, "Mint amount is bigger than max limit.");

        for(uint256 i = 0; i < ogDogeList.length; i++) {
            require(msg.sender == dogePound.ownerOf(ogDogeList[i]), "Invalid ogdoge id.");
            require(!exists(ogDogeList[i]), "The puppy already minted.");
            _safeMint(msg.sender, ogDogeList[i]);
            emit Mint(ogDogeList[i]);
        }
    }

    /**
    * Mint Puppy by Owner
    */
    function reservePuppyByOwner(address _to, uint256 _count) external onlyOwner {
        require(mintIsActive, "Mint is not enable now.");
        require(_count <= maxToMint, "Mint count is bigger than maxToMint.");

        uint256 puppyId = breedIndex;

        for(uint256 i = 0; i < _count; i++) {
            _safeMint(_to, puppyId);
            emit ReserveByOwner(puppyId);
            puppyId = puppyId + 1;
        }

        breedIndex = puppyId;
    }

    function reserveBurnedPuppies(address _to, uint256 number) external onlyOwner {
        require(mintIsActive, "Mint is not enable now.");
        require(!exists(number), "The puppy already minted.");

        _safeMint(_to, number);
        emit Mint(number);
    }

    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
     * Set maximum count to mint per once.
     */
    function setMaxToMint(uint256 _maxValue) external onlyOwner {
        maxToMint = _maxValue;
    }

    /*
    * Set provenance once it's calculated
    */
    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }

    /*
    * Pause mint if active, make active if paused
    */
    function setMintState(bool _mintIsActive) external onlyOwner {
        mintIsActive = _mintIsActive;
    }

    /*
    * Set breed mode
    */
    function setBreedMode(bool _breedByDoggoIsActive) external onlyOwner {
        breedByDoggoIsActive = _breedByDoggoIsActive;
        emit BreedModeUpdated(_breedByDoggoIsActive);
    }

    /*
    * Set breed fee percentage
    */
    function setBreedFeePct(uint256 _breedFeePct) external onlyOwner {
        require(_breedFeePct <= 20, 'Breed fee percentage is too much');

        breedFeePct = _breedFeePct;
        emit BreedFeePctUpdated(_breedFeePct);
    }

    function setBreedFeeWallet(address _walletAddress) external onlyOwner {
        breedFeeWallet = _walletAddress;
    }

    function setDogePoundAddr(address _dogePoundAddr) external onlyOwner {
        dogePound = IDogePound(_dogePoundAddr);
    }

    function withdrawFee() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(breedFeeWallet).transfer(balance);
    }
}