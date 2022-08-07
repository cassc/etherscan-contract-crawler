// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//                     .__              
// _____   __ __  ____ |__| ___________ 
// \__  \ |  |  \/ ___\|  |/ __ \_  __ \
//  / __ \|  |  / /_/  >  \  ___/|  | \/
// (____  /____/\___  /|__|\___  >__|   
//      \/     /_____/         \/       

/*//////////////////////////////////////////////////////////////
                        ERRORS
//////////////////////////////////////////////////////////////*/
error NOT_EXISTING_TOKEN();

contract NftAuction1 is ERC721, IERC2981, Ownable, ReentrancyGuard {
/*//////////////////////////////////////////////////////////////
                        STATE VARIABLES
//////////////////////////////////////////////////////////////*/
    string private customBaseURI;
    //Pop International
    address private constant payoutAddress1 = 0xfb9d4b1650875f754E704f186b5EcF7bE17b259d;
    //Augier 
    address private constant  payoutAddress2 =  0x26BdC56005Dc75F59F461A03C90f8171e5CB6fc4;
/*//////////////////////////////////////////////////////////////
                        INIT/CONSTRUCTOR
//////////////////////////////////////////////////////////////*/
    /// @notice Initialize the contract with the given parameters.
    /// @dev it takes a the URI and stores it as a state variable

    constructor(string memory customBaseURI_)
        ERC721("Augier Auction #1", "AGR")
    {
        customBaseURI = customBaseURI_;
        _mint(msg.sender, 1);
    }

/*//////////////////////////////////////////////////////////////
                        READ FUNCTIONS
//////////////////////////////////////////////////////////////*/
    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(super.tokenURI(tokenId),".json"));
    }

    ///@notice sets the royalties for secondary sales.
    ///Override function gets royalty information for a token (EIP-2981)
    ///@param salePrice as an input to calculate the royalties
    ///@dev conforms to EIP-2981

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if(!_exists(tokenId)) {
           revert NOT_EXISTING_TOKEN();
        }
        return (address(this), (salePrice * 10) / 100);
    }
    ///@notice override function to check if contract supports given interface
    ///@param interfaceId id of interface to check
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
/*//////////////////////////////////////////////////////////////
                        WITHDRAW 
//////////////////////////////////////////////////////////////*/
    function withdraw() public nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), (balance * 90) / 100);
        Address.sendValue(payable(payoutAddress2), (balance * 10) / 100);
    }

//Fallback
    receive() external payable {}
}