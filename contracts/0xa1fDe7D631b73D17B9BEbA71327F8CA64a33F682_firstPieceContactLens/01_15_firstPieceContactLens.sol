// SPDX-License-Identifier: MIT

/// @title: First Piece Contact Lens NFT Contract
/// @author: First Piece
/// @notice: For more information checkout https://twitter.com/FirstPiece_App
/// @dev: This is Version 1.0
//
//  ________  _                  _     _______   _                       
// |_   __  |(_)                / |_  |_   __ \ (_)                      
//   | |_ \_|__   _ .--.  .--. `| |-'   | |__) |__  .---.  .---.  .---.  
//   |  _|  [  | [ `/'`\]( (`\] | |     |  ___/[  |/ /__\\/ /'`\]/ /__\\ 
//  _| |_    | |  | |     `'.'. | |,   _| |_    | || \__.,| \__. | \__., 
// |_____|  [___][___]   [\__) )\__/  |_____|  [___]'.__.''.___.' '.__.' 
                                                                      


pragma solidity ^0.8.4;
// import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract firstPieceContactLens is ERC721AQueryable, Ownable {
    using Strings for uint256;

    uint256 public REVEAL_TIMESTAMP = 0;

    string baseTokenURI;
    
    constructor(string memory baseURI) ERC721A("First Piece Contact Lens", "FPCL") {
        setBaseURI(baseURI);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }


    function reveal(uint256 _revealTimeStamp, string memory baseURI) external onlyOwner {
        REVEAL_TIMESTAMP = _revealTimeStamp;
        setBaseURI(baseURI);
    } 

    function withdrawAll() public onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function withdrawTokens(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
    //mint NFTTokens
    function mintNFTTokens(uint256 _count) public payable onlyOwner {
        _safeMint(msg.sender, _count);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        if (REVEAL_TIMESTAMP == 0) return string(abi.encodePacked(baseURI));

        string memory _tokenURI = '';
        if (bytes(baseURI).length > 0) {
            _tokenURI = string(abi.encodePacked(baseURI, tokenId.toString()));
        }
        return _tokenURI;
    }

    function tokensMinted() public view returns (uint256) {
        return totalSupply();
    }

    function collectionInWallet(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        uint256 x = 0;
        for(uint256 i; i < totalSupply(); i++){
            if (_owner == ownerOf(i)) {
                tokensId[x] = i;
                x = x + 1;
            }
            if(x == tokenCount) return tokensId;
        }
        return tokensId;
    }

}