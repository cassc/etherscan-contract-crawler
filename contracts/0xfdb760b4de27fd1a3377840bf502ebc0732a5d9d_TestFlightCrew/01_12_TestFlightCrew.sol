// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestFlightCrew is ERC721, Ownable {
    uint256 private supply;

    uint256 startDate = 1627056000;

    bool private isFinished;

    bool private isTransferable;

    string private baseURI =
        "https://tomsachsrocketfactory.mypinata.cloud/ipfs/QmWeMQrqiY1JdhSvtaFwyime2Tt3K3EQSc4i4FovZ7hUV4";

    constructor() ERC721("TEST FLIGHT CREW", "TFC") {}

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /**
     * @dev Sets the isFinished flag to true.
     */
    function setFinished() external onlyOwner {
        isFinished = true;
    }

    /**
     * @dev Sets the start date.
     */
    function setStartDate(uint256 _startDate) external onlyOwner {
        startDate = _startDate;
    }

    function setIsTransferable(bool _isTransferable) external onlyOwner {
        isTransferable = _isTransferable;
    }

    /**
     * @dev mints a new commemorative NFT.
     */
    function mint() external {
        require(
            startDate < block.timestamp,
            "You are too early to claim this token"
        );

        require(isFinished == false, "You can not claim this token anymore");

        require(
            balanceOf(msg.sender) == 0,
            "Only one Token per wallet is allowed"
        );

        _mint(msg.sender, supply);

        supply++;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the total supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return supply;
    }

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return baseURI;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(isTransferable == true, "This token is non-transferable");

        ERC721._transfer(from, to, tokenId);
    }
}