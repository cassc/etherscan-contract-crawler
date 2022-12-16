// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title The WrappedPresent contract
 * @notice A contract that represents a random gift in the Santa.fm Gift Exchange
 */
contract WrappedPresent is Ownable, ERC721 {
    using Strings for string;

    // Table used for encoding the metadata in base64
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // Designated Minter Role
    address minter;
    // URL for the image returned in the token's metadata
    string internal tokenImage;
    // Counter for tokens minted
    uint256 public totalTokensMinted;
    // Counter for tokens burned
    uint256 public totalTokensBurned;

    // Mapping of burned tokens by address
    mapping(address => uint256[]) public burnedBy;
    // Mapping of of whether or not a token has been burned
    mapping(uint256 => bool) public burned;

    // Error for when an account doesn't own a token when burning
    error OnlyOwnerCanBurnThroughMinter();
    // Event for burning tokens
    event Burn(uint256 tokenId, address account);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _tokenImage
    ) Ownable() ERC721(_name, _symbol) {
        tokenImage = _tokenImage;
    }

    /*
     * Owner Functions
     */

    /**
     * @notice Function that sets the image to be returned in Token URI
     * @param _tokenImage - The tokenId we're checking
     */
    function setTokenImage(string memory _tokenImage) public onlyOwner {
        tokenImage = _tokenImage;
    }

    /**
     * @notice Function that updates the designated minter
     * @param _minter - The address of the new minter
     */
    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    /**
     * @notice Function that transfers a tokenId
     * @param from - The sender of the transfer
     * @param to - The receiver of the transfer
     * @param tokenId - TokenID of the token being transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /*
     * Minter Functions
     */

    /**
     * @notice Function that mints an NFT. Can only be called by `minter`
     * @param to - The address that receives the minted NFT
     */
    function simpleMint(address to) public onlyMinter {
        // increment number of tokens minted
        totalTokensMinted += 1;

        // mint the token to the address
        _mint(to, totalTokensMinted);
    }

    /**
     * @notice Function that burns a present
     * @param tokenId - The tokenId to burn
     * @param account - The account that owns the token
     *
     * @dev [WARNING!] Be sure that when using this function, the `account` actually owns `tokenId`
     */
    function burn(uint256 tokenId, address account) public onlyMinter {
        // Since _burn does not check approval for burning, we have to make sure that the
        // designated Minter only passes the correct owner of the token as `account`
        if (ownerOf(tokenId) != account) revert OnlyOwnerCanBurnThroughMinter();

        // burn the token.
        _burn(tokenId);

        // keep track of burnings
        totalTokensBurned += 1;
        burnedBy[account].push(tokenId);
        burned[tokenId] = true;

        // emit our event
        emit Burn(tokenId, account);
    }

    /*
     * URI Functions
     */

    /**
     * @notice Function that returns the Contract URI
     */
    function contractURI() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encodeByte64(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Santa.FM NFT Gift Exchange", ',
                                    '"description": "Santa.fm Presents are NFTs from the NFT Gift Exchange pool. Add a NFT gift to the pool and receive a NFT Present in return that you open on Christmas morning.", ',
                                    '"external_link": "https://santa.fm",'
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Function that returns the URI for a token
     * @param id - Token ID we're referencing
     */
    function tokenURI(uint256 id) public view override returns (string memory) {
        // Fail if token hasn't been minted
        require(id <= totalTokensMinted);

        // Fail if token has been burned
        require(!burned[id]);

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encodeByte64(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "Wrapped Present #',
                                    toString(id),
                                    '", ',
                                    '"description": "Wrapped Presents are given to you when you add an NFT to the Gift Dexchange. Use this present to redeem a random gift on Christmas Day!", ',
                                    '"image": "',
                                    tokenImage,
                                    '", "attributes": [{"trait_type": "Gift", "value": "Wrapped Present"}, {"trait_type": "Year", "value": "2022" }]}'
                                )
                            )
                        )
                    )
                )
            );
    }

    /**
     * @notice Function that encodes byte64
     * @param data - data to be encoded
     */
    function encodeByte64(
        bytes memory data
    ) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    /**
     * @notice Function that converts numbers to strings
     * @param value - number to be converted
     */
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /*
     * Modifiers
     */

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }
}