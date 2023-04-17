// SPDX-License-Identifier: GPL-3.0
// REMILIA COLLECTIVE

pragma solidity ^0.8.4;

import "solady/src/utils/SafeTransferLib.sol";
import "solady/src/utils/LibString.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BonklerNFT is ERC721, Ownable {
    using LibString for *;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev The starting `tokenId`.
     */
    uint256 public constant START_TOKEN_ID = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev The base URI.
     */
    string internal __baseURI;

    /**
     * @dev The Bonkler auction contract.
     */
    address internal _minter;

    /**
     * @dev The next `tokenId` to be minted.
     */
    uint32 public nextTokenId;

    /**
     * @dev Total number of Bonklers redeemed (burned).
     */
    uint32 public totalRedeemed;

    /**
     * @dev Whether the minter is permanently locked.
     */
    bool public minterLocked;

    /**
     * @dev Whether minting is permanently locked.
     */
    bool public mintLocked;

    /**
     * @dev Whether the base URI is permanently locked.
     */
    bool public baseURILocked;

    /**
     * @dev Mapping of `tokenId` to shares (amount of ETH stored in each Bonkler).
     */
    mapping(uint256 => uint256) internal _tokenShares;

    /**
     * @dev Mapping of `tokenId` to the generation hash for each Bonkler.
     */
    mapping(uint256 => uint256) internal _tokenGenerationHash;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CONSTRUCTOR                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    constructor() ERC721("Bonkler", "BNKLR") {
        nextTokenId = uint32(START_TOKEN_ID);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              PUBLIC / EXTERNAL VIEW FUNCTIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev ERC721 override to return the token URI for `tokenId`.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory result)
    {
        require(_exists(tokenId), "Token does not exist.");

        result = __baseURI;
        if (bytes(result).length != 0) {
            result = result.replace("{id}", LibString.toString(tokenId));
            result = result.replace("{shares}", LibString.toString(_tokenShares[tokenId]));
            result = result.replace("{hash}", LibString.toString(_tokenGenerationHash[tokenId]));
        }
    }

    /**
     * @dev Returns the amount of ETH stored in `tokenId`.
     */
    function getBonklerShares(uint256 tokenId) public view returns (uint256) {
        return _tokenShares[tokenId];
    }

    /**
     * @dev Returns the generation hash for `tokenId`.
     */
    function getBonklerHash(uint256 tokenId) external view returns (uint256) {
        return _tokenGenerationHash[tokenId];
    }

    /**
     * @dev Returns the total number of Bonklers minted.
     */
    function totalMinted() external view returns (uint256) {
        return nextTokenId - START_TOKEN_ID;
    }

    /**
     * @dev Returns the total number of Bonklers in existence.
     */
    function totalSupply() external view returns (uint256) {
        return nextTokenId - START_TOKEN_ID - totalRedeemed;
    }

    /**
     * @dev Returns if the `tokenId` exists.
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns if the `tokenIds` exist.
     */
    function exist(uint256[] memory tokenIds) external view returns (bool[] memory results) {
        uint256 n = tokenIds.length;
        results = new bool[](n);
        for (uint256 i; i < n; ++i) {
            results[i] = _ownerOf(tokenIds[i]) != address(0);
        }
    }

    /**
     * @dev Returns an array of all the `tokenIds` held by `owner`.
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory tokenIds) {
        uint256 n = balanceOf(owner);
        tokenIds = new uint256[](n);
        uint256 end = nextTokenId;
        uint256 o;
        for (uint256 i = START_TOKEN_ID; i < end && o < n; ++i) {
            if (_ownerOf(i) == owner) tokenIds[o++] = i;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              PUBLIC / EXTERNAL WRITE FUNCTIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Allows a Bonkler holder to burn a Bonkler,
     * and redeem the ETH inside it.
     */
    function redeemBonkler(uint256 tokenId) external {
        ++totalRedeemed;

        uint256 shares = _tokenShares[tokenId];

        // Once a token has been burned, calling `ownerOf` will revert.
        // The `tokenId` for each newly minted token will only increase,
        // `tokenId`s can never get reused.
        require(ownerOf(tokenId) == msg.sender, "Must own Bonkler to redeem it.");

        // Burns the token without checking ownership.
        // We have already checked the ownership above.
        _burn(tokenId);

        IBonklerAuction(_minter).emitBonklerRedeemedEvent(tokenId);

        // Sends the ETH to the token owner.
        SafeTransferLib.forceSafeTransferETH(msg.sender, shares);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   MINTER WRITE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Allows the minter to transfer `tokenId` to address `to`,
     * while accepting a ETH deposit to be stored inside the Bonkler,
     * to be redeemed if it is burned.
     */
    function transferPurchasedBonkler(uint256 tokenId, address to) external payable onlyMinter {
        _tokenShares[tokenId] = msg.value;
        _transfer(msg.sender, to, tokenId);
    }

    /**
     * @dev Allows the minter to mint a Bonkler to itself, with `generationHash`.
     */
    function mint(uint256 generationHash) external payable onlyMinter returns (uint256 tokenId) {
        require(!mintLocked, "Locked.");
        tokenId = nextTokenId++;
        _mint(msg.sender, tokenId); // Mint the sender 1 token.
        _tokenGenerationHash[tokenId] = generationHash;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   ADMIN WRITE FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Sets the minter.
     */
    function setMinter(address minter) external onlyOwner {
        require(!minterLocked, "Locked.");
        _minter = minter;
    }

    /**
     * @dev Sets the base URI.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        require(!baseURILocked, "Locked.");
        __baseURI = baseURI;
    }

    /**
     * @dev Permanently locks the minter from being changed.
     */
    function lockMinter() external onlyOwner {
        minterLocked = true;
    }

    /**
     * @dev Permanently locks minting.
     */
    function lockMint() external onlyOwner {
        mintLocked = true;
    }

    /**
     * @dev Permanently locks the base URI.
     */
    function lockBaseURI() external onlyOwner {
        baseURILocked = true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                 INTERNAL / PRIVATE HELPERS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * @dev Guards a function such that only the minter is authorized to call it.
     */
    modifier onlyMinter() virtual {
        require(msg.sender == _minter, "Unauthorized minter.");
        _;
    }
}

interface IBonklerAuction {
    /**
     * @dev For emitting an event when a Bonkler has been redeemed.
     */
    function emitBonklerRedeemedEvent(uint256 bonklerId) external payable;
}