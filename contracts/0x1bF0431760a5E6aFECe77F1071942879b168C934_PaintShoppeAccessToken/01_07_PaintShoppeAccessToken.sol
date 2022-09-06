// SPDX-License-Identifier: MIT

/// @title Paint Shoppe Access Key
/// @author transientlabs.xyz

/*
 ____   __    ____  _  _  ____    ___  _   _  _____  ____  ____  ____ 
(  _ \ /__\  (_  _)( \( )(_  _)  / __)( )_( )(  _  )(  _ \(  _ \( ___)
 )___//(__)\  _)(_  )  (   )(    \__ \ ) _ (  )(_)(  )___/ )___/ )__) 
(__) (__)(__)(____)(_)\_) (__)   (___/(_) (_)(_____)(__)  (__)  (____)
   __    ___  ___  ____  ___  ___    ____  _____  _  _  ____  _  _    
  /__\  / __)/ __)( ___)/ __)/ __)  (_  _)(  _  )( )/ )( ___)( \( )   
 /(__)\( (__( (__  )__) \__ \\__ \    )(   )(_)(  )  (  )__)  )  (    
(__)(__)\___)\___)(____)(___/(___/   (__) (_____)(_)\_)(____)(_)\_)   

*/

pragma solidity ^0.8.9;

import "ERC721A.sol";
import "Ownable.sol";
import "IERC721.sol";

contract PaintShoppeAccessToken is ERC721A, Ownable {

    bool public saleOpen;
    uint256 public mintPrice;
    address payable public payout;
    address public admin;
    string private baseURI;
    IERC721 public FEG;

    modifier adminOrOwner {
        require(msg.sender == admin || msg.sender == Ownable.owner(), "Address not admin or owner");
        _;
    }

    /// @param _price is the mint price
    /// @param _admin is the admin address
    /// @param _payout is the payout address
    /// @param _feg is the Feet and Eyes Guys contract address
    constructor (uint256 _price, address _admin, address _payout, address _feg)
        ERC721A("Paint Shoppe Access Token", "PSAT") Ownable() 
    {
        admin = _admin;
        payout = payable(_payout);
        mintPrice = _price;
        FEG = IERC721(_feg);
    }

    /// @notice function to set the admin address on the contract
    /// @dev requires owner
    /// @param _admin is the new admin address
    function setAdminAddress(address _admin) external onlyOwner {
        admin = _admin;
    }

    /// @notice function to set the payout address on the contract
    /// @dev requires owner
    /// @param _payout is the new admin address
    function setPayoutAddress(address _payout) external onlyOwner {
        require(_payout != address(0), "New payout address cannot be the zero address");
        payout = payable(_payout);
    }

    /// @notice function to set mint price
    /// @dev requires admin or owner
    /// @param _price is the new mint price
    function setMintPrice(uint256 _price) external adminOrOwner {
        mintPrice = _price;
    }

    /// @notice function to set the base URI
    /// @dev requires owner or admin
    /// @param _uri is the new base uri
    function setBaseURI(string calldata _uri) external adminOrOwner {
        baseURI = _uri;
    }

    /// @notice function to flip the sale state
    /// @dev requires admin or owner
    function flipSaleState() external adminOrOwner {
        saleOpen = !saleOpen;
    }

    /// @notice function to give key to a wallet
    /// @dev requires owner or admin
    /// @param _address is the recipient address - which should be verified to be able to receive ERC721 tokens as _mint is used
    function giveToken(address _address) external adminOrOwner {
        _mint(_address, 1);
    }

    /// @notice function for minting the tokens
    /// @dev requires enough eth to be sent with the function call
    /// @dev requires the token recipient to hold at least 1 Feet and Eyes Guy
    /// @param _recipient is the recipient of the token
    function buyToken(address _recipient) external payable {
        require(this.balanceOf(_recipient) == 0, "Recipient already has an access token");
        require(saleOpen, "Sale is not open");
        require(msg.value >= mintPrice, "Not enough ether attached to the function call");
        require(FEG.balanceOf(_recipient) >= 1, "Recipient does not own any Feet and Eyes Guys");
        _safeMint(_recipient, 1);
    }

    /// @notice function to withdraw ether
    /// @dev requires admin or owner
    function withdrawEther() external virtual adminOrOwner {
        payout.transfer(address(this).balance);
    }

    /// @notice function to stop people from setting approvals for marketplaces - ie, can't list the tokens
    function setApprovalForAll(address operator, bool approved) public virtual override {
        revert("This is a soul bound token and can't be listed");
    }

    /// @notice function to override base URI
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /// @notice function to set the start token id
     function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice function to turn this into a soul bound token
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        require(from == address(0), "This is a soul bound token and can't be transferred");
    }

}