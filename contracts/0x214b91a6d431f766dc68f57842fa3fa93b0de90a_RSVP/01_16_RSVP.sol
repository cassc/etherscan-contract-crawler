// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract RSVP is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable 
{
    using SafeMath for uint256;
    using SafeMath for uint8;

    address public vault;
    address public cookie_tree = 0x22764243EC635302C080b55de98ECEE0322E815A;
    address public dr_slurp = 0x13ED8515eA47b0B2dc20c7478F839E92b48f6A3b;
    bool public artistPrintsMinted = false;
    uint256 public constant MAX_RSVP = 53;

    //links
    string public baseURI;
    string public licenseLink;


    //0.03 ETH
    uint256 public price = 30000000000000000;

    mapping(uint256 => string) public RSVPs;

    enum State {Init, Sale, Done}
    State public state = State.Init;

    enum rsvpState {Open, Closed}
    rsvpState public rsvpStatus = rsvpState.Open;
						  
    constructor(string memory initialURI) ERC721("RSVP", "MYFI_RSVP") 
    {
	setBaseURI(initialURI);
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner 
    {
	baseURI = newBaseURI;
    }

    function setLicenseLink(string memory newLicense) public onlyOwner
    {
	licenseLink = newLicense;
    }

    function safeMint(address to, uint256 tokenId, string memory uri) public onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) 
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenID) public view override(ERC721, ERC721URIStorage) returns (string memory)
    {
       return string.concat(string.concat(baseURI, Strings.toString(tokenID)),".json");
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function setVault(address newVaultAddress) public onlyOwner
    {
        vault = newVaultAddress;
    }

    function withdraw(uint256 _amount) public onlyOwner
    {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(_amount));
    }

    function withdrawAll() public payable onlyOwner
    {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(address(this).balance));
    }

    //adjust the price of the NFT
    //only works when in Init
    function setPrice(uint256 newPrice) public onlyOwner initState
    {
        price = newPrice;
    }

    function mintArtistPrints() public onlyOwner initState
    {
        require(totalSupply() < MAX_RSVP, 'not enough pieces remaining for AP mints');
        require(totalSupply().add(2) <= MAX_RSVP, 'not enough invites left');
        require(!artistPrintsMinted, 'artist prints already minted :p');
        
        artistPrintsMinted = true;

        _safeMint(cookie_tree, 0);
        _safeMint(dr_slurp, 1);
    }

     /// @notice Mint RSVPs
    /// @dev  Note: you can mint a maximum of 13 RSVPs in a single transaction. 
    ///      @param toMint The amount of RSVPs you are trying to mint. Must be an integer between 1 and 13.
    function mintRSVP(uint256 toMint) public payable saleState
    {
        if(totalSupply() ==  MAX_RSVP)
	    {
	        state = State.Done;	
	    }

        require(totalSupply() < MAX_RSVP, 'all RSVPs minted');
        require(toMint > 0 && toMint <= 13, 'You can connect to between 1 and 13 RSVPs at a time');
        require(totalSupply().add(toMint) <= MAX_RSVP, 'not enougn RSVPs available for purchase, please chose a smaller ammount...');
        require(msg.value >= price.mul(toMint), 'check your math');

        for (uint256 i = 0; i < toMint; i++) 
        {
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    
    /// @notice RSVP for your destiny
    /// @dev Please write your RSVP message
    ///      @param tokenID The tokenID you want to record an RSVP for
    ///      @param rsvpMessage The message you want to record with your RSVP
    function Send_RSVP_Message(uint256 tokenID, string memory rsvpMessage) public openState
    {
        require(ownsToken(tokenID), 'you do not own this token, hence you cannot RSVP for it');
        RSVPs[tokenID] = rsvpMessage;
    }

    function ownsToken(uint256 tokenID) public view returns (bool)
    {
        //check if not valid token
        if( !( (0 <= tokenID) && (tokenID <= totalSupply())))
        {
            return false;
        }

        //check if token is owned by message sender
        if(msg.sender == ownerOf(tokenID))
        {
            return true;
        }
        else
        {
            return false;
        }
    }

    function openRSVPs() public closedState
    {
        rsvpStatus = rsvpState.Open; 
    }

    function closeRSVPs() public openState
    {
        rsvpStatus = rsvpState.Closed; 
    }


    //moves contract into sale state
    function startSale() public onlyOwner initState
    {
        state = State.Sale;
    }

    //brings contract back to init state
    function pauseSale() public onlyOwner saleState
    {
        state = State.Init;
    }

    //finalizes contract into done state
    function finishSale() public onlyOwner saleState
    {
        state = State.Done;
    }

    modifier initState 
    {
        require(state == State.Init);
        _;
    }

    modifier saleState
    {
        require(state == State.Sale);
        _;    
    }

    modifier openState
    {
        require(rsvpStatus == rsvpState.Open);
        _;    
    }

    modifier closedState
    {
        require(rsvpStatus == rsvpState.Closed);
        _;    
    }

}