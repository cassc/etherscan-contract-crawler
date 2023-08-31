// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721LazyMint.sol";
import "@thirdweb-dev/contracts/base/ERC1155Base.sol";
import "@thirdweb-dev/contracts/base/ERC721Drop.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
                                                                  
//                            /$$$$$$                      /$$$$$$$$
//                           /$$__  $$                    |_____ $$ 
//        /$$$$$$   /$$$$$$ | $$  \__/  /$$$$$$  /$$$$$$$      /$$/ 
//       /$$__  $$ /$$__  $$| $$ /$$$$ /$$__  $$| $$__  $$    /$$/  
//      | $$  \__/| $$$$$$$$| $$|_  $$| $$$$$$$$| $$  \ $$   /$$/   
//      | $$      | $$_____/| $$  \ $$| $$_____/| $$  | $$  /$$/    
//      | $$      |  $$$$$$$|  $$$$$$/|  $$$$$$$| $$  | $$ /$$$$$$$$
//      |__/       \_______/ \______/  \_______/|__/  |__/|________/

contract reGenZ is ERC721LazyMint {
    ERC721LazyMint public immutable mainNFT;
    ERC1155Base public immutable burnNFT;

    mapping(uint256 => bool) private usedMainNFTIds; // Keeps track of main NFT token IDs that have been used

    // Event to log the main NFT token IDs used for a burn
    event MainNFTUsedForBurn(address indexed user, uint256 indexed mainNFTId);
    event BurnWithoutMainNFT(address indexed user);

    constructor(
        address _defaultAdmin,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _mainNFT,
        address _burnNFT
    ) ERC721LazyMint(_defaultAdmin, _name, _symbol, _royaltyRecipient, _royaltyBps) {
        mainNFT = ERC721LazyMint(_mainNFT);
        burnNFT = ERC1155Base(_burnNFT);
    }

    string private _baseTokenURI;

    

    function verifyClaim(address _claimer, uint256[] memory mainTokenIds) public view {
        for (uint256 i = 0; i < mainTokenIds.length; i++) {
            require(mainNFT.ownerOf(mainTokenIds[i]) == _claimer, "You don't own any of these deGenZ");
            require(!usedMainNFTIds[mainTokenIds[i]], string(abi.encodePacked("deGenZ #", Strings.toString(mainTokenIds[i]), " has already been Vaccinated")));

            require(burnNFT.balanceOf(_claimer, 0) >= 1, "You don't have enough VaccineZ");
        }
    }

    function burnForMainNFTs(address _claimer, uint256[] memory mainTokenIds) external {
        
        verifyClaim(_claimer, mainTokenIds);

        for (uint256 i = 0; i < mainTokenIds.length; i++) {
            usedMainNFTIds[mainTokenIds[i]] = true;
            emit MainNFTUsedForBurn(_claimer, mainTokenIds[i]);
        }

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = 0; // Assuming the token ID to burn is 0
        amounts[0] = mainTokenIds.length; // Burn equivalent to the number of main NFTs provided
        require(_currentIndex + amounts[0] <= nextTokenIdToLazyMint, "All deGenZ have already been Vaccinated");
        burnNFT.burnBatch(_claimer, tokenIds, amounts);

         _mint(_claimer, mainTokenIds.length);
    }

    function burn3ForMainNFTs(address _claimer, uint256[] memory mainTokenIds) external {
        
        verifyClaim(_claimer, mainTokenIds);
        require(burnNFT.balanceOf(_claimer, 0) >= 3, "You don't have enough VaccineZ");
        require(mainTokenIds.length == 1, "Must select a deGenZ to Vaccinate");
        for (uint256 i = 0; i < mainTokenIds.length; i++) {
            usedMainNFTIds[mainTokenIds[i]] = true;
            emit MainNFTUsedForBurn(_claimer, mainTokenIds[i]);
        }

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = 0; // Assuming the token ID to burn is 0
        amounts[0] = 3; // Burn equivalent to the number of main NFTs provided
        require(_currentIndex + 1 <= nextTokenIdToLazyMint, "All deGenZ have already been Vaccinated");
        burnNFT.burnBatch(_claimer, tokenIds, amounts);

         _mint(_claimer, 1);
    }

    function burn6ForMainNFTs(address _claimer, uint256[] memory mainTokenIds) external {
        require(burnNFT.balanceOf(_claimer, 0) >= 6, "You don't have enough VaccineZ");
        require(mainTokenIds.length == 1, "Must select a deGenZ to Vaccinate");
        verifyClaim(_claimer, mainTokenIds);

        for (uint256 i = 0; i < mainTokenIds.length; i++) {
            usedMainNFTIds[mainTokenIds[i]] = true;
            emit MainNFTUsedForBurn(_claimer, mainTokenIds[i]);
        }

        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = 0; // Assuming the token ID to burn is 0
        amounts[0] = 6; // Burn equivalent to the number of main NFTs provided
        require(_currentIndex + 1 <= nextTokenIdToLazyMint, "All deGenZ have already been Vaccinated");
        burnNFT.burnBatch(_claimer, tokenIds, amounts);

         _mint(_claimer, 1);
    }

    function burnWithoutMainNFT(address _claimer) external {
        require(burnNFT.balanceOf(_claimer, 0) >= 3, "You don't have enough VaccineZ");
        require(_currentIndex + 1 <= nextTokenIdToLazyMint, "All deGenZ have already been Vaccinated");
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        tokenIds[0] = 0;
        amounts[0] = 3;

        burnNFT.burnBatch(_claimer, tokenIds, amounts);
        // Minting the NFT for the user
        // For the sake of simplicity, the following code assumes the existence of a mint function in the inherited ERC721LazyMint contract.
        _mint(_claimer, 1); // 'totalSupply() + 1' gives a new unique token ID based on the total supply

        emit BurnWithoutMainNFT(_claimer);
    }

    function _transferTokensOnClaim(address _receiver, uint256 _quantity) internal override returns(uint256) {
        uint256[] memory tokenIds = new uint256[](1);
        uint256[] memory quantities = new uint256[](1);

        // All NFTs have the token ID 0 in your case
        tokenIds[0] = 0;

        // Burning 3 of token ID 0
        quantities[0] = 3;

        burnNFT.burnBatch(_receiver, tokenIds, quantities);

        // Returning the number of tokens burned (3 in this case)
        return super._transferTokensOnClaim(_receiver, _quantity);
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    using Strings for uint256;

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory base = _baseTokenURI;
        string memory id = tokenId.toString();

        return bytes(base).length > 0
            ? string(abi.encodePacked(base, id))
            : "";
    }
}