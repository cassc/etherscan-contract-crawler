// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1155.sol";


// EulerBeats are generative visual & audio art pieces. The recipe and instructions to re-create the visualization and music reside on Ethereum blockchain.
//
// To recreate your art, you will need to retrieve the script
//
//  STEPS TO RETRIEVE THE SCRIPTS:
// - The artwork re-generation script is written in JavaScript, split into pieces, and stored on chain.
// - Query the contract for the scriptCount - this is the number of pieces of the re-genereation script. You will need all of them.
// - Run the getScriptAtIndex method in the EulerBeats smart contract starting with parameter 0, this is will return a transaction hash
// - The "Input Data" field of this transaction contains the first segment of the script. Convert this into UTF-8 format
// - Repeat these last two steps, incrementing the parameter in the getScriptAtIndex method until the number of script segments matches the scrtipCount

contract EulerBeats is Ownable, ERC1155 {
    using SafeMath for uint256;

    /***********************************|
    |        Variables and Events       |
    |__________________________________*/
    // For Minting and Burning, locks the prices
    bool private _enabled = false;
    // For metadata (scripts), when locked, cannot be changed
    bool private _locked = false;

    // Number of script sections stored
    uint256 public scriptCount = 0;
    // The scripts that can be used to render the NFT (audio and visual)
    mapping (uint256 => string) scripts;

    // The 40 bit is flag to distinguish prints - 1 for print
    uint256 constant SEED_MASK = uint40(~0);
    uint256 constant PRINTS_FLAG_BIT = 1 << 39;


    // Supply restriction on prints
    uint256 constant MAX_PRINT_SUPPLY = 120;
    // Supply restriction on seeds/original NFTs
    uint256 constant MAX_SEEDS_SUPPLY = 27;


    // Total supply of prints and seeds/original NFTs
    mapping(uint256 => uint256) public totalSupply;
    // Total number of seeds/original NFTs minted
    uint256 public originalsMinted = 0;
    // Owner of the seed/original NFT
    mapping(uint256 => address payable) public seedToOwner;


    // Cost of minting an original/seed 
    uint256 public mintPrice = 0.271 ether;
    // Funds reserved for burns
    uint256 public reserve = 0;

    // For bonding curve
    uint256 constant K = 1 ether;
    uint256 constant B = 50;
    uint256 constant C = 26;
    uint256 constant D = 8;
    uint256 constant SIG_DIGITS = 3;

    /**
     * @dev Emitted when an original NFT with a new seed is minted
     */
    event MintOriginal(address indexed to, uint256 seed, uint256 indexed originalsMinted);

    /**
     * @dev Emitted when an print is minted
     */
    event PrintMinted(
        address indexed to,
        uint256 id,
        uint256 indexed seed,
        uint256 pricePaid,
        uint256 nextPrintPrice,
        uint256 nextBurnPrice,
        uint256 printsSupply,
        uint256 royaltyPaid,
        uint256 reserve,
        address indexed royaltyRecipient
    );

    /**
     * @dev Emitted when an print is burned
     */
    event PrintBurned(
        address indexed to,
        uint256 id,
        uint256 indexed seed,
        uint256 priceReceived,
        uint256 nextPrintPrice,
        uint256 nextBurnPrice,
        uint256 printsSupply,
        uint256 reserve
    );


    constructor(string memory _uri) ERC1155("EulerBeats", "eBEATS", _uri) {}


    /***********************************|
    |        Modifiers                  |
    |__________________________________*/
    modifier onlyWhenEnabled() {
        require(_enabled, "Contract is disabled");
        _;
    }
    modifier onlyWhenDisabled() {
        require(!_enabled, "Contract is enabled");
        _;
    }
    modifier onlyUnlocked() {
        require(!_locked, "Contract is locked");
        _;
    }


    /***********************************|
    |        User Interactions          |
    |__________________________________*/
    /**
     * @dev Function to mint tokens. Msg.value must be sufficient
     */
    function mint() public payable onlyWhenEnabled returns (uint256) {
        uint256 newOriginalsSupply = originalsMinted.add(1);
        require(
            newOriginalsSupply <= MAX_SEEDS_SUPPLY,
            "Max supply reached"
        );
        require(msg.value == mintPrice, "Insufficient payment");

        // The generated seed  == the original nft token id. 
        // Both terms are used throughout and refer to the same thing.
        uint256 seed = _generateSeed(newOriginalsSupply);

        // Increment the supply per original nft (max: 1)
        totalSupply[seed]++;
        assert(totalSupply[seed] == 1);

        // Update total originals minted
        originalsMinted = newOriginalsSupply;

        _mint(msg.sender, seed, 1, "");

        emit MintOriginal(msg.sender, seed, newOriginalsSupply);
        return seed;
    }

    /**
     * @dev Function to mint prints from an existing seed. Msg.value must be sufficient.
     * @param seed The NFT id to mint print of
     */
    function mintPrint(uint256 seed)
        public
        payable
        onlyWhenEnabled
        returns (uint256)
    {
        require(seedToOwner[seed] != address(0), "Seed does not exist");
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        uint256 oldSupply = totalSupply[tokenId];
        // Get price to mint the next print
        uint256 printPrice = getPrintPrice(oldSupply + 1);
        require(msg.value >= printPrice, "Insufficient funds");

        uint256 newSupply = totalSupply[tokenId].add(1);
        totalSupply[tokenId] = newSupply;

        // Update reserve - reserveCut == Price to burn next token
        uint256 reserveCut = getBurnPrice(newSupply);
        reserve = reserve.add(reserveCut);

        // Calculate fees - seedOwner gets 80% of fee (printPrice - reserveCut)
        uint256 seedOwnerRoyalty = _getSeedOwnerCut(printPrice.sub(reserveCut));

        // Mint token
        _mint(msg.sender, tokenId, 1, "");

        // Disburse royalties
        address seedOwner = seedToOwner[seed];
        (bool success, ) = seedOwner.call{value: seedOwnerRoyalty}("");
        require(success, "Payment failed");
        // Remaining 20% kept for contract/Treum

        // If buyer sent extra ETH as padding in case another purchase was made they are refunded
        _refundSender(printPrice);

        emit PrintMinted(msg.sender, tokenId, seed, printPrice, getPrintPrice(newSupply.add(1)), reserveCut, newSupply, seedOwnerRoyalty, reserve, seedOwner);
        return tokenId;
    }

    /**
     * @dev Function to burn a print
     * @param seed The seed for the print to burn.
     * @param minimumSupply The minimum token supply for burn to succeed, this is a way to set slippage. 
     * Set to 1 to allow burn to go through no matter what the price is.
     */
    function burnPrint(uint256 seed, uint256 minimumSupply) public onlyWhenEnabled {
        require(seedToOwner[seed] != address(0), "Seed does not exist");
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        uint256 oldSupply = totalSupply[tokenId];
        require(oldSupply >= minimumSupply, 'Min supply not met');

        uint256 burnPrice = getBurnPrice(oldSupply);
        uint256 newSupply = totalSupply[tokenId].sub(1);
        totalSupply[tokenId] = newSupply;

        // Update reserve
        reserve = reserve.sub(burnPrice);

        _burn(msg.sender, tokenId, 1);

        // Disburse funds
        (bool success, ) = msg.sender.call{value: burnPrice}("");
        require(success, "Burn payment failed");

        emit PrintBurned(msg.sender, tokenId, seed, burnPrice, getPrintPrice(oldSupply), getBurnPrice(newSupply), newSupply, reserve);
    }


    /***********************************|
    |   Public Getters - Pricing        |
    |__________________________________*/
    /**
     * @dev Function to get print price
     * @param printNumber the print number of the print Ex. if there are 2 existing prints, and you want to get the
     * next print price, then this should be 3 as you are getting the price to mint the 3rd print
     */
    function getPrintPrice(uint256 printNumber) public pure returns (uint256 price) {
        require(printNumber <= MAX_PRINT_SUPPLY, "Maximum supply exceeded");

        uint256 decimals = 10 ** SIG_DIGITS;
        if (printNumber < B) {
            price = (10 ** ( B.sub(printNumber) )).mul(decimals).div(11 ** ( B.sub(printNumber)));
        } else if (printNumber == B) {
            price = decimals;     // price = decimals * (A ^ 0)
        } else {
            price = (11 ** ( printNumber.sub(B) )).mul(decimals).div(10 ** ( printNumber.sub(B) ));
        }
        price = price.add(C.mul(printNumber));

        price = price.sub(D);
        price = price.mul(1 ether).div(decimals);
    }

    /**
     * @dev Function to get funds received when burned
     * @param supply the supply of prints before burning. Ex. if there are 2 existing prints, to get the funds
     * receive on burn the supply should be 2
     */
    function getBurnPrice(uint256 supply) public pure returns (uint256 price) {
        uint256 printPrice = getPrintPrice(supply);
        price = printPrice * 90 / 100;  // 90 % of print price
    }


    /***********************************|
    | Public Getters - Seed + Prints    |
    |__________________________________*/
    /**
     * @dev Get the number of prints minted for the corresponding seed
     * @param seed The seed/original NFT token id
     */
    function seedToPrintsSupply(uint256 seed)
        public
        view
        returns (uint256)
    {
        uint256 tokenId = getPrintTokenIdFromSeed(seed);
        return totalSupply[tokenId];
    }

    /**
     * @dev The token id for the prints contains the seed/original NFT id
     * @param seed The seed/original NFT token id
     */
    function getPrintTokenIdFromSeed(uint256 seed) public pure returns (uint256) {
        return seed | PRINTS_FLAG_BIT;
    }

    /***********************************|
    |   Public Getters - Metadata       |
    |__________________________________*/
    function getScriptAtIndex(uint256 index) public view returns (string memory) {
        require(index < scriptCount, "Index out of bounds");
        return scripts[index];
    }

    /**
    * @notice A distinct Uniform Resource Identifier (URI) for a given token.
    * @dev URIs are defined in RFC 3986.
    *      URIs are assumed to be deterministically generated based on token ID
    * @return URI string
    */
    function uri(uint256 _id) public override view returns (string memory) {
        return string(abi.encodePacked(_uri, _uint2str(_id), ".json"));
    }


    /***********************************|
    |Internal Functions - Generate Seed |
    |__________________________________*/
    function _generateSeed(uint256 uniqueValue) internal view returns (uint256) {
        bytes32 hash = keccak256(abi.encodePacked(block.number, blockhash(block.number - 1), msg.sender, uniqueValue));

        // gridLength 0-5
        uint8 gridLength = uint8(hash[0]) % 6;

        // horizontalLever 0-58
        uint8 horizontalLever = uint8(hash[1]) % 59;

        // diagonalLever 0-10
        uint8 diagonalLever = uint8(hash[2]) % 11;

        // palette 4 0-11
        uint8 palette = uint8(hash[3]) % 12;

        // innerShape 0-3 with rarity
        uint8 innerShape = _getRareTrait(uint8(hash[4]) % 9);

        return uint256(uint40(gridLength) << 32 | uint40(horizontalLever) << 24 | uint40(diagonalLever) << 16 | uint40(palette) << 8 | uint40(innerShape));
    }

    function _getRareTrait(uint8 value) internal pure returns (uint8) {
        // 70% circle
        // 10% square;
        // 10% squareCircle;
        // 10% squareDiamond;
        
        if (value > 2) {
            return 3;
        } else {
            return value;
        }
    }


    /***********************************|
    |  Internal Functions - Prints      |
    |__________________________________*/
    function _getSeedOwnerCut(uint256 fee) internal pure returns (uint256) {
        return fee.mul(8).div(10);
    }

    function _refundSender(uint256 printPrice) internal {
        if (msg.value.sub(printPrice) > 0) {
            (bool success, ) =
                msg.sender.call{value: msg.value.sub(printPrice)}("");
            require(success, "Refund failed");
        }
    }


    /***********************************|
    |        Admin                      |
    |__________________________________*/
    /**
     * @dev Set mint price for seed/original NFT
     * @param _mintPrice The cost of an original
     */
    function setPrice(uint256 _mintPrice) public onlyOwner onlyWhenDisabled {
        mintPrice = _mintPrice;
    }

    function addScript(string memory _script) public onlyOwner onlyUnlocked {
        scripts[scriptCount] = _script;
        scriptCount = scriptCount.add(1);
    }

    function updateScript(string memory _script, uint256 index) public onlyOwner onlyUnlocked {
        require(index < scriptCount, "Index out of bounds");
        scripts[index] = _script;
    }

    function resetScriptCount() public onlyOwner onlyUnlocked {
        scriptCount = 0;
    }

    /**
     * @dev Withdraw earned funds from original Nft sales and print fees. Cannot withdraw the reserve funds.
     */
    function withdraw() public onlyOwner {
        uint256 withdrawableFunds = address(this).balance.sub(reserve);
        msg.sender.transfer(withdrawableFunds);
    }

    /**
     * @dev Function to enable/disable token minting
     * @param enabled The flag to turn minting on or off
     */
    function setEnabled(bool enabled) public onlyOwner {
        _enabled = enabled;
    }

    /**
     * @dev Function to lock/unlock the on-chain metadata
     * @param locked The flag turn locked on
     */
    function setLocked(bool locked) public onlyOwner onlyUnlocked {
        _locked = locked;
    }

    /**
     * @dev Function to update the base _uri for all tokens
     * @param newuri The base uri string
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }


    /***********************************|
    |        Hooks                      |
    |__________________________________*/
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // If token is original, keep track of owner so can send them fees
            if (ids[i] & PRINTS_FLAG_BIT != PRINTS_FLAG_BIT) {
                uint256 seed = ids[i];
                seedToOwner[seed] = payable(to);
            }
        }
    }

    /***********************************|
    |    Utility Internal Functions     |
    |__________________________________*/

    /**
    * @notice Convert uint256 to string
    * @param _i Unsigned integer to convert to string
    */
    function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
        return "0";
        }

        uint256 j = _i;
        uint256 ii = _i;
        uint256 len;

        // Get number of bytes
        while (j != 0) {
        len++;
        j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;

        // Get each individual ASCII
        while (ii != 0) {
        bstr[k--] = byte(uint8(48 + ii % 10));
        ii /= 10;
        }

        // Convert to string
        return string(bstr);
    }
}