// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/// @title StarlPixelNauts
/// @notice A contract for pixelnauts in the starlink ecosystem
contract StarlPixelNauts is Ownable, ERC721Enumerable {
    using   SafeMath for uint256;
    using   Strings for uint256;

    /// @notice event emitted when all tokens are revealed
    event Revealed(
        string _revealedURI
    );

    /// @notice event emitted when all tokens are unrevealed, this is for testing purpose
    event Unrevealed();

    /// @notice event emitted when base token uri is updated
    event BaseURIUpdated(
        string _newBaseURI
    );

    /// @notice event emitted when extension is updated
    event ExtensionUpdated(
        string _newExtension
    );

    uint256 cost = 0.08 ether;
    uint256 public maxSupply = 10000;
    uint256 public maxMintSupply = 9998;
    uint256 public maxMintAmount = 30;
    string  public revealedURI;
    string  public extension = "";
    string  public pendingURI;
    bool    public isRevealed = false;
    mapping(address => uint256) public addressCanMint;
    uint256 public mintStartTime;

    constructor (string memory _pendingURI, uint256 _mintStartTime) ERC721("Starlink PixelNauts", "PIXELNAUTS") {
        pendingURI = _pendingURI;
        mintStartTime = _mintStartTime;
    }

    function mint(address _to, uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();
        require(block.timestamp > mintStartTime, "Mint Not started");
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount, "maxMintAmount exceed");
        require(supply.add(_mintAmount) <= maxSupply, "Total supply exceed");

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount, "Insufficient funds");
            require(supply.add(_mintAmount) <= maxMintSupply, "Max mint supply exceed");
            require(
                addressCanMint[msg.sender] == 0 || _mintAmount <= addressCanMint[msg.sender],
                "You cant mint more items than left mint amount"
            );
        }

        for(uint256 i=1; i<=_mintAmount; i++) {
            _safeMint(_to, supply.add(i));
        }
        if (addressCanMint[msg.sender] == 0) {
            addressCanMint[msg.sender] = maxMintAmount.sub(_mintAmount);
        } else {
            addressCanMint[msg.sender] = addressCanMint[msg.sender].sub(_mintAmount);
        }
    }

    function reveal(string memory _revealedURI) public onlyOwner {
        require(!isRevealed, "Already revealed");
        revealedURI = _revealedURI;
        isRevealed = true;
        
        emit Revealed(_revealedURI);
    }

    function unReveal() public onlyOwner {
        require(isRevealed, "Not revealed");
        isRevealed = false;
        emit Unrevealed();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return !isRevealed ?
            currentBaseURI :
            string(
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        if (isRevealed) {
            revealedURI = _newBaseURI;
        } else {
            pendingURI = _newBaseURI;
        }

        emit BaseURIUpdated(_newBaseURI);
    }

    function setExtension(string memory _extension) public onlyOwner {
        extension = _extension;
        
        emit ExtensionUpdated(_extension);
    }
    
    function setMintStartTime(uint256 _mintStartTime) public onlyOwner {
        mintStartTime = _mintStartTime;
    }

    function removeExtension() public onlyOwner {
        extension = "";
        
        emit ExtensionUpdated("");
    }

    function withdraw() public onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }    
}