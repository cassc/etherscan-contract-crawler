// SPDX-License-Identifier: MIT
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@%&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@((#################%%&&&@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@&#((((((#(##########%###%%&@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@(((((((#((/ (((,(%#####%%%@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@&((((((((#/* ##,(,#(######&@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@((((((((#(/, #((##,%######@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@&(((((((#((( *#.*/########&@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@#((((((%(,((.#%#########%#@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@&((((((((((((#(%(#########%@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@&((((//( (#((((##(########&@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@(((((((((((((((#(.#(######@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@&(((((((((((#((###########&@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@#((((((((#(###(###########@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@((((((##((###############&@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&((((((((###############%#@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@(((#((#((#############%#%&@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@&##((#####(.(#############@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@#####(#####/(############%@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@&%########/*(##########%%&@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@&&@@@@@@@@&&%#####%#%###%#%@@@@@@@@@&@@@@@@@&&@@@@@
// @@@@@@@@@@@@#%%&&&&&&#(&&&&@@@@@@&&%%%%&@@@@@@@@@@@@@@@@@@@@@@@@
// %&(&%#%&&&&&&&&#&&&&&@&&&&&&&&&&&%%%%%%&(((###%&&@@@@@@@@@@@@@@@
// &&&&&@@@&&&&%&&(#%%%%%%%%##(/%%%%%%%%%%#%#####%%%%&@@@@@@@@@@@@@
// @@@&&@@&@@@@@@@%%%%%%%%%%#/((#%%%%%%%%%%&@@@@@@@@@@#%@@@@@@@@@@@

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

error IncorrectProof();
error AllNFTsSoldOut();
error AlreadyMintedForThisAddress();
error CannotSetZeroAddress();

///@author Charles
///@dev For our collection "ALPHA PRESTIGE"(https://ap.fusionist.io/)
contract APNFT is ERC721, ERC2981, Ownable {
    using Address for address;
    using Counters for Counters.Counter;

    uint256 public constant MAX_SUPPLY = 500;
    address public treasuryAddress;
    bytes32 public merkleRoot;

    mapping (address => bool) public minters;

    Counters.Counter private _tokenIdCounter;
    string private _baseTokenURI;

    constructor(
        address defaultTreasury,
        string memory defaultBaseURI
    ) ERC721("ALPHA PRESTIGE", "AP") {
        setTreasuryAddress(payable(defaultTreasury));
        setBaseURI(defaultBaseURI);
        setRoyaltyInfo(500);
    }

//EXTERNAL ---------

    function mint(bytes32[] calldata proof) external payable {
        address account = msg.sender;
        uint256 totalSupply_ = _tokenIdCounter.current();
        if(totalSupply_  >= MAX_SUPPLY ) revert AllNFTsSoldOut();        
        if(_verify(_leaf(account), proof) == false) revert IncorrectProof();
        if(minters[account] == true) revert AlreadyMintedForThisAddress();
        minters[account] = true;
        
        _tokenIdCounter.increment();
        uint256 tokenId;
        unchecked {
            tokenId = totalSupply_ + 1;//tokenID starts from 1            
        }
        _safeMint(account, tokenId);
    }
    
    function withdraw() external onlyOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    function setMerkleRoot(bytes32 merkleroot_) external onlyOwner {
        merkleRoot = merkleroot_;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }      

//PUBLIC ---------    


    function setTreasuryAddress(address payable newAddress) public onlyOwner {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
    }

    function setRoyaltyInfo(uint96 newRoyaltyPercentage) public onlyOwner {
        _setDefaultRoyalty(treasuryAddress, newRoyaltyPercentage);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC2981)
    returns (bool)
    {
        return
            ERC2981.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

//INTERNAL --------

    function setBaseURI(string memory newBaseURI) internal onlyOwner {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _verify(bytes32 leaf, bytes32[] calldata  proof) internal view returns (bool)
    {
        return MerkleProof.verifyCalldata(proof, merkleRoot, leaf);
    }

    function _leaf(address account) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(account));
    }
}