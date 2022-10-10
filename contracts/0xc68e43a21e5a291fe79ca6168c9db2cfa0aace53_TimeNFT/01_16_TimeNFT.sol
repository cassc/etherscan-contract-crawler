// SPDX-License-Identifier: MIT

// 1D46ED9230D0A49DA83BC565DBD8EEB1F72CA7FBADAABF1020D7EA042B155AD4
// This is a list of authors of the source code used as reference.Thanks!!
// @MEGAMINFT
// @NandemoToken
pragma solidity ^0.8.7;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC2981.sol";
import "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./LibPart.sol";
import "./LibRoyaltiesV2.sol";
import "./RoyaltiesV2.sol";
import "./ITimeNFT.sol";

contract TimeNFT is ITimeNFT, ERC721, Ownable, RoyaltiesV2 {
    struct TokenURIData {
        uint256 timezone;
        string daytimeIpfshash;
        string nightIpfshash;
    }

    mapping(uint256 => TokenURIData) public tokenURIDatas;

    /**
     * @dev baseURI. It used in combination with ipfshash.
     */
    string private constant BASE_TOKEN_URI = "ipfs://";

    /**
     * @dev Max supply.
     */
    uint256 private constant MAX_SUPPLY = 999;

    /**
     * @dev Current supply.
     */
    uint256 public totalSupply = 0;

    /**
     * @dev Percentage basis points of the royalty
     */
    uint96 private defaultPercentageBasisPoints = 1000; // 10%

    /**
     * @dev 100% in bases point
     */
    uint256 private constant HUNDRED_PERCENT_IN_BASIS_POINTS = 10000;

    /**
     * @dev Max royalty this contract allows to set. It's 100% in the basis points.
     */
    uint256 private constant MAX_ROYALTY_BASIS_POINTS = 10000;

    constructor() ERC721("SampleName", "SampleSymbol") {}

    /**
     * @dev Mint NFT to input address.
     * @param daytimeIpfshash It can show in daytime. ex. "bafybeidalq2vg5sbcygm5rbwy5dplizqlasmavcm77g7zthwzhuj34e4mm"
     * @param nightIpfshash It can show in night. ex. "bafybeibvjw467u2nrammqtlxmk4sygmcpanajuu3kuodjxvn4o4nqhture"
     */
    function mint(
        address to,
        string memory daytimeIpfshash,
        string memory nightIpfshash
    )
        external
        override
        onlyOwner
    {
        require(totalSupply <= MAX_SUPPLY, "Max supply exceeded");
        _mint(to, totalSupply);
        tokenURIDatas[totalSupply] =
            TokenURIData(9, daytimeIpfshash, nightIpfshash);
        ++totalSupply;
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) external onlyOwner{
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }

    /**
     * @dev Set the percentage basis points of the loyalty.
     */
    function settimezone(uint256 tokenId, uint256 timezone) external {
        require(msg.sender == ownerOf(tokenId), "Token owner only function");
        tokenURIDatas[tokenId].timezone = timezone;
    }

    /**
     * @dev Return input time is daytime(1) or night(0).
     */
    function boolDaytime(uint256 tokenId, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 currentTime =
            (((timestamp % 86400) / 3600) + tokenURIDatas[tokenId].timezone) % 24;
        if (8 <= currentTime && currentTime < 20) {
            //daytime
            return 1;
        } else {
            //night
            return 0;
        }
    }

    /**
     * @dev Return URL of metadata.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (boolDaytime(tokenId, block.timestamp) == 1) {
            return string(
                abi.encodePacked(BASE_TOKEN_URI, tokenURIDatas[tokenId].daytimeIpfshash)
            );
        } else {
            return string(
                abi.encodePacked(BASE_TOKEN_URI, tokenURIDatas[tokenId].nightIpfshash)
            );
        }
    }

    /**
     * @dev Set the percentage basis points of the loyalty.
     * @param newDefaultPercentageBasisPoints The new percentagy basis points of the loyalty.
     */
    function setDefaultPercentageBasisPoints(
        uint96 newDefaultPercentageBasisPoints
    )
        external
        onlyOwner
    {
        require(
            newDefaultPercentageBasisPoints <= MAX_ROYALTY_BASIS_POINTS,
            "must be less than or equal to 100%"
        );
        defaultPercentageBasisPoints = newDefaultPercentageBasisPoints;
    }

    /**
     * @dev Return royality information for Rarible.
     */
    function getRaribleV2Royalties(uint256)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = defaultPercentageBasisPoints;
        _royalties[0].account = payable(owner());
        return _royalties;
    }

    /**
     * @dev Return royality information in EIP-2981 standard.
     * @param salePrice The sale price of the token that royality is being calculated.
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (
            owner(),
            (salePrice * defaultPercentageBasisPoints)
                / HUNDRED_PERCENT_IN_BASIS_POINTS
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (IERC165, ERC721)
        returns (bool)
    {
        if (interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        if (interfaceId == type(IERC2981).interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}