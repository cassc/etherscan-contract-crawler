// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Import the ERC721A contract
import "./ERC721A.sol";
// Import the ERC721Burnable contract from OpenZeppelin
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

// Define your new contract
contract BurnAndStore {

    // Declare the ERC721A contract instance
    ERC721A public erc721AContract;

    // Declare the ERC721Burnable contract instance
    ERC721Burnable public erc721BurnableContract;

    // Define a mapping to store the input strings for each burned token
    mapping(uint256 => string) private burnedTokenData;

    // Constructor function to set the ERC721A contract address and initialize the ERC721Burnable contract
    constructor(address _erc721AContractAddress) {
        erc721AContract = ERC721A(_erc721AContractAddress);
        erc721BurnableContract = ERC721Burnable(_erc721AContractAddress);
    }

    // Function to allow users to burn their ERC721A tokens and store input data
    function burnAndStore(uint256 _tokenId, string memory _data) public {
        // Check that the sender owns the token
        require(erc721AContract.ownerOf(_tokenId) == msg.sender, "You do not own this token.");

        // Burn the token using the ERC721Burnable burn function
        erc721BurnableContract.burn(_tokenId);

        // Store the input data for the burned token
        burnedTokenData[_tokenId] = _data;
    }

    // Function to retrieve the input data for a burned token
    function getBurnedTokenData(uint256 _tokenId) public view returns (string memory) {
        return burnedTokenData[_tokenId];
    }
}