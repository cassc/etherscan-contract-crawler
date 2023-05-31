// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Openzeppelin Contracts
import "erc721a/contracts/extensions/ERC721APausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// PlaySide Contracts
import "./PetsSettingsG1.sol";
import "../PetsErrorCodes.sol";
import "../PetsEvents.sol";

contract BeansPetsGen1 is ERC721APausable, Ownable, PetsSettingsG1 {
    using Strings for uint256;

    constructor(string memory _name, string memory _symbol)
        ERC721A(_name, _symbol)
    {}

    function _startTokenId() internal pure override returns (uint256) {
        // Token ID starts at 1
        return 1;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721A)
        returns (string memory)
    {
        if (revealed == false) {
            return hiddenURI;
        }

        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json"))
                : "";
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    	PAUSE
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    // *                    	MINT
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    /// @dev Mints pets from the collection and automatically sends them to the
    /// 	correct people provided by the array
    function airdropPets(
        address[] calldata whitelist,
        uint256[] calldata whitelist_quanityPerUser
    ) public onlyOwner {
        if (
            whitelist.length == 0 ||
            whitelist_quanityPerUser.length != whitelist.length
        ) {
            revert PetsErrorCodes.ArrayMissmatch();
        }

        // Itterate over all the whitelist addresses and airdrop all the pets to their address
        for (uint256 i = 0; i < whitelist.length; i++) {
            // Cache both requested variables some the lists
            address targetAddress = whitelist[i];
            uint256 targetQuantity = whitelist_quanityPerUser[i];

            // Ensure the target quantity is above 0
            if (targetQuantity == 0) {
                revert();
            }

            // Finally mint the desired amount to the owner of this contract
            _safeMint(targetAddress, targetQuantity);

            emit PetsEvents.PetAirdropped(targetAddress, targetQuantity);
        }
    }

    /// @dev This is a function to take the money from the contract and pay the developers
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return
            ERC721A.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }
}