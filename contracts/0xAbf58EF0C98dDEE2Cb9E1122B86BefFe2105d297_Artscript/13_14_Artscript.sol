// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

/*_____________________________________________________________________________________________*/
//   ________  ________  _________  ________  ________  ________  ___  ________  _________     /
//  |\   __  \|\   __  \|\___   ___\\   ____\|\   ____\|\   __  \|\  \|\   __  \|\___   ___\   /
//  \ \  \|\  \ \  \|\  \|___ \  \_\ \  \___|\ \  \___|\ \  \|\  \ \  \ \  \|\  \|___ \  \_|   /
//   \ \   __  \ \   _  _\   \ \  \ \ \_____  \ \  \    \ \   _  _\ \  \ \   ____\   \ \  \    /
//    \ \  \ \  \ \  \\  \|   \ \  \ \|____|\  \ \  \____\ \  \\  \\ \  \ \  \___|    \ \  \   /
//     \ \__\ \__\ \__\\ _\    \ \__\  ____\_\  \ \_______\ \__\\ _\\ \__\ \__\        \ \__\  /
//      \|__|\|__|\|__|\|__|    \|__| |\_________\|_______|\|__|\|__|\|__|\|__|         \|__|  /
//                                    \|_________|                                             /
/*_____________________________________________________________________________________________*/


import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "./interfaces/IMetadataServer.sol";

contract Artscript is ERC1155Upgradeable, OwnableUpgradeable, IERC2981Upgradeable {

    uint256 public price;
    //token id to owner
    mapping(uint256 => address) public pieceOwners;
    bytes32 public wlSeed;
    IMetadataServer public metadataServer;
    uint16 public totalMinted;
    bool public wlClosed;
    bool public closed;

    error InsufficientValue(uint256 value, uint256 required);
    error Closed();
    error WhitelistClosed();
    error NotWhitelisted(address account);
    error AlreadyMinted(uint256 blockNumber);
    error AlreadySetted();
    error TotalSupplyReached();
    
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Function to initialize the contract.
     * @param _metadataServer On-chain metadata address.
     * @param _seed Whitelist seed.
     */
    function initialize(address _metadataServer, bytes32 _seed) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        metadataServer = IMetadataServer(_metadataServer);
        wlSeed = _seed;
        closed = true;
        wlClosed = false;
        price = 0.01 ether;
    }

    /**
     * @notice Public mint function.
     * @param _blockNumber Bitcoin block number.
     * @param _inscription Version of the Ordinal.
     */
    function mint(uint256 _blockNumber, IMetadataServer.Inscription memory _inscription) external payable {
        if (totalMinted >= 1000)
            revert TotalSupplyReached();
        
        if (closed) 
            revert Closed();

        if (msg.value < price)
            revert InsufficientValue(msg.value, price);

        if (pieceOwners[_blockNumber] != address(0))
            revert AlreadyMinted(_blockNumber);

        pieceOwners[_blockNumber] = msg.sender;
        metadataServer.addInscription(_blockNumber, _inscription);
        unchecked {
            totalMinted++;
        }
        _mint(msg.sender, _blockNumber, 1, "");
    }

    /**
     * @notice Whitelist mint function.
     * @param _merkleProof Whitelist merkle proof.
     * @param _blockNumber Bitcoin block number.
     * @param _inscription Version of the Ordinal.
     */
    function whitelistMint(bytes32[] calldata _merkleProof, uint256 _blockNumber, IMetadataServer.Inscription memory _inscription) external payable {
        if (totalMinted >= 1000)
            revert TotalSupplyReached();

        if (wlClosed)
            revert WhitelistClosed();

        if (!MerkleProofUpgradeable.verify(_merkleProof, wlSeed, keccak256(abi.encodePacked(msg.sender))))
            revert NotWhitelisted(msg.sender);  

        if (pieceOwners[_blockNumber] != address(0))
            revert AlreadyMinted(_blockNumber);

        pieceOwners[_blockNumber] = msg.sender;
        metadataServer.addInscription(_blockNumber, _inscription);
        unchecked {
            totalMinted++;
        }
        _mint(msg.sender, _blockNumber, 1, "");
    }

    /**
     * @notice Function to open/close the public mint.
     * @param _newState True or false.
     */
    function setClosed(bool _newState) external onlyOwner {
        if ( _newState == closed)
            revert AlreadySetted();
        closed = _newState;
    }

    /**
     * @notice Function to open/close the whitelist mint.
     * @param _newState True or false.
     */
    function setWLClosed(bool _newState) external onlyOwner {
        if ( _newState == wlClosed)
            revert AlreadySetted();
        wlClosed = _newState;
    }

    /**
     * @notice Function to set the whitelist seed.
     * @param _newSeed New seed.
     */
    function setWLSeed(bytes32 _newSeed) external onlyOwner {
        if ( _newSeed == wlSeed)
            revert AlreadySetted();
        wlSeed = _newSeed;
    }

    /**
     * @notice Function to set the price.
     * @param _newPrice New price.
     */
    function setPrice(uint256 _newPrice) external onlyOwner {
        if(_newPrice == price)
            revert AlreadySetted();
        price = _newPrice;
    }

    /**
     * @notice Function to withdraw funds.
     * @param _to Address to send the funds.
     * @param _amount Amount to send.
     */
    function withdrawFunds(address payable _to, uint256 _amount) external onlyOwner {
        AddressUpgradeable.sendValue(_to, _amount);
    }

    /**
     * @notice Function to check the royalties of the contract.
     * @param _tokenId  Token identifier.
     * @param _salePrice Sale price of the token.
     * @return _receiver Receiver of the royalties.
     * @return _royaltyAmount Amount of the royalties to receive.
     */
    function  royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address _receiver, uint256 _royaltyAmount) {
        return (owner(), (_salePrice * 5) / 100);
    }

    /**
     * @notice Function to get the metadata.
     * @param tokenId tokenId.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        return metadataServer.serveMetadata(tokenId);
    }

    /**
     * @notice Function to check the implemented interafaces of the contract.
     * @param _interfaceId  Interface identifier.
     * @return True if the interface is implemented, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155Upgradeable, IERC165Upgradeable) returns (bool) {
        return super.supportsInterface(_interfaceId) || _interfaceId == type(IERC2981Upgradeable).interfaceId;
    }

    /**
     * @notice Function to get the contract URI.
     * @return The contract URI.
     */
    function contractURI() public pure returns (string memory) {
        return "https://arweave.net/sbyFI-GFddYf7xB2CrswwUIe5tHY9iso_JMAAgH0gQI";
    }

}