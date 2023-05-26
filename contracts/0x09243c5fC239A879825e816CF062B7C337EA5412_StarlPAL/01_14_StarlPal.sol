// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title STARL PAL
/// @notice A contract for PAL(Physics Altering Lifeforms) in the STARL ecosystem
contract StarlPAL is Ownable, ERC721Enumerable {
    using SafeMath for uint256;
    using Strings for uint256;

    /// @notice event emitted when all tokens are revealed
    event Revealed(string _revealedURI);

    /// @notice event emitted when all tokens are unrevealed, this is for testing purpose
    event Unrevealed();

    /// @notice event emitted when base token uri is updated
    event BaseURIUpdated(string _newBaseURI);

    /// @notice event emitted when extension is updated
    event ExtensionUpdated(string _newExtension);

    /// @notice ether price of a PAL nft, initialized as 0.08 ether.
    uint256 public cost = 0.08 ether;
    /// @notice max supply of PAL nfts, initialized as 10k.
    uint256 public maxSupply = 10000;

    /// @notice revealed uri - token base uri after reveal, initialized as empty.
    string public revealedURI;
    /// @notice extension - token uri extension after reveal, initialized as empty.
    string public extension = "";
    /// @notice pending uri - token uri which is used before revealed, need to be initialized via constructor.
    string public pendingURI;
    /// @notice flag if revealed or not
    bool public isRevealed = false;

    /// @notice the start timestamp of minting, need to be initialized via constructor.
    uint256 public mintStartTime;

    /// @notice contract constructor
    /// @param _pendingURI token metadata uri that is used before it's revealed.
    /// @param _mintStartTime the timestamp when users can mint PAL nfts.
    constructor(
        string memory _pendingURI,
        uint256 _mintStartTime,
        uint256 _numberOfReserve
    ) ERC721("StarlPAL", "SPAL") {
        require(block.timestamp < _mintStartTime, "Invalid mintStartTime");
        pendingURI = _pendingURI;
        mintStartTime = _mintStartTime;

        uint256 supply = totalSupply();
        for (uint256 i = 1; i <= _numberOfReserve; i++) {
            _safeMint(msg.sender, supply.add(i));
        }
    }

    /// @notice mint _mintAmount of PALs to _to address by sending correct amount of ether. needed ether price is 0.08 * _mintAmount.
    /// @param _to the target address where minted nft is transferred. each address can mint upto 30 nfts.
    /// @param _mintAmount the amount of nft to mint. it should be less than 30.
    function mint(address _to, uint256 _mintAmount) public payable {
        require(block.timestamp > mintStartTime, "Mint Not started");
        uint256 supply = totalSupply();
        require(_mintAmount > 0, "Invalid mintAmount");
        require(supply.add(_mintAmount) <= maxSupply, "Total supply exceed");

        if (msg.sender != owner()) {
            require(
                msg.value >= cost * _mintAmount,
                "Insufficient amount of ether"
            );
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply.add(i));
        }
    }

    /// @notice update mint start timestamp
    /// @param _mintStartTime new value to set for start timestamp.
    function setMintStartTime(uint256 _mintStartTime) public onlyOwner {
        mintStartTime = _mintStartTime;
    }

    /// @notice After 10k PALs are minted, owner should call this reveal function to reveal token uris.
    /// @param _revealedURI token metadata base url.
    /// @param _extension token metadata url extension.
    function reveal(string memory _revealedURI, string memory _extension)
        public
        onlyOwner
    {
        require(!isRevealed, "Already revealed");
        revealedURI = _revealedURI;
        extension = _extension;
        isRevealed = true;

        emit Revealed(_revealedURI);
    }

    function unReveal() public onlyOwner {
        require(isRevealed, "Not revealed");
        isRevealed = false;
        emit Unrevealed();
    }

    /// @notice Return token uri for a token
    /// @param tokenId token id
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

        string memory currentBaseURI = _baseURI();
        return
            !isRevealed
                ? currentBaseURI
                : string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        extension
                    )
                );
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return isRevealed ? revealedURI : pendingURI;
    }

    /// @notice Update token base uri, set revealedURI if revealed, otherwise set pending uri.
    /// @param _newBaseURI base token metadata uri
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        if (isRevealed) {
            revealedURI = _newBaseURI;
        } else {
            pendingURI = _newBaseURI;
        }

        emit BaseURIUpdated(_newBaseURI);
    }

    /// @notice Update token uri extension, a token uri is composed of base uri or revealed uri appending token id and appending extension.
    /// @param _extension extension string to set, e.g. ".json"
    function setExtension(string memory _extension) public onlyOwner {
        extension = _extension;

        emit ExtensionUpdated(_extension);
    }

    /// @notice remove extension, if remove extension a token uri will be composed by only base uri and token id.
    function removeExtension() public onlyOwner {
        extension = "";

        emit ExtensionUpdated("");
    }

    /// @notice withdraw all ether balance of this contract to contract owner.
    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
}