pragma solidity ^0.5.0;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/access/Roles.sol";
import "./Metadata.sol";

/**
// ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! !
//    
//    OOOOOO    OOOOOOO   OOOOOO   OOOOOOOOOO   OOOOOOOOOO   OOOOOOOO  OOOOOOO 
//   OOOOOOO   OOOOOOOO  OOOOOOOO  OOOOOOOOOOO  OOOOOOOOOOO  OOOOOOOO  OOOOOOOO
//   !OO       !OO       OO!  OOO  OO! OO! OO!  OO! OO! OO!  OO!       OO!  OOO
//   !O!       !O!       !O!  O!O  !O! !O! !O!  !O! !O! !O!  !O!       !O!  O!O
//   !!OO!!    !O!       O!O!O!O!  O!! !!O O!O  O!! !!O O!O  O!!!:!    O!O!!O! 
//    !!O!!!   !!!       !!!O!!!!  !O!   ! !O!  !O!   ! !O!  !!!!!:    !!O!O!  
//        !:!  :!!       !!:  !!!  !!:     !!:  !!:     !!:  !!:       !!: :!! 
//       !:!   :!:       :!:  !:!  :!:     :!:  :!:     :!:  :!:       :!:  !:!
//   :::: ::    ::: :::  ::   :::  :::     ::   :::     ::    :: ::::  ::   :::
//   :: : :     :: :: :   :   : :   :      :     :      :    : :: ::    :   : :
//
// .. SCAMMER.MARKET .. 2021
// .. AMNESIA SCANNER .. PWR .. WURMHUMUSFABRIK MARIPOSA
//
// : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : : :
**/

contract Scammer is ERC721Full, Ownable {
    using Roles for Roles.Role;
    Roles.Role private _admins;
    uint8 admins;

    address public metadata;
    address public controller;

    modifier onlyAdminOrController() {
        require((_admins.has(msg.sender) || msg.sender == controller), "DOES_NOT_HAVE_ADMIN_OR_CONTROLLER_ROLE");
        _;
    }

    modifier onlyAdmin() {
        require(_admins.has(msg.sender), "DOES_NOT_HAVE_ADMIN_ROLE");
        _;
    }
    
    /**
    * @dev Checks msg.sender can transfer a token, by being owner, approved, operator or controller
    * @param _tokenId uint256 ID of the token to validate
    */
    modifier canTransfer(uint256 _tokenId) {
        require(_isApprovedOrOwner(msg.sender, _tokenId) || msg.sender == controller);
        _;
    }

    constructor(string memory name, string memory symbol, address _metadata) public ERC721Full(name, symbol) {
        metadata = _metadata;
        _admins.add(msg.sender);
        admins += 1;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }
    
    function mint(address recepient, uint256 tokenId) public onlyAdminOrController {
        _mint(recepient, tokenId);
    }
    function burn(uint256 tokenId) public onlyAdminOrController {
        _burn(ownerOf(tokenId), tokenId);
    }
    function updateMetadata(address _metadata) public onlyAdminOrController {
        metadata = _metadata;
    }
    function updateController(address _controller) public onlyAdminOrController {
        controller = _controller;
    }

    function addAdmin(address _admin) public onlyOwner {
        _admins.add(_admin);
        admins += 1;
    }
    function removeAdmin(address _admin) public onlyOwner {
        require(admins > 1, "CANT_REMOVE_LAST_ADMIN");
        _admins.remove(_admin);
        admins -= 1;
    }

    function tokenURI(uint _tokenId) external view returns (string memory _infoUrl) {
        return Metadata(metadata).tokenURI(_tokenId);
    }

    function contractURI() external view returns (string memory _infoUrl) {
        return Metadata(metadata).contractURI();
    }

    /**
    * @dev Moves Eth to a certain address for use in the ScammerController
    * @param _to The address to receive the Eth.
    * @param _amount The amount of Eth to be transferred.
    */
    function moveEth(address payable _to, uint256 _amount) public onlyAdminOrController {
        require(_amount <= address(this).balance);
        _to.transfer(_amount);
    }
    /**
    * @dev Moves Token to a certain address for use in the ScammerController
    * @param _to The address to receive the Token.
    * @param _amount The amount of Token to be transferred.
    * @param _token The address of the Token to be transferred.
    */
    function moveToken(address _to, uint256 _amount, address _token) public onlyAdminOrController returns (bool) {
        require(_amount <= IERC20(_token).balanceOf(address(this)));
        return IERC20(_token).transfer(_to, _amount);
    }

}