// SPDX-License-Identifier: MIT

/*
* GoldieGhosty.sol
*
* Author: Don Huey / twitter: donbtc
* Created: April 18th, 2022
* Creators: Mister Goldie, Don Huey
*
* Mint Price: Free for Scary Gary Holders, 0.05 ETH for all other
* Rinkby: 
*
* 
*
* Description: 
*
* Mister Goldie returns with the Gary Ghosts. 
* Gary Ghosts are based on the childhood act of pretending to be a ghost by throwing a sheet over your head. 
* Let this collection take you back to your childhood and bring you happiness. 
* Gary Ghosts are apart of the Scary Garys family.
*                                                                                                                                                                           
*
*/

pragma solidity > 0.5.0 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; 
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "./HueyAccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol"; 
import "./ERC2981ContractWideRoyalties.sol"; // Royalties for contract, EIP-2981
import "./RandomlyAssigned.sol";


contract GARYGHOSTS is ERC721, HueyAccessControl, ERC2981ContractWideRoyalties, RandomlyAssigned {

    //@dev Using SafeMath
        using SafeMath for uint256;
    //@dev Using Counters for increment/decrement
        using Counters for Counters.Counter;
    //@dev uint256 to strings
        using Strings for uint256;


    //@dev Important numbers and state variables
        string public baseExtension = ".json";
        uint256 public constant MAX_TOKENS = 750; // Max supply of tokens
        uint256 public constant GHOST_PRICE = 50000000000000000; // 0.05
        string public baseURI;
        string public constant ProvenanceHash = "3e85e3a4a3c57679a1bc832be0352c50c4ed05a74b522e656f6cecbf9a0b64de"; // This is the compiled metadata of all the football heads which can be used to prove that no metadata was changed.



      //@dev constructor for ERC721 + custom constructor
        constructor()
            ERC721("Gary Ghosts", "GG")
            RandomlyAssigned(MAX_TOKENS, 1)
        {
            
            _gang[msg.sender] = true;
            _gang[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
            _setRoyalties(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 750);
            baseURI = "ipfs://QmPCx9HGKDqnJTXn2hsb1pCoQUeKm5LCLWMcJzLchywSxc/";
            

        }



    //@dev Tool 'mint' creates token & maps previously assigned tokenIdToURI mapping
        function GhostMint() 
            public
            payable
        {
                //@dev The sent ETH has to be over the required amount.
            require(
                GHOST_PRICE <= msg.value, "Huey: Ethereum sent is not sufficient."
            );
            require(
                totalSupply() <= MAX_TOKENS, "Huey: There are no tokens left to mint."
            );
            
                _mintRandomId(msg.sender);
        }


    //@dev Tool 'mint' creates token & maps previously assigned tokenIdToURI mapping
        function GoldListMint() 
                public
                payable
                onlygoldlist(msg.sender)
            {
            //@dev The sent ETH has to be over the required amount.
            require(
                totalSupply() <= MAX_TOKENS, "Huey: There are no tokens left to mint."
            );

            require(
                balanceOf(msg.sender) < 1, "Huey: You can only mint one free Ghost"
            );
                    
            
                _mintRandomId(msg.sender);
                    
                    
                }


        function ownerMint(uint num)
        public
        payable
        onlyOwner
        {
            for (uint i = 0; i < num ; i++) {
            
                _mintRandomId(msg.sender);
            }
        }


    // @dev internal check to ensure a genesis token ID, or ID outside of the collection, doesn't get minted
        function _mintRandomId(address to) private {
            uint256 id = nextToken();
            assert(
                id < MAX_TOKENS
                    );
            _safeMint(to, id);

            }

    //@dev returns the tokenURI of tokenID
        function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "Huey: URI query for nonexistent token"
        );
        

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }


    //@dev internal baseURI function
            function _baseURI() 
                internal 
                view
                virtual 
                override 
                returns (string memory)
                {
                // Format: "ipfs://link/";
                    return baseURI;
                }


    //@dev Sets the Base URI value
            function setBaseURI(string memory _newbaseURI)
            public
            onlyOwner
            {
                baseURI = _newbaseURI;
            }



    //@dev Allows us to withdraw funds collected.
            function withdraw(address payable wallet, uint256 amount)
                payable
                isGang 
                public
            {
                require(amount <= address(this).balance,
                    "Huey: Insufficient funds to withdraw");
                wallet.transfer(amount);
            }

    //@dev overrides interface functions for EIP-2981, royalties.
            function supportsInterface(bytes4 interfaceId)
            public
            view
            virtual
            override (ERC721,ERC2981Base)
            returns (bool)
        {
            return
                interfaceId == type(IERC2981Royalties).interfaceId ||
                super.supportsInterface(interfaceId);
        }


}