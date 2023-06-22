// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/////////////////////////////
//                         //
//                         //
//            *            //
//          * | *          //
//         * \|/ *         //
//    * * * \|O|/ * * *    //
//     \o\o\o|O|o/o/o/     //
//     (<><><>O<><><>)     //
//      '==========='      //
//                         //
//      dev: bueno.art     //
/////////////////////////////

contract OfTheNight is ERC721, Ownable {
    using ECDSA for bytes32;
    uint256 public nextTokenId = 1;
    uint256 public presalePrice = 0.06 ether;
    uint256 public publicPrice = 0.08 ether;

    // each of these supply values are offset to save a little bit of gas on a <= check
    // token IDs are 1-1600
    uint256 public constant SUPPLY = 1602;
    uint256 public constant GIFT_MAX = 52;
    uint256 public constant MAX_PER_WALLET_PUBLIC = 3;

    // maximum value of an unsigned 256-bit integer
    uint256 private constant MAX_INT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    // each element of the array represents bits that indicate whether a token has been minted
    // 7 groups * 256 bits = 1792 slots -- the max supply in presale is 1550. Unused bits are ignored.
    uint256[7] groups = [
        MAX_INT,
        MAX_INT,
        MAX_INT,
        MAX_INT,
        MAX_INT,
        MAX_INT,
        MAX_INT
    ];

    string public _baseTokenURI;

    enum SaleState {
        CLOSED,
        PRESALE,
        OPEN
    }

    SaleState saleState = SaleState.CLOSED;

    address private bueno = 0x985AFcA097414E5510c2C4faEbDb287E4F237A1B;
    address private otn = 0x61c40fE173722A561ACb7088141C01A4a257f777;
    address private signer = address(0);

    event Mint(address purchaser, uint256 amount);
    event SaleStateChange(SaleState newState);

    constructor(string memory baseURI) ERC721("Of The Night", "OFTHENIGHT") {
        _baseTokenURI = baseURI;
    }

    function mint(uint256 qty) external payable {
        uint256 _nextTokenId = nextTokenId;
        require(msg.sender == tx.origin, "INVALID_SENDER");
        require(saleState == SaleState.OPEN, "SALE_INACTIVE");
        require((_nextTokenId + qty) < SUPPLY, "SOLD_OUT");
        require(
            balanceOf(msg.sender) + qty < MAX_PER_WALLET_PUBLIC,
            "MAX_PER_WALLET"
        );
        require(msg.value == publicPrice * qty, "INCORRECT_ETH");

        for (uint256 i = 0; i < qty; i++) {
            _mint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }

        nextTokenId = _nextTokenId;
        emit Mint(msg.sender, qty);
    }

    function mintOnePresale(bytes calldata _signature, uint256 spotId)
        external
        payable
    {
        uint256 _nextTokenId = nextTokenId;
        require(msg.sender == tx.origin, "INVALID_SENDER");
        require(saleState == SaleState.PRESALE, "SALE_INACTIVE");
        require(_nextTokenId + 1 < SUPPLY, "SOLD_OUT");
        require(msg.value == presalePrice, "INCORRECT_ETH");

        // verify that the spotId is valid
        require(
            _verify(
                keccak256(abi.encodePacked(msg.sender, spotId)),
                _signature
            ),
            "INVALID_SIGNATURE"
        );

        // invalidate the spotId passed in
        _claimAllowlistSpot(spotId);
        _mint(msg.sender, _nextTokenId);
        unchecked {
            _nextTokenId++;
        }

        nextTokenId = _nextTokenId;
        emit Mint(msg.sender, 1);
    }

    function mintPresale(
        bytes[] calldata _signatures,
        uint256[] calldata spotIds
    ) external payable {
        uint256 _nextTokenId = nextTokenId;
        require(msg.sender == tx.origin, "INVALID_SENDER");
        require(saleState == SaleState.PRESALE, "SALE_INACTIVE");
        require(_nextTokenId + spotIds.length < SUPPLY, "SOLD_OUT");
        require(msg.value == presalePrice * spotIds.length, "INCORRECT_ETH");

        for (uint256 i = 0; i < spotIds.length; i++) {
            require(
                _verify(
                    keccak256(abi.encodePacked(msg.sender, spotIds[i])),
                    _signatures[i]
                ),
                "INVALID_SIGNATURE"
            );

            _claimAllowlistSpot(spotIds[i]);
            _mint(msg.sender, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }

        nextTokenId = _nextTokenId;
        emit Mint(msg.sender, spotIds.length);
    }

    function devMint(address receiver, uint256 qty) external onlyOwner {
        uint256 _nextTokenId = nextTokenId;
        require(_nextTokenId + qty < GIFT_MAX, "INVALID_QUANTITY");

        for (uint256 i = 0; i < qty; i++) {
            _mint(receiver, _nextTokenId);

            unchecked {
                _nextTokenId++;
            }
        }

        nextTokenId = _nextTokenId;
    }

    function totalSupply() public view virtual returns (uint256) {
        return nextTokenId - 1;
    }

    function _verify(bytes32 hash, bytes memory signature)
        internal
        view
        returns (bool)
    {
        require(signer != address(0), "INVALID_SIGNER_ADDRESS");
        bytes32 signedHash = hash.toEthSignedMessageHash();
        return signedHash.recover(signature) == signer;
    }

    /** @dev h/t to https://medium.com/donkeverse/hardcore-gas-savings-in-nft-minting-part-3-save-30-000-in-presale-gas-c945406e89f0
     for this trick to optimize gas when minting an allowlist */
    function _claimAllowlistSpot(uint256 spotId) internal {
        require(spotId < groups.length * 256, "INVALID_ID");

        uint256 groupIndex;
        uint256 spotIndex;
        uint256 localGroup;
        uint256 storedBit;

        unchecked {
            // which index of the groups array the provided ID falls into
            // for ex, if the ID is 256, then we're in group[1]
            groupIndex = spotId / 256;
            // which of the 256 bits in that group the ID falls into
            spotIndex = spotId % 256;
        }

        localGroup = groups[groupIndex];

        // shift the group bits to the right by the number of bits at the specified index
        // this puts the bit we care about at the rightmost position
        // bitwise AND the result with a 1 to zero-out everything except the bit being examined
        storedBit = (localGroup >> spotIndex) & uint256(1);
        // if we got a 1, the spot was already used
        require(storedBit == 1, "ALREADY_MINTED");
        // zero-out the bit at the specified index by shifting it back to its original spot, and then bitflip
        localGroup = localGroup & ~(uint256(1) << spotIndex);

        // store the modified group back into the array
        groups[groupIndex] = localGroup;
    }

    /**
     * @dev Sets sale state to CLOSED (0), PRESALE (1), or OPEN (2).
     */
    function setSaleState(uint8 _state) public onlyOwner {
        saleState = SaleState(_state);
        emit SaleStateChange(saleState);
    }

    function getSaleState() public view returns (uint8) {
        return uint8(saleState);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function withdraw() external onlyOwner {
        (bool s1, ) = bueno.call{value: (address(this).balance * 15) / 100}("");
        (bool s2, ) = otn.call{value: (address(this).balance)}("");

        require(s1 && s2, "Transfer failed.");
    }

    function setPresalePrice(uint256 newPrice) external onlyOwner {
        presalePrice = newPrice;
    }

    function setPublicPrice(uint256 newPrice) external onlyOwner {
        publicPrice = newPrice;
    }

    function setSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function tokensOf(address wallet) public view returns (uint256[] memory) {
        uint256 supply = totalSupply();
        uint256[] memory tokenIds = new uint256[](balanceOf(wallet));

        uint256 currIndex = 0;
        for (uint256 i = 1; i <= supply; i++) {
            if (wallet == ownerOf(i)) tokenIds[currIndex++] = i;
        }

        return tokenIds;
    }
}