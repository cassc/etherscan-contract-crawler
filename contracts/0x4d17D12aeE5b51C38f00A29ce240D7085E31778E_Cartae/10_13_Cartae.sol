/*
    ᴅɪɪᴅ.ᴇᴛʜ ᴘʀᴇsᴇɴᴛs
     ██████╗ █████╗ ██████╗ ████████╗ █████╗ ███████╗
    ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝
    ██║     ███████║██████╔╝   ██║   ███████║█████╗  
    ██║     ██╔══██║██╔══██╗   ██║   ██╔══██║██╔══╝  
    ╚██████╗██║  ██║██║  ██║   ██║   ██║  ██║███████╗
     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/Base64.sol";
import "./libraries/SSTORE2.sol";

/**
 * @title Cartae
 * @author diid.eth
 * @notice A contract for dropping card packs of on-chain ERC1155s, randomized on-chain
 * 
 * gm! If you're reading this far... thanks! This is Cartae, a contract built specifically for doing on-chain drops of various trading card packs. It's setup to store metadata highly efficiently through SSTORE2, and then mint that metadata as randomized editions with varying supply. All of this is randomized on-chain with minimal opportities for MEV extraction (although if it gets to that point, I'll be excited).
 * 
 * Since the project will ideally be ongoing, it's setup for a decent amount of variation. That being said, I wanted to keep it as close to a traditional TCG drop as possible. So, while prices, supplies, and pack sizes might vary between drops, they are NOT expected to vary within a single drop. Each drop is intended to sell out at a single price.
 * There's no scaling allowlist or auction here. Just a single allowlist phase (obviously can be set per drop) at a single price. Nothing else. Ever.
 * 
 * What you can change are things like: per-address mint allocation, per-pack price, and the number of cards per pack. Plenty to customize per drop.
 * 
 * This was tested extensively:
 * ----------------------|----------|----------|----------|----------
 * File                  |  % Stmts | % Branch |  % Funcs |  % Lines
 * ----------------------|----------|----------|----------|----------
 *  contracts/           |      100 |    72.37 |      100 |      100
 *   Cartae.sol          |      100 |    72.37 |      100 |      100
 *  contracts/libraries/ |       85 |       50 |      100 |      100
 *   Base64.sol          |    85.71 |       50 |      100 |      100
 *   Bytecode.sol        |       80 |       50 |      100 |      100
 *   SSTORE2.sol         |      100 |       50 |      100 |      100
 * ----------------------|----------|----------|----------|----------
 * All files             |    96.34 |    69.32 |      100 |      100
 * ----------------------|----------|----------|----------|----------
 * (those missing branches are onlyOwner statements. I'm a fan of tests but I'm too lazy for that)
 * 
 * If you need to find me, you can @ diid.eth. 0xdiid, diid, or diid.art on socials
 */
contract Cartae is ERC1155, Ownable {
    uint public allowlistStartTime;
    uint public publicStartTime;

    /**
     * @notice the number of editions minted in one pack
     */
    uint public packSize = 4;

    /**
     * @notice the price for one pack of `packSize` editions
     */
    uint public price = .04 ether;

    /**
     * @notice the number of packs a given address is allowed to mint in public sale
     */
    uint public packsPerAddress = 1;

    /**
     * @notice a mapping of addresses to number of packs they are allowed to mint
     */
    mapping(address => uint) public allowlist;

    mapping(address => uint) private _mintedPacks;
    address[] private _mintedAddresses;
    address[] private _allowlistAddresses;
    uint256[] private _availableCards;
    bool private _saleActive = false;
    uint private _nextTokenId = 1;

    struct Token {
        string metadata;
        string mimeType;
        address[] chunks;
        bool locked;
    }

    /**
     * @notice The mapping that contains the token data for a given edition
     */
    mapping(uint256 => Token) public tokenData;

    constructor() ERC1155("cartae") {}

    /*
    --------------------------
        METADATA FUNCTIONS
    --------------------------
    */

    /**
     * @notice updates the token `tokenId` if data exists
     * 
     * @param tokenId the token id to update
     * @param image The image data, split into bytes of max len 24576 (EVM contract limit)
     * @param metadata The string metadata for the token, expressed as a JSON with no opening or closing bracket, e.g. `"name": "hello!","description": "world!"`
     * @param mimeType The mime type for `image`
     */
    function updateToken(
            uint256 tokenId,
            bytes[] calldata image,
            string calldata metadata,
            string calldata mimeType
    ) public onlyOwner {
        require(!tokenData[tokenId].locked, "Token is already locked.");

        if (bytes(metadata).length != 0) {
            tokenData[tokenId].metadata = metadata;
        }

        if (bytes(mimeType).length != 0) {
            tokenData[tokenId].mimeType = mimeType;
        }

        if (image.length != 0) {
            delete tokenData[tokenId].chunks;

            for (uint8 i = 0; i < image.length;) {
                tokenData[tokenId].chunks.push(SSTORE2.write(image[i]));

                unchecked { i++; }
            }
        }
    }

    /**
     *  @notice Creates a token with `metadata` of type `mimeType` and image `image`.
     * 
     *  @param image The image data, split into bytes of max len 24576 (EVM contract limit)
     *  @param metadata The string metadata for the token, expressed as a JSON with no opening or closing bracket, e.g. `"name": "hello!","description": "world!"`
     *  @param mimeType The mime type for `image`
     */
    function createToken(
        bytes[] calldata image,
        string calldata metadata,
        string calldata mimeType,
        uint editionCount
    ) external onlyOwner {
        // This pushes to the available cards array,
        // which will be pulled from at mint.
        for (uint i = 0; i < editionCount;) {
            _availableCards.push(_nextTokenId);
            unchecked { i++; }
        }

        // we shouldn't be adding tokens that folks can mint immediately,
        // so just double check that we're not live.
        _saleActive = false;

        updateToken(_nextTokenId, image, metadata, mimeType);

        // save token id for the next card
        unchecked {
            _nextTokenId++;
        }
    }

    /**
     *  @notice Appends chunks of binary data to the chunks for a given token. If your image won't fit in a single "mint" transaction, you can use this to add data to it.
     *  @param tokenId The token to add data to
     *  @param chunks The chunks of data to add, max length for each individual chunk is 24576 bytes (EVM contract limit)
     */
    function appendChunks(
        uint256 tokenId,
        bytes[] calldata chunks
    ) external onlyOwner {
        require(!tokenData[tokenId].locked, "Token is already locked.");

        for (uint i = 0; i < chunks.length;) {
            tokenData[tokenId].chunks.push(SSTORE2.write(chunks[i]));

            unchecked { i++; }
        }
    }

    /**
     * @notice locks all token metadata permanently.
     */
    function lockAll() external onlyOwner {
        for (uint i = 0; i < _nextTokenId;) {
            tokenData[i].locked = true;

            unchecked { i++; }
        }
    }

    /**
     * @notice what are you doing here? this is an internal function!
     * @dev decomposes the binary image data and packs that in a valid JSON alongside the given metadata and mime type
     * 
     * @param tokenId the token id to pack
     */
    function _pack(uint256 tokenId) internal view returns (string memory) {
        // prefix the image type with the URI prefix and mime type
        string memory image = string(
            abi.encodePacked(
                "data:",
                tokenData[tokenId].mimeType,
                ";base64,"
            )
        );

        // start by assembling all of the chunks in memory
        bytes memory data;
        for (uint8 i = 0; i < tokenData[tokenId].chunks.length; i++) {
            data = abi.encodePacked(
                data,
                SSTORE2.read(tokenData[tokenId].chunks[i])
            );
        }

        // base64 encode and append the image data!
        image = string(
            abi.encodePacked(
                image,
                Base64.encode(data)
            )
        );

        return image;
    }

    /**
     * @notice Returns the data URI for a given token
     * 
     * @param tokenId the token id to fetch metadata for
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenData[tokenId].chunks.length != 0, "Token metadata doesn't exist here");

        return string(
            abi.encodePacked(
                'data:application/json;utf8,{',
                tokenData[tokenId].metadata,
                ',"image":"',
                _pack(tokenId),
                '"}'
            )
        );
    }

    /*
    --------------------------
      END METADATA FUNCTIONS
    --------------------------
    */

    /*
    --------------------------
          MINT FUNCTIONS
    --------------------------
    */

    /**
     * @dev helper function to mint a pack of randomized tokens. Assumes mint compliance.
     * 
     * @param packs the number of packs to mint, will mint `packSize` x packs editions
     */
    function _mintPacks(uint packs) internal {
        uint[] memory tokensToMint = new uint[](packSize * packs);
        uint[] memory mintCount = new uint[](packSize * packs);
        for (uint i = 0; i < packSize * packs;) {
            // randomizes based on the block timestamp,
            // the sender (so 2 folks in the same block
            // aren't getting the same numbers), and the
            // available cards (so 1 person submitting twice)
            // in the same block isn't getting the same numbers.
            // hashed and coverted to int, then modulo'd down to a
            // properly indexed index.
            uint256 randomIndex = uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        msg.sender,
                        _availableCards.length
                    )
                )
            ) % (_availableCards.length);

            // add to the arrays we'll pass into _mintbatch later
            tokensToMint[i] = _availableCards[randomIndex];
            mintCount[i] = 1;

            // we don't care about order here, so we can just replace
            // the card with the last one. If randomIndex is the last index
            // it'll just replace with itself and then pop which is equally
            // as valid. No reason to add a check for every mint there.
            _availableCards[randomIndex] = _availableCards[_availableCards.length - 1];
            _availableCards.pop();

            unchecked { i++; }
        }

        // mint the tokens as a batch
        _mintBatch(msg.sender, tokensToMint, mintCount, "");
    }

    /**
     * @notice mints editions based on the value provided, should send number of packs to mint * mint price
     * 
     * Overall, this is far from the most gas-efficient way to do things here, but it is relatively foolproof which is more important to me. The usage of a single function for everything is * chefs kiss *
     */
    function mint() external payable {
        // check a few REALLY basic things
        require(saleActive() == true, "Sale is not active!");
        require(msg.value % price == 0, "Invalid price.");

        // the number of packs requested to be minted is based
        // on the amount of ETH sent to this function. Give that
        // a real basic check first.
        uint packs = msg.value / price;
        require(remainingPacks() >= packs, "Not enough packs left!");

        // fetch the mint allocation
        uint alSpots = allowlist[msg.sender];
        uint publicSpots = 0;

        uint mintedPacks = _mintedPacks[msg.sender];
        
        // if we're in the allowlist phase, keep public allocation at 0
        if (allowlistSaleActive() == false) {
            publicSpots = packsPerAddress - mintedPacks;
        }

        // double check that they CAN mint this many packs
        require(
            alSpots + publicSpots >= packs,
            "You can't mint this many packs!"
        );

        // add to _mintedAddresses if needed. This ensures
        // that we can reset the public mint allocation between
        // drops (or in the middle of a drop, if need be)
        if (mintedPacks == 0) {
            _mintedAddresses.push(msg.sender);
        }

        uint publicSpotsMinted = publicSpots;
        // if we didn't mint all of our public spots
        if (packs < publicSpots) {
            // only count the ones we did mint
            publicSpotsMinted = packs;

        // if we did mint all of them
        } else {
            // update our allowlist allocation accordingly
            allowlist[msg.sender] -= packs - publicSpots;
        }

        // and finally write that update to the public spots mapping
        _mintedPacks[msg.sender] = publicSpotsMinted + mintedPacks;

        // the sauce. It's so little in this giant function.
        // but this is where all of the fun stuff happens
        _mintPacks(packs);
    }

    /*
    --------------------------
        END MINT FUNCTIONS
    --------------------------
    */

    /*
    --------------------------
           START ADMIN
    --------------------------
    */
    /**
     * @notice immediately starts the public sale (no allowlist)
     */
    function startPublicSale() external onlyOwner {
        publicStartTime = block.timestamp;
        allowlistStartTime = block.timestamp;
        _saleActive = true;
    }

    /**
     * @notice starts the allowlist sale (signed AL spot required)
     */
    function startAllowlistSale() external onlyOwner {
        publicStartTime = 0;
        allowlistStartTime = block.timestamp;
        _saleActive = true;
    }

    /**
     * @notice disables the sale, leaving the allowlist status the same
     */
    function pauseSale() external onlyOwner {
        _saleActive = false;
    }

    /**
     * @notice resumes the sale, leaving the allowlist status the same
     */
    function resumeSale() external onlyOwner {
        _saleActive = true;
    }

    /**
     * @notice sets the start time for public sale
     * 
     * @param start the start time
     */
    function setPublicStartTime(uint start) external onlyOwner {
        publicStartTime = start;
    }

    /**
     * @notice sets the start time for allowlist sale
     * 
     * @param start the start time
     */
    function setAllowlistStartTime(uint start) external onlyOwner {
        allowlistStartTime = start;
    }

    /**
     * @notice sets a new per-pack price
     * 
     * @param _price the new price to set
     */
    function setPrice(uint _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice resets the allowlist. All addresses on the allowlist will be set to 0 available mints.
     */
    function resetAllowlist() public onlyOwner {
        for (uint i = 0; i < _allowlistAddresses.length;) {
            allowlist[_allowlistAddresses[i]] = 0;

            unchecked { i++; }
        }

        delete _allowlistAddresses;
    }

    /**
     * @notice resets the number of tokens a given address has minted. If the public sale is active, this address will be allowed to mint `packsPerAddress` packs again
     */
    function resetMintCounts() public onlyOwner {
        for (uint i = 0; i < _mintedAddresses.length;) {
            _mintedPacks[_mintedAddresses[i]] = 0;

            unchecked { i++; }
        }

        delete _mintedAddresses;
    }

    /**
     * @notice sets allocation per address for public mint. Does not affect allowlist mints.
     * 
     * @param packs the number of packs per address you wish to allocate
     */
    function setPacksPerAddress(uint packs) public onlyOwner {
        packsPerAddress = packs;
    }

    /**
     * @notice adds to the allowlist. Will add to the count if a given address is already on the allowlist
     * 
     * @param addresses a list of addresses to add to the allowlist
     * @param count the number of packs a given address can mint. Must be equal in size to `addresses`
     */
    function appendAllowlist(address[] calldata addresses, uint[] calldata count) public onlyOwner {
        require(addresses.length == count.length, "Array mismatch.");

        for (uint i = 0; i < addresses.length;) {
            if (allowlist[addresses[i]] == 0) {
                _allowlistAddresses.push(addresses[i]);
            }
            allowlist[addresses[i]] += count[i];

            unchecked { i++; }
        }
    }

    /**
     * @notice resets the existing allowlist and sets it based on the parameters provided
     * 
     * @param addresses a list of addresses to add to the allowlist
     * @param count the number of packs a given address can mint. Must be equal in size to `addresses`
     */
    function setAllowlist(address[] calldata addresses, uint[] calldata count) public onlyOwner {
        require(addresses.length == count.length, "Array mismatch.");

        resetAllowlist();

        for (uint i = 0; i < addresses.length;) {
            _allowlistAddresses.push(addresses[i]);
            allowlist[addresses[i]] += count[i];

            unchecked { i++; }
        }
    }

    /**
     * @notice sets up the mint in one go
     * 
     * @param _price the price of a single pack
     * @param _publicStartTime the start time for public sale
     * @param _allowlistStartTime the start time for the allowlist sale
     * @param allowlistAddresses A list of addresses to put on the allowlist
     * @param allowlistMintCount The number of packs matched to the address. Must be equal in size with `allowlistAddresses`
     */
    function initMint(uint _price, uint _publicStartTime, uint _allowlistStartTime, address[] calldata allowlistAddresses, uint[] calldata allowlistMintCount) external onlyOwner {
        require(allowlistAddresses.length == allowlistMintCount.length, "Allowlist size mismatch");

        publicStartTime = _publicStartTime;
        allowlistStartTime = _allowlistStartTime;
        price = _price;
        _saleActive = true;

        resetMintCounts();
        setAllowlist(allowlistAddresses, allowlistMintCount);
    }

    /**
     * @notice withdraw to the owner
     */
    function withdraw() external onlyOwner {
        (bool s,) = owner().call{value: (address(this).balance)}("");
        require(s, "Withdraw failed.");
    }

    /*
    --------------------------
            END ADMIN
    --------------------------
    */

    /*
    --------------------------
            BEGIN INFO
    --------------------------
    */

    /**
     * @notice the number of packs available to mint
     */
    function remainingPacks() public view returns (uint) {
        return _availableCards.length / packSize;
    }

    /**
     * @notice gives the allocation, both allowlist and public, for a given address.
     * 
     * @param minter the address to check allocation for
     * 
     * @return uint the allocation for the provided address
     */
    function allocation(address minter) external view returns (uint) {
        if (saleActive() == false) return 0;

        uint alSpots = allowlist[minter];
        uint publicSpots = 0;
        
        if (allowlistSaleActive() == false) {
            publicSpots = packsPerAddress - _mintedPacks[minter];
        }

        return alSpots + publicSpots;
    }

    function _publicSaleActive() internal view returns (bool) {
        return block.timestamp >= publicStartTime && publicStartTime != 0;
    }

    function _allowlistSaleActive() internal view returns (bool) {
        return block.timestamp >= allowlistStartTime && allowlistStartTime != 0;
    }

    function allowlistSaleActive() public view returns (bool) {
        return _allowlistSaleActive() && !_publicSaleActive();
    }

    function saleActive() public view returns (bool) {
        return _saleActive && (_allowlistSaleActive() || _publicSaleActive());
    }

    /*
    --------------------------
            END INFO
    --------------------------
    */
}

// diid wuz here