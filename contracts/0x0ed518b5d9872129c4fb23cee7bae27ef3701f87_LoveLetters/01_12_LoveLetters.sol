// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/*

Vinnie Hager x The Heart Project presents...

▀██▀                                  ▀██▀                ▄     ▄                          
 ██         ▄▄▄   ▄▄▄▄ ▄▄▄   ▄▄▄▄      ██         ▄▄▄▄  ▄██▄  ▄██▄    ▄▄▄▄  ▄▄▄ ▄▄   ▄▄▄▄  
 ██       ▄█  ▀█▄  ▀█▄  █  ▄█▄▄▄██     ██       ▄█▄▄▄██  ██    ██   ▄█▄▄▄██  ██▀ ▀▀ ██▄ ▀  
 ██       ██   ██   ▀█▄█   ██          ██       ██       ██    ██   ██       ██     ▄ ▀█▄▄ 
▄██▄▄▄▄▄█  ▀█▄▄█▀    ▀█     ▀█▄▄▄▀    ▄██▄▄▄▄▄█  ▀█▄▄▄▀  ▀█▄▀  ▀█▄▀  ▀█▄▄▄▀ ▄██▄    █▀▄▄█▀ 

(Love Letters) 💌

dev by Luke Davis (luke.onl) & Fraser (@jalfrazi_)

*/

contract LoveLetters is Ownable, ERC1155 {
    using Strings for uint256;

    string private _baseTokenURI;
    bytes32 private _merkleRoot;

    mapping(address => bool) private _hasClaimed;

    bool public isClaimEnabled = false;

    constructor() ERC1155("") {}

    modifier claimEnabledOnly() {
        require(isClaimEnabled, "Claim window is closed.");
        _;
    }

    function toggleClaimStatus() external onlyOwner {
        isClaimEnabled = !isClaimEnabled;
    }

    function claimLoveLetter(bytes32[] calldata _merkleProof)
        external
        claimEnabledOnly
    {
        require(
            !_hasClaimed[msg.sender],
            "You have already claimed your Love Letter."
        );
        require(
            _isEligibleToClaim(_merkleProof, msg.sender),
            "Address not eligible for claiming."
        );

        _mint(msg.sender, 0, 1, "");

        _hasClaimed[msg.sender] = true;
    }

    function _isEligibleToClaim(bytes32[] memory _merkleProof, address _addr)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                _merkleProof,
                _merkleRoot,
                keccak256(abi.encodePacked(_addr))
            );
    }

    function hasClaimedLetter(address addr) public view returns (bool) {
        return _hasClaimed[addr];
    }

    function setMerkleRoot(bytes32 _newRoot) external onlyOwner {
        _merkleRoot = _newRoot;
    }

    function setUri(string memory _newUri) external onlyOwner {
        _baseTokenURI = _newUri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, tokenId.toString()));
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}