/*

  /$$$$$$  /$$$$$$$$ /$$      /$$
 /$$__  $$|__  $$__/| $$$    /$$$
| $$  \ $$   | $$   | $$$$  /$$$$
| $$$$$$$$   | $$   | $$ $$/$$ $$
| $$__  $$   | $$   | $$  $$$| $$
| $$  | $$   | $$   | $$\  $ | $$
| $$  | $$   | $$   | $$ \/  | $$
|__/  |__/   |__/   |__/     |__/
                                                                                                                 
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
import "../rarible/royalties/contracts/LibPart.sol";
import "../rarible/royalties/contracts/LibRoyaltiesV2.sol";

/// @title ASIC Token Miner smart contract
/// @author 01101000 01100101 01111000 01101001 01101110 01100110 01101111 00100000 00100110 00100000 01101011 01101111 01100100 01100101
/// @notice ATM is a rare NFT that increases it's point payout value of ASIC overtime.
contract ATM is ERC721, ERC721Enumerable, RoyaltiesV2Impl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    address private immutable OWNER;
    address private constant BA_ADDRESS = address(0x7686640F09123394Cd8Dc3032e9927767aD89344);
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint96 private constant PERCENTAGE_BASIS_POINTS = 420;
    string private constant HOSTNAME = "https://api.pulsebitcoin.app/";
    string private constant ENDPOINT = "/atm/";

    // errors
    error NotOwner();

    // modifiers
    modifier onlyOwner() {
        if (msg.sender != OWNER) {
            revert NotOwner();
        }
        _;
    }

    constructor() ERC721("ASIC Token Miner", "ATM") {
        OWNER = msg.sender;
    }

    function owner() external view returns (address) {
        return OWNER;
    }

    function getLatestTokenId() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function mint(address _to) external onlyOwner returns (uint256) {
        _tokenIdTracker.increment();
        uint256 newTokenIdTracker = _tokenIdTracker.current();
        _setRoyalties(newTokenIdTracker);

        super._mint(_to, newTokenIdTracker);
        return newTokenIdTracker;
    }

    function burn(uint256 tokenIdTracker) external onlyOwner {
        _burn(tokenIdTracker);
    }

    function _setRoyalties(uint256 _tokenId) internal {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = PERCENTAGE_BASIS_POINTS;
        _royalties[0].account = payable(BA_ADDRESS);
        _saveRoyalties(_tokenId, _royalties);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        LibPart.Part[] memory _royalties = royalties[_tokenId];
        if (_royalties.length > 0) {
            return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
        }
        return (address(0), 0);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        string memory chainid = Strings.toString(block.chainid);
        return string(abi.encodePacked(HOSTNAME, chainid, ENDPOINT));
    }
}