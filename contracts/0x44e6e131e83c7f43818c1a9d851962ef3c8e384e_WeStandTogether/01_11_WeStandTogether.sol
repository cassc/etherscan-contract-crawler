// SPDX-License-Identifier: GPL-3.0-or-later

/// @title We Stand Together
/// @author Transient Labs

pragma solidity ^0.8.9;

/*
 _       __        _____ __                  __   ______                 __  __             
| |     / /__     / ___// /_____ _____  ____/ /  /_  __/___  ____ ____  / /_/ /_  ___  _____
| | /| / / _ \    \__ \/ __/ __ `/ __ \/ __  /    / / / __ \/ __ `/ _ \/ __/ __ \/ _ \/ ___/
| |/ |/ /  __/   ___/ / /_/ /_/ / / / / /_/ /    / / / /_/ / /_/ /  __/ /_/ / / /  __/ /    
|__/|__/\___/   /____/\__/\__,_/_/ /_/\__,_/    /_/  \____/\__, /\___/\__/_/ /_/\___/_/     
                                                          /____/                            
   ___       _ __   __  ___  _ ______                 __ 
  / _ )__ __(_) /__/ / / _ \(_) _/ _/__ _______ ___  / /_
 / _  / // / / / _  / / // / / _/ _/ -_) __/ -_) _ \/ __/
/____/\_,_/_/_/\_,_/ /____/_/_//_/ \__/_/  \__/_//_/\__/                                                          
 ______                  _          __    __        __     
/_  __/______ ____  ___ (_)__ ___  / /_  / /  ___ _/ /  ___
 / / / __/ _ `/ _ \(_-</ / -_) _ \/ __/ / /__/ _ `/ _ \(_-<
/_/ /_/  \_,_/_//_/___/_/\__/_//_/\__/ /____/\_,_/_.__/___/                                                           
*/

import "ERC721A.sol";
import "EIP2981AllToken.sol";
import "Ownable.sol";
import "Base64.sol";
import "Strings.sol";

contract WeStandTogether is ERC721A, EIP2981AllToken, Ownable {
    using Strings for uint256;

    bool public saleOpen;
    uint256 public mintPrice;
    address payable public payout;
    address public admin;
    string public description;
    string public image;

    modifier isEOA {
        require(msg.sender == tx.origin, "Function must be called by an EOA");
        _;
    }

    modifier adminOrOwner {
        require(msg.sender == admin || msg.sender == Ownable.owner(), "Address not admin or owner");
        _;
    }

    /// @param _price is the mint price
    /// @param _royaltyRecipient is the royalty recipient
    /// @param _royaltyPercentage is the royalty percentage to set
    /// @param _admin is the admin address
    /// @param _payout is the payout address
    /// @param _description is the piece description
    /// @param _image is the piece image URI
    constructor (uint256 _price, address _royaltyRecipient, uint256 _royaltyPercentage,
        address _admin, address _payout, string memory _description, string memory _image)
        ERC721A("We Stand Together", "STAND") EIP2981AllToken(_royaltyRecipient, _royaltyPercentage) Ownable() 
    {
        admin = _admin;
        payout = payable(_payout);
        mintPrice = _price;
        description = _description;
        image = _image;
    }

    /// @notice function to change the royalty info
    /// @dev requires admin or owner
    /// @dev this is useful if the amount was set improperly at contract creation.
    /// @param newAddr is the new royalty payout addresss
    /// @param newPerc is the new royalty percentage, in basis points (out of 10,000)
    function setRoyaltyInfo(address newAddr, uint256 newPerc) external adminOrOwner {
        require(newAddr != address(0), "Cannot set royalty receipient to the zero address");
        require(newPerc < 10000, "Cannot set royalty percentage above 10000");
        royaltyAddr = newAddr;
        royaltyPerc = newPerc;
    }

    /// @notice function to set the admin address on the contract
    /// @dev requires owner
    /// @param _admin is the new admin address
    function setAdminAddress(address _admin) external onlyOwner {
        require(_admin != address(0), "New admin cannot be the zero address");
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

    /// @notice function to set the piece description
    /// @dev requires owner or admin
    /// @param _description is the new description
    function setDescription(string calldata _description) external adminOrOwner {
        description = _description;
    }

    /// @notice function to flip the sale state
    /// @dev requires admin or owner
    function flipSaleState() external adminOrOwner {
        saleOpen = !saleOpen;
    }

    /// @notice function to mint to the owner's wallet
    function ownerMint() external adminOrOwner {
        _mint(owner(), 1);
    }

    /// @notice function for minting the editions
    /// @dev requires owner or admin
    /// @dev using _mint function as owner() should always be an EOA or trusted entity
    /// @param _num is the number to mint
    function mint(uint256 _num) external payable {
        require(_num <= 50, "Batch size too large");
        require(msg.value >= _num * mintPrice, "Not enough ether attached to the function call");
        require(saleOpen, "Sale is not open");
        _mint(msg.sender, _num);
    }

    /// @notice function to withdraw ether
    /// @dev requires admin or owner
    function withdrawEther() external virtual adminOrOwner {
        payout.transfer(address(this).balance);
    }

    /// @notice function to override tokenURI
    function tokenURI(uint256 tokenId) override public view returns(string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(abi.encodePacked(
                    '{"name": "We Stand Together #', tokenId.toString(), '",',
                    unicode'"description": "', description, '",',
                    '"image": "', image, '"}'
                )))
            )
        );
    }

    /// @notice function to set the start token id
     function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice overrides supportsInterface function
    /// @param interfaceId is supplied from anyone/contract calling this function, as defined in ERC 165
    /// @return boolean saying if this contract supports the interface or not
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, EIP2981AllToken) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || EIP2981AllToken.supportsInterface(interfaceId);
    }
}